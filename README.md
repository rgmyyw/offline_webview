[简体中文](https://github.com/rgmyyw/offline_webview/blob/main/README_zh.md) | **English**

---

# offline_webview

A lightweight high-performance Flutter SDK for offline web package loading.

## Features

- **Offline Package Management**: Download, cache, and serve web resources locally
- **URL Matching**: Flexible rule-based URL to bisName matching (param mode & rule mode)
- **Flow Pipeline**: Extensible chain-of-responsibility processing pipeline
- **WebView Integration**: Seamless InAppWebView (iOS/Android) integration with screenshot cache and vConsole
- **Performance Monitor**: Built-in debug floating panel showing loading timeline comparison
- **Monitoring & Reporting**: Built-in logging, monitoring, and data reporting
- **Local Server**: Per-package HTTP server on localhost, serving resources without file:// hacks
- **Fastlane CI/CD**: One-command build & distribute to Pgyer for iOS/Android

## Installation

```yaml
dependencies:
  offline_webview: ^1.1.0
```

## Quick Start

### 1. Start the test server

```bash
cd tool
python3 server.py
# Server auto-detects LAN IP and runs at http://<your-lan-ip>:18730
```

### 2. Initialize the SDK

```dart
import 'package:offline_webview/offline_webview.dart';

// Build config (preDownloadAll downloads all available packages from server)
final config = OfflineConfigBuilder()
    .isOpen(true)
    .preDownloadAll(true)
    .build();

// Build params
final params = OfflineParams()
    .config(config)
    .isDebug(true)
    .logBlock((level, message) => print(message))
    .reportBlock((event, bisName, params) => print('Report: $event'))
    .monitorBlock((type, data) => print('Monitor: $type'))
    .requestServer(YourRequest());

await OfflineWebClient.init(params);
```

### 3. Use OfflineWebView

```dart
// Param mode: URL contains ?offweb=bisName
OfflineWebView(
  initialUrl: 'https://example.com/page?offweb=my-bis-name',
  enableVConsole: true,  // inject vConsole debug panel
)

// With controller for reload
final controller = OfflineWebViewController();
OfflineWebView(
  initialUrl: 'https://example.com/page?offweb=my-bis-name',
  controller: controller,
  onLoadTiming: (totalMs) => print('Loaded in ${totalMs}ms'),
)

// Reload offline web
controller.reloadOfflineWeb();
```

### 4. Implement IOfflineRequest

```dart
class YourRequest extends IOfflineRequest {
  @override
  void requestPackageInfo(
    String bisName,
    String version,
    RequestCallback<OfflinePackageInfo> callback,
  ) async {
    final url = Uri.parse('http://your-server:18730/offweb').replace(
      queryParameters: {'bisName': bisName, 'offlineZipVer': version},
    );
    final response = await http.get(url);
    final json = jsonDecode(response.body);
    callback.onSuccess(OfflinePackageInfo.fromJson(json));
  }

  @override
  void requestAllBisNames(RequestCallback<List<String>> callback) async {
    final response = await http.get(Uri.parse('http://your-server:18730'));
    final json = jsonDecode(response.body);
    final packages = (json['packages'] as List).map((e) => e.toString()).toList();
    callback.onSuccess(packages);
  }
}
```

## Creating Offline Packages

An offline package is a standard `.zip` file containing your web resources and a version manifest.

### Package structure

```
my-package.zip
├── .offweb.json      # Required: version manifest
├── index.html        # Entry point
├── css/
│   └── style.css
├── js/
│   └── app.js
└── images/
    └── logo.png
```

### Version manifest (`.offweb.json`)

Place this file at the root of the zip:

```json
{
  "bisName": "my-package",
  "version": "v1"
}
```

### Requirements

- **`.offweb.json`** must exist at the zip root with `bisName` and `version` fields
- **`index.html`** must exist as the entry point
- All resource paths (CSS, JS, images) should use **relative paths**
- H5 pages must support null-origin for cookie/storage (loaded from `localhost`)

### Upload to server

Place the zip file in the server's `packages/` directory, or use the built-in upload page at `http://<server-ip>:18730/upload`.

### Server query API

When the SDK queries the server, the response format is:

```json
{
  "bisName": "my-package",
  "result": 1,
  "url": "http://server:18730/package?bisName=my-package",
  "refreshMode": 0,
  "version": "v2"
}
```

| Field | Description |
|-------|-------------|
| `result` | `-1` = disabled, `0` = same version, `1` = update available |
| `url` | Download URL for the zip package |
| `refreshMode` | `0` = normal, `1` = force refresh |
| `version` | Latest version string |

## URL Matching

### Param mode

Append `?offweb=<bisName>` to the URL. The SDK automatically intercepts it:

```dart
OfflineWebView(
  initialUrl: 'https://example.com/page?offweb=my-bis-name',
)
```

### Rule mode

Configure `OfflineRuleConfig` to match URLs by host/path patterns without modifying the URL:

```dart
final params = OfflineParams()
    .config(OfflineConfigBuilder().isOpen(true).build())
    .setRule(OfflineRuleConfig(
      rules: [
        OfflineRuleItem(host: 'example.com', path: '/app/*', bisName: 'my-app'),
      ],
    ))
    .requestServer(YourRequest());
```

## Performance Monitor

The SDK includes a debug-mode performance monitor with a draggable floating panel:

```dart
FloatingPerformancePanel(
  child: OfflineWebView(initialUrl: '...'),
)

// Or standalone (OfflineWebView embeds it internally)
FloatingPerformancePanel()
```

| Metric | Description |
|--------|-------------|
| `webViewCreatedMs` | Time from widget creation to WebView ready |
| `firstPaintMs` | Time to first visual paint |
| `loadCompleteMs` | Time to page fully loaded |
| `queryMs` | Offline query phase (offline mode only) |
| `downloadMs` | Package download phase (offline mode only) |
| `unzipMs` | Package extraction phase (offline mode only) |

Color coding: green (<50ms), blue (<200ms), yellow (<500ms), red (>=500ms).

## Configuration

```dart
final config = OfflineConfigBuilder()
    .isOpen(true)                      // Enable/disable offline feature
    .preDownloadAll(true)              // Pre-download all packages from server
    .addPreDownload('bis-name-1')      // Pre-download specific packages
    .addPreDownload('bis-name-2')
    .addDisable('bis-name-3')          // Disable specific packages
    .build();
```

## Local Development Server

A Python HTTP server is provided for local testing:

```bash
cd tool
python3 server.py
```

**Server endpoints:**
- `GET /` - Server info & registered packages
- `GET /health` - Health check
- `GET /offweb?bisName=xxx&offlineZipVer=xxx` - Query package update
- `GET /package?bisName=xxx` - Download package zip
- `GET /upload` - Web upload page
- `POST /upload` - Upload zip package
- `GET /demo` - Demo HTML page

## Architecture

```
+-------------------------------------------------------------+
|                     OfflineWebClient                         |
+-------------------------------------------------------------+
                            |
                            v
+-------------------------------------------------------------+
|                    OfflineWebManager                         |
+-------------------------------------------------------------+
                            |
              +-------------+-------------+
              |                           |
              v                           v
+---------------------------+ +-----------------------------+
|   ResourceFlow Pipeline   | |   PerformanceMonitor         |
|  FetchPackageFlow         | |   (singleton, Stream-based)  |
|    -> DownloadFlow        | |   ↳ FloatingPerformancePanel |
|    -> ParsePackageFlow    | +-----------------------------+
|    -> ReplaceResFlow      |
+---------------------------+
              |
              v
+-------------------------------------------------------------+
|                   OfflineWebView                             |
|   (InAppWebView + LocalServer + WebViewPreloadPool)          |
+-------------------------------------------------------------+
```

## CI/CD with Fastlane

```bash
bundle install

# Build & upload iOS
bundle exec fastlane build_ios

# Build & upload Android
bundle exec fastlane build_android
```

## Platform Support

- iOS (InAppWebView / WKWebView)
- Android (InAppWebView / WebView)
- Flutter Web (limited)

## License

MIT License - see [LICENSE](LICENSE) file
