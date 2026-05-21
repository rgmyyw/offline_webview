import 'package:flutter/material.dart';
import 'package:offline_webview/offline_webview.dart';

import '../widgets/draggable_monitor_panel.dart';

class OfflineWebPage extends StatelessWidget {
  final String visitUrl;

  const OfflineWebPage({
    super.key,
    required this.visitUrl,
  });

@override
  Widget build(BuildContext context) => _OfflineWebPage(visitUrl: visitUrl);
}

class _OfflineWebPage extends StatefulWidget {
  final String visitUrl;

  const _OfflineWebPage({required this.visitUrl});

  @override
  State<_OfflineWebPage> createState() => _OfflineWebPageState();
}

class _OfflineWebPageState extends State<_OfflineWebPage> {
  String _status = '加载中...';
  final _controller = OfflineWebViewController();
  DateTime? _startTime;
  late bool _isLocalLoading = LocalServer.isLocalServerUrl(
    OfflineWebView.resolveOfflineUrlSync(widget.visitUrl),
  );

  int _totalTime = 0;
  int _queryTime = 0;
  int _downloadTime = 0;
  int _unzipTime = 0;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _status = '正在加载: ${widget.visitUrl}';

    // 注册各阶段耗时回调
    OfflineWebManager.instance.setTimingBlock((queryMs, downloadMs, unzipMs) {
      Logger.d(
        'OfflineWebPage',
        'timingBlock 触发 => 查询:$queryMs ms 下载:$downloadMs ms 解压:$unzipMs ms',
      );
      setState(() {
        _queryTime = queryMs;
        _downloadTime = downloadMs;
        _unzipTime = unzipMs;
      });
    });
  }

  @override
  void dispose() {
    // 清除回调
    OfflineWebManager.instance.setTimingBlock(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('离线包模式'),
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
            initialUrl: widget.visitUrl,
            controller: _controller,
            onLoadStart: (controller, url) {
              setState(() {
                _status = '加载中: ${url?.toString() ?? ""}';
                _startTime = DateTime.now();
              });
            },
            onLoadStop: (controller, url) {
              final elapsed = DateTime.now()
                  .difference(_startTime!)
                  .inMilliseconds;
              setState(() {
                _status = '加载完成: ${url?.toString() ?? ""}';
                _isLocalLoading =
                    url != null && LocalServer.isLocalServerUrl(url.toString());
                Logger.i('OfflineWebPage', '加载完成 (耗时: ${elapsed}ms)');
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
            collapsedHeight: 40,
            initiallyExpanded: false,
            collapsedContent: _buildCollapsedContent(),
            expandedContent: _buildExpandedContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedContent() {
    return _buildStatusRow();
  }

  Widget _buildExpandedContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 20),
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
              _buildStatusRow(),
              if (_isLocalLoading || _queryTime > 0 || _downloadTime > 0 || _unzipTime > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _buildMetricsRow(),
                ),
            ],
      ),
    );
  }

  Widget _buildStatusRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
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

  Widget _buildMetricsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _buildMetricChip('查询', _queryTime),
          const SizedBox(width: 6),
          _buildMetricChip('下载', _downloadTime),
          const SizedBox(width: 6),
          _buildMetricChip('解压', _unzipTime),
        ],
      ),
    );
  }

  Widget _buildModeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
            color: _isLocalLoading
                ? Colors.greenAccent
                : Colors.lightBlueAccent,
          ),
          const SizedBox(width: 4),
          Text(
            _isLocalLoading ? '本地' : '网络',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _isLocalLoading
                  ? Colors.greenAccent
                  : Colors.lightBlueAccent,
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              text,
              style: const TextStyle(
                fontSize: 13,
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
