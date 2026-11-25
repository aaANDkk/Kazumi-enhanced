import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/card/network_img_layer.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/bean/widget/anime_pastel_style.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/utils/superellipse.dart';

// 番剧海报卡片 - 无描边 M3E 超椭圆海报卡
class BangumiCardV extends StatefulWidget {
  const BangumiCardV({
    super.key,
    required this.bangumiItem,
    this.canTap = true,
    this.enableHero = true,
    this.rankIndex,
    this.isWatching = false,
    this.showRating = true,
    this.compact = false,
  });

  final BangumiItem bangumiItem;
  final bool canTap;
  final bool enableHero;
  final int? rankIndex;
  final bool isWatching;
  final bool showRating;
  final bool compact;

  static const double coverAspectRatio = 0.68;

  static double extentFor(
    double cardWidth,
    TextScaler scaler, {
    bool compact = false,
  }) {
    final clamped = scaler.clamp(maxScaleFactor: 1.15);
    final framePad = compact ? 4.0 : 5.0;
    final coverWidth = (cardWidth - framePad * 2).clamp(40.0, double.infinity);
    final coverHeight = coverWidth / coverAspectRatio;
    final titleHeight = clamped.scale(compact ? 12.0 : 13.0) * 1.32;
    final subHeight = clamped.scale(compact ? 9.8 : 10.5) * 1.28;
    final textSectionHeight = (compact ? 5.0 : 6.0) +
        titleHeight +
        2.0 +
        subHeight +
        (compact ? 3.0 : 4.0);
    return framePad * 2 + coverHeight + textSectionHeight + 2.0;
  }

  @override
  State<BangumiCardV> createState() => _BangumiCardVState();
}

class _BangumiCardVState extends State<BangumiCardV> {
  bool _hovered = false;

  String _resolvePrimaryTitle() {
    final cn = widget.bangumiItem.nameCn.trim();
    return cn.isNotEmpty ? cn : widget.bangumiItem.name.trim();
  }

  String _resolveSubtitle(String primaryTitle) {
    final orig = widget.bangumiItem.name.trim();
    if (orig.isNotEmpty && orig != primaryTitle) {
      return orig;
    }
    final year = DateTime.tryParse(widget.bangumiItem.airDate)?.year;
    final tags = filterMeaningfulAnimeTags(
      widget.bangumiItem.metaTags.isNotEmpty
          ? widget.bangumiItem.metaTags
          : widget.bangumiItem.tags.map((t) => t.name),
      limit: 1,
    );
    return [
      if (year != null) '$year',
      if (tags.isNotEmpty) tags.first,
    ].join(' · ');
  }

  String? _resolveRibbonText() {
    if (widget.isWatching) {
      return '♥ 在追';
    }
    final rank = widget.rankIndex;
    if (rank != null && rank >= 0 && rank < 3) {
      return 'TOP ${rank + 1}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final palette = AnimePastelPalette.of(context);
    final compact = widget.compact;
    final frameRadius = compact ? 15.0 : 17.0;
    final coverRadius = compact ? 11.0 : 12.5;
    final framePad = compact ? 4.0 : 5.0;
    final title = _resolvePrimaryTitle();
    final subtitle = _resolveSubtitle(title);
    final ribbonText = _resolveRibbonText();
    final showScore = widget.showRating && widget.bangumiItem.ratingScore > 0;
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.15);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (!_hovered) setState(() => _hovered = true);
      },
      onExit: (_) {
        if (_hovered) setState(() => _hovered = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        decoration: ShapeDecoration(
          color: _hovered ? palette.cardHoverFill : palette.cardFill,
          shape: SuperellipseBorder(
            borderRadius: BorderRadius.circular(frameRadius),
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          shape: SuperellipseBorder(
            borderRadius: BorderRadius.circular(frameRadius),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: SuperellipseBorder(
              borderRadius: BorderRadius.circular(frameRadius),
            ),
            onTap: () {
              if (!widget.canTap) {
                KazumiDialog.showToast(
                  message: '编辑模式',
                );
                return;
              }
              context.pushNamed('/info/', arguments: widget.bangumiItem);
            },
            child: Padding(
              padding: EdgeInsets.all(framePad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: BangumiCardV.coverAspectRatio,
                    child: LayoutBuilder(
                      builder: (context, boxConstraints) {
                        final maxWidth = boxConstraints.maxWidth;
                        final maxHeight = boxConstraints.maxHeight;
                        final coverImg = NetworkImgLayer(
                          src: widget.bangumiItem.images['large'] ??
                              widget.bangumiItem.images['common'] ??
                              '',
                          width: maxWidth,
                          height: maxHeight,
                          borderRadius: BorderRadius.circular(coverRadius),
                        );
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            AnimatedScale(
                              scale: _hovered ? 1.03 : 1.0,
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              child: widget.enableHero
                                  ? Hero(
                                      transitionOnUserGestures: true,
                                      flightShuttleBuilder: NetworkImgLayer
                                          .heroFlightShuttleBuilder,
                                      tag: widget.bangumiItem.id,
                                      child: coverImg,
                                    )
                                  : coverImg,
                            ),
                            IgnorePointer(
                              child: SuperellipseClip(
                                borderRadius:
                                    BorderRadius.circular(coverRadius),
                                child: DecoratedBox(
                                  decoration: ShapeDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      stops: const [0.60, 1.0],
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.28),
                                      ],
                                    ),
                                    shape: SuperellipseBorder(
                                      borderRadius:
                                          BorderRadius.circular(coverRadius),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (ribbonText != null)
                              Positioned(
                                top: compact ? 5 : 6,
                                left: compact ? 5 : 6,
                                child: AnimeRibbonBadge(
                                  label: ribbonText,
                                  compact: compact,
                                ),
                              ),
                            if (showScore)
                              Positioned(
                                right: compact ? 5 : 6,
                                bottom: compact ? 5 : 6,
                                child: AnimeScoreBadge(
                                  score: widget.bangumiItem.ratingScore,
                                  compact: compact,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  SizedBox(height: compact ? 5 : 6),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: compact ? 2 : 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textScaler: scaler,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: compact ? 12.0 : 13.0,
                            height: 1.32,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle.isNotEmpty ? subtitle : ' ',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textScaler: scaler,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: compact ? 9.8 : 10.5,
                            height: 1.28,
                            color: palette.subtext,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
