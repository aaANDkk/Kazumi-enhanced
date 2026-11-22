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
    final isFinished = hasRatioBar && progressRatio >= 0.95;

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
                    if (currentPosText.isNotEmpty) '看到 $currentPosText',
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

                final episodeAndTimeRow = ExcludeSemantics(
                  child: IgnorePointer(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
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
                        if (hasRatioBar) ...[
                          const SizedBox(width: 8),
                          _TimeStatBadge(
                            currentPosText: currentPosText,
                            totalDurText: totalDurText,
                            progressRatio: progressRatio,
                            isFinished: isFinished,
                          ),
                        ],
                      ],
                    ),
                  ),
                );

                Widget? progressSection;
                if (hasRatioBar) {
                  progressSection = ExcludeSemantics(
                    child: IgnorePointer(
                      child: Padding(
                        padding: EdgeInsets.only(top: wide ? 8 : 6),
                        child: LinearProgressIndicator(value: progressRatio),
                      ),
                    ),
                  );
                } else if (currentPosText.isNotEmpty) {
                  progressSection = ExcludeSemantics(
                    child: IgnorePointer(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Container(
                          margin: EdgeInsets.only(top: wide ? 8 : 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time_rounded,
                                  size: 13, color: colors.primary),
                              const SizedBox(width: 4),
                              Text(
                                '看到 $currentPosText',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }

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

                final actionWidget = _trailingAction(context, wide: wide);

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
                                  SizedBox(height: wide ? 6 : 4),
                                  episodeAndTimeRow,
                                  if (progressSection != null) progressSection,
                                ],
                              ),
                              SizedBox(height: wide ? 10 : 8),
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

  Widget _trailingAction(BuildContext context, {required bool wide}) {
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
      isFinished: _progressRatio >= 0.95,
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

class _TimeStatBadge extends StatelessWidget {
  const _TimeStatBadge({
    required this.currentPosText,
    required this.totalDurText,
    required this.progressRatio,
    required this.isFinished,
  });

  final String currentPosText;
  final String totalDurText;
  final double progressRatio;
  final bool isFinished;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final pct = (progressRatio * 100).round().clamp(1, 100);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: currentPosText.isEmpty ? '0:00' : currentPosText,
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: ' / $totalDurText',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          style: theme.textTheme.labelMedium?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
          decoration: BoxDecoration(
            color: isFinished
                ? colors.primaryContainer
                : colors.secondaryContainer,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            isFinished ? '已看完' : '$pct%',
            style: theme.textTheme.labelSmall?.copyWith(
              color: isFinished
                  ? colors.onPrimaryContainer
                  : colors.onSecondaryContainer,
              fontWeight: FontWeight.w700,
              fontSize: 10.5,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
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
