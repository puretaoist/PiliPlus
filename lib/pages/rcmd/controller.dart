import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/models/home/rcmd/result.dart';
import 'package:PiliPlus/pages/common/common_list_controller.dart';
import 'package:PiliPlus/utils/diag_log.dart';
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
      DiagLog.once('rcmd.mode', '首页推荐：使用 web 端接口（appRcmd=false）');
      return VideoHttp.rcmdVideoList(freshIdx: page, ps: 20);
    }
    DiagLog.once(
      'rcmd.mode',
      '首页推荐：使用 app 端接口（appRcmd=true，带 track_id/report_data 归因参数）',
    );
    final cursor = _cursor(first: _isRefresh);
    // 游标/flush/pull 这三个参数是本 fork 修过的（上游曾导致刷新卡住），
    // 出问题时从日志能直接看出取的哪一段
    DiagLog.log(
      'rcmd.fetch',
      '首页推荐拉取 idx=$cursor flush=$_flush pull=$_isRefresh',
      repeatEvery: 20,
    );
    return VideoHttp.rcmdVideoListApp(
      idx: cursor,
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
            DiagLog.log(
              'rcmd.append',
              '刷新保留旧数据：旧列表 ${response.length} 条（>200）→ 逐元素补 '
              '50 条，规避 Iterable addAll 的集合类型检查异常',
            );
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
    DiagLog.log(
      'rcmd.result',
      '首页推荐返回 ${dataList.length} 条（flush=$_flush，'
      '刷新=${_isRefresh ? '是' : '否'}）',
      repeatEvery: 20,
    );
  }

  @override
  Future<void> onRefresh() {
    page = 0;
    isEnd = false;
    _flush = 0;
    return queryData();
  }
}
