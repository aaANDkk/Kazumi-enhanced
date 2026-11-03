import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/bean/widget/route_entrance.dart';

const _cover = SizedBox(
  width: 80,
  height: 120,
  child: ColoredBox(color: Colors.blue),
);

void main() {
  testWidgets('Hero measurement must not release expensive content', (
    tester,
  ) async {
    var entered = 0;
    var builtDetailsOffstage = false;
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: const Scaffold(
          body: Hero(tag: 'cover', child: _cover),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final route = MaterialPageRoute<void>(
      builder: (context) => RouteEntrance(
        onEntered: () => entered++,
        builder: (context, hasEntered) {
          final route = ModalRoute.of(context)!;
          // This also catches enabling shimmer during the fake completed frame.
          if (route.offstage && (hasEntered || TickerMode.valuesOf(context).enabled)) {
            builtDetailsOffstage = true;
          }
          return Scaffold(
            body: Column(
              children: [
                const Hero(tag: 'cover', child: _cover),
                if (hasEntered) const Text('details'),
              ],
            ),
          );
        },
      ),
    );
    unawaited(navigator.currentState!.push(route));
    await tester.pump();
    expect(builtDetailsOffstage, isFalse);
    expect(entered, 0);
    await tester.pump(const Duration(milliseconds: 100));
    expect(entered, 0);
    expect(find.text('details'), findsNothing);
    await tester.pumpAndSettle();
    expect(entered, 1);
    expect(find.text('details'), findsOneWidget);

    // Rebuilding, covering and uncovering must not restart initialization.
    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('overlay')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(entered, 1);
  });

  testWidgets('an early back action never starts deferred work', (
    tester,
  ) async {
    var entered = 0;
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: const Scaffold(
          body: Hero(tag: 'cover', child: _cover),
        ),
      ),
    );
    await tester.pumpAndSettle();
    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => RouteEntrance(
            onEntered: () => entered++,
            builder: (_, entered) => const Scaffold(
              body: Hero(tag: 'cover', child: _cover),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 32));
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(entered, 0);
    expect(tester.takeException(), isNull);
  });
}
