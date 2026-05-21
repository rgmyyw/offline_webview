# Performance Monitor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** SDK 内部性能监控模块，在 Debug 模式下以可拖动悬浮面板展示离线加载与网络加载的各阶段耗时对比。

**Architecture:** `PerformanceMonitor` 单例作为数据中枢，通过 `Stream` 向 `FloatingPerformancePanel` 推送 `LoadingTimeline`。`OfflineWebView` 和各 `Flow` 组件调用 `PerformanceMonitor` 记录各阶段时间点。

**Tech Stack:** Dart/Flutter, InAppWebView timing callbacks, Stopwatch, StreamController, Overlay

---

## File Structure

```
lib/src/monitor/
  loading_timeline.dart       # 数据模型
  performance_monitor.dart    # 单例，数据收集与分发
  floating_performance_panel.dart  # 可拖动悬浮面板

lib/offline_webview.dart     # 导出新组件
```

---

## Task 1: Create LoadingTimeline Data Model

**Files:**
- Create: `lib/src/monitor/loading_timeline.dart`

- [ ] **Step 1: Create the file**

```dart
/// 加载模式
enum LoadingMode { offline, network }

/// 单次加载的完整时序数据
class LoadingTimeline {
  /// 加载模式
  final LoadingMode mode;

  /// WebView 总耗时（从创建到加载完成）
  final int totalMs;

  /// WebView 创建到加载开始的耗时
  final int webViewCreatedMs;

  /// 首帧可见耗时
  final int firstPaintMs;

  /// 页面加载完成耗时
  final int loadCompleteMs;

  /// 离线模式阶段耗时（仅 offline 模式有值）
  final int? queryMs;
  final int? downloadMs;
  final int? unzipMs;

  /// 离线阶段是否成功
  final bool? querySuccess;
  final bool? downloadSuccess;
  final bool? unzipSuccess;

  const LoadingTimeline({
    required this.mode,
    required this.totalMs,
    this.webViewCreatedMs = 0,
    this.firstPaintMs = 0,
    this.loadCompleteMs = 0,
    this.queryMs,
    this.downloadMs,
    this.unzipMs,
    this.querySuccess,
    this.downloadSuccess,
    this.unzipSuccess,
  });

  bool get isOffline => mode == LoadingMode.offline;

  @override
  String toString() {
    return 'LoadingTimeline(mode: $mode, totalMs: $totalMs, '
        'webViewCreated: $webViewCreatedMs, firstPaint: $firstPaintMs, '
        'loadComplete: $loadCompleteMs, '
        'query: $queryMs, download: $downloadMs, unzip: $unzipMs)';
  }
}
```

- [ ] **Step 2: Commit**

---

## Task 2: Create PerformanceMonitor Singleton

**Files:**
- Create: `lib/src/monitor/performance_monitor.dart`

- [ ] **Step 1: Create the PerformanceMonitor singleton**

