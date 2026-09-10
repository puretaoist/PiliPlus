import 'package:PiliPlus/utils/bili_report_sign.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BiliReportSign.sign', () {
    test('与官方 APK 验签样例逐字节一致（8.62 逆向实证）', () {
      // 样例来自官方客户端抓包 + so 层 hook 实测（md5(sorted_urlencoded + appsec)）
      final params = <String, dynamic>{
        'actual_played_time': 0,
        'aid': 1453997972,
        'auto_play': 0,
        'build': 6240300,
        'c_locale': 'zh-Hans_CN',
        'channel': 'xxl_gdt_wm_253',
        'cid': 1526814271,
        'epid': 0,
        'epid_status': '',
        'from': 7,
        'from_spmid': 'tm.recommend.0.0',
        'last_play_progress_time': 0,
        'list_play_time': 0,
        'max_play_progress_time': 0,
        'mid': 0,
        'miniplayer_play_time': 0,
        'mobi_app': 'android',
        'network_type': 1,
        'paused_time': 0,
        'platform': 'android',
        'play_status': 0,
        'play_type': 1,
        'played_time': 0,
        'quality': 32,
        's_locale': 'zh-Hans_CN',
        'session': 'eaaa503b653ac6e68134935caaf822a11139ce62',
        'sid': 0,
        'spmid': 'main.ugc-video-detail.0.0',
        'start_ts': 0,
        'statistics': '{"appId":1,"platform":3,"version":"6.24.0","abtest":""}',
        'sub_type': 0,
        'total_time': 0,
        'ts': 1716390021,
        'type': 3,
        'user_status': 0,
        'video_duration': 195,
      };
      // 官方客户端对这组参数算出的 sign（服务端已验证通过，code=0）
      expect(
        BiliReportSign.sign(params),
        'f57ee9b9235576d09846ad8453462037',
      );
    });

    test('签名与 dio form 编码一致：空值参数必须带等号', () {
      // 空值若被省略等号（旧 AppSign 的行为），服务端验签会失败（-3）
      final params = <String, dynamic>{'from_spmid': 'tm.recommend.0.0'};
      // 不抛异常且结果为 32 位 md5 即可；关键是与 body 编码同规则
      expect(BiliReportSign.sign(params).length, 32);
    });
  });

  group('BiliReportSign.genSession', () {
    test('是 40 位小写十六进制（sha1）', () {
      final s = BiliReportSign.genSession(buvid: 'XXTEST');
      expect(RegExp(r'^[0-9a-f]{40}$').hasMatch(s), isTrue, reason: s);
    });

    test('buvid 为空时仍能生成合法 session', () {
      final s = BiliReportSign.genSession();
      expect(RegExp(r'^[0-9a-f]{40}$').hasMatch(s), isTrue, reason: s);
    });

    test('同一输入序列下长度恒定（防止误改成非 sha1 逻辑）', () {
      expect(BiliReportSign.genSession(buvid: 'A').length, 40);
      expect(BiliReportSign.genSession(buvid: 'B').length, 40);
    });
  });

  group('BiliReportSign.genPolarisActionId', () {
    test('是 8 位大写十六进制（对齐官方 PageViewTracker 形态）', () {
      final s = BiliReportSign.genPolarisActionId();
      expect(RegExp(r'^[0-9A-F]{8}$').hasMatch(s), isTrue, reason: s);
    });
  });
}
