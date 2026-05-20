/// 离线Web SDK的配置类。
///
/// 控制哪些业务模块启用离线支持，哪些被禁用。
class OfflineConfig {
  final bool isOpen;
  final Set<String> preDownloadList;
  final Set<String> disableList;

  const OfflineConfig({
    this.isOpen = false,
    this.preDownloadList = const {},
    this.disableList = const {},
  });

  /// 判断给定的[bisName]是否在禁用列表中。
  bool isDisable(String bisName) => disableList.contains(bisName);
}

/// [OfflineConfig]的构建器。
///
/// 通过链式调用方式构建[OfflineConfig]，在调用[build]之前
/// 可以添加预下载和禁用条目。
class OfflineConfigBuilder {
  bool _isOpen = false;
  final Set<String> _preDownloadList = {};
  final Set<String> _disableList = {};

  /// 设置离线Web是否启用。
  OfflineConfigBuilder isOpen(bool value) {
    _isOpen = value;
    return this;
  }

  /// 添加单个业务名称到预下载列表。
  OfflineConfigBuilder addPreDownload(String bisName) {
    _preDownloadList.add(bisName);
    return this;
  }

  /// 添加多个业务名称到预下载列表。
  OfflineConfigBuilder addPreDownloadList(List<String> list) {
    _preDownloadList.addAll(list);
    return this;
  }

  /// 添加单个业务名称到禁用列表。
  OfflineConfigBuilder addDisable(String bisName) {
    _disableList.add(bisName);
    return this;
  }

  /// 添加多个业务名称到禁用列表。
  OfflineConfigBuilder addDisableList(List<String> list) {
    _disableList.addAll(list);
    return this;
  }

  /// 构建不可变的[OfflineConfig]。
  OfflineConfig build() {
    return OfflineConfig(
      isOpen: _isOpen,
      preDownloadList: Set.unmodifiable(_preDownloadList),
      disableList: Set.unmodifiable(_disableList),
    );
  }
}
