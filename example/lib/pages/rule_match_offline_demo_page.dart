import 'package:flutter/material.dart';
import 'package:offline_webview/offline_webview.dart';

import '../config.dart';
import '../widgets/draggable_monitor_panel.dart';

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
  int _totalTime = 0;
  bool _isLocalLoading = true;

  /// 原始 URL，不包含 offweb 参数。
  /// 规则引擎将匹配 host 并注入 offweb 参数。
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
      body: Stack(
        children: [
          OfflineWebView(
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
                _totalTime = elapsed;
                _status = '加载完成: ${url?.toString() ?? ""}';
                _isLocalLoading = url != null && LocalServer.isLocalServerUrl(url.toString());
              });
            },
            onReceivedError: (controller, error) {
              setState(() {
                _status = '加载错误: ${error?.description ?? "unknown"}';
              });
            },
            onLoadTiming: (totalMs) {
              setState(() => _totalTime = totalMs);
            },
          ),
          DraggableMonitorPanel(
            expandedHeight: 110,
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
      child: Column(
        children: [
          const SizedBox(height: 4),
          if (_isLocalLoading)
            _buildMetricsRow()
          else
            const Center(
              child: Text(
                '网络加载，无离线包阶段数据',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow() {
    return Row(
      children: [
        _buildMetricChip('查询', 0),
        const SizedBox(width: 8),
        _buildMetricChip('下载', 0),
        const SizedBox(width: 8),
        _buildMetricChip('解压', 0),
      ],
    );
  }

  Widget _buildModeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _isLocalLoading
            ? Colors.green.withValues(alpha: 0.25)
            : Colors.blue.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isLocalLoading ? Colors.green : Colors.blue,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isLocalLoading ? Icons.folder_off : Icons.cloud,
            size: 12,
            color: _isLocalLoading ? Colors.greenAccent : Colors.lightBlueAccent,
          ),
          const SizedBox(width: 4),
          Text(
            _isLocalLoading ? '本地' : '网络',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _isLocalLoading ? Colors.greenAccent : Colors.lightBlueAccent,
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

  Widget _buildMetricChip(String label, int duration) {
    final text = duration > 0 ? '${duration}ms' : '无';

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 6),
            Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}