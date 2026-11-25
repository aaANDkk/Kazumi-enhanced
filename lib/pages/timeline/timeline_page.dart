import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'package:kazumi/bean/appbar/sys_app_bar.dart';
import 'package:kazumi/bean/card/bangumi_timeline_card.dart';
import 'package:kazumi/bean/dialog/adaptive_bottom_sheet.dart';
import 'package:kazumi/bean/dialog/material_bottom_sheet.dart';
import 'package:kazumi/bean/widget/anime_pastel_style.dart';
import 'package:kazumi/bean/widget/bangumi_mirror_error_widget.dart';
import 'package:kazumi/bean/widget/content_section.dart';
import 'package:kazumi/bean/widget/empty_state_widget.dart';
import 'package:kazumi/bean/widget/loading_indicator.dart';
import 'package:kazumi/bean/widget/split_list_row.dart';
import 'package:kazumi/bean/widget/state_presentation.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/pages/timeline/timeline_controller.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/utils/anime_season.dart';
import 'package:kazumi/utils/superellipse.dart';

part 'timeline_options.dart';
part 'timeline_week_selector.dart';

class TimelinePage extends StatefulWidget {
  const TimelinePage({
    super.key,
    required this.controller,
  });

  final TimelineController controller;

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  TimelineController get _controller => widget.controller;
  late final bool _showRating;
  final _nestedKey = GlobalKey<NestedScrollViewState>();

  @override
  void initState() {
    super.initState();
    _controller.scrollToTop = _scrollToTop;
    _showRating = GStorage.getSetting(SettingsKeys.showRating);
    if (_controller.bangumiCalendar.isEmpty) {
      _controller.loadSeason(_controller.selectedDate);
    }
  }

  @override
  void dispose() {
    if (_controller.scrollToTop == _scrollToTop) {
      _controller.scrollToTop = null;
    }
    super.dispose();
  }

  void _scrollToTop() {
    final state = _nestedKey.currentState;
    if (state != null) {
      if (state.outerController.hasClients) {
        for (final position in state.outerController.positions) {
          position.animateTo(
            0,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
          );
        }
      }
      if (state.innerController.hasClients) {
        for (final position in state.innerController.positions) {
          position.animateTo(
            0,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
          );
        }
      }
    }
  }

  String _seasonLabel(DateTime date) {
    return '${date.year}年${getSeasonStringByMonth(date.month)}季番';
  }

  String _seasonSymbol(DateTime date) {
    final startMonth = ((date.month - 1) ~/ 3) * 3 + 1;
    return switch (startMonth) {
      1 => '❄',
      4 => '✿',
      7 => '☀',
      _ => '🍁',
    };
  }

