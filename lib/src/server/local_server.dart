import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

import '../core/offline_const.dart';
import '../util/file_mgr.dart';
import '../util/off_web_log.dart';

/// 离线包资源本地 HTTP 服务器（每包独立端口）。
///
/// 每个 bisName 启动独立的 [HttpServer]，根目录直接映射到该包的 `cur` 目录。
///
/// 示例：
/// - xxx → `http://localhost:10001/index.html`
/// - xxy → `http://localhost:10002/index.html`
class LocalServer {
  static final LocalServer _instance = LocalServer._internal();
  static LocalServer get instance => _instance;
  LocalServer._internal();

  /// bisName → HttpServer
  final Map<String, HttpServer> _servers = {};

  /// bisName → port
  final Map<String, int> _ports = {};

  /// 为指定的 bisName 启动独立 HTTP 服务器。
  ///
  /// 如果该 bisName 的服务器已在运行，直接返回。
  Future<void> startForBisName(String bisName) async {
    if (_servers.containsKey(bisName)) return;

    const tag = 'LocalServer';
    try {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _servers[bisName] = server;
      _ports[bisName] = server.port;
      Logger.i(tag, '$bisName 服务器启动: http://localhost:${server.port}');

      server.listen(
        (request) => _handleRequest(request, bisName),
        onError: (error) {
          Logger.e(tag, '$bisName 服务器错误: $error');
        },
      );
    } catch (e) {
      Logger.e(tag, '$bisName 服务器启动失败: $e');
    }
  }

  /// 停止指定 bisName 的服务器。
  Future<void> stopForBisName(String bisName) async {
    final server = _servers.remove(bisName);
    if (server != null) {
      await server.close(force: true);
      _ports.remove(bisName);
      Logger.i('LocalServer', '$bisName 服务器已停止');
    }
  }

  /// 停止所有服务器。
  Future<void> stopAll() async {
    for (final server in _servers.values) {
      await server.close(force: true);
    }
    _servers.clear();
    _ports.clear();
    Logger.i('LocalServer', '所有服务器已停止');
  }

  /// 检查所有已注册的服务器健康状态，自动重启死掉的服务器。
  ///
  /// 注意：此方法与 startForBisName/stopForBisName 存在理论上的并发竞态
  /// （Dart 单线程模型下实际风险极低，仅在 await 切换点可能出现）。
  Future<void> healthCheckAll() async {
    const tag = 'LocalServer';
    if (_servers.isEmpty) return;

    final deadEntries = <MapEntry<String, int>>[];

    final client = HttpClient();
    client.connectionTimeout = const Duration(milliseconds: 500);

    for (final entry in _servers.entries.toList()) {
      final bisName = entry.key;
      final port = _ports[bisName];
      if (port == null) continue;

      try {
        final request = await client.headUrl(
          Uri.parse('http://localhost:$port/'),
        );
        await request.close();
      } catch (_) {
        deadEntries.add(MapEntry(bisName, port));
      }
    }

    client.close(force: true);

    if (deadEntries.isEmpty) {
      Logger.i(tag, '健康检查通过，所有服务器正常');
      return;
    }

    Logger.w(tag, '检测到 ${deadEntries.length} 个服务器已死，开始重启');

    for (final entry in deadEntries) {
      await _restartServer(entry.key, entry.value);
    }
  }

  /// 重启指定 bisName 的服务器，保持原端口不变。
  Future<void> _restartServer(String bisName, int oldPort) async {
    const tag = 'LocalServer';

    final oldServer = _servers.remove(bisName);
    if (oldServer != null) {
      await oldServer.close(force: true);
    }

    for (int attempt = 1; attempt <= 3; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      try {
        final server = await HttpServer.bind(
          InternetAddress.loopbackIPv4,
          oldPort,
        );
        _servers[bisName] = server;
        _ports[bisName] = server.port;
        server.listen(
          (request) => _handleRequest(request, bisName),
          onError: (error) {
            Logger.e(tag, '$bisName 服务器错误: $error');
          },
        );
        Logger.i(tag, '$bisName 服务器重启成功: http://localhost:$oldPort');
        return;
      } catch (e) {
        Logger.w(
          tag,
          '$bisName 重启失败 (第$attempt次): $e',
        );
      }
    }

    _ports.remove(bisName);
    Logger.e(tag, '$bisName 重启彻底失败，已移除');
  }

