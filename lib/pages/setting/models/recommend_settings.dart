import 'package:PiliPlus/common/widgets/custom_icon.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/pages/rcmd/controller.dart';
import 'package:PiliPlus/pages/recommend_label/view.dart';
import 'package:PiliPlus/pages/setting/models/model.dart';
import 'package:PiliPlus/utils/login_utils.dart';
import 'package:PiliPlus/utils/recommend_filter.dart';
import 'package:PiliPlus/utils/rcmd_resort.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

List<SettingsModel> get recommendSettings => [
  NormalModel(
    title: 'buvid',
    leading: const Icon(CustomIcons.identifier_circle),
    getSubtitle: () => LoginUtils.buvid,
    onTap: _showBuvidDialog,
  ),
  const SwitchModel(
    title: '首页使用app端推荐',
    subtitle: '若web端推荐不太符合预期，可尝试切换至app端推荐',
    leading: Icon(Icons.model_training_outlined),
    setKey: SettingBoxKey.appRcmd,
    defaultVal: true,
    needReboot: true,
  ),
  SwitchModel(
    title: '保留首页推荐刷新',
    subtitle: '下拉刷新时保留上次内容',
    leading: const Icon(Icons.refresh),
    setKey: SettingBoxKey.enableSaveLastData,
    defaultVal: true,
    onChanged: (value) {
      try {
        Get.find<RcmdController>()
          ..enableSaveLastData = value
          ..lastRefreshAt = null;
      } catch (e) {
        if (kDebugMode) debugPrint('$e');
      }
    },
  ),
  SwitchModel(
    title: '显示上次看到位置提示',
    subtitle: '保留上次推荐时，在上次刷新位置显示提示',
    leading: const Icon(Icons.tips_and_updates_outlined),
    setKey: SettingBoxKey.savedRcmdTip,
    defaultVal: true,
    onChanged: (value) {
      try {
        Get.find<RcmdController>()
          ..savedRcmdTip = value
          ..lastRefreshAt = null;
      } catch (e) {
        if (kDebugMode) debugPrint('$e');
      }
    },
  ),
  NormalModel(
    title: '内容偏好调节',
    subtitle: '管理首页推荐的内容偏好标签，与官方账号互通',
    leading: const Icon(Icons.interests_outlined),
    onTap: (_, _) => Get.to(const RecommendLabelPage()),
  ),
  getVideoFilterSelectModel(
    title: '点赞率',
    suffix: '%',
    key: SettingBoxKey.minLikeRatioForRecommend,
    values: [0, 1, 2, 3, 4],
    onChanged: (value) => RecommendFilter.minLikeRatioForRecommend = value,
    filterScope: 'Web推荐、热门、分区',
  ),
  getBanWordModel(
    title: '标题关键词过滤',
    key: SettingBoxKey.banWordForRecommend,
    onChanged: (value) {
      RecommendFilter.rcmdRegExp = value;
      RecommendFilter.enableFilter = value.pattern.isNotEmpty;
    },
    banScope: '推荐、热门、分区、相关视频',
  ),
  getBanWordModel(
    title: '分区关键词过滤',
    key: SettingBoxKey.banWordForZone,
    onChanged: (value) {
      VideoHttp.zoneRegExp = value;
      VideoHttp.enableFilter = value.pattern.isNotEmpty;
    },
    banScope: 'App推荐、热门、分区',
  ),
  getVideoFilterSelectModel(
    title: '视频时长',
    suffix: 's',
    key: SettingBoxKey.minDurationForRcmd,
    values: [0, 30, 60, 90, 120],
    onChanged: (value) => RecommendFilter.minDurationForRcmd = value,
    filterScope: '推荐、相关视频',
  ),
  getVideoFilterSelectModel(
    title: '播放量',
    key: SettingBoxKey.minPlayForRcmd,
    values: [0, 50, 100, 500, 1000],
    onChanged: (value) => RecommendFilter.minPlayForRcmd = value,
    filterScope: '推荐、热门、分区、相关视频',
  ),
  SwitchModel(
    title: '已关注UP豁免推荐过滤',
    subtitle: '推荐中已关注用户发布的内容不会被过滤',
    leading: const Icon(Icons.favorite_border_outlined),
    setKey: SettingBoxKey.exemptFilterForFollowed,
    defaultVal: true,
    onChanged: (value) => RecommendFilter.exemptFilterForFollowed = value,
  ),
  SwitchModel(
    title: '推荐重排',
    subtitle: '把已关注的UP、没看过的内容往前排，已看完的往后排。'
        '服务端首页主要是热门池，这一步用本地已有信号重新排序；'
        '只调整顺序，不删内容',
    leading: const Icon(Icons.swap_vert),
    setKey: SettingBoxKey.rcmdResort,
    defaultVal: false,
    onChanged: (value) => RcmdResort.enabled = value,
  ),
  SwitchModel(
    title: '过滤器也应用于详情页相关视频',
    subtitle: '其它（如热门视频、搜索等）均不受过滤器影响，无法豁免相关视频中的已关注UP',
    leading: const Icon(Icons.explore_outlined),
    setKey: SettingBoxKey.applyFilterToRelatedVideos,
    defaultVal: true,
    onChanged: (value) => RecommendFilter.applyFilterToRelatedVideos = value,
  ),
];

void _showBuvidDialog(BuildContext context, VoidCallback setState) {
  String buvid = LoginUtils.buvid;
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('buvid'),
      content: TextFormField(
        autofocus: true,
        initialValue: buvid,
        onChanged: (value) => buvid = value,
        inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r"\s"))],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Get.back();
            Pref.buvid = LoginUtils.buvid = LoginUtils.generateBuvid();
            setState();
          },
          child: const Text('随机'),
        ),
        TextButton(
          onPressed: Get.back,
          child: Text(
            '取消',
            style: TextStyle(color: ColorScheme.of(context).outline),
          ),
        ),
        TextButton(
          onPressed: () {
            Get.back();
            if (buvid.isEmpty) return;
            Pref.buvid = LoginUtils.buvid = buvid;
            setState();
          },
          child: const Text('确定'),
        ),
      ],
    ),
  );
}
