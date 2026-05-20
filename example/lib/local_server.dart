import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:offline_webview/offline_webview.dart';

import 'config.dart';

/// bisName → 版本号。
final Map<String, String> _versions = {};

/// bisName → 远程下载服务器地址（http 开头）。
final Map<String, String> _remoteUrls = {};

/// bisName → 本地预加载的 zip 数据。
final Map<String, Uint8List> _localZipData = {};

/// 启动本地 HTTP 服务器。
///
/// 从 assets/packages.json 读取包版本注册表。
/// downloadUrl 以 http 开头 → 远程下载；以 assets/ 开头 → 本地 /package。
///
/// 端点:
/// - GET /offweb?bisName=xx&offlineZipVer=xx — 查询包信息
/// - GET /package?bisName=xx — 下载本地包 zip
/// - GET /demo — 演示页面
/// - GET /health — 健康检查
Future<HttpServer> startLocalServer() async {
  final configStr = await rootBundle.loadString('assets/packages.json');
  final configList = jsonDecode(configStr) as List<dynamic>;

  for (final item in configList) {
    final map = item as Map<String, dynamic>;
    final bisName = map['bisName'] as String;
    _versions[bisName] = map['version'] as String? ?? 'v1';
    final downloadUrl = map['downloadUrl'] as String? ?? '';

    debugPrint('[LocalServer] 注册包: bisName=$bisName, downloadUrl=$downloadUrl');
    if (downloadUrl.startsWith('http')) {
      _remoteUrls[bisName] = downloadUrl;
    } else if (downloadUrl.startsWith('assets/')) {
      try {
        final byteData = await rootBundle.load(downloadUrl);
        _localZipData[bisName] = byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        );
        debugPrint(
          '[LocalServer] ✅ Asset加载成功: $bisName, '
          '${_localZipData[bisName]!.length} 字节',
        );
      } catch (e) {
        debugPrint('[LocalServer] ❌ Asset加载失败: $bisName, 错误: $e');
      }
    }
  }

  debugPrint('[LocalServer] 版本注册表: $_versions');
  if (_remoteUrls.isNotEmpty) {
    debugPrint('[LocalServer] 远程下载: $_remoteUrls');
  }
  if (_localZipData.isNotEmpty) {
    final entries = _localZipData.entries
        .map((e) => '${e.key}: ${e.value.length} 字节')
        .join(', ');
    debugPrint('[LocalServer] 本地Asset包: $entries');
  } else {
    debugPrint('[LocalServer] ⚠️ 警告: 没有加载到任何本地Asset包!');
  }

  final server = await HttpServer.bind('localhost', AppConfig.serverPort);
  debugPrint('[LocalServer] 服务器启动成功: ${AppConfig.baseUrl}');

  server.listen((HttpRequest request) async {
    final path = request.uri.path;
    Logger.d('LocalServer', '${request.method} $path');

    try {
      if (path == '/' || path == '/index') {
        await _handleIndex(request);
      } else if (path == '/health') {
        await _handleHealth(request);
      } else if (path == '/offweb') {
        await _handleOffweb(request);
      } else if (path == '/package') {
        await _handlePackage(request);
      } else if (path == '/demo') {
        await _handleDemo(request);
      } else {
        request.response.statusCode = 404;
        request.response.write('Not found: $path');
        await request.response.close();
      }
    } catch (e, st) {
      Logger.e('LocalServer', '请求处理错误 $path: $e\n$st');
      try {
        request.response.statusCode = 500;
        request.response.write('Server error: $e');
        await request.response.close();
      } catch (_) {}
    }
  });

  return server;
}

Future<void> _handleIndex(HttpRequest request) async {
  try {
    final body = jsonEncode({
      'status': 'ok',
      'port': AppConfig.serverPort,
      'packages': _versions.keys.toList(),
      'endpoints': {
        '/health': '健康检查',
        '/offweb?bisName=xxx&offlineZipVer=xxx': '查询离线包',
        '/package?bisName=xxx': '下载离线包 zip',
        '/demo': '演示页面',
      },
    });
    request.response.headers.set(
      'Content-Type',
      'application/json; charset=utf-8',
    );
    request.response.add(utf8.encode(body));
    await request.response.close();
  } catch (e, st) {
    Logger.e('LocalServer', '_handleIndex 错误: $e\n$st');
    request.response.statusCode = 500;
    request.response.write('Internal error: $e');
    await request.response.close();
  }
}

