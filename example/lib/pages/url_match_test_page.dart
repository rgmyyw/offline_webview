import 'package:flutter/material.dart';
import 'package:offline_webview/offline_webview.dart';

import '../l10n/app_localizations.dart';

/// URL 匹配测试器
///
/// 输入任意 URL，测试会匹配到哪个 bisName，并展示匹配结果和规则信息。
class UrlMatchTestPage extends StatefulWidget {
  const UrlMatchTestPage({super.key});

  @override
  State<UrlMatchTestPage> createState() => _UrlMatchTestPageState();
}

class _UrlMatchTestPageState extends State<UrlMatchTestPage> {
  final _urlController = TextEditingController(
    text: 'https://m.example.com/test-offline-package/index.html',
  );
  String? _matchResult;
  String? _ruleInfo;
  bool _isLoading = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testMatch() async {
    final l10n = AppLocalizations.of(context)!;
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isLoading = true;
      _matchResult = null;
      _ruleInfo = null;
    });

    try {
      // 测试 OfflinePackage.getOffWebBisName
      final bisName = OfflinePackage.getOffWebBisName(url);

      // 测试 DefaultMatcher.matching
      final matcher = DefaultMatcher();
      final matchResult = matcher.matching(url);

      setState(() {
        _matchResult = bisName ?? l10n.noMatchBisName;
        _ruleInfo = '''
URL: $url

getOffWebBisName 结果: ${bisName ?? 'null'}
DefaultMatcher 结果: $matchResult

提示: getOffWebBisName 通过配置规则匹配
      DefaultMatcher 通过 URL 直接匹配
''';
      });
    } catch (e) {
      setState(() {
        _matchResult = l10n.matchFailed;
        _ruleInfo = '${l10n.loadFailed}: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.urlMatchTest),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 输入区域
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.inputUrl,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        hintText: l10n.exampleUrlHint,
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _urlController.clear(),
                        ),
                      ),
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _testMatch,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(l10n.testMatch),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 常用测试 URL
            Text(
              l10n.commonTestUrls,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickUrlChip(
                  label: 'test-offline-package',
                  url: 'https://m.example.com/test-offline-package/index.html',
                  onTap: () => _urlController.text = 'https://m.example.com/test-offline-package/index.html',
                ),
                _QuickUrlChip(
                  label: 'megift',
                  url: 'https://m.example.com/megift/index.html',
                  onTap: () => _urlController.text = 'https://m.example.com/megift/index.html',
                ),
                _QuickUrlChip(
                  label: 'academy',
                  url: 'https://m.example.com/academy/index.html',
                  onTap: () => _urlController.text = 'https://m.example.com/academy/index.html',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 结果展示
            if (_matchResult != null) ...[
              Text(
                l10n.matchResult,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            _matchResult!,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      if (_ruleInfo != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _ruleInfo!,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickUrlChip extends StatelessWidget {
  final String label;
  final String url;
  final VoidCallback onTap;

  const _QuickUrlChip({
    required this.label,
    required this.url,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      avatar: const Icon(Icons.link, size: 16),
      onPressed: onTap,
    );
  }
}