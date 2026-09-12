import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/recommend_label.dart';
import 'package:PiliPlus/models/common/account_type.dart';
import 'package:PiliPlus/models_new/recommend_label/recommend_label.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/diag_log.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
// 必须用 material_ui：本 fork 的 MaterialApp 来自 material_ui 包，它注册的是
// material_ui 的 MaterialLocalizations。此前这里 import 的是 package:flutter/material.dart，
// 于是本页的 AppBar/showDialog 去找 flutter 侧的 MaterialLocalizations → 取到 null
// → "Null check operator used on a null value"（真机日志 2026-09-12 21:28/21:30/21:34）
import 'package:material_ui/material_ui.dart';

/// 内容偏好调节（对齐官方客户端的推荐标签管理）
/// 数据来自 /x/v2/feed/uinterest*，与官方账号互通
///
/// 写接口（/x/v2/feed/uinterest/mng）的契约见 [RecLabelAction]：
/// 每次提交"变更后的 fixed/unfixed 全量快照 + 本次改动的标签名 + action"。
/// 官方没有"批量删除"这种 action，所以删除必须逐个提交（action 2/3），
/// 新增则可以用 action 7 批量提交。
class RecommendLabelPage extends StatefulWidget {
  const RecommendLabelPage({super.key});

  @override
  State<RecommendLabelPage> createState() => _RecommendLabelPageState();
}

class _RecommendLabelPageState extends State<RecommendLabelPage> {
  LoadingState<RecommendLabelResponse> _state = LoadingState.loading();
  bool _editing = false;
  bool _submitting = false;

  /// 正在拉取「更多标签」候选池
  bool _moreLoading = false;

