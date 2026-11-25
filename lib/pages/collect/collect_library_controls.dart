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
    return AnimePillTabTrack(
      tabBarKey: const PageStorageKey('collect-filter-strip'),
      controller: controller,
      isScrollable: true,
      trackRadius: 18,
      indicatorRadius: 14,
      padding: const EdgeInsets.all(4),
      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
      tabs: [
        for (final type in _collectCategories)
          Tab(
            height: 36,
            child: Semantics(
              label: '${type?.label ?? '全部'}，${count(type)} 部',
              excludeSemantics: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ValueListenableBuilder(
                  valueListenable: selected,
                  builder: (context, value, _) {
                    final isSelected = value == type;
                    final numCount = count(type);
                    final fg = DefaultTextStyle.of(context).style.color ??
                        Theme.of(context).colorScheme.onSurfaceVariant;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          type?.label ?? '全部',
                          style: isSelected
                              ? const TextStyle(fontWeight: FontWeight.w700)
                              : null,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$numCount',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.15,
                            fontWeight: FontWeight.w600,
                            color: fg.withValues(alpha: isSelected ? 0.88 : 0.65),
                            fontFeatures: const [FontFeature.tabularFigures()],
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
                    borderRadius: BorderRadius.circular(14),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    customBorder: SuperellipseBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    onTap: toggle,
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        color: palette.cardFill,
                        shape: SuperellipseBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: SizedBox(
                        height: 38,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sort_rounded,
                                size: 17,
                                color: colors.onSurfaceVariant,
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
