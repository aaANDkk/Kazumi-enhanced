import 'package:flutter/material.dart';
import 'package:kazumi/bean/card/network_img_layer.dart';
import 'package:kazumi/bean/widget/kazumi_menu.dart';
import 'package:kazumi/bean/widget/loading_indicator.dart';
import 'package:kazumi/modules/collect/collect_type.dart';
import 'package:kazumi/modules/history/history_module.dart';

class HistoryRecordTile extends StatelessWidget {
  const HistoryRecordTile({
    super.key,
    required this.history,
    required this.onPlay,
    this.onPlayNext,
    required this.onDetails,
    required this.onDelete,
    required this.collectType,
    required this.onChangeCollect,
    required this.borderRadius,
    this.editing = false,
    this.selected = false,
    this.batchMode = false,
    this.onToggleSelect,
    this.busy = false,
  });

  final History history;
  final VoidCallback onPlay;
  final VoidCallback? onPlayNext;
  final VoidCallback onDetails;
  final Future<void> Function() onDelete;
  final CollectType collectType;
  final ValueChanged<CollectType>? onChangeCollect;
  final BorderRadius borderRadius;
  final bool editing;
  final bool selected;
  final bool batchMode;
  final VoidCallback? onToggleSelect;
  final bool busy;

  Progress? get _currentProgress => history.progresses[history.lastWatchEpisode];

  double get _progressRatio => _currentProgress?.progressRatio ?? 0.0;

