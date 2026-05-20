import 'dart:io';

import 'package:path/path.dart' as p;

import '../download/default_downloader.dart';
import '../download/downloader.dart';
import '../flow/fetch_package_flow.dart';
import '../flow/resource_flow.dart';
import '../interceptor/interceptor.dart';
import '../match/bis_name_matcher.dart';
import '../match/default_matcher.dart';
import '../match/off_web_rule_util.dart';
import '../net/offline_request.dart';
import '../page/offline_page_manager.dart';
import '../server/local_server.dart';
import '../task/offline_task_manager.dart';
import '../util/file_mgr.dart';
import '../util/off_web_log.dart';
import 'offline_config.dart';
import 'offline_const.dart';
import 'offline_params.dart';

/// 离线Web SDK的核心单例管理器。
///
/// 持有所有状态并提供对所有子系统的访问：
/// 配置、回调、下载器、匹配器、拦截器、
/// 任务管理器、页面管理器和缓存。
class OfflineWebManager {
  static final OfflineWebManager _instance = OfflineWebManager._internal();

  /// 单例实例。
  static OfflineWebManager get instance => _instance;

  OfflineWebManager._internal();

  // --- 配置和回调 ---
  OfflineConfig _config = const OfflineConfig();
  OfflineWebLogBlock? _logBlock;
  OfflineWebReportBlock? _reportBlock;
  OfflineWebMonitorBlock? _monitorBlock;
  OfflineWebResultBlock? _resultBlock;
  void Function(int queryMs, int downloadMs, int unzipMs)? _timingBlock;
  bool _isDebug = false;

  // --- 子系统 ---
  IDownloader? _downloader;
  BisNameMatcher? _matcher;
  Interceptor? _interceptor;
  IFlowResultHandleStrategy? _strategy;
  IOfflineRequest? _request;
  OfflineRuleConfig? _ruleConfig;
  String _env = '';
  String _appVersion = '';

  // --- 状态 ---
  bool _isInit = false;
  bool _disableFlag = false;
  final Set<String> _disableBisList = {};

  // --- 管理器 ---
  final OfflinePageManager _pageManager = OfflinePageManager();
  final OfflineTaskManager _taskManager = OfflineTaskManager();
  final List<ResourceFlow> _resourceFlows = [];
  final Map<String, String> _curPathCache = {};

  // --- Getters ---

  /// 管理器是否已初始化。
  bool get isInit => _isInit;

  /// 离线Web配置。
  OfflineConfig get config => _config;

  /// 日志回调。
  OfflineWebLogBlock? get logBlock => _logBlock;

  /// 上报回调。
  OfflineWebReportBlock? get reportBlock => _reportBlock;

  /// 监控回调。
  OfflineWebMonitorBlock? get monitorBlock => _monitorBlock;

  /// 结果事件回调。
  OfflineWebResultBlock? get resultBlock => _resultBlock;

  /// 各阶段耗时回调。
  void Function(int queryMs, int downloadMs, int unzipMs)? get timingBlock =>
      _timingBlock;

  /// 设置各阶段耗时回调。
  void setTimingBlock(void Function(int queryMs, int downloadMs, int unzipMs)? block) {
    _timingBlock = block;
  }

  /// 调试模式标志。
  bool get isDebug => _isDebug;

  /// 下载器实例（默认为[DefaultDownloader]）。
  IDownloader get downloader => _downloader ?? DefaultDownloader();

  /// URL匹配器实例（默认为[DefaultMatcher]）。
  BisNameMatcher get matcher => _matcher ?? DefaultMatcher();

  /// 拦截器实例（默认为[DefaultInterceptor]）。
  Interceptor get interceptor => _interceptor ?? DefaultInterceptor();

  /// Flow结果处理策略。
  IFlowResultHandleStrategy? get strategy => _strategy;

  /// 服务器请求接口。
  IOfflineRequest? get request => _request;

  /// 更新请求接口而无需重新初始化整个SDK。
  void setRequest(IOfflineRequest request) {
    _request = request;
  }

  /// URL规则配置。
  OfflineRuleConfig get ruleConfig => _ruleConfig ?? const OfflineRuleConfig();

  /// 环境字符串。
  String get env => _env;

  /// App版本字符串。
  String get appVersion => _appVersion;

  /// 用于跟踪活动WebView代理的页面管理器。
  OfflinePageManager get pageManager => _pageManager;

  /// 用于后台操作的任务管理器。
  OfflineTaskManager get taskManager => _taskManager;

  /// 活动的resource flows。
  List<ResourceFlow> get resourceFlows => _resourceFlows;

  /// 每个业务模块的缓存当前路径。
  Map<String, String> get curPathCache => _curPathCache;

  // --- 初始化 ---

