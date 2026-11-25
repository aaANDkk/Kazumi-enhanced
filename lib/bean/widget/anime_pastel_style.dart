import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:kazumi/modules/collect/collect_type.dart';
import 'package:kazumi/utils/superellipse.dart';

/// Shared visual tokens and pastel anime UI primitives for Kazumi's
/// "Kawaii Pastel Glass" (轻樱手账风) redesign across Popular, Timeline, and Collect.
class AnimePastelPalette {
  const AnimePastelPalette({
    required this.isDark,
    required this.sakura,
    required this.sakuraSoft,
    required this.peach,
    required this.sky,
    required this.frameFill,
    required this.frameBorder,
    required this.watchingFillTop,
    required this.watchingFillBottom,
    required this.watchingBorder,
    required this.toolbarFill,
    required this.toolbarBorder,
    required this.tagFill,
    required this.tagText,
    required this.scoreBg,
    required this.scoreFg,
    required this.scoreStar,
    required this.ribbonStart,
    required this.ribbonEnd,
    required this.watchingStart,
    required this.watchingEnd,
    required this.subtext,
  });

  final bool isDark;
  final Color sakura;
  final Color sakuraSoft;
  final Color peach;
  final Color sky;
  final Color frameFill;
  final Color frameBorder;
  final Color watchingFillTop;
  final Color watchingFillBottom;
  final Color watchingBorder;
  final Color toolbarFill;
  final Color toolbarBorder;
  final Color tagFill;
  final Color tagText;
  final Color scoreBg;
  final Color scoreFg;
  final Color scoreStar;
  final Color ribbonStart;
  final Color ribbonEnd;
  final Color watchingStart;
  final Color watchingEnd;
  final Color subtext;

  factory AnimePastelPalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (isDark) {
      const sakura = Color(0xFFFF88B8);
      const peach = Color(0xFFFFAE8C);
      const sky = Color(0xFF84C4FF);
      return AnimePastelPalette(
        isDark: true,
        sakura: sakura,
        sakuraSoft: const Color(0xFF3A2332),
        peach: peach,
        sky: sky,
        frameFill: Color.alphaBlend(
          sakura.withValues(alpha: 0.06),
          colors.surfaceContainerLow,
        ),
        frameBorder: sakura.withValues(alpha: 0.22),
        watchingFillTop: Color.alphaBlend(
          sakura.withValues(alpha: 0.16),
          colors.surfaceContainerLow,
        ),
        watchingFillBottom: Color.alphaBlend(
          sky.withValues(alpha: 0.06),
          colors.surfaceContainerLow,
        ),
        watchingBorder: sakura.withValues(alpha: 0.48),
        toolbarFill: Color.alphaBlend(
          sakura.withValues(alpha: 0.07),
          colors.surfaceContainerLow,
        ),
        toolbarBorder: sakura.withValues(alpha: 0.18),
        tagFill: Color.alphaBlend(
          sakura.withValues(alpha: 0.12),
          colors.surfaceContainerHigh,
        ),
        tagText: const Color(0xFFF6D5E4),
        scoreBg: const Color(0xE8281F27),
        scoreFg: const Color(0xFFFFD479),
        scoreStar: const Color(0xFFFFC54D),
        ribbonStart: const Color(0xFFFF68A2),
        ribbonEnd: const Color(0xFFFF9878),
        watchingStart: const Color(0xFFE95690),
        watchingEnd: const Color(0xFFFF86A8),
        subtext: colors.onSurfaceVariant.withValues(alpha: 0.78),
      );
    }

