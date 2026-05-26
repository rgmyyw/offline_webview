import 'dart:collection';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:offline_webview/offline_webview.dart';
import 'package:path/path.dart' as p;

/// WebView 设置的类型别名
typedef OfflineWebViewSettings = InAppWebViewSettings;

/// WebView 初始数据的类型别名。
typedef OfflineWebViewInitialData = InAppWebViewInitialData;

/// WebView 保活标识的类型别名。
typedef OfflineWebViewKeepAlive = InAppWebViewKeepAlive;

/// WebView 点击测试结果的类型别名。
typedef OfflineWebViewHitTestResult = InAppWebViewHitTestResult;

/// 提供离线 Web 支持的 StatefulWidget。
///
/// 离线包通过 [LocalServer] 提供的 HTTP localhost URL 加载，
/// 使用标准 URLRequest 导航，无需 file:// 特殊处理。
class OfflineWebView extends StatefulWidget {
  /// 在线 URL，会自动解析为离线 HTTP localhost URL。
  final String initialUrl;

  /// 离线 WebView 控制器。
  final OfflineWebViewController? controller;

  /// 可选的 AppBar，传入后会自动包裹 Scaffold。
  final PreferredSizeWidget? appBar;

  /// 加载耗时回调（毫秒）。
  final void Function(int totalMs)? onLoadTiming;

  /// 是否启用 vConsole 调试面板，默认关闭。
  final bool enableVConsole;

  /// 手势识别器集合，用于自定义 WebView 的手势行为。
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  /// WebView 窗口 ID，用于多窗口场景。
  final int? windowId;

  /// 无头 WebView 实例，用于在后台预加载页面。
  final HeadlessInAppWebView? headlessWebView;

  /// WebView 保活标识，避免 WebView 被意外回收。
  final OfflineWebViewKeepAlive? keepAlive;

  /// 是否阻止手势延迟。
  final bool? preventGestureDelay;

  /// 布局方向。
  final TextDirection? layoutDirection;

  /// WebView 运行环境，用于自定义 WebView 引擎配置。
  final WebViewEnvironment? webViewEnvironment;

  /// WebView 初始数据。若提供，优先级高于 [initialUrl]。
  final OfflineWebViewInitialData? initialData;

  /// WebView 初始本地 HTML 文件。若提供，优先级高于 [initialUrl]。
  final String? initialFile;

  /// WebView 初始设置。优先使用调用方传递的值，未设置的字段使用默认值。
  /// 默认: javaScriptEnabled=true, defaultFontSize=16,
  ///       useHybridComposition=false, transparentBackground=Platform.isAndroid
  final OfflineWebViewSettings? initialSettings;

  /// WebView 初始用户脚本列表。
  final UnmodifiableListView<UserScript>? initialUserScripts;

  /// 下拉刷新控制器。
  final PullToRefreshController? pullToRefreshController;

  /// 页面内查找交互控制器。
  final FindInteractionController? findInteractionController;

  /// 上下文菜单配置。
  final ContextMenu? contextMenu;

  /// 页面开始加载回调
  final void Function(InAppWebViewController controller, WebUri? url)?
  onLoadStart;

  /// 页面加载完成回调
  final void Function(InAppWebViewController controller, WebUri? url)?
  onLoadStop;

  /// 简化签名的错误回调，仅传递 controller 和 error。
  final void Function(InAppWebViewController, WebResourceError?)?
  onReceivedError;

  /// WebView 创建完成回调
  final void Function(InAppWebViewController controller)? onWebViewCreated;

  /// URL 加载拦截回调
  final Future<NavigationActionPolicy?> Function(
    InAppWebViewController controller,
    NavigationAction navigationAction,
  )?
  shouldOverrideUrlLoading;

  /// 加载进度变化回调
  final void Function(InAppWebViewController controller, int progress)?
  onProgressChanged;

  /// 页面内容首次可见回调
  final void Function(InAppWebViewController controller, WebUri? url)?
  onPageCommitVisible;

  /// HTTP 错误回调
  final void Function(
    InAppWebViewController controller,
    WebResourceRequest request,
    WebResourceResponse errorResponse,
  )?
  onReceivedHttpError;

  /// 页面标题变化回调。
  final void Function(InAppWebViewController controller, String? title)?
  onTitleChanged;

  /// Ajax 请求进度回调。
  final Future<AjaxRequestAction> Function(
    InAppWebViewController controller,
    AjaxRequest ajaxRequest,
  )?
  onAjaxProgress;

