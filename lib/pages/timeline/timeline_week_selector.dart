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
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.2);

    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 560;
      final tabHeight = heightFor(scaler, wide: wide);
      final minTabWidth = wide ? 80.0 : 44.0;
      final spacing = wide ? 7.0 : 6.0;
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
          final inner = wide
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _jpWeekdays[day],
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: fgColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isToday ? '今天' : _cnWeekdays[day],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                height: 1.15,
                                fontWeight: selection > 0.5 || isToday
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: fgColor,
                              ),
                            ),
                            Text(
                              countText,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 10,
                                height: 1.15,
                                fontWeight: FontWeight.w600,
                                color: fgColor.withValues(alpha: 0.78),
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          ],
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
