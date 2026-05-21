import 'package:offline_webview/offline_webview.dart';
import '../monitor/performance_monitor.dart';

/// 离线Web后台任务管理器。
class OfflineTaskManager {
  static final IDownloader _defaultDownloader = DefaultDownloader();
  final Set<String> _runningFlows = {};

  /// 运行初始化：版本检查+缓存刷新+预下载。
  Future<void> startInitTask() async {
    const tag = 'OfflineTaskManager';
    try {
      Logger.i(tag, '初始化任务开始');
      await CheckVersionTask.run();
      await OfflineWebManager.instance.refreshAllCurPathCache();

      // 触发预下载列表中的包下载
      await _preDownloadPackages();

      Logger.i(tag, '初始化任务完成');
    } catch (e) {
      Logger.e(tag, '初始化任务错误: $e');
    }
  }

  /// 预下载preDownloadList中的所有包。
  Future<void> _preDownloadPackages() async {
    const tag = 'OfflineTaskManager';
    final config = OfflineWebManager.instance.config;
    if (config.preDownloadList.isEmpty) {
      Logger.d(tag, '预下载列表为空，跳过');
      return;
    }

    Logger.d(tag, '开始预下载 ${config.preDownloadList.length} 个包');

    // 收集所有需要等待的bisName
    final bisNamesToDownload = config.preDownloadList.toList();

    for (final bisName in bisNamesToDownload) {
      Logger.d(tag, '预下载业务: $bisName');
      checkPackage(
        bisName,
        null,
        request: OfflineWebManager.instance.request,
        downloader: OfflineWebManager.instance.downloader,
        interceptor: OfflineWebManager.instance.interceptor,
        resultBlock: OfflineWebManager.instance.resultBlock,
      );
    }

    // 等待所有预下载任务完成
    Logger.d(tag, '等待预下载完成...');
    while (_runningFlows.intersection(bisNamesToDownload.toSet()).isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    Logger.i(tag, '预下载完成');
  }

  /// 检查并更新[bisName]的离线包。
  void checkPackage(
    String bisName,
    FlowListener? listener, {
    required IOfflineRequest? request,
    required IDownloader? downloader,
    required Interceptor? interceptor,
    required OfflineWebResultBlock? resultBlock,
  }) {
    const tag = 'OfflineTaskManager';
    Logger.d(tag, '检查包更新 - bisName: $bisName, downloader: $downloader');
    if (bisName.isEmpty) {
      Logger.w(tag, '检查包更新 - bisName为空, 返回');
      return;
    }
    if (interceptor != null && interceptor.isIntercept(bisName)) {
      Logger.d(tag, '检查包更新 - 被拦截, 跳过');
      return;
    }
    if (_runningFlows.contains(bisName)) {
      Logger.d(tag, '检查包更新 - 正在运行中 $bisName, 跳过');
      return;
    }
    _runningFlows.add(bisName);
    Logger.d(tag, '检查包更新 - 已添加到运行列表');

    // 如果没有提供下载器，则使用DefaultDownloader
    final effectiveDownloader = downloader ?? _defaultDownloader;

    // 构建并异步启动flow
    _startFlow(bisName, listener, effectiveDownloader, resultBlock);
  }

  Future<void> _startFlow(
    String bisName,
    FlowListener? listener,
    IDownloader? downloader,
    OfflineWebResultBlock? resultBlock,
  ) async {
    const tag = 'OfflineTaskManager';
    Logger.d(tag, '流程开始 - bisName: $bisName, downloader: $downloader');
    try {
      final localVersion = await FileMgr.getCurVersion(bisName);
      Logger.d(tag, '本地版本: $localVersion');

      final reportParams = FlowReportParams(bisName: bisName);
      final packageInfo = OfflinePackageInfo(
        bisName: bisName,
        version: localVersion,
      );
      final flow = ResourceFlow()
        ..setPackageInfo(packageInfo)
        ..setReportParams(reportParams)
        ..setFlowListener(
          _TaskFlowListener(
            bisName: bisName,
            runningFlows: _runningFlows,
            innerListener: listener,
            flowParams: reportParams,
          ),
        );

      flow.addFlow(
        FetchPackageFlow(
          flow: flow,
          bisName: bisName,
          version: localVersion,
          resultBlock: resultBlock,
        ),
      );

      if (downloader != null) {
        flow.addFlow(
          DownloadFlow(
            flow: flow,
            downloader: downloader,
            resultBlock: resultBlock,
          ),
        );
      }

      flow.addFlow(ParsePackageFlow(flow: flow, resultBlock: resultBlock));

      flow.addFlow(ReplaceResFlow(flow: flow, resultBlock: resultBlock));

      await flow.start();
      Logger.i(tag, '流程启动成功');
    } catch (e) {
      Logger.e(tag, '流程错误: $e');
      _runningFlows.remove(bisName);
    }
  }

  /// 清理所有离线Web缓存数据。
  Future<void> clean() async {
    _runningFlows.clear();
    await CleanTask.run();
  }

  /// 从运行中列表移除指定[bisName]。
  void removeRunning(String bisName) {
    _runningFlows.remove(bisName);
  }
}

/// 在完成时刷新缓存的内部FlowListener。
class _TaskFlowListener implements FlowListener {
  final String bisName;
  final Set<String> runningFlows;
  final FlowListener? innerListener;
  final FlowReportParams? _flowParams;