  /// Ajax readyState 变化回调。
  final Future<AjaxRequestAction?> Function(
    InAppWebViewController controller,
    AjaxRequest ajaxRequest,
  )?
  onAjaxReadyStateChange;

  /// 控制台消息回调。
  final void Function(
    InAppWebViewController controller,
    ConsoleMessage consoleMessage,
  )?
  onConsoleMessage;

  /// 新窗口创建回调。
  final Future<bool?> Function(
    InAppWebViewController controller,
    CreateWindowAction createWindowAction,
  )?
  onCreateWindow;

  /// 窗口关闭回调。
  final void Function(InAppWebViewController controller)? onCloseWindow;

  /// 窗口获得焦点回调。
  final void Function(InAppWebViewController controller)? onWindowFocus;

  /// 窗口失去焦点回调。
  final void Function(InAppWebViewController controller)? onWindowBlur;

  /// 下载开始请求回调。
  final void Function(
    InAppWebViewController controller,
    DownloadStartRequest downloadStartRequest,
  )?
  onDownloadStartRequest;

  /// JavaScript alert 弹窗回调。
  final Future<JsAlertResponse?> Function(
    InAppWebViewController controller,
    JsAlertRequest jsAlertRequest,
  )?
  onJsAlert;

  /// JavaScript confirm 弹窗回调。
  final Future<JsConfirmResponse?> Function(
    InAppWebViewController controller,
    JsConfirmRequest jsConfirmRequest,
  )?
  onJsConfirm;

  /// JavaScript prompt 弹窗回调。
  final Future<JsPromptResponse?> Function(
    InAppWebViewController controller,
    JsPromptRequest jsPromptRequest,
  )?
  onJsPrompt;

  /// 资源加载完成回调。
  final void Function(
    InAppWebViewController controller,
    LoadedResource resource,
  )?
  onLoadResource;

  /// 自定义协议资源加载回调。
  final Future<CustomSchemeResponse?> Function(
    InAppWebViewController controller,
    WebResourceRequest request,
  )?
  onLoadResourceWithCustomScheme;

  /// 长按点击测试结果回调。
  final void Function(
    InAppWebViewController controller,
    OfflineWebViewHitTestResult hitTestResult,
  )?
  onLongPressHitTestResult;

  /// 打印请求回调。
  final Future<bool?> Function(
    InAppWebViewController controller,
    WebUri? url,
    PlatformPrintJobController? printJobController,
  )?
  onPrintRequest;

  /// 客户端证书请求回调。
  final Future<ClientCertResponse?> Function(
    InAppWebViewController controller,
    URLAuthenticationChallenge challenge,
  )?
  onReceivedClientCertRequest;

  /// HTTP 认证请求回调。
  final Future<HttpAuthResponse?> Function(
    InAppWebViewController controller,
    URLAuthenticationChallenge challenge,
  )?
  onReceivedHttpAuthRequest;

  /// 服务器信任认证请求回调。
  final Future<ServerTrustAuthResponse?> Function(
    InAppWebViewController controller,
    URLAuthenticationChallenge challenge,
  )?
  onReceivedServerTrustAuthRequest;

  /// 滚动位置变化回调。
  final void Function(InAppWebViewController controller, int x, int y)?
  onScrollChanged;

  /// 浏览历史更新回调。
  final void Function(
    InAppWebViewController controller,
    WebUri? url,
    bool? isReload,
  )?
  onUpdateVisitedHistory;

  /// Ajax 请求拦截回调。
  final Future<AjaxRequest?> Function(
    InAppWebViewController controller,
    AjaxRequest ajaxRequest,
  )?
  shouldInterceptAjaxRequest;

  /// Fetch 请求拦截回调。
  final Future<FetchRequest?> Function(
    InAppWebViewController controller,
    FetchRequest fetchRequest,
  )?
  shouldInterceptFetchRequest;

  /// 进入全屏回调。
  final void Function(InAppWebViewController controller)? onEnterFullscreen;

  /// 退出全屏回调。
  final void Function(InAppWebViewController controller)? onExitFullscreen;

  /// 过度滚动回调。
  final void Function(
    InAppWebViewController controller,
    int x,
    int y,
    bool clampedX,
    bool clampedY,
  )?
  onOverScrolled;

  /// 缩放比例变化回调。
  final void Function(
    InAppWebViewController controller,
    double oldScale,
    double newScale,
  )?
  onZoomScaleChanged;

