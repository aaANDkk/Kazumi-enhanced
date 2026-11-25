import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kazumi/bean/card/network_img_layer.dart';
import 'package:kazumi/bean/widget/anime_pastel_style.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/utils/superellipse.dart';

class BangumiTimelineCard extends StatefulWidget {
  const BangumiTimelineCard({
    super.key,
    required this.bangumiItem,
    required this.showRating,
    required this.onTap,
    this.isWatching = false,
    this.compact = false,
  });

  final BangumiItem bangumiItem;
  final bool showRating;
  final bool isWatching;
  final bool compact;
  final VoidCallback onTap;

  static final _episodePattern =
      RegExp(r'^\s*([1-9]\d*)\s*[话話集](?=\s*(?:[/／]|$))');

  static const _contentPadding = 10.0;
  static const _cornerRadius = 20.0;
  static const _titleFontSize = 14.5;
  static const _titleLineHeight = 1.32;
  static const _jpFontSize = 10.8;
  static const _jpLineHeight = 1.3;

  // Shared by the grid and card to keep text-scaled heights aligned.
  static double heightFor(TextScaler scaler, {bool compact = false}) {
    final clamped = scaler.clamp(maxScaleFactor: 1.25);
    final titleHeight = clamped.scale(_titleFontSize) * _titleLineHeight * 2;
    final jpHeight = clamped.scale(_jpFontSize) * _jpLineHeight;
    const footerHeight = 26.0;
    final minContent = compact ? 96.0 : 108.0;
    final needed = titleHeight + 4 + jpHeight + 10 + footerHeight;
    return _contentPadding * 2 + math.max(minContent, needed);
  }

  @override
  State<BangumiTimelineCard> createState() => _BangumiTimelineCardState();
}

class _BangumiTimelineCardState extends State<BangumiTimelineCard> {
  bool _hovered = false;

  String? _episodeLabel() {
    final match =
        BangumiTimelineCard._episodePattern.firstMatch(widget.bangumiItem.info);
    if (match == null) return null;
    return '${match.group(1)} 话';
  }

  List<String> _genreTags() {
    final source = widget.bangumiItem.metaTags.isNotEmpty
        ? widget.bangumiItem.metaTags
        : widget.bangumiItem.tags.map((tag) => tag.name);
    return filterMeaningfulAnimeTags(
      source,
      limit: widget.compact ? 2 : 3,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AnimePastelPalette.of(context);
    final cardHeight = BangumiTimelineCard.heightFor(
      MediaQuery.textScalerOf(context),
      compact: widget.compact,
    );

    return Semantics(
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          if (!_hovered) setState(() => _hovered = true);
        },
        onExit: (_) {
          if (_hovered) setState(() => _hovered = false);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: cardHeight,
          decoration: palette.cardDecoration(
            radius: BangumiTimelineCard._cornerRadius,
            hovered: _hovered,
          ),
          child: Material(
            type: MaterialType.transparency,
            shape: const SuperellipseBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(BangumiTimelineCard._cornerRadius),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: const SuperellipseBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(BangumiTimelineCard._cornerRadius),
                ),
              ),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.all(BangumiTimelineCard._contentPadding),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCover(context),
                    SizedBox(width: widget.compact ? 10 : 12),
                    Expanded(child: _buildDetails(context)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetails(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final palette = AnimePastelPalette.of(context);
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.25);

    final translatedName = widget.bangumiItem.nameCn.trim();
    final title = translatedName.isNotEmpty
        ? translatedName
        : widget.bangumiItem.name.trim();
    final originalName = widget.bangumiItem.name.trim();
    final jpSubtitle = (originalName.isNotEmpty && originalName != title)
        ? originalName
        : (widget.bangumiItem.airDate.isNotEmpty
            ? '首播 ${widget.bangumiItem.airDate}'
            : '');
    final tags = _genreTags();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textScaler: scaler,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.onSurface,
                  fontSize: BangumiTimelineCard._titleFontSize,
                  fontWeight: FontWeight.w800,
                  height: BangumiTimelineCard._titleLineHeight,
                ),
              ),
            ),
            if (widget.isWatching) ...[
              const SizedBox(width: 6),
              const AnimeRibbonBadge(
                label: '♥ 在追',
                compact: true,
              ),
            ],
          ],
        ),
        if (jpSubtitle.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            jpSubtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textScaler: scaler,
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.subtext,
              fontSize: BangumiTimelineCard._jpFontSize,
              height: BangumiTimelineCard._jpLineHeight,
            ),
          ),
        ],
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: tags.isEmpty
                  ? const SizedBox.shrink()
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      child: Row(
                        children: [
                          for (var i = 0; i < tags.length; i++) ...[
                            if (i > 0) const SizedBox(width: 5),
                            AnimeTagPill(label: tags[i]),
                          ],
                        ],
                      ),
                    ),
            ),
            if (widget.showRating) ...[
              const SizedBox(width: 8),
              _buildRating(context),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCover(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final imageUrl = widget.bangumiItem.images['large'] ??
        widget.bangumiItem.images['common'] ??
        '';
    final epLabel = _episodeLabel();
    const coverRadius = BorderRadius.all(Radius.circular(13));

    return ExcludeSemantics(
      child: SizedBox(
        width: widget.compact ? 68 : 78,
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: widget.bangumiItem.id,
                transitionOnUserGestures: true,
                flightShuttleBuilder: NetworkImgLayer.heroFlightShuttleBuilder,
                child: SuperellipseClip(
                  borderRadius: coverRadius,
                  child: imageUrl.isEmpty
                      ? ColoredBox(
                          color: colors.surfaceContainerHighest,
                          child: Center(
                            child: Icon(
                              Icons.movie_outlined,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        )
                      : NetworkImgLayer(
                          src: imageUrl,
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          borderRadius: coverRadius,
                        ),
                ),
              ),
              if (epLabel != null)
                Positioned(
                  left: 4,
                  right: 4,
                  bottom: 4,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: const Color(0xAA16121A),
                      shape: SuperellipseBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Text(
                        epLabel,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9.2,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF6F8FA),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRating(BuildContext context) {
    final palette = AnimePastelPalette.of(context);
    final colors = Theme.of(context).colorScheme;
    if (widget.bangumiItem.ratingScore <= 0) {
      return DecoratedBox(
        decoration: ShapeDecoration(
          color: palette.isDark
              ? colors.surfaceContainerHighest.withValues(alpha: 0.55)
              : colors.surfaceContainerHighest.withValues(alpha: 0.72),
          shape: SuperellipseBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          child: Text(
            '刚开播',
            maxLines: 1,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return Semantics(
      label: '评分 ${widget.bangumiItem.ratingScore.toStringAsFixed(1)}',
      excludeSemantics: true,
      child: AnimeScoreBadge(
        score: widget.bangumiItem.ratingScore,
        compact: widget.compact,
      ),
    );
  }
}
