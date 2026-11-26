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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (extraWide) ...[
                        AnimeCapsuleText(
                          _jpWeekdays[day],
                          fontSize: 12.5,
                          lineHeight: 1.15,
                          fontWeight: FontWeight.w800,
                          color: fgColor.withValues(alpha: 0.85),
                          overflow: TextOverflow.visible,
                        ),
                        const SizedBox(width: 4),
                      ],
                      AnimeCapsuleText(
                        isToday ? '今天' : _cnWeekdays[day],
                        fontSize: 12.5,
                        lineHeight: 1.15,
                        fontWeight: selection > 0.5 || isToday
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: fgColor,
                      ),
                      const SizedBox(width: 5),
                      AnimeCountPill(
                        label: countText,
                        backgroundColor: badgeBg,
                        foregroundColor: badgeFg,
                      ),
                    ],
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimeCapsuleText(
                      _jpWeekdays[day],
                      fontSize: 13.0,
                      lineHeight: 1.15,
                      fontWeight: FontWeight.w700,
                      color: fgColor,
                      overflow: TextOverflow.visible,
                    ),
                    const SizedBox(height: 2),
                    AnimeCapsuleText(
                      isToday ? '今' : countText,
                      fontSize: 9.8,
                      lineHeight: 1.1,
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                      color: fgColor.withValues(alpha: 0.80),
                      tabularFigures: true,
                      overflow: TextOverflow.visible,
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
