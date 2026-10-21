import 'package:PiliPlus/http/video.dart';
import 'package:flutter_test/flutter_test.dart';

/// 「不感兴趣」参数构造的回归测试。
///
/// 背景（详见 docs/regression-checklist.md 陷阱 11）：
/// - 官方 `pegasus/api/D.java` 的 `b(...)` 里，`mid`/`rid`/`tag_id` 只在
///   `> 0` 时下发；`old_pegasus=1` 是必带项。
/// - 实测传对了 `reason_id`（UP主级=4）时，后续 3200 条曝光中该 UP 出现 0 次；
///   不传理由时抑制率仅 22%（噪声范围）→ `reason_id` 决定反馈是否真的生效。
void main() {
  group('buildFeedDislikeParams', () {
    test('基本字段：goto / id / old_pegasus / spmid', () {
      final p = VideoHttp.buildFeedDislikeParams(
        goto: 'av',
        id: 117380936177017,
        reasonId: 4,
      );
      expect(p['goto'], 'av');
      expect(p['id'], 117380936177017);
      // 官方必带，缺了接口仍返回 code=0 但反馈不生效
      expect(p['old_pegasus'], '1');
      expect(p['spmid'], 'tm.recommend.0.0');
      expect(p['from_spmid'], 'tm.recommend.0.0');
      expect(p['is_light_panel'], 'false');
      expect(p['mobi_app'], 'android');
      expect(p['build'], 1);
    });

    test('reason_id 与 feedback_id 都透传', () {
      final p = VideoHttp.buildFeedDislikeParams(
        goto: 'av',
        id: 1,
        reasonId: 4,
      );
      expect(p['reason_id'], 4);
      expect(p.containsKey('feedback_id'), isFalse,
          reason: '没传 feedback_id 就不该出现空值键');

      final p2 = VideoHttp.buildFeedDislikeParams(
        goto: 'av',
        id: 1,
        feedbackId: 7,
      );
      expect(p2['feedback_id'], 7);
      expect(p2.containsKey('reason_id'), isFalse);
    });

    test('mid / rid / tag_id 为 0 或 null 时不下发（对齐官方 > 0 才带）', () {
      final zero = VideoHttp.buildFeedDislikeParams(
        goto: 'av',
        id: 1,
        reasonId: 4,
        mid: 0,
        rid: 0,
        tagId: 0,
      );
      for (final k in ['mid', 'rid', 'tag_id']) {
        expect(zero.containsKey(k), isFalse,
            reason: '$k 为 0 时不应下发，官方是 > 0 才带');
      }

      final nulls = VideoHttp.buildFeedDislikeParams(
        goto: 'av',
        id: 1,
        reasonId: 4,
      );
      for (final k in ['mid', 'rid', 'tag_id']) {
        expect(nulls.containsKey(k), isFalse);
      }

      final positive = VideoHttp.buildFeedDislikeParams(
        goto: 'av',
        id: 1,
        reasonId: 4,
        mid: 1696279451,
        rid: 117380936177017,
        tagId: 648168,
      );
      expect(positive['mid'], 1696279451);
      expect(positive['rid'], 117380936177017);
      expect(positive['tag_id'], 648168);
    });

    test('空的 trackId / reportData 不下发', () {
      final p = VideoHttp.buildFeedDislikeParams(
        goto: 'av',
        id: 1,
        reasonId: 4,
        trackId: '',
        reportData: '',
      );
      expect(p.containsKey('track_id'), isFalse);
      expect(p.containsKey('report_data'), isFalse);

      final filled = VideoHttp.buildFeedDislikeParams(
        goto: 'av',
        id: 1,
        reasonId: 4,
        trackId: 'abc',
        reportData: '{"x":1}',
      );
      expect(filled['track_id'], 'abc');
      expect(filled['report_data'], '{"x":1}');
    });

    test('不下发 access_key —— 交给 AccountManager 拦截器统一处理', () {
      // 这是 P2 修复的核心：业务层不再自己拼 access_key，
      // 也不再因缺少 access_key 而拒绝提交。
      final p = VideoHttp.buildFeedDislikeParams(
        goto: 'av',
        id: 1,
        reasonId: 4,
      );
      expect(p.containsKey('access_key'), isFalse);
      expect(p.containsKey('appkey'), isFalse);
      expect(p.containsKey('sign'), isFalse);
      expect(p.containsKey('ts'), isFalse);
    });
  });
}
