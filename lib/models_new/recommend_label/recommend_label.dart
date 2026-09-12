/// 官方「内容偏好调节」数据模型
/// 接口（逆向自官方客户端 RecommendLabelApiService）：
/// GET  https://app.bilibili.com/x/v2/feed/uinterest
/// GET  https://app.bilibili.com/x/v2/feed/uinterest/more
/// POST https://app.bilibili.com/x/v2/feed/uinterest/mng

class RecommendLabelResponse {
  final List<RecLabel> labels;
  final List<RecLabelArea> allLabels;
  final RecLabelPageMaterial? pageMaterial;
  final RecLabelMngPageMaterial? mngPageMaterial;
  final RecLabelDistributionMaterial? distributionMaterial;

  RecommendLabelResponse.fromJson(Map<String, dynamic> json)
    : labels = (json['labels'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => RecLabel.fromJson(e.cast<String, dynamic>()))
          .toList(),
      allLabels = (json['all_labels'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => RecLabelArea.fromJson(e.cast<String, dynamic>()))
          .toList(),
      pageMaterial = json['uinterest_page_material'] is Map
          ? RecLabelPageMaterial.fromJson(
              (json['uinterest_page_material'] as Map).cast<String, dynamic>(),
            )
          : null,
      mngPageMaterial = json['uinterest_mng_page_material'] is Map
          ? RecLabelMngPageMaterial.fromJson(
              (json['uinterest_mng_page_material'] as Map)
                  .cast<String, dynamic>(),
            )
          : null,
      distributionMaterial = json['uinterest_distribution_material'] is Map
          ? RecLabelDistributionMaterial.fromJson(
              (json['uinterest_distribution_material'] as Map)
                  .cast<String, dynamic>(),
            )
          : null;
}

/// 单个偏好标签；标签以字符串名（name）为唯一凭据，读写都传 name
class RecLabel {
  final String? name;
  final String? icon;
  final int isFixed;
  final String? areaName;

  bool get isPined => isFixed == 1;

  RecLabel.fromJson(Map<String, dynamic> json)
    : name = json['name'],
      icon = json['icon'],
      isFixed = json['is_fixed'] ?? 0,
      areaName = json['area_name'];
}

/// 按分区分组的全部可选标签
class RecLabelArea {
  final String? areaIcon;
  final String? areaName;
  final List<String> areaLabel;

  RecLabelArea.fromJson(Map<String, dynamic> json)
    : areaIcon = json['area_icon'],
      areaName = json['area_name'],
      areaLabel = (json['area_label'] as List? ?? const [])
          .map((e) => e.toString())
          .toList();
}

/// 偏好页文案（服务端下发）
class RecLabelPageMaterial {
  final String? title;
  final String? subtitle;
  final String? myInterestTitle;
  final String? editButtonText;
  final String? backToDefaultButton;
  final String? moreInterestButton;
  final String? noteText;

  /// 恢复默认的二次确认弹窗文案（官方 BackToDefaultWindow）
  final RecLabelBackToDefaultWindow? backToDefaultWindow;

  RecLabelPageMaterial.fromJson(Map<String, dynamic> json)
    : title = json['title'],
      subtitle = json['subtitle'],
      myInterestTitle = json['my_interest_title'],
      editButtonText = json['edit_button_text'],
      backToDefaultButton = json['back_to_default_button'],
      moreInterestButton = json['more_interest_button'],
      noteText = json['note_text'],
      backToDefaultWindow = json['back_to_default_window'] is Map
          ? RecLabelBackToDefaultWindow.fromJson(
              (json['back_to_default_window'] as Map).cast<String, dynamic>(),
            )
          : null;
}

/// 恢复默认确认弹窗（官方 data.BackToDefaultWindow）
class RecLabelBackToDefaultWindow {
  final String? title;
  final String? subtitle;
  final String? cancelButton;
  final String? confirmButton;
  final String? toast;

  RecLabelBackToDefaultWindow.fromJson(Map<String, dynamic> json)
    : title = json['title'],
      subtitle = json['subtitle'],
      cancelButton = json['cancel_button'],
      confirmButton = json['confirm_button'],
      toast = json['toast'];
}

/// 编辑页文案
class RecLabelMngPageMaterial {
  final String? editTitle;
  final String? editMyGroupTitle;
  final String? editMyGroupSubtitle;
  final String? editAddGroupTitle;
  final String? editFinishButtonText;
  final int editMaxLabelsCount;

  RecLabelMngPageMaterial.fromJson(Map<String, dynamic> json)
    : editTitle = json['edit_title'],
      editMyGroupTitle = json['edit_my_group_title'],
      editMyGroupSubtitle = json['edit_my_group_subtitle'],
      editAddGroupTitle = json['edit_add_group_title'],
      editFinishButtonText = json['edit_finish_button_text'],
      editMaxLabelsCount = json['edit_max_labels_count'] ?? 0;
}

/// 近期偏好分布（B 站当前认为你喜欢什么）
class RecLabelDistributionMaterial {
  final String? title;
  final String? subtitle;
  final List<RecDistributionArea> areaList;

  RecLabelDistributionMaterial.fromJson(Map<String, dynamic> json)
    : title = json['title'],
      subtitle = json['subtitle'],
      areaList = (json['area_list'] as List? ?? const [])
          .map((e) => RecDistributionArea.fromJson(e))
          .toList();
}

class RecDistributionArea {
  final String? name;
  final String? color;
  final int count;

  RecDistributionArea.fromJson(Map<String, dynamic> json)
    : name = json['name'],
      color = json['color'],
      count = json['count'] ?? 0;
}

/// GET /x/v2/feed/uinterest/more 的响应
/// （官方 data.RecommendLabelMoreResponse：labels/title/subtitle/add_button/toast）
class RecLabelMoreResponse {
  final List<String> labels;
  final String? title;
  final String? subtitle;
  final String? addButton;
  final String? toast;

  RecLabelMoreResponse.fromJson(Map<String, dynamic> json)
    : labels = (json['labels'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
      title = json['title'],
      subtitle = json['subtitle'],
      addButton = json['add_button'],
      toast = json['toast'];
}

/// 从标签集合提取提交参数用的 name 列表
List<String> recLabelNames(Iterable<RecLabel> labels) =>
    labels.map((e) => e.name).whereType<String>().toList();
