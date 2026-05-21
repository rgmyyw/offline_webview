import 'package:flutter/material.dart';
import 'package:offline_webview/offline_webview.dart';

import '../config.dart';

/// 简单演示页面：URL 包含 ?offweb=test-offline-package.
///
/// OfflineWebView 组件会自动拦截此 URL，
/// 如果离线包可用则加载离线包。
class ParamOfflineDemoPage extends StatefulWidget {
  const ParamOfflineDemoPage({super.key});

  @override
  State<ParamOfflineDemoPage> createState() => _ParamOfflineDemoPageState();
}

class _ParamOfflineDemoPageState extends State<ParamOfflineDemoPage> {
  String _status = '加载中...';
  final _controller = OfflineWebViewController();
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _status = '正在加载: ${_buildUrl()}';
  }

  String _buildUrl() {
    return '${AppConfig.baseUrl}/demo?offweb=${AppConfig.testBisName}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('离线加载模式'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _startTime = DateTime.now();
              _controller.reloadOfflineWeb();
            },
          ),
        ],
      ),
      body: OfflineWebView(
        initialUrl: _buildUrl(),
        controller: _controller,
        onLoadStart: (controller, url) {
          setState(() {
            _status = '加载中: ${url?.toString() ?? ""}';
          });
        },
        onLoadStop: (controller, url) {
          final elapsed = DateTime.now().difference(_startTime!).inMilliseconds;
          setState(() {
            _status = '加载完成: ${url?.toString() ?? ""}';
          });
          Logger.i('ParamOfflineDemoPage', '加载完成 (耗时: ${elapsed}ms)');
        },
        onReceivedError: (controller, error) {
          setState(() {
            _status = '加载错误: ${error?.description ?? "unknown"}';
          });
        },
      ),
    );
  }
}