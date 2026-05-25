import 'package:flutter/material.dart';
import 'package:offline_webview/offline_webview.dart';

import '../l10n/app_localizations.dart';
import 'config_info_page.dart';
import 'disable_list_page.dart';
import 'force_update_page.dart';
import 'offline_package_manage_page.dart';
import 'preload_test_page.dart';
import 'url_match_test_page.dart';

class DevToolPage extends StatefulWidget {
  const DevToolPage({super.key});

  @override
  State<DevToolPage> createState() => _DevToolPageState();
}

class _DevToolPageState extends State<DevToolPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.debugToolsPage),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 性能监控面板开关
          Card(
            child: SwitchListTile(
              secondary: Icon(
                Icons.speed,
                color: FloatingPerformancePanel.enabled
                    ? Colors.green
                    : Colors.grey,
              ),
              title: Text(l10n.performancePanelSwitch),
              subtitle: Text(l10n.performancePanelSwitchDesc),
              value: FloatingPerformancePanel.enabled,
              onChanged: (value) {
                setState(() {
                  FloatingPerformancePanel.enabled = value;
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          _ToolCard(
            icon: Icons.folder_open,
            title: l10n.offlinePackageManagement,
            description: l10n.offlinePackageManagementDesc,
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
            title: l10n.clearWebViewCache,
            description: l10n.clearWebViewCacheDesc,
            color: Colors.orange,
            onTap: () => _showClearCacheDialog(context),
          ),
          const SizedBox(height: 12),
          _ToolCard(
            icon: Icons.link,
            title: l10n.urlMatchTestCard,
            description: l10n.urlMatchTestCardDesc,
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
            title: l10n.disableListManagementCard,
            description: l10n.disableListManagementDesc,
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
            title: l10n.forceUpdateCheckCard,
            description: l10n.forceUpdateCheckDesc,
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
            title: l10n.preloadTestCard,
            description: l10n.preloadTestDesc,
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
            title: l10n.configInfoCard,
            description: l10n.configInfoCardDesc,
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmClear),
        content: Text(l10n.confirmClearWebViewCache),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearWebViewCache(context);
            },
            child: Text(l10n.clear),
          ),
        ],
      ),
    );
  }

  Future<void> _clearWebViewCache(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.webViewCacheCleared)));
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