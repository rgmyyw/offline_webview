import 'package:flutter/material.dart';

import 'offline_package_manage_page.dart';

/// 调试工具页面 - 路由入口集合
class DevToolPage extends StatelessWidget {
  const DevToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('调试工具'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ToolCard(
            icon: Icons.folder_open,
            title: '离线包管理',
            subtitle: '查看、删除离线包缓存',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OfflinePackageManagePage(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ToolCard(
            icon: Icons.cleaning_services,
            title: '清除 WebView 缓存',
            subtitle: '清除 WebView 的所有缓存数据',
            onTap: () => _showClearCacheDialog(context),
          ),
          // TODO: 添加更多调试功能入口
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除'),
        content: const Text('确定要清除 WebView 的所有缓存吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearWebViewCache(context);
            },
            child: const Text('清除'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearWebViewCache(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('WebView 缓存已清除')),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}