part of 'collect_library_view.dart';

class _CollectWatchSummary {
  const _CollectWatchSummary({
    required this.episodeLabel,
    required this.ratio,
    required this.isCompleted,
    required this.hasProgress,
  });

  final String episodeLabel;
  final double ratio;
  final bool isCompleted;
  final bool hasProgress;

  static _CollectWatchSummary? fromHistory(History? history) {
    if (history == null) return null;
    final progress = history.progresses[history.lastWatchEpisode];
    final epName = history.lastWatchEpisodeName.trim();
    final episodeLabel =
        epName.isNotEmpty ? epName : '第 ${history.lastWatchEpisode} 话';
    final ratio = progress?.progressRatio ?? 0.0;
    final completed = (progress?.isCompleted ?? false) || ratio >= 0.95;
    final hasProgress = completed || ratio > 0.0 || history.lastWatchEpisode > 0;
    if (!hasProgress) return null;
    return _CollectWatchSummary(
      episodeLabel: episodeLabel,
      ratio: completed ? 1.0 : ratio.clamp(0.0, 1.0),
      isCompleted: completed,
      hasProgress: true,
    );
  }

  String compactSubtitle() {
    if (isCompleted) {
      return '✓ 已看完 $episodeLabel';
    }
    if (ratio > 0.01) {
      return '看到 $episodeLabel · ${(ratio * 100).round()}%';
    }
    return '看到 $episodeLabel';
  }
}

class _CollectPosterCard extends StatefulWidget {
  const _CollectPosterCard({
    super.key,
    required this.entry,
    this.history,
    required this.showRating,
    required this.showStatus,
    required this.compact,
    required this.onOpen,
    required this.onChangeType,
  });

  final CollectedBangumi entry;
  final History? history;
  final bool showRating;
  final bool showStatus;
  final bool compact;
  final VoidCallback onOpen;
  final ValueChanged<CollectType>? onChangeType;

  static const _coverRatio = 0.68;

  static double extent(
    double width,
    TextScaler scaler, {
    required bool compact,
  }) {
    final clamped = scaler.clamp(maxScaleFactor: 1.15);
    final framePad = compact ? 4.0 : 5.0;
    final coverWidth = (width - framePad * 2).clamp(40.0, double.infinity);
    final coverHeight = coverWidth / _coverRatio;
    final titleHeight = clamped.scale(compact ? 12.0 : 13.0) * 1.32;
    final subHeight = clamped.scale(compact ? 9.8 : 10.5) * 1.28;
    final footerHeight = (compact ? 5.0 : 6.0) +
        titleHeight +
        2.0 +
        subHeight +
        (compact ? 3.0 : 4.0);
    return framePad * 2 + coverHeight + footerHeight + 2.0;
  }

  @override
  State<_CollectPosterCard> createState() => _CollectPosterCardState();
}

