// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'OfflineWebView Demo';

  @override
  String get offlineLoadingMode => 'Offline Loading Mode';

  @override
  String get offlineLoadingModeSubtitle =>
      'URL with offweb parameter, directly load offline package';

  @override
  String get ruleMatchMode => 'Rule Match Mode';

  @override
  String get ruleMatchModeSubtitle =>
      'Auto-match URL and inject offweb parameter';

  @override
  String get debugTools => 'Debug Tools';

  @override
  String get debugToolsSubtitle =>
      'Offline package management, URL matching, cache cleanup, etc.';

  @override
  String get serverDebug => 'Server Debug';

  @override
  String get serverDebugSubtitle => 'Test local server endpoints';

  @override
  String get customConfig => 'Custom Config';

  @override
  String get customConfigSubtitle =>
      'Customize offline package download URL and access URL';

  @override
  String get offlinePackageMode => 'Offline Package Mode';

  @override
  String get networkLoading => 'Network Loading';

  @override
  String get ruleMatchDemo => 'Rule Match Demo';

  @override
  String get debugToolsPage => 'Debug Tools';

  @override
  String get serverDebugPage => 'Server Debug';

  @override
  String get customConfigPage => 'Custom Config';

  @override
  String get configInfo => 'Config Info';

  @override
  String get packageManagement => 'Offline Package Management';

  @override
  String get disableListManagement => 'Disable List Management';

  @override
  String get forceUpdateCheck => 'Force Update Check';

  @override
  String get preloadTest => 'Preload Test';

  @override
  String get urlMatchTest => 'URL Match Test';

  @override
  String get screenshotView => 'Screenshot View';

  @override
  String get refresh => 'Refresh';

  @override
  String get confirmClear => 'Confirm Clear';

  @override
  String get confirmClearWebViewCache =>
      'Are you sure you want to clear all WebView cache?';

  @override
  String get cancel => 'Cancel';

  @override
  String get clear => 'Clear';

  @override
  String get webViewCacheCleared => 'WebView cache cleared';

  @override
  String get basicConfig => 'Basic Config';

  @override
  String get ruleConfig => 'Rule Config';

  @override
  String get sdkStatus => 'SDK Status';

  @override
  String get noRuleConfig => 'No rule config';

  @override
  String get initStatus => 'Init Status';

  @override
  String get initialized => 'Initialized';

  @override
  String get notInitialized => 'Not Initialized';

  @override
  String get request => 'Request';

  @override
  String get configured => 'Configured';

  @override
  String get notConfigured => 'Not Configured';

  @override
  String get offlinePackageManagement => 'Offline Package Management';

  @override
  String get offlinePackageManagementDesc =>
      'View and delete offline package cache';

  @override
  String get clearWebViewCache => 'Clear WebView Cache';

  @override
  String get clearWebViewCacheDesc => 'Clear all WebView cache data';

  @override
  String get urlMatchTestCard => 'URL Match Test';

  @override
  String get urlMatchTestCardDesc => 'Test which bisName a URL matches to';

  @override
  String get disableListManagementCard => 'Disable List Management';

  @override
  String get disableListManagementDesc => 'View and add disable items';

  @override
  String get forceUpdateCheckCard => 'Force Update Check';

  @override
  String get forceUpdateCheckDesc => 'Force update check for specified bisName';

  @override
  String get preloadTestCard => 'Preload Test';

  @override
  String get preloadTestDesc => 'Test offline package preload status';

  @override
  String get configInfoCard => 'Config Info';

  @override
  String get configInfoCardDesc => 'View current SDK config and rules';

  @override
  String get bisNameHint => 'Enter bisName';

  @override
  String get add => 'Add';

  @override
  String get remoteAvailablePackages => 'Remote Available Packages:';

  @override
  String get noPackagesAvailable => 'No packages available';

  @override
  String currentDisableItems(int count) {
    return 'Current $count disable items';
  }

  @override
  String get noDisableItems => 'No disable items';

  @override
  String get test => 'Test';

  @override
  String get delete => 'Delete';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String confirmDeletePackageCache(String bisName) {
    return 'Are you sure you want to delete offline cache for \"$bisName\"?';
  }

  @override
  String get confirmClearAll => 'Confirm Clear All';

  @override
  String get confirmDeleteAllCache =>
      'Are you sure you want to delete all offline cache? This cannot be undone.';

  @override
  String get deleteAll => 'Delete All';

  @override
  String deleted(String bisName) {
    return 'Deleted $bisName';
  }

  @override
  String get deleteFailed => 'Delete failed';

  @override
  String get clearedAllCache => 'Cleared all cache';

  @override
  String get clearFailed => 'Clear failed';

  @override
  String get offlinePackageCount => 'Offline Package Count';

  @override
  String get totalSize => 'Total Size';

  @override
  String get offlinePackageList => 'Offline Package List';

  @override
  String packagesCount(int count) {
    return '$count packages';
  }

  @override
  String get noOfflinePackageData => 'No offline package data';

  @override
  String get version => 'Version';

  @override
  String get size => 'Size';

  @override
  String get bisNameLabel => 'bisName';

  @override
  String get exampleBisName => 'e.g: act3-2108';

  @override
  String get start => 'Start';

  @override
  String get updateLogs => 'Update Logs';

  @override
  String logCount(int count) {
    return '$count logs';
  }

  @override
  String get clickStartButtonForUpdateCheck =>
      'Click start button for update check...';

  @override
  String get readyEnterBisNameClickStart =>
      'Ready, enter bisName and click start';

  @override
  String startUpdateCheck(String bisName) {
    return 'Start update check: $bisName';
  }

  @override
  String localVersion(String version) {
    return 'Local version: $version';
  }

  @override
  String get requestingServer => 'Requesting server...';

  @override
  String get notConfiguredOfflineRequest =>
      'Not configured IOfflineRequest, cannot request server';

  @override
  String get triggeredCheckPackage => 'Triggered checkPackage';

  @override
  String get updateTaskSubmitted =>
      'Update task submitted, check logs for progress';

  @override
  String foundNewVersion(String version) {
    return 'Found new version: $version';
  }

  @override
  String currentVersion(String version) {
    return 'Current version: $version';
  }

  @override
  String get updateCheckComplete => 'Update check complete';

  @override
  String updateFailed(String error) {
    return 'Update failed: $error';
  }

  @override
  String get clearLogs => 'Clear Logs';

  @override
  String get availableOfflinePackages => 'Available Offline Packages:';

  @override
  String get noOfflinePackageDataSmall => 'No offline package data';

  @override
  String get enterBisName => 'Please enter bisName';

  @override
  String get serverConfig => 'Server Config';

  @override
  String get offlinePackageServerAddress => 'Offline Package Server Address';

  @override
  String get exampleServerAddress => 'e.g: http://192.168.1.100:9999';

  @override
  String get getOfflinePackageList => 'Get Offline Package List';

  @override
  String get selectOfflinePackage => 'Select Offline Package';

  @override
  String get pleaseSelectPackage => 'Please select package';

  @override
  String get businessConfig => 'Business Config';

  @override
  String get businessName => 'Business Name (bisName)';

  @override
  String get examplePackage => 'e.g: package';

  @override
  String get accessAddress => 'Access Address';

  @override
  String get exampleAccessAddress => 'e.g: https://example.com?offweb=package';

  @override
  String get loadingMethod => 'Loading Method';

  @override
  String get useOfflinePackageLoading => 'Use Offline Package Loading';

  @override
  String get useOfflinePackageLoadingDesc =>
      'Accelerate H5 page loading via offline package';

  @override
  String get doNotUseOfflinePackage => 'Do Not Use Offline Package';

  @override
  String get doNotUseOfflinePackageDesc =>
      'Load online page directly (control group)';

  @override
  String get directNavigate => 'Direct Navigate';

  @override
  String get directNavigateDesc => 'Open page without preload';

  @override
  String get launch => 'Launch';

  @override
  String get navigate => 'Navigate';

  @override
  String get tools => 'Tools';

  @override
  String get viewScreenshotCache => 'View Screenshot Cache';

  @override
  String get cleanOfflinePackage => 'Clean Offline Package';

  @override
  String get pleaseFillAllFields => 'Please fill all fields';

  @override
  String get pleaseFillServerAndBisName =>
      'Please fill server address and bisName';

  @override
  String fetchedPackagesCount(int count, String packages) {
    return 'Fetched $count offline packages: $packages';
  }

  @override
  String requestFailed(int statusCode) {
    return 'Request failed: $statusCode';
  }

  @override
  String fetchOfflinePackageFailed(String error) {
    return 'Fetch offline package failed: $error';
  }

  @override
  String get pleaseFillAccessAddress => 'Please fill access address';

  @override
  String initFailed(String error) {
    return 'Init failed: $error';
  }

  @override
  String get pleaseFillBisNameFirst => 'Please fill bisName first';

  @override
  String get confirmClean => 'Confirm Clean';

  @override
  String confirmCleanPackageCache(String bisName) {
    return 'Are you sure you want to clean offline package cache for \"$bisName\"?';
  }

  @override
  String get confirm => 'Confirm';

  @override
  String cleanedPackageCache(String bisName) {
    return 'Cleaned \"$bisName\" offline package cache';
  }

  @override
  String screenshotNotExists(String path) {
    return 'Screenshot does not exist: $path';
  }

  @override
  String sizeBytes(int bytes, String path) {
    return 'Size: $bytes bytes\nPath: $path';
  }

  @override
  String imageLoadFailed(String error) {
    return 'Image load failed: $error';
  }

  @override
  String addedToDisableList(String bisName) {
    return 'Added \"$bisName\" to disable list';
  }

  @override
  String addFailed(String error) {
    return 'Add failed: $error';
  }

  @override
  String bisNameIsDisabled(String bisName) {
    return '\"$bisName\" is disabled';
  }

  @override
  String bisNameNotDisabled(String bisName) {
    return '\"$bisName\" is not disabled';
  }

  @override
  String testFailed(String error) {
    return 'Test failed: $error';
  }

  @override
  String get deleteRequiresReinitSdk => 'Delete requires re-init SDK config';

  @override
  String get serverEndpoints => 'Server Endpoints';

  @override
  String get health => 'Health';

  @override
  String get healthCheck => 'Health Check Endpoint';

  @override
  String get queryUpdate => 'Query (Check Update)';

  @override
  String get queryUpdateDesc => 'Query offline package update status';

  @override
  String get queryNoUpdate => 'Query (No Update)';

  @override
  String get queryNoUpdateDesc => 'Test no-update response';

  @override
  String get package => 'Package';

  @override
  String get packageDesc => 'Download offline package zip';

  @override
  String get demo => 'Demo';

  @override
  String get demoPage => 'Demo HTML Page';

  @override
  String get testButton => 'Test';

  @override
  String get logs => 'Logs';

  @override
  String get clickButtonToStartTest => 'Click button above to start test...';

  @override
  String get testing => 'Testing...';

  @override
  String get notTested => 'Not tested';

  @override
  String get inputUrl => 'Input URL';

  @override
  String get exampleUrlHint => 'e.g: https://m.example.com/act3/index.html';

  @override
  String get testMatch => 'Test Match';

  @override
  String get commonTestUrls => 'Common Test URLs';

  @override
  String get matchResult => 'Match Result';

  @override
  String get noMatchBisName => 'No bisName matched';

  @override
  String get matchFailed => 'Match failed';

  @override
  String loadFailed(String error) {
    return 'Load failed: $error';
  }

  @override
  String get preloadTestPage => 'Preload Test';

  @override
  String get testLogs => 'Test Logs';

  @override
  String get clickStartButtonForPreloadTest =>
      'Click start button for preload test...';

  @override
  String get readyEnterBisNameClickStartPreload =>
      'Ready, enter bisName and click start preload';

  @override
  String get gettingAvailablePackages =>
      'Getting available packages from server...';

  @override
  String serverHasPackagesCount(int count) {
    return 'Server has $count offline packages';
  }

  @override
  String fetchFailed(int statusCode) {
    return 'Fetch failed: $statusCode';
  }

  @override
  String fetchPackageListError(String error) {
    return 'Fetch package list error: $error';
  }

  @override
  String startPreloadTest(String bisName) {
    return 'Start preload test: $bisName';
  }

  @override
  String get localVersionNone => 'Local version: none';

  @override
  String get queryingServerEndpoint => 'Querying server endpoint...';

  @override
  String queryResult(String message) {
    return 'Query result: $message';
  }

  @override
  String foundNewVersionPrepareDownload(String version) {
    return 'Found new version: $version, preparing download...';
  }

  @override
  String get alreadyLatestNoDownload => 'Already latest, no download needed';

  @override
  String preloadTestComplete(int ms) {
    return 'Preload test complete, elapsed: ${ms}ms';
  }

  @override
  String preloadTestFailed(String error) {
    return 'Preload test failed: $error';
  }

  @override
  String get triggerDownloadFlow => 'Trigger download flow...';

  @override
  String downloadCompleteNewVersion(String version) {
    return 'Download complete, new version: $version';
  }

  @override
  String get downloadComplete => 'Download complete';

  @override
  String downloadFailedError(String error) {
    return 'Download failed: $error';
  }

  @override
  String queryUrl(String url) {
    return 'Query URL: $url';
  }
}
