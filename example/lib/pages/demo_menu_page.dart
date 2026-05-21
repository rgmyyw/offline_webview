import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'param_offline_demo_page.dart';
import 'rule_match_offline_demo_page.dart';
import 'dev_tool_page.dart';
import 'server_debug_page.dart';
import 'offline_config_page.dart';

class DemoMenuPage extends StatelessWidget {
  const DemoMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final demos = <Map<String, dynamic>>[
      {
        'title': l10n.offlineLoadingMode,
        'subtitle': l10n.offlineLoadingModeSubtitle,
        'page': const ParamOfflineDemoPage(),
      },
      {
        'title': l10n.ruleMatchMode,
        'subtitle': l10n.ruleMatchModeSubtitle,
        'page': const RuleMatchOfflineDemoPage(),
      },
      {
        'title': l10n.debugTools,
        'subtitle': l10n.debugToolsSubtitle,
        'page': const DevToolPage(),
      },
      {
        'title': l10n.serverDebug,
        'subtitle': l10n.serverDebugSubtitle,
        'page': const ServerDebugPage(),
      },
      {
        'title': l10n.customConfig,
        'subtitle': l10n.customConfigSubtitle,
        'page': const OfflineConfigPage(),
      },
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: ListView.builder(
        itemCount: demos.length,
        itemBuilder: (context, index) {
          final demo = demos[index];
          final page = demo['page'] as Widget;

          return ListTile(
            title: Text(demo['title'] as String),
            subtitle: Text(demo['subtitle'] as String),
            trailing: Icon(
              Icons.chevron_right,
              size: 24,
              color: Theme.of(context).colorScheme.primary,
            ),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => page));
            },
          );
        },
      ),
    );
  }
}