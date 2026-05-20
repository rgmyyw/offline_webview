import 'package:flutter/material.dart';
import 'package:offline_webview/offline_webview.dart';

/// 离线包加载监控面板，固定展示在WebView底部，覆盖形式。
/// 展示各阶段耗时、加载模式等核心指标。
class OfflineLoadMonitorPanel extends StatelessWidget {
  final FlowReportParams? params;
  final String? currentStatus;
  final bool isLocalLoading;

  const OfflineLoadMonitorPanel({
    super.key,
    this.params,
    this.currentStatus,
    this.isLocalLoading = true,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        margin: EdgeInsets.only(bottom: bottomPadding),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade900.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTopRow(),
                const SizedBox(height: 30),
                _buildMetricsRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      children: [
        _buildModeBadge(),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            currentStatus ?? '等待加载...',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _buildTotalTime(),
      ],
    );
  }

  Widget _buildModeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLocalLoading
            ? Colors.green.withValues(alpha: 0.25)
            : Colors.blue.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLocalLoading ? Colors.green : Colors.blue,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLocalLoading ? Icons.folder_off : Icons.cloud,
            size: 12,
            color: isLocalLoading ? Colors.greenAccent : Colors.lightBlueAccent,
          ),
          const SizedBox(width: 4),
          Text(
            isLocalLoading ? '本地' : '网络',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isLocalLoading
                  ? Colors.greenAccent
                  : Colors.lightBlueAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalTime() {
    final total = _calcTotalDuration(params);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        total > 0 ? '总计 ${total}ms' : '总计 -',
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildMetricsRow() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          _buildMetricChip('查询', params),
          const SizedBox(width: 8),
          _buildMetricChip('下载', params),
          const SizedBox(width: 8),
          _buildMetricChip('解压', params),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, FlowReportParams? params) {
    int duration = 0;
    bool? success;
    double? size;

    if (label == '查询') {
      duration = _calcDuration(params?.queryStartTime, params?.queryEndTime);
      success = params?.querySuccess;
    } else if (label == '下载') {
      duration = _calcDuration(
        params?.downloadStartTime,
        params?.downloadEndTime,
      );
      success = params?.downloadSuccess;
      size = params?.zipSize;
    } else if (label == '解压') {
      duration = _calcDuration(params?.unzipStartTime, params?.unzipEndTime);
      success = params?.unzipSuccess;
    }

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
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: success == true
                    ? Colors.greenAccent
                    : success == false
                    ? Colors.orangeAccent
                    : Colors.white,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
            if (size != null && size > 0) ...[
              const SizedBox(height: 4),
              Text(
                _formatSize(size),
                style: const TextStyle(fontSize: 10, color: Colors.white38),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatSize(double bytes) {
    if (bytes >= 1048576) {
      return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${bytes.toStringAsFixed(0)} B';
  }

  int _calcDuration(int? start, int? end) {
    if (start != null && end != null && end > start) {
      return end - start;
    }
    return 0;
  }

  int _calcTotalDuration(FlowReportParams? params) {
    if (params == null) return 0;
    return _calcDuration(params.queryStartTime, params.queryEndTime) +
        _calcDuration(params.downloadStartTime, params.downloadEndTime) +
        _calcDuration(params.unzipStartTime, params.unzipEndTime);
  }
}