    const sakura = Color(0xFFE05288);
    const peach = Color(0xFFF28E6B);
    const sky = Color(0xFF5DA9EE);
    return AnimePastelPalette(
      isDark: false,
      sakura: sakura,
      sakuraSoft: const Color(0xFFFDEAF2),
      peach: peach,
      sky: sky,
      frameFill: Color.alphaBlend(
        sakura.withValues(alpha: 0.025),
        Colors.white,
      ),
      frameBorder: sakura.withValues(alpha: 0.18),
      watchingFillTop: const Color(0xFFFFF3F8),
      watchingFillBottom: const Color(0xFFFFFFFF),
      watchingBorder: sakura.withValues(alpha: 0.44),
      toolbarFill: Color.alphaBlend(
        sakura.withValues(alpha: 0.055),
        colors.surfaceContainerLow,
      ),
      toolbarBorder: sakura.withValues(alpha: 0.15),
      tagFill: const Color(0xFFFCECF3),
      tagText: const Color(0xFF9C315E),
      scoreBg: const Color(0xF0FFFDF7),
      scoreFg: const Color(0xFF9A4E0B),
      scoreStar: const Color(0xFFEB9B16),
      ribbonStart: const Color(0xFFFF6EA5),
      ribbonEnd: const Color(0xFFFF9A7B),
      watchingStart: const Color(0xFFE8528C),
      watchingEnd: const Color(0xFFFF82A8),
      subtext: colors.onSurfaceVariant.withValues(alpha: 0.78),
    );
  }

  LinearGradient get ribbonGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [ribbonStart, ribbonEnd],
      );

  LinearGradient get watchingGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [watchingStart, watchingEnd],
      );

  AnimeStatusStyle statusStyle(CollectType type) {
    return switch (type) {
      CollectType.watching => const AnimeStatusStyle(
          bg: Color(0xE8E8548E),
          fg: Color(0xFFFFF5F9),
          icon: Icons.favorite_rounded,
          symbol: '♥',
        ),
      CollectType.planToWatch => const AnimeStatusStyle(
          bg: Color(0xE8DE8718),
          fg: Color(0xFFFFF9EC),
          icon: Icons.auto_awesome_rounded,
          symbol: '✦',
        ),
      CollectType.watched => const AnimeStatusStyle(
          bg: Color(0xE81C8C7B),
          fg: Color(0xFFE9FFF9),
          icon: Icons.check_rounded,
          symbol: '✓',
        ),
      CollectType.onHold => const AnimeStatusStyle(
          bg: Color(0xE87A56BD),
          fg: Color(0xFFF6F0FF),
          icon: Icons.pause_rounded,
          symbol: '❚❚',
        ),
      CollectType.abandoned => const AnimeStatusStyle(
          bg: Color(0xE89B4652),
          fg: Color(0xFFFFEEF1),
          icon: Icons.close_rounded,
          symbol: '✕',
        ),
      CollectType.none => AnimeStatusStyle(
          bg: isDark ? const Color(0xCC2C242C) : const Color(0xCC5A4D58),
          fg: Colors.white,
          icon: Icons.bookmark_border_rounded,
          symbol: '○',
        ),
    };
  }
}

class AnimeStatusStyle {
  const AnimeStatusStyle({
    required this.bg,
    required this.fg,
    required this.icon,
    required this.symbol,
  });

  final Color bg;
  final Color fg;
  final IconData icon;
  final String symbol;
}

/// Computes fluid responsive poster column count so landscape / desktop cards
/// stay sleek (~148–172dp wide) instead of ballooning to 220–300dp.
int animePosterColumns(
  double contentWidth, {
  required bool isPortrait,
  double spacing = 12,
  double targetWidth = 152,
}) {
  if (isPortrait) {
    if (contentWidth >= 600) {
      return ((contentWidth + spacing) / (156 + spacing)).floor().clamp(4, 6);
    }
    return 3;
  }
  return ((contentWidth + spacing) / (targetWidth + spacing))
      .floor()
      .clamp(4, 9);
}

/// Lightweight RepaintBoundary pastel sakura & sky-glow stationery backdrop.
class AnimePastelBackdrop extends StatelessWidget {
  const AnimePastelBackdrop({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = AnimePastelPalette.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _AnimePastelBackdropPainter(
                  isDark: palette.isDark,
                  sakura: palette.sakura,
                  sky: palette.sky,
                  peach: palette.peach,
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _AnimePastelBackdropPainter extends CustomPainter {
  const _AnimePastelBackdropPainter({
    required this.isDark,
    required this.sakura,
    required this.sky,
    required this.peach,
  });

  final bool isDark;
  final Color sakura;
  final Color sky;
  final Color peach;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    // Top-left soft sakura aura
    final leftCenter = Offset(size.width * 0.14, 24);
    final leftRadius = math.max(size.width * 0.42, 260.0);
    final leftPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          sakura.withValues(alpha: isDark ? 0.14 : 0.16),
          sakura.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: leftCenter, radius: leftRadius));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, math.min(size.height, 360)),
      leftPaint,
    );

