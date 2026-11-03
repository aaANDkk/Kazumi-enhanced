import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:kazumi/services/logging/logger.dart';

/// Rasterize the blur once into a small texture. A RepaintBoundary around an
/// ImageFiltered widget only retains its layers, not the result of the filter;
/// moving those layers can still run a full-width blur on every raster frame.
class InfoHeaderBackground extends StatelessWidget {
  const InfoHeaderBackground({super.key, required this.image});

  final ImageProvider image;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          if (!size.isFinite || size.isEmpty) return const SizedBox.shrink();
          return Stack(
            fit: StackFit.expand,
            children: [
              _HeaderTexture(image: image, size: size),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      backgroundColor.withValues(alpha: 0.05),
                      backgroundColor.withValues(alpha: 0.65),
                      backgroundColor,
                    ],
                    stops: const [0.0, 0.75, 1.0],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderTexture extends StatefulWidget {
  const _HeaderTexture({required this.image, required this.size});

  final ImageProvider image;
  final Size size;

  @override
  State<_HeaderTexture> createState() => _HeaderTextureState();
}

class _HeaderTextureState extends State<_HeaderTexture> {
  ImageStream? _stream;
  late final ImageStreamListener _listener = ImageStreamListener(
    _onImage,
    onError: (Object error, StackTrace? stack) {
      KazumiLogger().w('Info header image load failed', error: error);
    },
  );
  ImageInfo? _source;
  ui.Image? _texture;
  int _generation = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant _HeaderTexture oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) {
      _generation++;
      _source?.dispose();
      _source = null;
      _texture?.dispose();
      _texture = null;
      _resolveImage();
    } else if (oldWidget.size != widget.size) {
      _rasterize();
    }
  }

  void _resolveImage() {
    // This is a decorative, heavily blurred image, independent of display DPR.
    final stream = ResizeImage(
      widget.image,
      width: 256,
    ).resolve(createLocalImageConfiguration(context));
    if (_stream?.key == stream.key) return;
    _stream?.removeListener(_listener);
    _stream = stream;
    stream.addListener(_listener);
  }

  void _onImage(ImageInfo image, bool synchronousCall) {
    _source?.dispose();
    _source = image;
    _rasterize();
  }

  Future<void> _rasterize() async {
    final source = _source?.image.clone();
    if (source == null) return;
    final generation = ++_generation;
    final size = widget.size;
    // Cap actual output pixels, not just widget dimensions or decode size.
    final scale = math.min(1.0, 384 / math.max(size.width, size.height));
    final width = math.max(1, (size.width * scale).round());
    final height = math.max(1, (size.height * scale).round());
    final bounds = Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.saveLayer(
      bounds,
      Paint()
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: 16 * scale,
          sigmaY: 16 * scale,
          tileMode: TileMode.clamp,
        ),
    );
    paintImage(
      canvas: canvas,
      rect: bounds,
      image: source,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.low,
    );
    canvas.restore();
    final picture = recorder.endRecording();
    try {
      final texture = await picture.toImage(width, height);
      if (!mounted || generation != _generation) {
        texture.dispose();
        return;
      }
      setState(() {
        _texture?.dispose();
        _texture = texture;
      });
    } catch (error) {
      KazumiLogger().w('Info header blur failed', error: error);
    } finally {
      picture.dispose();
      source.dispose();
    }
  }

  @override
  void dispose() {
    _generation++;
    _stream?.removeListener(_listener);
    _source?.dispose();
    _texture?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RawImage(
    image: _texture,
    fit: BoxFit.fill,
    filterQuality: FilterQuality.low,
    color: const Color.fromRGBO(255, 255, 255, 0.35),
    colorBlendMode: BlendMode.modulate,
  );
}
