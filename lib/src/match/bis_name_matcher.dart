/// 将URL匹配到业务模块名称的抽象接口。
///
/// 实现类定义如何将URL映射到离线包业务名称（例如通过host、path模式等）。
abstract class BisNameMatcher {
  /// 返回给定[url]的业务模块名称，
  /// 如果未找到匹配则返回空字符串。
  String matching(String url);
}
