import '../core/offline_const.dart';

/// 离线Web URL规则配置。
///
/// 包含[RulesInfo]条目列表，定义哪些URL
/// 应被拦截以进行离线加载。
class OfflineRuleConfig {
  final List<RulesInfo> rules;

  const OfflineRuleConfig({this.rules = const []});

  /// 从JSON map创建。
  factory OfflineRuleConfig.fromJson(Map<String, dynamic> json) {
    final rulesList = json['rules'] as List<dynamic>? ?? [];
    return OfflineRuleConfig(
      rules: rulesList
          .map((e) => RulesInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 转换为JSON map。
  Map<String, dynamic> toJson() {
    return {
      'rules': rules.map((e) => e.toJson()).toList(),
    };
  }
}

/// 单个规则条目，将URL匹配到离线Web业务模块。
///
/// 每个规则指定：
/// - [offWeb]：业务模块名称（bisName）
/// - [hosts]：要匹配的主机名列表
/// - [paths]：要匹配的路径列表（支持通配符`*`）
/// - [fragmentPrefix]：要匹配的fragment前缀列表
class RulesInfo {
  final String offWeb;
  final List<String> hosts;
  final List<String> paths;
  final List<String> fragmentPrefix;

  const RulesInfo({
    this.offWeb = '',
    this.hosts = const [],
    this.paths = const [],
    this.fragmentPrefix = const [],
  });

  /// 从JSON map创建。
  factory RulesInfo.fromJson(Map<String, dynamic> json) {
    return RulesInfo(
      offWeb: json['offWeb']?.toString() ?? '',
      hosts: (json['hosts'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      paths: (json['paths'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      fragmentPrefix: (json['fragmentPrefix'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  /// 转换为JSON map。
  Map<String, dynamic> toJson() {
    return {
      'offWeb': offWeb,
      'hosts': hosts,
      'paths': paths,
      'fragmentPrefix': fragmentPrefix,
    };
  }
}

/// 用于将URL与离线Web规则匹配并添加`offweb`查询参数的实用类。
///
/// 对应iOS的HLLOfflineWebBisNameMatch和Android的OffWebRuleUtil。
class OffWebRuleUtil {
  /// 将[url]与[config]规则匹配。如果找到匹配，
  /// 则将匹配的 business模块名称附加或替换到`offweb`查询参数，
  /// 并返回修改后的URL。
  ///
  /// 如果满足以下任一条件则返回原始[url]不变：
  /// - [url]为空
  /// - [config]为null
  /// - [config.rules]为空
  /// - 无规则匹配
  static String addOfflineParam(String url, OfflineRuleConfig? config) {
    // 对空/空输入提前返回
    if (url.isEmpty || config == null || config.rules.isEmpty) {
      return url;
    }

    // 解析URI
    Uri uri;
    try {
      uri = Uri.parse(url);
    } catch (_) {
      return url;
    }

    final host = uri.host;
    // 从path中去除尾部斜杠
    var path = uri.path;
    if (path.endsWith('/') && path.length > 1) {
      path = path.substring(0, path.length - 1);
    }

    // 提取fragment，去除'?'后的部分
    var fragment = uri.fragment;
    if (fragment.contains('?')) {
      fragment = fragment.substring(0, fragment.indexOf('?'));
    }

    // 匹配规则
    final matchedOffWeb = _matchRule(config, host, path, fragment);
    if (matchedOffWeb == null) {
      return url;
    }

    // 添加/替换offweb参数
    return _addParams(uri, matchedOffWeb);
  }

  /// 尝试将给定host/path/fragment与规则进行匹配。
  ///
  /// 返回匹配的`offWeb`值，如果无匹配则返回`null`。
  static String? _matchRule(
    OfflineRuleConfig config,
    String host,
    String path,
    String fragment,
  ) {
    for (final rule in config.rules) {
      // 检查host匹配
      if (!_matchHost(rule.hosts, host)) {
        continue;
      }

      // 检查path匹配（支持通配符）
      if (!_matchPath(rule.paths, path)) {
        continue;
      }

      // 检查fragment匹配
      if (!_matchFragment(rule.fragmentPrefix, fragment)) {
        continue;
      }

      // 所有检查通过
      return rule.offWeb;
    }
    return null;
  }

  /// 检查[host]是否匹配[hosts]中的任何条目。
  static bool _matchHost(List<String> hosts, String host) {
    if (hosts.isEmpty) return false;
    return hosts.contains(host);
  }

  /// 检查[path]是否匹配[paths]中的任何条目。
  ///
  /// 支持通配符`*`，可匹配任何单个路径段。
  /// 例如，`/a/*/c`匹配`/a/anything/c`。
  static bool _matchPath(List<String> paths, String path) {
    if (paths.isEmpty) return false;
    for (final pattern in paths) {
      if (_pathMatchesPattern(pattern, path)) {
        return true;
      }
    }
    return false;
  }

  /// 将单个路径[pattern]与实际[path]进行匹配。
  ///
  /// 按`/`分割并逐段比较。
  /// 模式中的`*`匹配任何单个段。
  static bool _pathMatchesPattern(String pattern, String path) {
    final patternSegments = pattern.split('/');
    final pathSegments = path.split('/');

    if (patternSegments.length != pathSegments.length) {
      return false;
    }

    for (int i = 0; i < patternSegments.length; i++) {
      final ps = patternSegments[i];
      final actual = pathSegments[i];

      if (ps == '*') {
        // 通配符匹配任何单个段
        continue;
      }
      if (ps != actual) {
        return false;
      }
    }
    return true;
  }

  /// 检查[fragment]是否匹配[fragmentPrefixes]中的任何fragment前缀。
  ///
  /// 如果[fragmentPrefixes]为空，则不应用限制（匹配成功）。
  static bool _matchFragment(List<String> fragmentPrefixes, String fragment) {
    // 空列表意味着没有fragment限制
    if (fragmentPrefixes.isEmpty) return true;

    for (final prefix in fragmentPrefixes) {
      if (fragment.startsWith(prefix)) {
        return true;
      }
    }
    return false;
  }

  /// 在URL中添加或替换`offweb`查询参数。
  ///
  /// 使用解析后的[uri]正确处理查询参数和hash fragment。
  /// 使用Uri.replace()正确重构URL。
  static String _addParams(Uri uri, String offWebValue) {
    // 构建新的查询参数字典，替换或添加offweb
    final newParams = Map<String, String>.from(uri.queryParameters);
    newParams[OfflineParam.offWeb] = offWebValue;

    // 使用Uri.replace正确重构带新参数的URL
    return uri.replace(queryParameters: newParams).toString();
  }
}
