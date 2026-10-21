import 'package:PiliPlus/models/home/rcmd/result.dart';
import 'package:PiliPlus/models/model_rec_video_item.dart';
import 'package:PiliPlus/models/model_video.dart';
import 'package:PiliPlus/utils/rcmd_resort.dart';
import 'package:flutter_test/flutter_test.dart';

/// 守护 P1「推荐重排」的三条底线：
/// 1. 只动顺序、不动内容 —— 条目数、集合必须与输入完全一致
/// 2. 没有可用信号时保持原样 —— 不能在没把握的情况下打乱首页
/// 3. 默认关闭 —— 不擅自改变任何人的首页
class _Item extends BaseRcmdVideoItemModel {
  _Item({
    required int cid,
    required int mid,
    int duration = 600,
    this.zone = 1,
    bool followed = false,
  }) {
    this.cid = cid;
    this.duration = duration;
    isFollowed = followed;
    title = 'video$cid';
    owner = _Owner(mid);
    stat = RcmdStat.fromJson(const {});
  }

  final int zone;

  int? get tid => zone;
}

class _Owner extends BaseOwner {
  _Owner(int mid) {
    this.mid = mid;
    name = 'up$mid';
  }
}

void main() {
  int? Function(int) progress(Map<int, int> map) =>
      (cid) => map.containsKey(cid) ? map[cid] : null;
  int? zoneOf(BaseRcmdVideoItemModel i) => (i as _Item).zone;

  /// 统一的调用入口：默认无任何信号
  List<int>? order(
    List<BaseRcmdVideoItemModel> items, {
    Map<int, int> progressMs = const {},
  }) => RcmdResort.computeOrder(
    items,
    progressMs: progress(progressMs),
    zoneOf: zoneOf,
  );

  List<_Item> itemsOf(
    int n, {
    bool Function(int)? followed,
    int Function(int)? mid,
  }) => [
    for (var i = 0; i < n; i++)
      _Item(
        cid: i,
        mid: mid?.call(i) ?? (100 + i),
        zone: i + 1,
        followed: followed?.call(i) ?? false,
      ),
  ];

  test('默认关闭（不擅自改动任何人的首页）', () {
    // 注意：不断言 RcmdResort.enabled == false，因为该 getter 会读 Hive 设置；
    // 单元测试环境没有初始化 box 时会走容错分支。真正要守护的是"默认值"。
    expect(RcmdResort.enabledByDefault, isFalse);
  });

  test('低于 2 条不做处理', () {
    expect(order(<BaseRcmdVideoItemModel>[]), isNull);
    expect(order([_Item(cid: 1, mid: 1)]), isNull);
  });

  test('完全没有信号时返回 null，顺序保持原样', () {
    expect(order(itemsOf(5)), isNull);
  });

  test('已关注 UP 提前', () {
    final items = itemsOf(3, followed: (i) => i == 2);
    final result = order(items);
    expect(result, isNotNull);
    expect(result!.first, 2, reason: '被关注的第 3 条应排到最前');
  });

  test('已看完的往后排', () {
    final items = itemsOf(3);
    // cid=0 时长 600s，进度 600s → 已看完
    final result = order(items, progressMs: {0: 600000});
    expect(result, isNotNull);
    expect(result!.last, 0, reason: '已看完的应排到最后');
  });

  test('看了一部分的轻微降权，但仍排在已看完之前', () {
    final items = itemsOf(3);
    final result = order(items, progressMs: {0: 60000, 1: 600000});
    expect(result, isNotNull);
    expect(result!.last, 1, reason: '已看完(cid=1)应最靠后');
    expect(
      result.indexOf(0) < result.indexOf(1),
      isTrue,
      reason: '看了 1 分钟的(cid=0)应排在已看完的(cid=1)之前',
    );
  });

  test('同 UP 不连续相邻（同 UP 占多数时也要掰开）', () {
    // 5 条同一个 UP + 3 条不同 UP：原始顺序里 UP7 连着 5 条
    final items = [
      for (var i = 0; i < 5; i++)
        _Item(cid: i, mid: 7, zone: i % 2 + 1, followed: true),
      for (var i = 5; i < 8; i++)
        _Item(cid: i, mid: 100 + i, zone: i % 2 + 1, followed: true),
    ];
    final result = order(items);
    expect(result, isNotNull);
    var adjacent = 0;
    for (var i = 0; i + 1 < result!.length; i++) {
      if (items[result[i]].owner.mid == items[result[i + 1]].owner.mid) {
        adjacent++;
      }
    }
    // 原始是 7 条相邻对里有 4 条同 UP；重排后应显著减少
    expect(
      adjacent,
      lessThanOrEqualTo(1),
      reason: '同 UP 仍大量相邻：$result',
    );
  });

  test('整批只有一个 UP 时不抖动（无处错开就别动）', () {
    final items = [
      for (var i = 0; i < 4; i++)
        _Item(cid: i, mid: 7, zone: i + 1, followed: true),
    ];
    expect(
      order(items),
      isNull,
      reason: '全是同一个 UP 时，重排只会造成无意义的顺序变化',
    );
  });

  test('时长未知(<=0)时不做已看完判断', () {
    expect(RcmdResort.isCompleted(999999, 0), isFalse);
    expect(RcmdResort.isCompleted(999999, -1), isFalse);
    expect(RcmdResort.isCompleted(0, 600), isFalse);
  });

  test('已看完判定边界：距片尾 5 秒内算看完', () {
    expect(RcmdResort.isCompleted(600000, 600), isTrue, reason: '正好片尾');
    expect(RcmdResort.isCompleted(595000, 600), isTrue, reason: '差 5 秒');
    expect(RcmdResort.isCompleted(594000, 600), isFalse, reason: '差 6 秒不算');
  });

  test('只重排不丢内容：结果必须是输入的排列', () {
    final items = [
      for (var i = 0; i < 12; i++)
        _Item(
          cid: i,
          mid: i.isEven ? 5 : 100 + i, // 制造重复 UP
          zone: i % 3,
          followed: i == 7,
        ),
    ];
    final result = order(items, progressMs: {0: 600000, 1: 30000});
    expect(result, isNotNull);
    expect(result!.length, items.length);
    expect(result.toSet().length, items.length, reason: '不能有重复下标');
    final sorted = [...result]..sort();
    expect(
      sorted,
      List.generate(items.length, (i) => i),
      reason: '必须是 0..n-1 的排列，不能丢条目',
    );
  });

  test('没有进度、没有关注、没有分区时稳定性：结果仍是 0..n-1', () {
    final items = itemsOf(6, mid: (i) => i); // 每个 UP 都不同
    // 没有任何提权/降权 → 应返回 null（顺序未变），不产生无意义的改动
    expect(order(items), isNull);
  });
}