    // Top-right soft sky aura
    final rightCenter = Offset(size.width * 0.88, 36);
    final rightRadius = math.max(size.width * 0.36, 220.0);
    final rightPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          sky.withValues(alpha: isDark ? 0.11 : 0.14),
          sky.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: rightCenter, radius: rightRadius));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, math.min(size.height, 340)),
      rightPaint,
    );

    // Subtle kawaii pastel sparkles in upper header band
    final sparkleLimitY = math.min(size.height, 260.0);
    final dotColors = [
      sakura.withValues(alpha: isDark ? 0.22 : 0.24),
      sky.withValues(alpha: isDark ? 0.20 : 0.24),
      peach.withValues(alpha: isDark ? 0.20 : 0.24),
    ];
    final anchors = <(double, double, double, bool)>[
      (0.08, 0.22, 3.0, false),
      (0.24, 0.14, 5.5, true),
      (0.41, 0.32, 2.5, false),
      (0.58, 0.16, 4.5, true),
      (0.73, 0.36, 3.0, false),
      (0.86, 0.18, 6.0, true),
      (0.94, 0.42, 2.5, false),
      (0.16, 0.62, 2.5, false),
      (0.66, 0.68, 4.0, true),
    ];
    for (var i = 0; i < anchors.length; i++) {
      final (fx, fy, r, isStar) = anchors[i];
      final center = Offset(size.width * fx, sparkleLimitY * fy);
      final paint = Paint()..color = dotColors[i % dotColors.length];
      if (isStar) {
        _drawFourPointStar(canvas, center, r, paint);
      } else {
        canvas.drawCircle(center, r, paint);
      }
    }
  }

  void _drawFourPointStar(
      Canvas canvas, Offset c, double radius, Paint paint) {
    final inner = radius * 0.28;
    final path = Path()
      ..moveTo(c.dx, c.dy - radius)
      ..lineTo(c.dx + inner, c.dy - inner)
      ..lineTo(c.dx + radius, c.dy)
      ..lineTo(c.dx + inner, c.dy + inner)
      ..lineTo(c.dx, c.dy + radius)
      ..lineTo(c.dx - inner, c.dy + inner)
      ..lineTo(c.dx - radius, c.dy)
      ..lineTo(c.dx - inner, c.dy - inner)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AnimePastelBackdropPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.sakura != sakura ||
        oldDelegate.sky != sky ||
        oldDelegate.peach != peach;
  }
}

/// Gradient kawaii capsule ribbon badge (e.g. `✿ 热门 No.1`, `♥ 追更中`, `✦ 奇幻`).
class AnimeRibbonBadge extends StatelessWidget {
  const AnimeRibbonBadge({
    super.key,
    required this.label,
    this.gradient,
    this.backgroundColor,
    this.foregroundColor = Colors.white,
    this.compact = false,
  });

  final String label;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color foregroundColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = AnimePastelPalette.of(context);
    return DecoratedBox(
      decoration: ShapeDecoration(
        gradient: backgroundColor == null
            ? (gradient ?? palette.ribbonGradient)
            : null,
        color: backgroundColor,
        shape: SuperellipseBorder(
          borderRadius: const BorderRadius.all(Radius.circular(1000)),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.28),
            width: 0.6,
          ),
        ),
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 7.5,
          vertical: compact ? 2 : 2.5,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compact ? 9.2 : 10.2,
            height: 1.2,
            fontWeight: FontWeight.w800,
            color: foregroundColor,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

/// Creamy translucent rating badge (`★ 9.1`).
class AnimeScoreBadge extends StatelessWidget {
  const AnimeScoreBadge({
    super.key,
    required this.score,
    this.compact = false,
  });

  final double score;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = AnimePastelPalette.of(context);
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: palette.scoreBg,
        shape: SuperellipseBorder(
          borderRadius: const BorderRadius.all(Radius.circular(1000)),
          side: BorderSide(
            color: palette.scoreStar.withValues(alpha: 0.30),
            width: 0.7,
          ),
        ),
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 5.5 : 7,
          vertical: compact ? 2 : 2.5,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              size: compact ? 11.5 : 13,
              color: palette.scoreStar,
            ),
            const SizedBox(width: 2),
            Text(
              score.toStringAsFixed(1),
              maxLines: 1,
              style: TextStyle(
                fontSize: compact ? 9.8 : 11,
                height: 1.15,
                fontWeight: FontWeight.w800,
                color: palette.scoreFg,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Soft pastel tonal chip for anime genres / metadata.
class AnimeTagPill extends StatelessWidget {
  const AnimeTagPill({
    super.key,
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final palette = AnimePastelPalette.of(context);
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: backgroundColor ?? palette.tagFill,
        shape: SuperellipseBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10.5,
            height: 1.25,
            fontWeight: FontWeight.w600,
            color: foregroundColor ?? palette.tagText,
          ),
        ),
      ),
    );
  }
}

/// Dashed G2 superellipse outline painter (used for empty watch-progress slot).
class AnimeDashedSuperellipsePainter extends CustomPainter {
  const AnimeDashedSuperellipsePainter({
    required this.color,
    required this.borderRadius,
    this.strokeWidth = 1.0,
    this.dashLength = 4.0,
    this.gapLength = 3.5,
  });

  final Color color;
  final BorderRadius borderRadius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = superellipsePath(
      rect.deflate(strokeWidth / 2),
      borderRadius,
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double next = math.min(distance + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant AnimeDashedSuperellipsePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
