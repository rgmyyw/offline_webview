#!/usr/bin/env dart
/// Generates a test offline package zip file for the example app.
///
/// Usage: dart run tools/create_test_package.dart
///
/// Creates:
/// - index.html — a simple styled page confirming offline load success
/// - .offweb.json — package metadata with bisName and version
/// Zips them into example/assets/test-package.zip

import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';

void main() {
  // 1. Create temp directory
  final tempDir = Directory.systemTemp.createTempSync('offweb_test_pkg_');
  print('Temp dir: ${tempDir.path}');

  try {
    // 2. Write index.html
    final htmlContent = '''
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>离线包加载成功</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: #fff;
      padding: 20px;
    }
    .container {
      text-align: center;
      max-width: 400px;
      width: 100%;
    }
    .icon {
      font-size: 72px;
      margin-bottom: 20px;
    }
    h1 {
      font-size: 28px;
      margin-bottom: 12px;
      text-shadow: 0 2px 4px rgba(0,0,0,0.2);
    }
    .subtitle {
      font-size: 16px;
      opacity: 0.9;
      margin-bottom: 24px;
      line-height: 1.5;
    }
    .info-card {
      background: rgba(255, 255, 255, 0.15);
      border-radius: 12px;
      padding: 16px;
      backdrop-filter: blur(10px);
      margin-bottom: 16px;
    }
    .info-row {
      display: flex;
      justify-content: space-between;
      padding: 8px 0;
      border-bottom: 1px solid rgba(255,255,255,0.1);
      font-size: 14px;
    }
    .info-row:last-child { border-bottom: none; }
    .info-label { opacity: 0.7; }
    .info-value { font-weight: 600; }
    .load-time {
      font-size: 12px;
      opacity: 0.7;
      margin-top: 16px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="icon">&#9989;</div>
    <h1>离线包加载成功</h1>
    <p class="subtitle">
      恭喜！这个页面是从本地离线包加载的，<br>
      无需网络连接即可访问。
    </p>
    <div class="info-card">
      <div class="info-row">
        <span class="info-label">包名</span>
        <span class="info-value">test-offline-package</span>
      </div>
      <div class="info-row">
        <span class="info-label">版本</span>
        <span class="info-value">v1</span>
      </div>
      <div class="info-row">
        <span class="info-label">来源</span>
        <span class="info-value">本地缓存</span>
      </div>
    </div>
    <p class="load-time" id="loadTime"></p>
  </div>
  <script>
    document.getElementById('loadTime').textContent =
      '加载时间: ' + new Date().toLocaleString('zh-CN');
  </script>
</body>
</html>
''';

    final htmlFile = File('${tempDir.path}/index.html');
    htmlFile.writeAsStringSync(htmlContent);
    print('Created index.html');

    // 3. Write .offweb.json
    final configContent = jsonEncode({
      'bisName': 'test-offline-package',
      'ver': 'v1',
    });

    final configFile = File('${tempDir.path}/.offweb.json');
    configFile.writeAsStringSync(configContent);
    print('Created .offweb.json');

    // 4. Create zip archive using the archive package
    final archive = Archive();

    // Add index.html
    final htmlBytes = htmlFile.readAsBytesSync();
    archive.addFile(ArchiveFile('index.html', htmlBytes.length, htmlBytes));

    // Add .offweb.json
    final configBytes = configFile.readAsBytesSync();
    archive.addFile(ArchiveFile('.offweb.json', configBytes.length, configBytes));

    // Encode to zip
    final zipBytes = ZipEncoder().encode(archive);

    // 5. Save to example/assets/test-package.zip
    final outputDir = Directory('${_projectRoot()}/example/assets');
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }

    final outputFile = File('${outputDir.path}/test-package.zip');
    outputFile.writeAsBytesSync(zipBytes);
    print('Generated: ${outputFile.path}');
    print('Size: ${zipBytes.length} bytes');
  } finally {
    // Cleanup temp dir
    tempDir.deleteSync(recursive: true);
    print('Cleaned up temp directory');
  }
}

/// Walks up from this script to find the project root (contains pubspec.yaml).
String _projectRoot() {
  var dir = File.fromUri(Platform.script).parent.parent;
  while (dir.path != '/') {
    if (File('${dir.path}/pubspec.yaml').existsSync()) {
      return dir.path;
    }
    dir = dir.parent;
  }
  // Fallback: assume script is in tools/ of the SDK
  return File.fromUri(Platform.script).parent.parent.path;
}
