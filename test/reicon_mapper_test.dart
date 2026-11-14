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
    expect(
      ReiconMapper.resolveSpec(Icons.access_time_outlined)?.filled,
      isFalse,
    );
    expect(
      ReiconMapper.resolveSpec(Icons.access_time_filled)?.filled,
      isTrue,
    );
    expect(ReiconMapper.resolveSpec(Icons.person_outline)?.filled, isFalse);
    expect(ReiconMapper.resolveSpec(Icons.person)?.filled, isTrue);
    expect(ReiconMapper.resolveSpec(Icons.settings_outlined)?.filled, isFalse);
    expect(ReiconMapper.resolveSpec(Icons.settings_rounded)?.filled, isTrue);
    expect(ReiconMapper.resolveSpec(Icons.star_rounded)?.filled, isTrue);
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
