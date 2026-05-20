import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../util/off_web_log.dart';

/// 预加载条目：管理一个隐藏但真实的 [InAppWebView]。
///
/// 与 [HeadlessInAppWebView] 不同，此方案使用真实的平台视图，
/// 享受 [OfflineWebViewPreWarmer] 的进程复用和 GPU 渲染加速。
class PreloadedWebView extends StatefulWidget {
  final String fileUrl;

  const PreloadedWebView({
    super.key,
    required this.fileUrl,
  });

  @override
  State<PreloadedWebView> createState() => PreloadedWebViewState();
}

class PreloadedWebViewState extends State<PreloadedWebView> {
  bool _isReady = false;
  bool _consumed = false;
  InAppWebViewController? _controller;

  bool get isReady => _isReady && !_consumed;
  InAppWebViewController? get controller => _consumed ? null : _controller;

  /// 标记已消费，触发从 widget tree 中移除。
  void consume() {
    if (_consumed) return;
    _consumed = true;
    _controller = null;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_consumed) return const SizedBox.shrink();

    return SizedBox(
      width: 1,
      height: 1,
      child: OverflowBox(
        maxWidth: 1,
        maxHeight: 1,
        child: Opacity(
          opacity: 0.0,
          child: InAppWebView(
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
            ),
            onWebViewCreated: (controller) {
              _controller = controller;
              Logger.d('WebViewPreloadPool', 'WebView 已创建，开始加载');
              controller.loadUrl(
                urlRequest: URLRequest(url: WebUri(widget.fileUrl)),
              );
            },
            onLoadStop: (controller, url) {
              if (!_isReady) {
                _isReady = true;
                Logger.i('WebViewPreloadPool', '预加载完成: ${widget.fileUrl}');
              }
            },
            onReceivedError: (controller, request, error) {
              Logger.e('WebViewPreloadPool', '加载错误: ${error.description}');
            },
          ),
        ),
      ),
    );
  }
}

/// WebView 预加载池管理器。
class WebViewPreloadPool {
  static final WebViewPreloadPool _instance = WebViewPreloadPool._();
  static WebViewPreloadPool get instance => _instance;
  WebViewPreloadPool._();

  /// bisName to GlobalKey mapping for preloaded WebView states
  final Map<String, GlobalKey<PreloadedWebViewState>> _entries = {};

  /// 注册一个预加载 WebView。
  void register(String bisName, GlobalKey<PreloadedWebViewState> key) {
    _entries[bisName] = key;
    Logger.d('WebViewPreloadPool', '注册: $bisName');
  }

  /// 取出指定 bisName 的预加载 State。
  PreloadedWebViewState? take(String bisName) {
    final key = _entries.remove(bisName);
    if (key == null) return null;

    final state = key.currentState;
    if (state == null || !state.isReady) {
      _entries[bisName] = key; // 放回
      return null;
    }

    state.consume();
    Logger.d('WebViewPreloadPool', '取出并消费: $bisName');
    return state;
  }

  /// 指定 bisName 是否已预加载完成。
  bool isReady(String bisName) {
    return _entries[bisName]?.currentState?.isReady ?? false;
  }

  void unregister(String bisName) {
    _entries.remove(bisName);
  }

  void clear() {
    _entries.clear();
  }
}
