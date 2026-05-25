/// 在flow执行期间收集的用于上报/监控的参数。
///
/// 跟踪每个阶段的时序、大小和结果：
/// query -> download -> unzip。
class FlowReportParams {
  String bisName;
  int queryStartTime;
  int queryEndTime;
  int downloadStartTime;
  int downloadEndTime;
  int unzipStartTime;
  int unzipEndTime;
  int replaceStartTime;
  int replaceEndTime;
  bool querySuccess;
  bool downloadSuccess;
  bool unzipSuccess;
  bool replaceSuccess;
  String queryMessage;
  String downloadMessage;
  String unzipMessage;
  String replaceMessage;
  double zipSize;
  bool isBrokenDown;

  FlowReportParams({
    required this.bisName,
    this.queryStartTime = 0,
    this.queryEndTime = 0,
    this.downloadStartTime = 0,
    this.downloadEndTime = 0,
    this.unzipStartTime = 0,
    this.unzipEndTime = 0,
    this.replaceStartTime = 0,
    this.replaceEndTime = 0,
    this.querySuccess = false,
    this.downloadSuccess = false,
    this.unzipSuccess = false,
    this.replaceSuccess = false,
    this.queryMessage = '',
    this.downloadMessage = '',
    this.unzipMessage = '',
    this.replaceMessage = '',
    this.zipSize = 0,
    this.isBrokenDown = false,
  });

  /// 标记查询阶段开始。
  void queryStart() {
    queryStartTime = DateTime.now().millisecondsSinceEpoch;
  }

  /// 标记查询阶段结束。
  void queryEnd() {
    queryEndTime = DateTime.now().millisecondsSinceEpoch;
  }

  /// 设置查询结果状态和可选消息。
  void setQueryResult(bool success, [String message = '']) {
    querySuccess = success;
    queryMessage = message;
  }

  /// 标记下载开始。
  void downloadStart() {
    downloadStartTime = DateTime.now().millisecondsSinceEpoch;
  }

  /// 设置下载结果状态和可选消息。
  void downloadResult(bool success, [String message = '']) {
    downloadSuccess = success;
    downloadMessage = message;
    downloadEndTime = DateTime.now().millisecondsSinceEpoch;
  }

  /// 标记解压开始。
  void unZipStart() {
    unzipStartTime = DateTime.now().millisecondsSinceEpoch;
  }

  /// 标记解压结束并设置成功状态。
  void unZipEnd(bool success, [String message = '']) {
    unzipSuccess = success;
    unzipMessage = message;
    unzipEndTime = DateTime.now().millisecondsSinceEpoch;
  }

  /// 标记替换阶段开始。
  void replaceStart() {
    replaceStartTime = DateTime.now().millisecondsSinceEpoch;
  }

  /// 标记替换阶段结束并设置成功状态。
  void replaceEnd(bool success, [String message = '']) {
    replaceSuccess = success;
    replaceMessage = message;
    replaceEndTime = DateTime.now().millisecondsSinceEpoch;
  }

  /// 设置下载的zip文件大小。
  void zipSizeSet(double size) {
    zipSize = size;
  }

  /// 设置这是否是断点续传。
  void isBrokenDownSet(bool value) {
    isBrokenDown = value;
  }

  /// 将所有参数转换为适合上报/监控的map。
  Map<String, dynamic> toReportMap() {
    return {
      'bisName': bisName,
      'queryStartTime': queryStartTime,
      'queryEndTime': queryEndTime,
      'downloadStartTime': downloadStartTime,
      'downloadEndTime': downloadEndTime,
      'unzipStartTime': unzipStartTime,
      'unzipEndTime': unzipEndTime,
      'replaceStartTime': replaceStartTime,
      'replaceEndTime': replaceEndTime,
      'querySuccess': querySuccess,
      'downloadSuccess': downloadSuccess,
      'unzipSuccess': unzipSuccess,
      'replaceSuccess': replaceSuccess,
      'queryMessage': queryMessage,
      'downloadMessage': downloadMessage,
      'unzipMessage': unzipMessage,
      'replaceMessage': replaceMessage,
      'zipSize': zipSize,
      'isBrokenDown': isBrokenDown,
      'queryDuration': queryEndTime - queryStartTime,
      'downloadDuration': downloadEndTime - downloadStartTime,
      'unzipDuration': unzipEndTime - unzipStartTime,
      'replaceDuration': replaceEndTime - replaceStartTime,
    };
  }
}
