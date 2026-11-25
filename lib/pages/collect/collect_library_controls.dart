part of 'collect_library_view.dart';

class _CollectCategories extends StatelessWidget {
  const _CollectCategories({
    required this.controller,
    required this.selected,
    required this.count,
  });

  final TabController controller;
  final ValueListenable<CollectType?> selected;
  final int Function(CollectType?) count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final palette = AnimePastelPalette.of(context);
    final labelStyle = theme.textTheme.labelLarge?.copyWith(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
    );

    return TabBar(
      key: const PageStorageKey('collect-filter-strip'),
      controller: controller,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      dividerHeight: 0,
      indicatorSize: TabBarIndicatorSize.tab,
      indicatorPadding: const EdgeInsets.symmetric(horizontal: 2),
      indicator: ShapeDecoration(
        gradient: palette.ribbonGradient,
        shape: SuperellipseBorder(borderRadius: BorderRadius.circular(13)),
        shadows: [
          BoxShadow(
            color:
                palette.sakura.withValues(alpha: palette.isDark ? 0.24 : 0.24),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      indicatorAnimation: TabIndicatorAnimation.elastic,
      labelColor: Colors.white,
      unselectedLabelColor: colors.onSurfaceVariant,
      labelStyle: labelStyle,
      unselectedLabelStyle: labelStyle,
      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
      splashFactory: NoSplash.splashFactory,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      tabs: [
        for (final type in _collectCategories)
          Tab(
            height: 36,
            child: Semantics(
              label: '${type?.label ?? '全部'}，${count(type)} 部',
              excludeSemantics: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 11),
                child: ValueListenableBuilder(
                  valueListenable: selected,
                  builder: (context, value, _) {
                    final isSelected = value == type;
                    final numCount = count(type);
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          type?.label ?? '全部',
                          style: isSelected
                              ? const TextStyle(fontWeight: FontWeight.w800)
                              : null,
                        ),
                        const SizedBox(width: 5),
                        DecoratedBox(
                          decoration: ShapeDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.24)
                                : palette.sakura.withValues(alpha: 0.11),
                            shape: const SuperellipseBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(1000)),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5.5,
                              vertical: 1.5,
                            ),
                            child: Text(
                              '$numCount',
                              style: TextStyle(
                                fontSize: 10,
                                height: 1.15,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : palette.sakura.withValues(alpha: 0.9),
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CollectLayoutSwitch extends StatelessWidget {
  const _CollectLayoutSwitch({required this.value, required this.onChanged});

  final CollectLayout value;
  final ValueChanged<CollectLayout> onChanged;

  @override
  Widget build(BuildContext context) {
    return ConnectedButtonGroup<CollectLayout>(
      expanded: false,
      segments: [
        for (final layout in [CollectLayout.cards, CollectLayout.list])
          ButtonSegment(
            value: layout,
            tooltip: '${layout.label}布局',
            icon: Icon(layout == CollectLayout.list
                ? Icons.view_list_rounded
                : Icons.grid_view_rounded),
          ),
      ],
      selected: value,
      onSelected: onChanged,
    );
  }
}

class _CollectSortMenu extends StatelessWidget {
  const _CollectSortMenu({
    required this.value,
    required this.showLabel,
    required this.onChanged,
  });

  final CollectSort value;
  final bool showLabel;
  final ValueChanged<CollectSort> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AnimePastelPalette.of(context);
    final colors = Theme.of(context).colorScheme;
    return KazumiMenuButton(
      menuChildren: [
        for (final sort in CollectSort.values)
          KazumiMenuItem(
            selected: value == sort,
            onPressed: () => onChanged(sort),
            label: sort.label,
          ),
      ],
      builder: (context, toggle) {
        return Tooltip(
          message: '排序：${value.label}',
          child: showLabel
              ? Material(
                  type: MaterialType.transparency,
                  shape: SuperellipseBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    customBorder: SuperellipseBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: toggle,
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        color: palette.frameFill,
                        shape: SuperellipseBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: palette.frameBorder,
                            width: 0.9,
                          ),
                        ),
                      ),
                      child: SizedBox(
                        height: 38,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sort_rounded,
                                size: 17,
                                color: palette.sakura,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                value.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
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
              : IconButton(
                  onPressed: toggle,
                  icon: const Icon(Icons.sort_rounded),
                ),
        );
      },
    );
  }
}
