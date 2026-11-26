import 'dart:async';

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
  static final List<String> _allTags = ['', ...defaultAnimeTags];

  late final TabController _tagTabController;
  late final bool _showRating;
  final Map<int, ScrollController> _scrollControllers = {};
  final Map<String, List<BangumiItem>> _tagCache = {};

  PopularController get popularController => widget.controller;

  ScrollController _controllerFor(int index) {
    return _scrollControllers.putIfAbsent(index, () {
      final ctrl = ScrollController(
        initialScrollOffset:
            index == _tagTabController.index ? popularController.scrollOffset : 0.0,
      );
      ctrl.addListener(() => _onScroll(index, ctrl));
      return ctrl;
    });
  }

  @override
  void initState() {
    super.initState();
    _showRating = GStorage.getSetting(SettingsKeys.showRating);
    final initialIndex = _allTags
        .indexOf(popularController.currentTag)
        .clamp(0, _allTags.length - 1);
    _tagTabController = TabController(
      length: _allTags.length,
      initialIndex: initialIndex,
      vsync: this,
    )..addListener(_onTabChanged);
    popularController.scrollToTop = _scrollToTop;
    final collect = widget.collectController;
    if (collect != null && collect.collectibles.isEmpty) {
      collect.loadCollectibles();
    }
    if (popularController.currentTag.isEmpty) {
      if (popularController.trendList.isEmpty) {
        popularController.queryBangumiByTrend();
      }
    } else if (popularController.bangumiList.isEmpty) {
      popularController.queryBangumiByTag(type: 'init');
    }
  }

  @override
  void dispose() {
    if (popularController.scrollToTop == _scrollToTop) {
      popularController.scrollToTop = null;
    }
    _tagTabController.removeListener(_onTabChanged);
    _tagTabController.dispose();
    for (final ctrl in _scrollControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _onTabChanged() {
    if (_tagTabController.indexIsChanging) return;
    final tag = _allTags[_tagTabController.index];
    if (tag != popularController.currentTag) {
      unawaited(_selectTag(tag));
    }
  }

  void _scrollToTop() {
    final ctrl = _scrollControllers[_tagTabController.index];
    if (ctrl != null && ctrl.hasClients) {
      ctrl.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  void _onScroll(int tabIndex, ScrollController ctrl) {
    if (tabIndex != _tagTabController.index) return;
    popularController.scrollOffset = ctrl.offset;
    if (ctrl.position.pixels >= ctrl.position.maxScrollExtent - 200 &&
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

  List<BangumiItem> _itemsForTag(String tag) {
    if (tag.isEmpty) {
      return popularController.trendList;
    }
    if (tag == popularController.currentTag) {
      if (popularController.bangumiList.isNotEmpty) {
        _tagCache[tag] = List<BangumiItem>.of(popularController.bangumiList);
      }
      return popularController.bangumiList;
    }
    return _tagCache[tag] ?? const <BangumiItem>[];
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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 10),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AnimeSeparatedTabBar(
                    controller: _tagTabController,
                    itemCount: _allTags.length,
                    scrollable: true,
                    height: 36,
                    spacing: 7,
                    borderRadius: 12,
                    padding: EdgeInsets.symmetric(horizontal: sideInset),
                    onTap: (index) => unawaited(_selectTag(_allTags[index])),
                    itemBuilder: (context, index, selection, fgColor) {
                      final tag = _allTags[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 13),
                        child: AnimeCapsuleText(
                          tag.isEmpty ? '热门番组' : tag,
                          fontSize: 12.5,
                          lineHeight: 1.15,
                          fontWeight: selection > 0.5
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: fgColor,
                          overflow: TextOverflow.visible,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Observer(
                builder: (_) => AnimatedOpacity(
                  opacity: popularController.isLoadingMore ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 240),
                  child: popularController.isLoadingMore
                      ? const LinearProgressIndicator(minHeight: 3)
                      : const SizedBox(height: 3),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tagTabController,
                  children: [
                    for (var i = 0; i < _allTags.length; i++)
                      _buildTagPage(
                        index: i,
                        tag: _allTags[i],
                        contentWidth: contentWidth,
                        sideInset: sideInset,
                        isPortrait: isPortrait,
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTagPage({
    required int index,
    required String tag,
    required double contentWidth,
    required double sideInset,
    required bool isPortrait,
  }) {
    final isTrend = tag.isEmpty;
    final ctrl = _controllerFor(index);
    return Observer(
      builder: (_) {
        final isActive = tag == popularController.currentTag;
        if (isActive && popularController.isTimeOut) {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: sideInset),
              child: BangumiMirrorErrorWidget(
                onRetry: () {
                  if (isTrend) {
                    popularController.queryBangumiByTrend();
                  } else {
                    popularController.queryBangumiByTag(type: 'init');
                  }
                },
                onSettingsReturned: () {
                  if (mounted) setState(() {});
                },
              ),
            ),
          );
        }
        final list = _itemsForTag(tag);
        final watchingIds = _watchingIds();
        return HeroMode(
          enabled: isActive,
          child: CustomScrollView(
            key: PageStorageKey('popular-tag-$tag'),
            controller: ctrl,
            slivers: [
              contentGrid(
                list,
                contentWidth: contentWidth,
                sideInset: sideInset,
                isPortrait: isPortrait,
                isTrend: isTrend,
                watchingIds: watchingIds,
              ),
            ],
          ),
        );
      },
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
      decoration: palette.cardDecoration(radius: compact ? 15 : 17),
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
    popularController.setCurrentTag(selected);
    if (selected.isEmpty) {
      popularController.clearBangumiList();
      if (popularController.trendList.isEmpty) {
        await popularController.queryBangumiByTrend();
      }
    } else {
      final cached = _tagCache[selected];
      if (cached != null && cached.isNotEmpty) {
        popularController.clearBangumiList();
        popularController.bangumiList.addAll(cached);
        return;
      }
      await popularController.queryBangumiByTag(type: 'init');
      if (mounted &&
          popularController.currentTag == selected &&
          popularController.bangumiList.isNotEmpty) {
        _tagCache[selected] = List<BangumiItem>.of(popularController.bangumiList);
      }
    }
  }
}
