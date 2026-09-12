import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/http/init.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/login.dart';
import 'package:PiliPlus/models/common/account_type.dart';
import 'package:PiliPlus/models_new/recommend_label/recommend_label.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/diag_log.dart';
import 'package:dio/dio.dart';

/// mng 接口的 action 取值。
///
/// 逆向自官方 APK 8.62：
/// `com.bilibili.pegasus.recommendlabel.l0#c(list, list, str, int, ...)`
/// → `RecommendLabelApiService.managerRecommendLabel(fixed, unfixed, changed, action)`
///
/// 官方客户端每次只改一个标签，提交的是**变更后的全量快照**：
/// - `fixed_label`   = 变更后 is_fixed==1 的标签名（l0 里 `g0.a`，由 `labels` 过滤得到）
/// - `unfixed_label` = 变更后 is_fixed==0 的标签名（l0 里 `g0.b`）
/// - `changed_label` = 本次改动的标签名（批量时是多个名字）
///
/// | action | 语义 | fixed_label | unfixed_label | changed_label |
/// |---|---|---|---|---|
/// | 1 | 取消固定（降级为自选） | 去掉该标签 | 加上该标签 | 该标签名 |
/// | 2 | 删除固定标签 | 去掉该标签 | 不变 | 该标签名 |
/// | 3 | 删除自选标签 | 不变 | 去掉该标签 | 该标签名 |
/// | 4 | 自选升为固定 | 加上该标签 | 去掉该标签 | 该标签名 |
/// | 5 | 新增单个标签 | 新标签 + 原 fixed | 不变 | 该标签名 |
/// | 6 | 恢复默认 | 空 | 空 | 不传 |
/// | 7 | 批量新增 | 勾选标签 + 原 fixed | 不变 | 勾选名逗号拼接 |
abstract final class RecLabelAction {
  static const int cancelFixed = 1;
  static const int deleteFixed = 2;
  static const int deleteUnfixed = 3;
  static const int fixUnfixed = 4;
  static const int addLabel = 5;
  static const int resetDefault = 6;
  static const int batchAdd = 7;
}

/// 官方「内容偏好调节」接口
/// 逆向自官方客户端 tv.danmaku.bili 的 RecommendLabelApiService（2026-09）
abstract final class RecommendLabelHttp {
  static const String _base = 'https://app.bilibili.com';

  /// app 公参，对齐官方手机版 profile（bbspace 同规格，无需 sign）
  static Map<String, dynamic> _commonParams() {
    final accessKey = Accounts.get(AccountType.main).accessKey;
    return {
      'build': 8620300,
      'c_locale': 'zh_CN',
      'channel': 'master',
      'disable_rcmd': 0,
      'mobi_app': 'android',
      'platform': 'android',
      's_locale': 'zh_CN',
      'ts': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'access_key': ?accessKey,
    };
  }

  static Options get _options => Options(
    headers: {
      'buvid': LoginHttp.buvid,
      'env': 'prod',
      'app-key': 'android',
      'user-agent': Constants.userAgentApp,
      'x-bili-trace-id': Constants.traceId,
      'bili-http-engine': 'cronet',
    },
  );

  static LoadingState<T> _parse<T>(
    Response res,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (res.data is Map && res.data['code'] == 0) {
      if (res.data['data'] is Map) {
        return Success(fromJson(res.data['data']));
      }
      return Success(fromJson(const {}));
    }
    final msg = res.data is Map ? res.data['message'] : res.toString();
    DiagLog.log('uinterest.fail', 'uinterest 读取失败: ${res.data}');
    return Error(msg ?? '请求失败');
  }

  /// 读：我的偏好标签 + 全部可选标签 + 近期偏好分布
  static Future<LoadingState<RecommendLabelResponse>> uinterest() async {
    final res = await Request().get(
      '$_base/x/v2/feed/uinterest',
      queryParameters: {..._commonParams(), 'need_all_label': 1},
      options: _options,
    );
    return _parse(res, RecommendLabelResponse.fromJson);
  }

  /// 读：更多可选标签（编辑页"添加标签"用）
  static Future<LoadingState<RecLabelMoreResponse>> uinterestMore() async {
    final res = await Request().get(
      '$_base/x/v2/feed/uinterest/more',
      queryParameters: _commonParams(),
      options: _options,
    );
    return _parse(res, RecLabelMoreResponse.fromJson);
  }

  /// 组装 mng 的表单字段（独立出来便于单元测试守护字段编码，
  /// 见 test/http/recommend_label_test.dart）
  ///
  /// 关键：`fixed_label` / `unfixed_label` 是**标签名用 "," 拼接的字符串**，
  /// 与官方 Kotlin 侧的 `Jt0.b.a(List<String>)` 一致；早期实现发的是
  /// `jsonEncode(list)`（`["a","b"]`），服务端会把它当成一个标签名，
  /// 于是"提交成功但偏好没变"。
  static Map<String, dynamic> buildMngBody({
    required List<String> fixedLabel,
    required List<String> unfixedLabel,
    String? changedLabel,
    required int action,
  }) => {
    'fixed_label': fixedLabel.join(','),
    'unfixed_label': unfixedLabel.join(','),
    // action 6（恢复默认）不传 changed_label
    if (changedLabel != null && changedLabel.isNotEmpty)
      'changed_label': changedLabel,
    'action': action,
  };

  /// 写：提交偏好标签修改。
  ///
  /// [fixedLabel] 变更后 is_fixed==1 的标签名快照
  /// [unfixedLabel] 变更后 is_fixed==0 的标签名快照
  /// [changedLabel] 本次改动的标签名（action 7 时为多个名字）
  /// [action] 见 [RecLabelAction]
  static Future<LoadingState<void>> managerLabel({
    required List<String> fixedLabel,
    required List<String> unfixedLabel,
    String? changedLabel,
    required int action,
  }) async {
    final res = await Request().post(
      '$_base/x/v2/feed/uinterest/mng',
      data: {
        ..._commonParams(),
        ...buildMngBody(
          fixedLabel: fixedLabel,
          unfixedLabel: unfixedLabel,
          changedLabel: changedLabel,
          action: action,
        ),
      },
      options: _options.copyWith(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
    if (res.data is Map && res.data['code'] == 0) {
      // 内容偏好是用户手动操作触发的低频写，成功也记一条：
      // 出现"提交成功但偏好没变"时，能对照日志确认服务端确实收下了
      DiagLog.always(
        'uinterest/mng ok action=$action fixed=${fixedLabel.join(',')} '
        'unfixed=${unfixedLabel.join(',')} changed=${changedLabel ?? '-'}',
      );
      return const Success(null);
    }
    final msg = res.data is Map ? res.data['message'] : res.toString();
    // 提交失败时把请求与响应一并记进可导出日志，便于真机校准
    DiagLog.always(
      'uinterest/mng failed action=$action '
      'fixed=${fixedLabel.join(',')} unfixed=${unfixedLabel.join(',')} '
      'changed=$changedLabel resp=${res.data}',
    );
    return Error(msg ?? '提交失败');
  }
}
