import 'dart:async';

import 'package:offline_webview/offline_webview.dart';

/// 离线Web后台任务管理器。
class OfflineTaskManager {
  static final IDownloader _defaultDownloader = DefaultDownloader();
  final Set<String> _runningFlows = {};
  final List<FlowReportParams> _completedStats = [];

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
    final request = OfflineWebManager.instance.request;

    // 如果开启了全量预下载，先从服务器获取所有bisName
    if (config.preDownloadAll && request != null) {
      final allBisNames = await _fetchAllBisNames(request);
      for (final bisName in allBisNames) {
        if (!config.disableList.contains(bisName)) {
          Logger.d(tag, '全量预下载添加: $bisName');
        }
      }
      // 合并：全量列表 + 手动指定的列表，排除禁用列表
      final merged = <String>{...allBisNames, ...config.preDownloadList}
        ..removeAll(config.disableList);

      if (merged.isEmpty) {
        Logger.d(tag, '全量预下载列表为空，跳过');
        return;
      }

      Logger.d(tag, '开始预下载 ${merged.length} 个包（含全量）');
      await _downloadBisNames(merged.toList());
      return;
    }

    if (config.preDownloadList.isEmpty) {
      Logger.d(tag, '预下载列表为空，跳过');
      return;
    }

    Logger.d(tag, '开始预下载 ${config.preDownloadList.length} 个包');
    await _downloadBisNames(config.preDownloadList.toList());
  }

  /// 从服务器获取所有可用的bisName列表。
  Future<List<String>> _fetchAllBisNames(IOfflineRequest request) async {
    const tag = 'OfflineTaskManager';
    final completer = Completer<List<String>>();
    request.requestAllBisNames(_AllBisNamesCallback(
      onSuccess: (list) {
        Logger.d(tag, '获取到 ${list.length} 个可用包');
        completer.complete(list);
      },
      onFail: (error) {
        Logger.e(tag, '获取全量包列表失败: $error');
        completer.complete(const []);
      },
    ));
    return completer.future;
  }

  /// 下载指定的bisName列表，等待全部完成。
  Future<void> _downloadBisNames(List<String> bisNames) async {
    const tag = 'OfflineTaskManager';
    _completedStats.clear();

    for (final bisName in bisNames) {
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
    while (_runningFlows.intersection(bisNames.toSet()).isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _printSummary();

    Logger.i(tag, '预下载完成');
  }

  /// 打印所有包的耗时汇总。
  void _printSummary() {
    const tag = 'PreDownloadSummary';
    if (_completedStats.isEmpty) {
      Logger.i(tag, '无已完成的包');
      return;
    }

    int totalQueryMs = 0;
    int totalDownloadMs = 0;
    int totalUnzipMs = 0;
    int totalReplaceMs = 0;
    double totalSize = 0;
    int successCount = 0;
    int failCount = 0;

    final buffer = StringBuffer();
    buffer.writeln('--- 预下载汇总 ---');

    for (final p in _completedStats) {
      final queryMs = p.queryEndTime > p.queryStartTime ? p.queryEndTime - p.queryStartTime : 0;
      final downloadMs = p.downloadEndTime > p.downloadStartTime ? p.downloadEndTime - p.downloadStartTime : 0;
      final unzipMs = p.unzipEndTime > p.unzipStartTime ? p.unzipEndTime - p.unzipStartTime : 0;
      final replaceMs = p.replaceEndTime > p.replaceStartTime ? p.replaceEndTime - p.replaceStartTime : 0;

      final downloaded = p.downloadStartTime > 0;
      final status = !p.querySuccess ? 'fail'
          : (downloaded ? (p.downloadSuccess && p.unzipSuccess ? 'ok' : 'fail') : 'cached');

      totalQueryMs += queryMs;
      totalDownloadMs += downloadMs;
      totalUnzipMs += unzipMs;
      totalReplaceMs += replaceMs;
      totalSize += p.zipSize;
      if (status == 'ok') successCount++; else if (status == 'fail') failCount++;

      final pkgTotal = queryMs + downloadMs + unzipMs + replaceMs;
      buffer.writeln('  [$status] ${p.bisName}  total=${pkgTotal}ms  query=${queryMs}ms  download=${downloadMs}ms  unzip=${unzipMs}ms  replace=${replaceMs}ms  size=${_formatSize(p.zipSize)}');
    }

    final allTotalMs = totalQueryMs + totalDownloadMs + totalUnzipMs + totalReplaceMs;
    final cachedCount = _completedStats.length - successCount - failCount;
    buffer.writeln('--- all: ${_completedStats.length} packages ($successCount ok / $cachedCount cached / $failCount fail)  total=${allTotalMs}ms  query=${totalQueryMs}ms  download=${totalDownloadMs}ms  unzip=${totalUnzipMs}ms  replace=${totalReplaceMs}ms  size=${_formatSize(totalSize)} ---');

    Logger.i(tag, buffer.toString());
    _completedStats.clear();
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
            completedStats: _completedStats,
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
  final List<FlowReportParams> _completedStats;

  _TaskFlowListener({
    required this.bisName,
    required this.runningFlows,
    this.innerListener,
    FlowReportParams? flowParams,
    required List<FlowReportParams> completedStats,
  })  : _flowParams = flowParams,
        _completedStats = completedStats;

  @override
  void done(OfflinePackageInfo? info) {
    const tag = 'TaskFlowListener';
    runningFlows.remove(bisName);
    innerListener?.done(info);

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
      final replaceMs = params.replaceEndTime > params.replaceStartTime
          ? params.replaceEndTime - params.replaceStartTime : 0;
      final totalMs = queryMs + downloadMs + unzipMs + replaceMs;
      PerformanceMonitor.instance.recordOfflinePhase(
        bisName: bisName,
        queryMs: queryMs,
        downloadMs: downloadMs,
        unzipMs: unzipMs,
        querySuccess: params.querySuccess,
        downloadSuccess: params.downloadSuccess,
        unzipSuccess: params.unzipSuccess,
      );

      // 打印单包耗时（含总计）
      final downloaded = params.downloadStartTime > 0;
      final status = !params.querySuccess ? 'fail'
          : (downloaded ? (params.downloadSuccess && params.unzipSuccess ? 'ok' : 'fail') : 'cached');
      final curPath = OfflineWebManager.instance.getCachedCurPath(bisName);
      Logger.i(tag, '[$status] $bisName  total=${totalMs}ms  query=${queryMs}ms  download=${downloadMs}ms  unzip=${unzipMs}ms  replace=${replaceMs}ms  size=${_formatSize(params.zipSize)}  path=$curPath');

      // 收集统计用于汇总打印
      _completedStats.add(params);
    }
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

/// 用于requestAllBisNames回调的RequestCallback实现。
class _AllBisNamesCallback implements RequestCallback<List<String>> {
  final void Function(List<String> data) _onSuccess;
  final void Function(Object error) _onFail;

  _AllBisNamesCallback({
    required void Function(List<String> data) onSuccess,
    required void Function(Object error) onFail,
  })  : _onSuccess = onSuccess,
        _onFail = onFail;

  @override
  void onSuccess(List<String> data) => _onSuccess(data);

  @override
  void onFail(Object error) => _onFail(error);
}

String _formatSize(double sizeInKB) {
  if (sizeInKB <= 0) return '-';
  if (sizeInKB >= 1024) return '${(sizeInKB / 1024).toStringAsFixed(2)}MB';
  return '${sizeInKB.toStringAsFixed(1)}KB';
}
