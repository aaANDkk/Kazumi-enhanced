import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:kazumi/modules/collect/collect_type.dart';
import 'package:kazumi/utils/superellipse.dart';

/// Shared M3 theme-adaptive anime UI primitives for Popular, Timeline, and Collect.
///
/// Strictly follows [Theme.of(context).colorScheme] with clean borderless M3
/// tonal surfaces (`surfaceContainerLow`) and unified G2 superellipse corners.
class AnimePastelPalette {
  const AnimePastelPalette({
    required this.isDark,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.onAccentSoft,
    required this.cardFill,
    required this.cardHoverFill,
    required this.trackFill,
    required this.tagFill,
    required this.tagText,
    required this.scoreBg,
    required this.scoreFg,
    required this.scoreStar,
    required this.subtext,
  });

  final bool isDark;
  final Color accent;
  final Color onAccent;
  final Color accentSoft;
  final Color onAccentSoft;
  final Color cardFill;
  final Color cardHoverFill;
  final Color trackFill;
  final Color tagFill;
  final Color tagText;
  final Color scoreBg;
  final Color scoreFg;
  final Color scoreStar;
  final Color subtext;

  factory AnimePastelPalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AnimePastelPalette(
      isDark: isDark,
      accent: colors.primary,
      onAccent: colors.onPrimary,
      accentSoft: colors.primaryContainer,
      onAccentSoft: colors.onPrimaryContainer,
      cardFill: colors.surfaceContainerLow,
      cardHoverFill: colors.surfaceContainer,
      trackFill: colors.surfaceContainerLow,
      tagFill: colors.secondaryContainer.withValues(alpha: isDark ? 0.52 : 0.72),
      tagText: colors.onSecondaryContainer,
      scoreBg: isDark
          ? colors.surfaceContainerHighest.withValues(alpha: 0.90)
          : colors.surface.withValues(alpha: 0.92),
      scoreFg: colors.onSurface,
      scoreStar: isDark ? const Color(0xFFFFC95C) : const Color(0xFFE09612),
      subtext: colors.onSurfaceVariant.withValues(alpha: 0.78),
    );
  }

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

/// Unified borderless M3E elastic sliding pill track shared across
/// Popular (tags), Timeline (weekdays), and Collect (categories).
///
/// Tab children remain completely transparent so the sliding [colors.primary]
/// superellipse indicator glides smoothly behind text with zero occlusion.
class AnimePillTabTrack extends StatelessWidget {
  const AnimePillTabTrack({
    super.key,
    required this.tabs,
    this.controller,
    this.isScrollable = true,
    this.tabAlignment,
    this.onTap,
    this.trackRadius = 18.0,
    this.indicatorRadius = 14.0,
    this.padding = const EdgeInsets.all(4),
    this.labelPadding = const EdgeInsets.symmetric(horizontal: 2),
    this.tabBarKey,
  });

  final List<Widget> tabs;
  final TabController? controller;
  final bool isScrollable;
  final TabAlignment? tabAlignment;
  final ValueChanged<int>? onTap;
  final double trackRadius;
  final double indicatorRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry labelPadding;
  final Key? tabBarKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final labelStyle = theme.textTheme.labelLarge?.copyWith(
      fontSize: 12.5,
      fontWeight: FontWeight.w700,
    );
    final unselectedStyle = theme.textTheme.labelLarge?.copyWith(
      fontSize: 12.5,
      fontWeight: FontWeight.w500,
    );

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: colors.surfaceContainerLow,
        shape: SuperellipseBorder(
          borderRadius: BorderRadius.circular(trackRadius),
        ),
      ),
      child: Padding(
        padding: padding,
        child: TabBar(
          key: tabBarKey,
          controller: controller,
          isScrollable: isScrollable,
          tabAlignment: tabAlignment ??
              (isScrollable ? TabAlignment.start : TabAlignment.fill),
          dividerHeight: 0,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: ShapeDecoration(
            color: colors.primary,
            shape: SuperellipseBorder(
              borderRadius: BorderRadius.circular(indicatorRadius),
            ),
          ),
          indicatorAnimation: TabIndicatorAnimation.elastic,
          labelColor: colors.onPrimary,
          unselectedLabelColor: colors.onSurfaceVariant,
          labelStyle: labelStyle,
          unselectedLabelStyle: unselectedStyle,
          labelPadding: labelPadding,
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.hovered) ||
                      states.contains(WidgetState.focused)
                  ? colors.primary.withValues(alpha: 0.08)
                  : Colors.transparent),
          splashBorderRadius: BorderRadius.circular(indicatorRadius),
          onTap: onTap,
          tabs: tabs,
        ),
      ),
    );
  }
}

/// Theme-adaptive capsule ribbon badge (e.g. `TOP 1`, `♥ 在追`).
class AnimeRibbonBadge extends StatelessWidget {
  const AnimeRibbonBadge({
    super.key,
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.compact = false,
  });

  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? colors.primary.withValues(alpha: 0.92);
    final fg = foregroundColor ?? colors.onPrimary;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: bg,
        shape: const SuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(1000)),
        ),
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

/// Crisp borderless translucent rating pill (`★ 9.1`).
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
        shape: const SuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(1000)),
        ),
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