  /// 导航响应回调（iOS/macOS）。
  final Future<NavigationResponseAction?> Function(
    InAppWebViewController controller,
    NavigationResponse navigationResponse,
  )?
  onNavigationResponse;

  /// 权限请求回调。
  final Future<PermissionResponse?> Function(
    InAppWebViewController controller,
    PermissionRequest permissionRequest,
  )?
  onPermissionRequest;

  /// 收到网站图标回调。
  final void Function(InAppWebViewController controller, Uint8List icon)?
  onReceivedIcon;

  /// 收到登录请求回调。
  final void Function(
    InAppWebViewController controller,
    LoginRequest loginRequest,
  )?
  onReceivedLoginRequest;

  /// 权限请求取消回调。
  final void Function(
    InAppWebViewController controller,
    PermissionRequest permissionRequest,
  )?
  onPermissionRequestCanceled;

  /// 请求焦点回调。
  final void Function(InAppWebViewController controller)? onRequestFocus;

  /// 收到触摸图标 URL 回调。
  final void Function(
    InAppWebViewController controller,
    WebUri url,
    bool precomposed,
  )?
  onReceivedTouchIconUrl;

  /// 渲染进程终止回调。
  final void Function(
    InAppWebViewController controller,
    RenderProcessGoneDetail detail,
  )?
  onRenderProcessGone;

  /// 渲染进程恢复响应回调。
  final Future<WebViewRenderProcessAction?> Function(
    InAppWebViewController controller,
    WebUri? url,
  )?
  onRenderProcessResponsive;

  /// 渲染进程无响应回调。
  final Future<WebViewRenderProcessAction?> Function(
    InAppWebViewController controller,
    WebUri? url,
  )?
  onRenderProcessUnresponsive;

  /// 安全浏览命中回调。
  final Future<SafeBrowsingResponse?> Function(
    InAppWebViewController controller,
    WebUri url,
    SafeBrowsingThreat? threatType,
  )?
  onSafeBrowsingHit;

  /// Web 内容进程终止回调（iOS/macOS）。
  final void Function(InAppWebViewController controller)?
  onWebContentProcessDidTerminate;

  /// 是否允许过时 TLS 回调（iOS/macOS）。
  final Future<ShouldAllowDeprecatedTLSAction?> Function(
    InAppWebViewController controller,
    URLAuthenticationChallenge challenge,
  )?
  shouldAllowDeprecatedTLS;

  /// 请求拦截回调（Android）。
  final Future<WebResourceResponse?> Function(
    InAppWebViewController controller,
    WebResourceRequest request,
  )?
  shouldInterceptRequest;

  /// 摄像头采集状态变化回调。
  final Future<void> Function(
    InAppWebViewController controller,
    MediaCaptureState? oldState,
    MediaCaptureState? newState,
  )?
  onCameraCaptureStateChanged;

  /// 麦克风采集状态变化回调。
  final Future<void> Function(
    InAppWebViewController controller,
    MediaCaptureState? oldState,
    MediaCaptureState? newState,
  )?
  onMicrophoneCaptureStateChanged;

  /// 内容尺寸变化回调。
  final void Function(
    InAppWebViewController controller,
    Size oldContentSize,
    Size newContentSize,
  )?
  onContentSizeChanged;

  /// 收到服务器重定向回调（iOS/macOS）。
  final void Function(InAppWebViewController controller)?
  onDidReceiveServerRedirectForProvisionalNavigation;

  /// 表单重新提交回调。
  final Future<FormResubmissionAction?> Function(
    InAppWebViewController controller,
    WebUri? url,
  )?
  onFormResubmission;

  /// 地理位置权限隐藏提示回调。
  final void Function(InAppWebViewController controller)?
  onGeolocationPermissionsHidePrompt;

  /// 地理位置权限显示提示回调。
  final Future<GeolocationPermissionShowPromptResponse?> Function(
    InAppWebViewController controller,
    String origin,
  )?
  onGeolocationPermissionsShowPrompt;

  /// JavaScript beforeUnload 弹窗回调。
  final Future<JsBeforeUnloadResponse?> Function(
    InAppWebViewController controller,
    JsBeforeUnloadRequest jsBeforeUnloadRequest,
  )?
  onJsBeforeUnload;

