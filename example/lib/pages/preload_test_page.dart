import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:offline_webview/offline_webview.dart';

import '../config.dart';

/// 预加载测试页面
///
/// 通过服务端点查询离线包更新状态，测试预加载流程。
class PreloadTestPage extends StatefulWidget {
  const PreloadTestPage({super.key});

  @override
  State<PreloadTestPage> createState() => _PreloadTestPageState();
}

class _PreloadTestPageState extends State<PreloadTestPage> {
  final _bisNameController = TextEditingController(text: 'academy');
  bool _isLoading = false;
  final List<_PreloadLogEntry> _logs = [];
  List<String> _availableBisNames = [];

  @override
  void initState() {
    super.initState();
    _addLog('就绪，请输入 bisName 并点击开始预加载', isInfo: true);
    _loadAvailableBisNames();
  }

  Future<void> _loadAvailableBisNames() async {
    _addLog('正在从服务端获取可用离线包...');
    try {
      final response = await http
          .get(Uri.parse(AppConfig.baseUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final packages =
            (json['packages'] as List<dynamic>?)?.cast<String>() ?? [];
        setState(() {
          _availableBisNames = packages;
        });
        _addLog('服务端共有 ${packages.length} 个离线包', isInfo: true);
      } else {
        _addLog('获取失败: ${response.statusCode}', isError: true);
      }
    } catch (e) {
      _addLog('获取离线包列表异常: $e', isError: true);
    }
  }

  @override
  void dispose() {
    _bisNameController.dispose();
    super.dispose();
  }

  void _addLog(String message, {bool isInfo = false, bool isError = false}) {
    setState(() {
      _logs.insert(
        0,
        _PreloadLogEntry(message: message, isInfo: isInfo, isError: isError),
      );
      if (_logs.length > 100) _logs.removeLast();
    });
  }

  Future<void> _startPreload() async {
    final bisName = _bisNameController.text.trim();
    if (bisName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入 bisName')));
      return;
    }

    setState(() {
      _isLoading = true;
      _logs.clear();
    });

    _addLog('开始预加载测试: $bisName', isInfo: true);

    final startTime = DateTime.now();

    try {
      // 获取本地当前版本
      final localVersion = await FileMgr.getCurVersion(bisName);
      _addLog('本地版本: ${localVersion.isEmpty ? "无" : localVersion}');

      // 通过服务端点查询更新
      _addLog('正在查询服务端点...');
      final result = await _queryUpdate(bisName, localVersion);
      _addLog('查询结果: ${result.message}');

      if (result.hasUpdate) {
        _addLog('发现新版本: ${result.version}，准备下载...', isInfo: true);
        // 触发下载流程
        await _triggerDownload(bisName, result.version);
      } else {
        _addLog('已是最新版本，无需下载', isInfo: true);
      }

      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      _addLog('预加载测试完成，耗时: ${elapsed}ms', isInfo: true);
    } catch (e) {
      Logger.e('PreloadTestPage', '预加载测试失败: $e');
      _addLog('预加载测试失败: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<_QueryResult> _queryUpdate(String bisName, String localVersion) async {
    final queryUrl =
        '${AppConfig.queryUrl}?bisName=$bisName&offlineZipVer=$localVersion';
    _addLog('查询URL: $queryUrl');

    try {
      final response = await http
          .get(Uri.parse(queryUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final resultCode = json['result'] as int? ?? -1;
        final version = json['version'] as String? ?? '';
        final url = json['url'] as String?;

        if (resultCode == 1 && url != null && url.isNotEmpty) {
          return _QueryResult(
            hasUpdate: true,
            version: version,
            url: url,
            message: '有新版本',
          );
        } else if (resultCode == 0) {
          return _QueryResult(
            hasUpdate: false,
            version: localVersion,
            url: null,
            message: '已是最新',
          );
        } else {
          return _QueryResult(
            hasUpdate: false,
            version: '',
            url: null,
            message: '无离线包',
          );
        }
      } else {
        return _QueryResult(
          hasUpdate: false,
          version: '',
          url: null,
          message: '请求失败: ${response.statusCode}',
        );
      }
    } catch (e) {
      return _QueryResult(
        hasUpdate: false,
        version: '',
        url: null,
        message: '查询异常: $e',
      );
    }
  }

  Future<void> _triggerDownload(String bisName, String newVersion) async {
    _addLog('触发下载流程...');

    final completer = Completer<void>();

    OfflineWebManager.instance.checkPackage(
      bisName,
      _FlowListener(
        onDone: (info) {
          if (info != null) {
            _addLog('下载完成，新版本: ${info.version}', isInfo: true);
          } else {
            _addLog('下载完成', isInfo: true);
          }
          completer.complete();
        },
        onError: (info, err) {
          _addLog('下载失败: $err', isError: true);
          completer.completeError(err);
        },
      ),
    );

    try {
      await completer.future.timeout(const Duration(seconds: 30));
    } catch (e) {
      // 超时或其他错误
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('预加载测试'),
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
          // 输入区域
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _bisNameController,
                    decoration: const InputDecoration(
                      labelText: 'bisName',
                      hintText: '例如: act3-2108',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _isLoading ? null : _startPreload,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('开始'),
                ),
              ],
            ),
          ),

          // 常用 bisName
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text(
                  '可用离线包:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_availableBisNames.isEmpty)
                  Text('暂无离线包数据', style: TextStyle(color: Colors.grey.shade500))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableBisNames
                        .map(
                          (name) => _QuickChip(
                            label: name,
                            onTap: () => _bisNameController.text = name,
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),

          // 日志区域
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.terminal,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  '测试日志',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade800, width: 1),
              ),
              child: _logs.isEmpty
                  ? const Center(
                      child: Text(
                        '点击开始按钮进行预加载测试...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      reverse: true,
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        Color textColor = Colors.greenAccent;
                        if (log.isError) textColor = Colors.redAccent;
                        if (log.isInfo) textColor = Colors.blueAccent;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            log.message,
                            style: TextStyle(
                              color: textColor,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(label: Text(label), onPressed: onTap);
  }
}

class _PreloadLogEntry {
  final String message;
  final bool isInfo;
  final bool isError;

  _PreloadLogEntry({
    required this.message,
    this.isInfo = false,
    this.isError = false,
  });
}

class _QueryResult {
  final bool hasUpdate;
  final String version;
  final String? url;
  final String message;

  _QueryResult({
    required this.hasUpdate,
    required this.version,
    this.url,
    required this.message,
  });
}

class _FlowListener extends FlowListener {
  final void Function(OfflinePackageInfo? info) onDone;
  final void Function(OfflinePackageInfo? info, Object err) onError;

  _FlowListener({required this.onDone, required this.onError});

  @override
  void done(OfflinePackageInfo? info) => onDone(info);

  @override
  void error(OfflinePackageInfo? info, Object err) => onError(info, err);
}
