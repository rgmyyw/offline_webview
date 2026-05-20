/// 用于拦截离线Web请求的抽象接口。
///
/// 实现类可以使用此接口阻止某些业务模块使用离线Web流程。
abstract class Interceptor {
  /// 如果业务模块[bisName]应被拦截（即绕过离线加载）则返回`true`。
  bool isIntercept(String bisName);
}

/// 不拦截任何请求的默认实现。
class DefaultInterceptor implements Interceptor {
  @override
  bool isIntercept(String bisName) => false;
}
