import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/models/home/rcmd/result.dart';
import 'package:PiliPlus/models/model_rec_video_item.dart';
import 'package:PiliPlus/pages/common/common_list_controller.dart';
import 'package:PiliPlus/utils/diag_log.dart';
import 'package:PiliPlus/utils/rcmd_resort.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_pref.dart';

class RcmdController extends CommonListController {
  late bool enableSaveLastData = Pref.enableSaveLastData;
  final bool appRcmd = Pref.appRcmd;

  int? lastRefreshAt;
  late bool savedRcmdTip = Pref.savedRcmdTip;

  // app 推荐接口的会话内请求计数（刷新归零、每次成功后 +1）
  int _flush = 0;
  bool _isRefresh = true;

  /// 原始续推游标（必须在任何重排之前读取）。
  ///
  /// app 推荐接口的 `idx` 在同一页内**递减**，所以"刷新取首条、加载更多取末条"
  /// 依赖列表顺序。一旦我们在客户端重排，`list.first/last` 就不再是原始的首/末
  /// 条 —— 直接读会把错误的 idx 回传给服务端，导致反复拿到同一批内容或跳页。
  /// 因此这里单独缓存收到数据时的真实极值，重排只影响展示顺序。
  int? _idxNewest;
  int? _idxOldest;

  @override
  bool get isEnd => false;

  @override
  void onInit() {
    super.onInit();
    page = 0;
    queryData();
  }

  @override
  Future<void> queryData([bool isRefresh = true]) {
    _isRefresh = isRefresh;
    return super.queryData(isRefresh);
  }

  // 刷新取列表首条的 idx、加载更多取末条的 idx
  int _cursor({required bool first}) {
    if (appRcmd) {
      final cached = first ? _idxNewest : _idxOldest;
      if (cached != null) return cached;
    }
    final list = loadingState.value.dataOrNull;
    if (list == null || list.isEmpty) {
      return 0;
    }
    final item = first ? list.first : list.last;
    return item is RcmdVideoItemAppModel ? (item.idx ?? 0) : 0;
  }

  /// 记录本批数据的原始 idx 极值（重排前调用）
  void _cacheCursor(List dataList) {
    if (!appRcmd) return;
    int? maxIdx;
    int? minIdx;
    for (final e in dataList) {
      if (e is! RcmdVideoItemAppModel) continue;
      final idx = e.idx;
      if (idx == null) continue;
      if (maxIdx == null || idx > maxIdx) maxIdx = idx;
      if (minIdx == null || idx < minIdx) minIdx = idx;
    }
    if (maxIdx != null) {
      // 刷新时取本批最大（最新）游标；加载更多不会更新它
      if (_isRefresh || _idxNewest == null || maxIdx > _idxNewest!) {
        _idxNewest = maxIdx;
      }
    }
    // 加载更多是向下推进，最小值每次都会被刷新
    if (minIdx != null) _idxOldest = minIdx;
  }

  @override
  Future<LoadingState> customGetData() {
    if (!appRcmd) {
      return VideoHttp.rcmdVideoList(freshIdx: page, ps: 20);
    }
    return VideoHttp.rcmdVideoListApp(
      idx: _cursor(first: _isRefresh),
      flush: _flush,
      pull: _isRefresh,
    );
  }

  @override
  bool handleError(String? errMsg) {
    // enableSaveLastData 的语义是"失败时保留旧数据"；
    // 但首次加载/无旧数据时吞掉错误会让首页永远空白，此时应显示错误
    final hasData = loadingState.value.dataOrNull?.isNotEmpty == true;
    final keep = enableSaveLastData && hasData;
    DiagLog.log(
      'rcmd.error',
      '首页推荐请求失败：${keep ? '保留旧数据' : '无旧数据 → 直接显示错误'}'
      '（$errMsg）',
    );
    return keep;
  }

  @override
  void handleListResponse(List dataList) {
    // 游标必须在重排之前固定（见 _idxNewest 注释）
    _cacheCursor(dataList);

    // 本批新到的条数。下面可能把上次的内容拼到尾部，重排只能作用于这一段，
    // 否则会把已经显示过的旧内容也打乱，且会让「上次看到这里」标记错位
    final freshLength = dataList.length;

    if (enableSaveLastData && page == 0) {
      if (loadingState.value case Success(:final response)) {
        if (response != null && response.isNotEmpty) {
          if (savedRcmdTip) {
            lastRefreshAt = dataList.length;
          }
          if (response.length > 200) {
            // upstream bug 修复（行为等价）：take(50) 返回 Iterable<dynamic>，
            // 而 dataList 运行时是 List<RcmdVideoItemXxx>，addAll 触发集合类型
            // 检查抛异常 → loadingState 不更新 → 刷新失败（保留数据 >200 条时
            // 必现，真机日志已证实）。逐元素写入规避。
            for (final e in response.take(50)) {
              dataList.add(e);
            }
          } else {
            dataList.addAll(response);
          }
        }
      }
    }

    _resort(dataList, freshLength);

    _flush++;
  }

  /// 在客户端重排本批新内容（只在用户开启「推荐重排」时生效）
  void _resort(List dataList, int freshLength) {
    if (!RcmdResort.enabled) return;
    if (freshLength < 2 || freshLength > dataList.length) return;

    final batch = <BaseRcmdVideoItemModel>[];
    for (var i = 0; i < freshLength; i++) {
      final e = dataList[i];
      if (e is! BaseRcmdVideoItemModel) {
        // 首页出现非视频卡片时不做重排（不要在混合类型上猜顺序）
        DiagLog.once('rcmd.resort.skip', '首页推荐含非视频卡片，本轮跳过重排');
        return;
      }
      batch.add(e);
    }

    final order = RcmdResort.computeOrder(
      batch,
      progressMs: _progressOf,
      zoneOf: RcmdResort.zoneOfItem,
    );
    if (order == null) return;

    final reordered = [for (final index in order) batch[index]];
    for (var i = 0; i < freshLength; i++) {
      dataList[i] = reordered[i];
    }
    // 不记成功日志：重排效果在界面上直接可见，且本项目约定只记失败/降级
  }

  /// 本地播放进度（按 cid 存），零额外请求
  static int? _progressOf(int cid) => GStorage.watchProgress.get(cid.toString());

  @override
  Future<void> onRefresh() {
    page = 0;
    isEnd = false;
    _flush = 0;
    return queryData();
  }
}
