import 'package:flutter/material.dart';
import 'package:offline_webview/offline_webview.dart';

/// 强制更新检查页面
///
/// 对指定 bisName 强制触发更新检查，显示更新过程和结果。
class ForceUpdatePage extends StatefulWidget {
  const ForceUpdatePage({super.key});

  @override
  State<ForceUpdatePage> createState() => _ForceUpdatePageState();
}

class _ForceUpdatePageState extends State<ForceUpdatePage> {
  final _bisNameController = TextEditingController(
    text: 'test-offline-package',
  );
  bool _isUpdating = false;
  final List<_UpdateLogEntry> _logs = [];
  List<String> _availableBisNames = [];

  @override
  void initState() {
    super.initState();
    _addLog('就绪，请输入 bisName 并点击开始', isInfo: true);
    _loadAvailableBisNames();
  }

  Future<void> _loadAvailableBisNames() async {
    final names = await FileMgr.getAllBisNames();
    setState(() {
      _availableBisNames = names;
    });
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
        _UpdateLogEntry(message: message, isInfo: isInfo, isError: isError),
      );
      if (_logs.length > 100) _logs.removeLast();
    });
  }

  Future<void> _startUpdate() async {
    final bisName = _bisNameController.text.trim();
    if (bisName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入 bisName')));
      return;
    }

    setState(() {
      _isUpdating = true;
      _logs.clear();
    });

    _addLog('开始更新检查: $bisName', isInfo: true);

    try {
      // 获取当前本地版本
      final localVersion = await FileMgr.getCurVersion(bisName);
      _addLog('本地版本: $localVersion');

      // 触发更新检查
      _addLog('正在请求服务器...');
      final manager = OfflineWebManager.instance;
      final request = manager.request;

      if (request == null) {
        _addLog('未配置 IOfflineRequest，无法请求服务器', isError: true);
        setState(() => _isUpdating = false);
        return;
      }

      // 使用 request 请求更新
      await Future.delayed(const Duration(milliseconds: 100));
      _addLog('已触发 checkPackage');

      // 调用 checkPackage 触发更新流程
      manager.checkPackage(bisName, null);

      _addLog('更新任务已提交，请查看日志了解进度');

      // 等待一段时间后检查结果
      await Future.delayed(const Duration(seconds: 2));

      // 检查新版本是否出现
      final newVersion = await FileMgr.getNewVersion(bisName);
      if (newVersion.isNotEmpty) {
        _addLog('发现新版本: $newVersion', isInfo: true);
      }

      final curVersion = await FileMgr.getCurVersion(bisName);
      _addLog('当前版本: $curVersion');
      _addLog('更新检查完成', isInfo: true);
    } catch (e) {
      Logger.e('ForceUpdatePage', '更新失败: $e');
      _addLog('更新失败: $e', isError: true);
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('强制更新检查'),
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
                    enabled: !_isUpdating,
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _isUpdating ? null : _startUpdate,
                  child: _isUpdating
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
                  '更新日志',
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
                        '点击开始按钮进行更新检查...',
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

class _UpdateLogEntry {
  final String message;
  final bool isInfo;
  final bool isError;

  _UpdateLogEntry({
    required this.message,
    this.isInfo = false,
    this.isError = false,
  });
}
