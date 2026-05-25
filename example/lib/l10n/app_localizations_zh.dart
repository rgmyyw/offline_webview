// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'OfflineWebView 演示';

  @override
  String get offlineLoadingMode => '离线加载模式';

  @override
  String get offlineLoadingModeSubtitle => 'URL带offweb参数，直接加载离线包';

  @override
  String get ruleMatchMode => '规则匹配模式';

  @override
  String get ruleMatchModeSubtitle => '自动匹配URL并注入offweb参数';

  @override
  String get debugTools => '调试工具';

  @override
  String get debugToolsSubtitle => '离线包管理、URL匹配、缓存清理等';

  @override
  String get serverDebug => '服务调试';

  @override
  String get serverDebugSubtitle => '测试本地服务端点是否正常工作';

  @override
  String get customConfig => '自定义配置';

  @override
  String get customConfigSubtitle => '自定义离线包下载地址和访问地址';

  @override
  String get offlinePackageMode => '离线包模式';

  @override
  String get networkLoading => '网络加载';

  @override
  String get ruleMatchDemo => '规则匹配演示';

  @override
  String get debugToolsPage => '调试工具';

  @override
  String get serverDebugPage => '服务调试';

  @override
  String get customConfigPage => '自定义配置';

  @override
  String get configInfo => '配置查看';

  @override
  String get packageManagement => '离线包管理';

  @override
  String get disableListManagement => '禁用列表管理';

  @override
  String get forceUpdateCheck => '强制更新检查';

  @override
  String get preloadTest => '预加载测试';

  @override
  String get urlMatchTest => 'URL匹配测试';

  @override
  String get screenshotView => '截图查看';

  @override
  String get refresh => '刷新';

  @override
  String get confirmClear => '确认清除';

  @override
  String get confirmClearWebViewCache => '确定要清除 WebView 的所有缓存吗？';

  @override
  String get cancel => '取消';

  @override
  String get clear => '清除';

  @override
  String get webViewCacheCleared => 'WebView 缓存已清除';

  @override
  String get basicConfig => '基础配置';

  @override
  String get ruleConfig => '规则配置';

  @override
  String get sdkStatus => 'SDK 状态';

  @override
  String get noRuleConfig => '暂无规则配置';

  @override
  String get initStatus => '初始化状态';

  @override
  String get initialized => '已初始化';

  @override
  String get notInitialized => '未初始化';

  @override
  String get request => 'Request';

  @override
  String get configured => '已配置';

  @override
  String get notConfigured => '未配置';

  @override
  String get offlinePackageManagement => '离线包管理';

  @override
  String get offlinePackageManagementDesc => '查看、删除离线包缓存';

  @override
  String get clearWebViewCache => '清除 WebView 缓存';

  @override
  String get clearWebViewCacheDesc => '清除 WebView 的所有缓存数据';

  @override
  String get urlMatchTestCard => 'URL 匹配测试';

  @override
  String get urlMatchTestCardDesc => '测试 URL 匹配到哪个 bisName';

  @override
  String get disableListManagementCard => '禁用列表管理';

  @override
  String get disableListManagementDesc => '查看、添加禁用项';

  @override
  String get forceUpdateCheckCard => '强制更新检查';

  @override
  String get forceUpdateCheckDesc => '对指定 bisName 强制触发更新';

  @override
  String get preloadTestCard => '预加载测试';

  @override
  String get preloadTestDesc => '测试离线包预加载状态';

  @override
  String get configInfoCard => '配置查看';

  @override
  String get configInfoCardDesc => '查看 SDK 当前配置和规则';

  @override
  String get bisNameHint => '输入 bisName';

  @override
  String get add => '添加';

  @override
  String get remoteAvailablePackages => '远程可用离线包:';

  @override
  String get noPackagesAvailable => '暂无可用包';

  @override
  String currentDisableItems(int count) {
    return '当前 $count 个禁用项';
  }

  @override
  String get noDisableItems => '暂无禁用项';

  @override
  String get test => '测试';

  @override
  String get delete => '删除';

  @override
  String get confirmDelete => '确认删除';

  @override
  String confirmDeletePackageCache(String bisName) {
    return '确定要删除 \"$bisName\" 的离线缓存吗？';
  }

  @override
  String get confirmClearAll => '确认清空';

  @override
  String get confirmDeleteAllCache => '确定要删除所有离线缓存吗？此操作不可恢复。';

  @override
  String get deleteAll => '全部删除';

  @override
  String deleted(String bisName) {
    return '已删除 $bisName';
  }

  @override
  String get deleteFailed => '删除失败';

  @override
  String get clearedAllCache => '已清空所有缓存';

  @override
  String get clearFailed => '清空失败';

  @override
  String get offlinePackageCount => '离线包数量';

  @override
  String get totalSize => '总大小';

  @override
  String get offlinePackageList => '离线包列表';

  @override
  String packagesCount(int count) {
    return '$count 个包';
  }

  @override
  String get noOfflinePackageData => '暂无离线包数据';

  @override
  String get version => '版本';

  @override
  String get size => '大小';

  @override
  String get bisNameLabel => 'bisName';

  @override
  String get exampleBisName => '例如: act3-2108';

  @override
  String get start => '开始';

  @override
  String get updateLogs => '更新日志';

  @override
  String logCount(int count) {
    return '$count 条';
  }

  @override
  String get clickStartButtonForUpdateCheck => '点击开始按钮进行更新检查...';

  @override
  String get readyEnterBisNameClickStart => '就绪，请输入 bisName 并点击开始';

  @override
  String startUpdateCheck(String bisName) {
    return '开始更新检查: $bisName';
  }

  @override
  String localVersion(String version) {
    return '本地版本: $version';
  }

  @override
  String get requestingServer => '正在请求服务器...';

  @override
  String get notConfiguredOfflineRequest => '未配置 IOfflineRequest，无法请求服务器';

  @override
  String get triggeredCheckPackage => '已触发 checkPackage';

  @override
  String get updateTaskSubmitted => '更新任务已提交，请查看日志了解进度';

  @override
  String foundNewVersion(String version) {
    return '发现新版本: $version';
  }

  @override
  String currentVersion(String version) {
    return '当前版本: $version';
  }

  @override
  String get updateCheckComplete => '更新检查完成';

  @override
  String updateFailed(String error) {
    return '更新失败: $error';
  }

  @override
  String get clearLogs => '清空日志';

  @override
  String get availableOfflinePackages => '可用离线包:';

  @override
  String get noOfflinePackageDataSmall => '暂无离线包数据';

  @override
  String get enterBisName => '请输入 bisName';

  @override
  String get serverConfig => '服务器配置';

  @override
  String get offlinePackageServerAddress => '离线包服务地址';

  @override
  String get exampleServerAddress => '例: http://192.168.1.100:9999';

  @override
  String get getOfflinePackageList => '获取离线包列表';

  @override
  String get selectOfflinePackage => '选择离线包';

  @override
  String get pleaseSelectPackage => '请选择离线包';

  @override
  String get businessConfig => '业务配置';

  @override
  String get businessName => '业务名称 (bisName)';

  @override
  String get examplePackage => '例: package';

  @override
  String get accessAddress => '访问地址';

  @override
  String get exampleAccessAddress => '例: https://example.com?offweb=package';

  @override
  String get loadingMethod => '加载方式';

  @override
  String get useOfflinePackageLoading => '使用离线包加载';

  @override
  String get useOfflinePackageLoadingDesc => '通过离线包加速 H5 页面加载';

  @override
  String get doNotUseOfflinePackage => '不使用离线包';

  @override
  String get doNotUseOfflinePackageDesc => '直接加载在线页面（对照组）';

  @override
  String get directNavigate => '直接跳转';

  @override
  String get directNavigateDesc => '不预加载，直接打开页面';

  @override
  String get launch => '启动';

  @override
  String get navigate => '跳转';

  @override
  String get tools => '工具';

  @override
  String get viewScreenshotCache => '查看截图缓存';

  @override
  String get cleanOfflinePackage => '清理离线包';

  @override
  String get pleaseFillAllFields => '请填写所有字段';

  @override
  String get pleaseFillServerAndBisName => '请填写访问地址和 bisName';

  @override
  String fetchedPackagesCount(int count, String packages) {
    return '获取到 $count 个离线包: $packages';
  }

  @override
  String requestFailed(int statusCode) {
    return '请求失败: $statusCode';
  }

  @override
  String fetchOfflinePackageFailed(String error) {
    return '获取离线包失败: $error';
  }

  @override
  String get pleaseFillAccessAddress => '请填写访问地址';

  @override
  String initFailed(String error) {
    return '初始化失败: $error';
  }

  @override
  String get pleaseFillBisNameFirst => '请先填写 bisName';

  @override
  String get confirmClean => '确认清理';

  @override
  String confirmCleanPackageCache(String bisName) {
    return '确定要清理 \"$bisName\" 的离线包缓存吗？';
  }

  @override
  String get confirm => '确定';

  @override
  String cleanedPackageCache(String bisName) {
    return '已清理 \"$bisName\" 离线包缓存';
  }

  @override
  String screenshotNotExists(String path) {
    return '截图不存在: $path';
  }

  @override
  String sizeBytes(int bytes, String path) {
    return '大小: $bytes 字节\n路径: $path';
  }

  @override
  String imageLoadFailed(String error) {
    return '图片加载失败: $error';
  }

  @override
  String addedToDisableList(String bisName) {
    return '已添加 \"$bisName\" 到禁用列表';
  }

  @override
  String addFailed(String error) {
    return '添加失败: $error';
  }

  @override
  String bisNameIsDisabled(String bisName) {
    return '\"$bisName\" 已被禁用';
  }

  @override
  String bisNameNotDisabled(String bisName) {
    return '\"$bisName\" 未被禁用';
  }

  @override
  String testFailed(String error) {
    return '测试失败: $error';
  }

  @override
  String get deleteRequiresReinitSdk => '删除需要重新初始化 SDK 配置';

  @override
  String get serverEndpoints => '服务端点';

  @override
  String get health => 'Health';

  @override
  String get healthCheck => '健康检查端点';

  @override
  String get queryUpdate => 'Query (检查更新)';

  @override
  String get queryUpdateDesc => '查询离线包更新状态';

  @override
  String get queryNoUpdate => 'Query (无更新)';

  @override
  String get queryNoUpdateDesc => '测试无更新响应';

  @override
  String get package => 'Package';

  @override
  String get packageDesc => '下载离线包 zip';

  @override
  String get demo => 'Demo';

  @override
  String get demoPage => '演示 HTML 页面';

  @override
  String get testButton => '测试';

  @override
  String get logs => '日志';

  @override
  String get clickButtonToStartTest => '点击上方按钮开始测试...';

  @override
  String get testing => '测试中...';

  @override
  String get notTested => '未测试';

  @override
  String get inputUrl => '输入 URL';

  @override
  String get exampleUrlHint => '例如: https://m.example.com/act3/index.html';

  @override
  String get testMatch => '测试匹配';

  @override
  String get commonTestUrls => '常用测试 URL';

  @override
  String get matchResult => '匹配结果';

  @override
  String get noMatchBisName => '未匹配到 bisName';

  @override
  String get matchFailed => '匹配失败';

  @override
  String loadFailed(String error) {
    return '刷新失败: $error';
  }

  @override
  String get preloadTestPage => '预加载测试';

  @override
  String get testLogs => '测试日志';

  @override
  String get clickStartButtonForPreloadTest => '点击开始按钮进行预加载测试...';

  @override
  String get readyEnterBisNameClickStartPreload => '就绪，请输入 bisName 并点击开始预加载';

  @override
  String get gettingAvailablePackages => '正在从服务端获取可用离线包...';

  @override
  String serverHasPackagesCount(int count) {
    return '服务端共有 $count 个离线包';
  }

  @override
  String fetchFailed(int statusCode) {
    return '获取失败: $statusCode';
  }

  @override
  String fetchPackageListError(String error) {
    return '获取离线包列表异常: $error';
  }

  @override
  String startPreloadTest(String bisName) {
    return '开始预加载测试: $bisName';
  }

  @override
  String get localVersionNone => '本地版本: 无';

  @override
  String get queryingServerEndpoint => '正在查询服务端点...';

  @override
  String queryResult(String message) {
    return '查询结果: $message';
  }

  @override
  String foundNewVersionPrepareDownload(String version) {
    return '发现新版本: $version，准备下载...';
  }

  @override
  String get alreadyLatestNoDownload => '已是最新版本，无需下载';

  @override
  String preloadTestComplete(int ms) {
    return '预加载测试完成，耗时: ${ms}ms';
  }

  @override
  String preloadTestFailed(String error) {
    return '预加载测试失败: $error';
  }

  @override
  String get triggerDownloadFlow => '触发下载流程...';

  @override
  String downloadCompleteNewVersion(String version) {
    return '下载完成，新版本: $version';
  }

  @override
  String get downloadComplete => '下载完成';

  @override
  String downloadFailedError(String error) {
    return '下载失败: $error';
  }

  @override
  String queryUrl(String url) {
    return '查询URL: $url';
  }

  @override
  String get performancePanelSwitch => '性能监控面板';

  @override
  String get performancePanelSwitchDesc => '显示悬浮性能监控浮层';
}
