import 'dart:convert';

import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/http/init.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/login.dart';
import 'package:PiliPlus/models/common/account_type.dart';
import 'package:PiliPlus/models_new/recommend_label/recommend_label.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:dio/dio.dart';

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
    Utils.reportError('[DIAG] uinterest failed: ${res.data}');
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

  /// 写：提交修改。
  /// [fixedLabel] 固定标签（服务端标记 is_fixed，不可移除，但提交时仍要带上）
  /// [unfixedLabel] 自选标签全集（提交后的最终状态，不是增量）
  /// [action] 官方为 int：1=保存修改，2=恢复默认（实测校准）
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
        'fixed_label': jsonEncode(fixedLabel),
        'unfixed_label': jsonEncode(unfixedLabel),
        'changed_label': ?changedLabel,
        'action': action,
      },
      options: _options.copyWith(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
    if (res.data is Map && res.data['code'] == 0) {
      return const Success(null);
    }
    final msg = res.data is Map ? res.data['message'] : res.toString();
    // action 的取值是逆向推断的（1=保存 / 2=恢复默认），提交失败时把
    // 请求与响应一并记进可导出日志，便于真机校准
    Utils.reportError(
      '[DIAG] managerLabel failed action=$action '
      'fixed=$fixedLabel unfixed=$unfixedLabel resp=${res.data}',
    );
    return Error(msg ?? '提交失败');
  }
}