  void _showSeasonBottomSheet(BuildContext context) {
    final now = DateTime.now();
    final years = List.generate(20, (i) => now.year - i);
    showAdaptiveBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      maxHeightFactor: .86,
      builder: (context) => Column(
        children: [
          MaterialBottomSheetHeader(
            title: '放送季度',
            description: '正在查看 ${_seasonLabel(_controller.selectedDate)}',
            onClose: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: ListView.separated(
              padding: materialBottomSheetContentPadding,
              itemCount: years.length,
              separatorBuilder: (_, __) => const SizedBox(height: 24),
              itemBuilder: (context, index) {
                final year = years[index];
                return ContentSection(
                  title: '$year',
                  padding: const EdgeInsets.all(8),
                  child: LayoutBuilder(builder: (context, constraints) {
                    final columns =
                        MediaQuery.textScalerOf(context).scale(14) > 21 ? 2 : 4;
                    return Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (final month in [1, 4, 7, 10])
                          SizedBox(
                            width: (constraints.maxWidth - 4 * (columns - 1)) /
                                columns,
                            child: _seasonButton(
                                context, DateTime(year, month), now),
                          ),
                      ],
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _seasonButton(BuildContext context, DateTime date, DateTime now) {
    final selected = isSameSeason(_controller.selectedDate, date);
    final colors = Theme.of(context).colorScheme;
    return TextButton(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        backgroundColor:
            selected ? colors.secondaryContainer : Colors.transparent,
        foregroundColor:
            selected ? colors.onSecondaryContainer : colors.onSurface,
      ),
      onPressed: !date.isAfter(now)
          ? () {
              Navigator.of(context).pop();
              _controller.loadSeason(date);
            }
          : null,
      child: Text('${getSeasonStringByMonth(date.month)}季'),
    );
  }

  void _showOptions() {
    showAdaptiveBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      maxHeightFactor: .8,
      compactLandscapeMaxHeightFactor: 1,
      builder: (_) => _TimelineOptionsSheet(controller: _controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 7,
      initialIndex: DateTime.now().weekday - 1,
      animationDuration:
          MediaQuery.disableAnimationsOf(context) ? Duration.zero : null,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AnimePastelPalette.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(builder: (context, constraints) {
      final narrowPortrait = constraints.maxWidth < 600 &&
          constraints.maxHeight > constraints.maxWidth;
      final sidePadding = constraints.maxWidth < 600 ? 14.0 : 24.0;
      final contentWidth =
          (constraints.maxWidth - sidePadding * 2).clamp(0.0, 1400.0);
      final inset = (constraints.maxWidth - contentWidth) / 2;
      final minCardWidth = scaler.scale(16) > 24 ? 420.0 : 310.0;
      final columns =
          ((contentWidth + 12) / (minCardWidth + 12)).floor().clamp(1, 3);
      final wideWeekBar = contentWidth >= 560;

      return Observer(builder: (context) {
        final loading = _controller.isLoading;
        final failed = _controller.isTimeOut;
        final watchingIds = _controller.loadWatchingBangumiIds();
        final calendar = _controller.filterCalendar(watchingIds);
        final totalCount =
            calendar.fold<int>(0, (sum, day) => sum + day.length);
        final today = DateTime.now();
        final currentSeason = isSameSeason(_controller.selectedDate, today);
        final seasonHeader = narrowPortrait
            ? null
            : _buildSeasonHeader(
                context,
                loading: loading,
                compact: constraints.maxHeight < 500,
                totalCount: totalCount,
              );
        final weekHeight =
            _TimelineWeekSelector.heightFor(scaler, wide: wideWeekBar) + 14;
        final weekSelector = Padding(
          padding: EdgeInsets.fromLTRB(inset, 0, inset, 14),
          child: _TimelineWeekSelector(
            counts: calendar.map((day) => day.length).toList(),
            todayIndex: currentSeason ? today.weekday - 1 : null,
            isLoading: loading || failed,
          ),
        );
        return Scaffold(
          extendBody: true,
          appBar: SysAppBar(
            needTopOffset: false,
            toolbarHeight: 68,
            backgroundColor: Colors.transparent,
            title: narrowPortrait
                ? _buildSeasonPicker(context, loading: loading, inAppBar: true)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '✿ ON AIR SCHEDULE · 放送番組表',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: palette.sakura,
                        ),
                      ),
                      Text(
                        '放送时间表',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _buildWatchingFilterChip(
                  context,
                  compact: narrowPortrait,
                  active: _controller.onlyShowWatchingBangumis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _TimelineOptionsButton(
                  availableWidth: constraints.maxWidth,
                  sort: _controller.sort,
                  filterCount: _controller.activeFilterCount,
                  onPressed: _showOptions,
                ),
              ),
            ],
          ),
          body: AnimePastelBackdrop(
            child: LayoutBuilder(
              builder: (context, viewport) => NestedScrollView(
                key: _nestedKey,
                // Keep the outer viewport clamped and unstretched so tabs stay fixed.
                physics: const ClampingScrollPhysics(),
                scrollBehavior: ScrollConfiguration.of(context).copyWith(
                  overscroll: false,
                  scrollbars: false,
                ),
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  if (seasonHeader != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(inset, 2, inset, 14),
                        child: seasonHeader,
                      ),
                    ),
                  SliverOverlapAbsorber(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context),
                    sliver: SliverPersistentHeader(
                      pinned: true,
                      delegate: _WeekHeaderDelegate(
                        height: weekHeight,
                        color: theme.scaffoldBackgroundColor
                            .withValues(alpha: 0.92),
                        child: weekSelector,
                      ),
                    ),
                  ),
                ],
                body: loading && calendar.every((day) => day.isEmpty)
                    ? _buildLoading(viewport.maxHeight, weekHeight)
                    : failed
                        ? _TimelineScrollView(
                            slivers: [
                              SliverPadding(
                                padding: const EdgeInsets.all(24),
                                sliver: SliverToBoxAdapter(
                                  child: BangumiMirrorErrorWidget(
                                    onRetry: () => _controller
                                        .loadSeason(_controller.selectedDate),
                                    onSettingsReturned: () {
                                      if (mounted) setState(() {});
                                    },
                                  ),
                                ),
                              ),
                            ],
                          )
                        : TabBarView(
                            children: [
                              for (var day = 0; day < 7; day++)
                                _buildDay(
                                  context,
                                  day: day,
                                  items: calendar[day],
                                  watchingIds: watchingIds,
                                  columns: columns,
                                  inset: inset,
                                  compact: narrowPortrait,
                                ),
                            ],
                          ),
              ),
            ),
          ),
        );
      });
    });
  }

  Widget _buildWatchingFilterChip(
    BuildContext context, {
    required bool compact,
    required bool active,
  }) {
    final palette = AnimePastelPalette.of(context);
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: active ? '显示全部放送番剧' : '仅看正在追的番剧',
      child: Material(
        type: MaterialType.transparency,
        shape: SuperellipseBorder(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: SuperellipseBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          onTap: () => _controller.setOnlyShowWatchingBangumis(!active),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 12,
              vertical: 8,
            ),
            decoration: ShapeDecoration(
              gradient: active ? palette.watchingGradient : null,
              color: active ? null : palette.frameFill,
              shape: SuperellipseBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: active
                      ? Colors.white.withValues(alpha: 0.28)
                      : palette.frameBorder,
                  width: 0.9,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  active
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 15,
                  color: active ? Colors.white : palette.sakura,
                ),
                const SizedBox(width: 5),
                Text(
                  compact ? '在追' : '仅看在追',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    color: active ? Colors.white : colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(double viewportHeight, double overlapHeight) {
    return LayoutBuilder(builder: (context, constraints) {
      // Center loading in the full viewport, including the scroll headers.
      final contentHeight =
          (constraints.maxHeight - overlapHeight).clamp(0.0, double.infinity);
      final headerHeight = viewportHeight - contentHeight;
      final bottomInset = headerHeight.clamp(
          0.0, (contentHeight - 48).clamp(0.0, double.infinity));
      return _TimelineScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: const Center(child: LoadingIndicator()),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSeasonPicker(BuildContext context,
      {required bool loading, bool compact = false, bool inAppBar = false}) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final palette = AnimePastelPalette.of(context);
    final label = _seasonLabel(_controller.selectedDate);
    final symbol = _seasonSymbol(_controller.selectedDate);
    final style = inAppBar
        ? theme.textTheme.titleMedium
        : compact || MediaQuery.textScalerOf(context).scale(16) > 24
            ? theme.textTheme.titleLarge
            : theme.textTheme.headlineSmall;
    return Semantics(
      label: '切换放送季度，$label',
      button: true,
      enabled: !loading,
      onTap: loading ? null : () => _showSeasonBottomSheet(context),
      excludeSemantics: true,
      child: Tooltip(
        message: '切换放送季度',
        child: InkWell(
          onTap: loading ? null : () => _showSeasonBottomSheet(context),
          customBorder:
              SuperellipseBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DecoratedBox(
                  decoration: ShapeDecoration(
                    color: palette.sakuraSoft,
                    shape: SuperellipseBorder(
                      borderRadius: BorderRadius.circular(11),
                      side: BorderSide(color: palette.frameBorder, width: 0.8),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: inAppBar ? 7 : 10,
                      vertical: inAppBar ? 3 : 5,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          inAppBar ? symbol : '$symbol 切换季度',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: palette.sakura,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.expand_more_rounded,
                          size: 16,
                          color: palette.sakura,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeasonHeader(
    BuildContext context, {
    required bool loading,
    required bool compact,
    required int totalCount,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final date = _controller.selectedDate;
    final startMonth = ((date.month - 1) ~/ 3) * 3 + 1;
    final subtitle = loading
        ? '正在加载放送时间表…'
        : '$startMonth — ${startMonth + 2} 月 · 每周放送${totalCount > 0 ? ' · 共 $totalCount 部' : ''}';
    return Row(
      children: [
        Flexible(
          child: _buildSeasonPicker(context, loading: loading, compact: compact),
        ),
        if (!compact) ...[
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDay(
    BuildContext context, {
    required int day,
    required List<BangumiItem> items,
    required Set<int> watchingIds,
    required int columns,
    required double inset,
    required bool compact,
  }) {
    final cardHeight = BangumiTimelineCard.heightFor(
        MediaQuery.textScalerOf(context),
        compact: compact);
    final rawCalendar = _controller.bangumiCalendar;
    final filteredOut = day < rawCalendar.length && rawCalendar[day].isNotEmpty;
    return _TimelineScrollView(
      key: PageStorageKey('timeline-day-$day'),
      slivers: [
        if (items.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: inset),
              child: GeneralEmptyState(
                icon: filteredOut
                    ? Icons.filter_alt_off_rounded
                    : Icons.event_available_rounded,
                title: filteredOut ? '没有符合筛选的番剧' : '这一天暂无放送',
                actions: [
                  if (filteredOut)
                    StateActionButton.tonal(
                      onPressed: _controller.clearFilters,
                      text: '清除筛选',
                    ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              inset,
              0,
              inset,
              12.0 + MediaQuery.paddingOf(context).bottom,
            ),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 11,
                crossAxisSpacing: 11,
                mainAxisExtent: cardHeight,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = items[index];
                  return BangumiTimelineCard(
                    key: ValueKey(item.id),
                    bangumiItem: item,
                    compact: compact,
                    showRating: _showRating,
                    isWatching: watchingIds.contains(item.id),
                    onTap: () => context.pushNamed('/info/', arguments: item),
                  );
                },
                childCount: items.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _TimelineScrollView extends StatelessWidget {
  const _TimelineScrollView({super.key, required this.slivers});

  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        ...slivers,
      ],
    );
  }
}

class _WeekHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _WeekHeaderDelegate({
    required this.height,
    required this.color,
    required this.child,
  });

  final double height;
  final Color color;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      ColoredBox(color: color, child: child);

  @override
  bool shouldRebuild(covariant _WeekHeaderDelegate oldDelegate) =>
      oldDelegate.height != height ||
      oldDelegate.color != color ||
      oldDelegate.child != child;
}
