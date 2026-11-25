import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/appbar/drag_to_move_bar.dart' as dtb;
import 'package:kazumi/bean/card/bangumi_card.dart';
import 'package:kazumi/bean/widget/anime_pastel_style.dart';
import 'package:kazumi/bean/widget/bangumi_mirror_error_widget.dart';
import 'package:kazumi/bean/widget/kazumi_menu.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/collect/collect_type.dart';
import 'package:kazumi/pages/collect/collect_controller.dart';
import 'package:kazumi/pages/popular/popular_controller.dart';
import 'package:kazumi/services/logging/logger.dart';
import 'package:kazumi/services/platform/desktop_window_config.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/utils/constants.dart';
import 'package:kazumi/utils/device.dart';
import 'package:kazumi/utils/superellipse.dart';
import 'package:window_manager/window_manager.dart';

class PopularPage extends StatefulWidget {
  const PopularPage({
    super.key,
    required this.controller,
    this.collectController,
  });

  final PopularController controller;
  final CollectController? collectController;

  @override
  State<PopularPage> createState() => _PopularPageState();
}

class _PopularPageState extends State<PopularPage> {
  late final ScrollController scrollController;
  late final bool _showRating;
  PopularController get popularController => widget.controller;

  @override
  void initState() {
    super.initState();
    _showRating = GStorage.getSetting(SettingsKeys.showRating);
    scrollController = ScrollController(
      initialScrollOffset: popularController.scrollOffset,
    );
    scrollController.addListener(scrollListener);
    popularController.scrollToTop = _scrollToTop;
    if (popularController.trendList.isEmpty) {
      popularController.queryBangumiByTrend();
    }
  }

  @override
  void dispose() {
    if (popularController.scrollToTop == _scrollToTop) {
      popularController.scrollToTop = null;
    }
    scrollController.removeListener(scrollListener);
    scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  void scrollListener() {
    popularController.scrollOffset = scrollController.offset;
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        !popularController.isLoadingMore) {
      KazumiLogger()
          .i('PopularPageController: Fetching next recommendation batch');
      if (popularController.currentTag != '') {
        popularController.queryBangumiByTag();
      } else {
        popularController.queryBangumiByTrend();
      }
    }
  }

