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
  /// 全局开关，控制面板是否渲染悬浮卡片。默认禁用。
  static bool enabled = false;

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
  /// 当前活跃的面板实例，确保同时只有一个可见
  static _FloatingPerformancePanelState? _activeInstance;

  late Offset _position;
  bool _panelVisible = true;

  /// 当前最新的加载记录（每个 WebView 只显示一条）
  LoadingTimeline? _latestTimeline;

  StreamSubscription<LoadingTimeline>? _subscription;

  @override
  void initState() {
    super.initState();
    _position = widget.initialOffset;
    // 隐藏前一个活跃面板，保证只有一个可见
    _activeInstance?._forceHide();
    _activeInstance = this;
    _subscription = PerformanceMonitor.instance.timelineStream.listen((tl) {
      if (mounted) {
        setState(() {
          _latestTimeline = tl;
        });
      }
    });
  }

  @override
  void dispose() {
    if (_activeInstance == this) {
      _activeInstance = null;
    }
    _subscription?.cancel();
    super.dispose();
  }

  void _forceHide() {
    if (mounted) {
      setState(() => _panelVisible = false);
    }
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
    if (!FloatingPerformancePanel.enabled) {
      return widget.child ?? const SizedBox.shrink();
    }

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
    final tl = _latestTimeline;
    if (tl == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          '等待加载...',
          style: TextStyle(fontSize: 10, color: Colors.white38),
        ),
      );
    }

    return _buildTimelineItem(tl);
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
          // 阶段耗时（按加载流程排序：离线阶段 → WebView生命周期）
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (tl.isOffline) ...[
                _buildStageChip('查询', '${tl.queryMs ?? 0}ms',
                    success: tl.querySuccess),
                _buildStageChip('下载', '${tl.downloadMs ?? 0}ms',
                    success: tl.downloadSuccess),
                _buildStageChip('解压', '${tl.unzipMs ?? 0}ms',
                    success: tl.unzipSuccess),
                _buildStageChip('WebView创建', '${tl.webViewCreatedMs}ms'),
                _buildStageChip('开始加载', '${tl.loadStartMs}ms'),
                _buildStageChip('首帧', '${tl.firstPaintMs}ms'),
                _buildStageChip('加载完成', '${tl.loadCompleteMs}ms'),
              ] else ...[
                _buildStageChip('WebView创建', '${tl.webViewCreatedMs}ms'),
                _buildStageChip('开始加载', '${tl.loadStartMs}ms'),
                _buildStageChip('首帧', '${tl.firstPaintMs}ms'),
                _buildStageChip('加载完成', '${tl.loadCompleteMs}ms'),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStageChip(String label, String value, {bool? success}) {
    // 提取数值用于颜色分级
    final numericValue = int.tryParse(value.replaceAll('ms', '')) ?? 0;
    Color valueColor;
    if (numericValue == 0) {
      valueColor = Colors.white38; // 无数据
    } else if (numericValue < 50) {
      valueColor = Colors.greenAccent; // 快
    } else if (numericValue < 200) {
      valueColor = Colors.lightBlueAccent; // 中等
    } else if (numericValue < 500) {
      valueColor = Colors.yellowAccent; // 较慢
    } else {
      valueColor = Colors.deepOrangeAccent; // 慢
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