import 'package:flutter/material.dart';

/// 可拖拽隐藏的底部监控面板。
///
/// 拖拽向下时面板收起只显示顶栏，
/// 拖拽向上时面板展开显示全部内容。
class DraggableMonitorPanel extends StatefulWidget {
  final Widget collapsedContent;
  final Widget expandedContent;
  final double expandedHeight;
  final double collapsedHeight;
  final bool initiallyExpanded;

  const DraggableMonitorPanel({
    super.key,
    required this.collapsedContent,
    required this.expandedContent,
    this.expandedHeight = 120,
    this.collapsedHeight = 44,
    this.initiallyExpanded = false,
  });

  @override
  State<DraggableMonitorPanel> createState() => _DraggableMonitorPanelState();
}

class _DraggableMonitorPanelState extends State<DraggableMonitorPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _heightAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _animController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
      value: _isExpanded ? 1.0 : 0.0,
    );
    _heightAnimation = Tween<double>(
      begin: widget.collapsedHeight,
      end: widget.expandedHeight,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void expand() {
    if (!_isExpanded) {
      setState(() => _isExpanded = true);
      _animController.forward();
    }
  }

  void collapse() {
    if (_isExpanded) {
      setState(() => _isExpanded = false);
      _animController.reverse();
    }
  }

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AnimatedBuilder(
      animation: _heightAnimation,
      builder: (context, child) {
        final contentHeight = _heightAnimation.value;
        return Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.velocity.pixelsPerSecond.dy > 300) {
                collapse();
              } else if (details.velocity.pixelsPerSecond.dy < -300) {
                expand();
              } else {
                _toggle();
              }
            },
            onTap: _toggle,
            child: SizedBox(
              height: contentHeight + bottomPadding,
              child: Container(
                padding: EdgeInsets.only(bottom: bottomPadding),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade900.withValues(alpha: 0.95),
                  borderRadius: _isExpanded
                      ? const BorderRadius.vertical(top: Radius.circular(16))
                      : BorderRadius.zero,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: _isExpanded
                    ? widget.expandedContent
                    : widget.collapsedContent,
              ),
            ),
          ),
        );
      },
    );
  }
}