```dart
import 'dart:async';
import 'loading_timeline.dart';

/// SDK 内部性能监控单例.
///
/// 收集离线加载和网络加载的各阶段耗时，通过 [timelineStream] 分发数据。
/// [FloatingPerformancePanel] 订阅此 Stream 展示实时指标。
class PerformanceMonitor {
  static final PerformanceMonitor instance = PerformanceMonitor._();

  PerformanceMonitor._();

  final _controller = StreamController<LoadingTimeline>.broadcast();

  /// 实时 timeline 流，Panel 订阅此 Stream
  Stream<LoadingTimeline> get timelineStream => _controller.stream;

  // --- 离线加载状态 ---

  LoadingMode _currentMode = LoadingMode.network;
  int _webViewCreatedMs = 0;
  int _loadStartMs = 0;
  int _firstPaintMs = 0;
  int _loadCompleteMs = 0;

  int? _queryMs;
  int? _downloadMs;
  int? _unzipMs;
  bool? _querySuccess;
  bool? _downloadSuccess;
  bool? _unzipSuccess;

  /// 当前加载模式
  LoadingMode get currentMode => _currentMode;

  // --- WebView 生命周期记录 ---

  /// 记录 WebView 创建时间点
  void recordWebViewCreated() {
    _webViewCreatedMs = DateTime.now().millisecondsSinceEpoch;
  }

  /// 记录加载开始时间点，并设置加载模式
  void recordLoadStart(LoadingMode mode) {
    _currentMode = mode;
    _loadStartMs = DateTime.now().millisecondsSinceEpoch;
    _resetOfflinePhase();
  }

  /// 记录首帧可见时间点
  void recordFirstPaint() {
    _firstPaintMs = DateTime.now().millisecondsSinceEpoch;
  }

  /// 记录页面加载完成，并发送完整 Timeline 到 Stream
  void recordLoadComplete(int totalMs) {
    _loadCompleteMs = DateTime.now().millisecondsSinceEpoch;

    final timeline = LoadingTimeline(
      mode: _currentMode,
      totalMs: totalMs,
      webViewCreatedMs: _webViewCreatedMs > 0
          ? _loadStartMs - _webViewCreatedMs
          : 0,
      firstPaintMs: _firstPaintMs > 0 ? _firstPaintMs - _loadStartMs : 0,
      loadCompleteMs: _loadCompleteMs - _loadStartMs,
      queryMs: _queryMs,
      downloadMs: _downloadMs,
      unzipMs: _unzipMs,
      querySuccess: _querySuccess,
      downloadSuccess: _downloadSuccess,
      unzipSuccess: _unzipSuccess,
    );

    _controller.add(timeline);
  }

  // --- 离线阶段记录 ---

  /// 记录离线阶段耗时
  void recordOfflinePhase({
    required int queryMs,
    required int downloadMs,
    required int unzipMs,
    required bool querySuccess,
    required bool downloadSuccess,
    required bool unzipSuccess,
  }) {
    _queryMs = queryMs;
    _downloadMs = downloadMs;
    _unzipMs = unzipMs;
    _querySuccess = querySuccess;
    _downloadSuccess = downloadSuccess;
    _unzipSuccess = unzipSuccess;
  }

  void _resetOfflinePhase() {
    _queryMs = null;
    _downloadMs = null;
    _unzipMs = null;
    _querySuccess = null;
    _downloadSuccess = null;
    _unzipSuccess = null;
  }

  void dispose() {
    _controller.close();
  }
}
```

- [ ] **Step 2: Commit**

---

## Task 3: Create FloatingPerformancePanel Widget

**Files:**
- Create: `lib/src/monitor/floating_performance_panel.dart`

- [ ] **Step 1: Create the panel widget**

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'loading_timeline.dart';
import 'performance_monitor.dart';

/// 可拖动的性能监控悬浮面板.
///
/// 默认固定在右上角，通过 GestureDetector 拖动位置。
/// 订阅 [PerformanceMonitor.timelineStream] 展示实时数据。
class FloatingPerformancePanel extends StatefulWidget {
  const FloatingPerformancePanel({super.key});

  @override
  State<FloatingPerformancePanel> createState() =>
      _FloatingPerformancePanelState();
}

class _FloatingPerformancePanelState extends State<FloatingPerformancePanel> {
  Offset _position = const Offset(16, 60);
  bool _visible = true;

  LoadingTimeline? _offlineTimeline;
  LoadingTimeline? _networkTimeline;

