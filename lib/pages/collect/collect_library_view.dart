import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kazumi/bean/card/network_img_layer.dart';
import 'package:kazumi/bean/widget/anime_pastel_style.dart';
import 'package:kazumi/bean/widget/connected_button_group.dart';
import 'package:kazumi/bean/widget/empty_state_widget.dart';
import 'package:kazumi/bean/widget/kazumi_menu.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/collect/collect_layout.dart';
import 'package:kazumi/modules/collect/collect_module.dart';
import 'package:kazumi/modules/collect/collect_type.dart';
import 'package:kazumi/modules/history/history_module.dart';
import 'package:kazumi/pages/collect/collect_library_query.dart';
import 'package:kazumi/utils/superellipse.dart';

part 'collect_library_card.dart';
part 'collect_library_controls.dart';

const _collectCategories = <CollectType?>[
  null,
  CollectType.watching,
  CollectType.planToWatch,
  CollectType.watched,
  CollectType.onHold,
  CollectType.abandoned,
];

class CollectLibraryView extends StatefulWidget {
  const CollectLibraryView({
    super.key,
    required this.entries,
    this.watchProgressMap = const <int, History>{},
    required this.showRating,
    required this.onOpen,
    required this.onChangeType,
    required this.canEdit,
    required this.layout,
    required this.onLayoutChanged,
  });

  final List<CollectedBangumi> entries;
  final Map<int, History> watchProgressMap;
  final bool showRating;
  final ValueChanged<BangumiItem> onOpen;
  final void Function(BangumiItem, CollectType) onChangeType;
  final bool Function(BangumiItem) canEdit;
  final CollectLayout layout;
  final ValueChanged<CollectLayout> onLayoutChanged;

  @override
  State<CollectLibraryView> createState() => CollectLibraryViewState();
}