  Set<int> _watchingIds() {
    final collect = widget.collectController;
    if (collect == null) return const <int>{};
    return collect.collectibles
        .where((e) => e.type == CollectType.watching.value)
        .map((e) => e.bangumiItem.id)
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.orientationOf(context);
    final isPortrait = orientation == Orientation.portrait;

    return Scaffold(
      extendBody: true,
      body: AnimePastelBackdrop(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final compact = maxWidth < 600;
            final cappedWidth = maxWidth.clamp(0.0, 1600.0);
            final sideInset =
                (maxWidth - cappedWidth) / 2 + (compact ? 12.0 : 22.0);
            final contentWidth =
                (maxWidth - sideInset * 2).clamp(240.0, double.infinity);

            return CustomScrollView(
              controller: scrollController,
              slivers: [
                buildSliverAppBar(
                  sideInset: sideInset,
                  isWide: maxWidth >= 780,
                ),
                SliverToBoxAdapter(
                  child: _buildTagStrip(sideInset: sideInset),
                ),
                SliverToBoxAdapter(
                  child: Observer(
                    builder: (_) => AnimatedOpacity(
                      opacity: popularController.isLoadingMore ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 260),
                      child: popularController.isLoadingMore
                          ? const LinearProgressIndicator(minHeight: 3)
                          : const SizedBox(height: 3),
                    ),
                  ),
                ),
                Observer(
                  builder: (_) {
                    if (popularController.isTimeOut) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: sideInset),
                          child: SizedBox(
                            height: 400,
                            child: BangumiMirrorErrorWidget(
                              onRetry: () {
                                if (popularController.trendList.isEmpty) {
                                  popularController.queryBangumiByTrend();
                                } else {
                                  popularController.queryBangumiByTag();
                                }
                              },
                              onSettingsReturned: () {
                                if (mounted) {
                                  setState(() {});
                                }
                              },
                            ),
                          ),
                        ),
                      );
                    }
                    final isTrend = popularController.currentTag == '';
                    final list = isTrend
                        ? popularController.trendList
                        : popularController.bangumiList;
                    final watchingIds = _watchingIds();
                    return contentGrid(
                      list,
                      contentWidth: contentWidth,
                      sideInset: sideInset,
                      isPortrait: isPortrait,
                      isTrend: isTrend,
                      watchingIds: watchingIds,
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTagStrip({required double sideInset}) {
    final palette = AnimePastelPalette.of(context);
    final colors = Theme.of(context).colorScheme;
    final tags = ['', ...defaultAnimeTags];

    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 10),
      child: SizedBox(
        height: 36,
        child: Observer(
          builder: (_) {
            final activeTag = popularController.currentTag;
            return ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: sideInset),
              itemCount: tags.length,
              separatorBuilder: (_, __) => const SizedBox(width: 7),
              itemBuilder: (context, index) {
                final tag = tags[index];
                final selected = tag == activeTag;
                final label = tag.isEmpty ? '✿ 热门番组' : tag;
                return Material(
                  type: MaterialType.transparency,
                  shape: SuperellipseBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    customBorder: SuperellipseBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () => _selectTag(tag),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: ShapeDecoration(
                        gradient: selected ? palette.ribbonGradient : null,
                        color: selected ? null : palette.frameFill,
                        shape: SuperellipseBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: selected
                                ? Colors.white.withValues(alpha: 0.28)
                                : palette.frameBorder,
                            width: 0.9,
                          ),
                        ),
                        shadows: selected
                            ? [
                                BoxShadow(
                                  color: palette.sakura.withValues(
                                      alpha: palette.isDark ? 0.24 : 0.22),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : const [],
                      ),
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.2,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget contentGrid(
    List<BangumiItem> bangumiList, {
    required double contentWidth,
    required double sideInset,
    required bool isPortrait,
    required bool isTrend,
    required Set<int> watchingIds,
  }) {
    final compact = contentWidth < 520;
    final spacing = compact ? 9.0 : 12.0;
    final crossCount = animePosterColumns(
      contentWidth,
      isPortrait: isPortrait,
      spacing: spacing,
      targetWidth: 152.0,
    );
    final cardWidth = (contentWidth - spacing * (crossCount - 1)) / crossCount;
    final scaler = MediaQuery.textScalerOf(context);
    final extent = BangumiCardV.extentFor(cardWidth, scaler, compact: compact);

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        sideInset,
        4,
        sideInset,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          crossAxisCount: crossCount,
          mainAxisExtent: extent,
        ),
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            if (bangumiList.isEmpty) {
              return _buildSkeletonCard(compact: compact);
            }
            final item = bangumiList[index];
            return BangumiCardV(
              bangumiItem: item,
              rankIndex: isTrend ? index : null,
              isWatching: watchingIds.contains(item.id),
              showRating: _showRating,
              compact: compact,
            );
          },
          childCount: bangumiList.isNotEmpty ? bangumiList.length : 12,
        ),
      ),
    );
  }

  Widget _buildSkeletonCard({required bool compact}) {
    final palette = AnimePastelPalette.of(context);
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: palette.frameFill,
        shape: SuperellipseBorder(
          borderRadius: BorderRadius.circular(compact ? 15 : 17),
          side: BorderSide(color: palette.frameBorder, width: 0.9),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 4 : 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: BangumiCardV.coverAspectRatio,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.6),
                  shape: SuperellipseBorder(
                    borderRadius: BorderRadius.circular(compact ? 11 : 12.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 11,
              margin: const EdgeInsets.only(right: 24, left: 2),
              decoration: ShapeDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
                shape: SuperellipseBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSliverAppBar({
    required double sideInset,
    required bool isWide,
  }) {
    final theme = Theme.of(context);
    final palette = AnimePastelPalette.of(context);
    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 96,
      toolbarHeight: 62,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      actions: buildActions(isWide: isWide),
      title: null,
      flexibleSpace: SafeArea(
        bottom: false,
        child: dtb.DragToMoveArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double maxExtent =
                  96 - MediaQuery.paddingOf(context).top.clamp(0.0, 34.0);
              final denom = (maxExtent - 62).clamp(1.0, double.infinity);
              final t = (1 - ((constraints.maxHeight - 62) / denom))
                  .clamp(0.0, 1.0);
              final fontSize = lerpDouble(23, 19, t)!;
              final showEyebrow = t < 0.45;
              return Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: sideInset,
                    right: isWide ? 280 : 108,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showEyebrow)
                        Opacity(
                          opacity: (1 - t * 2.2).clamp(0.0, 1.0),
                          child: Text(
                            '✿ TRENDING ANIME · 今季热播',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: palette.sakura,
                            ),
                          ),
                        ),
                      Observer(
                        builder: (_) {
                          final bool isTrend =
                              popularController.currentTag == '';
                          return KazumiMenuButton(
                            animated: true,
                            style: const MenuStyle(
                              maximumSize:
                                  WidgetStatePropertyAll(Size(240, 360)),
                            ),
                            menuChildren: [
                              for (final tag in ['', ...defaultAnimeTags])
                                KazumiMenuItem(
                                  label: tag.isEmpty ? '热门番组' : tag,
                                  selected: tag == popularController.currentTag,
                                  onPressed: () => _selectTag(tag),
                                ),
                            ],
                            builder: (context, toggle) => InkWell(
                              customBorder: SuperellipseBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              onTap: toggle,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        isTrend
                                            ? '热门番组'
                                            : popularController.currentTag,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          fontSize: fontSize,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: fontSize,
                                      color: palette.sakura,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> buildActions({required bool isWide}) {
    final palette = AnimePastelPalette.of(context);
    final colors = Theme.of(context).colorScheme;
    return <Widget>[
      if (isWide)
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Material(
            type: MaterialType.transparency,
            shape: SuperellipseBorder(borderRadius: BorderRadius.circular(13)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: SuperellipseBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              onTap: () => context.pushNamed('/search/'),
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: palette.frameFill,
                  shape: SuperellipseBorder(
                    borderRadius: BorderRadius.circular(13),
                    side: BorderSide(color: palette.frameBorder, width: 0.9),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_rounded,
                          size: 16, color: palette.sakura),
                      const SizedBox(width: 6),
                      Text(
                        '搜索番剧、标签…',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        )
      else if (MediaQuery.orientationOf(context) == Orientation.portrait)
        IconButton(
          tooltip: '搜索',
          onPressed: () => context.pushNamed('/search/'),
          icon: const Icon(Icons.search_rounded),
        ),
      IconButton(
        tooltip: '历史记录',
        onPressed: () => context.pushNamed('/settings/history/'),
        icon: const Icon(Icons.history_rounded),
      ),
      if (isDesktop() && !DesktopWindowConfig.showWindowButton)
        IconButton(
          tooltip: '退出',
          onPressed: () => windowManager.close(),
          icon: const Icon(Icons.close_rounded),
        ),
      const SizedBox(width: 8),
    ];
  }

  Future<void> _selectTag(String selected) async {
    if (!mounted || selected == popularController.currentTag) return;
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
    popularController.setCurrentTag(selected);
    if (selected.isEmpty) {
      popularController.clearBangumiList();
      if (popularController.trendList.isEmpty) {
        await popularController.queryBangumiByTrend();
      }
    } else {
      await popularController.queryBangumiByTag(type: 'init');
    }
  }
}
