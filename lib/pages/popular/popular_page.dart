import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/appbar/sys_app_bar.dart';
import 'package:kazumi/bean/card/bangumi_card.dart';
import 'package:kazumi/bean/widget/anime_pastel_style.dart';
import 'package:kazumi/bean/widget/bangumi_mirror_error_widget.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/collect/collect_type.dart';
import 'package:kazumi/pages/collect/collect_controller.dart';
import 'package:kazumi/pages/popular/popular_controller.dart';
import 'package:kazumi/services/logging/logger.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/utils/constants.dart';
import 'package:kazumi/utils/superellipse.dart';

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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final orientation = MediaQuery.orientationOf(context);
    final isPortrait = orientation == Orientation.portrait;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= 780;

    return Scaffold(
      extendBody: true,
      appBar: SysAppBar(
        needTopOffset: false,
        toolbarHeight: 68,
        backgroundColor: colors.surface,
        title: Observer(
          builder: (_) {
            final isTrend = popularController.currentTag == '';
            return Text(
              isTrend ? '热门番组' : popularController.currentTag,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            );
          },
        ),
        actions: buildActions(isWide: isWide),
      ),
      body: AnimePastelBackdrop(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final compact = maxWidth < 600;
            final cappedWidth = maxWidth.clamp(0.0, 1600.0);
            final sideInset =
                (maxWidth - cappedWidth) / 2 + (compact ? 14.0 : 24.0);
            final contentWidth =
                (maxWidth - sideInset * 2).clamp(240.0, double.infinity);

            return CustomScrollView(
              controller: scrollController,
              slivers: [
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
      padding: const EdgeInsets.only(top: 4, bottom: 10),
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
                final label = tag.isEmpty ? '热门番组' : tag;
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
                        horizontal: 13,
                        vertical: 6,
                      ),
                      decoration: ShapeDecoration(
                        gradient: selected ? palette.ribbonGradient : null,
                        color: selected ? null : palette.frameFill,
                        shape: SuperellipseBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: selected
                                ? palette.accent.withValues(alpha: 0.25)
                                : palette.frameBorder,
                            width: 0.85,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.2,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected
                                ? palette.onAccent
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
          side: BorderSide(color: palette.frameBorder, width: 0.85),
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
                  color: palette.toolbarFill,
                  shape: SuperellipseBorder(
                    borderRadius: BorderRadius.circular(13),
                    side: BorderSide(color: palette.toolbarBorder, width: 0.85),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_rounded,
                          size: 16, color: palette.accent),
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
      Padding(
        padding: const EdgeInsets.only(right: 4),
        child: IconButton(
          tooltip: '历史记录',
          onPressed: () => context.pushNamed('/settings/history/'),
          icon: const Icon(Icons.history_rounded),
        ),
      ),
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
