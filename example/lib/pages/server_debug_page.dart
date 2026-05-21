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
  static const _tag = 'ServerDebug';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _testHealth();
    });
  }

  final List<_LogEntry> _logs = [];

  _EndpointResult _healthResult = _EndpointResult.initial();
  _EndpointResult _queryResult = _EndpointResult.initial();
  _EndpointResult _queryNoUpdateResult = _EndpointResult.initial();
  _EndpointResult _packageResult = _EndpointResult.initial();
  _EndpointResult _demoResult = _EndpointResult.initial();

  void _addLog(String message, {bool isError = false}) {
    setState(() {
      _logs.insert(0, _LogEntry(message: message, isError: isError));
      if (_logs.length > 100) _logs.removeLast();
    });
  }

  Future<void> _testHealth() async {
    setState(() => _healthResult = _EndpointResult.loading());
    _addLog('测试 /health...');
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/health');
      Logger.d(_tag, '地址: $url');
      final response = await http.get(url);
      setState(() => _healthResult = _EndpointResult.success(response.body));
      _addLog('/health OK: ${response.statusCode}\n${response.body}');
    } catch (e) {
      Logger.e(_tag, '/health 失败: $e');
      setState(() => _healthResult = _EndpointResult.error(e.toString()));
      _addLog('/health 失败: $e', isError: true);
    }
  }

  Future<void> _testQuery() async {
    setState(() => _queryResult = _EndpointResult.loading());
    _addLog('测试 /offweb (检查更新)...');
    try {
      final url = Uri.parse(
        '${AppConfig.queryUrl}?bisName=${AppConfig.testBisName}&offlineZipVer=0',
      );
      Logger.d(_tag, '地址: $url');
      final response = await http.get(url);
      setState(() => _queryResult = _EndpointResult.success(response.body));
      _addLog('/offweb OK: ${response.statusCode}\n${response.body}');
    } catch (e) {
      Logger.e(_tag, '/offweb 失败: $e');
      setState(() => _queryResult = _EndpointResult.error(e.toString()));
      _addLog('/offweb 失败: $e', isError: true);
    }
  }

  Future<void> _testQueryNoUpdate() async {
    setState(() => _queryNoUpdateResult = _EndpointResult.loading());
    _addLog('测试 /offweb (无更新)...');
    try {
      final url = Uri.parse(
        '${AppConfig.queryUrl}?bisName=${AppConfig.testBisName}&offlineZipVer=v1',
      );
      Logger.d(_tag, '地址: $url');
      final response = await http.get(url);
      setState(
        () => _queryNoUpdateResult = _EndpointResult.success(response.body),
      );
      _addLog(
        '/offweb (no update) OK: ${response.statusCode}\n${response.body}',
      );
    } catch (e) {
      Logger.e(_tag, '/offweb 失败: $e');
      setState(
        () => _queryNoUpdateResult = _EndpointResult.error(e.toString()),
      );
      _addLog('/offweb 失败: $e', isError: true);
    }
  }

  Future<void> _testPackage() async {
    setState(() => _packageResult = _EndpointResult.loading());
    _addLog('测试 /package...');
    try {
      final url = Uri.parse(
        '${AppConfig.packageUrl}?bisName=${AppConfig.testBisName}',
      );
      Logger.d(_tag, '地址: $url');
      final response = await http.get(url);
      setState(
        () => _packageResult = _EndpointResult.success(
          'Status: ${response.statusCode}, Size: ${response.contentLength ?? 0} bytes',
        ),
      );
      _addLog(
        '/package OK: Status=${response.statusCode}, Size=${response.contentLength ?? 0} bytes',
      );
    } catch (e) {
      Logger.e(_tag, '/package 失败: $e');
      setState(() => _packageResult = _EndpointResult.error(e.toString()));
      _addLog('/package 失败: $e', isError: true);
    }
  }

  Future<void> _testDemo() async {
    setState(() => _demoResult = _EndpointResult.loading());
    _addLog('测试 /demo...');
    try {
      final url = Uri.parse(
        '${AppConfig.baseUrl}/demo?offweb=${AppConfig.testBisName}',
      );
      Logger.d(_tag, '地址: $url');
      final response = await http.get(url);
      setState(
        () => _demoResult = _EndpointResult.success(
          'HTML page (${response.body.length} bytes)\n${response.body}',
        ),
      );
      _addLog(
        '/demo OK: HTML page (${response.body.length} bytes)\n${response.body}',
      );
    } catch (e) {
      Logger.e(_tag, '/demo 失败: $e');
      setState(() => _demoResult = _EndpointResult.error(e.toString()));
      _addLog('/demo 失败: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('服务调试'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => setState(() => _logs.clear()),
            tooltip: '清空日志',
          ),
        ],
      ),
      body: Column(
        children: [
          // Server info header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.dns,
                      size: 20,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '服务端点',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  AppConfig.baseUrl,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Endpoint cards
                  _buildEndpointCard(
                    title: 'Health',
                    description: '健康检查端点',
                    icon: Icons.favorite,
                    color: Colors.pink,
                    result: _healthResult,
                    onTest: _testHealth,
                  ),
                  const SizedBox(height: 12),
                  _buildEndpointCard(
                    title: 'Query (检查更新)',
                    description: '查询离线包更新状态',
                    icon: Icons.search,
                    color: Colors.blue,
                    result: _queryResult,
                    onTest: _testQuery,
                  ),
                  const SizedBox(height: 12),
                  _buildEndpointCard(
                    title: 'Query (无更新)',
                    description: '测试无更新响应',
                    icon: Icons.search_off,
                    color: Colors.grey,
                    result: _queryNoUpdateResult,
                    onTest: _testQueryNoUpdate,
                  ),
                  const SizedBox(height: 12),
                  _buildEndpointCard(
                    title: 'Package',
                    description: '下载离线包 zip',
                    icon: Icons.download,
                    color: Colors.green,
                    result: _packageResult,
                    onTest: _testPackage,
                  ),
                  const SizedBox(height: 12),
                  _buildEndpointCard(
                    title: 'Demo',
                    description: '演示 HTML 页面',
                    icon: Icons.web,
                    color: Colors.orange,
                    result: _demoResult,
                    onTest: _testDemo,
                  ),

                  const SizedBox(height: 24),

                  // Log section
                  Row(
                    children: [
                      Icon(
                        Icons.terminal,
                        size: 20,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '日志',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_logs.length} 条',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 200,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade800, width: 1),
                    ),
                    child: _logs.isEmpty
                        ? const Center(
                            child: Text(
                              '点击上方按钮开始测试...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            reverse: true,
                            itemCount: _logs.length,
                            itemBuilder: (context, index) {
                              final log = _logs[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                child: Text(
                                  log.message,
                                  style: TextStyle(
                                    color: log.isError
                                        ? Colors.redAccent
                                        : Colors.greenAccent,
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndpointCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required _EndpointResult result,
    required VoidCallback onTest,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 6),
                  _buildResultIndicator(result),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.tonal(onPressed: onTest, child: const Text('测试')),
          ],
        ),
      ),
    );
  }

  Widget _buildResultIndicator(_EndpointResult result) {
    if (result.isLoading) {
      return Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '测试中...',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      );
    }

    if (result.isInitial) {
      return Row(
        children: [
          Icon(Icons.circle_outlined, size: 12, color: Colors.grey.shade400),
          const SizedBox(width: 6),
          Text(
            '未测试',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
      );
    }

    final isSuccess = result.isSuccess;
    return Row(
      children: [
        Icon(
          isSuccess ? Icons.check_circle : Icons.error,
          size: 14,
          color: isSuccess ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            result.message,
            style: TextStyle(
              fontSize: 12,
              color: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _EndpointResult {
  final String message;
  final bool isLoading;
  final bool isSuccess;
  final bool isError;
  final bool isInitial;

  const _EndpointResult._({
    required this.message,
    this.isLoading = false,
    this.isSuccess = false,
    this.isError = false,
    this.isInitial = false,
  });

  factory _EndpointResult.initial() =>
      const _EndpointResult._(message: '未测试', isInitial: true);

  factory _EndpointResult.loading() =>
      const _EndpointResult._(message: '测试中...', isLoading: true);

  factory _EndpointResult.success(String message) =>
      _EndpointResult._(message: message, isSuccess: true);

  factory _EndpointResult.error(String error) =>
      _EndpointResult._(message: error, isError: true);
}

class _LogEntry {
  final String message;
  final bool isError;

  const _LogEntry({required this.message, this.isError = false});
}
