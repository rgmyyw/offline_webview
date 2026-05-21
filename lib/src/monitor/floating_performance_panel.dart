import 'dart:async';
import 'package:flutter/material.dart';
import 'loading_timeline.dart';
import 'performance_monitor.dart';

/// 性能监控悬浮面板.
///
/// 作为包装器使用：
/// ```dart
/// FloatingPerformancePanel(
///   child: SomePageWithWebView(),
/// )
/// ```
///
/// 或单独使用（由 OfflineWebView 内部嵌入）：
/// ```dart
/// FloatingPerformancePanel()
/// ```
///
/// 面板默认显示在右上角，可拖动。订阅 [PerformanceMonitor.timelineStream]
/// 实时展示加载各阶段耗时。
class FloatingPerformancePanel extends StatefulWidget {
  /// 被包裹的子组件（可选，如果不提供则只显示面板本身）
  final Widget? child;

  /// 面板初始位置偏移量（默认右上角）
  final Offset initialOffset;

  const FloatingPerformancePanel({
    super.key,
    this.child,
    this.initialOffset = const Offset(16, 60),
  });

  @override
  State<FloatingPerformancePanel> createState() =>
      _FloatingPerformancePanelState();
}

class _FloatingPerformancePanelState extends State<FloatingPerformancePanel> {
  late Offset _position;
  bool _panelVisible = true;

  /// 所有加载记录
  final List<LoadingTimeline> _timelines = [];

  StreamSubscription<LoadingTimeline>? _subscription;

  @override
  void initState() {
    super.initState();
    _position = widget.initialOffset;
    _subscription = PerformanceMonitor.instance.timelineStream.listen((tl) {
      if (mounted) {
        setState(() {
          _timelines.add(tl);
          // 只保留最近 10 条记录
          if (_timelines.length > 10) {
            _timelines.removeAt(0);
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
    final topPadding = MediaQuery.of(context).padding.top;

    final content = Stack(
      fit: StackFit.expand,
      children: [
        if (widget.child != null) widget.child!,
        if (_panelVisible)
          Positioned(
            right: _position.dx,
            top: _position.dy + topPadding,
            child: GestureDetector(
              onPanUpdate: _onPanUpdate,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 300,
                  constraints: const BoxConstraints(maxHeight: 400),
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
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 8),
                        _buildTimelineList(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    return content;
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

  Widget _buildTimelineList() {
    if (_timelines.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          '等待加载...',
          style: TextStyle(fontSize: 10, color: Colors.white38),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _timelines.reversed.map((tl) => _buildTimelineItem(tl)).toList(),
    );
  }

  Widget _buildTimelineItem(LoadingTimeline tl) {
    final accent = tl.isOffline ? Colors.green : Colors.blue;
    final modeLabel = tl.isOffline ? '离线' : '网络';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  modeLabel,
                  style: TextStyle(fontSize: 9, color: accent),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  tl.url,
                  style: const TextStyle(fontSize: 9, color: Colors.white54),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${tl.totalMs}ms',
                style: TextStyle(
                  fontSize: 10,
                  color: accent,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 阶段耗时
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildStageChip('WebView创建', '${tl.webViewCreatedMs}ms'),
              _buildStageChip('开始加载', '${tl.loadStartMs}ms'),
              _buildStageChip('首帧', '${tl.firstPaintMs}ms'),
              _buildStageChip('加载完成', '${tl.loadCompleteMs}ms'),
              if (tl.isOffline) ...[
                _buildStageChip('查询', '${tl.queryMs ?? 0}ms',
                    success: tl.querySuccess),
                _buildStageChip('下载', '${tl.downloadMs ?? 0}ms',
                    success: tl.downloadSuccess),
                _buildStageChip('解压', '${tl.unzipMs ?? 0}ms',
                    success: tl.unzipSuccess),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStageChip(String label, String value, {bool? success}) {
    Color valueColor = Colors.white;
    if (success == true) {
      valueColor = Colors.greenAccent;
    } else if (success == false) {
      valueColor = Colors.orangeAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 9, color: Colors.white54),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 9,
              color: valueColor,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}