class _CollectPosterCardState extends State<_CollectPosterCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final palette = AnimePastelPalette.of(context);
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.15);
    final item = widget.entry.bangumiItem;
    final title = CollectLibraryQuery.titleOf(widget.entry);
    final year = DateTime.tryParse(item.airDate)?.year;
    final type = CollectType.fromValue(widget.entry.type);
    final statusStyle = palette.statusStyle(type);
    final hasRating = widget.showRating && item.ratingScore > 0;
    final watch = _CollectWatchSummary.fromHistory(widget.history);
    final compact = widget.compact;
    final frameRadius = compact ? 15.0 : 17.0;
    final coverRadius = compact ? 11.0 : 12.5;
    final framePad = compact ? 4.0 : 5.0;

    final origName = item.name.trim();
    final String subLine;
    final bool highlightSub;
    if (watch != null) {
      subLine = watch.compactSubtitle();
      highlightSub = true;
    } else if (origName.isNotEmpty && origName != title) {
      subLine = origName;
      highlightSub = false;
    } else {
      subLine = [
        if (year != null) '$year 年',
        type.label,
      ].join(' · ');
      highlightSub = false;
    }

    final borderColor = _hovered
        ? palette.sakura.withValues(alpha: palette.isDark ? 0.65 : 0.55)
        : palette.frameBorder;

    return Semantics(
      button: true,
      label: [
        title,
        type.label,
        if (year != null) '$year 年',
        if (hasRating) '${item.ratingScore.toStringAsFixed(1)} 分',
        if (watch != null) watch.compactSubtitle(),
      ].join('，'),
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
          decoration: ShapeDecoration(
            color: palette.frameFill,
            shape: SuperellipseBorder(
              borderRadius: BorderRadius.circular(frameRadius),
              side: BorderSide(
                color: borderColor,
                width: _hovered ? 1.3 : 0.9,
              ),
            ),
            shadows: [
              BoxShadow(
                color: _hovered
                    ? palette.sakura
                        .withValues(alpha: palette.isDark ? 0.20 : 0.16)
                    : (palette.isDark
                        ? Colors.black.withValues(alpha: 0.20)
                        : palette.sakura.withValues(alpha: 0.06)),
                blurRadius: _hovered ? 14 : 8,
                offset: Offset(0, _hovered ? 5 : 3),
              ),
            ],
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
              onTap: widget.onOpen,
              child: Padding(
                padding: EdgeInsets.all(framePad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AspectRatio(
                      aspectRatio: _CollectPosterCard._coverRatio,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ExcludeSemantics(
                            child: AnimatedScale(
                              scale: _hovered ? 1.03 : 1.0,
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              child: _CollectCover(
                                item: item,
                                borderRadius:
                                    BorderRadius.circular(coverRadius),
                              ),
                            ),
                          ),
                          // Soft bottom veil for rating & progress contrast
                          IgnorePointer(
                            child: SuperellipseClip(
                              borderRadius: BorderRadius.circular(coverRadius),
                              child: DecoratedBox(
                                decoration: ShapeDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    stops: const [0.58, 1.0],
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.42),
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
                          if (widget.showStatus || type == CollectType.watching)
                            Positioned(
                              top: compact ? 5 : 6,
                              left: compact ? 5 : 6,
                              child: IgnorePointer(
                                child: AnimeRibbonBadge(
                                  label: '${statusStyle.symbol} ${type.label}',
                                  backgroundColor: statusStyle.bg,
                                  foregroundColor: statusStyle.fg,
                                  compact: compact,
                                ),
                              ),
                            ),
                          // Compact top-right overlay menu button (replaces bulky footer button)
                          Positioned(
                            top: compact ? 4 : 5,
                            right: compact ? 4 : 5,
                            child: _CollectEntryMenu(
                              entry: widget.entry,
                              onChanged: widget.onChangeType,
                              overlayMode: true,
                              compact: compact,
                            ),
                          ),
                          if (hasRating)
                            Positioned(
                              left: compact ? 5 : 6,
                              bottom: watch != null
                                  ? (compact ? 10 : 11)
                                  : (compact ? 5 : 6),
                              child: IgnorePointer(
                                child: AnimeScoreBadge(
                                  score: item.ratingScore,
                                  compact: compact,
                                ),
                              ),
                            ),
                          if (watch != null && watch.ratio > 0.0)
                            Positioned(
                              left: 5,
                              right: 5,
                              bottom: 4.5,
                              child: IgnorePointer(
                                child: SuperellipseClip(
                                  borderRadius: BorderRadius.circular(999),
                                  child: SizedBox(
                                    height: 3.5,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ColoredBox(
                                          color: Colors.white
                                              .withValues(alpha: 0.28),
                                        ),
                                        FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor:
                                              watch.ratio.clamp(0.06, 1.0),
                                          child: DecoratedBox(
                                            decoration: ShapeDecoration(
                                              gradient: watch.isCompleted
                                                  ? const LinearGradient(
                                                      colors: [
                                                        Color(0xFF47D9BA),
                                                        Color(0xFF9DF5DF),
                                                      ],
                                                    )
                                                  : palette.ribbonGradient,
                                              shape: const SuperellipseBorder(
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(999),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: compact ? 5 : 6),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: compact ? 2 : 3),
                      child: ExcludeSemantics(
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
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subLine,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textScaler: scaler,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: compact ? 9.8 : 10.5,
                                height: 1.28,
                                fontWeight: highlightSub
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: highlightSub
                                    ? ((watch?.isCompleted ?? false)
                                        ? (palette.isDark
                                            ? const Color(0xFF7BE8CE)
                                            : const Color(0xFF187C6C))
                                        : palette.sakura)
                                    : palette.subtext,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CollectListTile extends StatefulWidget {
  const _CollectListTile({
    super.key,
    required this.entry,
    this.history,
    required this.showRating,
    required this.onOpen,
    required this.onChangeType,
  });

  final CollectedBangumi entry;
  final History? history;
  final bool showRating;
  final VoidCallback onOpen;
  final ValueChanged<CollectType>? onChangeType;

  @override
  State<_CollectListTile> createState() => _CollectListTileState();
}

class _CollectListTileState extends State<_CollectListTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final palette = AnimePastelPalette.of(context);
    final item = widget.entry.bangumiItem;
    final title = CollectLibraryQuery.titleOf(widget.entry);
    final origName = item.name.trim();
    final jpSubtitle = (origName.isNotEmpty && origName != title) ? origName : '';
    final airDate = DateTime.tryParse(item.airDate);
    final hasRating = widget.showRating && item.ratingScore > 0;
    final watch = _CollectWatchSummary.fromHistory(widget.history);

    return MouseRegion(
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
        decoration: ShapeDecoration(
          color: palette.frameFill,
          shape: SuperellipseBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: _hovered
                  ? palette.sakura.withValues(alpha: palette.isDark ? 0.6 : 0.5)
                  : palette.frameBorder,
              width: _hovered ? 1.3 : 0.9,
            ),
          ),
          shadows: [
            BoxShadow(
              color: _hovered
                  ? palette.sakura.withValues(alpha: palette.isDark ? 0.16 : 0.12)
                  : (palette.isDark
                      ? Colors.black.withValues(alpha: 0.16)
                      : palette.sakura.withValues(alpha: 0.04)),
              blurRadius: _hovered ? 12 : 6,
              offset: Offset(0, _hovered ? 4 : 2),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          shape: SuperellipseBorder(borderRadius: BorderRadius.circular(18)),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Isolate menu focus and taps from card navigation.
              Positioned.fill(
                child: Semantics(
                  button: true,
                  label: [
                    title,
                    if (airDate != null) '${airDate.year} 年',
                    if (hasRating) '${item.ratingScore.toStringAsFixed(1)} 分',
                  ].join('，'),
                  child: InkWell(
                    customBorder: SuperellipseBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    onTap: widget.onOpen,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: IgnorePointer(
                        child: SizedBox(
                          width: 72,
                          height: 104,
                          child: _CollectCover(
                            item: item,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 104,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ExcludeSemantics(
                                    child: IgnorePointer(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w800,
                                              height: 1.3,
                                              color: colors.onSurface,
                                            ),
                                          ),
                                          if (jpSubtitle.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              jpSubtitle,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                fontSize: 10.5,
                                                color: palette.subtext,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _CollectEntryMenu(
                                  entry: widget.entry,
                                  onChanged: widget.onChangeType,
                                  showStatusLabel: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ExcludeSemantics(
                              child: IgnorePointer(
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    if (hasRating)
                                      AnimeScoreBadge(
                                        score: item.ratingScore,
                                        compact: true,
                                      ),
                                    if (airDate != null)
                                      AnimeTagPill(label: '${airDate.year} 年'),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),
                            ExcludeSemantics(
                              child: IgnorePointer(
                                child: _CollectInlineProgressCapsule(
                                  watch: watch,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollectInlineProgressCapsule extends StatelessWidget {
  const _CollectInlineProgressCapsule({required this.watch});

  final _CollectWatchSummary? watch;

  @override
  Widget build(BuildContext context) {
    final palette = AnimePastelPalette.of(context);
    final colors = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(8);
    final summary = watch;

    if (summary == null) {
      return SizedBox(
        height: 22,
        child: CustomPaint(
          painter: AnimeDashedSuperellipsePainter(
            color: colors.outlineVariant.withValues(alpha: 0.72),
            borderRadius: radius,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '尚未开始观看',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                Text(
                  '0%',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurfaceVariant.withValues(alpha: 0.55),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final fillRatio = summary.ratio > 0 ? summary.ratio.clamp(0.05, 1.0) : 0.0;
    final trackColor = palette.isDark
        ? colors.surfaceContainerHigh
        : palette.sakuraSoft.withValues(alpha: 0.75);
    final fillColor = summary.isCompleted
        ? (palette.isDark ? const Color(0xFF1E5247) : const Color(0xFFC8F2E8))
        : (palette.isDark ? const Color(0xFF56283E) : const Color(0xFFFCD2E4));
    final textColor = summary.isCompleted
        ? (palette.isDark ? const Color(0xFFA6F5E2) : const Color(0xFF10584B))
        : (palette.isDark ? const Color(0xFFFFD9EA) : const Color(0xFF8B2250));
    final leftLabel = summary.isCompleted
        ? '已看完 ${summary.episodeLabel}'
        : '看到 ${summary.episodeLabel}';
    final rightLabel = summary.isCompleted
        ? '已看完'
        : (summary.ratio > 0.01 ? '${(summary.ratio * 100).round()}%' : '在看');

    return SuperellipseClip(
      borderRadius: radius,
      child: SizedBox(
        height: 22,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: trackColor),
            if (fillRatio > 0)
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fillRatio,
                child: ColoredBox(color: fillColor),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      leftLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    rightLabel,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectCover extends StatelessWidget {
  const _CollectCover({
    required this.item,
    this.borderRadius,
  });
  final BangumiItem item;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => Hero(
          tag: item.id,
          transitionOnUserGestures: true,
          flightShuttleBuilder: NetworkImgLayer.heroFlightShuttleBuilder,
          child: NetworkImgLayer(
            src: item.images['large'] ?? item.images['common'] ?? '',
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            borderRadius: borderRadius,
          ),
        ),
      );
}

class _CollectEntryMenu extends StatelessWidget {
  const _CollectEntryMenu({
    required this.entry,
    required this.onChanged,
    this.showStatusLabel = false,
    this.overlayMode = false,
    this.compact = false,
  });
  final CollectedBangumi entry;
  final ValueChanged<CollectType>? onChanged;
  final bool showStatusLabel;
  final bool overlayMode;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = AnimePastelPalette.of(context);
    final colors = Theme.of(context).colorScheme;
    final type = CollectType.fromValue(entry.type);
    final statusStyle = palette.statusStyle(type);
    final title = CollectLibraryQuery.titleOf(entry);

    return KazumiMenuButton(
      enabled: onChanged != null,
      style: MenuStyle(
        shape: WidgetStatePropertyAll(SuperellipseBorder(
          borderRadius: BorderRadius.circular(16),
        )),
      ),
      menuChildren: [
        for (final status
            in CollectType.values.where((type) => type.isCollected))
          KazumiMenuItem(
            selected: status == type,
            onPressed: onChanged == null || status == type
                ? null
                : () => onChanged!(status),
            label: status.label,
          ),
        const Divider(indent: 16, endIndent: 16),
        KazumiMenuItem(
          onPressed:
              onChanged == null ? null : () => onChanged!(CollectType.none),
          label: '取消收藏',
          destructive: true,
        ),
      ],
      builder: (context, toggle) {
        if (showStatusLabel) {
          return Tooltip(
            message: '调整《$title》的观看状态',
            child: Material(
              type: MaterialType.transparency,
              shape:
                  SuperellipseBorder(borderRadius: BorderRadius.circular(10)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                customBorder: SuperellipseBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onTap: toggle,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: statusStyle.bg,
                    shape: SuperellipseBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${statusStyle.symbol} ${type.label}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: statusStyle.fg,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.expand_more_rounded,
                          size: 15,
                          color: statusStyle.fg,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        if (overlayMode) {
          final size = compact ? 24.0 : 28.0;
          return Tooltip(
            message: '管理《$title》 · ${type.label}',
            child: Material(
              type: MaterialType.transparency,
              shape: SuperellipseBorder(
                borderRadius: BorderRadius.circular(compact ? 8 : 9),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                customBorder: SuperellipseBorder(
                  borderRadius: BorderRadius.circular(compact ? 8 : 9),
                ),
                onTap: toggle,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: const Color(0x9E14101A),
                    shape: SuperellipseBorder(
                      borderRadius: BorderRadius.circular(compact ? 8 : 9),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.24),
                        width: 0.6,
                      ),
                    ),
                  ),
                  child: SizedBox(
                    width: size,
                    height: size,
                    child: Icon(
                      Icons.more_horiz_rounded,
                      size: compact ? 14 : 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return IconButton(
          tooltip: '管理《$title》 · ${type.label}',
          onPressed: toggle,
          style: IconButton.styleFrom(
            foregroundColor: colors.onSurfaceVariant,
            minimumSize: const Size(44, 44),
            visualDensity: VisualDensity.standard,
          ),
          icon: const Icon(Icons.more_horiz_rounded, size: 20),
        );
      },
    );
  }
}
