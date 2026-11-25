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

class _PopularPageState extends State<PopularPage>
    with SingleTickerProviderStateMixin {
  late final ScrollController scrollController;
  late final TabController _tagTabController;
  late final bool _showRating;
  static final List<String> _allTags = ['', ...defaultAnimeTags];

  PopularController get popularController => widget.controller;

  @override
  void initState() {
    super.initState();
    _showRating = GStorage.getSetting(SettingsKeys.showRating);
    final initialIndex =
        _allTags.indexOf(popularController.currentTag).clamp(0, _allTags.length - 1);
    _tagTabController = TabController(
      length: _allTags.length,
      initialIndex: initialIndex,
      vsync: this,
    );
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
    _tagTabController.dispose();
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
        actions: buildActions(isPortrait: isPortrait),
      ),
      body: LayoutBuilder(
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
                child: Padding(
                  padding: EdgeInsets.fromLTRB(sideInset, 4, sideInset, 10),
                  child: AnimePillTabTrack(
                    tabBarKey: const PageStorageKey('popular-tag-strip'),
                    controller: _tagTabController,
                    isScrollable: true,
                    onTap: (index) => _selectTag(_allTags[index]),
                    tabs: [
                      for (final tag in _allTags)
                        Tab(
                          height: 36,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(tag.isEmpty ? '热门番组' : tag),
                          ),
                        ),
                    ],
                  ),
                ),
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
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: colors.surfaceContainerLow,
        shape: SuperellipseBorder(
          borderRadius: BorderRadius.circular(compact ? 15 : 17),
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

  List<Widget> buildActions({required bool isPortrait}) {
    return <Widget>[
      if (isPortrait)
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
