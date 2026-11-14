import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kazumi/utils/reicon_mapper.dart';

/// Drop-in replacement for Flutter's [Icon] that renders Reicon SVG icons
/// whenever a mapping exists in [ReiconMapper], preserving [IconTheme] sizing,
/// coloring, opacity, text scaling, and RTL mirroring behavior.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.size,
    this.fill,
    this.weight,
    this.grade,
    this.opticalSize,
    this.color,
    this.shadows,
    this.semanticLabel,
    this.textDirection,
    this.applyTextScaling,
    this.blendMode,
  });

  final IconData? icon;
  final double? size;
  final double? fill;
  final double? weight;
  final double? grade;
  final double? opticalSize;
  final Color? color;
  final List<Shadow>? shadows;
  final String? semanticLabel;
  final TextDirection? textDirection;
  final bool? applyTextScaling;
  final BlendMode? blendMode;

  @override
  Widget build(BuildContext context) {
    final IconData? iconData = icon;
    final IconThemeData iconTheme = IconTheme.of(context);
    final double tentativeIconSize = size ?? iconTheme.size ?? 24.0;
    final bool applyTextScale =
        applyTextScaling ?? iconTheme.applyTextScaling ?? false;
    final double effectiveSize = applyTextScale
        ? MediaQuery.textScalerOf(context).scale(tentativeIconSize)
        : tentativeIconSize;

    if (iconData == null) {
      return Center(
        widthFactor: 1.0,
        heightFactor: 1.0,
        child: SizedBox.square(dimension: effectiveSize),
      );
    }

    final bool? filledOverride = fill == null ? null : fill! >= 0.5;
    final String? svg =
        ReiconMapper.resolveSvg(iconData, filled: filledOverride);
    if (svg == null) {
      return Icon(
        iconData,
        size: size,
        fill: fill,
        weight: weight,
        grade: grade,
        opticalSize: opticalSize,
        color: color,
        shadows: shadows,
        semanticLabel: semanticLabel,
        textDirection: textDirection,
        applyTextScaling: applyTextScaling,
        blendMode: blendMode,
      );
    }

    final double iconOpacity = iconTheme.opacity ?? 1.0;
    Color? iconColor = color ?? iconTheme.color;
    if (iconColor != null && iconOpacity != 1.0) {
      iconColor = iconColor.withValues(alpha: iconColor.a * iconOpacity);
    }

    // Reicon glyphs fill ~90-98% of their 24x24 viewBox versus Material's ~78%,
    // so apply a slight optical inset and loosen tight/minimum parent constraints
    // with Center so large badges, prefix slots, and avatars do not stretch the SVG.
    final double glyphSize = effectiveSize * 0.88;
    Widget result = SvgPicture.string(
      svg,
      width: glyphSize,
      height: glyphSize,
      fit: BoxFit.contain,
      colorFilter: iconColor != null
          ? ColorFilter.mode(iconColor, blendMode ?? BlendMode.srcIn)
          : null,
      excludeFromSemantics: true,
    );

    if (iconData.matchTextDirection) {
      final TextDirection? resolvedDirection =
          textDirection ?? Directionality.maybeOf(context);
      if (resolvedDirection == TextDirection.rtl) {
        result = Transform.flip(flipX: true, child: result);
      }
    }

    result = Center(
      widthFactor: 1.0,
      heightFactor: 1.0,
      child: SizedBox.square(
        dimension: effectiveSize,
        child: Center(child: result),
      ),
    );

    if (semanticLabel != null) {
      result = Semantics(label: semanticLabel, child: result);
    }

    return result;
  }
}
