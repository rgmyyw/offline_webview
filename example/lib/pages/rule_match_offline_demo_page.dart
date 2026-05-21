import 'package:flutter/material.dart';
import 'package:offline_webview/offline_webview.dart';

import '../config.dart';

/// 完整演示页面：演示基于规则的 URL 匹配.
///
/// URL 中不包含 `offweb` 参数。而是通过 [OfflineRuleConfig]
/// 设置按 host/path 模式匹配 URL 并自动注入 `offweb` 参数.
class RuleMatchOfflineDemoPage extends StatefulWidget {
  const RuleMatchOfflineDemoPage({super.key});

  @override
  State<RuleMatchOfflineDemoPage> createState() => _RuleMatchOfflineDemoPageState();
}

class _RuleMatchOfflineDemoPageState extends State<RuleMatchOfflineDemoPage> {
  String _status = '加载中...';
  final _controller = OfflineWebViewController();
  DateTime? _startTime;

  /// 原始 URL，不包含 offweb 参数.
  /// 规则引擎将匹配 host 并注入 offweb 参数.
  String get _originalUrl =>
      'http://${AppConfig.serverHost}:${AppConfig.serverPort}/demo';

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _status = '正在加载: $_originalUrl';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('规则匹配模式'),
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
        initialUrl: _originalUrl,
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
          Logger.i('RuleMatchOfflineDemoPage', '加载完成 (耗时: ${elapsed}ms)');
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