  /// 编辑态下"我的标签"的最终集合（含原有的固定/自选标签与新勾选的）
  Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (!Accounts.get(AccountType.main).isLogin) {
      setState(() => _state = const Error('该功能需要登录后使用'));
      return;
    }
    setState(() => _state = LoadingState.loading());
    final res = await RecommendLabelHttp.uinterest();
    if (!mounted) return;
    setState(() => _state = res);
    if (res case Success(:final response)) {
      _selected = recLabelNames(response.labels).toSet();
    } else if (res is Error) {
      DiagLog.log('uinterest.open.fail', '内容偏好页加载失败: ${res.errMsg}');
    }
  }

  int get _maxCount =>
      _state.dataOrNull?.mngPageMaterial?.editMaxLabelsCount ?? 0;

  /// 编辑态展示的"我的标签"顺序：原顺序在前，新勾选的（全部分区 / 更多标签）
  /// 按勾选顺序补在后面。`_selected` 是 LinkedHashSet，插入序即展示序。
  List<String> _editingMyNames(RecommendLabelResponse response) {
    final ordered = <String>[
      for (final e in response.labels)
        if (e.name != null && _selected.contains(e.name)) e.name!,
    ];
    for (final n in _selected) {
      if (!ordered.contains(n)) ordered.add(n);
    }
    return ordered;
  }

  /// 「更多标签」：拉 /x/v2/feed/uinterest/more 的候选池（官方把它挂在
  /// `uinterest_page_material.more_interest_button` 上）。
  ///
  /// 官方行为（l0#c 的 `InterfaceC1910h.d` 分支）：
  /// - 候选标签**默认全部勾选**（`C1911i(name, true)`）
  /// - 一个都没勾时按钮置灰；点了就 action 7 批量提交（fixed = 勾选 + 原 fixed），
  ///   然后弹服务端下发的 toast 并收起弹窗
  /// - 候选为空时 toast 服务端文案，没有就 "没有更多啦"
  ///
  /// 本页是"编辑态暂存、点完成统一下发"的交互，所以这里只把勾选的并进编辑集，
  /// 真正的 action 7 请求仍由 [_save] 发出（提交内容与官方一致）。
  Future<void> _openMore() async {
    if (_moreLoading || _submitting) return;
    setState(() => _moreLoading = true);
    final res = await RecommendLabelHttp.uinterestMore();
    if (!mounted) return;
    setState(() => _moreLoading = false);
    if (res is! Success<RecLabelMoreResponse>) {
      res.toast();
      return;
    }
    final more = res.response;
    if (more.labels.isEmpty) {
      SmartDialog.showToast(
        more.subtitle?.isNotEmpty == true ? more.subtitle! : '没有更多啦',
      );
      return;
    }
    final checked = more.labels.where((e) => e.isNotEmpty).toSet();
    final confirmed = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (more.title?.isNotEmpty == true)
                  Text(
                    more.title!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (more.subtitle?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      more.subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: more.labels
                          .map(
                            (name) => FilterChip(
                              selected: checked.contains(name),
                              onSelected: (_) => setSheetState(() {
                                if (!checked.add(name)) checked.remove(name);
                              }),
                              label: Text(name),
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: checked.isEmpty
                        ? null
                        : () => Navigator.of(context).pop(checked),
                    child: Text(
                      more.addButton?.isNotEmpty == true ? more.addButton! : '添加',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (confirmed == null || confirmed.isEmpty || !mounted) return;
    final toAdd = confirmed.where((n) => !_selected.contains(n)).toList();
    // -1 表示服务端没下发上限
    final room = _maxCount > 0
        ? (_maxCount - _selected.length).clamp(0, _maxCount)
        : -1;
    final clipped = room >= 0 && toAdd.length > room
        ? toAdd.sublist(0, room)
        : toAdd;
    if (clipped.length < toAdd.length) {
      SmartDialog.showToast('最多选择 $_maxCount 个标签');
    }
    if (clipped.isEmpty) return;
    setState(() => _selected.addAll(clipped));
  }

  /// 提交编辑：先删后加。
  ///
  /// 官方 mng 接口每次只处理"一个动作 + 变更后快照"，因此：
  /// - 删除：逐个提交，固定标签走 action 2、自选标签走 action 3
  /// - 新增：一次 action 7 批量提交（官方 uinterest/more 页勾选后就是这么提交的）
  Future<void> _save() async {
    if (_submitting) return;
    final response = _state.dataOrNull;
    if (response == null) return;
    setState(() => _submitting = true);

    final fixed = <String>[
      for (final e in response.labels)
        if (e.isPined && e.name != null) e.name!,
    ];
    final unfixed = <String>[
      for (final e in response.labels)
        if (!e.isPined && e.name != null) e.name!,
    ];
    final before = {...fixed, ...unfixed};

    final removed = before.where((n) => !_selected.contains(n)).toList();
    final added = _selected.where((n) => !before.contains(n)).toList();

    // 1) 删除：官方无批量删除，逐个提交（每次带上删除后的快照）
    for (final name in removed) {
      final isFixedLabel = fixed.contains(name);
      final action = isFixedLabel
          ? RecLabelAction.deleteFixed
          : RecLabelAction.deleteUnfixed;
      if (isFixedLabel) {
        fixed.remove(name);
      } else {
        unfixed.remove(name);
      }
      final res = await RecommendLabelHttp.managerLabel(
        fixedLabel: fixed,
        unfixedLabel: unfixed,
        changedLabel: name,
        action: action,
      );
      if (res is! Success) {
        if (!mounted) return;
        setState(() => _submitting = false);
        res.toast();
        _fetch();
        return;
      }
    }

    // 2) 新增：action 7 批量提交。官方把新增标签以 is_fixed=1 写进 fixed_label，
    //    changed_label 是本次勾选名字的逗号拼接
    if (added.isNotEmpty) {
      final res = await RecommendLabelHttp.managerLabel(
        fixedLabel: [...added, ...fixed],
        unfixedLabel: unfixed,
        changedLabel: added.join(','),
        action: RecLabelAction.batchAdd,
      );
      if (res is! Success) {
        if (!mounted) return;
        setState(() => _submitting = false);
        res.toast();
        _fetch();
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _editing = false;
    });
    SmartDialog.showToast('已保存');
    _fetch();
  }

  Future<void> _backToDefault() async {
    final material = _state.dataOrNull?.pageMaterial;
    final window = material?.backToDefaultWindow;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(window?.title ?? material?.backToDefaultButton ?? '恢复默认'),
        content: Text(
          window?.subtitle ?? material?.noteText ?? '将清除当前的内容偏好标签，确定恢复默认？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(window?.cancelButton ?? '取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(window?.confirmButton ?? '确定'),
          ),
        ],
      ),
    );
    if (confirmed != true || _submitting) return;
    setState(() => _submitting = true);
    // action 6 = 恢复默认：fixed/unfixed 都提交为空、且不传 changed_label
    final res = await RecommendLabelHttp.managerLabel(
      fixedLabel: const [],
      unfixedLabel: const [],
      action: RecLabelAction.resetDefault,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res is Success) {
      SmartDialog.showToast(window?.toast ?? '已恢复默认');
      _fetch();
    } else {
      res.toast();
    }
  }

  void _toggle(String name) {
    if (_maxCount > 0 &&
        !_selected.contains(name) &&
        _selected.length >= _maxCount) {
      SmartDialog.showToast('最多选择 $_maxCount 个标签');
      return;
    }
    setState(() {
      if (!_selected.add(name)) {
        _selected.remove(name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('内容偏好调节')),
      body: switch (_state) {
        Loading() => const Center(child: CircularProgressIndicator()),
        Error(:final errMsg) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(errMsg ?? '加载失败'),
              TextButton(onPressed: _fetch, child: const Text('重试')),
            ],
          ),
        ),
        Success(:final response) => _buildBody(response, colorScheme),
      },
    );
  }

  Widget _buildBody(
    RecommendLabelResponse response,
    ColorScheme colorScheme,
  ) {
    final material = response.pageMaterial;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        if (_editing) ..._buildEdit(response, colorScheme)
        else ...[
          if (material?.subtitle?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                material!.subtitle!,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          _sectionTitle(material?.myInterestTitle ?? '我的内容偏好'),
          _buildMyLabels(response),
          Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: () => setState(() {
                  _selected = recLabelNames(response.labels).toSet();
                  _editing = true;
                }),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(material?.editButtonText ?? '编辑'),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: _submitting ? null : _backToDefault,
                icon: const Icon(Icons.restart_alt, size: 18),
                label: Text(material?.backToDefaultButton ?? '恢复默认'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (material?.noteText?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                material!.noteText!,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (response.distributionMaterial
              case final RecLabelDistributionMaterial dist when dist.areaList.isNotEmpty)
            _buildDistribution(dist, colorScheme),
        ],
      ],
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 8),
    child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
  );

  Widget _buildMyLabels(RecommendLabelResponse response) {
    if (response.labels.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('暂无偏好标签'),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: response.labels
            .map(
              (e) => Chip(
                avatar: e.isPined
                    ? const Icon(Icons.push_pin, size: 14)
                    : null,
                label: Text(e.name ?? ''),
                visualDensity: VisualDensity.compact,
              ),
            )
            .toList(),
      ),
    );
  }

  List<Widget> _buildEdit(
    RecommendLabelResponse response,
    ColorScheme colorScheme,
  ) {
    final material = response.mngPageMaterial;
    final myNames = _editingMyNames(response);
    return [
      Row(
        children: [
          Expanded(
            child: Text(
              material?.editTitle ?? '编辑内容偏好',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          if (_maxCount > 0)
            Text(
              '${_selected.length} / $_maxCount',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
        ],
      ),
      const SizedBox(height: 8),
      _sectionTitle(material?.editMyGroupTitle ?? '我的标签'),
      if (material?.editMyGroupSubtitle?.isNotEmpty == true)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            material!.editMyGroupSubtitle!,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      if (myNames.isEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            '还没有选择任何标签',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        )
      else
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: myNames
              .map(
                (name) => FilterChip(
                  selected: true,
                  // 取消勾选 = 提交时删除该标签（官方编辑页允许删掉固定标签）
                  onSelected: (_) => _toggle(name),
                  label: Text(name),
                  visualDensity: VisualDensity.compact,
                ),
              )
              .toList(),
        ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _sectionTitle(material?.editAddGroupTitle ?? '全部偏好'),
          ),
          // 官方把「更多标签」的入口文案挂在 uinterest_page_material 上
          if (response.pageMaterial?.moreInterestButton?.isNotEmpty == true)
            TextButton.icon(
              onPressed: _moreLoading || _submitting ? null : _openMore,
              icon: _moreLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_circle_outline, size: 18),
              label: Text(response.pageMaterial!.moreInterestButton!),
            ),
        ],
      ),
      ...response.allLabels.map(
        (area) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (area.areaName?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 6),
                child: Text(
                  area.areaName!,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: area.areaLabel
                  .map(
                    (name) => FilterChip(
                      selected: _selected.contains(name),
                      onSelected: (_) => _toggle(name),
                      label: Text(name),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _submitting
                  ? null
                  : () => setState(() => _editing = false),
              child: const Text('取消'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _submitting ? null : _save,
              child: Text(
                _submitting
                    ? '保存中...'
                    : (material?.editFinishButtonText ?? '完成'),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
    ];
  }

  /// 服务端下发的 #RRGGBB 色值，解析失败时给一个可见的兜底色
  Color _parseColor(String? hex) {
    var value = (hex ?? '').replaceFirst('#', '');
    if (value.length == 6) {
      value = 'FF$value';
    }
    return Color(int.tryParse(value, radix: 16) ?? 0xFF2196F3);
  }

  Widget _buildDistribution(
    RecLabelDistributionMaterial dist,
    ColorScheme colorScheme,
  ) {
    final maxCount = dist.areaList
        .map((e) => e.count)
        .fold<int>(1, (a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(dist.title ?? '近期偏好分布'),
        if (dist.subtitle?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              dist.subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ...dist.areaList.map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Text(
                    item.name ?? '',
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: maxCount == 0 ? 0 : item.count / maxCount,
                      minHeight: 10,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      color: _parseColor(item.color),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 36,
                  child: Text(
                    '${item.count}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '该分布由 B 站服务端根据你的观看行为生成，修改偏好标签后需要一段时间生效',
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
