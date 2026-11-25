import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:kazumi/modules/collect/collect_type.dart';
import 'package:kazumi/utils/superellipse.dart';

/// Shared M3 theme-adaptive anime UI primitives for Popular, Timeline, and Collect.
///
/// Every color derives strictly from [Theme.of(context).colorScheme] so the UI
/// stays 100% harmonious with any user-chosen seed color or Monet dynamic theme.
class AnimePastelPalette {
  const AnimePastelPalette({
    required this.isDark,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.onAccentSoft,
    required this.accentSecondary,
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
    required this.subtext,
  });

  final bool isDark;
  final Color accent;
  final Color onAccent;
  final Color accentSoft;
  final Color onAccentSoft;
  final Color accentSecondary;
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
  final Color subtext;

  factory AnimePastelPalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final ribbonEnd = Color.lerp(colors.primary, colors.tertiary, 0.28) ??
        colors.primary;

    return AnimePastelPalette(
      isDark: isDark,
      accent: colors.primary,
      onAccent: colors.onPrimary,
      accentSoft: colors.primaryContainer,
      onAccentSoft: colors.onPrimaryContainer,
      accentSecondary: colors.tertiary,
      frameFill: isDark
          ? colors.surfaceContainerLow
          : Color.alphaBlend(
              colors.primary.withValues(alpha: 0.018),
              colors.surfaceContainerLowest,
            ),
      frameBorder: colors.outlineVariant.withValues(alpha: isDark ? 0.42 : 0.55),
      watchingFillTop: Color.alphaBlend(
        colors.primaryContainer.withValues(alpha: isDark ? 0.40 : 0.42),
        colors.surfaceContainerLow,
      ),
      watchingFillBottom: isDark
          ? colors.surfaceContainerLow
          : colors.surfaceContainerLowest,
      watchingBorder: colors.primary.withValues(alpha: isDark ? 0.58 : 0.44),
      toolbarFill: colors.surfaceContainerLow,
      toolbarBorder:
          colors.outlineVariant.withValues(alpha: isDark ? 0.34 : 0.45),
      tagFill: colors.secondaryContainer.withValues(alpha: isDark ? 0.52 : 0.68),
      tagText: colors.onSecondaryContainer,
      scoreBg: isDark
          ? colors.surfaceContainerHighest.withValues(alpha: 0.88)
          : colors.surface.withValues(alpha: 0.92),
      scoreFg: colors.onSurface,
      scoreStar: isDark ? const Color(0xFFFFC95C) : const Color(0xFFE09612),
      ribbonStart: colors.primary,
      ribbonEnd: ribbonEnd,
      subtext: colors.onSurfaceVariant.withValues(alpha: 0.78),
    );
  }

  LinearGradient get ribbonGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [ribbonStart, ribbonEnd],
      );

  /// Tonal status style for pills/dropdowns (harmonious with active ColorScheme).
  AnimeStatusStyle statusStyle(
    BuildContext context,
    CollectType type, {
    bool overlay = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    if (overlay) {
      return switch (type) {
        CollectType.watching => AnimeStatusStyle(
            bg: colors.primary.withValues(alpha: 0.92),
            fg: colors.onPrimary,
            icon: Icons.favorite_rounded,
            symbol: '♥',
          ),
        CollectType.planToWatch => AnimeStatusStyle(
            bg: colors.tertiary.withValues(alpha: 0.92),
            fg: colors.onTertiary,
            icon: Icons.auto_awesome_rounded,
            symbol: '✦',
          ),
        CollectType.watched => AnimeStatusStyle(
            bg: colors.secondary.withValues(alpha: 0.92),
            fg: colors.onSecondary,
            icon: Icons.check_rounded,
            symbol: '✓',
          ),
        CollectType.onHold => AnimeStatusStyle(
            bg: colors.inverseSurface.withValues(alpha: 0.84),
            fg: colors.onInverseSurface,
            icon: Icons.pause_rounded,
            symbol: '❚❚',
          ),
        CollectType.abandoned => AnimeStatusStyle(
            bg: colors.error.withValues(alpha: 0.90),
            fg: colors.onError,
            icon: Icons.close_rounded,
            symbol: '✕',
          ),
        CollectType.none => AnimeStatusStyle(
            bg: colors.inverseSurface.withValues(alpha: 0.80),
            fg: colors.onInverseSurface,
            icon: Icons.bookmark_border_rounded,
            symbol: '○',
          ),
      };
    }

    return switch (type) {
      CollectType.watching => AnimeStatusStyle(
          bg: colors.primaryContainer,
          fg: colors.onPrimaryContainer,
          icon: Icons.favorite_rounded,
          symbol: '♥',
        ),
      CollectType.planToWatch => AnimeStatusStyle(
          bg: colors.tertiaryContainer,
          fg: colors.onTertiaryContainer,
          icon: Icons.auto_awesome_rounded,
          symbol: '✦',
        ),
      CollectType.watched => AnimeStatusStyle(
          bg: colors.secondaryContainer,
          fg: colors.onSecondaryContainer,
          icon: Icons.check_rounded,
          symbol: '✓',
        ),
      CollectType.onHold => AnimeStatusStyle(
          bg: colors.surfaceContainerHighest,
          fg: colors.onSurfaceVariant,
          icon: Icons.pause_rounded,
          symbol: '❚❚',
        ),
      CollectType.abandoned => AnimeStatusStyle(
          bg: colors.errorContainer,
          fg: colors.onErrorContainer,
          icon: Icons.close_rounded,
          symbol: '✕',
        ),
      CollectType.none => AnimeStatusStyle(
          bg: colors.surfaceContainerHighest,
          fg: colors.onSurfaceVariant,
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

const _ignoredAnimeMetaTags = <String>{
  'TV',
  'WEB',
  'OVA',
  'OAD',
  '剧场版',
  '动态漫画',
  '泡面番',
  '日本',
  '中国',
  '国产',
  '欧美',
  '美国',
  '韩国',
  '动画',
  '番剧',
  '连载',
  '完结',
  '未确定',
};

/// Filters out noisy format/country tags like `TV`, `WEB`, `日本` so only
/// expressive anime genre tags appear on cards.
List<String> filterMeaningfulAnimeTags(
  Iterable<String> rawTags, {
  int limit = 3,
}) {
  final seen = <String>{};
  final result = <String>[];
  for (final raw in rawTags) {
    final cleaned = raw.trim();
    if (cleaned.isEmpty || cleaned.length > 6) continue;
    final upper = cleaned.toUpperCase();
    if (_ignoredAnimeMetaTags.contains(cleaned) ||
        _ignoredAnimeMetaTags.contains(upper)) {
      continue;
    }
    if (RegExp(r'^\d{4}年?$').hasMatch(cleaned)) continue;
    if (seen.add(cleaned)) {
      result.add(cleaned);
      if (result.length >= limit) break;
    }
  }
  return result;
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

/// Subtle, theme-harmonious radial glow backdrop (strictly follows ColorScheme).
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
                  primary: palette.accent,
                  secondary: palette.accentSecondary,
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
    required this.primary,
    required this.secondary,
  });

  final bool isDark;
  final Color primary;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final leftCenter = Offset(size.width * 0.16, 0);
    final leftRadius = math.max(size.width * 0.45, 240.0);
    final leftPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primary.withValues(alpha: isDark ? 0.09 : 0.08),
          primary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: leftCenter, radius: leftRadius));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, math.min(size.height, 260)),
      leftPaint,
    );

    final rightCenter = Offset(size.width * 0.88, 12);
    final rightRadius = math.max(size.width * 0.36, 200.0);
    final rightPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          secondary.withValues(alpha: isDark ? 0.07 : 0.06),
          secondary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: rightCenter, radius: rightRadius));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, math.min(size.height, 240)),
      rightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AnimePastelBackdropPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary;
  }
}

/// Theme-adaptive capsule ribbon badge (e.g. `TOP 1`, `♥ 在追`).
class AnimeRibbonBadge extends StatelessWidget {
  const AnimeRibbonBadge({
    super.key,
    required this.label,
    this.gradient,
    this.backgroundColor,
    this.foregroundColor,
    this.compact = false,
  });

  final String label;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = AnimePastelPalette.of(context);
    final fg = foregroundColor ?? palette.onAccent;
    return DecoratedBox(
      decoration: ShapeDecoration(
        gradient: backgroundColor == null
            ? (gradient ?? palette.ribbonGradient)
            : null,
        color: backgroundColor,
        shape: SuperellipseBorder(
          borderRadius: const BorderRadius.all(Radius.circular(1000)),
          side: BorderSide(
            color: fg.withValues(alpha: 0.22),
            width: 0.6,
          ),
        ),
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 5,
            offset: const Offset(0, 1.5),
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
            color: fg,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

/// Crisp translucent rating pill (`★ 9.1`).
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
            color: palette.frameBorder,
            width: 0.7,
          ),
        ),
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
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

/// Soft tonal chip for anime genres / metadata.
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
