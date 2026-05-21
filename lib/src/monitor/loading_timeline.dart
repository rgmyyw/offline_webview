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