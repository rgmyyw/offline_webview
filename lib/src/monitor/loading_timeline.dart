/// 单次加载的完整时序数据
class LoadingTimeline {
  /// 加载模式
  final LoadingMode mode;

  /// 页面地址
  final String url;

  /// WebView 创建耗时（从组件创建到 WebView 创建好）
  final int webViewCreatedMs;

  /// URL 开始加载耗时
  final int loadStartMs;

  /// 首帧可见耗时
  final int firstPaintMs;

  /// 页面加载完成耗时
  final int loadCompleteMs;

  /// 总耗时（从 WebView 创建到加载完成）
  final int totalMs;

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
    required this.url,
    this.webViewCreatedMs = 0,
    this.loadStartMs = 0,
    this.firstPaintMs = 0,
    this.loadCompleteMs = 0,
    this.totalMs = 0,
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
    return 'LoadingTimeline(mode: $mode, url: $url, '
        'webView: $webViewCreatedMs, start: $loadStartMs, '
        'firstPaint: $firstPaintMs, complete: $loadCompleteMs, total: $totalMs, '
        'query: $queryMs, download: $downloadMs, unzip: $unzipMs)';
  }
}