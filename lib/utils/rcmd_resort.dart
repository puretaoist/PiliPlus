import 'package:PiliPlus/models/home/rcmd/result.dart';
import 'package:PiliPlus/models/model_rec_video_item.dart';
import 'package:PiliPlus/utils/storage_pref.dart';

/// 首页推荐在客户端重排（P1）。
///
/// 背景（真机与实测结论）：服务端下发的首页是**热门库存池**，不是画像 ——
/// 100 条里 60~73% 来自 `newuser` 池，推荐理由几乎全是「1万点赞」这类
/// 点赞数导向；同一 buvid 连续两次请求 0 条重合，反而两台全新设备之间
/// 重合约 43%。个性化本身很浅，客户端拿不到"服务端认为你喜欢什么"。
///
/// 既然服务端不给画像，就在本地用**已有的、零额外请求的**信号重排：
///
/// 1. `isFollowed`（服务端给的「已关注 / 新关注」）→ 提权
/// 2. 本地 `watchProgress`（按 cid 存的播放进度，用户真的点开过才写）
///    → 已看完的降权、看过一部分的轻微降权
/// 3. 相邻去重：同 UP、同分区不要连着排（首页常见连续多条同一 UP）
///
/// 刻意**不做**的事（避免猜用户的品味）：
/// - 不按播放量高低排序（"爆款"不等于用户不爱看）
/// - 不按点赞率排序（`RcmdStat` 本来就没有 like 字段，只有
///   `rcmdReason` 含「赞」时才零星补上）
/// - 不删除任何条目（只重排；条目变少会让首页刷新变空）
/// - 不记录任何新的持久化数据（不新增黑名单/画像，避免隐私与迁移负担）
///
/// 稳定性：[computeOrder] 用"严格大于"挑选，等分条目保持原有相对顺序；
/// 若最终顺序与原顺序完全相同则返回 null，调用方不做任何改动。
/// 因此"没有可用信号"时首页一个字都不会动。
abstract final class RcmdResort {
  /// 是否启用（设置项，默认关 —— 未经用户同意不改动首页顺序）
  static bool enabled = Pref.rcmdResort;

  /// 关注的 UP：明显提权
  static const double followedBonus = 3.0;

  /// 已看完（进度到达片尾）：明显降权
  static const double completedPenalty = -4.0;

  /// 看过一部分：轻微降权（可能还想继续看，不能压太狠）
  static const double openedPenalty = -1.0;

  /// 与「上一条」同 UP 的惩罚。
  /// 取值大于 [followedBonus]，保证"关注了但连续刷到同一 UP"时会让位 ——
  /// 首页经常连着好几条同一个 UP，把它们掰开比让它们挤在前面更有价值。
  ///
  /// 刻意**不设"每个 UP 最多出现 N 条"的硬上限**：如果用户关注了某 UP
  /// 且服务端连发 6 条，说明这确实是他的兴趣所在；压掉等于替用户做决定。
  /// 这里只负责让它们不连在一起，不负责减少总量。
  static const double adjacentSameMidPenalty = 4.0;

  /// 与「上一条」同分区的惩罚（弱于同 UP：同分区连着看通常无所谓）
  static const double adjacentSameZonePenalty = 0.8;

  /// 「已看完」判定：进度距片尾不足 5 秒。
  /// 时长未知时不做判断（`duration <= 0`）—— 宁可不动顺序。
  static bool isCompleted(int progressMs, int durationSec) {
    if (durationSec <= 0 || progressMs <= 0) return false;
    return durationSec * 1000 - progressMs <= 5000;
  }

  /// 计算重排后的下标顺序；不需要调整时返回 null。
  ///
  /// [items] 只传**本次新到的这一批**（刷新时即页首新数据），
  /// 不包含「保留首页推荐刷新」拼进来的旧内容 —— 旧内容已经在屏幕上
  /// 显示过，动它会让人以为内容被换掉了。
  ///
  /// [progressMs] 传入"按 cid 查本地播放进度"的函数，返回 null 表示没看过。
  ///
  /// [zoneOf] 传入"取分区 id"的函数（app 推荐才有 `tid`，web 推荐没有）。
  /// 用回调而不是在这里判类型，是为了让本模块不依赖具体模型、可直接单测。
  static List<int>? computeOrder(
    List<BaseRcmdVideoItemModel> items, {
    required int? Function(int cid) progressMs,
    int? Function(BaseRcmdVideoItemModel item)? zoneOf,
  }) {
    if (items.length < 2) return null;

    final zones = List<int?>.filled(items.length, null);
    if (zoneOf != null) {
      for (var i = 0; i < items.length; i++) {
        zones[i] = zoneOf(items[i]);
      }
    }

    final scores = List<double>.filled(items.length, 0);
    for (var i = 0; i < items.length; i++) {
      scores[i] = _score(items[i], progressMs);
    }

    // 整批只有一个 UP / 只有一个分区时，"错开"无处可去，只按分数排即可，
    // 否则邻接惩罚会在同分条目之间制造无意义的顺序抖动。
    final midSpreadable = _distinctCount(items, (i) => i.owner.mid) > 1;
    final zoneSpreadable = zones.where((z) => z != null).toSet().length > 1;

    final remaining = List<int>.generate(items.length, (i) => i);
    final order = <int>[];
    int? lastMid;
    int? lastZone;

    while (remaining.isNotEmpty) {
      var bestPos = 0;
      var bestValue = double.negativeInfinity;
      for (var pos = 0; pos < remaining.length; pos++) {
        final index = remaining[pos];
        final item = items[index];
        var value = scores[index];
        if (midSpreadable && lastMid != null && item.owner.mid == lastMid) {
          value -= adjacentSameMidPenalty;
        }
        final zone = zones[index];
        if (zoneSpreadable && lastZone != null && zone == lastZone) {
          value -= adjacentSameZonePenalty;
        }
        // 严格大于：等分保持原有相对顺序（稳定）
        if (value > bestValue) {
          bestValue = value;
          bestPos = pos;
        }
      }

      final picked = remaining.removeAt(bestPos);
      order.add(picked);
      lastMid = items[picked].owner.mid;
      lastZone = zones[picked];
    }

    for (var i = 0; i < order.length; i++) {
      if (order[i] != i) return order;
    }
    // 顺序没变就不返回，让调用方完全跳过写入
    return null;
  }

  static double _score(
    BaseRcmdVideoItemModel item,
    int? Function(int cid) progressMs,
  ) {
    var score = 0.0;
    if (item.isFollowed) score += followedBonus;

    final cid = item.cid;
    if (cid != null) {
      final progress = progressMs(cid);
      if (progress != null && progress > 0) {
        score += isCompleted(progress, item.duration)
            ? completedPenalty
            : openedPenalty;
      }
    }
    return score;
  }

  /// 本批里有多少个不同的非空值（用于判断"错开"是否有意义）
  static int _distinctCount(
    List<BaseRcmdVideoItemModel> items,
    int? Function(BaseRcmdVideoItemModel) pick,
  ) {
    final seen = <int>{};
    for (final item in items) {
      final value = pick(item);
      if (value != null) seen.add(value);
    }
    return seen.length;
  }

  /// 只有 app 推荐才带分区 id；web 推荐没有，按"无分区"处理
  static int? zoneOfItem(BaseRcmdVideoItemModel item) =>
      item is RcmdVideoItemAppModel ? item.tid : null;
}
