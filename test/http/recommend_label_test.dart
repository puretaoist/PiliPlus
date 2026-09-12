import 'package:PiliPlus/http/recommend_label.dart';
import 'package:PiliPlus/models_new/recommend_label/recommend_label.dart';
import 'package:flutter_test/flutter_test.dart';

/// 守护 mng 接口的字段编码与 action 取值。
///
/// 契约来自官方 APK 8.62 反编译：
/// - `com.bilibili.pegasus.recommendlabel.l0#c` 里 7 个调用点决定 action 语义
/// - `Jt0.b.a(List<String>)` 把标签名用 "," 拼接（不是 JSON 数组）
void main() {
  group('RecommendLabelHttp.buildMngBody', () {
    test('标签名用逗号拼接，不是 JSON 数组', () {
      final body = RecommendLabelHttp.buildMngBody(
        fixedLabel: const ['动画', '游戏'],
        unfixedLabel: const ['美食'],
        changedLabel: '美食',
        action: RecLabelAction.batchAdd,
      );
      expect(body['fixed_label'], '动画,游戏');
      expect(body['unfixed_label'], '美食');
      expect(body['changed_label'], '美食');
      expect(body['action'], 7);
    });

    test('批量新增：changed_label 是多个名字的逗号拼接', () {
      final body = RecommendLabelHttp.buildMngBody(
        fixedLabel: const ['电影', '动画', '游戏'],
        unfixedLabel: const [],
        changedLabel: '电影,动画',
        action: RecLabelAction.batchAdd,
      );
      expect(body['fixed_label'], '电影,动画,游戏');
      expect(body['changed_label'], '电影,动画');
    });

    test('恢复默认（action 6）：两个列表为空且不带 changed_label', () {
      final body = RecommendLabelHttp.buildMngBody(
        fixedLabel: const [],
        unfixedLabel: const [],
        action: RecLabelAction.resetDefault,
      );
      expect(body.containsKey('changed_label'), isFalse);
      expect(body['fixed_label'], '');
      expect(body['unfixed_label'], '');
      expect(body['action'], 6);
    });

    test('空 changed_label 不下发（服务端按缺失处理，而非空串）', () {
      final body = RecommendLabelHttp.buildMngBody(
        fixedLabel: const ['动画'],
        unfixedLabel: const [],
        changedLabel: '',
        action: RecLabelAction.deleteFixed,
      );
      expect(body.containsKey('changed_label'), isFalse);
      expect(body['action'], 2);
    });
  });

  group('RecLabelAction 取值（对齐官方 l0#c 调用点）', () {
    test('1..7 语义不串位', () {
      expect(RecLabelAction.cancelFixed, 1);
      expect(RecLabelAction.deleteFixed, 2);
      expect(RecLabelAction.deleteUnfixed, 3);
      expect(RecLabelAction.fixUnfixed, 4);
      expect(RecLabelAction.addLabel, 5);
      expect(RecLabelAction.resetDefault, 6);
      expect(RecLabelAction.batchAdd, 7);
    });
  });

  group('服务端字段解析', () {
    test('labels 用 is_fixed 区分固定/自选（1 → isPined）', () {
      final res = RecommendLabelResponse.fromJson({
        'labels': [
          {'name': '动画', 'is_fixed': 1},
          {'name': '美食', 'is_fixed': 0},
          {'name': '游戏'},
        ],
      });
      expect(res.labels.map((e) => e.isPined).toList(), [true, false, false]);
      expect(recLabelNames(res.labels), ['动画', '美食', '游戏']);
    });

    test('恢复默认弹窗文案（back_to_default_window）', () {
      final res = RecommendLabelResponse.fromJson({
        'uinterest_page_material': {
          'back_to_default_button': '恢复默认',
          'back_to_default_window': {
            'title': '恢复默认？',
            'subtitle': '将清空你的偏好标签',
            'cancel_button': '再想想',
            'confirm_button': '恢复',
            'toast': '已恢复默认',
          },
        },
      });
      final window = res.pageMaterial?.backToDefaultWindow;
      expect(window?.title, '恢复默认？');
      expect(window?.cancelButton, '再想想');
      expect(window?.confirmButton, '恢复');
      expect(window?.toast, '已恢复默认');
    });

    test('更多标签响应（labels + title/subtitle/add_button/toast）', () {
      final more = RecLabelMoreResponse.fromJson({
        'labels': ['电竞', '手工'],
        'title': '更多偏好',
        'subtitle': '选中的标签会加进你的偏好',
        'add_button': '添加',
        'toast': '添加成功',
      });
      expect(more.labels, ['电竞', '手工']);
      expect(more.title, '更多偏好');
      expect(more.addButton, '添加');
      expect(more.toast, '添加成功');
    });
  });
}
