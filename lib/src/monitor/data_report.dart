import '../core/offline_const.dart';
import '../core/offline_web_manager.dart';

/// WebView加载监控数据上报。
///
/// 对应iOS的HLLOfflineWebDataReport。跟踪WebView加载事件
/// 的时序和状态，并通过manager的上报和监控回调报告指标。
class DataReport {
  /// 被监控的业务模块名称。
  final String bisName;

  Uri? _originURL;
  int _startQueryTime = 0;
  int _willQueryTime = 0;
  int _httpResponseCode = 0;

  DataReport({required this.bisName});

  /// 通知reporter WebView生命周期事件。
  ///
  /// [event] - WebView事件类型
  /// [url] - 与事件关联的URL（如果适用）
  /// [code] - HTTP响应码或错误码
  /// [errMsg] - 错误消息（用于fail事件）
  void notifyWebEvent(
      DataReportEvent event, Uri? url, int code, String errMsg) {
    switch (event) {
      case DataReportEvent.webviewStartLoad:
        _startQueryTime = DateTime.now().millisecondsSinceEpoch;
        break;

      case DataReportEvent.webviewWillRequest:
        _willQueryTime = DateTime.now().millisecondsSinceEpoch;
        if (url != null) {
          _originURL = url;
        }
        break;

      case DataReportEvent.webviewReceiveResponse:
        _httpResponseCode = code;
        break;

      case DataReportEvent.webviewLoadSuccess:
        _handleLoadComplete(true, code, errMsg);
        break;

      case DataReportEvent.webviewLoadFail:
        _handleLoadComplete(false, code, errMsg);
        break;
    }
  }

  /// 处理加载完成（成功或失败）。
  ///
  /// 计算时序，构建上报数据，并提交给监控。
  void _handleLoadComplete(bool success, int code, String errMsg) {
    // 如果没有记录origin URL，则无需上报
    if (_originURL == null) {
      return;
    }

    // 计算耗时
    final costTime = _calculateCostTime();
    if (costTime < 0) {
      _reset();
      return;
    }

    // 构建上报数据字典
    final isOffweb = _originURL!.scheme == 'file';
    final simpleUrl = _buildSimpleUrl(_originURL!);

    final reportDict = <String, dynamic>{
      'url': _originURL.toString(),
      'simpleUrl': simpleUrl,
      'loadTime': costTime,
      'loadResult': success ? 0 : -1,
      'errMsg': errMsg,
      'errCode': code,
      'httpCode': _httpResponseCode,
      'isOffweb': isOffweb ? 1 : 0,
      'bisName': bisName,
    };

    // 通过OfflineWebManager提交上报
    final manager = OfflineWebManager.instance;
    if (manager.isInit) {
      manager.reportBlock?.call(
        DataReportEvent.webviewLoadSuccess,
        bisName,
        reportDict,
      );
    }

    // 构建监控标签
    final labels = <String, dynamic>{
      'scheme': _originURL!.scheme,
      'url': isOffweb
          ? _originURL.toString()
          : _originURL!.replace(fragment: '').toString(),
      'bisName': bisName,
      'result': success ? 'success' : 'fail',
    };

    // 通过OfflineWebManager提交监控
    if (manager.isInit) {
      manager.monitorBlock?.call(
        OfflineWebMonitorType.summary,
        {
          'name': 'webviewLoadTime',
          'value': costTime,
          'labels': labels,
        },
      );
    }

    // 重置时间戳为下一个周期做准备
    _reset();
  }

  /// 计算加载耗时（毫秒）。
  ///
  /// 如果可用则使用_willQueryTime（更准确的起点），
  /// 否则回退到_startQueryTime。
  int _calculateCostTime() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final startTime = _willQueryTime > 0 ? _willQueryTime : _startQueryTime;
    if (startTime <= 0) return -1;
    return now - startTime;
  }

  /// 构建简化URL字符串（scheme + host + path，无query/fragment）。
  String _buildSimpleUrl(Uri uri) {
    if (uri.scheme == 'file') {
      return 'file://${uri.path}';
    }
    return '${uri.scheme}://${uri.host}${uri.path}';
  }

  /// 重置所有时序数据为下一个加载周期做准备。
  void _reset() {
    _startQueryTime = 0;
    _willQueryTime = 0;
    _httpResponseCode = 0;
    // 保留_originURL以供后续参考
  }

  /// 完全重置所有状态，包括origin URL。
  void fullReset() {
    _reset();
    _originURL = null;
  }
}
