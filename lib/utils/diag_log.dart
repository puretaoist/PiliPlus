import 'package:PiliPlus/utils/utils.dart';

/// fork 侧诊断日志的统一出口（设置 → 日志 → 导出）。
///
/// 本 fork 相对上游改了不少行为：4K/app 流取流与回退、推荐归因心跳、
/// 播放历史、内容偏好调节、弹幕节流与全屏刷新率…… 这些链路出问题时在真机上
/// 只表现为"没生效"（不崩、不弹错），所以每条链路都要往可导出日志里留痕。
///
/// 直接 `Utils.reportError('[DIAG] ...')` 的坑：同一个失败每次重试都写一行，
/// 实测一次运行写了 514 行 `reportHistory failed`，把日志顶到 700KB（真机日志
/// 2026-09-11~12）。这里按 [key] 做节流：
/// - 前 [maxTimes] 次逐条记录
/// - 之后每 [repeatEvery] 次记一条，并带上累计次数（不再逐条刷）
///
/// 约定 key 用 `模块.事件` 形式，例如 `heartbeat.fail`、`history.switch`。
abstract final class DiagLog {
  static final Map<String, int> _counts = {};
  static final Set<String> _onceKeys = {};

  /// 日志出口。默认写进 App 的可导出日志；测试里可替换成收集器
  static void Function(String message) write = _writeToAppLog;

  static void _writeToAppLog(String message) => Utils.reportError(message);

  /// 记录一条可能高频重复的诊断（按 key 节流）
  static void log(
    String key,
    String message, {
    int maxTimes = 3,
    int repeatEvery = 50,
  }) {
    final n = (_counts[key] ?? 0) + 1;
    _counts[key] = n;
    if (n <= maxTimes) {
      write('[DIAG] $message');
    } else if (repeatEvery > 0 && n % repeatEvery == 0) {
      write('[DIAG] $message（同类已累计 $n 次）');
    }
  }

  /// 只记第一次（用于"开关生效/通道切换/启动状态"这类一次性事实）
  static void once(String key, String message) {
    if (!_onceKeys.add(key)) return;
    write('[DIAG] $message');
  }

  /// 每次都记（用于低频且关键的成功路径）
  static void always(String message) => write('[DIAG] $message');

  /// 某 key 已记录次数（测试用）
  static int countOf(String key) => _counts[key] ?? 0;

  /// 清空节流状态（测试用）
  static void reset() {
    _counts.clear();
    _onceKeys.clear();
    write = _writeToAppLog;
  }
}
