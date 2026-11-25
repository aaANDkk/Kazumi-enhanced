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
      return 30 + clamped.scale(13) + clamped.scale(11);
    }
    return 28 + clamped.scale(14) + clamped.scale(11);
  }

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.2);

    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 560;
      final tabHeight = heightFor(scaler, wide: wide) - 8;
      final minTabWidth = wide ? 80.0 : 42.0;
      final scrollable = constraints.maxWidth - 8 < minTabWidth * 7;

      return AnimePillTabTrack(
        isScrollable: scrollable,
        tabAlignment: scrollable ? TabAlignment.start : TabAlignment.fill,
        trackRadius: 18,
        indicatorRadius: 14,
        padding: const EdgeInsets.all(4),
        labelPadding: EdgeInsets.symmetric(horizontal: wide ? 4 : 2),
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
                          cn: day == todayIndex ? '今天' : _cnWeekdays[day],
                          countText: isLoading ? '—' : '${counts[day]}',
                        )
                      : _CompactWeekdayTabContent(
                          jp: _jpWeekdays[day],
                          countText: day == todayIndex
                              ? '今'
                              : (isLoading ? '—' : '${counts[day]}'),
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
  });

  final String jp;
  final String cn;
  final String countText;

  @override
  Widget build(BuildContext context) {
    final fg = DefaultTextStyle.of(context).style.color ??
        Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          jp,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: fg,
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
                  fontSize: 11.5,
                  height: 1.15,
                  color: fg,
                ),
              ),
              Text(
                countText,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.15,
                  fontWeight: FontWeight.w500,
                  color: fg.withValues(alpha: 0.78),
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
  });

  final String jp;
  final String countText;

  @override
  Widget build(BuildContext context) {
    final fg = DefaultTextStyle.of(context).style.color ??
        Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          jp,
          style: TextStyle(
            fontSize: 13,
            height: 1.15,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          countText,
          style: TextStyle(
            fontSize: 9.8,
            height: 1.1,
            fontWeight: FontWeight.w500,
            color: fg.withValues(alpha: 0.8),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