  _TaskFlowListener({
    required this.bisName,
    required this.runningFlows,
    this.innerListener,
    FlowReportParams? flowParams,
  }) : _flowParams = flowParams;

  @override
  void done(OfflinePackageInfo? info) {
    const tag = 'TaskFlowListener';
    Logger.i(tag, '完成 - bisName: $bisName, 版本: ${info?.version}');
    runningFlows.remove(bisName);
    innerListener?.done(info);

    // 刷新缓存，确保后续访问可以使用离线内容
    Logger.d(tag, '刷新缓存供下次访问使用');
    OfflineWebManager.instance.refreshCurPathCache(bisName);

    // 记录离线阶段耗时到 PerformanceMonitor
    final params = _flowParams;
    if (params != null) {
      final queryMs = params.queryEndTime > params.queryStartTime
          ? params.queryEndTime - params.queryStartTime : 0;
      final downloadMs = params.downloadEndTime > params.downloadStartTime
          ? params.downloadEndTime - params.downloadStartTime : 0;
      final unzipMs = params.unzipEndTime > params.unzipStartTime
          ? params.unzipEndTime - params.unzipStartTime : 0;
      PerformanceMonitor.instance.recordOfflinePhase(
        queryMs: queryMs,
        downloadMs: downloadMs,
        unzipMs: unzipMs,
        querySuccess: params.querySuccess,
        downloadSuccess: params.downloadSuccess,
        unzipSuccess: params.unzipSuccess,
      );
    }

    // 注意：下载完成后不自动reload当前页面
    // 原因：首次访问时页面已显示在线内容，下载完成时如果强制reload会中断用户当前浏览
    // 下次访问时由于缓存已更新，会自动使用离线内容
    Logger.d(tag, '不强制刷新当前页面，下次访问将自动使用离线内容');
  }

  /// 查找给定bisName的代理。
  // IOfflineWebViewProxy? _findProxyForBisName(String bisName) {
  //   // 访问页面管理器的内部代理 - 我们需要暴露一种按bisName获取代理的方法
  //   // 目前，触发所有页面的reload - 管理器将按bisName过滤
  //   OfflineWebManager.instance.pageManager.reload(bisName);
  //   return null;
  // }

  @override
  void error(OfflinePackageInfo? info, Object err) {
    const tag = 'TaskFlowListener';
    Logger.e(tag, '错误 - bisName: $bisName, 错误: $err');
    runningFlows.remove(bisName);
    innerListener?.error(info, err);
  }
}
