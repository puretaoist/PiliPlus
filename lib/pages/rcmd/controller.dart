import 'package:flutter/foundation.dart' show debugPrint;
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/models/home/rcmd/result.dart';
import 'package:PiliPlus/pages/common/common_list_controller.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/utils.dart';

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

  /// 本次会话是否已记录过沉底分布（避免高频写日志）
  static bool _demoteLogged = false;

  @override
  bool get isEnd => false;

  @override
  void onInit() {
    super.onInit();
    try {
      _seen.addAll(Pref.rcmdSeenAids);
      _seenSet.addAll(_seen);
    } catch (e) {
      // 记录损坏时当作空处理，绝不让首页崩掉
      debugPrint('load rcmd seen failed: $e');
      _seen.clear();
      _seenSet.clear();
    }
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
    try {
      Pref.setRcmdSeenAids(_seen);
    } catch (e) {
      debugPrint('save rcmd seen failed: $e');
    }
  }

  void _markSeen(List<int> aids) {
    if (aids.isEmpty) return;
    try {
      var added = false;
      for (final aid in aids) {
        if (_seenSet.add(aid)) {
          _seen.add(aid);
          added = true;
        }
      }
      // 没有新增就别写盘，避免每次下拉都全量序列化
      if (!added) return;
      if (_seen.length > _maxSeen) {
        final overflow = _seen.length - _maxSeen;
        for (var i = 0; i < overflow; i++) {
          _seenSet.remove(_seen[i]);
        }
        _seen.removeRange(0, overflow);
      }
      Pref.setRcmdSeenAids(_seen);
    } catch (e) {
      // 持久化失败只影响去重记忆，绝不能让首页崩掉
      debugPrint('save rcmd seen failed: $e');
    }
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
    // enableSaveLastData 的语义是"失败时保留旧数据"；
    // 但首次加载/无旧数据时吞掉错误会让首页永远空白，此时应显示错误
    final hasData = loadingState.value.dataOrNull?.isNotEmpty == true;
    return enableSaveLastData && hasData;
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
      // 已看过的内容"沉底"而不是删除。
      // 第三方客户端的推荐池有限、服务端必然重推，删除式过滤会让列表
      // 越刷越短甚至刷空；降权排序既保证新内容排在前面（去重的实际收益），
      // 又保证首页永远有内容，从机制上不可能刷空。
      final fresh = <dynamic>[];
      final seen = <dynamic>[];
      final ids = <int>[];
      for (final e in dataList) {
        final id = e is RcmdVideoItemAppModel ? e.id : null;
        if (id != null) {
          ids.add(id);
        }
        if (id != null && _seenSet.contains(id)) {
          seen.add(e);
        } else {
          fresh.add(e);
        }
      }
      if (seen.isNotEmpty) {
        dataList
          ..clear()
          ..addAll(fresh)
          ..addAll(seen);
      }
      // 沉底分布写进可导出日志：用于判断 seen 是否异常膨胀导致内容枯竭
      if (!_demoteLogged || fresh.isEmpty) {
        _demoteLogged = true;
        Utils.reportError(
          '[DIAG] rcmd demote fresh=${fresh.length} seen=${seen.length} '
          'total=${_seen.length}',
        );
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
