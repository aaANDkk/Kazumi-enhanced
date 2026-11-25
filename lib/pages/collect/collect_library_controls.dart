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
    final palette = AnimePastelPalette.of(context);
    return AnimeSeparatedTabBar(
      key: const PageStorageKey('collect-filter-strip'),
      controller: controller,
      itemCount: _collectCategories.length,
      scrollable: true,
      height: 36,
      spacing: 7,
      borderRadius: 12,
      semanticLabelBuilder: (index) {
        final type = _collectCategories[index];
        return '${type?.label ?? '全部'}，${count(type)} 部';
      },
      itemBuilder: (context, index, selection, fgColor) {
        final type = _collectCategories[index];
        final numCount = count(type);
        final badgeBg = Color.lerp(
          palette.accent.withValues(alpha: 0.11),
          palette.onAccent.withValues(alpha: 0.22),
          selection,
        )!;
        final badgeFg = Color.lerp(
          palette.accent.withValues(alpha: 0.90),
          palette.onAccent,
          selection,
        )!;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                type?.label ?? '全部',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.2,
                  fontWeight:
                      selection > 0.5 ? FontWeight.w700 : FontWeight.w500,
                  color: fgColor,
                ),
              ),
              const SizedBox(width: 5),
              DecoratedBox(
                decoration: ShapeDecoration(
                  color: badgeBg,
                  shape: const SuperellipseBorder(
                    borderRadius: BorderRadius.all(Radius.circular(1000)),
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
                      color: badgeFg,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
                        height: 36,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 11),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sort_rounded,
                                size: 17,
                                color: palette.accent,
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
