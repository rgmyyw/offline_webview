import 'offline_web_view_proxy.dart';

/// [IOfflineWebViewProxy]的空实现。
///
/// 原样传递所有URL，不进行任何离线解析。
/// 当离线Web管理器未初始化时使用。
class EmptyOfflineWebViewProxy implements IOfflineWebViewProxy {
  @override
  String get bisName => '';

  @override
  String loadUrl(String url) => url;

  @override
  void initialize(String originalUrl, String resolvedUrl) {
    // 无操作
  }

  @override
  void reLoadUrl() {
    // 无操作
  }

  @override
  void destroy() {
    // 无操作
  }
}
