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
      return 24 + clamped.scale(14);
    }
    return 22 + clamped.scale(14) + clamped.scale(11);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AnimePastelPalette.of(context);
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.2);

    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 560;
      final extraWide = constraints.maxWidth >= 820;
      final tabHeight = heightFor(scaler, wide: wide);
      final minTabWidth = extraWide ? 96.0 : (wide ? 72.0 : 44.0);
      final spacing = wide ? 8.0 : 6.0;
      final scrollable = constraints.maxWidth < minTabWidth * 7 + spacing * 6;

      return AnimeSeparatedTabBar(
        itemCount: 7,
        scrollable: scrollable,
        height: tabHeight,
        spacing: spacing,
        borderRadius: 12,
        semanticLabelBuilder: (day) => '${_cnWeekdays[day]}'
            '${day == todayIndex ? '，今天' : ''}'
            '${isLoading ? '，加载中' : '，${counts[day]}部'}',
        itemBuilder: (context, day, selection, fgColor) {
          final isToday = day == todayIndex;
          final countText = isLoading ? '—' : '${counts[day]}';
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

          final inner = wide
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (extraWide) ...[
                        Text(
                          _jpWeekdays[day],
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            color: fgColor.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        isToday ? '今天' : _cnWeekdays[day],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.2,
                          fontWeight: selection > 0.5 || isToday
                              ? FontWeight.w700
                              : FontWeight.w500,
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
                            countText,
                            style: TextStyle(
                              fontSize: 10,
                              height: 1.15,
                              fontWeight: FontWeight.w700,
                              color: badgeFg,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _jpWeekdays[day],
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                        color: fgColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isToday ? '今' : countText,
                      style: TextStyle(
                        fontSize: 9.8,
                        height: 1.1,
                        fontWeight:
                            isToday ? FontWeight.w800 : FontWeight.w500,
                        color: fgColor.withValues(alpha: 0.80),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                );
          return scrollable
              ? SizedBox(width: minTabWidth, child: Center(child: inner))
              : inner;
        },
      );
    });
  }
}