  StreamSubscription<LoadingTimeline>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = PerformanceMonitor.instance.timelineStream.listen((tl) {
      setState(() {
        if (tl.isOffline) {
          _offlineTimeline = tl;
        } else {
          _networkTimeline = tl;
        }
      });
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
    if (!_visible) return const SizedBox.shrink();

    return Positioned(
      right: _position.dx,
      top: _position.dy,
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
          onTap: () => setState(() => _visible = false),
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
```

- [ ] **Step 2: Commit**

---

## Task 4: Integrate PerformanceMonitor into OfflineWebView

**Files:**
- Modify: `lib/src/widget/offline_web_view.dart`

- [ ] **Step 1: Add PerformanceMonitor to imports**

```dart
import '../monitor/performance_monitor.dart';
```

- [ ] **Step 2: Update onWebViewCreated to record creation time**

In `onWebViewCreated` callback, after `_proxy!.initialize(...)`:

```dart
PerformanceMonitor.instance.recordWebViewCreated();
```

- [ ] **Step 3: Update onLoadStart to detect mode and record**

Replace the existing `onLoadStart` callback content with:

```dart
onLoadStart: (controller, url) {
  if (!_loggedLoadStart) {
    Logger.d('OfflineWebView', 'onLoadStart: ${_sw.elapsedMilliseconds}ms');
    _loggedLoadStart = true;
  }
  final currentUrl = url?.toString() ?? '';
  if (currentUrl.isNotEmpty) {
    _controller.setCurrentUrl(currentUrl);
  }

  // 检测加载模式并记录
  final isLocal = currentUrl.isNotEmpty &&
      LocalServer.isLocalServerUrl(currentUrl);
  final mode = isLocal ? LoadingMode.offline : LoadingMode.network;
  PerformanceMonitor.instance.recordLoadStart(mode);

  _dataReport.notifyWebEvent(
    DataReportEvent.webviewWillRequest,
    url,
    0,
    '',
  );
  widget.onLoadStart?.call(controller, url);
},
```

- [ ] **Step 4: Update onPageCommitVisible to record first paint**

```dart
onPageCommitVisible: (controller, url) {
  if (!_loggedCommitVisible) {
    Logger.i('OfflineWebView', '首帧可见: ${_sw.elapsedMilliseconds}ms');
    _loggedCommitVisible = true;
    PerformanceMonitor.instance.recordFirstPaint();
  }
},
```

- [ ] **Step 5: Update onLoadStop to record completion**

In `onLoadStop` callback, add at the end before `widget.onLoadStop?.call(...)`:

```dart
PerformanceMonitor.instance.recordLoadComplete(_sw.elapsedMilliseconds);
```

- [ ] **Step 6: Commit**

---

## Task 5: Update _TaskFlowListener to Use PerformanceMonitor

**Files:**
- Modify: `lib/src/task/offline_task_manager.dart:178-199`

- [ ] **Step 1: Replace the timing callback with PerformanceMonitor**

Replace the section that calls `OfflineWebManager.instance.timingBlock?.call(...)` with:

```dart
// 记录离线阶段耗时到 PerformanceMonitor
PerformanceMonitor.instance.recordOfflinePhase(
  queryMs: queryMs,
  downloadMs: downloadMs,
  unzipMs: unzipMs,
  querySuccess: params?.querySuccess ?? false,
  downloadSuccess: params?.downloadSuccess ?? false,
  unzipSuccess: params?.unzipSuccess ?? false,
);
```

- [ ] **Step 2: Commit**

---

## Task 6: Export from offline_webview.dart

**Files:**
- Modify: `lib/offline_webview.dart`

- [ ] **Step 1: Add exports**

```dart
export 'src/monitor/loading_timeline.dart';
export 'src/monitor/performance_monitor.dart';
export 'src/monitor/floating_performance_panel.dart';
```

- [ ] **Step 2: Commit**

---

## Task 7: Add Panel to Example App

**Files:**
- Modify: `example/lib/main.dart` (or relevant example page)

- [ ] **Step 1: Add FloatingPerformancePanel to the widget tree**

In the Scaffold or app's root widget:

```dart
stack: [
  // ... existing content ...
  const FloatingPerformancePanel(),
],
```

- [ ] **Step 2: Commit**

---

## Verification

After implementation:
1. Run the example app
2. Navigate to a page that uses `OfflineWebView`
3. Verify the performance panel appears in the top-right corner
4. Drag the panel to reposition it
5. Load an offline page — should see offline timing data
6. Load a network page — should see network timing data
7. Click X to close the panel

---

## Spec Coverage Check

- [x] 数据模型 LoadingTimeline — Task 1
- [x] PerformanceMonitor 单例 — Task 2
- [x] FloatingPerformancePanel 可拖动面板 — Task 3
- [x] OfflineWebView 集成 WebView 生命周期 — Task 4
- [x] _TaskFlowListener 集成离线阶段 — Task 5
- [x] SDK 导出 — Task 6
- [x] Example 集成 — Task 7