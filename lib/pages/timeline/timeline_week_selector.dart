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
      return 28 + clamped.scale(13) + clamped.scale(11);
    }
    return 26 + clamped.scale(14) + clamped.scale(11);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final palette = AnimePastelPalette.of(context);
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.2);

    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 560;
      final tabHeight = heightFor(scaler, wide: wide) - 10;
      final minTabWidth = wide ? 76.0 : 42.0;
      final scrollable = constraints.maxWidth - 10 < minTabWidth * 7;

      return DecoratedBox(
        decoration: ShapeDecoration(
          color: palette.toolbarFill,
          shape: SuperellipseBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: palette.toolbarBorder, width: 0.9),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: TabBar(
            isScrollable: scrollable,
            tabAlignment: scrollable ? TabAlignment.start : TabAlignment.fill,
            dividerHeight: 0,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: ShapeDecoration(
              gradient: palette.ribbonGradient,
              shape: SuperellipseBorder(
                borderRadius: BorderRadius.circular(17),
              ),
              shadows: [
                BoxShadow(
                  color: palette.sakura
                      .withValues(alpha: palette.isDark ? 0.25 : 0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            indicatorAnimation: TabIndicatorAnimation.elastic,
            labelColor: Colors.white,
            unselectedLabelColor: colors.onSurfaceVariant,
            labelPadding: EdgeInsets.symmetric(horizontal: wide ? 4 : 2),
            labelStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            overlayColor: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.hovered) ||
                        states.contains(WidgetState.focused)
                    ? palette.sakura.withValues(alpha: 0.08)
                    : null),
            splashBorderRadius: BorderRadius.circular(18),
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
                      width: scrollable ? minTabWidth : null,
                      child: wide
                          ? _WideWeekdayTabContent(
                              jp: _jpWeekdays[day],
                              cn: day == todayIndex
                                  ? '✦ 今日'
                                  : _cnWeekdays[day],
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
          ),
        ),
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
    final fg = DefaultTextStyle.of(context).style.color ??
        Theme.of(context).colorScheme.onSurfaceVariant;
    final isSelected = fg == Colors.white;
    final palette = AnimePastelPalette.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: ShapeDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.22)
                : (isToday
                    ? palette.sakura.withValues(alpha: 0.16)
                    : palette.sakura.withValues(alpha: 0.08)),
            shape: SuperellipseBorder(borderRadius: BorderRadius.circular(9)),
          ),
          child: SizedBox(
            width: 26,
            height: 26,
            child: Center(
              child: Text(
                jp,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: isSelected
                      ? Colors.white
                      : (isToday ? palette.sakura : fg),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 7),
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
                  fontWeight:
                      isSelected || isToday ? FontWeight.w800 : FontWeight.w600,
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
    final fg = DefaultTextStyle.of(context).style.color ??
        Theme.of(context).colorScheme.onSurfaceVariant;
    final isSelected = fg == Colors.white;
    final palette = AnimePastelPalette.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          jp,
          style: TextStyle(
            fontSize: 13,
            height: 1.15,
            fontWeight: FontWeight.w800,
            color:
                isSelected ? Colors.white : (isToday ? palette.sakura : fg),
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
    );
  }
}
