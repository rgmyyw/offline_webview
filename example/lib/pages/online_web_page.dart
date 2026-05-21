import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:offline_webview/offline_webview.dart';

import '../l10n/app_localizations.dart';

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
  final Stopwatch _sw = Stopwatch()..start();
  bool _loggedCreate = false;
  bool _loggedLoadStart = false;
  bool _loggedCommitVisible = false;

  @override
  void initState() {
    super.initState();
    Logger.d('OnlineWebPage', '页面创建');
  }

  String _buildUrl() {
    return widget.url;
  }

  @override
  void dispose() {
    _sw.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.networkLoading),
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
            if (!_loggedCreate) {
              PerformanceMonitor.instance.recordWebViewCreated();
              _loggedCreate = true;
            }
          },
          onLoadStart: (controller, url) {
            Logger.d('OnlineWebPage', '开始加载');
            if (!_loggedLoadStart) {
              PerformanceMonitor.instance.recordLoadStart(
                LoadingMode.network,
                url.toString(),
              );
              _loggedLoadStart = true;
            }
          },
          onPageCommitVisible: (controller, url) {
            if (!_loggedCommitVisible) {
              Logger.d('OnlineWebPage', '首帧可见');
              PerformanceMonitor.instance.recordFirstPaint();
              _loggedCommitVisible = true;
            }
          },
          onLoadStop: (controller, url) {
            Logger.i('OnlineWebPage', '加载完成');
            PerformanceMonitor.instance.recordLoadComplete(_sw.elapsedMilliseconds);
          },
        ),
      ),
    );
  }
}