  /// 获取指定 bisName 的服务器基础 URL。
  ///
  /// 如果该 bisName 没有启动服务器，返回 null。
  String? getBaseUrl(String bisName) {
    final port = _ports[bisName];
    if (port == null) return null;
    return 'http://localhost:$port';
  }

  /// 获取指定 bisName 的服务器端口。
  int? getPort(String bisName) => _ports[bisName];

  /// 指定 bisName 的服务器是否在运行。
  bool isRunning(String bisName) => _servers.containsKey(bisName);

  /// 构建离线包资源 URL。
  ///
  /// [bisName] 业务名称，[filePath] 相对于 cur 目录的文件路径。
  /// 返回如 `http://localhost:12345/images/xxx.webp`。
  String? buildUrl(String bisName, String filePath) {
    final base = getBaseUrl(bisName);
    if (base == null) return null;
    final normalized = filePath.replaceAll('\\', '/');
    return '$base/$normalized';
  }

  /// 构建离线包 index.html URL（含查询参数和 fragment）。
  String? buildIndexUrl(
    String bisName, {
    Map<String, String>? queryParams,
    String? fragment,
  }) {
    final base = getBaseUrl(bisName);
    if (base == null) return null;
    final url = '$base/${OfflineFileName.html}';
    final qs = queryParams != null && queryParams.isNotEmpty
        ? '?${_encodeQueryParams(queryParams)}'
        : '';
    final frag = fragment != null && fragment.isNotEmpty ? '#$fragment' : '';
    return '$url$qs$frag';
  }

  /// 检测给定 URL 是否来自任一本地服务器。
  static bool isLocalServerUrl(String url) {
    final ports = LocalServer._instance._ports.values;
    for (final port in ports) {
      if (url.startsWith('http://localhost:$port/')) return true;
    }
    return false;
  }

  Future<void> _handleRequest(HttpRequest request, String bisName) async {
    final path = request.uri.path;
    final tag = 'LocalServer';

    // 根路由 "/" → 重定向到 index.html
    final filePath = path == '/' ? OfflineFileName.html : path.substring(1);

    if (request.method == 'HEAD') {
      request.response.statusCode = 200;
      await request.response.close();
      return;
    }

    Logger.d(tag, '$bisName GET $path => $filePath');

    try {
      final bisDir = await FileMgr.getBisDir(bisName);
      final fullPath = p.join(bisDir, OfflineDirName.cur, filePath);
      final file = File(fullPath);

      if (!file.existsSync()) {
        request.response.statusCode = 404;
        request.response.write('Not found: $filePath');
        await request.response.close();
        return;
      }

      final mimeType = _getMimeType(fullPath);
      request.response.headers.set('Content-Type', mimeType);
      request.response.headers.set('Access-Control-Allow-Origin', '*');
      request.response.headers.set('Cache-Control', 'no-cache');

      await file.openRead().pipe(request.response);
    } catch (e) {
      Logger.e(tag, '$bisName 文件服务错误: $e');
      request.response.statusCode = 500;
      await request.response.close();
    }
  }

  String _getMimeType(String filePath) {
    final mime = lookupMimeType(filePath);
    if (mime != null) return mime;

    final ext = p.extension(filePath).toLowerCase();
    switch (ext) {
      case '.woff':
        return 'font/woff';
      case '.woff2':
        return 'font/woff2';
      case '.ico':
        return 'image/x-icon';
      case '.webmanifest':
        return 'application/manifest+json';
      default:
        return 'application/octet-stream';
    }
  }

  static String _encodeQueryParams(Map<String, String> params) {
    final parts = <String>[];
    for (final entry in params.entries) {
      parts.add(
        '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
      );
    }
    return parts.join('&');
  }
}
