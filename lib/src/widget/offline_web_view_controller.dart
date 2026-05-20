import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// 管理离线Web系统中[InAppWebView]实例的控制器。
///
/// 包装平台的[InAppWebViewController]并提供
/// 用于加载URL和重新加载离线内容的方法。
class OfflineWebViewController {
  InAppWebViewController? _webController;
  String _currentUrl = '';
  String _originalUrl = '';

  /// 附加平台的[InAppWebViewController]。
  void attach(InAppWebViewController controller) {
    _webController = controller;
  }

  /// 分离平台控制器（dispose时调用）。
  void detach() {
    _webController = null;
  }

  /// 平台控制器当前是否已附加。
  bool get isAttached => _webController != null;

  /// WebView中当前加载的URL。
  String get currentUrl => _currentUrl;

  /// 设置当前URL（在离线内容加载后由内部使用）。
  void setCurrentUrl(String url) {
    _currentUrl = url;
  }

  /// 原始（非离线）URL。
  String get originalUrl => _originalUrl;

  /// 重新加载离线Web内容。
  Future<void> reloadOfflineWeb() async {
    final controller = _webController;
    if (controller == null || _currentUrl.isEmpty) return;

    await controller.loadUrl(
      urlRequest: URLRequest(url: WebUri(_currentUrl)),
    );
  }

  /// 在WebView中加载给定的[url]。
  Future<void> loadUrl(String url) async {
    _currentUrl = url;
    _originalUrl = url;
    final controller = _webController;
    if (controller == null) return;
    await controller.loadUrl(
      urlRequest: URLRequest(url: WebUri(url)),
    );
  }

  /// 清除 WebView 的所有缓存。
  Future<void> clearCache() async {
    await InAppWebViewController.clearAllCache();
  }
}
