import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:kazumi/modules/collect/collect_type.dart';
import 'package:kazumi/utils/superellipse.dart';

/// Shared M3 theme-adaptive anime UI primitives for Popular, Timeline, Collect,
/// History, and Search.
///
/// Every color derives strictly from [Theme.of(context).colorScheme] with
/// refined bordered superellipse cards, glowing rating pills, and zero-glitch
/// separated tab capsules.
class AnimePastelPalette {
  const AnimePastelPalette({
    required this.isDark,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.onAccentSoft,
    required this.frameFill,
    required this.frameBorder,
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
  final Color frameFill;
  final Color frameBorder;
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

    final ribbonEnd =
        Color.lerp(colors.primary, colors.tertiary, 0.28) ?? colors.primary;

    return AnimePastelPalette(
      isDark: isDark,
      accent: colors.primary,
      onAccent: colors.onPrimary,
      accentSoft: colors.primaryContainer,
      onAccentSoft: colors.onPrimaryContainer,
      frameFill: isDark
          ? colors.surfaceContainerLow
          : Color.alphaBlend(
              colors.primary.withValues(alpha: 0.022),
              colors.surfaceContainerLowest,
            ),
      frameBorder: colors.outlineVariant.withValues(alpha: isDark ? 0.46 : 0.60),
      tagFill: colors.secondaryContainer.withValues(alpha: isDark ? 0.52 : 0.72),
      tagText: colors.onSecondaryContainer,
      scoreBg: isDark
          ? colors.surfaceContainerHighest.withValues(alpha: 0.90)
          : colors.surface.withValues(alpha: 0.94),
      scoreFg: colors.onSurface,
      scoreStar: isDark ? const Color(0xFFFFCA5C) : const Color(0xFFE49A12),
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

  /// Standard framed superellipse card decoration shared across Popular,
  /// Timeline, Collect, History, and Search cards.
  ///
  /// Border width stays constant (`1.0`) across rest/hover states so
  /// [AnimatedContainer] never alters inner `ShapeDecoration.padding` and never
  /// invalidates [NetworkImgLayer]'s `memCacheWidth` during hover animations.
  ShapeDecoration cardDecoration({
    required double radius,
    bool hovered = false,
    BorderRadius? borderRadius,
    Color? fillColor,
    BorderSide? borderSideOverride,
  }) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(radius);
    final borderSide = borderSideOverride ??
        BorderSide(
          color: hovered
              ? accent.withValues(alpha: isDark ? 0.65 : 0.58)
              : frameBorder,
          width: 1.0,
        );
    return ShapeDecoration(
      color: fillColor ?? frameFill,
      shape: SuperellipseBorder(
        borderRadius: effectiveRadius,
        side: borderSide,
      ),
      shadows: [
        BoxShadow(
          color: hovered
              ? accent.withValues(alpha: isDark ? 0.22 : 0.16)
              : Colors.black.withValues(alpha: isDark ? 0.18 : 0.045),
          blurRadius: hovered ? 12 : 7,
          offset: Offset(0, hovered ? 4 : 2),
        ),
      ],
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

/// Unified separated superellipse capsule tab bar shared across
/// Popular (tags), Timeline (weekdays), and Collect (categories).
///
/// Each capsule smoothly cross-fades fill, border, glow, and foreground color
/// 1:1 with [TabController.animation] during taps AND horizontal screen swipes —
/// no enclosing rectangle and zero indicator z-order overlap.
class AnimeSeparatedTabBar extends StatefulWidget {
  const AnimeSeparatedTabBar({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.scrollable = true,
    this.height = 36.0,
    this.spacing = 7.0,
    this.borderRadius = 12.0,
    this.padding = EdgeInsets.zero,
    this.onTap,
    this.semanticLabelBuilder,
  });

  final int itemCount;
  final Widget Function(
    BuildContext context,
    int index,
    double selection,
    Color foregroundColor,
  ) itemBuilder;
  final TabController? controller;
  final bool scrollable;
  final double height;
  final double spacing;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final ValueChanged<int>? onTap;
  final String Function(int index)? semanticLabelBuilder;

  @override
  State<AnimeSeparatedTabBar> createState() => _AnimeSeparatedTabBarState();
}

class _AnimeSeparatedTabBarState extends State<AnimeSeparatedTabBar> {
  TabController? _controller;
  List<GlobalKey> _itemKeys = const [];
  int _lastCenteredIndex = -1;

  void _syncKeys() {
    if (_itemKeys.length != widget.itemCount) {
      _itemKeys = List.generate(widget.itemCount, (_) => GlobalKey());
    }
  }

  void _attachController(TabController? next) {
    if (_controller == next) return;
    _controller?.removeListener(_handleControllerChanged);
    _controller = next;
    _controller?.addListener(_handleControllerChanged);
    _lastCenteredIndex = _controller?.index ?? -1;
  }

  void _handleControllerChanged() {
    final ctrl = _controller;
    if (ctrl == null || !widget.scrollable) return;
    if (ctrl.index != _lastCenteredIndex) {
      _lastCenteredIndex = ctrl.index;
      _scrollActiveIntoView(ctrl.index);
    }
  }

  void _scrollActiveIntoView(int index) {
    if (index < 0 || index >= _itemKeys.length) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _itemKeys[index].currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.5,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _syncKeys();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncKeys();
    _attachController(widget.controller ?? DefaultTabController.maybeOf(context));
  }

  @override
  void didUpdateWidget(covariant AnimeSeparatedTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncKeys();
    _attachController(widget.controller ?? DefaultTabController.maybeOf(context));
  }

  @override
  void dispose() {
    _controller?.removeListener(_handleControllerChanged);
    super.dispose();
  }

  Widget _buildPill(
    BuildContext context,
    int index,
    double animValue,
    AnimePastelPalette palette,
    ColorScheme colors,
  ) {
    final selection = (1.0 - (animValue - index).abs()).clamp(0.0, 1.0);
    final bgColor = Color.lerp(palette.frameFill, palette.accent, selection)!;
    final borderColor = Color.lerp(
      palette.frameBorder,
      palette.accent,
      selection,
    )!;
    final fgColor = Color.lerp(
      colors.onSurfaceVariant,
      palette.onAccent,
      selection,
    )!;
    final shadowAlpha = selection * (palette.isDark ? 0.22 : 0.18);
    final radius = BorderRadius.circular(widget.borderRadius);
    final shape = SuperellipseBorder(borderRadius: radius);

    final pill = DecoratedBox(
      key: _itemKeys[index],
      decoration: ShapeDecoration(
        color: bgColor,
        shape: SuperellipseBorder(
          borderRadius: radius,
          side: BorderSide(
            color: borderColor,
            width: 0.9,
          ),
        ),
        shadows: shadowAlpha > 0.01
            ? [
                BoxShadow(
                  color: palette.accent.withValues(alpha: shadowAlpha),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : const [],
      ),
      child: Material(
        type: MaterialType.transparency,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: shape,
          onTap: () {
            final ctrl = _controller;
            if (ctrl != null && ctrl.index != index) {
              ctrl.animateTo(index);
            }
            widget.onTap?.call(index);
          },
          child: SizedBox(
            height: widget.height,
            child: Center(
              child: widget.itemBuilder(context, index, selection, fgColor),
            ),
          ),
        ),
      ),
    );

    final label = widget.semanticLabelBuilder?.call(index);
    if (label == null) return pill;
    return Semantics(
      label: label,
      selected: selection > 0.5,
      button: true,
      excludeSemantics: true,
      child: pill,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AnimePastelPalette.of(context);
    final colors = Theme.of(context).colorScheme;
    final ctrl = _controller;
    final Listenable listenable =
        ctrl?.animation ?? const AlwaysStoppedAnimation<double>(0.0);

    return AnimatedBuilder(
      animation: listenable,
      builder: (context, _) {
        final animValue = ctrl?.animation?.value ?? (ctrl?.index.toDouble() ?? 0.0);
        if (!widget.scrollable) {
          return Padding(
            padding: widget.padding,
            child: Row(
              children: [
                for (var i = 0; i < widget.itemCount; i++) ...[
                  if (i > 0) SizedBox(width: widget.spacing),
                  Expanded(
                    child: _buildPill(context, i, animValue, palette, colors),
                  ),
                ],
              ],
            ),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: widget.padding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < widget.itemCount; i++) ...[
                if (i > 0) SizedBox(width: widget.spacing),
                _buildPill(context, i, animValue, palette, colors),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Shared vertical text-height behavior modeled after FlClash's status capsule
/// (`TextLeadingDistribution.even`) so CJK, digits, and icons center optically
/// inside fixed-height pills on Android and Windows.
const kAnimePillTextHeightBehavior = TextHeightBehavior(
  applyHeightToFirstAscent: true,
  applyHeightToLastDescent: true,
  leadingDistribution: TextLeadingDistribution.even,
);

/// Single-line capsule text with symmetric vertical leading (`even` + forced
/// strut height), guaranteeing optical vertical centering inside pills/badges.
class AnimeCapsuleText extends StatelessWidget {
  const AnimeCapsuleText(
    this.text, {
    super.key,
    required this.fontSize,
    required this.color,
    this.lineHeight = 1.15,
    this.fontWeight = FontWeight.w700,
    this.letterSpacing,
    this.tabularFigures = false,
    this.textAlign,
    this.overflow = TextOverflow.ellipsis,
    this.textScaler,
  });

  final String text;
  final double fontSize;
  final Color color;
  final double lineHeight;
  final FontWeight fontWeight;
  final double? letterSpacing;
  final bool tabularFigures;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final TextScaler? textScaler;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      softWrap: false,
      textAlign: textAlign,
      overflow: overflow,
      textScaler: textScaler,
      textHeightBehavior: kAnimePillTextHeightBehavior,
      strutStyle: StrutStyle(
        fontSize: fontSize,
        height: lineHeight,
        forceStrutHeight: true,
        leadingDistribution: TextLeadingDistribution.even,
      ),
      style: TextStyle(
        fontSize: fontSize,
        height: lineHeight,
        leadingDistribution: TextLeadingDistribution.even,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        fontFeatures:
            tabularFigures ? const [FontFeature.tabularFigures()] : null,
      ),
    );
  }
}

/// Compact tabular count capsule used inside tab pills (Collect & Timeline).
class AnimeCountPill extends StatelessWidget {
  const AnimeCountPill({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: backgroundColor,
        shape: const SuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(1000)),
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 20, minHeight: 18),
        child: SizedBox(
          height: 18,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.5),
            child: Center(
              widthFactor: 1.0,
              child: AnimeCapsuleText(
                label,
                fontSize: 10.0,
                lineHeight: 1.1,
                fontWeight: FontWeight.w700,
                color: foregroundColor,
                tabularFigures: true,
                overflow: TextOverflow.visible,
              ),
            ),
          ),
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
    this.icon,
    this.gradient,
    this.backgroundColor,
    this.foregroundColor,
    this.compact = false,
  });

  final String label;
  final IconData? icon;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = AnimePastelPalette.of(context);
    final fg = foregroundColor ?? palette.onAccent;
    final height = compact ? 19.0 : 21.0;
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
      child: SizedBox(
        height: height,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 6.5 : 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: compact ? 10.5 : 11.5,
                  color: fg,
                ),
                const SizedBox(width: 2.5),
              ],
              AnimeCapsuleText(
                label,
                fontSize: compact ? 9.5 : 10.5,
                lineHeight: 1.1,
                fontWeight: FontWeight.w800,
                color: fg,
                letterSpacing: 0.2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Crisp translucent rating pill (`★ 9.1`) with delicate warm star glow.
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
    final height = compact ? 20.0 : 22.0;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: palette.scoreBg,
        shape: SuperellipseBorder(
          borderRadius: const BorderRadius.all(Radius.circular(1000)),
          side: BorderSide(
            color: palette.scoreStar.withValues(alpha: 0.36),
            width: 0.75,
          ),
        ),
        shadows: [
          BoxShadow(
            color: palette.scoreStar
                .withValues(alpha: palette.isDark ? 0.24 : 0.22),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SizedBox(
        height: height,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 6.5 : 7.5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.star_rounded,
                size: compact ? 12.0 : 13.0,
                color: palette.scoreStar,
              ),
              const SizedBox(width: 2.5),
              AnimeCapsuleText(
                score.toStringAsFixed(1),
                fontSize: compact ? 10.5 : 11.0,
                lineHeight: 1.1,
                fontWeight: FontWeight.w800,
                color: palette.scoreFg,
                tabularFigures: true,
                overflow: TextOverflow.visible,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Soft tonal capsule for anime genres / metadata, sized identically to
/// [AnimeScoreBadge] so inline meta rows align cleanly.
class AnimeTagPill extends StatelessWidget {
  const AnimeTagPill({
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
    final palette = AnimePastelPalette.of(context);
    final height = compact ? 20.0 : 22.0;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: backgroundColor ?? palette.tagFill,
        shape: const SuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(1000)),
        ),
      ),
      child: SizedBox(
        height: height,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 7.5 : 8.5),
          child: Center(
            widthFactor: 1.0,
            child: AnimeCapsuleText(
              label,
              fontSize: compact ? 10.5 : 11.0,
              lineHeight: 1.1,
              fontWeight: FontWeight.w600,
              color: foregroundColor ?? palette.tagText,
            ),
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
