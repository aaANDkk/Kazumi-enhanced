import 'dart:math' as math;
import 'dart:ui' show ClipOp;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

bool get _isDesktop => switch (defaultTargetPlatform) {
      TargetPlatform.windows ||
      TargetPlatform.linux ||
      TargetPlatform.macOS =>
        true,
      _ => false,
    };

/// Rounded superellipse that renders true G2 continuous corners on both mobile
/// (Impeller) and desktop (Skia).
///
/// Ported from FlClash (`prism_ui/lib/shape.dart`) and extended so desktop Skia
/// stroked borders also follow the analytical superellipse path instead of
/// falling back to circular `RRect` arcs.
class SuperellipseBorder extends RoundedSuperellipseBorder {
  const SuperellipseBorder({super.side, super.borderRadius});

  factory SuperellipseBorder.circular(
    double radius, {
    BorderSide side = BorderSide.none,
  }) {
    return SuperellipseBorder(
      side: side,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  static final Map<Object, Path> _pathSizeCache = <Object, Path>{};
  static const int _pathCacheLimit = 256;

  Path _getPathForSize(Size size, TextDirection? textDirection) {
    final key = Object.hash(size, borderRadius, textDirection);
    final cached = _pathSizeCache[key];
    if (cached != null) {
      return cached;
    }
    final path = super.getOuterPath(
      Offset.zero & size,
      textDirection: textDirection,
    );
    if (_pathSizeCache.length >= _pathCacheLimit) {
      _pathSizeCache.remove(_pathSizeCache.keys.first);
    }
    _pathSizeCache[key] = path;
    return path;
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    if (!_isDesktop || borderRadius == BorderRadius.zero) {
      return super.getOuterPath(rect, textDirection: textDirection);
    }
    final localPath = _getPathForSize(rect.size, textDirection);
    return rect.topLeft == Offset.zero
        ? localPath
        : localPath.shift(rect.topLeft);
  }

  @override
  void paintInterior(
    Canvas canvas,
    Rect rect,
    Paint paint, {
    TextDirection? textDirection,
  }) {
    if (!_isDesktop ||
        borderRadius == BorderRadius.zero ||
        paint.maskFilter != null) {
      super.paintInterior(canvas, rect, paint, textDirection: textDirection);
      return;
    }
    final localPath = _getPathForSize(rect.size, textDirection);
    if (rect.topLeft == Offset.zero) {
      canvas.drawPath(localPath, paint);
    } else {
      canvas.save();
      canvas.translate(rect.left, rect.top);
      canvas.drawPath(localPath, paint);
      canvas.restore();
    }
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (!_isDesktop ||
        borderRadius == BorderRadius.zero ||
        side.style == BorderStyle.none) {
      super.paint(canvas, rect, textDirection: textDirection);
      return;
    }
    final width = side.width;
    if (width == 0.0) {
      canvas.drawPath(
        getOuterPath(rect, textDirection: textDirection),
        side.toPaint(),
      );
      return;
    }
    final inset = switch (side.strokeAlign) {
      BorderSide.strokeAlignInside => width / 2,
      BorderSide.strokeAlignCenter => 0.0,
      BorderSide.strokeAlignOutside => -width / 2,
      _ => (1 - side.strokeAlign) * width / 2,
    };
    final strokeRect = rect.deflate(inset);
    if (strokeRect.isEmpty) {
      return;
    }
    final resolved = borderRadius.resolve(textDirection);
    final adjustedRadius = inset == 0.0
        ? resolved
        : BorderRadius.only(
            topLeft: _adjustRadius(resolved.topLeft, -inset),
            topRight: _adjustRadius(resolved.topRight, -inset),
            bottomLeft: _adjustRadius(resolved.bottomLeft, -inset),
            bottomRight: _adjustRadius(resolved.bottomRight, -inset),
          );
    final strokePath = SuperellipseBorder(borderRadius: adjustedRadius)
        ._getPathForSize(strokeRect.size, textDirection);
    final strokePaint = side.toPaint();
    if (strokeRect.topLeft == Offset.zero) {
      canvas.drawPath(strokePath, strokePaint);
    } else {
      canvas.save();
      canvas.translate(strokeRect.left, strokeRect.top);
      canvas.drawPath(strokePath, strokePaint);
      canvas.restore();
    }
  }

  static Radius _adjustRadius(Radius radius, double delta) {
    return Radius.elliptical(
      math.max(0.0, radius.x + delta),
      math.max(0.0, radius.y + delta),
    );
  }

  @override
  SuperellipseBorder copyWith({
    BorderSide? side,
    BorderRadiusGeometry? borderRadius,
  }) {
    return SuperellipseBorder(
      side: side ?? this.side,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return SuperellipseBorder(
      side: side.scale(t),
      borderRadius: borderRadius * t,
    );
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    final res = super.lerpFrom(a, t);
    return res is RoundedSuperellipseBorder
        ? SuperellipseBorder(side: res.side, borderRadius: res.borderRadius)
        : res;
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    final res = super.lerpTo(b, t);
    return res is RoundedSuperellipseBorder
        ? SuperellipseBorder(side: res.side, borderRadius: res.borderRadius)
        : res;
  }
}

/// Builds a true continuous superellipse [Path] for custom painters.
Path superellipsePath(
  Rect rect,
  BorderRadiusGeometry borderRadius, {
  TextDirection? textDirection,
}) {
  return SuperellipseBorder(borderRadius: borderRadius)
      .getOuterPath(rect, textDirection: textDirection);
}

/// Drop-in replacement for [ClipRRect] using continuous superellipse corners.
///
/// Uses Flutter's native [ClipRSuperellipse] on mobile (Impeller) and a cached
/// [SuperellipseBorder] [ShapeBorderClipper] on desktop (Skia).
class SuperellipseClip extends StatelessWidget {
  const SuperellipseClip({
    super.key,
    this.borderRadius = BorderRadius.zero,
    this.clipBehavior = Clip.antiAlias,
    this.child,
  });

  final BorderRadiusGeometry borderRadius;
  final Clip clipBehavior;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (borderRadius == BorderRadius.zero || clipBehavior == Clip.none) {
      return child ?? const SizedBox.shrink();
    }
    if (!_isDesktop) {
      return ClipRSuperellipse(
        borderRadius: borderRadius,
        clipBehavior: clipBehavior,
        child: child,
      );
    }
    return ClipPath(
      clipper: ShapeBorderClipper(
        shape: SuperellipseBorder(borderRadius: borderRadius),
        textDirection: Directionality.maybeOf(context),
      ),
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}

/// Drop-in replacement for [OutlineInputBorder] using [SuperellipseBorder].
class SuperellipseInputBorder extends InputBorder {
  const SuperellipseInputBorder({
    super.borderSide = const BorderSide(),
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.gapPadding = 4.0,
    this.isOutline = true,
  });

  final BorderRadius borderRadius;
  final double gapPadding;

  @override
  final bool isOutline;

  SuperellipseBorder get _shape =>
      SuperellipseBorder(borderRadius: borderRadius, side: borderSide);

  @override
  bool get preferPaintInterior => true;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(borderSide.width);

  @override
  SuperellipseInputBorder copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
    double? gapPadding,
    bool? isOutline,
  }) {
    return SuperellipseInputBorder(
      borderSide: borderSide ?? this.borderSide,
      borderRadius: borderRadius ?? this.borderRadius,
      gapPadding: gapPadding ?? this.gapPadding,
      isOutline: isOutline ?? this.isOutline,
    );
  }

  @override
  SuperellipseInputBorder scale(double t) {
    return SuperellipseInputBorder(
      borderSide: borderSide.scale(t),
      borderRadius: borderRadius * t,
      gapPadding: gapPadding * t,
      isOutline: isOutline,
    );
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _shape.getInnerPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _shape.getOuterPath(rect, textDirection: textDirection);

  @override
  void paintInterior(
    Canvas canvas,
    Rect rect,
    Paint paint, {
    TextDirection? textDirection,
  }) =>
      _shape.paintInterior(canvas, rect, paint, textDirection: textDirection);

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is SuperellipseInputBorder) {
      return SuperellipseInputBorder(
        borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
        borderRadius: BorderRadius.lerp(a.borderRadius, borderRadius, t)!,
        gapPadding: a.gapPadding + (gapPadding - a.gapPadding) * t,
        isOutline: isOutline,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is SuperellipseInputBorder) {
      return SuperellipseInputBorder(
        borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
        borderRadius: BorderRadius.lerp(borderRadius, b.borderRadius, t)!,
        gapPadding: gapPadding + (b.gapPadding - gapPadding) * t,
        isOutline: b.isOutline,
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    if (borderSide.style == BorderStyle.none) {
      return;
    }
    final clampedPercentage = gapPercentage.clamp(0.0, 1.0);
    final effectiveExtent =
        (gapExtent + gapPadding * 2.0) * clampedPercentage;
    if (gapStart == null || effectiveExtent <= 0.0) {
      _shape.paint(canvas, rect, textDirection: textDirection);
      return;
    }
    final isRtl = textDirection == TextDirection.rtl;
    final left = isRtl
        ? rect.right - gapStart - gapPadding - effectiveExtent
        : rect.left + gapStart - gapPadding;
    final cutout = Rect.fromLTWH(
      left,
      rect.top - borderSide.width - 2.0,
      effectiveExtent,
      borderSide.width * 2.0 + 4.0,
    );
    canvas.save();
    canvas.clipRect(cutout, clipOp: ClipOp.difference);
    _shape.paint(canvas, rect, textDirection: textDirection);
    canvas.restore();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SuperellipseInputBorder &&
        other.borderSide == borderSide &&
        other.borderRadius == borderRadius &&
        other.gapPadding == gapPadding &&
        other.isOutline == isOutline;
  }

  @override
  int get hashCode =>
      Object.hash(borderSide, borderRadius, gapPadding, isOutline);
}
