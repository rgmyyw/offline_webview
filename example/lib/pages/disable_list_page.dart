import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:offline_webview/offline_webview.dart';

import '../l10n/app_localizations.dart';

import '../config.dart';

/// 禁用列表管理页面
///
/// 查看、添加、删除禁用项，并测试禁用效果。
class DisableListPage extends StatefulWidget {
  const DisableListPage({super.key});

  @override
  State<DisableListPage> createState() => _DisableListPageState();
}

class _DisableListPageState extends State<DisableListPage> {
  List<String> _disableList = [];
  final _inputController = TextEditingController();
  bool _isLoading = true;
  List<String> _remotePackages = [];
  bool _isLoadingRemote = false;

  @override
  void initState() {
    super.initState();
    _loadDisableList();
    _loadRemotePackages();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _loadDisableList() async {
    setState(() => _isLoading = true);
    try {
      // 从 OfflineWebManager 获取配置
      final manager = OfflineWebManager.instance;
      final config = manager.config;
      setState(() {
        _disableList = config.disableList.toList();
      });
    } catch (e) {
      Logger.e('DisableListPage', '加载失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRemotePackages() async {
    setState(() => _isLoadingRemote = true);
    try {
      final response = await http
          .get(Uri.parse(AppConfig.baseUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final packages =
            (json['packages'] as List<dynamic>?)?.cast<String>() ?? [];
        setState(() {
          _remotePackages = packages;
        });
      }
    } catch (e) {
      Logger.e('DisableListPage', '获取远程包列表失败: $e');
    } finally {
      setState(() => _isLoadingRemote = false);
    }
  }

  Future<void> _addToDisableList() async {
    final l10n = AppLocalizations.of(context)!;
    final bisName = _inputController.text.trim();
    if (bisName.isEmpty) return;

    try {
      OfflineWebClient.addToDisableList(bisName);
      _inputController.clear();
      await _loadDisableList();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.addedToDisableList(bisName))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.addFailed(e.toString()))),
        );
      }
    }
  }

  Future<void> _testDisable(String bisName) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final manager = OfflineWebManager.instance;
      final isDisabled = manager.isDisable(bisName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isDisabled ? l10n.bisNameIsDisabled(bisName) : l10n.bisNameNotDisabled(bisName)),
            backgroundColor: isDisabled ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.testFailed(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.disableListManagement),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDisableList,
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 添加区域
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          decoration: InputDecoration(
                            hintText: l10n.bisNameHint,
                            border: const OutlineInputBorder(),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _addToDisableList,
                        child: Text(l10n.add),
                      ),
                    ],
                  ),
                ),

                // 远程可用离线包
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.remoteAvailablePackages,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_isLoadingRemote)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (_remotePackages.isEmpty)
                  Text(
                    l10n.noPackagesAvailable,
                    style: TextStyle(color: Colors.grey.shade500),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _remotePackages.map((pkg) {
                      final isDisabled = _disableList.contains(pkg);
                      return _RemotePackageChip(
                        label: pkg,
                        isDisabled: isDisabled,
                        onTap: isDisabled
                            ? null
                            : () => _inputController.text = pkg,
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),

                // 统计信息
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.block,
                        size: 20,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.currentDisableItems(_disableList.length),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                // 列表
                Expanded(
                  child: _disableList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.playlist_add_check,
                                size: 80,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.noDisableItems,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _disableList.length,
                          itemBuilder: (context, index) {
                            final bisName = _disableList[index];
                            return Card(
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.block,
                                    color: Colors.red.shade400,
                                  ),
                                ),
                                title: Text(
                                  bisName,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.play_arrow),
                                      tooltip: l10n.test,
                                      onPressed: () => _testDisable(bisName),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: Colors.red.shade400,
                                      ),
                                      tooltip: l10n.delete,
                                      onPressed: () => _removeItem(bisName),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Future<void> _removeItem(String bisName) async {
    final l10n = AppLocalizations.of(context)!;
    // 注意：SDK 没有直接从禁用列表移除的方法
    // 实际需要通过重新初始化配置来实现
    // 这里仅提示用户
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.deleteRequiresReinitSdk),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}

class _RemotePackageChip extends StatelessWidget {
  final String label;
  final bool isDisabled;
  final VoidCallback? onTap;

  const _RemotePackageChip({
    required this.label,
    required this.isDisabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      backgroundColor: isDisabled ? Colors.red.shade50 : Colors.blue.shade50,
      side: BorderSide(
        color: isDisabled ? Colors.red.shade200 : Colors.blue.shade200,
      ),
      labelStyle: TextStyle(
        color: isDisabled ? Colors.red.shade400 : Colors.blue.shade600,
        fontSize: 12,
      ),
      onPressed: onTap,
    );
  }
}