  /// 使用给定的[params]初始化管理器。
  ///
  /// 解析所有参数，检查离线Web是否启用，
  /// 并从配置中填充禁用列表。
  Future<void> init(OfflineParams params) async {
    const tag = 'OfflineWebManager';
    Logger.i(tag, '初始化方法调用');

    // 解析参数
    _config = params.getConfig;
    Logger.d(tag, '配置isOpen: ${_config.isOpen}');
    Logger.d(tag, '配置预下载列表: ${_config.preDownloadList}');
    Logger.d(tag, '配置禁用列表: ${_config.disableList}');

    _logBlock = params.getLogBlock;
    Logger.init(_logBlock);
    _reportBlock = params.getReportBlock;
    _monitorBlock = params.getMonitorBlock;
    _resultBlock = params.getResultBlock;
    _timingBlock = params.getTimingBlock;
    _isDebug = params.getIsDebug;

    if (params.getDownloader != null) {
      _downloader = params.getDownloader as IDownloader;
      Logger.d(tag, '下载器已设置: ${_downloader.runtimeType}');
    }
    if (params.getMatcher != null) {
      _matcher = params.getMatcher as BisNameMatcher;
      Logger.d(tag, '匹配器已设置: ${_matcher.runtimeType}');
    }
    if (params.getInterceptor != null) {
      _interceptor = params.getInterceptor as Interceptor;
    }
    if (params.getFlowResultHandleStrategy != null) {
      _strategy =
          params.getFlowResultHandleStrategy as IFlowResultHandleStrategy;
    }
    if (params.getRequestServer != null) {
      _request = params.getRequestServer as IOfflineRequest;
      Logger.d(tag, '请求服务已设置: ${_request.runtimeType}');
    }
    if (params.getRule != null) {
      _ruleConfig = params.getRule as OfflineRuleConfig;
      Logger.d(tag, '规则配置已设置, 规则数量: ${_ruleConfig!.rules.length}');
    } else {
      Logger.w(tag, '规则配置为空，使用默认空配置');
    }

    _env = params.getEnv;
    _appVersion = params.getAppVersion;

    // 检查离线Web是否启用
    if (!_config.isOpen) {
      Logger.w(tag, '离线Web未启用，跳过');
      _isInit = false;
      return;
    }

    // 从配置中填充禁用列表
    _disableBisList.clear();
    _disableBisList.addAll(_config.disableList);
    Logger.d(tag, '禁用列表已填充: $_disableBisList');

    _isInit = true;
    Logger.d(tag, '初始化完成标志已设置');

    // 为FetchPackageFlow设置provider
    _connectFlows();

    // 刷新本地路径缓存，确保已知包都被发现
    await refreshAllCurPathCache();

    // 为所有已知离线包启动本地 HTTP 服务器
    final server = LocalServer.instance;
    for (final bisName in _curPathCache.keys) {
      await server.startForBisName(bisName);
    }

    Logger.i(tag, '初始化完成');
  }

  // --- 禁用管理 ---

  /// 检查业务模块是否被禁用。
  ///
  /// 如果满足以下任一条件则返回true：
  /// - 全局禁用标志已设置
  /// - bisName在配置禁用列表中
  /// - bisName在动态禁用列表中
  bool isDisable(String bisName) {
    if (_disableFlag) return true;
    if (_config.isDisable(bisName)) return true;
    if (_disableBisList.contains(bisName)) return true;
    return false;
  }

  /// 将业务模块添加到动态禁用列表。
  void addToDisableList(String bisName) {
    _disableBisList.add(bisName);
  }

  // --- Cur路径缓存 ---

  /// 获取业务模块的缓存当前路径。
  String? getCachedCurPath(String bisName) {
    return _curPathCache[bisName];
  }

  /// 刷新给定[bisName]的当前路径缓存。
  ///
  /// 读取实际目录结构并更新内部缓存和[DefaultMatcher]静态缓存。
  Future<void> refreshCurPathCache(String bisName) async {
    try {
      final bisDir = await FileMgr.getBisDir(bisName);
      final curDir = p.join(bisDir, OfflineDirName.cur);
      final htmlPath = p.join(curDir, OfflineFileName.html);

      // 检查cur/index.html是否存在
      final exists = File(htmlPath).existsSync();
      if (exists) {
        _curPathCache[bisName] = curDir;
        DefaultMatcher.setCurPath(bisName, curDir);
        // 确保 bisName 的本地服务器已启动
        if (_isInit && !LocalServer.instance.isRunning(bisName)) {
          await LocalServer.instance.startForBisName(bisName);
        }
      } else {
        _curPathCache.remove(bisName);
        DefaultMatcher.removeCurPath(bisName);
      }
    } catch (e) {
      _curPathCache.remove(bisName);
      DefaultMatcher.removeCurPath(bisName);
    }
  }

  /// 刷新所有业务模块的当前路径缓存。
  Future<void> refreshAllCurPathCache() async {
    final bisNames = await FileMgr.getAllBisNames();
    for (final bisName in bisNames) {
      await refreshCurPathCache(bisName);
    }
  }

  /// 从磁盘获取包的本地版本。
  Future<String> getLocalVersion(String bisName) async {
    return FileMgr.getCurVersion(bisName);
  }

  // --- 包检查 ---

  /// 检查并更新给定[bisName]的离线包。
  ///
  /// 委托给[OfflineTaskManager]。
  void checkPackage(String bisName, FlowListener? listener) {
    _taskManager.checkPackage(
      bisName,
      listener,
      request: _request,
      downloader: _downloader,
      interceptor: _interceptor,
      resultBlock: _resultBlock,
    );
  }

  /// 清理所有离线Web数据。
  ///
  /// 委托给[OfflineTaskManager]。
  Future<void> clean() async {
    await _taskManager.clean();
    _curPathCache.clear();
    DefaultMatcher.clearCache();
    await LocalServer.instance.stopAll();
  }

  /// 清理指定[bisName]的离线Web数据。
  Future<void> cleanBisName(String bisName) async {
    _taskManager.removeRunning(bisName);
    await FileMgr.deleteDiskCache(bisName);
    await LocalServer.instance.stopForBisName(bisName);
    _curPathCache.remove(bisName);
    DefaultMatcher.removeCurPath(bisName);
  }

  // --- 私有辅助方法 ---

  /// 连接需要provider访问的flow子系统。
  void _connectFlows() {
    // FetchPackageFlow需要访问请求接口。
    // 它使用静态provider模式。
    FetchPackageFlow.setProvider(_ManagerProvider(this));
  }
}

/// 提供flows访问manager状态的Provider实现。
class _ManagerProvider implements OfflineWebManagerProvider {
  final OfflineWebManager _manager;

  _ManagerProvider(this._manager);

  @override
  IOfflineRequest? get request => _manager.request;
}
