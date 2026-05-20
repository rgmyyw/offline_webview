import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:offline_webview/offline_webview.dart';

import '../config.dart';

/// 本地服务器端点调试页面。
///
/// 此页面提供按钮以手动测试每个端点：
/// - /health - 健康检查
/// - /offweb - 查询离线包更新
/// - /package - 下载包 zip
class ServerDebugPage extends StatefulWidget {
  const ServerDebugPage({super.key});

  @override
  State<ServerDebugPage> createState() => _ServerDebugPageState();
}

class _ServerDebugPageState extends State<ServerDebugPage> {
  String _logText = '';
  String _healthResult = '-';
  String _queryResult = '-';
  String _packageResult = '-';

  void _log(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _logText = '[$timestamp] $message\n$_logText';
    });
  }

  Future<void> _testHealth() async {
    const tag = 'ServerDebug';
    Logger.d(tag, '测试 /health...');
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/health');
      Logger.d(tag, '地址: $url');
      final response = await http.get(url);
      setState(() => _healthResult = response.body);
      _log('/health OK: ${response.statusCode}');
    } catch (e, stack) {
      Logger.e(tag, '/health 失败: $e');
      Logger.d(tag, '堆栈: $stack');
      _log('/health 失败: $e');
    }
  }

  Future<void> _testQuery() async {
    const tag = 'ServerDebug';
    Logger.d(tag, '测试 /offweb (检查更新)...');
    try {
      final url = Uri.parse(
          '${AppConfig.queryUrl}?bisName=${AppConfig.testBisName}&offlineZipVer=0');
      Logger.d(tag, '地址: $url');
      final response = await http.get(url);
      setState(() => _queryResult = response.body);
      _log('/offweb OK: ${response.statusCode}');
    } catch (e, stack) {
      Logger.e(tag, '/offweb 失败: $e');
      Logger.d(tag, '堆栈: $stack');
      _log('/offweb 失败: $e');
    }
  }

  Future<void> _testQueryNoUpdate() async {
    const tag = 'ServerDebug';
    Logger.d(tag, '测试 /offweb (无更新)...');
    try {
      final url = Uri.parse(
          '${AppConfig.queryUrl}?bisName=${AppConfig.testBisName}&offlineZipVer=v1');
      Logger.d(tag, '地址: $url');
      final response = await http.get(url);
      setState(() => _queryResult = response.body);
      _log('/offweb (no update) OK: ${response.statusCode}');
    } catch (e, stack) {
      Logger.e(tag, '/offweb 失败: $e');
      Logger.d(tag, '堆栈: $stack');
      _log('/offweb 失败: $e');
    }
  }

  Future<void> _testPackage() async {
    const tag = 'ServerDebug';
    Logger.d(tag, '测试 /package...');
    try {
      final url =
          Uri.parse('${AppConfig.packageUrl}?bisName=${AppConfig.testBisName}');
      Logger.d(tag, '地址: $url');
      final response = await http.get(url);
      setState(() => _packageResult =
          'Status: ${response.statusCode}, Size: ${response.contentLength} bytes');
      _log('/package OK: Status=${response.statusCode}, Size=${response.contentLength} bytes');
    } catch (e, stack) {
      Logger.e(tag, '/package 失败: $e');
      Logger.d(tag, '堆栈: $stack');
      _log('/package 失败: $e');
    }
  }

  Future<void> _testDemo() async {
    const tag = 'ServerDebug';
    Logger.d(tag, '测试 /demo...');
    try {
      final url = Uri.parse(
          '${AppConfig.baseUrl}/demo?offweb=${AppConfig.testBisName}');
      Logger.d(tag, '地址: $url');
      final response = await http.get(url);
      _log('/demo OK: HTML page (${response.body.length} bytes)');
    } catch (e, stack) {
      Logger.e(tag, '/demo 失败: $e');
      Logger.d(tag, '堆栈: $stack');
      _log('/demo 失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('本地服务调试'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '服务端点: ${AppConfig.baseUrl}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _testHealth,
                  icon: const Icon(Icons.favorite, size: 18),
                  label: const Text('Health'),
                ),
                ElevatedButton.icon(
                  onPressed: _testQuery,
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Query (检查更新)'),
                ),
                ElevatedButton.icon(
                  onPressed: _testQueryNoUpdate,
                  icon: const Icon(Icons.search_off, size: 18),
                  label: const Text('Query (无更新)'),
                ),
                ElevatedButton.icon(
                  onPressed: _testPackage,
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Package (下载)'),
                ),
                ElevatedButton.icon(
                  onPressed: _testDemo,
                  icon: const Icon(Icons.web, size: 18),
                  label: const Text('Demo (HTML)'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildResultCard('Health', _healthResult),
            _buildResultCard('Query', _queryResult),
            _buildResultCard('Package', _packageResult),
            const SizedBox(height: 16),
            const Text(
              '日志:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  reverse: true,
                  child: Text(
                    _logText.isEmpty ? '点击按钮开始测试...' : _logText,
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(String label, String result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            SizedBox(
              width: 70,
              child: Text(
                '$label:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(
                result,
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}