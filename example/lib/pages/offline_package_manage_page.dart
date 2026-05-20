import 'package:flutter/material.dart';
import 'package:offline_webview/offline_webview.dart';

/// 离线包管理页面
///
/// 展示和管理所有缓存的离线包，支持刷新、删除单个、删除全部等操作。
class OfflinePackageManagePage extends StatefulWidget {
  const OfflinePackageManagePage({super.key});

  @override
  State<OfflinePackageManagePage> createState() =>
      _OfflinePackageManagePageState();
}

class _OfflinePackageManagePageState extends State<OfflinePackageManagePage> {
  List<_BisInfo> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
    });

    try {
      final names = await FileMgr.getAllBisNames();
      final items = <_BisInfo>[];
      for (final name in names) {
        final version = await FileMgr.getCurVersion(name);
        final size = await FileMgr.getPackageSize(name);
        final item = _BisInfo(bisName: name, version: version, sizeBytes: size);
        items.add(item);
        Logger.d('OfflinePackageManage', '业务: $name, 版本: $version, 大小: ${item.sizeDisplay}');
      }
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('刷新失败: $e')));
      }
    }
  }

  Future<void> _deleteItem(String bisName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 "$bisName" 的离线缓存吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await OfflinePackage.deleteDiskCache(bisName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? '已删除 $bisName' : '删除失败')),
        );
        _refresh();
      }
    }
  }

  Future<void> _deleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要删除所有离线缓存吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('全部删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await OfflinePackage.deleteAllDiskCache();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(success ? '已清空所有缓存' : '清空失败')));
        _refresh();
      }
    }
  }

  int get _totalSize {
    return _items.fold(0, (sum, item) => sum + item.sizeBytes);
  }

  String get _totalSizeDisplay {
    final size = _totalSize;
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('离线包管理'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton.icon(
            onPressed: _deleteAll,
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            label: const Text(
              '一键清理所有包',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.folder_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('暂无离线包数据', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // 统计信息
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey[100],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            label: '离线包数量',
                            value: '${_items.length}',
                            icon: Icons.folder,
                          ),
                          _StatItem(
                            label: '总大小',
                            value: _totalSizeDisplay,
                            icon: Icons.storage,
                          ),
                        ],
                      ),
                    ),
                    // 列表
                    Expanded(
                      child: ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.folder),
                              title: Text(item.bisName),
                              subtitle: Text(
                                '版本: ${item.version}  大小: ${item.sizeDisplay}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteItem(item.bisName),
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
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _BisInfo {
  final String bisName;
  final String version;
  final int sizeBytes;

  _BisInfo({
    required this.bisName,
    required this.version,
    required this.sizeBytes,
  });

  String get sizeDisplay {
    if (sizeBytes < 1024) {
      return '$sizeBytes B';
    }
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
