import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/models/home/rcmd/result.dart';
import 'package:PiliPlus/pages/common/common_list_controller.dart';
import 'package:PiliPlus/utils/storage_pref.dart';

class RcmdController extends CommonListController {
  late bool enableSaveLastData = Pref.enableSaveLastData;
  final bool appRcmd = Pref.appRcmd;

  int? lastRefreshAt;
  late bool savedRcmdTip = Pref.savedRcmdTip;

  // app 推荐接口的会话内请求计数（刷新归零、每次成功后 +1）
  int _flush = 0;
  bool _isRefresh = true;

  // 已推过的内容（aid）。第三方客户端不做曝光上报，服务端不知道"这条我看过了"，
  // 因此本地记一份，避免刷新后反复推同样的视频
  static const int _maxSeen = 2000;
  final List<int> _seen = [];
  final Set<int> _seenSet = {};
  bool filterSeen = Pref.rcmdFilterSeen;

  @override
  bool get isEnd => false;

  @override
  void onInit() {
    super.onInit();
    _seen.addAll(Pref.rcmdSeenAids);
    _seenSet.addAll(_seen);
    page = 0;
    queryData();
  }

  void setFilterSeen(bool enabled) {
    filterSeen = enabled;
    if (!enabled) {
      clearSeen();
    }
  }

  /// 清空已推记录（设置里关闭过滤，或想让推荐"重置"时用）
  void clearSeen() {
    _seen.clear();
    _seenSet.clear();
    Pref.setRcmdSeenAids(_seen);
  }

  void _markSeen(List<int> aids) {
    if (aids.isEmpty) return;
    for (final aid in aids) {
      if (_seenSet.add(aid)) {
        _seen.add(aid);
      }
    }
    if (_seen.length > _maxSeen) {
      final overflow = _seen.length - _maxSeen;
      for (var i = 0; i < overflow; i++) {
        _seenSet.remove(_seen[i]);
      }
      _seen.removeRange(0, overflow);
    }
    Pref.setRcmdSeenAids(_seen);
  }

  @override
  Future<void> queryData([bool isRefresh = true]) {
    _isRefresh = isRefresh;
    return super.queryData(isRefresh);
  }

  // 刷新取列表首条的 idx、加载更多取末条的 idx
  int _cursor({required bool first}) {
    final list = loadingState.value.dataOrNull;
    if (list == null || list.isEmpty) {
      return 0;
    }
    final item = first ? list.first : list.last;
    return item is RcmdVideoItemAppModel ? (item.idx ?? 0) : 0;
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
    return enableSaveLastData;
  }

  @override
  void handleListResponse(List dataList) {
    if (enableSaveLastData && page == 0) {
      if (loadingState.value case Success(:final response)) {
        if (response != null && response.isNotEmpty) {
          if (savedRcmdTip) {
            lastRefreshAt = dataList.length;
          }
          if (response.length > 200) {
            dataList.addAll(response.take(50));
          } else {
            dataList.addAll(response);
          }
        }
      }
    }

    if (filterSeen && dataList.isNotEmpty) {
      final before = dataList.length;
      final kept = <dynamic>[];
      for (final e in dataList) {
        final id = e is RcmdVideoItemAppModel ? e.id : null;
        if (id != null && _seenSet.contains(id)) {
          continue;
        }
        kept.add(e);
      }
      // 安全阀：推荐池有限，若绝大多数都推过则本轮不过滤，避免首页刷空
      if (kept.isNotEmpty && kept.length * 10 >= before * 3) {
        dataList
          ..clear()
          ..addAll(kept);
      }
      final ids = <int>[];
      for (final e in dataList) {
        final id = e is RcmdVideoItemAppModel ? e.id : null;
        if (id != null) {
          ids.add(id);
        }
      }
      _markSeen(ids);
    }

    _flush++;
  }

  @override
  Future<void> onRefresh() {
    page = 0;
    isEnd = false;
    _flush = 0;
    return queryData();
  }
}
