import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/recommend_label.dart';
import 'package:PiliPlus/models/common/account_type.dart';
import 'package:PiliPlus/models_new/recommend_label/recommend_label.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

/// 内容偏好调节（对齐官方客户端的推荐标签管理）
/// 数据来自 /x/v2/feed/uinterest*，与官方账号互通
class RecommendLabelPage extends StatefulWidget {
  const RecommendLabelPage({super.key});

  @override
  State<RecommendLabelPage> createState() => _RecommendLabelPageState();
}

class _RecommendLabelPageState extends State<RecommendLabelPage> {
  LoadingState<RecommendLabelResponse> _state = LoadingState.loading();
  bool _editing = false;
  bool _submitting = false;
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
      _selected = response.labels
          .where((e) => !e.isPined)
          .map((e) => e.name)
          .whereType<String>()
          .toSet();
    }
  }

  List<RecLabel> get _fixedLabels =>
      _state.dataOrNull?.labels.where((e) => e.isPined).toList() ??
      const <RecLabel>[];

  int get _maxCount =>
      _state.dataOrNull?.mngPageMaterial?.editMaxLabelsCount ?? 0;

  Future<void> _save() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final res = await RecommendLabelHttp.managerLabel(
      fixedLabel: recLabelNames(_fixedLabels),
      unfixedLabel: _selected.toList(),
      action: 1,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res is Success) {
      SmartDialog.showToast('已保存');
      setState(() => _editing = false);
      _fetch();
    } else {
      res.toast();
    }
  }

  Future<void> _backToDefault() async {
    final material = _state.dataOrNull?.pageMaterial;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(material?.backToDefaultButton ?? '恢复默认'),
        content: Text(
          material?.noteText ?? '将清除当前的内容偏好标签，确定恢复默认？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (confirmed != true || _submitting) return;
    setState(() => _submitting = true);
    final res = await RecommendLabelHttp.managerLabel(
      fixedLabel: recLabelNames(_fixedLabels),
      unfixedLabel: const [],
      action: 2,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res is Success) {
      SmartDialog.showToast('已恢复默认');
      _fetch();
    } else {
      res.toast();
    }
  }

  void _toggle(String name) {
    if (_fixedLabels.any((e) => e.name == name)) {
      SmartDialog.showToast('固定标签不可移除');
      return;
    }
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
                onPressed: () => setState(() => _editing = true),
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
    final fixedNames = _fixedLabels.map((e) => e.name).toSet();
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
              '${_selected.length + fixedNames.length} / $_maxCount',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
        ],
      ),
      const SizedBox(height: 8),
      if (fixedNames.isNotEmpty) ...[
        _sectionTitle(material?.editMyGroupTitle ?? '固定标签'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: fixedNames
              .map(
                (name) => FilterChip(
                  selected: true,
                  onSelected: (_) => _toggle(name),
                  label: Text(name),
                  visualDensity: VisualDensity.compact,
                ),
              )
              .toList(),
        ),
      ],
      _sectionTitle(material?.editAddGroupTitle ?? '全部偏好'),
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
                      value: item.count / maxCount,
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
