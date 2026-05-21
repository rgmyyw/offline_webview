import 'dart:async';
import 'loading_timeline.dart';

/// 离线阶段耗时数据结构
class _OfflinePhaseTiming {
  final int queryMs;
  final int downloadMs;
  final int unzipMs;
  final bool querySuccess;
  final bool downloadSuccess;
  final bool unzipSuccess;

  _OfflinePhaseTiming({
    required this.queryMs,
    required this.downloadMs,
    required this.unzipMs,
    required this.querySuccess,
    required this.downloadSuccess,
    required this.unzipSuccess,
  });
}

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

  // 加载状态
  LoadingMode _currentMode = LoadingMode.network;
  String _currentUrl = '';
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

  // WebView 生命周期记录

  /// 记录 WebView 创建时间点（每个 WebView 只调用一次）
  void recordWebViewCreated() {
    _webViewCreatedMs = DateTime.now().millisecondsSinceEpoch;
  }

  /// 记录加载开始时间点，并设置加载模式
  void recordLoadStart(LoadingMode mode, String url) {
    _currentMode = mode;
    _currentUrl = url;
    _loadStartMs = DateTime.now().millisecondsSinceEpoch;
    _firstPaintMs = 0;
    _loadCompleteMs = 0;
    // 不重置离线阶段数据（可能在 App 启动时提前完成）
  }

  /// 记录首帧可见时间点
  void recordFirstPaint() {
    _firstPaintMs = DateTime.now().millisecondsSinceEpoch;
  }

  /// 记录页面加载完成，并发送完整 Timeline 到 Stream
  void recordLoadComplete(int totalMs) {
    if (_loadStartMs == 0) return;

    _loadCompleteMs = DateTime.now().millisecondsSinceEpoch;

    // 计算各阶段耗时
    final webViewCreated = _webViewCreatedMs > 0 && _loadStartMs > _webViewCreatedMs
        ? _loadStartMs - _webViewCreatedMs
        : 0;
    final firstPaint = _firstPaintMs > _loadStartMs ? _firstPaintMs - _loadStartMs : 0;
    final loadComplete = _loadCompleteMs - _loadStartMs;

    final timeline = LoadingTimeline(
      mode: _currentMode,
      url: _currentUrl,
      webViewCreatedMs: webViewCreated,
      loadStartMs: 0,
      firstPaintMs: firstPaint,
      loadCompleteMs: loadComplete,
      totalMs: totalMs,
      queryMs: _queryMs,
      downloadMs: _downloadMs,
      unzipMs: _unzipMs,
      querySuccess: _querySuccess,
      downloadSuccess: _downloadSuccess,
      unzipSuccess: _unzipSuccess,
    );

    _controller.add(timeline);
  }

  // 离线阶段记录
  final Map<String, _OfflinePhaseTiming> _offlinePhaseCache = {};

  /// 记录离线阶段耗时
  void recordOfflinePhase({
    required int queryMs,
    required int downloadMs,
    required int unzipMs,
    required bool querySuccess,
    required bool downloadSuccess,
    required bool unzipSuccess,
    String? bisName,
  }) {
    if (bisName != null && bisName.isNotEmpty) {
      _offlinePhaseCache[bisName] = _OfflinePhaseTiming(
        queryMs: queryMs,
        downloadMs: downloadMs,
        unzipMs: unzipMs,
        querySuccess: querySuccess,
        downloadSuccess: downloadSuccess,
        unzipSuccess: unzipSuccess,
      );
    }
    _queryMs = queryMs;
    _downloadMs = downloadMs;
    _unzipMs = unzipMs;
    _querySuccess = querySuccess;
    _downloadSuccess = downloadSuccess;
    _unzipSuccess = unzipSuccess;
  }

  /// 获取指定 bisName 的离线阶段耗时
  _OfflinePhaseTiming? getOfflinePhaseTiming(String bisName) {
    return _offlinePhaseCache[bisName];
  }

  /// 消耗指定 bisName 的离线阶段耗时
  _OfflinePhaseTiming? consumeOfflinePhaseTiming(String bisName) {
    return _offlinePhaseCache.remove(bisName);
  }

  void dispose() {
    _controller.close();
  }
}