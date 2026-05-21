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
    _resetAllState();
  }

  /// 记录首帧可见时间点
  void recordFirstPaint() {
    _firstPaintMs = DateTime.now().millisecondsSinceEpoch;
  }

  /// 记录页面加载完成，并发送完整 Timeline 到 Stream
  void recordLoadComplete(int totalMs) {
    if (_loadStartMs == 0) return; // guard against missing recordLoadStart

    _loadCompleteMs = DateTime.now().millisecondsSinceEpoch;

    // 计算各阶段耗时（使用同一时间源，避免不一致）
    final webViewCreated = _webViewCreatedMs > 0 ? _loadStartMs - _webViewCreatedMs : 0;
    final firstPaint = _firstPaintMs > _loadStartMs ? _firstPaintMs - _loadStartMs : 0;
    final loadComplete = _loadCompleteMs - _loadStartMs;

    final timeline = LoadingTimeline(
      mode: _currentMode,
      totalMs: totalMs,
      webViewCreatedMs: webViewCreated,
      firstPaintMs: firstPaint,
      loadCompleteMs: loadComplete,
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

  void _resetAllState() {
    _webViewCreatedMs = 0;
    _loadStartMs = 0;
    _firstPaintMs = 0;
    _loadCompleteMs = 0;
    _resetOfflinePhase();
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