Future<void> _handleHealth(HttpRequest request) async {
  final body = jsonEncode({
    'status': 'ok',
    'port': AppConfig.serverPort,
    'packages': _versions,
  });
  request.response.headers.set(
    'Content-Type',
    'application/json; charset=utf-8',
  );
  request.response.write(body);
  await request.response.close();
}

Future<void> _handleOffweb(HttpRequest request) async {
  final bisName = request.uri.queryParameters['bisName'] ?? '';
  final offlineZipVer = request.uri.queryParameters['offlineZipVer'] ?? '0';

  Logger.d('LocalServer', '/offweb 业务=$bisName 版本=$offlineZipVer');

  String body;
  final serverVersion = _versions[bisName];

  if (serverVersion == null) {
    body = jsonEncode({
      'bisName': bisName,
      'result': -1,
      'version': '0',
      'url': '',
      'refreshMode': 0,
    });
  } else if (offlineZipVer == '0' || offlineZipVer != serverVersion) {
    final remote = _remoteUrls[bisName];
    final hasLocal = _localZipData.containsKey(bisName);
    Logger.d(
      'LocalServer',
      '需要更新 - remote=${remote ?? "null"}, hasLocal=$hasLocal, localZipKeys=${_localZipData.keys.toList()}',
    );
    final String downloadUrl;
    if (remote != null) {
      downloadUrl = remote;
    } else if (hasLocal) {
      downloadUrl = '${AppConfig.baseUrl}/package?bisName=$bisName';
    } else {
      downloadUrl = '';
    }
    body = jsonEncode({
      'bisName': bisName,
      'result': 1,
      'version': serverVersion,
      'url': downloadUrl,
      'refreshMode': 0,
    });
  } else {
    body = jsonEncode({
      'bisName': bisName,
      'result': 0,
      'version': offlineZipVer,
      'url': '',
      'refreshMode': 0,
    });
  }

  request.response.headers.set(
    'Content-Type',
    'application/json; charset=utf-8',
  );
  request.response.write(body);
  await request.response.close();
}

Future<void> _handlePackage(HttpRequest request) async {
  final bisName = request.uri.queryParameters['bisName'] ?? '';
  Logger.d('LocalServer', '/package 业务=$bisName');

  final data = _localZipData[bisName];
  if (data == null) {
    request.response.statusCode = 404;
    request.response.write('Package not found: $bisName');
    await request.response.close();
    return;
  }

  request.response.headers.set('Content-Type', 'application/zip');
  request.response.headers.set('Content-Length', data.length.toString());
  request.response.add(data);
  await request.response.close();
}

