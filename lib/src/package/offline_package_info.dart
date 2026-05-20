/// 离线包检查服务器响应的模型。
class OfflinePackageInfo {
  final String bisName;
  final int result;
  final String url;
  final int refreshMode;
  final String version;

  const OfflinePackageInfo({
    required this.bisName,
    this.result = -1,
    this.url = '',
    this.refreshMode = 0,
    this.version = '0',
  });

  /// 此包是否启用（result不为-1）。
  bool get isEnable => result != -1;

  /// 当前版本是否与服务器版本匹配（result == 0）。
  bool get isSameVersion => result == 0;

  /// 是否需要更新（result == 1）。
  bool get isNeedUpdate => result == 1;

  /// 是否需要强制刷新（refreshMode == 1）。
  bool get isForceRefresh => refreshMode == 1;

  /// 从JSON map创建[OfflinePackageInfo]。
  factory OfflinePackageInfo.fromJson(Map<String, dynamic> json) {
    return OfflinePackageInfo(
      bisName: json['bisName']?.toString() ?? '',
      result: json['result'] as int? ?? -1,
      url: json['url']?.toString() ?? '',
      refreshMode: json['refreshMode'] as int? ?? 0,
      version: json['version']?.toString() ?? '0',
    );
  }

  /// 将此实例转换为JSON map。
  Map<String, dynamic> toJson() {
    return {
      'bisName': bisName,
      'result': result,
      'url': url,
      'refreshMode': refreshMode,
      'version': version,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OfflinePackageInfo && other.bisName == bisName;
  }

  @override
  int get hashCode => bisName.hashCode;

  @override
  String toString() {
    return 'OfflinePackageInfo(bisName: $bisName, result: $result, '
        'version: $version, refreshMode: $refreshMode, url: $url)';
  }
}
