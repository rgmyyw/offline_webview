import '../download/downloader.dart';
import '../flow/resource_flow.dart';
import '../interceptor/interceptor.dart';
import '../match/bis_name_matcher.dart';
import '../match/off_web_rule_util.dart';
import '../net/offline_request.dart';
import 'offline_config.dart';
import 'offline_const.dart';

/// 离线Web SDK的初始化参数。
///
/// 通过链式setter方法构建。包含所有可配置的依赖项：
/// config、回调函数、调试标志和策略对象。
class OfflineParams {
  /// 离线Web配置开关和predownloadlist等。
  OfflineConfig _config = const OfflineConfig();

  /// 日志回调，用于输出调试信息。
  OfflineWebLogBlock? _logBlock;

  /// 上报回调，用于上报埋点数据。
  OfflineWebReportBlock? _reportBlock;

  /// 监控回调，用于监控离线包加载状态。
  OfflineWebMonitorBlock? _monitorBlock;

  /// 离线包加载结果回调。
  OfflineWebResultBlock? _resultBlock;

  /// Flow流程完成后的详细耗时回调（query/download/unzip各阶段耗时）。
  void Function(int queryMs, int downloadMs, int unzipMs)? _timingBlock;

  /// 是否开启调试模式。
  bool _isDebug = false;

  /// 文件下载器，负责从服务器下载离线包zip。
  IDownloader? _downloader;

  /// URL到bisName的匹配器。
  BisNameMatcher? _matcher;

  /// 业务模块拦截器，可决定某些bisName是否跳过离线加载。
  Interceptor? _interceptor;

  /// Flow流程结果的处理策略。
  IFlowResultHandleStrategy? _flowResultHandleStrategy;

  /// 与服务器通信的请求器，用于查询离线包更新信息。
  IOfflineRequest? _requestServer;

  /// URL匹配规则配置，包含hosts/paths到bisName的映射。
  OfflineRuleConfig? _rule;

  /// 环境标识，如"prod"/"test"。
  String _env = '';

  /// 客户端版本号，用于服务器端版本判断。
  String _appVersion = '';

  OfflineParams config(OfflineConfig value) {
    _config = value;
    return this;
  }

  OfflineParams logBlock(OfflineWebLogBlock? value) {
    _logBlock = value;
    return this;
  }

  OfflineParams reportBlock(OfflineWebReportBlock? value) {
    _reportBlock = value;
    return this;
  }

  OfflineParams monitorBlock(OfflineWebMonitorBlock? value) {
    _monitorBlock = value;
    return this;
  }

  OfflineParams resultBlock(OfflineWebResultBlock? value) {
    _resultBlock = value;
    return this;
  }

  OfflineParams timingBlock(void Function(int, int, int)? value) {
    _timingBlock = value;
    return this;
  }

  OfflineParams isDebug(bool value) {
    _isDebug = value;
    return this;
  }

  OfflineParams downloader(IDownloader? value) {
    _downloader = value;
    return this;
  }

  OfflineParams matcher(BisNameMatcher? value) {
    _matcher = value;
    return this;
  }

  OfflineParams interceptor(Interceptor? value) {
    _interceptor = value;
    return this;
  }

  OfflineParams flowResultHandleStrategy(IFlowResultHandleStrategy? value) {
    _flowResultHandleStrategy = value;
    return this;
  }

  OfflineParams requestServer(IOfflineRequest? value) {
    _requestServer = value;
    return this;
  }

  OfflineParams setRule(OfflineRuleConfig? value) {
    _rule = value;
    return this;
  }

  OfflineParams env(String value) {
    _env = value;
    return this;
  }

  OfflineParams appVersion(String value) {
    _appVersion = value;
    return this;
  }

  OfflineConfig get getConfig => _config;
  OfflineWebLogBlock? get getLogBlock => _logBlock;
  OfflineWebReportBlock? get getReportBlock => _reportBlock;
  OfflineWebMonitorBlock? get getMonitorBlock => _monitorBlock;
  OfflineWebResultBlock? get getResultBlock => _resultBlock;
  void Function(int, int, int)? get getTimingBlock => _timingBlock;
  bool get getIsDebug => _isDebug;
  IDownloader? get getDownloader => _downloader;
  BisNameMatcher? get getMatcher => _matcher;
  Interceptor? get getInterceptor => _interceptor;
  IFlowResultHandleStrategy? get getFlowResultHandleStrategy =>
      _flowResultHandleStrategy;
  IOfflineRequest? get getRequestServer => _requestServer;
  OfflineRuleConfig? get getRule => _rule;
  String get getEnv => _env;
  String get getAppVersion => _appVersion;
}