  String _formatDuration(Duration duration) {
    if (duration.inSeconds <= 0) return '';
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    return duration.inHours > 0
        ? '${duration.inHours}:$minutes:$seconds'
        : '${duration.inMinutes}:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final animDuration =
        disableAnimations ? Duration.zero : const Duration(milliseconds: 200);

    final title = history.bangumiItem.nameCn.isEmpty
        ? history.bangumiItem.name
        : history.bangumiItem.nameCn;
    final episode = history.lastWatchEpisodeName.isEmpty
        ? '第 ${history.lastWatchEpisode} 话'
        : history.lastWatchEpisodeName;
    final source = HistoryEntryKind.normalize(history.entryKind) ==
            HistoryEntryKind.offline
        ? '缓存'
        : '在线';
    final time =
        TimeOfDay.fromDateTime(history.lastWatchTime.toLocal()).format(context);
    final image = history.bangumiItem.images['large'] ?? '';

    final prog = _currentProgress;
    final progressDuration = prog?.progress ?? Duration.zero;
    final totalDuration = prog?.totalDuration ?? Duration.zero;
    final currentPosText = _formatDuration(progressDuration);
    final totalDurText = _formatDuration(totalDuration);
    final progressRatio = _progressRatio;
    final hasRatioBar = totalDurText.isNotEmpty && progressRatio > 0.0;
    final isFinished =
        (prog?.isCompleted ?? false) || (hasRatioBar && progressRatio >= 0.95);

    final effectiveRadius =
        editing && selected ? BorderRadius.circular(16) : borderRadius;
    final surfaceColor = editing && selected
        ? Color.alphaBlend(
            colors.errorContainer.withValues(alpha: 0.35),
            colors.surfaceContainerLow,
          )
        : colors.surfaceContainerLow;

    return Dismissible(
      key: ValueKey(history.key),
      direction:
          busy || editing ? DismissDirection.none : DismissDirection.endToStart,
      // The parent removes saved deletions; failed writes keep the row usable.
      confirmDismiss: (_) async {
        await onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: effectiveRadius,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_rounded,
                size: 22, color: colors.onErrorContainer),
            const SizedBox(height: 2),
            Text(
              '删除',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      child: AnimatedContainer(
        duration: animDuration,
        curve: Curves.easeInOutCubicEmphasized,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: effectiveRadius,
          border: editing && selected
              ? Border.all(color: colors.error, width: 1.5)
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Keep menu focus outside the card's InkWell to prevent stuck highlights.
              Positioned.fill(
                child: Semantics(
                  button: !busy,
                  selected: editing ? selected : null,
                  label: [
                    title,
                    episode,
                    if (isFinished)
                      '已看完'
                    else if (currentPosText.isNotEmpty)
                      '看到 $currentPosText'
                    else
                      '暂无观看进度',
                    source,
                    history.adapterName,
                    time,
                  ].where((text) => text.isNotEmpty).join('，'),
                  child: InkWell(
                    onTap: busy ? null : (editing ? onToggleSelect : onDetails),
                  ),
                ),
              ),
              LayoutBuilder(builder: (context, constraints) {
                final wide = constraints.maxWidth >= 600;
                final largeText =
                    MediaQuery.textScalerOf(context).scale(14) > 21;
                final coverWidth = wide ? 72.0 : 68.0;
                final coverHeight = coverWidth * 1.4;
                final pad = wide ? 14.0 : 12.0;

                final cover = ExcludeSemantics(
                  child: IgnorePointer(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: image.isEmpty
                          ? Container(
                              width: coverWidth,
                              height: coverHeight,
                              color: colors.surfaceContainerHighest,
                              child: Icon(Icons.movie_outlined,
                                  color: colors.onSurfaceVariant),
                            )
                          : NetworkImgLayer(
                              src: image,
                              width: coverWidth,
                              height: coverHeight,
                            ),
                    ),
                  ),
                );

                final titleRow = Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ExcludeSemantics(
                        child: IgnorePointer(
                          child: Text(
                            title,
                            maxLines: wide ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: (wide
                                    ? theme.textTheme.titleMedium
                                    : theme.textTheme.titleSmall)
                                ?.copyWith(
                              fontSize: wide ? 16.5 : 15.5,
                              fontWeight: FontWeight.w700,
                              height: 1.28,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!editing && !busy) ...[
                      const SizedBox(width: 4),
                      _moreButton(context),
                    ],
                  ],
                );

                final episodeRow = ExcludeSemantics(
                  child: IgnorePointer(
                    child: Text(
                      episode,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: wide ? 13.5 : 13.0,
                      ),
                    ),
                  ),
                );

                final progressSection = ExcludeSemantics(
                  child: IgnorePointer(
                    child: Padding(
                      padding: EdgeInsets.only(top: wide ? 7 : 5),
                      child: _HistoryProgressCapsule(
                        wide: wide,
                        currentPosText: currentPosText,
                        totalDurText: totalDurText,
                        progressRatio: progressRatio,
                        hasRatioBar: hasRatioBar,
                        isFinished: isFinished,
                      ),
                    ),
                  ),
                );

                final metaText = ExcludeSemantics(
                  child: IgnorePointer(
                    child: Text(
                      [
                        source,
                        if (history.adapterName.isNotEmpty) history.adapterName,
                        time,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: wide ? 12.0 : 11.5,
                      ),
                    ),
                  ),
                );

                final actionWidget = _trailingAction(
                  context,
                  wide: wide,
                  isFinished: isFinished,
                );

                final bottomRow = largeText
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          metaText,
                          const SizedBox(height: 8),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: actionWidget,
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: metaText),
                          const SizedBox(width: 8),
                          actionWidget,
                        ],
                      );

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: wide ? 16 : pad,
                    vertical: pad,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AnimatedSize(
                        duration: animDuration,
                        curve: Curves.easeInOutCubicEmphasized,
                        child: editing
                            ? Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: ExcludeSemantics(
                                  child: IgnorePointer(
                                    child: _SelectionCircle(
                                      selected: selected,
                                      duration: animDuration,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      cover,
                      SizedBox(width: wide ? 16 : 12),
                      Expanded(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: coverHeight),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  titleRow,
                                  SizedBox(height: wide ? 4 : 3),
                                  episodeRow,
                                  progressSection,
                                ],
                              ),
                              SizedBox(height: wide ? 9 : 7),
                              bottomRow,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _moreButton(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return KazumiMenuButton(
      menuChildren: [
        KazumiMenuItem(
          onPressed: onDetails,
          label: '番剧详情',
        ),
        SubmenuButton(
          menuChildren: [
            for (final type in CollectType.values)
              KazumiMenuItem(
                selected: collectType == type,
                onPressed: onChangeCollect == null
                    ? null
                    : () => onChangeCollect!(type),
                label: type.label,
              ),
          ],
          child: Text(collectType.label),
        ),
        const Divider(),
        KazumiMenuItem(
          destructive: true,
          onPressed: onDelete,
          label: '删除记录',
        ),
      ],
      builder: (context, toggle) => Tooltip(
        message: '更多操作',
        child: InkResponse(
          onTap: toggle,
          radius: 18,
          child: SizedBox(
            width: 28,
            height: 24,
            child: Icon(
              Icons.more_horiz_rounded,
              size: 18,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _trailingAction(
    BuildContext context, {
    required bool wide,
    required bool isFinished,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final height = wide ? 36.0 : 34.0;

    if (busy) {
      return SizedBox(
        width: 48,
        height: height,
        child: Center(child: LoadingIndicator(size: wide ? 18 : 16)),
      );
    }

    if (editing) {
      if (selected) {
        return ExcludeSemantics(
          child: IgnorePointer(
            child: Container(
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: colors.error,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_rounded, size: 13, color: colors.onError),
                  const SizedBox(width: 4),
                  Text(
                    '待删除',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onError,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      if (batchMode) {
        return SizedBox(height: height);
      }
      return Material(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(height / 2),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onDelete,
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_outline_rounded,
                      size: 16, color: colors.onErrorContainer),
                  const SizedBox(width: 4),
                  Text(
                    '删除',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onErrorContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return _HistoryActionPill(
      wide: wide,
      height: height,
      onPlay: onPlay,
      onPlayNext: onPlayNext,
      isFinished: isFinished,
    );
  }
}

class _SelectionCircle extends StatelessWidget {
  const _SelectionCircle({required this.selected, required this.duration});

  final bool selected;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeInOutCubicEmphasized,
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? colors.error : Colors.transparent,
        border: Border.all(
          color: selected ? colors.error : colors.outline,
          width: 2,
        ),
      ),
      child: selected
          ? Icon(Icons.check_rounded, size: 14, color: colors.onError)
          : null,
    );
  }
}

class _HistoryProgressCapsule extends StatelessWidget {
  const _HistoryProgressCapsule({
    required this.wide,
    required this.currentPosText,
    required this.totalDurText,
    required this.progressRatio,
    required this.hasRatioBar,
    required this.isFinished,
  });

  final bool wide;
  final String currentPosText;
  final String totalDurText;
  final double progressRatio;
  final bool hasRatioBar;
  final bool isFinished;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    const radius = 8.0;
    final borderRadius = BorderRadius.circular(radius);
    final minHeight = wide ? 24.0 : 22.0;

    final trackBg = Color.alphaBlend(
      colors.primary.withValues(alpha: isDark ? 0.08 : 0.07),
      colors.surfaceContainerHigh,
    );
    final emptyBg = Color.alphaBlend(
      colors.surfaceContainerHighest.withValues(alpha: isDark ? 0.32 : 0.45),
      colors.surfaceContainerLow,
    );

    final bool isEmptyState = !isFinished && currentPosText.isEmpty;
    final bool isUnknownDuration =
        !isFinished && !hasRatioBar && currentPosText.isNotEmpty;

    final double fillFactor = isFinished
        ? 1.0
        : (hasRatioBar ? progressRatio.clamp(0.0, 1.0) : 0.0);

    final baseTextStyle = theme.textTheme.labelSmall?.copyWith(
      fontSize: wide ? 11.0 : 10.5,
      height: 1.15,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    final Widget leftContent;
    final String rightText;
    final Color rightColor;

    if (isFinished) {
      final finishedLeft = totalDurText.isNotEmpty
          ? '$totalDurText / $totalDurText'
          : (currentPosText.isNotEmpty ? '看到 $currentPosText' : '本集已看完');
      leftContent = Text(
        finishedLeft,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: baseTextStyle?.copyWith(
          color: colors.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      );
      rightText = '已看完';
      rightColor = colors.onPrimaryContainer;
    } else if (hasRatioBar) {
      final pct = (progressRatio * 100).round().clamp(1, 100);
      leftContent = Text(
        '${currentPosText.isEmpty ? '0:00' : currentPosText} / $totalDurText',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: baseTextStyle?.copyWith(
          color: colors.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      );
      rightText = '$pct%';
      rightColor =
          progressRatio >= 0.85 ? colors.onPrimaryContainer : colors.primary;
    } else if (isUnknownDuration) {
      leftContent = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule_rounded,
            size: wide ? 12.5 : 12.0,
            color: colors.primary,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '看到 $currentPosText',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: baseTextStyle?.copyWith(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
      rightText = '未知总长';
      rightColor = colors.onSurfaceVariant.withValues(alpha: 0.78);
    } else {
      leftContent = Text(
        '暂无观看进度',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: baseTextStyle?.copyWith(
          color: colors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      );
      rightText = '0%';
      rightColor = colors.onSurfaceVariant;
    }

    Widget capsule = ClipRRect(
      borderRadius: borderRadius,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: ColoredBox(color: isEmptyState ? emptyBg : trackBg),
            ),
            if (fillFactor > 0)
              Positioned.fill(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FractionallySizedBox(
                    widthFactor: fillFactor,
                    heightFactor: 1.0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: borderRadius,
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: wide ? 10 : 8,
                vertical: 3,
              ),
              child: Row(
                children: [
                  Expanded(child: leftContent),
                  const SizedBox(width: 6),
                  Text(
                    rightText,
                    maxLines: 1,
                    style: baseTextStyle?.copyWith(
                      color: rightColor,
                      fontWeight:
                          isEmptyState ? FontWeight.w600 : FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (isEmptyState) {
      capsule = CustomPaint(
        foregroundPainter: _DashedRRectPainter(
          color: colors.outlineVariant,
          radius: radius,
        ),
        child: capsule,
      );
    }

    return capsule;
  }
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    const strokeWidth = 1.0;
    const dashLength = 4.5;
    const gapLength = 3.0;
    const half = strokeWidth / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        half,
        half,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

class _HistoryActionPill extends StatelessWidget {
  const _HistoryActionPill({
    required this.wide,
    required this.height,
    required this.onPlay,
    required this.onPlayNext,
    required this.isFinished,
  });

  final bool wide;
  final double height;
  final VoidCallback onPlay;
  final VoidCallback? onPlayNext;
  final bool isFinished;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final outer = Radius.circular(height / 2);
    const inner = Radius.circular(6);
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );

    if (onPlayNext == null) {
      return Tooltip(
        message: isFinished ? '重播本集' : '继续播放',
        child: Material(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.all(outer),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPlay,
            child: SizedBox(
              height: height,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: wide ? 16 : 13),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isFinished
                          ? Icons.replay_rounded
                          : Icons.play_arrow_rounded,
                      size: isFinished ? 16 : 18,
                      color: colors.onPrimaryContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isFinished
                          ? (wide ? '重播本集' : '重播')
                          : (wide ? '继续播放' : '继续'),
                      style: labelStyle?.copyWith(
                          color: colors.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: '继续播放',
          child: Material(
            color: colors.primaryContainer,
            borderRadius: BorderRadiusDirectional.horizontal(
              start: outer,
              end: inner,
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPlay,
              child: SizedBox(
                height: height,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: wide ? 14 : 11),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_arrow_rounded,
                        size: wide ? 18 : 20,
                        color: colors.onPrimaryContainer,
                      ),
                      if (wide) ...[
                        const SizedBox(width: 4),
                        Text(
                          '继续播放',
                          style: labelStyle?.copyWith(
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 2),
        Tooltip(
          message: '下一集',
          child: Material(
            color: colors.secondaryContainer,
            borderRadius: BorderRadiusDirectional.horizontal(
              start: inner,
              end: outer,
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPlayNext,
              child: SizedBox(
                height: height,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: wide ? 12 : 9,
                    right: wide ? 14 : 11,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.skip_next_rounded,
                        size: 17,
                        color: colors.onSecondaryContainer,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        wide ? '下一集' : '下集',
                        style: labelStyle?.copyWith(
                          color: colors.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
