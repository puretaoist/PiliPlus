import 'dart:async';
import 'dart:math';

import 'package:PiliPlus/common/assets.dart';
import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/badge.dart';
import 'package:PiliPlus/common/widgets/button/icon_button.dart';
import 'package:PiliPlus/common/widgets/image/image_save.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/keep_alive_wrapper.dart';
import 'package:PiliPlus/common/widgets/scroll_physics.dart'
    show tabBarScrollPhysics;
import 'package:PiliPlus/common/widgets/stat/stat.dart';
import 'package:PiliPlus/http/fav.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/models/common/episode_panel_type.dart';
import 'package:PiliPlus/models/common/stat_type.dart';
import 'package:PiliPlus/models_new/pgc/pgc_info_model/episode.dart' as pgc;
import 'package:PiliPlus/models_new/video/video_detail/episode.dart' as ugc;
import 'package:PiliPlus/models_new/video/video_detail/page.dart';
import 'package:PiliPlus/pages/common/slide/common_slide_page.dart';
import 'package:PiliPlus/pages/video/controller.dart';
import 'package:PiliPlus/pages/video/introduction/ugc/controller.dart';
import 'package:PiliPlus/pages/video/introduction/ugc/widgets/page.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/date_utils.dart';
import 'package:PiliPlus/utils/duration_utils.dart';
import 'package:PiliPlus/utils/extension/num_ext.dart';
import 'package:PiliPlus/utils/extension/scroll_controller_ext.dart';
import 'package:PiliPlus/utils/id_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart';

class EpisodePanel extends CommonSlidePage {
  const EpisodePanel({
    super.key,
    super.enableSlide,
    required this.ugcIntroController,
    required this.heroTag,
    required this.type,
    // required this.count,
    // required this.name,
    required this.aid,
    required this.bvid,
    required this.cid,
    required this.cover,
    this.showTitle = true,
    required this.list,
    this.seasonId,
    this.initialTabIndex = 0,
    this.isSupportReverse,
    this.isReversed,
    this.onReverse,
    required this.onChangeEpisode,
    this.onClose,
  }) : assert(type == EpisodeType.pgc || ugcIntroController != null);

  final UgcIntroController? ugcIntroController;
  final String heroTag;
  final EpisodeType type;
  // final int count;
  // final String name;
  final int? aid;
  final String bvid;
  final int cid;
  final String? cover;
  final bool showTitle;
  final List list;
  final int? seasonId;
  final int initialTabIndex;
  final bool? isSupportReverse;
  final bool? isReversed;
  final Future<bool> Function(ugc.BaseEpisodeItem) onChangeEpisode;
  final VoidCallback? onReverse;
  final VoidCallback? onClose;

  @override
  State<EpisodePanel> createState() => _EpisodePanelState();
}

