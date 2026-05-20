import '../package/offline_package_info.dart';

/// 异步请求结果的回调接口。
abstract class RequestCallback<T> {
  /// 请求成功并返回[data]时调用。
  void onSuccess(T data);

  /// 请求失败并返回[error]时调用。
  void onFail(Object error);
}

/// 与离线包相关的服务器请求抽象接口。
abstract class IOfflineRequest {
  /// 请求给定[bisName]和当前[version]的包信息。
  /// 结果通过[callback]传递。
  void requestPackageInfo(
      String bisName, String version, RequestCallback<OfflinePackageInfo> callback);
}
