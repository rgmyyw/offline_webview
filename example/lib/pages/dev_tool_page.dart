import 'package:flutter/material.dart';

import 'config_info_page.dart';
import 'disable_list_page.dart';
import 'force_update_page.dart';
import 'offline_package_manage_page.dart';
import 'preload_test_page.dart';
import 'url_match_test_page.dart';

/// 调试工具页面 - 路由入口集合
class DevToolPage extends StatelessWidget {
  const DevToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('调试工具'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ToolCard(
            icon: Icons.folder_open,
            title: '离线包管理',
            description: '查看、删除离线包缓存',
            color: Colors.blue,
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
            description: '清除 WebView 的所有缓存数据',
            color: Colors.orange,
            onTap: () => _showClearCacheDialog(context),
          ),
          const SizedBox(height: 12),
          _ToolCard(
            icon: Icons.link,
            title: 'URL 匹配测试',
            description: '测试 URL 匹配到哪个 bisName',
            color: Colors.teal,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UrlMatchTestPage(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ToolCard(
            icon: Icons.block,
            title: '禁用列表管理',
            description: '查看、添加禁用项',
            color: Colors.red,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DisableListPage(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ToolCard(
            icon: Icons.update,
            title: '强制更新检查',
            description: '对指定 bisName 强制触发更新',
            color: Colors.purple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ForceUpdatePage(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ToolCard(
            icon: Icons.speed,
            title: '预加载测试',
            description: '测试离线包预加载状态',
            color: Colors.green,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PreloadTestPage(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ToolCard(
            icon: Icons.settings,
            title: '配置查看',
            description: '查看 SDK 当前配置和规则',
            color: Colors.indigo,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ConfigInfoPage(),
              ),
            ),
          ),
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('WebView 缓存已清除')));
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
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
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
