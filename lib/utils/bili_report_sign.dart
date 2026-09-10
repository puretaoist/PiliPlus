import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// 归因上报（mobile 心跳 / 播放历史）的签名与会话 ID 生成。
///
/// 算法均来自官方 APK 逆向实证（8.62）+ 官方验签样例复现：
/// - 签名：`md5(sorted(biliUrlEncode(k=v)) + appsec)`，biliUrlEncode 只保留 `-._~`；
///   **appkey 既参与签名，也必须出现在请求体里**（缺失会被服务端判 -400）
/// - session：`sha1(buvid + 毫秒时间戳 + random(0..999999))`，40 位小写 hex
/// - polaris_action_id：8 位大写 hex（页面级随机 ID）
abstract final class BiliReportSign {
  static const String appKeyAndroid = '1d8b6e7d45233436';
  static const String appSecAndroid = '560c52ccd288fed045859ed18bffd973';

  /// 与 dio 的 form 编码（Uri.encodeQueryComponent）保持一致的签名计算。
  /// 注意：appkey 只加入签名副本，调用方须自行把它放进请求体。
  static String sign(
    Map<String, dynamic> params, {
    String appKey = appKeyAndroid,
    String appSec = appSecAndroid,
  }) {
    final m = <String, String>{
      for (final e in params.entries) e.key: e.value?.toString() ?? '',
      'appkey': appKey,
    };
    final keys = m.keys.toList()..sort();
    final q = keys
        .map((k) => '$k=${Uri.encodeQueryComponent(m[k]!)}')
        .join('&');
    return md5.convert(utf8.encode('$q$appSec')).toString();
  }

  static String genSession({String? buvid}) {
    final input =
        '${buvid ?? ''}${DateTime.now().millisecondsSinceEpoch}${_random.nextInt(1000000)}';
    return sha1.convert(utf8.encode(input)).toString();
  }

  static String genPolarisActionId() {
    final value = _random.nextInt(0x7FFFFFFF) ^
        DateTime.now().microsecondsSinceEpoch.hashCode;
    return (value & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0').toUpperCase();
  }

  static final Random _random = Random();
}
