import 'package:PiliPlus/utils/diag_log.dart';
import 'package:flutter_test/flutter_test.dart';

/// 守护 DiagLog 的节流行为：它决定真机日志会不会被同一个失败刷爆
/// （历史问题：一次运行 514 行 `reportHistory failed`，日志 700KB）。
///
/// 约定：**只记出问题的事**——成功路径不写日志，日志里出现的每一行都应该
/// 指示"有东西不对"。
void main() {
  late List<String> out;

  setUp(() {
    DiagLog.reset();
    out = [];
    DiagLog.write = out.add;
  });

  tearDown(DiagLog.reset);

  test('log：前 maxTimes 次逐条，之后每 repeatEvery 次记一条汇总', () {
    for (var i = 1; i <= 100; i++) {
      DiagLog.log('history.app.fail', 'msg$i', maxTimes: 3, repeatEvery: 50);
    }
    // 3 条逐条 + 第 50、100 次的两条汇总
    expect(out.length, 5);
    expect(out[0], '[DIAG] msg1');
    expect(out[2], '[DIAG] msg3');
    expect(out[3], contains('已累计 50 次'));
    expect(out[4], contains('已累计 100 次'));
    expect(DiagLog.countOf('history.app.fail'), 100);
  });

  test('log：不同 key 各自独立计数', () {
    DiagLog.log('a', 'A');
    DiagLog.log('b', 'B');
    DiagLog.log('a', 'A2');
    expect(out, ['[DIAG] A', '[DIAG] B', '[DIAG] A2']);
  });

  test('once：同一个 key 只记一次', () {
    DiagLog.once('grpc.ok', 'first');
    DiagLog.once('grpc.ok', 'second');
    expect(out, ['[DIAG] first']);
  });
}