  const OfflineWebView({
    super.key,
    required this.initialUrl,
    this.controller,
    this.appBar,
    this.onLoadTiming,
    this.enableVConsole = false,
    this.gestureRecognizers,
    this.windowId,
    this.headlessWebView,
    this.keepAlive,
    this.preventGestureDelay,
    this.layoutDirection,
    this.webViewEnvironment,
    this.initialData,
    this.initialFile,
    this.initialSettings,
    this.initialUserScripts,
    this.pullToRefreshController,
    this.findInteractionController,
    this.contextMenu,
    this.onLoadStart,
    this.onLoadStop,
    this.onReceivedError,
    this.onWebViewCreated,
    this.shouldOverrideUrlLoading,
    this.onProgressChanged,
    this.onPageCommitVisible,
    this.onReceivedHttpError,
    this.onTitleChanged,
    this.onAjaxProgress,
    this.onAjaxReadyStateChange,
    this.onConsoleMessage,
    this.onCreateWindow,
    this.onCloseWindow,
    this.onWindowFocus,
    this.onWindowBlur,
    this.onDownloadStartRequest,
    this.onJsAlert,
    this.onJsConfirm,
    this.onJsPrompt,
    this.onLoadResource,
    this.onLoadResourceWithCustomScheme,
    this.onLongPressHitTestResult,
    this.onPrintRequest,
    this.onReceivedClientCertRequest,
    this.onReceivedHttpAuthRequest,
    this.onReceivedServerTrustAuthRequest,
    this.onScrollChanged,
    this.onUpdateVisitedHistory,
    this.shouldInterceptAjaxRequest,
    this.shouldInterceptFetchRequest,
    this.onEnterFullscreen,
    this.onExitFullscreen,
    this.onOverScrolled,
    this.onZoomScaleChanged,
    this.onNavigationResponse,
    this.onPermissionRequest,
    this.onReceivedIcon,
    this.onReceivedLoginRequest,
    this.onPermissionRequestCanceled,
    this.onRequestFocus,
    this.onReceivedTouchIconUrl,
    this.onRenderProcessGone,
    this.onRenderProcessResponsive,
    this.onRenderProcessUnresponsive,
    this.onSafeBrowsingHit,
    this.onWebContentProcessDidTerminate,
    this.shouldAllowDeprecatedTLS,
    this.shouldInterceptRequest,
    this.onCameraCaptureStateChanged,
    this.onMicrophoneCaptureStateChanged,
    this.onContentSizeChanged,
    this.onDidReceiveServerRedirectForProvisionalNavigation,
    this.onFormResubmission,
    this.onGeolocationPermissionsHidePrompt,
    this.onGeolocationPermissionsShowPrompt,
    this.onJsBeforeUnload,
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

  late final Stopwatch _sw;
  bool _loggedCreate = false;
  bool _loggedLoadStart = false;
  bool _loggedCommitVisible = false;
  int _lastProgress = 0;

  /// 从 URL 中提取的业务名称。
  late final String _bisName;

  /// 离线包 cur 目录路径，用于 HtmlCache 读写。
  String? _curDirPath;

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

    _curDirPath = bisName.isNotEmpty
        ? DefaultMatcher.getCurPath(bisName)
        : null;

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

  InAppWebViewSettings _buildSettings() {
    final defaults = InAppWebViewSettings(
      javaScriptEnabled: true,
      defaultFontSize: 16,
      useHybridComposition: false,
      transparentBackground: false,
    );

    final userSettings = widget.initialSettings;
    if (userSettings == null) {
      return InAppWebViewSettings(
        javaScriptEnabled: defaults.javaScriptEnabled,
        defaultFontSize: defaults.defaultFontSize,
        useHybridComposition: defaults.useHybridComposition,
        transparentBackground: Platform.isAndroid,
      );
    }

    return InAppWebViewSettings(
      javaScriptEnabled: userSettings.javaScriptEnabled,
      defaultFontSize: userSettings.defaultFontSize,
      useHybridComposition: userSettings.useHybridComposition,
      transparentBackground: userSettings.transparentBackground,
      useShouldOverrideUrlLoading: userSettings.useShouldOverrideUrlLoading,
      useOnLoadResource: userSettings.useOnLoadResource,
      useOnDownloadStart: userSettings.useOnDownloadStart,
      userAgent: userSettings.userAgent,
      applicationNameForUserAgent: userSettings.applicationNameForUserAgent,
      javaScriptCanOpenWindowsAutomatically:
          userSettings.javaScriptCanOpenWindowsAutomatically,
      mediaPlaybackRequiresUserGesture:
          userSettings.mediaPlaybackRequiresUserGesture,
      minimumFontSize: userSettings.minimumFontSize,
      verticalScrollBarEnabled: userSettings.verticalScrollBarEnabled,
      horizontalScrollBarEnabled: userSettings.horizontalScrollBarEnabled,
      resourceCustomSchemes: userSettings.resourceCustomSchemes,
      contentBlockers: userSettings.contentBlockers,
      preferredContentMode: userSettings.preferredContentMode,
      useShouldInterceptAjaxRequest: userSettings.useShouldInterceptAjaxRequest,
      interceptOnlyAsyncAjaxRequests:
          userSettings.interceptOnlyAsyncAjaxRequests,
      useShouldInterceptFetchRequest:
          userSettings.useShouldInterceptFetchRequest,
      incognito: userSettings.incognito,
      cacheEnabled: userSettings.cacheEnabled,
      disableVerticalScroll: userSettings.disableVerticalScroll,
      disableHorizontalScroll: userSettings.disableHorizontalScroll,
      disableContextMenu: userSettings.disableContextMenu,
      supportZoom: userSettings.supportZoom,
      allowFileAccessFromFileURLs: userSettings.allowFileAccessFromFileURLs,
      allowUniversalAccessFromFileURLs:
          userSettings.allowUniversalAccessFromFileURLs,
      textZoom: userSettings.textZoom,
      builtInZoomControls: userSettings.builtInZoomControls,
      displayZoomControls: userSettings.displayZoomControls,
      databaseEnabled: userSettings.databaseEnabled,
      domStorageEnabled: userSettings.domStorageEnabled,
      useWideViewPort: userSettings.useWideViewPort,
      safeBrowsingEnabled: userSettings.safeBrowsingEnabled,
      mixedContentMode: userSettings.mixedContentMode,
      allowContentAccess: userSettings.allowContentAccess,
      allowFileAccess: userSettings.allowFileAccess,
      appCachePath: userSettings.appCachePath,
      blockNetworkImage: userSettings.blockNetworkImage,
      blockNetworkLoads: userSettings.blockNetworkLoads,
      cacheMode: userSettings.cacheMode,
      cursiveFontFamily: userSettings.cursiveFontFamily,
      defaultFixedFontSize: userSettings.defaultFixedFontSize,
      defaultTextEncodingName: userSettings.defaultTextEncodingName,
      disabledActionModeMenuItems: userSettings.disabledActionModeMenuItems,
      fantasyFontFamily: userSettings.fantasyFontFamily,
      fixedFontFamily: userSettings.fixedFontFamily,
      forceDark: userSettings.forceDark,
      forceDarkStrategy: userSettings.forceDarkStrategy,
      geolocationEnabled: userSettings.geolocationEnabled,
      layoutAlgorithm: userSettings.layoutAlgorithm,
      loadWithOverviewMode: userSettings.loadWithOverviewMode,
      loadsImagesAutomatically: userSettings.loadsImagesAutomatically,
      minimumLogicalFontSize: userSettings.minimumLogicalFontSize,
      needInitialFocus: userSettings.needInitialFocus,
      offscreenPreRaster: userSettings.offscreenPreRaster,
      sansSerifFontFamily: userSettings.sansSerifFontFamily,
      serifFontFamily: userSettings.serifFontFamily,
      standardFontFamily: userSettings.standardFontFamily,
      saveFormData: userSettings.saveFormData,
      thirdPartyCookiesEnabled: userSettings.thirdPartyCookiesEnabled,
      hardwareAcceleration: userSettings.hardwareAcceleration,
      initialScale: userSettings.initialScale,
      supportMultipleWindows: userSettings.supportMultipleWindows,
      regexToCancelSubFramesLoading: userSettings.regexToCancelSubFramesLoading,
      useShouldInterceptRequest: userSettings.useShouldInterceptRequest,
      useOnRenderProcessGone: userSettings.useOnRenderProcessGone,
      overScrollMode: userSettings.overScrollMode,
      networkAvailable: userSettings.networkAvailable,
      scrollBarStyle: userSettings.scrollBarStyle,
      verticalScrollbarPosition: userSettings.verticalScrollbarPosition,
      scrollBarDefaultDelayBeforeFade:
          userSettings.scrollBarDefaultDelayBeforeFade,
      scrollbarFadingEnabled: userSettings.scrollbarFadingEnabled,
      scrollBarFadeDuration: userSettings.scrollBarFadeDuration,
      rendererPriorityPolicy: userSettings.rendererPriorityPolicy,
      disableDefaultErrorPage: userSettings.disableDefaultErrorPage,
      verticalScrollbarThumbColor: userSettings.verticalScrollbarThumbColor,
      verticalScrollbarTrackColor: userSettings.verticalScrollbarTrackColor,
      horizontalScrollbarThumbColor: userSettings.horizontalScrollbarThumbColor,
      horizontalScrollbarTrackColor: userSettings.horizontalScrollbarTrackColor,
      algorithmicDarkeningAllowed: userSettings.algorithmicDarkeningAllowed,
      enterpriseAuthenticationAppLinkPolicyEnabled:
          userSettings.enterpriseAuthenticationAppLinkPolicyEnabled,
      defaultVideoPoster: userSettings.defaultVideoPoster,
      requestedWithHeaderOriginAllowList:
          userSettings.requestedWithHeaderOriginAllowList,
      disallowOverScroll: userSettings.disallowOverScroll,
      enableViewportScale: userSettings.enableViewportScale,
      suppressesIncrementalRendering:
          userSettings.suppressesIncrementalRendering,
      allowsAirPlayForMediaPlayback: userSettings.allowsAirPlayForMediaPlayback,
      allowsBackForwardNavigationGestures:
          userSettings.allowsBackForwardNavigationGestures,
      allowsLinkPreview: userSettings.allowsLinkPreview,
      ignoresViewportScaleLimits: userSettings.ignoresViewportScaleLimits,
      allowsInlineMediaPlayback: userSettings.allowsInlineMediaPlayback,
      allowsPictureInPictureMediaPlayback:
          userSettings.allowsPictureInPictureMediaPlayback,
      isFraudulentWebsiteWarningEnabled:
          userSettings.isFraudulentWebsiteWarningEnabled,
      selectionGranularity: userSettings.selectionGranularity,
      dataDetectorTypes: userSettings.dataDetectorTypes,
      sharedCookiesEnabled: userSettings.sharedCookiesEnabled,
      automaticallyAdjustsScrollIndicatorInsets:
          userSettings.automaticallyAdjustsScrollIndicatorInsets,
      accessibilityIgnoresInvertColors:
          userSettings.accessibilityIgnoresInvertColors,
      decelerationRate: userSettings.decelerationRate,
      alwaysBounceVertical: userSettings.alwaysBounceVertical,
      alwaysBounceHorizontal: userSettings.alwaysBounceHorizontal,
      scrollsToTop: userSettings.scrollsToTop,
      isPagingEnabled: userSettings.isPagingEnabled,
      maximumZoomScale: userSettings.maximumZoomScale,
      minimumZoomScale: userSettings.minimumZoomScale,
      contentInsetAdjustmentBehavior:
          userSettings.contentInsetAdjustmentBehavior,
      isDirectionalLockEnabled: userSettings.isDirectionalLockEnabled,
      mediaType: userSettings.mediaType,
      pageZoom: userSettings.pageZoom,
      limitsNavigationsToAppBoundDomains:
          userSettings.limitsNavigationsToAppBoundDomains,
      useOnNavigationResponse: userSettings.useOnNavigationResponse,
      applePayAPIEnabled: userSettings.applePayAPIEnabled,
      allowingReadAccessTo: userSettings.allowingReadAccessTo,
      disableLongPressContextMenuOnLinks:
          userSettings.disableLongPressContextMenuOnLinks,
      disableInputAccessoryView: userSettings.disableInputAccessoryView,
      underPageBackgroundColor: userSettings.underPageBackgroundColor,
      isTextInteractionEnabled: userSettings.isTextInteractionEnabled,
      isSiteSpecificQuirksModeEnabled:
          userSettings.isSiteSpecificQuirksModeEnabled,
      upgradeKnownHostsToHTTPS: userSettings.upgradeKnownHostsToHTTPS,
      isElementFullscreenEnabled: userSettings.isElementFullscreenEnabled,
      isFindInteractionEnabled: userSettings.isFindInteractionEnabled,
      minimumViewportInset: userSettings.minimumViewportInset,
      maximumViewportInset: userSettings.maximumViewportInset,
      isInspectable: userSettings.isInspectable,
      shouldPrintBackgrounds: userSettings.shouldPrintBackgrounds,
      allowBackgroundAudioPlaying: userSettings.allowBackgroundAudioPlaying,
      webViewAssetLoader: userSettings.webViewAssetLoader,
      iframeAllow: userSettings.iframeAllow,
      iframeAllowFullscreen: userSettings.iframeAllowFullscreen,
      iframeSandbox: userSettings.iframeSandbox,
      iframeReferrerPolicy: userSettings.iframeReferrerPolicy,
      iframeName: userSettings.iframeName,
      iframeCsp: userSettings.iframeCsp,
    );
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
      final codec = await ui.instantiateImageCodec(pngBytes, targetWidth: 10);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
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
        totalDev +=
            (pixels[offset] - avgR).abs() +
            (pixels[offset + 1] - avgG).abs() +
            (pixels[offset + 2] - avgB).abs();
      }
      return totalDev / totalPixels < 5;
    } catch (_) {
      return false;
    }
  }