Future<void> _handleDemo(HttpRequest request) async {
  const html = '''
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>离线包测试页面</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      min-height: 100vh;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: #fff;
      padding: 20px;
    }
    .container {
      max-width: 500px;
      margin: 0 auto;
    }
    .header {
      text-align: center;
      margin-bottom: 24px;
    }
    .icon {
      font-size: 64px;
      margin-bottom: 12px;
    }
    h1 {
      font-size: 24px;
      margin-bottom: 8px;
      text-shadow: 0 2px 4px rgba(0,0,0,0.2);
    }
    .badge {
      display: inline-block;
      padding: 6px 16px;
      border-radius: 20px;
      font-size: 12px;
      background: #ff9800;
      font-weight: 600;
    }
    .card {
      background: rgba(255, 255, 255, 0.15);
      border-radius: 16px;
      padding: 20px;
      backdrop-filter: blur(10px);
      margin-bottom: 16px;
      box-shadow: 0 4px 20px rgba(0,0,0,0.1);
    }
    .card-title {
      font-size: 16px;
      font-weight: 600;
      margin-bottom: 16px;
      padding-bottom: 12px;
      border-bottom: 1px solid rgba(255,255,255,0.2);
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .card-title span { font-size: 20px; }
    .info-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 12px;
    }
    .info-item {
      background: rgba(255,255,255,0.1);
      border-radius: 10px;
      padding: 12px;
    }
    .info-label {
      font-size: 11px;
      opacity: 0.7;
      margin-bottom: 4px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    .info-value {
      font-size: 14px;
      font-weight: 600;
      word-break: break-all;
    }
    .feature-list {
      display: flex;
      flex-direction: column;
      gap: 10px;
    }
    .feature-item {
      display: flex;
      align-items: flex-start;
      gap: 10px;
      font-size: 14px;
      line-height: 1.4;
    }
    .feature-icon {
      font-size: 18px;
      flex-shrink: 0;
    }
    .status-row {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 10px 0;
      border-bottom: 1px solid rgba(255,255,255,0.1);
    }
    .status-row:last-child { border-bottom: none; }
    .status-label { font-size: 14px; opacity: 0.8; }
    .status-value {
      font-size: 14px;
      font-weight: 600;
    }
    .status-value.success { color: #4caf50; }
    .btn-group {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 12px;
      margin-top: 8px;
    }
    .btn {
      background: rgba(255,255,255,0.2);
      border: none;
      border-radius: 10px;
      padding: 12px 16px;
      color: #fff;
      font-size: 14px;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.2s;
    }
    .btn:hover {
      background: rgba(255,255,255,0.3);
      transform: translateY(-1px);
    }
    .btn:active {
      transform: translateY(0);
    }
    .footer {
      text-align: center;
      margin-top: 20px;
      font-size: 12px;
      opacity: 0.6;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="icon">&#128640;</div>
      <h1>离线包测试页面</h1>
      <div class="badge">&#9733; 在线模式</div>
    </div>

    <div class="card">
      <div class="card-title"><span>&#128197;</span> 离线包信息</div>
      <div class="info-grid">
        <div class="info-item">
          <div class="info-label">业务名称</div>
          <div class="info-value" id="bisName">demo</div>
        </div>
        <div class="info-item">
          <div class="info-label">包版本</div>
          <div class="info-value" id="version">v1.0.0</div>
        </div>
        <div class="info-item">
          <div class="info-label">加载方式</div>
          <div class="info-value">本地服务</div>
        </div>
        <div class="info-item">
          <div class="info-label">资源协议</div>
          <div class="info-value">HTTP</div>
        </div>
      </div>
    </div>

    <div class="card">
      <div class="card-title"><span>&#9881;</span> 资源加载状态</div>
      <div class="status-row">
        <span class="status-label">HTML 页面</span>
        <span class="status-value success">&#10004; 已加载</span>
      </div>
      <div class="status-row">
        <span class="status-label">CSS 样式</span>
        <span class="status-value success">&#10004; 已加载</span>
      </div>
      <div class="status-row">
        <span class="status-label">JS 脚本</span>
        <span class="status-value success">&#10004; 已加载</span>
      </div>
      <div class="status-row">
        <span class="status-label">本地资源</span>
        <span class="status-value success">&#10004; 可访问</span>
      </div>
    </div>

    
    <div class="card">
      <div class="card-title"><span>&#128757;</span> 交互测试</div>
      <div class="btn-group">
        <button class="btn" onclick="testAlert()">测试弹窗</button>
        <button class="btn" onclick="testConsole()">测试控制台</button>
      </div>
    </div>

    <div class="footer">
      加载时间: <span id="loadTime"></span>
    </div>
  </div>

  <script>
    document.getElementById('loadTime').textContent = new Date().toLocaleString('zh-CN');

    function testAlert() {
      alert('&#128079; 离线包弹窗功能正常！');
    }

    function testConsole() {
      console.log('========== 离线包调试信息 ==========');
      console.log('业务名称:', document.getElementById('bisName').textContent);
      console.log('页面地址:', window.location.href);
      console.log('协议:', window.location.protocol);
      console.log('主机:', window.location.hostname);
      console.log('端口:', window.location.port || '默认');
      console.log('用户代理:', navigator.userAgent);
      console.log('在线状态:', navigator.onLine ? '在线' : '离线');
      console.log('=====================================');
      alert('&#128221; 已在控制台输出调试信息\\n请打开开发者工具查看');
    }

    console.log('&#127919; 离线包测试页面已加载');
    console.log('&#128640; 当前模式: 离线包（localhost）');
  </script>
</body>
</html>
''';

  request.response.headers.set('Content-Type', 'text/html; charset=utf-8');
  request.response.write(html);
  await request.response.close();
}