class _EpisodePanelState extends State<EpisodePanel>
    with TickerProviderStateMixin, CommonSlideMixin {
  // tab
  late TabController _tabController;
  late final RxInt _currentTabIndex = _tabController.index.obs;

  late final showTitle = widget.showTitle;

  /// 夹进合法范围的 tab 下标。
  ///
  /// 分集数据会在**同一个 State** 上更新（切视频、番剧换季、合集从 1 个 tab
  /// 变成 N 个），而 tab 下标来自父级与新列表，控制器列表却是按长度建的；
  /// 不夹的话真机会抛 RangeError（2026-09-16 22:26 连续三条：
  /// `0..5: 6` ← material_ui tabs.dart `_IndicatorPainter.centerOf`、
  /// `0..4: 5` / `0..4: 6` ← 本文件 `_buildBody` / `jumpToCurrent`）
  int get _tabIndex =>
      _currentTabIndex.value.clamp(0, max(0, widget.list.length - 1));

  int get _safeInitialTabIndex =>
      widget.initialTabIndex.clamp(0, max(0, widget.list.length - 1));

  List<ugc.BaseEpisodeItem> get _getCurrEpisodes =>
      widget.list.isEmpty
      ? const []
      : widget.type == EpisodeType.season
      ? widget.list[_tabIndex].episodes
      : widget.list[_tabIndex];

  // item
  late int _currentItemIndex;
  int get _findCurrentItemIndex => max(
    0,
    _getCurrEpisodes.indexWhere((item) => item.cid == widget.cid),
  );

  late List<bool> _isReversed;
  late List<ScrollController> _itemScrollController;

  // fav
  Rx<LoadingState<bool>>? _favState;

  void listener() {
    _currentTabIndex.value = _tabController.index;
  }

  /// 按当前 [EpisodePanel.list] 建立 tab 控制器与每个 tab 的滚动控制器。
  ///
  /// initState 与 didUpdateWidget（列表长度变化时）都会调用 ——
  /// 以前只在 initState 建一次，长度变化后下标就越界了（见 [_tabIndex] 注释）。
  void _initControllers() {
    final length = max(1, widget.list.length);
    _tabController = TabController(
      initialIndex: _safeInitialTabIndex,
      length: length,
      vsync: this,
    )..addListener(listener);
    _currentTabIndex.value = _tabController.index;
    _currentItemIndex = _findCurrentItemIndex;
    _itemScrollController = List.generate(
      length,
      (i) => ScrollController(
        initialScrollOffset: i == _safeInitialTabIndex
            ? _currentItemIndex == 0
                  ? 0
                  : _calcItemOffset(_currentItemIndex)
            : 0,
      ),
      growable: false,
    );
    _isReversed = List.filled(length, false);
  }

  @override
  void didUpdateWidget(EpisodePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 分集列表变长/变短（合集加载完、切视频、番剧换季）时重建控制器：
    // 控制器是按下标建的，长度变了必须跟着重建，否则 index 会越界
    if (widget.list.length != oldWidget.list.length) {
      for (final c in _itemScrollController) {
        c.dispose();
      }
      _tabController
        ..removeListener(listener)
        ..dispose();
      _initControllers();
    }
    if (showTitle) {
      return;
    }

    @pragma('vm:notify-debugger-on-exception')
    void jumpToCurrent() {
      final newItemIndex = _findCurrentItemIndex;
      if (_currentItemIndex != newItemIndex) {
        _currentItemIndex = newItemIndex;
        try {
          _itemScrollController[_tabIndex].jumpTo(
            _calcItemOffset(newItemIndex),
          );
        } catch (e, s) {
          Utils.reportError(e, s);
        }
      }
    }

    // jump to current
    if (_currentTabIndex.value != _safeInitialTabIndex) {
      _tabController.animateTo(
        _safeInitialTabIndex,
        duration: const Duration(milliseconds: 200),
      );
      Timer(const Duration(milliseconds: 300), jumpToCurrent);
    } else {
      jumpToCurrent();
    }
  }

  @override
  void initState() {
    super.initState();
    _initControllers();

    if (widget.type == EpisodeType.season && Accounts.main.isLogin) {
      final favState =
          widget.ugcIntroController?.seasonFavState[widget.seasonId];
      if (favState != null) {
        _favState = Success(favState).obs;
      } else {
        _favState = LoadingState<bool>.loading().obs;
        VideoHttp.videoRelation(bvid: widget.bvid).then(
          (result) {
            if (!mounted) return;
            if (result case Success(:final response)) {
              final seasonFav = response.seasonFav ?? false;
              _favState!.value = Success(seasonFav);
              widget.ugcIntroController?.seasonFavState[widget.seasonId] =
                  seasonFav;
            }
          },
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(listener)
      ..dispose();
    _favState?.close();
    for (final e in _itemScrollController) {
      e.dispose();
    }
    super.dispose();
  }

  late final _isMulti =
      widget.type == EpisodeType.season && widget.list.length > 1;

  @override
  Widget buildPage(ThemeData theme) {
    return Material(
      color: showTitle ? theme.colorScheme.surface : null,
      type: showTitle ? MaterialType.canvas : MaterialType.transparency,
      child: Column(
        children: [
          _buildToolbar(theme),
          if (_isMulti)
            TabBar(
              controller: _tabController,
              padding: const EdgeInsets.only(right: 60),
              isScrollable: true,
              tabs: widget.list.map((item) => Tab(text: item.title)).toList(),
              dividerHeight: 1,
              dividerColor: theme.dividerColor.withValues(alpha: 0.1),
            ),
          Expanded(child: enableSlide ? slideList(theme) : buildList(theme)),
        ],
      ),
    );
  }

  @override
  Widget buildList(ThemeData theme) {
    if (_isMulti) {
      return TabBarView(
        controller: _tabController,
        physics: tabBarScrollPhysics,
        horizontalDragGestureRecognizer: horizontalDragGestureRecognizer,
        children: List.generate(
          widget.list.length,
          (index) => _buildBody(
            theme,
            index,
            widget.list[index].episodes,
          ),
        ),
      );
    }
    return _buildBody(theme, 0, _getCurrEpisodes);
  }

  double _calcItemOffset(int index) {
    if (showTitle) {
      final episodes = _getCurrEpisodes;
      double offset = 0;
      for (var i = 0; i < index; i++) {
        offset += _calcItemHeight(episodes[i]);
      }
      return offset + 7;
    } else {
      return index * 112 + 7;
    }
  }

  double _calcItemHeight(ugc.BaseEpisodeItem episode) {
    if (episode is ugc.EpisodeItem && episode.pages!.length > 1) {
      return 167; // 110 + 2 + 10 + 45
    }
    return 112;
  }

  Widget _buildBody(
    ThemeData theme,
    int tabIndex,
    List<ugc.BaseEpisodeItem> episodes,
  ) {
    final isCurrTab = tabIndex == widget.initialTabIndex;
    return KeepAliveWrapper(
      child: CustomScrollView(
        reverse: _isReversed[tabIndex],
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _itemScrollController[tabIndex],
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(
              top: 7,
              bottom: MediaQuery.viewPaddingOf(context).bottom + 100,
            ),
            sliver: showTitle
                ? SliverVariedExtentList.builder(
                    itemCount: episodes.length,
                    itemBuilder: (context, index) {
                      final episode = episodes[index];
                      final isCurrItem = isCurrTab
                          ? index == _currentItemIndex
                          : false;
                      Widget episodeItem = _buildEpisodeItem(
                        theme: theme,
                        episode: episode,
                        index: index,
                        length: episodes.length,
                        isCurrentIndex: isCurrItem,
                      );
                      if (episode is ugc.EpisodeItem &&
                          episode.pages!.length > 1) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            episodeItem, // 110
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ), // 10
                              child: PagesPanel(
                                // 45
                                list: isCurrTab && isCurrItem
                                    ? null
                                    : episode.pages,
                                cover: episode.arc?.pic,
                                heroTag: widget.heroTag,
                                ugcIntroController: widget.ugcIntroController!,
                                bvid:
                                    episode.bvid ?? IdUtils.av2bv(episode.aid!),
                              ),
                            ),
                          ],
                        );
                      }
                      return episodeItem;
                    },
                    itemExtentBuilder: (index, _) =>
                        _calcItemHeight(episodes[index]),
                  )
                : SliverFixedExtentList.builder(
                    itemCount: episodes.length,
                    itemBuilder: (context, index) {
                      final episode = episodes[index];
                      final isCurrItem = isCurrTab
                          ? index == _currentItemIndex
                          : false;
                      return _buildEpisodeItem(
                        theme: theme,
                        episode: episode,
                        index: index,
                        length: episodes.length,
                        isCurrentIndex: isCurrItem,
                      );
                    },
                    itemExtent: 112,
                  ),
          ),
        ],
      ),
    );
  }

  late final int? vipStatus = Pref.userInfoCache?.vipStatus;
  Widget _buildEpisodeItem({
    required ThemeData theme,
    required ugc.BaseEpisodeItem episode,
    required int index,
    required int length,
    required bool isCurrentIndex,
  }) {
    late String title;
    String? cover;
    String? bvid;
    num? duration;
    int? pubdate;
    int? view;
    int? danmaku;
    bool? isCharging;
    bool? cacheWidth;

    switch (episode) {
      case Part part:
        cover = part.firstFrame ?? widget.cover;
        title = part.part!;
        duration = part.duration;
        pubdate = part.ctime;
        cacheWidth = part.dimension?.cacheWidth;
        break;
      case ugc.EpisodeItem item:
        title = item.title!;
        bvid = item.bvid;
        if (item.arc case final arc?) {
          cover = arc.pic;
          duration = arc.duration;
          pubdate = arc.pubdate;
          if (arc.stat case final stat?) {
            view = stat.view;
            danmaku = stat.danmaku;
          }
          cacheWidth = arc.dimension?.cacheWidth;
        }
        if (item.attribute == 8) {
          isCharging = true;
        }
        break;
      case pgc.EpisodeItem item:
        bvid = item.bvid;
        title = item.showTitle ?? item.title!;
        cover = item.cover;
        if (item.from == 'pugv') {
          duration = item.duration;
          view = item.play;
        } else {
          duration = item.duration == null ? null : item.duration! ~/ 1000;
        }
        pubdate = item.pubTime;
        cacheWidth = item.dimension?.cacheWidth;
        break;
    }
    late final Color primary = theme.colorScheme.primary;

    void onLongPress() {
      if (cover?.isNotEmpty == true) {
        imageSaveDialog(title: title, cover: cover, bvid: bvid);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: SizedBox(
        height: 110,
        child: Material(
          type: .transparency,
          child: InkWell(
            onTap: () {
              if (isCurrentIndex) return;
              if (episode.badge == "会员" &&
                  Accounts.mainEqVideo &&
                  vipStatus != 1) {
                SmartDialog.showToast('需要大会员');
                // return;
              }
              SmartDialog.showToast('切换到：$title');
              widget.onClose?.call();

              widget.onChangeEpisode(episode).then((res) {
                if (res) {
                  if (!showTitle) {
                    _currentItemIndex = index;
                  }
                  if (widget.type == EpisodeType.season) {
                    try {
                      Get.find<VideoDetailController>(
                        tag: widget.ugcIntroController!.heroTag,
                      ).seasonCid = episode.cid;
                    } catch (_) {
                      if (kDebugMode) rethrow;
                    }
                  }
                }
              });
            },
            onLongPress: onLongPress,
            onSecondaryTap: PlatformUtils.isMobile ? null : onLongPress,
            child: Padding(
              padding: const .symmetric(
                horizontal: Style.safeSpace,
                vertical: 5,
              ),
              child: Row(
                spacing: 10,
                children: [
                  if (cover?.isNotEmpty == true)
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        NetworkImgLayer(
                          src: cover,
                          width: 160,
                          height: 100,
                          cacheWidth: cacheWidth,
                        ),
                        if (duration != null && duration > 0)
                          PBadge(
                            text: DurationUtils.formatDuration(duration),
                            right: 6.0,
                            bottom: 6.0,
                            type: .gray,
                          ),
                        if (widget.type == .part)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: const .symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer,
                                borderRadius: const .only(
                                  bottomLeft: .circular(4),
                                  topRight: Style.imgRadius,
                                ),
                              ),
                              child: Text(
                                (index + 1).toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          )
                        else if (isCharging == true)
                          const PBadge(
                            text: '充电专属',
                            top: 6,
                            right: 6,
                            type: .error,
                          )
                        else if (episode.badge != null)
                          PBadge(
                            text: episode.badge,
                            top: 6,
                            right: 6,
                            type: switch (episode.badge) {
                              '预告' => .gray,
                              '限免' => .free,
                              _ => .primary,
                            },
                          ),
                      ],
                    )
                  else if (isCurrentIndex)
                    Image.asset(
                      Assets.livingStatic,
                      color: primary,
                      height: 12,
                      cacheHeight: 12.cacheSize(context),
                      semanticLabel: "正在播放：",
                    ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontSize: theme.textTheme.bodyMedium!.fontSize,
                              height: 1.42,
                              letterSpacing: 0.3,
                              fontWeight: isCurrentIndex
                                  ? FontWeight.bold
                                  : null,
                              color: isCurrentIndex ? primary : null,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (pubdate != null)
                          Text(
                            DateFormatUtils.format(pubdate),
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1,
                              color: theme.colorScheme.outline,
                              overflow: TextOverflow.clip,
                            ),
                          ),
                        if (view != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            spacing: 8,
                            children: [
                              StatWidget(
                                value: view,
                                type: StatType.play,
                              ),
                              if (danmaku != null)
                                StatWidget(
                                  value: danmaku,
                                  type: StatType.danmaku,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFavBtn(LoadingState<bool> loadingState) {
    return switch (loadingState) {
      Success(:final response) => iconButton(
        iconSize: 22,
        tooltip: response ? '取消订阅' : '订阅',
        icon: response
            ? const Icon(Icons.notifications_off_outlined)
            : const Icon(Icons.notifications_active_outlined),
        onPressed: () async {
          final res = await FavHttp.seasonFav(
            isFav: response,
            seasonId: widget.seasonId,
          );
          if (res.isSuccess) {
            SmartDialog.showToast('${response ? '取消' : ''}订阅成功');
            _favState!.value = Success(!response);
            widget.ugcIntroController?.seasonFavState[widget.seasonId] =
                !response;
          } else {
            res.toast();
          }
        },
      ),
      _ => const SizedBox.shrink(),
    };
  }

  Widget get _buildReverseBtn => iconButton(
    iconSize: 22,
    tooltip: widget.isReversed == true ? '正序播放' : '倒序播放',
    icon: widget.isReversed == true
        ? const Icon(MdiIcons.sortDescending)
        : const Icon(MdiIcons.sortAscending),
    onPressed: () => widget.onReverse?.call(),
  );

  void _animToTopOrBottom({bool top = true}) {
    final tabIndex = _tabIndex;
    _itemScrollController[tabIndex].animTo(
      top ^ _isReversed[tabIndex]
          ? 0
          : _calcItemOffset(_getCurrEpisodes.length),
      duration: const Duration(milliseconds: 200),
    );
  }

  Widget _buildToolbar(ThemeData theme) => Container(
    height: 45,
    padding: EdgeInsets.symmetric(horizontal: showTitle ? 14 : 6),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
    ),
    child: Row(
      children: [
        if (showTitle)
          Text(
            widget.type.title,
            style: theme.textTheme.titleMedium,
          ),
        if (_favState != null) Obx(() => _buildFavBtn(_favState!.value)),
        iconButton(
          iconSize: 22,
          tooltip: '跳至顶部',
          icon: const Icon(Icons.vertical_align_top),
          onPressed: _animToTopOrBottom,
        ),
        iconButton(
          iconSize: 22,
          tooltip: '跳至底部',
          icon: const Icon(Icons.vertical_align_bottom),
          onPressed: () => _animToTopOrBottom(top: false),
        ),
        iconButton(
          iconSize: 22,
          tooltip: '跳至当前',
          icon: const Icon(Icons.my_location),
          onPressed: () async {
            final currentTabIndex = _tabIndex;
            if (currentTabIndex != _safeInitialTabIndex) {
              _tabController.animateTo(_safeInitialTabIndex);
              await Future.pause(const Duration(milliseconds: 225));
            }
            _itemScrollController[_safeInitialTabIndex].animTo(
              _calcItemOffset(_currentItemIndex),
              duration: const Duration(milliseconds: 200),
            );
          },
        ),
        if (widget.isSupportReverse == true)
          Obx(
            () {
              return _currentTabIndex.value == _safeInitialTabIndex
                  ? _buildReverseBtn
                  : const SizedBox.shrink();
            },
          ),
        const Spacer(),
        Obx(
          () {
            final currentTabIndex = _tabIndex;
            return iconButton(
              iconSize: 22,
              tooltip: _isReversed[currentTabIndex] ? '顺序' : '倒序',
              icon: !_isReversed[currentTabIndex]
                  ? const Icon(MdiIcons.sortNumericAscending)
                  : const Icon(MdiIcons.sortNumericDescending),
              onPressed: () => setState(() {
                _isReversed[currentTabIndex] = !_isReversed[currentTabIndex];
              }),
            );
          },
        ),
        if (widget.onClose != null)
          iconButton(
            iconSize: 22,
            tooltip: '关闭',
            icon: const Icon(Icons.close),
            onPressed: widget.onClose,
          ),
      ],
    ),
  );
}
