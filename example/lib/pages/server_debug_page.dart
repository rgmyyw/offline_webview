import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:offline_webview/offline_webview.dart';

import '../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.serverDebugPage),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => setState(() => _logs.clear()),
            tooltip: l10n.clearLogs,
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
                    Text(
                      l10n.serverEndpoints,
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
                    description: l10n.healthCheck,
                    icon: Icons.favorite,
                    color: Colors.pink,
                    result: _healthResult,
                    onTest: _testHealth,
                    l10n: l10n,
                  ),
                  const SizedBox(height: 12),
                  _buildEndpointCard(
                    title: l10n.queryUpdate,
                    description: l10n.queryUpdateDesc,
                    icon: Icons.search,
                    color: Colors.blue,
                    result: _queryResult,
                    onTest: _testQuery,
                    l10n: l10n,
                  ),
                  const SizedBox(height: 12),
                  _buildEndpointCard(
                    title: l10n.queryNoUpdate,
                    description: l10n.queryNoUpdateDesc,
                    icon: Icons.search_off,
                    color: Colors.grey,
                    result: _queryNoUpdateResult,
                    onTest: _testQueryNoUpdate,
                    l10n: l10n,
                  ),
                  const SizedBox(height: 12),
                  _buildEndpointCard(
                    title: l10n.package,
                    description: l10n.packageDesc,
                    icon: Icons.download,
                    color: Colors.green,
                    result: _packageResult,
                    onTest: _testPackage,
                    l10n: l10n,
                  ),
                  const SizedBox(height: 12),
                  _buildEndpointCard(
                    title: l10n.demo,
                    description: l10n.demoPage,
                    icon: Icons.web,
                    color: Colors.orange,
                    result: _demoResult,
                    onTest: _testDemo,
                    l10n: l10n,
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
                      Text(
                        l10n.logs,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        l10n.logCount(_logs.length),
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
                        ? Center(
                            child: Text(
                              l10n.clickButtonToStartTest,
                              style: const TextStyle(color: Colors.grey),
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
    required AppLocalizations l10n,
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
                  _buildResultIndicator(result, l10n),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.tonal(onPressed: onTest, child: Text(l10n.testButton)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultIndicator(_EndpointResult result, AppLocalizations l10n) {
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
            l10n.testing,
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
            l10n.notTested,
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
