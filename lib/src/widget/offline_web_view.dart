import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:offline_webview/offline_webview.dart';
import 'package:path/path.dart' as p;

import '../core/offline_const.dart';
import '../core/offline_web_manager.dart';
import '../match/default_matcher.dart';
import '../monitor/performance_monitor.dart';
import '../monitor/loading_timeline.dart';
import '../server/local_server.dart';
import '../util/file_mgr.dart';
import '../match/off_web_rule_util.dart';
import '../monitor/data_report.dart';
import '../proxy/offline_web_view_proxy.dart';
import '../proxy/offline_web_view_proxy_factory.dart';
import '../util/html_cache.dart';
import '../util/off_web_log.dart';
import 'offline_web_view_controller.dart';

/// 包装[InAppWebView]以提供离线Web支持的StatefulWidget。
///
/// 离线包通过 [LocalServer] 提供的 HTTP localhost URL 加载，
/// 使用标准 URLRequest 导航，无需 file:// 特殊处理。
class OfflineWebView extends StatefulWidget {
  final String initialUrl;
  final OfflineWebViewController? controller;
  final void Function(InAppWebViewController, WebUri?)? onLoadStart;
  final void Function(InAppWebViewController, WebUri?)? onLoadStop;
  final void Function(InAppWebViewController, WebResourceError?)?
      onReceivedError;
  final PreferredSizeWidget? appBar;
  final void Function(int totalMs)? onLoadTiming;

  const OfflineWebView({
    super.key,
    required this.initialUrl,
    this.controller,
    this.onLoadStart,
    this.onLoadStop,
    this.onReceivedError,
    this.appBar,
    this.onLoadTiming,
  });

  @override
  State<OfflineWebView> createState() => _OfflineWebViewState();

  /// 同步解析在线 URL 为离线 HTTP localhost URL。
  /// 供 [OfflineWebClient.preloadWebView] 复用。
  static String resolveOfflineUrlSync(String url) {
    final manager = OfflineWebManager.instance;
    if (!manager.isInit) return url;

    final urlWithParam = OffWebRuleUtil.addOfflineParam(
      url,
      manager.ruleConfig,
    );

    if (!urlWithParam.contains(OfflineParam.offWeb)) return url;
    if (!urlWithParam.startsWith('http://') &&
        !urlWithParam.startsWith('https://')) {
      return url;
    }

    String bisName;
    try {
      final uri = Uri.parse(urlWithParam);
      bisName = uri.queryParameters[OfflineParam.offWeb] ?? '';
    } catch (_) {
      return url;
    }

    if (bisName.isEmpty) return url;
    if (manager.isDisable(bisName)) return url;

    return manager.matcher.matching(urlWithParam);
  }
}

class _OfflineWebViewState extends State<OfflineWebView> {
  late final OfflineWebViewController _controller;
  late final DataReport _dataReport;
  IOfflineWebViewProxy? _proxy;

  /// initState 中同步预解析的 URL。
  late final String _resolvedUrl;

  /// _resolvedUrl 是否来自本地服务器。
  late final bool _isLocalUrl;

  // --- 性能计时 ---
  late final Stopwatch _sw;
  bool _loggedCreate = false;
  bool _loggedLoadStart = false;
  bool _loggedCommitVisible = false;
  int _lastProgress = 0;

  /// 从 URL 中提取的业务名称。
  late final String _bisName;

  /// 离线包 cur 目录路径，用于 HtmlCache 读写。
  String? _curDirPath;

  // --- 截图缓存 ---
  Uint8List? _screenshotBytes;
  bool _showingScreenshot = false;
  bool _screenshotSaved = false;

