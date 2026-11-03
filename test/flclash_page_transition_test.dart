import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/bean/widget/flclash_page_transition.dart';

class _CountingPainter extends CustomPainter {
  _CountingPainter(Listenable repaint) : super(repaint: repaint);
  var paints = 0;

  @override
  void paint(Canvas canvas, Size size) {
    paints++;
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.blue);
  }

  @override
  bool shouldRepaint(_CountingPainter oldDelegate) => false;
}

void main() {
  const transitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FlClashPageTransitionsBuilder(),
      TargetPlatform.windows: FlClashPageTransitionsBuilder(),
    },
  );

  testWidgets('landscape push and pop freeze child paints into one snapshot', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final navigator = GlobalKey<NavigatorState>();
    final repaint = ChangeNotifier();
    addTearDown(repaint.dispose);
    final painter = _CountingPainter(repaint);
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        theme: ThemeData(
          platform: TargetPlatform.windows,
          pageTransitionsTheme: transitions,
        ),
        home: const Scaffold(body: Text('home')),
      ),
    );
    await tester.pumpAndSettle();
    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            body: CustomPaint(painter: painter, child: const SizedBox.expand()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 32));
    final paints = painter.paints;
    expect(paints, greaterThan(0));
    expect(
      tester
          .widgetList<SnapshotWidget>(find.byType(SnapshotWidget))
          .where((widget) => widget.controller.allowSnapshotting),
      isNotEmpty,
    );
    for (var i = 0; i < 8; i++) {
      repaint.notifyListeners();
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(
      painter.paints,
      paints,
      reason: 'image fades or ink must not repaint the sliding page',
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<SnapshotWidget>(find.byType(SnapshotWidget))
          .every((widget) => !widget.controller.allowSnapshotting),
      isTrue,
    );
    repaint.notifyListeners();
    await tester.pump();
    expect(painter.paints, greaterThan(paints));

    navigator.currentState!.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 32));
    final popPaints = painter.paints;
    for (var i = 0; i < 5; i++) {
      repaint.notifyListeners();
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(painter.paints, popPaints);
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('snapshots wait for Hero placeholders and release at landing', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    final repaint = ChangeNotifier();
    addTearDown(repaint.dispose);
    final destination = _CountingPainter(repaint);
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        theme: ThemeData(pageTransitionsTheme: transitions),
        home: const Scaffold(
          body: Hero(tag: 'cover', child: SizedBox(width: 80, height: 120)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            body: Hero(
              tag: 'cover',
              flightShuttleBuilder: (_, animation, direction, from, to) =>
                  const ColoredBox(color: Colors.red),
              child: CustomPaint(
                painter: destination,
                child: const SizedBox(width: 120, height: 180),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 64));
    expect(
      destination.paints,
      0,
      reason: 'the snapshot must contain a placeholder, not a duplicate cover',
    );
    await tester.pumpAndSettle();
    expect(destination.paints, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a route can opt out of snapshotting', (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    final repaint = ChangeNotifier();
    addTearDown(repaint.dispose);
    final painter = _CountingPainter(repaint);
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        theme: ThemeData(pageTransitionsTheme: transitions),
        home: const Scaffold(),
      ),
    );
    await tester.pumpAndSettle();
    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          allowSnapshotting: false,
          builder: (_) => Scaffold(
            body: CustomPaint(painter: painter, child: const SizedBox.expand()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 32));
    final paints = painter.paints;
    repaint.notifyListeners();
    await tester.pump(const Duration(milliseconds: 16));
    expect(painter.paints, greaterThan(paints));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
