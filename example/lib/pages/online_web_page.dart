import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:offline_webview/offline_webview.dart';

/// 普通 WebView 页面，用于与离线加载进行速度对比.
/// 此页面直接加载 URL，不使用离线包拦截.
class OnlineWebPage extends StatefulWidget {
  final String url;

  const OnlineWebPage({super.key, this.url = 'https://www.baidu.com'});

  @override
  State<OnlineWebPage> createState() => _OnlineWebPageState();
}

class _OnlineWebPageState extends State<OnlineWebPage> {
  late InAppWebViewController _controller;

  @override
  void initState() {
    super.initState();
    Logger.d('OnlineWebPage', '页面创建');
  }

  String _buildUrl() {
    return widget.url;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('网络加载'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _controller.reload();
            },
          ),
        ],
      ),
      body: FloatingPerformancePanel(
        child: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(_buildUrl())),
          initialSettings: InAppWebViewSettings(
            useShouldOverrideUrlLoading: false,
            javaScriptEnabled: true,
          ),
          onWebViewCreated: (controller) {
            _controller = controller;
            Logger.d('OnlineWebPage', 'WebView创建');
          },
          onLoadStart: (controller, url) {
            Logger.d('OnlineWebPage', '开始加载');
          },
          onLoadStop: (controller, url) {
            Logger.i('OnlineWebPage', '加载完成');
          },
        ),
      ),
    );
  }
}