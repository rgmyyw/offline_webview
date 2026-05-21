import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:offline_webview/offline_webview.dart';

import '../widgets/draggable_monitor_panel.dart';

/// 普通 WebView 页面，用于与离线加载进行速度对比。
/// 此页面直接加载 URL，不使用离线包拦截。
class OnlineWebPage extends StatefulWidget {
  final String url;

  const OnlineWebPage({super.key, this.url = 'https://www.baidu.com'});

  @override
  State<OnlineWebPage> createState() => _OnlineWebPageState();
}

class _OnlineWebPageState extends State<OnlineWebPage> {
  String _status = '加载中...';
  late InAppWebViewController _controller;
  DateTime? _startTime;
  int _totalTime = 0;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _status = '正在加载: ${_buildUrl()}';
    Logger.d('OnlineWebPage', '页面创建, 开始计时');
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
              _startTime = DateTime.now();
              _controller.reload();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(_buildUrl())),
            initialSettings: InAppWebViewSettings(
              useShouldOverrideUrlLoading: false,
              javaScriptEnabled: true,
            ),
            onWebViewCreated: (controller) {
              _controller = controller;
              final elapsed = DateTime.now()
                  .difference(_startTime!)
                  .inMilliseconds;
              Logger.d('OnlineWebPage', 'WebView创建: ${elapsed}ms');
            },
            onLoadStart: (controller, url) {
              final elapsed = DateTime.now()
                  .difference(_startTime!)
                  .inMilliseconds;
              Logger.d('OnlineWebPage', '开始加载: ${elapsed}ms');
              setState(() {
                _status = '加载中: ${url?.toString() ?? ""}';
              });
            },
            onLoadStop: (controller, url) {
              final elapsed = DateTime.now()
                  .difference(_startTime!)
                  .inMilliseconds;
              Logger.i('OnlineWebPage', '加载完成: ${elapsed}ms');
              setState(() {
                _totalTime = elapsed;
                _status = '加载完成: ${url?.toString() ?? ""}';
              });
            },
            onReceivedError: (controller, request, error) {
              if (request.isForMainFrame == true) {
                setState(() {
                  _status = '加载错误: ${error.description}';
                });
              }
            },
          ),
          DraggableMonitorPanel(
            expandedHeight: 80,
            collapsedHeight: 44,
            initiallyExpanded: false,
            collapsedContent: _buildCollapsedContent(),
            expandedContent: _buildExpandedContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildModeBadge(),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _status,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _buildTotalTime(),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Center(
        child: Text(
          _totalTime > 0 ? '加载耗时: ${_totalTime}ms' : '等待加载...',
          style: const TextStyle(fontSize: 13, color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildModeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue, width: 1),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud, size: 12, color: Colors.lightBlueAccent),
          SizedBox(width: 4),
          Text(
            '网络',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.lightBlueAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalTime() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _totalTime > 0 ? '总计 ${_totalTime}ms' : '总计 -',
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