  /// 注入 vConsole 调试面板。
  void _injectVConsole(InAppWebViewController controller) async {
    try {
      await controller.evaluateJavascript(
        source: '''
        if (!window.__vConsoleInjected) {
          var script = document.createElement('script');
          script.src = 'https://unpkg.com/vconsole@latest/dist/vconsole.min.js';
          script.onload = function() {
            new window.VConsole();
          };
          document.head.appendChild(script);
          window.__vConsoleInjected = true;
        }
      ''',
      );
      Logger.d('OfflineWebView', 'vConsole 注入成功');
    } catch (e) {
      Logger.d('OfflineWebView', 'vConsole 注入失败: $e');
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
      gestureRecognizers: widget.gestureRecognizers,
      windowId: widget.windowId,
      headlessWebView: widget.headlessWebView,
      keepAlive: widget.keepAlive,
      preventGestureDelay: widget.preventGestureDelay,
      layoutDirection: widget.layoutDirection,
      webViewEnvironment: widget.webViewEnvironment,
      initialData: widget.initialData,
      initialFile: widget.initialFile,
      initialSettings: _buildSettings(),
      initialUrlRequest:
          (widget.initialData == null && widget.initialFile == null)
          ? URLRequest(url: WebUri(_resolvedUrl))
          : null,
      initialUserScripts: widget.initialUserScripts,
      pullToRefreshController: widget.pullToRefreshController,
      findInteractionController: widget.findInteractionController,
      contextMenu: widget.contextMenu,
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
        widget.onWebViewCreated?.call(controller);
      },
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        final url = navigationAction.request.url?.toString() ?? '';
        if (url.isEmpty) {
          final result = await widget.shouldOverrideUrlLoading?.call(
            controller,
            navigationAction,
          );
          return result ?? NavigationActionPolicy.ALLOW;
        }

        // 本地服务器 URL 直接放行
        if (LocalServer.isLocalServerUrl(url)) {
          final result = await widget.shouldOverrideUrlLoading?.call(
            controller,
            navigationAction,
          );
          return result ?? NavigationActionPolicy.ALLOW;
        }

        final proxy = _proxy;
        if (proxy == null) {
          final result = await widget.shouldOverrideUrlLoading?.call(
            controller,
            navigationAction,
          );
          return result ?? NavigationActionPolicy.ALLOW;
        }

        final resolvedUrl = proxy.loadUrl(url);

        if (resolvedUrl != url) {
          await controller.loadUrl(
            urlRequest: URLRequest(url: WebUri(resolvedUrl)),
          );
          _controller.setCurrentUrl(resolvedUrl);
          return NavigationActionPolicy.CANCEL;
        }

        final result = await widget.shouldOverrideUrlLoading?.call(
          controller,
          navigationAction,
        );
        return result ?? NavigationActionPolicy.ALLOW;
      },
      onLoadStart: (controller, url) {
        // 用户主动刷新时重置计时器，重定向时不重置
        if (_controller.consumeReloadFlag()) {
          _sw.reset();
          _loggedCommitVisible = false;
          _lastProgress = 0;
        }
        if (!_loggedLoadStart) {
          Logger.d(
            'OfflineWebView',
            'onLoadStart: ${_sw.elapsedMilliseconds}ms',
          );
          _loggedLoadStart = true;
        }
        final currentUrl = url?.toString() ?? '';
        if (currentUrl.isNotEmpty) {
          _controller.setCurrentUrl(currentUrl);
        }

        // 检测加载模式并记录
        final isLocal =
            currentUrl.isNotEmpty && LocalServer.isLocalServerUrl(currentUrl);
        final mode = isLocal ? LoadingMode.offline : LoadingMode.network;

        // 如果是离线模式，尝试消费已缓存的离线阶段耗时
        if (isLocal && _bisName.isNotEmpty) {
          final cached = PerformanceMonitor.instance.consumeOfflinePhaseTiming(
            _bisName,
          );
          if (cached != null) {
            PerformanceMonitor.instance.recordOfflinePhase(
              queryMs: cached.queryMs,
              downloadMs: cached.downloadMs,
              unzipMs: cached.unzipMs,
              querySuccess: cached.querySuccess,
              downloadSuccess: cached.downloadSuccess,
              unzipSuccess: cached.unzipSuccess,
            );
          }
        }

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
        widget.onProgressChanged?.call(controller, progress);
      },
      onPageCommitVisible: (controller, url) {
        if (!_loggedCommitVisible) {
          Logger.i('OfflineWebView', '首帧可见: ${_sw.elapsedMilliseconds}ms');
          _loggedCommitVisible = true;
          PerformanceMonitor.instance.recordFirstPaint();
        }
        widget.onPageCommitVisible?.call(controller, url);
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
        if (widget.enableVConsole) {
          _injectVConsole(controller);
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
        widget.onReceivedHttpError?.call(controller, request, errorResponse);
      },

      onTitleChanged: widget.onTitleChanged,
      onAjaxProgress: widget.onAjaxProgress,
      onAjaxReadyStateChange: widget.onAjaxReadyStateChange,
      onConsoleMessage: widget.onConsoleMessage,
      onCreateWindow: widget.onCreateWindow,
      onCloseWindow: widget.onCloseWindow,
      onWindowFocus: widget.onWindowFocus,
      onWindowBlur: widget.onWindowBlur,
      onDownloadStartRequest: widget.onDownloadStartRequest,
      onJsAlert: widget.onJsAlert,
      onJsConfirm: widget.onJsConfirm,
      onJsPrompt: widget.onJsPrompt,
      onLoadResource: widget.onLoadResource,
      onLoadResourceWithCustomScheme: widget.onLoadResourceWithCustomScheme,
      onLongPressHitTestResult: widget.onLongPressHitTestResult,
      onPrintRequest: widget.onPrintRequest,
      onReceivedClientCertRequest: widget.onReceivedClientCertRequest,
      onReceivedHttpAuthRequest: widget.onReceivedHttpAuthRequest,
      onReceivedServerTrustAuthRequest: widget.onReceivedServerTrustAuthRequest,
      onScrollChanged: widget.onScrollChanged,
      onUpdateVisitedHistory: widget.onUpdateVisitedHistory,
      shouldInterceptAjaxRequest: widget.shouldInterceptAjaxRequest,
      shouldInterceptFetchRequest: widget.shouldInterceptFetchRequest,
      onEnterFullscreen: widget.onEnterFullscreen,
      onExitFullscreen: widget.onExitFullscreen,
      onOverScrolled: widget.onOverScrolled,
      onZoomScaleChanged: widget.onZoomScaleChanged,
      onNavigationResponse: widget.onNavigationResponse,
      onPermissionRequest: widget.onPermissionRequest,
      onReceivedIcon: widget.onReceivedIcon,
      onReceivedLoginRequest: widget.onReceivedLoginRequest,
      onPermissionRequestCanceled: widget.onPermissionRequestCanceled,
      onRequestFocus: widget.onRequestFocus,
      onReceivedTouchIconUrl: widget.onReceivedTouchIconUrl,
      onRenderProcessGone: widget.onRenderProcessGone,
      onRenderProcessResponsive: widget.onRenderProcessResponsive,
      onRenderProcessUnresponsive: widget.onRenderProcessUnresponsive,
      onSafeBrowsingHit: widget.onSafeBrowsingHit,
      onWebContentProcessDidTerminate: widget.onWebContentProcessDidTerminate,
      shouldAllowDeprecatedTLS: widget.shouldAllowDeprecatedTLS,
      shouldInterceptRequest: widget.shouldInterceptRequest,
      onCameraCaptureStateChanged: widget.onCameraCaptureStateChanged,
      onMicrophoneCaptureStateChanged: widget.onMicrophoneCaptureStateChanged,
      onContentSizeChanged: widget.onContentSizeChanged,
      onDidReceiveServerRedirectForProvisionalNavigation:
          widget.onDidReceiveServerRedirectForProvisionalNavigation,
      onFormResubmission: widget.onFormResubmission,
      onGeolocationPermissionsHidePrompt:
          widget.onGeolocationPermissionsHidePrompt,
      onGeolocationPermissionsShowPrompt:
          widget.onGeolocationPermissionsShowPrompt,
      onJsBeforeUnload: widget.onJsBeforeUnload,
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