  @override
  void initState() {
    super.initState();
    _sw = Stopwatch()..start();
    _controller = widget.controller ?? OfflineWebViewController();

    String bisName = '';
    try {
      final uri = Uri.parse(widget.initialUrl);
      bisName = uri.queryParameters[OfflineParam.offWeb] ?? '';
    } catch (_) {}
    _bisName = bisName;
    _dataReport = DataReport(bisName: bisName);

    _resolvedUrl = OfflineWebView.resolveOfflineUrlSync(widget.initialUrl);
    _isLocalUrl = LocalServer.isLocalServerUrl(_resolvedUrl);

    _curDirPath =
        bisName.isNotEmpty ? DefaultMatcher.getCurPath(bisName) : null;

    // 同步加载截图缓存（字节级，Image.memory 首帧立即可见）
    if (_curDirPath != null && _isLocalUrl) {
      final file = File(p.join(_curDirPath!, 'screenshot.png'));
      if (file.existsSync()) {
        _screenshotBytes = file.readAsBytesSync();
        _showingScreenshot = true;
        Logger.d('OfflineWebView', '截图缓存命中');

        // 安全超时：3 秒后强制隐藏截图
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _showingScreenshot) {
            Logger.w('OfflineWebView', '截图安全超时，强制隐藏');
            setState(() {
              _showingScreenshot = false;
              _screenshotBytes = null;
            });
          }
        });
      }
    }

    Logger.d(
      'OfflineWebView',
      '初始化完成: ${_sw.elapsedMilliseconds}ms, 本地URL=$_isLocalUrl',
    );
  }

  @override
  void dispose() {
    _proxy?.destroy();
    _controller.detach();
    super.dispose();
  }

  /// 将当前页面渲染后的 HTML 保存到缓存。
  void _saveHtmlCache(InAppWebViewController controller) async {
    try {
      final result = await controller.evaluateJavascript(
        source: 'document.documentElement.outerHTML',
      );
      if (result != null && result is String && result.isNotEmpty) {
        await HtmlCache.save(_curDirPath!, result);
        Logger.d('OfflineWebView', 'HTML缓存已保存');
      }
    } catch (e) {
      Logger.d('OfflineWebView', 'HTML缓存保存失败: $e');
    }
  }

  /// 保存首屏截图到离线包目录（仅初始URL首次加载时调用）。
  void _saveScreenshot(InAppWebViewController controller) async {
    if (_screenshotSaved || _bisName.isEmpty) return;
    _screenshotSaved = true;

    final bisDir = await FileMgr.getBisDir(_bisName);
    final curDirPath = p.join(bisDir, OfflineDirName.cur);

    final curDir = Directory(curDirPath);
    if (!curDir.existsSync()) {
      Logger.d('OfflineWebView', '跳过截图: curDir不存在 (离线包未安装)');
      return;
    }

    Logger.d('OfflineWebView', '_saveScreenshot 开始, curDir=$curDirPath');

    int attempt = 0;
    while (mounted) {
      attempt++;
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      try {
        final png = await controller.takeScreenshot(
          screenshotConfiguration: Platform.isAndroid
              ? ScreenshotConfiguration(quality: 100)
              : null,
        );
        if (png != null && png.length > 50000) {
          if (await _isSolidColor(png)) {
            Logger.d('OfflineWebView', '截图为纯色, 重试 (第 $attempt 次)');
            continue;
          }
          final file = File(p.join(curDirPath, 'screenshot.png'));
          await file.writeAsBytes(png);
          Logger.d(
            'OfflineWebView',
            '截图已保存: ${png.length} 字节 (第 $attempt 次尝试)',
          );
          return;
        }
        Logger.d(
          'OfflineWebView',
          '截图无效 (${png?.length ?? 0} 字节), 重试 (第 $attempt 次)',
        );
      } catch (e) {
        Logger.d('OfflineWebView', '截图失败, 重试 (第 $attempt 次): $e');
      }
    }
  }

  /// 检测截图是否为纯色（白屏等空白图片）。
  Future<bool> _isSolidColor(Uint8List pngBytes) async {
    try {
      final codec = await ui.instantiateImageCodec(
        pngBytes,
        targetWidth: 10,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return true;

      final pixels = byteData.buffer.asUint8List();
      final totalPixels = image.width * image.height;
      if (totalPixels == 0) return true;

      int sumR = 0, sumG = 0, sumB = 0;
      for (int i = 0; i < totalPixels; i++) {
        final offset = i * 4;
        sumR += pixels[offset];
        sumG += pixels[offset + 1];
        sumB += pixels[offset + 2];
      }

      final avgR = sumR / totalPixels;
      final avgG = sumG / totalPixels;
      final avgB = sumB / totalPixels;

      double totalDev = 0;
      for (int i = 0; i < totalPixels; i++) {
        final offset = i * 4;
        totalDev += (pixels[offset] - avgR).abs() +
            (pixels[offset + 1] - avgG).abs() +
            (pixels[offset + 2] - avgB).abs();
      }
      return totalDev / totalPixels < 5;
    } catch (_) {
      return false;
    }
  }

  /// 移除截图覆盖层。iOS 用 AnimatedOpacity 淡出，Android 瞬间移除。
  void _removeScreenshot() {
    if (!_showingScreenshot) return;
    Logger.d('OfflineWebView', '准备移除截图: ${_sw.elapsedMilliseconds}ms');
    if (Platform.isIOS) {
      setState(() => _showingScreenshot = false);
      Logger.d('OfflineWebView', '截图淡出开始: ${_sw.elapsedMilliseconds}ms');
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _screenshotBytes != null) {
          setState(() => _screenshotBytes = null);
          Logger.d('OfflineWebView', '截图已移除: ${_sw.elapsedMilliseconds}ms');
        }
      });
    } else {
      setState(() {
        _showingScreenshot = false;
        _screenshotBytes = null;
      });
      Logger.d('OfflineWebView', '截图瞬间移除: ${_sw.elapsedMilliseconds}ms');
    }
  }

  /// 截图移除控制。
  bool _screenshotRemoveTriggered = false;

  void _tryRemoveScreenshot() {
    Logger.d(
      'OfflineWebView',
      '_tryRemoveScreenshot: triggered=$_screenshotRemoveTriggered, '
      'showing=$_showingScreenshot, time=${_sw.elapsedMilliseconds}ms',
    );
    if (_screenshotRemoveTriggered || !_showingScreenshot) return;
    _screenshotRemoveTriggered = true;
    if (Platform.isAndroid) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) _removeScreenshot();
      });
    } else {
      _removeScreenshot();
    }
  }

  @override
  Widget build(BuildContext context) {
    Logger.d('OfflineWebView', '构建开始: ${_sw.elapsedMilliseconds}ms');

    final child = InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(_resolvedUrl)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        defaultFontSize: 16,
        useHybridComposition: false,
        transparentBackground: Platform.isAndroid,
      ),
      onWebViewCreated: (controller) {
        final ts = _sw.elapsedMilliseconds;
        if (!_loggedCreate) {
          Logger.d('OfflineWebView', 'onWebViewCreated: ${ts}ms');
          _loggedCreate = true;
        }
        _controller.attach(controller);
        _proxy = OfflineWebViewProxyFactory.create(controller: _controller);
        _proxy!.initialize(widget.initialUrl, _resolvedUrl);
        PerformanceMonitor.instance.recordWebViewCreated();
        _controller.setCurrentUrl(_resolvedUrl);
      },
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        final url = navigationAction.request.url?.toString() ?? '';
        if (url.isEmpty) return NavigationActionPolicy.ALLOW;

        // 本地服务器 URL 直接放行
        if (LocalServer.isLocalServerUrl(url)) {
          return NavigationActionPolicy.ALLOW;
        }

        final proxy = _proxy;
        if (proxy == null) return NavigationActionPolicy.ALLOW;

        final resolvedUrl = proxy.loadUrl(url);

        if (resolvedUrl != url) {
          await controller.loadUrl(
            urlRequest: URLRequest(url: WebUri(resolvedUrl)),
          );
          _controller.setCurrentUrl(resolvedUrl);
          return NavigationActionPolicy.CANCEL;
        }

        return NavigationActionPolicy.ALLOW;
      },
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
        PerformanceMonitor.instance.recordLoadStart(mode, currentUrl);

        _dataReport.notifyWebEvent(
          DataReportEvent.webviewWillRequest,
          url,
          0,
          '',
        );
        widget.onLoadStart?.call(controller, url);
      },
      onProgressChanged: (controller, progress) {
        if (progress > _lastProgress) {
          Logger.d(
            'OfflineWebView',
            'onProgressChanged: ${_sw.elapsedMilliseconds}ms progress=$progress',
          );
          _lastProgress = progress;
        }
        if (Platform.isAndroid && progress >= 100 && _showingScreenshot) {
          _tryRemoveScreenshot();
        }
      },
      onPageCommitVisible: (controller, url) {
        if (!_loggedCommitVisible) {
          Logger.i('OfflineWebView', '首帧可见: ${_sw.elapsedMilliseconds}ms');
          _loggedCommitVisible = true;
          PerformanceMonitor.instance.recordFirstPaint();
        }
      },
      onLoadStop: (controller, url) {
        Logger.i('OfflineWebView', '加载完成: ${_sw.elapsedMilliseconds}ms');
        final currentUrl = url?.toString() ?? '';
        if (currentUrl.isNotEmpty) {
          _controller.setCurrentUrl(currentUrl);
        }
        _dataReport.notifyWebEvent(
          DataReportEvent.webviewLoadSuccess,
          url,
          0,
          '',
        );
        if (_curDirPath != null && LocalServer.isLocalServerUrl(currentUrl)) {
          _saveHtmlCache(controller);
        }
        if (_bisName.isNotEmpty && !_screenshotSaved) {
          Logger.d(
            'OfflineWebView',
            '触发截屏: bisName=$_bisName, saved=$_screenshotSaved',
          );
          _saveScreenshot(controller);
        }
        if (_showingScreenshot) {
          if (Platform.isIOS) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) _tryRemoveScreenshot();
            });
          }
        }
        widget.onLoadStop?.call(controller, url);
        PerformanceMonitor.instance.recordLoadComplete(_sw.elapsedMilliseconds);
        widget.onLoadTiming?.call(_sw.elapsedMilliseconds);
      },
      onReceivedError: (controller, request, error) {
        if (request.isForMainFrame == true) {
          _dataReport.notifyWebEvent(
            DataReportEvent.webviewLoadFail,
            request.url,
            error.type.toNativeValue() ?? 0,
            error.description,
          );
          widget.onReceivedError?.call(controller, error);
        }
      },
      onReceivedHttpError: (controller, request, errorResponse) {
        _dataReport.notifyWebEvent(
          DataReportEvent.webviewReceiveResponse,
          request.url,
          errorResponse.statusCode ?? 0,
          errorResponse.reasonPhrase ?? '',
        );
      },
    );

    final body = Stack(
      children: [
        Container(color: Colors.white, child: child),
        if (_screenshotBytes != null)
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: _showingScreenshot ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: IgnorePointer(
                child: Image.memory(
                  _screenshotBytes!,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          ),
        const Positioned(
          right: 16,
          top: 60,
          child: FloatingPerformancePanel(),
        ),
      ],
    );
    Logger.d(
      'OfflineWebView',
      'build: ${_sw.elapsedMilliseconds}ms, '
      'screenshotBytes=${_screenshotBytes?.length ?? 'null'}, '
      'showing=$_showingScreenshot, platform=${Platform.operatingSystem}',
    );

    if (widget.appBar != null) {
      return Scaffold(
        appBar: widget.appBar,
        backgroundColor: Colors.white,
        body: body,
      );
    }

    return body;
  }
}
