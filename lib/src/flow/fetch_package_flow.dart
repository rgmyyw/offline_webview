import 'dart:async';

import '../core/offline_const.dart';
import '../net/offline_request.dart';
import '../package/offline_package_info.dart';
import '../monitor/flow_report_params.dart';
import '../util/off_web_log.dart';
import 'resource_flow.dart';

/// 提供访问共享manager依赖的provider接口。
abstract class OfflineWebManagerProvider {
  /// 用于服务器通信的请求接口。
  IOfflineRequest? get request;
}

/// Flow步骤：从服务器获取包信息。
///
/// 查询服务器获取给定bisName的最新包信息。
/// 如果需要更新，则更新flow上的包信息并继续管道。
/// 否则将flow标记为完成（无更新）。
class FetchPackageFlow implements IFlow {
  final ResourceFlow _flow;
  final String _bisName;
  final String _version;
  final OfflineWebResultBlock? _resultBlock;

  // 由OfflineWebManager在任务9-11中连接。
  static OfflineWebManagerProvider? _provider;

  /// 设置provider（在OfflineWebManager初始化期间调用）。
  static void setProvider(OfflineWebManagerProvider provider) {
    _provider = provider;
  }

  FetchPackageFlow({
    required ResourceFlow flow,
    required String bisName,
    required String version,
    OfflineWebResultBlock? resultBlock,
  }) : _flow = flow,
       _bisName = bisName,
       _version = version,
       _resultBlock = resultBlock;

  @override
  Future<void> process() async {
    const tag = 'FetchPackageFlow';
    Logger.d(tag, '开始 - bisName: $_bisName, version: $_version');

    // 验证bisName
    if (_bisName.isEmpty) {
      Logger.e(tag, 'bisName为空, 返回错误');
      _flow.error(Exception('bisName is empty'));
      return;
    }

    final request = _provider?.request;
    if (request == null) {
      Logger.e(tag, '请求接口为空, 返回错误');
      _flow.error(Exception('OfflineWebManagerProvider or request is null'));
      return;
    }

    // 从服务器请求包信息
    Logger.d(tag, '正在从服务器请求包信息 - bisName: $_bisName');
    final reportParams = _flow.reportParams;
    reportParams?.queryStart();

    // 使用Completer正确等待异步回调
    final completer = Completer<void>();

    request.requestPackageInfo(
      _bisName,
      _version,
      _RequestCallback(
        onSuccess: (OfflinePackageInfo packageInfo) {
          Logger.i(
            tag,
            '查询成功 - packageInfo: bisName=${packageInfo.bisName}, isEnable=${packageInfo.isEnable}, isSameVersion=${packageInfo.isSameVersion}, isNeedUpdate=${packageInfo.isNeedUpdate}',
          );
          reportParams?.queryEnd();
          // 只有在NOT isNeedUpdate时才从回调中调用_flow.process()
          // 如果isNeedUpdate=true，我们在_onQuerySuccess本身中处理延续
          _onQuerySuccess(packageInfo, reportParams);
          completer.complete();
        },
        onFail: (Object error) {
          Logger.e(tag, '查询失败 - 错误: $error');
          reportParams?.queryEnd();
          reportParams?.setQueryResult(false, error.toString());
          _flow.error(error);
          completer.completeError(error);
        },
      ),
    );

    // 等待异步回调完成后再返回
    try {
      await completer.future;
    } catch (_) {
      // 错误已在onFail回调中处理
    }
  }

  void _onQuerySuccess(
    OfflinePackageInfo packageInfo,
    FlowReportParams? reportParams,
  ) {
    const tag = 'FetchPackageFlow';
    Logger.d(
      tag,
      '_onQuerySuccess - bisName=${packageInfo.bisName}, isEnable=${packageInfo.isEnable}, isSameVersion=${packageInfo.isSameVersion}, isNeedUpdate=${packageInfo.isNeedUpdate}',
    );

    // 验证bisName匹配
    if (packageInfo.bisName != _bisName) {
      Logger.e(tag, 'bisName不匹配 - 期望=$_bisName, 实际=${packageInfo.bisName}');
      reportParams?.setQueryResult(false, 'bisName mismatch');
      _flow.error(
        Exception(
          'bisName mismatch: expected=$_bisName, got=${packageInfo.bisName}',
        ),
      );
      return;
    }

    // 检查isEnable
    if (!packageInfo.isEnable) {
      Logger.w(tag, '包已禁用');
      reportParams?.setQueryResult(true, 'disabled');
      _resultBlock?.call(
        OfflineWebResultEvent.disable,
        _bisName,
        'package is disabled',
      );
      _flow.setDone();
      return;
    }

    // 检查isSameVersion（无需更新）
    if (packageInfo.isSameVersion) {
      Logger.i(tag, '版本相同, 无需更新');
      reportParams?.setQueryResult(true, 'same version, no update');
      _resultBlock?.call(
        OfflineWebResultEvent.noUpdate,
        _bisName,
        'no update needed',
      );
      _flow.setDone();
      return;
    }

    // 检查isNeedUpdate
    if (packageInfo.isNeedUpdate) {
      Logger.i(tag, '需要更新, 设置包信息并继续管道');
      _flow.setPackageInfo(packageInfo);
      Logger.d(tag, '继续执行下载流程');
      return;
    }

    // 回退：未启用、版本相同、不需要更新
    Logger.d(tag, '无需操作, 设置完成');
    reportParams?.setQueryResult(true, 'no action needed');
    _flow.setDone();
  }
}

/// 将结果委托给闭包的私有[RequestCallback]实现。
class _RequestCallback implements RequestCallback<OfflinePackageInfo> {
  final void Function(OfflinePackageInfo data) _onSuccess;
  final void Function(Object error) _onFail;

  _RequestCallback({
    required void Function(OfflinePackageInfo data) onSuccess,
    required void Function(Object error) onFail,
  }) : _onSuccess = onSuccess,
       _onFail = onFail;

  @override
  void onSuccess(OfflinePackageInfo data) => _onSuccess(data);

  @override
  void onFail(Object error) => _onFail(error);
}
