part of 'timeline_page.dart';

class _TimelineWeekSelector extends StatelessWidget {
  const _TimelineWeekSelector({
    required this.counts,
    this.todayIndex,
    this.isLoading = false,
  });

  final List<int> counts;
  final int? todayIndex;
  final bool isLoading;

  static const _jpWeekdays = ['月', '火', '水', '木', '金', '土', '日'];
  static const _cnWeekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  static double heightFor(TextScaler scaler, {bool wide = false}) {
    final clamped = scaler.clamp(maxScaleFactor: 1.2);
    if (wide) {
      return 24 + clamped.scale(13) + clamped.scale(11);
    }
    return 22 + clamped.scale(14) + clamped.scale(11);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final palette = AnimePastelPalette.of(context);
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.2);

    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 560;
      final tabHeight = heightFor(scaler, wide: wide);
      final minTabWidth = wide ? 80.0 : 44.0;
      final scrollable = constraints.maxWidth < minTabWidth * 7;
      final itemGap = wide ? 3.5 : 3.0;

      return TabBar(
        isScrollable: scrollable,
        tabAlignment: scrollable ? TabAlignment.start : TabAlignment.fill,
        dividerHeight: 0,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: EdgeInsets.symmetric(horizontal: itemGap),
        indicator: ShapeDecoration(
          gradient: palette.ribbonGradient,
          shape: SuperellipseBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: palette.accent.withValues(alpha: 0.25),
              width: 0.85,
            ),
          ),
        ),
        indicatorAnimation: TabIndicatorAnimation.elastic,
        labelColor: palette.onAccent,
        unselectedLabelColor: colors.onSurfaceVariant,
        labelPadding: EdgeInsets.symmetric(horizontal: itemGap),
        labelStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        splashFactory: NoSplash.splashFactory,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        tabs: [
          for (var day = 0; day < 7; day++)
            Tab(
              height: tabHeight,
              child: Semantics(
                label: '${_cnWeekdays[day]}'
                    '${day == todayIndex ? '，今天' : ''}'
                    '${isLoading ? '，加载中' : '，${counts[day]}部'}',
                excludeSemantics: true,
                child: SizedBox(
                  width: scrollable ? minTabWidth : double.infinity,
                  height: tabHeight,
                  child: wide
                      ? _WideWeekdayTabContent(
                          jp: _jpWeekdays[day],
                          cn: day == todayIndex ? '✦ 今日' : _cnWeekdays[day],
                          countText: isLoading ? '—' : '${counts[day]}',
                          isToday: day == todayIndex,
                        )
                      : _CompactWeekdayTabContent(
                          jp: _jpWeekdays[day],
                          countText: day == todayIndex
                              ? '今'
                              : (isLoading ? '—' : '${counts[day]}'),
                          isToday: day == todayIndex,
                        ),
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _WideWeekdayTabContent extends StatelessWidget {
  const _WideWeekdayTabContent({
    required this.jp,
    required this.cn,
    required this.countText,
    required this.isToday,
  });

  final String jp;
  final String cn;
  final String countText;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final palette = AnimePastelPalette.of(context);
    final fg = DefaultTextStyle.of(context).style.color ??
        Theme.of(context).colorScheme.onSurfaceVariant;
    final isSelected = fg == palette.onAccent;

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: isSelected ? Colors.transparent : palette.frameFill,
        shape: SuperellipseBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide.none
              : BorderSide(color: palette.frameBorder, width: 0.85),
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: ShapeDecoration(
                  color: isSelected
                      ? palette.onAccent.withValues(alpha: 0.18)
                      : (isToday
                          ? palette.accent.withValues(alpha: 0.14)
                          : palette.accent.withValues(alpha: 0.08)),
                  shape: SuperellipseBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: Center(
                    child: Text(
                      jp,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? palette.onAccent
                            : (isToday ? palette.accent : fg),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cn,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.15,
                        fontWeight: isSelected || isToday
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      countText,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.15,
                        fontWeight: FontWeight.w600,
                        color: fg.withValues(alpha: isSelected ? 0.9 : 0.7),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactWeekdayTabContent extends StatelessWidget {
  const _CompactWeekdayTabContent({
    required this.jp,
    required this.countText,
    required this.isToday,
  });

  final String jp;
  final String countText;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final palette = AnimePastelPalette.of(context);
    final fg = DefaultTextStyle.of(context).style.color ??
        Theme.of(context).colorScheme.onSurfaceVariant;
    final isSelected = fg == palette.onAccent;

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: isSelected ? Colors.transparent : palette.frameFill,
        shape: SuperellipseBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide.none
              : BorderSide(color: palette.frameBorder, width: 0.85),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            jp,
            style: TextStyle(
              fontSize: 13,
              height: 1.15,
              fontWeight: FontWeight.w700,
              color: isSelected
                  ? palette.onAccent
                  : (isToday ? palette.accent : fg),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            countText,
            style: TextStyle(
              fontSize: 9.8,
              height: 1.1,
              fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
              color: fg.withValues(alpha: isSelected ? 0.92 : 0.72),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
