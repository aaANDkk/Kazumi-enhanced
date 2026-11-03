import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/pages/info/info_header_background.dart';

class _TestImage extends ImageProvider<_TestImage> {
  _TestImage(this.image);

  final Future<ui.Image> image;

  @override
  Future<_TestImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(_TestImage key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(
        image.then((image) => ImageInfo(image: image.clone())),
      );
}

Widget _app(ImageProvider image, Size size, {double offset = 0}) => MaterialApp(
  home: Align(
    alignment: Alignment.topLeft,
    child: Transform.translate(
      offset: Offset(offset, 0),
      child: SizedBox.fromSize(
        size: size,
        child: InfoHeaderBackground(image: image),
      ),
    ),
  ),
);

ui.Image? _texture(WidgetTester tester) =>
    tester.widget<RawImage>(find.byType(RawImage)).image;

Future<void> _waitForTexture(WidgetTester tester, {ui.Image? previous}) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
    final texture = _texture(tester);
    if (texture != null && !identical(texture, previous)) return;
  }
  fail('The background did not finish rasterizing');
}

void main() {
  testWidgets('bounds actual raster pixels on a high-DPI landscape window', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(7680, 2160);
    addTearDown(tester.view.reset);
    final source = (await tester.runAsync(
      () => createTestImage(width: 64, height: 96),
    ))!;
    addTearDown(source.dispose);
    final provider = _TestImage(Future.value(source));

    await tester.pumpWidget(_app(provider, const Size(3840, 400)));
    await _waitForTexture(tester);
    expect(_texture(tester)!.width, 384);
    expect(_texture(tester)!.height, 40);
    expect(find.byType(ImageFiltered), findsNothing);

    // Translating the route must reuse the finished pixels, not rerun a blur.
    final texture = _texture(tester);
    for (final offset in [100.0, 300.0, 600.0, 0.0]) {
      await tester.pumpWidget(
        _app(provider, const Size(3840, 400), offset: offset),
      );
      expect(identical(_texture(tester), texture), isTrue);
    }

    await tester.pumpWidget(_app(provider, const Size(390, 400)));
    await _waitForTexture(tester, previous: texture);
    expect(_texture(tester)!.width, 374);
    expect(_texture(tester)!.height, 384);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a stale image cannot replace a newer subject background', (
    tester,
  ) async {
    final source = (await tester.runAsync(
      () => createTestImage(width: 64, height: 96),
    ))!;
    addTearDown(source.dispose);
    final delayed = Completer<ui.Image>();
    await tester.pumpWidget(
      _app(_TestImage(delayed.future), const Size(800, 400)),
    );
    await tester.pumpWidget(
      _app(_TestImage(Future.value(source)), const Size(800, 400)),
    );
    await _waitForTexture(tester);
    final texture = _texture(tester);
    delayed.complete(source);
    await tester.pump();
    expect(identical(_texture(tester), texture), isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'leaving before the source loads does not update disposed state',
    (tester) async {
      final source = (await tester.runAsync(
        () => createTestImage(width: 64, height: 96),
      ))!;
      addTearDown(source.dispose);
      final delayed = Completer<ui.Image>();
      await tester.pumpWidget(
        _app(_TestImage(delayed.future), const Size(800, 400)),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      delayed.complete(source);
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
