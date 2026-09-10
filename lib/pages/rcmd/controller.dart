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
