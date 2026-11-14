import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/bean/widget/app_icon.dart';
import 'package:kazumi/bean/widget/play_pause_icon.dart';
import 'package:kazumi/utils/reicon_mapper.dart';

void main() {
  test('every mapped icon resolves to valid Reicon SVG markup', () {
    expect(ReiconMapper.entries, isNotEmpty);
    for (final entry in ReiconMapper.entries) {
      final svg = ReiconMapper.resolveSvgByName(
        entry.value.name,
        filled: entry.value.filled,
      );
      expect(
        svg,
        isNotNull,
        reason: 'Missing Reicon SVG for ${entry.value.name} '
            '(filled: ${entry.value.filled})',
      );
      expect(svg, contains('<svg'));
      expect(svg, contains('</svg>'));
    }
  });

  test('navigation and state icons preserve outline vs filled semantics', () {
    expect(ReiconMapper.resolveSpec(Icons.home_outlined)?.filled, isFalse);
    expect(ReiconMapper.resolveSpec(Icons.home)?.filled, isTrue);
    expect(ReiconMapper.resolveSpec(Icons.favorite_border)?.filled, isFalse);
    expect(ReiconMapper.resolveSpec(Icons.favorite)?.filled, isTrue);
    final outlineClock = ReiconMapper.resolveSpec(Icons.access_time_outlined);
    final filledClock = ReiconMapper.resolveSpec(Icons.access_time_filled);
    expect(outlineClock?.filled, isFalse);
    expect(filledClock?.filled, isTrue);
    expect(outlineClock?.name, equals(filledClock?.name));
    expect(
      ReiconMapper.resolveSvg(Icons.access_time_outlined),
      isNot(equals(ReiconMapper.resolveSvg(Icons.access_time_filled))),
    );
    expect(ReiconMapper.resolveSpec(Icons.person_outline)?.filled, isFalse);
    expect(ReiconMapper.resolveSpec(Icons.person)?.filled, isTrue);
    expect(ReiconMapper.resolveSpec(Icons.settings_outlined)?.filled, isFalse);
    expect(ReiconMapper.resolveSpec(Icons.settings_rounded)?.filled, isFalse);
    expect(ReiconMapper.resolveSpec(Icons.extension_rounded)?.filled, isFalse);
    expect(
      ReiconMapper.resolveSpec(Icons.drag_indicator_rounded)?.name,
      equals('reorder'),
    );
    expect(ReiconMapper.resolveSpec(Icons.more_horiz_rounded)?.filled, isTrue);
    expect(ReiconMapper.resolveSpec(Icons.tune_rounded)?.name, equals('setting4'));
    expect(ReiconMapper.resolveSpec(Icons.star_rounded)?.filled, isTrue);
  });

  testWidgets('AppIcon preserves requested size inside oversized constraints',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SizedBox.square(
                dimension: 72,
                child: AppIcon(Icons.image_search_rounded, size: 31.68),
              ),
              SizedBox.square(
                dimension: 48,
                child: AppIcon(Icons.drag_indicator_rounded, size: 24),
              ),
              TextField(
                decoration: InputDecoration(
                  prefixIcon: AppIcon(Icons.search_rounded),
                ),
              ),
              AppIcon(Icons.access_time_outlined, size: 24),
              AppIcon(Icons.access_time_filled, size: 24),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final svgs = tester.widgetList<SvgPicture>(find.byType(SvgPicture)).toList();
    expect(svgs, hasLength(5));
    final badgeSvgSize = tester.getSize(find.byType(SvgPicture).at(0));
    final dragSvgSize = tester.getSize(find.byType(SvgPicture).at(1));
    final searchSvgSize = tester.getSize(find.byType(SvgPicture).at(2));
    expect(badgeSvgSize.width, lessThan(32));
    expect(badgeSvgSize.height, lessThan(32));
    expect(dragSvgSize.width, lessThan(24));
    expect(searchSvgSize.width, lessThan(24));
  });

  testWidgets('AppIcon renders SvgPicture for mapped icons and falls back cleanly',
      (tester) async {
    const unmapped = IconData(0xF0001, fontFamily: 'CustomTestFont');

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              AppIcon(Icons.home, size: 22, color: Colors.red),
              AppIcon(unmapped, size: 18),
              AppIcon(null, size: 16),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.byIcon(unmapped), findsOneWidget);
  });

  testWidgets('PlayPauseIcon toggles between Reicon play and pause',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PlayPauseIcon(playing: false, iconSize: 24),
        ),
      ),
    );
    expect(find.byType(AppIcon), findsOneWidget);
    expect(tester.widget<AppIcon>(find.byType(AppIcon)).icon,
        equals(Icons.play_arrow_rounded));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PlayPauseIcon(playing: true, iconSize: 24),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<AppIcon>(find.byType(AppIcon)).icon,
        equals(Icons.pause_rounded));
  });
}
