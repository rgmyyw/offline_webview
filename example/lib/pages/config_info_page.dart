import 'package:flutter/material.dart';
import 'package:offline_webview/offline_webview.dart';

import '../l10n/app_localizations.dart';

/// 配置查看面板
///
/// 显示当前 SDK 初始化配置（env、appVersion 等）和规则配置详情。
class ConfigInfoPage extends StatefulWidget {
  const ConfigInfoPage({super.key});

  @override
  State<ConfigInfoPage> createState() => _ConfigInfoPageState();
}

class _ConfigInfoPageState extends State<ConfigInfoPage> {
  Map<String, String> _configInfo = {};
  Map<String, dynamic> _ruleConfig = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);

    try {
      final manager = OfflineWebManager.instance;

      setState(() {
        _configInfo = {
          'isInit': manager.isInit.toString(),
          'env': manager.env,
          'appVersion': manager.appVersion,
          'config.isOpen': manager.config.isOpen.toString(),
          'preDownloadAll': manager.config.preDownloadAll.toString(),
          'preDownloadList': manager.config.preDownloadList.toString(),
          'disableList': manager.config.disableList.toString(),
          'matcherType': manager.matcher.runtimeType.toString(),
          'hasRequest': (manager.request != null).toString(),
        };

        _ruleConfig = manager.ruleConfig.toJson();
      });

      Logger.d('ConfigInfoPage', '配置信息: $_configInfo');
    } catch (e) {
      Logger.e('ConfigInfoPage', '加载失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.configInfo),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConfig,
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 基础配置
                _buildSection(
                  title: l10n.basicConfig,
                  icon: Icons.settings,
                  children: _configInfo.entries
                      .map((e) => _ConfigRow(configKey: e.key, value: e.value))
                      .toList(),
                ),

                const SizedBox(height: 16),

                // 规则配置
                _buildSection(
                  title: l10n.ruleConfig,
                  icon: Icons.rule,
                  children: [
                    if (_ruleConfig.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          l10n.noRuleConfig,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      _RuleConfigWidget(config: _ruleConfig),
                  ],
                ),

                const SizedBox(height: 16),

                // SDK 状态
                _buildSection(
                  title: l10n.sdkStatus,
                  icon: Icons.info,
                  children: [
                    _StatusRow(
                      label: l10n.initStatus,
                      value: _configInfo['isInit'] == 'true' ? l10n.initialized : l10n.notInitialized,
                      isOk: _configInfo['isInit'] == 'true',
                    ),
                    _StatusRow(
                      label: 'Matcher',
                      value: _configInfo['matcherType'] ?? 'unknown',
                      isOk: true,
                    ),
                    _StatusRow(
                      label: l10n.request,
                      value: _configInfo['hasRequest'] == 'true' ? l10n.configured : l10n.notConfigured,
                      isOk: _configInfo['hasRequest'] == 'true',
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  final String configKey;
  final String value;

  const _ConfigRow({required this.configKey, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              configKey,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isOk;

  const _StatusRow({
    required this.label,
    required this.value,
    required this.isOk,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            isOk ? Icons.check_circle : Icons.cancel,
            color: isOk ? Colors.green : Colors.red,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isOk ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleConfigWidget extends StatelessWidget {
  final Map<String, dynamic> config;

  const _RuleConfigWidget({required this.config});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildJsonView(config),
        ],
      ),
    );
  }

  Widget _buildJsonView(Map<String, dynamic> json, {int indent = 0}) {
    final indentStr = '  ' * indent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: json.entries.map((entry) {
        final value = entry.value;
        if (value is Map) {
          return Padding(
            padding: EdgeInsets.only(left: indent * 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$indentStr"${entry.key}":',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
                _buildJsonView(value as Map<String, dynamic>, indent: indent + 1),
              ],
            ),
          );
        } else if (value is List) {
          return Padding(
            padding: EdgeInsets.only(left: indent * 16.0),
            child: Text(
              '$indentStr"${entry.key}": ${value.toString()}',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          );
        } else {
          return Padding(
            padding: EdgeInsets.only(left: indent * 16.0),
            child: Text(
              '$indentStr"${entry.key}": "$value"',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          );
        }
      }).toList(),
    );
  }
}