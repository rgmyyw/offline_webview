import '../package/offline_package_info.dart';
import '../monitor/flow_report_params.dart';
import '../util/off_web_log.dart';

/// Flow结果处理的策略接口。
abstract class IFlowResultHandleStrategy {
  /// 当flow流程完成时调用。
  void done(FlowReportParams params);
}

/// 默认实现，不对结果做任何处理。
class DefaultFlowResultHandleStrategy implements IFlowResultHandleStrategy {
  @override
  void done(FlowReportParams params) {
    // 默认no-op
  }
}

/// Flow完成事件的监听器。
abstract class FlowListener {
  /// 当flow成功完成并带有可选的[info]时调用。
  void done(OfflinePackageInfo? info);

  /// 当flow遇到错误时调用。
  void error(OfflinePackageInfo? info, Object err);
}

/// 处理离线包的处理管道中单个步骤的抽象接口。
abstract class IFlow {
  /// 执行此flow步骤。
  Future<void> process();
}

/// 为离线包编排一组[IFlow]步骤的管道。
///
/// 持有包信息、上报参数和监听器。Flows通过[start]顺序执行。
/// 支持通过[stop]提前终止。
class ResourceFlow {
  final List<IFlow> _flows = [];
  OfflinePackageInfo? _packageInfo;
  FlowReportParams? _reportParams;
  FlowListener? _listener;
  bool _stopped = false;

  /// 将flow步骤添加到管道。
  ResourceFlow addFlow(IFlow flow) {
    _flows.add(flow);
    return this;
  }

  /// 设置flow监听器用于完成/错误回调。
  ResourceFlow setFlowListener(FlowListener listener) {
    _listener = listener;
    return this;
  }

  /// 设置此flow执行的包信息。
  ResourceFlow setPackageInfo(OfflinePackageInfo info) {
    _packageInfo = info;
    return this;
  }

  /// 设置监控的上报参数。
  ResourceFlow setReportParams(FlowReportParams params) {
    _reportParams = params;
    return this;
  }

  /// 获取当前包信息。
  OfflinePackageInfo? get packageInfo => _packageInfo;

  /// 获取当前上报参数。
  FlowReportParams? get reportParams => _reportParams;

  /// 信号管道在当前步骤后停止。
  void stop() {
    _stopped = true;
  }

  /// 管道是否已被停止。
  bool get isStopped => _stopped;

  /// 开始顺序执行所有flow步骤。
  Future<void> start() async {
    _stopped = false;
    await process();
  }

  /// 按顺序执行每个flow步骤，在步骤之间检查[isStopped]。
  Future<void> process() async {
    const tag = 'ResourceFlow';
    for (final flow in _flows) {
      Logger.d(tag, '正在处理: ${flow.runtimeType}');
      if (_stopped) {
        Logger.d(tag, '已停止, 跳出循环');
        break;
      }
      try {
        await flow.process();
      } catch (e) {
        Logger.e(tag, '流程异常: $e');
        error(e);
        return;
      }
    }
    if (!_stopped) {
      Logger.i(tag, '所有流程已完成');
      setDone();
    }
  }

  /// 将flow标记为成功完成, 停止管道并通知监听器。
  void setDone() {
    _stopped = true;
    _listener?.done(_packageInfo);
  }

  /// 报告错误并通知监听器。
  void error(Object err) {
    _listener?.error(_packageInfo, err);
  }
}