class CollectLibraryViewState extends State<CollectLibraryView>
    with TickerProviderStateMixin {
  void scrollToTop() {
    final state = _nestedScrollKey.currentState;
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

  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _libraryFocus = FocusNode();
  final _nestedScrollKey = GlobalKey<NestedScrollViewState>();
  late TabController _tabController;
  bool? _disableAnimations;
  PageStorageBucket _resultsStorage = PageStorageBucket();
  CollectSort _sort = CollectSort.recentlyChanged;
  String _query = '';
  bool _searchExpanded = false;

  // The tapped tab while a tap animates, otherwise the dominant page so swipes
  // update mid-gesture. Tab switches rebuild nothing but its listeners.
  final _selectedType = ValueNotifier<CollectType?>(CollectType.watching);

  @override
  void initState() {
    super.initState();
    _selectedType.addListener(_libraryFocus.requestFocus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (_disableAnimations == disableAnimations) return;
    if (_disableAnimations != null) {
      _tabController.dispose();
    }
    _disableAnimations = disableAnimations;
    _tabController = TabController(
      length: _collectCategories.length,
      initialIndex: _collectCategories.indexOf(_selectedType.value),
      animationDuration: disableAnimations ? Duration.zero : null,
      vsync: this,
    )
      ..addListener(_syncSelectedType)
      ..animation!.addListener(_syncSelectedType);
  }

  void _syncSelectedType() {
    final index = _tabController.indexIsChanging
        ? _tabController.index
        : _tabController.animation!.value
            .round()
            .clamp(0, _collectCategories.length - 1);
    _selectedType.value = _collectCategories[index];
  }

  @override
  void dispose() {
    _tabController.dispose();
    _selectedType.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    _libraryFocus.dispose();
    super.dispose();
  }

  void _jumpToTop() {
    final outer = _nestedScrollKey.currentState?.outerController;
    if (outer != null && outer.hasClients) outer.jumpTo(0);
  }

  void _resetResults() {
    // Reset saved offsets for unmounted categories too.
    _resultsStorage = PageStorageBucket();
    _jumpToTop();
  }

  void _focusSearch() {
    _jumpToTop();
    setState(() => _searchExpanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  void _closeSearch() {
    _libraryFocus.requestFocus();
    _searchController.clear();
    setState(() {
      if (_query.isNotEmpty) _resetResults();
      _searchExpanded = false;
      _query = '';
    });
  }

  void _search(String value) {
    setState(() {
      _query = value;
      _resetResults();
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = CollectLibraryQuery(widget.entries, _query);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, control: true):
            _focusSearch,
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
            _focusSearch,
        const SingleActivator(LogicalKeyboardKey.escape): _closeSearch,
      },
      child: Focus(
        focusNode: _libraryFocus,
        autofocus: true,
        child: LayoutBuilder(builder: (context, constraints) {
          final compact = constraints.maxWidth < 600;
          final singleLineToolbar = constraints.maxWidth >= 980;
          final width = constraints.maxWidth.clamp(0.0, 1600.0);
          final inset =
              (constraints.maxWidth - width) / 2 + (compact ? 12.0 : 24.0);
          final contentWidth = constraints.maxWidth - inset * 2;
          final header = _header(
            query,
            compact: compact,
            singleLineToolbar: singleLineToolbar,
          );
          return PageStorage(
            bucket: _resultsStorage,
            child: NotificationListener<ScrollUpdateNotification>(
              onNotification: (notification) {
                if (notification.dragDetails != null &&
                    notification.metrics.axis == Axis.vertical &&
                    _searchFocus.hasFocus) {
                  _libraryFocus.requestFocus();
                }
                return false;
              },
              child: NestedScrollView(
                key: _nestedScrollKey,
                physics: const ClampingScrollPhysics(),
                scrollBehavior: ScrollConfiguration.of(context).copyWith(
                  overscroll: false,
                  scrollbars: false,
                ),
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: inset),
                    sliver: SliverToBoxAdapter(child: header),
                  ),
                ],
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    for (final type in _collectCategories)
                      ValueListenableBuilder(
                        valueListenable: _selectedType,
                        builder: (context, selected, child) => HeroMode(
                          enabled: type == selected,
                          child: child!,
                        ),
                        child: _results(query, type,
                            inset: inset, contentWidth: contentWidth),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _header(
    CollectLibraryQuery query, {
    required bool compact,
    required bool singleLineToolbar,
  }) {
    if (singleLineToolbar) {
      return Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 14),
        child: Row(
          children: [
            Expanded(
              child: _CollectCategories(
                controller: _tabController,
                selected: _selectedType,
                count: query.count,
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(width: 196, child: _compactSearchField()),
            const SizedBox(width: 8),
            _CollectSortMenu(
              value: _sort,
              showLabel: true,
              onChanged: (value) => setState(() {
                _sort = value;
                _resetResults();
              }),
            ),
            const SizedBox(width: 6),
            _CollectLayoutSwitch(
              value: widget.layout,
              onChanged: (layout) {
                if (layout != widget.layout) _resetResults();
                widget.onLayoutChanged(layout);
              },
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: _CollectCategories(
            controller: _tabController,
            selected: _selectedType,
            count: query.count,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            if (!compact)
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: _compactSearchField(),
                  ),
                ),
              )
            else
              Expanded(child: _countLabel(query)),
            const SizedBox(width: 10),
            _CollectSortMenu(
              value: _sort,
              showLabel: !compact,
              onChanged: (value) => setState(() {
                _sort = value;
                _resetResults();
              }),
            ),
            if (compact)
              IconButton(
                tooltip: _searchExpanded ? '收起搜索' : '搜索收藏',
                isSelected: _searchExpanded,
                selectedIcon: const Icon(Icons.search_off_rounded),
                icon: const Icon(Icons.search_rounded),
                onPressed: _searchExpanded ? _closeSearch : _focusSearch,
              ),
            const SizedBox(width: 6),
            _CollectLayoutSwitch(
              value: widget.layout,
              onChanged: (layout) {
                if (layout != widget.layout) _resetResults();
                widget.onLayoutChanged(layout);
              },
            ),
          ],
        ),
        if (compact && _searchExpanded) ...[
          const SizedBox(height: 10),
          _compactSearchField(),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _countLabel(CollectLibraryQuery query) => ValueListenableBuilder(
        valueListenable: _selectedType,
        builder: (context, selected, _) => Text(
          '共 ${query.count(selected)} 部收藏',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
      );

  Widget _compactSearchField() {
    final palette = AnimePastelPalette.of(context);
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: '搜索收藏',
      child: SizedBox(
        height: 38,
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocus,
          onChanged: _search,
          onSubmitted: (_) => _libraryFocus.requestFocus(),
          style: TextStyle(fontSize: 13, color: colors.onSurface),
          decoration: InputDecoration(
            hintText: '筛选片名…',
            hintStyle: TextStyle(fontSize: 12.5, color: palette.subtext),
            filled: true,
            fillColor: palette.frameFill,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 18,
              color: palette.accent,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 34,
              minHeight: 34,
            ),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    tooltip: '清除搜索',
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      _searchController.clear();
                      _search('');
                    },
                    icon: const Icon(Icons.close_rounded, size: 17),
                  )
                : null,
            enabledBorder: SuperellipseInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: palette.frameBorder, width: 0.9),
            ),
            focusedBorder: SuperellipseInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: palette.accent, width: 1.3),
            ),
            border: SuperellipseInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: palette.frameBorder, width: 0.9),
            ),
          ),
        ),
      ),
    );
  }

  Widget _results(CollectLibraryQuery query, CollectType? type,
      {required double inset, required double contentWidth}) {
    return Builder(builder: (context) {
      final entries = query.results(type, _sort);
      return ScrollbarTheme(
        data: ScrollbarTheme.of(context).copyWith(crossAxisMargin: 0),
        child: CustomScrollView(
          key: PageStorageKey('collect-results-${type?.value ?? 'all'}'),
          semanticChildCount: entries.length,
          slivers: [
            if (entries.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: inset),
                  child: _emptyState(query.count(null), type: type),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    inset, 0, inset, 24 + MediaQuery.paddingOf(context).bottom),
                sliver: widget.layout == CollectLayout.cards
                    ? _grid(entries, contentWidth, type: type)
                    : _list(entries, contentWidth),
              ),
          ],
        ),
      );
    });
  }

  Widget _list(List<CollectedBangumi> entries, double contentWidth) {
    const spacing = 12.0;
    final textScale = (MediaQuery.textScalerOf(context).scale(14) / 14)
        .clamp(1.0, double.infinity);
    final minWidth = 310 + 140 * (textScale - 1);
    final preferredWidth = 420 + 140 * (textScale - 1);
    final maxColumns =
        ((contentWidth + spacing) / (minWidth + spacing)).floor().clamp(1, 3);
    final columns = ((contentWidth + spacing) / (preferredWidth + spacing))
        .ceil()
        .clamp(1, maxColumns);

    Widget tile(int index) {
      final entry = entries[index];
      return IndexedSemantics(
        index: index,
        child: _CollectListTile(
          key: ValueKey('collect-${entry.bangumiItem.id}'),
          entry: entry,
          history: widget.watchProgressMap[entry.bangumiItem.id],
          showRating: widget.showRating,
          onOpen: () => widget.onOpen(entry.bangumiItem),
          onChangeType: _changeTypeFor(entry),
        ),
      );
    }

    return SliverList.builder(
      itemCount: (entries.length + columns - 1) ~/ columns,
      addSemanticIndexes: false,
      itemBuilder: (context, row) {
        final first = row * columns;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: columns == 1
              ? tile(first)
              : IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: spacing,
                    children: [
                      for (var column = 0; column < columns; column++)
                        Expanded(
                          child: first + column < entries.length
                              ? tile(first + column)
                              : const SizedBox(),
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  ValueChanged<CollectType>? _changeTypeFor(CollectedBangumi entry) =>
      widget.canEdit(entry.bangumiItem)
          ? (type) => widget.onChangeType(entry.bangumiItem, type)
          : null;

  Widget _grid(List<CollectedBangumi> entries, double contentWidth,
      {required CollectType? type}) {
    final portrait = MediaQuery.orientationOf(context) == Orientation.portrait;
    final compact = contentWidth < 520;
    final spacing = compact ? 9.0 : 12.0;
    final scaler = MediaQuery.textScalerOf(context);
    final columns = animePosterColumns(
      contentWidth,
      isPortrait: portrait,
      spacing: spacing,
      targetWidth: 152.0,
    );
    final width = (contentWidth - spacing * (columns - 1)) / columns;
    return SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        mainAxisExtent:
            _CollectPosterCard.extent(width, scaler, compact: compact),
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _CollectPosterCard(
          key: ValueKey('collect-${entry.bangumiItem.id}'),
          entry: entry,
          history: widget.watchProgressMap[entry.bangumiItem.id],
          showRating: widget.showRating,
          showStatus: type == null,
          compact: compact,
          onOpen: () => widget.onOpen(entry.bangumiItem),
          onChangeType: _changeTypeFor(entry),
        );
      },
    );
  }

  Widget _emptyState(int matchCount, {required CollectType? type}) {
    final searching = _query.trim().isNotEmpty;
    final String title;

    if (searching) {
      title = matchCount > 0 ? '当前分类没有匹配的番剧' : '没有找到匹配的番剧';
    } else if (matchCount == 0) {
      title = '还没有收藏的番剧';
    } else {
      title = switch (type) {
        CollectType.watching => '还没有在追的番剧',
        CollectType.planToWatch => '还没有想看的番剧',
        CollectType.watched => '还没有看过的番剧',
        CollectType.onHold => '没有搁置的番剧',
        CollectType.abandoned => '没有弃追的番剧',
        _ => '还没有收藏的番剧',
      };
    }
    return GeneralEmptyState(
      icon: searching ? Icons.search_off_rounded : Icons.video_library_outlined,
      title: title,
    );
  }
}
