import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/utils/superellipse.dart';
import 'package:kazumi/utils/theme.dart';

void main() {
  testWidgets(
      'SuperellipseBorder renders asymmetric corners and interpolates smoothly on desktop',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      const restRadius = BorderRadius.only(
        topLeft: Radius.circular(28),
        topRight: Radius.circular(64),
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
      );
      const restShape = SuperellipseBorder(
        borderRadius: restRadius,
        side: BorderSide(color: Colors.green, width: 1.5),
      );
      const pressedShape = SuperellipseBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: Colors.green, width: 1.5),
      );

      final lerped = ShapeBorder.lerp(restShape, pressedShape, 0.5);
      expect(lerped, isA<SuperellipseBorder>());

      await tester.pumpWidget(
        MaterialApp(
          theme: applySuperellipseTheme(
            ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
          ),
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 240,
                    height: 120,
                    decoration: const ShapeDecoration(
                      color: Colors.green,
                      shape: restShape,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SuperellipseClip(
                    borderRadius: BorderRadius.circular(16),
                    child: const SizedBox(width: 80, height: 80),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(
                    width: 220,
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: '搜索',
                        border: SuperellipseInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.byType(SuperellipseClip), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  test('applySuperellipseTheme configures global Material component shapes', () {
    final theme = applySuperellipseTheme(
      ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
    );
    expect(theme.cardTheme.shape, isA<SuperellipseBorder>());
    expect(theme.dialogTheme.shape, isA<SuperellipseBorder>());
    expect(theme.bottomSheetTheme.shape, isA<SuperellipseBorder>());
    expect(theme.popupMenuTheme.shape, isA<SuperellipseBorder>());
    expect(theme.snackBarTheme.shape, isA<SuperellipseBorder>());
    expect(theme.chipTheme.shape, isA<SuperellipseBorder>());
    expect(theme.inputDecorationTheme.border, isA<SuperellipseInputBorder>());
  });
}
