import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'OfflineWebView Demo'**
  String get appTitle;

  /// Demo menu item title
  ///
  /// In en, this message translates to:
  /// **'Offline Loading Mode'**
  String get offlineLoadingMode;

  /// Demo menu item subtitle
  ///
  /// In en, this message translates to:
  /// **'URL with offweb parameter, directly load offline package'**
  String get offlineLoadingModeSubtitle;

  /// Demo menu item title
  ///
  /// In en, this message translates to:
  /// **'Rule Match Mode'**
  String get ruleMatchMode;

  /// Demo menu item subtitle
  ///
  /// In en, this message translates to:
  /// **'Auto-match URL and inject offweb parameter'**
  String get ruleMatchModeSubtitle;

  /// Demo menu item title
  ///
  /// In en, this message translates to:
  /// **'Debug Tools'**
  String get debugTools;

  /// Demo menu item subtitle
  ///
  /// In en, this message translates to:
  /// **'Offline package management, URL matching, cache cleanup, etc.'**
  String get debugToolsSubtitle;

  /// Demo menu item title
  ///
  /// In en, this message translates to:
  /// **'Server Debug'**
  String get serverDebug;

  /// Demo menu item subtitle
  ///
  /// In en, this message translates to:
  /// **'Test local server endpoints'**
  String get serverDebugSubtitle;

  /// Demo menu item title
  ///
  /// In en, this message translates to:
  /// **'Custom Config'**
  String get customConfig;

  /// Demo menu item subtitle
  ///
  /// In en, this message translates to:
  /// **'Customize offline package download URL and access URL'**
  String get customConfigSubtitle;

  /// Page title
  ///
  /// In en, this message translates to:
  /// **'Offline Package Mode'**
  String get offlinePackageMode;

  /// Page title
  ///
  /// In en, this message translates to:
  /// **'Network Loading'**
  String get networkLoading;

  /// Page title
  ///
  /// In en, this message translates to:
  /// **'Rule Match Demo'**
  String get ruleMatchDemo;

  /// Page title
  ///
  /// In en, this message translates to:
  /// **'Debug Tools'**
  String get debugToolsPage;

  /// Page title
  ///
  /// In en, this message translates to:
  /// **'Server Debug'**
  String get serverDebugPage;

  /// Page title
  ///
  /// In en, this message translates to:
  /// **'Custom Config'**
  String get customConfigPage;

  /// Page title
  ///
  /// In en, this message translates to:
  /// **'Config Info'**
  String get configInfo;

  /// Page title
  ///
  /// In en, this message translates to:
  /// **'Offline Package Management'**
  String get packageManagement;

  /// Page title
  ///
  /// In en, this message translates to:
  /// **'Disable List Management'**
  String get disableListManagement;

  /// Page title
  ///
  /// In en, this message translates to:
  /// **'Force Update Check'**
  String get forceUpdateCheck;

  /// Page title
  ///
  /// In en, this message translates to:
  /// **'Preload Test'**
  String get preloadTest;

  /// Page title
  ///
  /// In en, this message translates to:
  /// **'URL Match Test'**
  String get urlMatchTest;

  /// Page title
  ///
  /// In en, this message translates to:
  /// **'Screenshot View'**
  String get screenshotView;

  /// Tooltip for refresh button
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Confirm Clear'**
  String get confirmClear;

  /// Dialog content
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all WebView cache?'**
  String get confirmClearWebViewCache;

  /// Button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Button text
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Snackbar message
  ///
  /// In en, this message translates to:
  /// **'WebView cache cleared'**
  String get webViewCacheCleared;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Basic Config'**
  String get basicConfig;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Rule Config'**
  String get ruleConfig;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'SDK Status'**
  String get sdkStatus;

  /// Empty state text
  ///
  /// In en, this message translates to:
  /// **'No rule config'**
  String get noRuleConfig;

  /// Status label
  ///
  /// In en, this message translates to:
  /// **'Init Status'**
  String get initStatus;

  /// Status value
  ///
  /// In en, this message translates to:
  /// **'Initialized'**
  String get initialized;

  /// Status value
  ///
  /// In en, this message translates to:
  /// **'Not Initialized'**
  String get notInitialized;

  /// Status label
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get request;

  /// Status value
  ///
  /// In en, this message translates to:
  /// **'Configured'**
  String get configured;

  /// Status value
  ///
  /// In en, this message translates to:
  /// **'Not Configured'**
  String get notConfigured;

  /// Card title
  ///
  /// In en, this message translates to:
  /// **'Offline Package Management'**
  String get offlinePackageManagement;

  /// Card description
  ///
  /// In en, this message translates to:
  /// **'View and delete offline package cache'**
  String get offlinePackageManagementDesc;

  /// Card title
  ///
  /// In en, this message translates to:
  /// **'Clear WebView Cache'**
  String get clearWebViewCache;

  /// Card description
  ///
  /// In en, this message translates to:
  /// **'Clear all WebView cache data'**
  String get clearWebViewCacheDesc;

  /// Card title
  ///
  /// In en, this message translates to:
  /// **'URL Match Test'**
  String get urlMatchTestCard;

  /// Card description
  ///
  /// In en, this message translates to:
  /// **'Test which bisName a URL matches to'**
  String get urlMatchTestCardDesc;

  /// Card title
  ///
  /// In en, this message translates to:
  /// **'Disable List Management'**
  String get disableListManagementCard;

  /// Card description
  ///
  /// In en, this message translates to:
  /// **'View and add disable items'**
  String get disableListManagementDesc;

  /// Card title
  ///
  /// In en, this message translates to:
  /// **'Force Update Check'**
  String get forceUpdateCheckCard;

  /// Card description
  ///
  /// In en, this message translates to:
  /// **'Force update check for specified bisName'**
  String get forceUpdateCheckDesc;

  /// Card title
  ///
  /// In en, this message translates to:
  /// **'Preload Test'**
  String get preloadTestCard;

  /// Card description
  ///
  /// In en, this message translates to:
  /// **'Test offline package preload status'**
  String get preloadTestDesc;

  /// Card title
  ///
  /// In en, this message translates to:
  /// **'Config Info'**
  String get configInfoCard;

  /// Card description
  ///
  /// In en, this message translates to:
  /// **'View current SDK config and rules'**
  String get configInfoCardDesc;

  /// Text field hint
  ///
  /// In en, this message translates to:
  /// **'Enter bisName'**
  String get bisNameHint;

  /// Button text
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Section label
  ///
  /// In en, this message translates to:
  /// **'Remote Available Packages:'**
  String get remoteAvailablePackages;

  /// Empty state text
  ///
  /// In en, this message translates to:
  /// **'No packages available'**
  String get noPackagesAvailable;

  /// Statistics label
  ///
  /// In en, this message translates to:
  /// **'Current {count} disable items'**
  String currentDisableItems(int count);

  /// Empty state text
  ///
  /// In en, this message translates to:
  /// **'No disable items'**
  String get noDisableItems;

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get test;

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// Dialog content
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete offline cache for \"{bisName}\"?'**
  String confirmDeletePackageCache(String bisName);

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Confirm Clear All'**
  String get confirmClearAll;

  /// Dialog content
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all offline cache? This cannot be undone.'**
  String get confirmDeleteAllCache;

  /// Button text
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get deleteAll;

  /// Snackbar message
  ///
  /// In en, this message translates to:
  /// **'Deleted {bisName}'**
  String deleted(String bisName);

  /// Snackbar message
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get deleteFailed;

  /// Snackbar message
  ///
  /// In en, this message translates to:
  /// **'Cleared all cache'**
  String get clearedAllCache;

  /// Snackbar message
  ///
  /// In en, this message translates to:
  /// **'Clear failed'**
  String get clearFailed;

  /// Stat card label
  ///
  /// In en, this message translates to:
  /// **'Offline Package Count'**
  String get offlinePackageCount;

  /// Stat card label
  ///
  /// In en, this message translates to:
  /// **'Total Size'**
  String get totalSize;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Offline Package List'**
  String get offlinePackageList;

  /// Package count label
  ///
  /// In en, this message translates to:
  /// **'{count} packages'**
  String packagesCount(int count);

  /// Empty state text
  ///
  /// In en, this message translates to:
  /// **'No offline package data'**
  String get noOfflinePackageData;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// Text field label
  ///
  /// In en, this message translates to:
  /// **'bisName'**
  String get bisNameLabel;

  /// Text field hint
  ///
  /// In en, this message translates to:
  /// **'e.g: act3-2108'**
  String get exampleBisName;

  /// Button text
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Update Logs'**
  String get updateLogs;

  /// Log count label
  ///
  /// In en, this message translates to:
  /// **'{count} logs'**
  String logCount(int count);

  /// Empty state text
  ///
  /// In en, this message translates to:
  /// **'Click start button for update check...'**
  String get clickStartButtonForUpdateCheck;

  /// Initial log message
  ///
  /// In en, this message translates to:
  /// **'Ready, enter bisName and click start'**
  String get readyEnterBisNameClickStart;

  /// Log message
  ///
  /// In en, this message translates to:
  /// **'Start update check: {bisName}'**
  String startUpdateCheck(String bisName);

  /// Log message
  ///
  /// In en, this message translates to:
  /// **'Local version: {version}'**
  String localVersion(String version);

  /// Log message
  ///
  /// In en, this message translates to:
  /// **'Requesting server...'**
  String get requestingServer;

  /// Log message
  ///
  /// In en, this message translates to:
  /// **'Not configured IOfflineRequest, cannot request server'**
  String get notConfiguredOfflineRequest;

  /// Log message
  ///
  /// In en, this message translates to:
  /// **'Triggered checkPackage'**
  String get triggeredCheckPackage;

  /// Log message
  ///
  /// In en, this message translates to:
  /// **'Update task submitted, check logs for progress'**
  String get updateTaskSubmitted;

  /// Log message
  ///
  /// In en, this message translates to:
  /// **'Found new version: {version}'**
  String foundNewVersion(String version);

  /// Log message
  ///
  /// In en, this message translates to:
  /// **'Current version: {version}'**
  String currentVersion(String version);

  /// Log message
  ///
  /// In en, this message translates to:
  /// **'Update check complete'**
  String get updateCheckComplete;

  /// Log message
  ///
  /// In en, this message translates to:
  /// **'Update failed: {error}'**
  String updateFailed(String error);

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'Clear Logs'**
  String get clearLogs;

  /// Section label
  ///
  /// In en, this message translates to:
  /// **'Available Offline Packages:'**
  String get availableOfflinePackages;

  /// Empty state text
  ///
  /// In en, this message translates to:
  /// **'No offline package data'**
  String get noOfflinePackageDataSmall;

  /// Snackbar message
  ///
  /// In en, this message translates to:
  /// **'Please enter bisName'**
  String get enterBisName;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Server Config'**
  String get serverConfig;

  /// Text field label
  ///
  /// In en, this message translates to:
  /// **'Offline Package Server Address'**
  String get offlinePackageServerAddress;

  /// Text field hint
  ///
  /// In en, this message translates to:
  /// **'e.g: http://192.168.1.100:9999'**
  String get exampleServerAddress;

  /// Button text
  ///
  /// In en, this message translates to:
  /// **'Get Offline Package List'**
  String get getOfflinePackageList;

  /// Dropdown label
  ///
  /// In en, this message translates to:
  /// **'Select Offline Package'**
  String get selectOfflinePackage;

  /// Dropdown hint
  ///
  /// In en, this message translates to:
  /// **'Please select package'**
  String get pleaseSelectPackage;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Business Config'**
  String get businessConfig;

  /// Text field label
  ///
  /// In en, this message translates to:
  /// **'Business Name (bisName)'**
  String get businessName;

  /// Text field hint
  ///
  /// In en, this message translates to:
  /// **'e.g: package'**
  String get examplePackage;

  /// Text field label
  ///
  /// In en, this message translates to:
  /// **'Access Address'**
  String get accessAddress;

  /// Text field hint
  ///
  /// In en, this message translates to:
  /// **'e.g: https://example.com?offweb=package'**
  String get exampleAccessAddress;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Loading Method'**
  String get loadingMethod;

  /// Card title
  ///
  /// In en, this message translates to:
  /// **'Use Offline Package Loading'**
  String get useOfflinePackageLoading;

  /// Card description
  ///
  /// In en, this message translates to:
  /// **'Accelerate H5 page loading via offline package'**
  String get useOfflinePackageLoadingDesc;

  /// Card title
  ///
  /// In en, this message translates to:
  /// **'Do Not Use Offline Package'**
  String get doNotUseOfflinePackage;

  /// Card description
  ///
  /// In en, this message translates to:
  /// **'Load online page directly (control group)'**
  String get doNotUseOfflinePackageDesc;

  /// Card title
  ///
  /// In en, this message translates to:
  /// **'Direct Navigate'**
  String get directNavigate;

  /// Card description
  ///
  /// In en, this message translates to:
  /// **'Open page without preload'**
  String get directNavigateDesc;

  /// Button text
  ///
  /// In en, this message translates to:
  /// **'Launch'**
  String get launch;

  /// Button text
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigate;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tools;

  /// Button label
  ///
  /// In en, this message translates to:
  /// **'View Screenshot Cache'**
  String get viewScreenshotCache;

  /// Button label
  ///
  /// In en, this message translates to:
  /// **'Clean Offline Package'**
  String get cleanOfflinePackage;

  /// Snackbar message
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get pleaseFillAllFields;

  /// Snackbar message
  ///
  /// In en, this message translates to:
  /// **'Please fill server address and bisName'**
  String get pleaseFillServerAndBisName;

  /// Snackbar message
  ///
  /// In en, this message translates to:
  /// **'Fetched {count} offline packages: {packages}'**
  String fetchedPackagesCount(int count, String packages);

  /// Snackbar message
  ///
  /// In en, this message translates to:
  /// **'Request failed: {statusCode}'**
  String requestFailed(int statusCode);

  /// Snackbar message
  ///
  /// In en, this message translates to:
  /// **'Fetch offline package failed: {error}'**
  String fetchOfflinePackageFailed(String error);

  /// Snackbar message
  ///
  /// In en, this message translates to:
  /// **'Please fill access address'**
  String get pleaseFillAccessAddress;

  /// Snackbar message
  ///
  /// In en, this message translates to:
  /// **'Init failed: {error}'**
  String initFailed(String error);

  /// Snackbar message
  ///
  /// In en, this message translates to:
  /// **'Please fill bisName first'**
  String get pleaseFillBisNameFirst;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Confirm Clean'**
  String get confirmClean;

  /// Dialog content
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clean offline package cache for \"{bisName}\"?'**
  String confirmCleanPackageCache(String bisName);

  /// Button text
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Snackbar message
  ///
  /// In en, this message translates to:
  /// **'Cleaned \"{bisName}\" offline package cache'**
  String cleanedPackageCache(String bisName);

  /// Snackbar message
  ///
  /// In en, this message translates to:
  /// **'Screenshot does not exist: {path}'**
  String screenshotNotExists(String path);

  /// Info text
  ///
  /// In en, this message translates to:
  /// **'Size: {bytes} bytes\nPath: {path}'**
  String sizeBytes(int bytes, String path);

  /// Error message
  ///
  /// In en, this message translates to:
  /// **'Image load failed: {error}'**
  String imageLoadFailed(String error);

  /// Snackbar message
  ///
  /// In en, this message translates to:
  /// **'Added \"{bisName}\" to disable list'**
  String addedToDisableList(String bisName);

  /// Snackbar message
  ///
  /// In en, this message translates to:
  /// **'Add failed: {error}'**
  String addFailed(String error);

  /// Snackbar message
  ///
  /// In en, this message translates to:
  /// **'\"{bisName}\" is disabled'**
  String bisNameIsDisabled(String bisName);

  /// Snackbar message
  ///
  /// In en, this message translates to:
  /// **'\"{bisName}\" is not disabled'**
  String bisNameNotDisabled(String bisName);

  /// Snackbar message
  ///
  /// In en, this message translates to:
  /// **'Test failed: {error}'**
  String testFailed(String error);

  /// Snackbar message
  ///
  /// In en, this message translates to:
  /// **'Delete requires re-init SDK config'**
  String get deleteRequiresReinitSdk;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Server Endpoints'**
  String get serverEndpoints;

  /// Endpoint name
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get health;

  /// Endpoint description
  ///
  /// In en, this message translates to:
  /// **'Health Check Endpoint'**
  String get healthCheck;

  /// Endpoint name
  ///
  /// In en, this message translates to:
  /// **'Query (Check Update)'**
  String get queryUpdate;

  /// Endpoint description
  ///
  /// In en, this message translates to:
  /// **'Query offline package update status'**
  String get queryUpdateDesc;

  /// Endpoint name
  ///
  /// In en, this message translates to:
  /// **'Query (No Update)'**
  String get queryNoUpdate;

  /// Endpoint description
  ///
  /// In en, this message translates to:
  /// **'Test no-update response'**
  String get queryNoUpdateDesc;

  /// Endpoint name
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get package;

  /// Endpoint description
  ///
  /// In en, this message translates to:
  /// **'Download offline package zip'**
  String get packageDesc;

  /// Endpoint name
  ///
  /// In en, this message translates to:
  /// **'Demo'**
  String get demo;

  /// Endpoint description
  ///
  /// In en, this message translates to:
  /// **'Demo HTML Page'**
  String get demoPage;

  /// Button text
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get testButton;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logs;

  /// Empty state text
  ///
  /// In en, this message translates to:
  /// **'Click button above to start test...'**
  String get clickButtonToStartTest;

  /// Status text
  ///
  /// In en, this message translates to:
  /// **'Testing...'**
  String get testing;

  /// Status text
  ///
  /// In en, this message translates to:
  /// **'Not tested'**
  String get notTested;

  /// Section label
  ///
  /// In en, this message translates to:
  /// **'Input URL'**
  String get inputUrl;

  /// Text field hint
  ///
  /// In en, this message translates to:
  /// **'e.g: https://m.example.com/act3/index.html'**
  String get exampleUrlHint;

  /// Button text
  ///
  /// In en, this message translates to:
  /// **'Test Match'**
  String get testMatch;

  /// Section label
  ///
  /// In en, this message translates to:
  /// **'Common Test URLs'**
  String get commonTestUrls;

  /// Section label
  ///
  /// In en, this message translates to:
  /// **'Match Result'**
  String get matchResult;

  /// Result text
  ///
  /// In en, this message translates to:
  /// **'No bisName matched'**
  String get noMatchBisName;

  /// Result text
  ///
  /// In en, this message translates to:
  /// **'Match failed'**
  String get matchFailed;

  /// Snackbar message
  ///
  /// In en, this message translates to:
  /// **'Load failed: {error}'**
  String loadFailed(String error);

  /// Page title
  ///
  /// In en, this message translates to:
  /// **'Preload Test'**
  String get preloadTestPage;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Test Logs'**
  String get testLogs;

  /// Empty state text
  ///
  /// In en, this message translates to:
  /// **'Click start button for preload test...'**
  String get clickStartButtonForPreloadTest;

  /// Initial log message
  ///
  /// In en, this message translates to:
  /// **'Ready, enter bisName and click start preload'**
  String get readyEnterBisNameClickStartPreload;

  /// Log message
  ///
  /// In en, this message translates to:
  /// **'Getting available packages from server...'**
  String get gettingAvailablePackages;

  /// Log message
  ///
  /// In en, this message translates to:
  /// **'Server has {count} offline packages'**
  String serverHasPackagesCount(int count);

  /// Log message
  ///
  /// In en, this message translates to:
  /// **'Fetch failed: {statusCode}'**
  String fetchFailed(int statusCode);

  /// Log message
  ///
  /// In en, this message translates to:
  /// **'Fetch package list error: {error}'**
  String fetchPackageListError(String error);

  /// Log message
  ///
  /// In en, this message translates to:
  /// **'Start preload test: {bisName}'**
  String startPreloadTest(String bisName);

  /// Log message
  ///
  /// In en, this message translates to:
  /// **'Local version: none'**
  String get localVersionNone;

  /// Log message
  ///
  /// In en, this message translates to:
  /// **'Querying server endpoint...'**
  String get queryingServerEndpoint;

  /// Log message
  ///
  /// In en, this message translates to:
  /// **'Query result: {message}'**
  String queryResult(String message);

  /// Log message
  ///
  /// In en, this message translates to:
  /// **'Found new version: {version}, preparing download...'**
  String foundNewVersionPrepareDownload(String version);

  /// Log message
  ///
  /// In en, this message translates to:
  /// **'Already latest, no download needed'**
  String get alreadyLatestNoDownload;

  /// Log message
  ///
  /// In en, this message translates to:
  /// **'Preload test complete, elapsed: {ms}ms'**
  String preloadTestComplete(int ms);

  /// Log message
  ///
  /// In en, this message translates to:
  /// **'Preload test failed: {error}'**
  String preloadTestFailed(String error);

  /// Log message
  ///
  /// In en, this message translates to:
  /// **'Trigger download flow...'**
  String get triggerDownloadFlow;

  /// Log message
  ///
  /// In en, this message translates to:
  /// **'Download complete, new version: {version}'**
  String downloadCompleteNewVersion(String version);

  /// Log message
  ///
  /// In en, this message translates to:
  /// **'Download complete'**
  String get downloadComplete;

  /// Log message
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String downloadFailedError(String error);

  /// Log message
  ///
  /// In en, this message translates to:
  /// **'Query URL: {url}'**
  String queryUrl(String url);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
