import 'dart:async';
import 'package:flutter/material.dart';
import 'loading_timeline.dart';
import 'performance_monitor.dart';

/// 包裹子组件并在上面显示性能监控面板的包装器.
///
/// 使用方式：
/// ```dart
/// FloatingPerformancePanel(
///   child: SomePageWithWebView(),
/// )
/// ```
///
/// 面板默认显示在右上角，可拖动。订阅 [PerformanceMonitor.timelineStream]
/// 实时展示离线加载与网络加载的各阶段耗时对比。
class FloatingPerformancePanel extends StatefulWidget {
  /// 被包裹的子组件（通常是包含 WebView 的页面）
  final Widget child;

  /// 面板初始位置偏移量（默认右上角）
  final Offset initialOffset;

  const FloatingPerformancePanel({
    super.key,
    required this.child,
    this.initialOffset = const Offset(16, 60),
  });

  @override
  State<FloatingPerformancePanel> createState() =>
      _FloatingPerformancePanelState();
}

class _FloatingPerformancePanelState extends State<FloatingPerformancePanel> {
  late Offset _position;
  bool _panelVisible = true;

  LoadingTimeline? _offlineTimeline;
  LoadingTimeline? _networkTimeline;

  StreamSubscription<LoadingTimeline>? _subscription;

  @override
  void initState() {
    super.initState();
    _position = widget.initialOffset;
    _subscription = PerformanceMonitor.instance.timelineStream.listen((tl) {
      if (mounted) {
        setState(() {
          if (tl.isOffline) {
            _offlineTimeline = tl;
          } else {
            _networkTimeline = tl;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _position = Offset(
        _position.dx + details.delta.dx,
        _position.dy + details.delta.dy,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_panelVisible) _buildPanel(context),
      ],
    );
  }

  Widget _buildPanel(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      right: _position.dx,
      top: _position.dy + topPadding,
      child: GestureDetector(
        onPanUpdate: _onPanUpdate,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 260,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade900.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 8),
                _buildComparison(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.speed, size: 16, color: Colors.white70),
        const SizedBox(width: 6),
        const Expanded(
          child: Text(
            'Performance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => _panelVisible = false),
          child: const Icon(Icons.close, size: 16, color: Colors.white38),
        ),
      ],
    );
  }

  Widget _buildComparison() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildTimelineCard('离线', _offlineTimeline, Colors.green),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTimelineCard('网络', _networkTimeline, Colors.blue),
        ),
      ],
    );
  }

  Widget _buildTimelineCard(
    String label,
    LoadingTimeline? tl,
    Color accent,
  ) {
    if (tl == null) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '-',
              style: TextStyle(fontSize: 12, color: Colors.white38),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          _buildMetricRow('总耗时', '${tl.totalMs}ms'),
          if (tl.isOffline) ...[
            _buildMetricRow('查询', '${tl.queryMs ?? 0}ms',
                success: tl.querySuccess),
            _buildMetricRow('下载', '${tl.downloadMs ?? 0}ms',
                success: tl.downloadSuccess),
            _buildMetricRow('解压', '${tl.unzipMs ?? 0}ms',
                success: tl.unzipSuccess),
          ],
          _buildMetricRow('首帧', '${tl.firstPaintMs}ms'),
          _buildMetricRow('完成', '${tl.loadCompleteMs}ms'),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, {bool? success}) {
    Color valueColor = Colors.white;
    if (success == true) {
      valueColor = Colors.greenAccent;
    } else if (success == false) {
      valueColor = Colors.orangeAccent;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.white54),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              color: valueColor,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}