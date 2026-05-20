/// 离线Web操作的result事件。
enum OfflineWebResultEvent {
  disable(-17),
  parseError(-16),
  queryError(-14),
  downloadError(-13),
  unzipError(-12),
  downloadCancel(-1),
  downloading(-4),
  unzipSuccess(0),
  refreshPackageLater(1),
  refreshPackageNow(2),
  refreshOnlineWebNow(3),
  noUpdate(10),
  downloadSuccess(11);

  final int code;
  const OfflineWebResultEvent(this.code);
}

/// 离线Web SDK日志级别。
enum OfflineWebLogLevel {
  error(0),
  warning(1),
  info(2),
  debug(3);

  final int level;
  const OfflineWebLogLevel(this.level);
}

/// 上报监控类型。
enum OfflineWebMonitorType {
  counter(0),
  summary(1);

  final int type;
  const OfflineWebMonitorType(this.type);
}

/// WebView生命周期数据上报事件。
enum DataReportEvent {
  webviewStartLoad(0),
  webviewLoadSuccess(1),
  webviewLoadFail(2),
  webviewWillRequest(3),
  webviewReceiveResponse(4);

  final int event;
  const DataReportEvent(this.event);
}

/// 离线Web result事件的回调函数。
typedef OfflineWebResultBlock = void Function(
    OfflineWebResultEvent event, String bisName, String? message);

/// 日志消息的回调函数。
typedef OfflineWebLogBlock = void Function(
    OfflineWebLogLevel level, String message);

/// 数据上报事件的回调函数。
typedef OfflineWebReportBlock = void Function(
    DataReportEvent event, String bisName, Map<String, dynamic>? params);

/// 监控数据的回调函数。
typedef OfflineWebMonitorBlock = void Function(
    OfflineWebMonitorType type, Map<String, dynamic> data);

/// 离线包管理使用的目录名常量。
class OfflineDirName {
  static const String cur = 'cur';
  static const String newDir = 'new';
  static const String old = 'old';
  static const String temp = 'temp';
}

/// 离线包管理使用的文件名常量。
class OfflineFileName {
  static const String config = '.offweb.json';
  static const String html = 'index.html';
  static const String zipSuffix = '.zip';
}

/// 离线Web请求的参数键常量。
class OfflineParam {
  static const String offWeb = 'offweb';
  static const String offWebHost = 'offweb_host';
  static const String offlineZipVer = 'offlineZipVer';
  static const String env = 'env';
  static const String clientVersion = 'clientVersion';
  static const String os = 'os';
  static const String bisName = 'bisName';
}

/// 离线Web存储的根目录名称。
const String kOfflineWebRootDir = 'offline_web';
