import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/appbar/sys_app_bar.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/modules/collect/collect_type.dart';
import 'package:kazumi/modules/history/history_module.dart';
import 'package:kazumi/pages/collect/collect_controller.dart';
import 'package:kazumi/pages/history/history_controller.dart';
import 'package:kazumi/pages/history/history_list_view.dart';
import 'package:kazumi/pages/history/history_record_tile.dart';
import 'package:kazumi/services/player/history_playback_service.dart';
import 'package:kazumi/services/plugin/rule_engine_models.dart'
    show RuleCancelToken;
import 'package:kazumi/utils/device.dart';
import 'package:kazumi/utils/superellipse.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, required this.controller});

  final HistoryController controller;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool _editing = false;
  bool _clearing = false;
  final Set<String> _deleting = {};
  final Set<String> _selectedKeys = {};

  @override
  void initState() {
    super.initState();
    widget.controller.init();
  }

  void _setEditing(bool value) {
    setState(() {
      _editing = value;
      if (!value) {
        _selectedKeys.clear();
      }
    });
  }

  void _toggleSelect(History history) {
    if (_clearing || _deleting.contains(history.key)) return;
    setState(() {
      if (_selectedKeys.contains(history.key)) {
        _selectedKeys.remove(history.key);
      } else {
        _selectedKeys.add(history.key);
      }
    });
  }

  void _toggleSelectAll(List<History> entries) {
    if (_clearing) return;
    final allKeys = entries.map((e) => e.key).toSet();
    setState(() {
      if (_selectedKeys.length >= allKeys.length &&
          allKeys.every(_selectedKeys.contains)) {
        _selectedKeys.clear();
      } else {
        _selectedKeys
          ..clear()
          ..addAll(allKeys);
      }
    });
  }

  void _invertSelection(List<History> entries) {
    if (_clearing) return;
    setState(() {
      final next = <String>{};
      for (final entry in entries) {
        if (!_selectedKeys.contains(entry.key)) {
          next.add(entry.key);
        }
      }
      _selectedKeys
        ..clear()
        ..addAll(next);
    });
  }

  Future<void> _deleteHistory(History history) async {
    if (_clearing || _deleting.contains(history.key)) return;
    setState(() => _deleting.add(history.key));
    try {
      await widget.controller.deleteHistory(history);
      if (mounted) {
        _selectedKeys.remove(history.key);
        if (widget.controller.histories.isEmpty) {
          _setEditing(false);
        }
      }
    } catch (_) {
      if (mounted) {
        KazumiDialog.showToast(context: context, message: '删除失败，请稍后重试');
      }
    } finally {
      if (mounted) setState(() => _deleting.remove(history.key));
    }
  }

  Future<void> _deleteSelected(List<History> entries) async {
    if (_clearing || _selectedKeys.isEmpty) return;
    final targets = entries
        .where((e) =>
            _selectedKeys.contains(e.key) && !_deleting.contains(e.key))
        .toList();
    if (targets.isEmpty) return;

    setState(() {
      _deleting.addAll(targets.map((e) => e.key));
    });
    try {
      await widget.controller.deleteHistories(targets);
      if (mounted) {
        setState(() {
          for (final item in targets) {
            _selectedKeys.remove(item.key);
          }
          if (widget.controller.histories.isEmpty) {
            _editing = false;
            _selectedKeys.clear();
          }
        });
      }
    } catch (_) {
      if (mounted) {
        KazumiDialog.showToast(context: context, message: '批量删除失败，请稍后重试');
      }
    } finally {
      if (mounted) {
        setState(() {
          for (final item in targets) {
            _deleting.remove(item.key);
          }
        });
      }
    }
  }

  Future<void> _clearHistory() async {
    if (_clearing || _deleting.isNotEmpty) return;
    final confirmed = await KazumiDialog.show<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_sweep_outlined),
        title: const Text('清空历史记录？'),
        content: Text(
            '将删除全部 ${widget.controller.histories.length} 条观看记录，包括在线和缓存记录。此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('清空全部'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _clearing = true);
    try {
      await widget.controller.clearAll();
      if (mounted) _setEditing(false);
    } catch (_) {
      if (mounted) {
        KazumiDialog.showToast(context: context, message: '清空失败，请稍后重试');
      }
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final dockAnimDuration =
        disableAnimations ? Duration.zero : const Duration(milliseconds: 220);

    return Observer(builder: (context) {
      final entries = widget.controller.histories.toList();
      final validKeys = entries.map((e) => e.key).toSet();
      final selectedCount = _selectedKeys.where(validKeys.contains).length;
      final allSelected =
          entries.isNotEmpty && selectedCount == entries.length;
      final batchMode = selectedCount > 0;

      return PopScope(
        canPop: !_editing,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _editing) {
            _setEditing(false);
          }
        },
        child: Scaffold(
          appBar: SysAppBar(
            title: Text(
              _editing
                  ? (batchMode ? '已选择 $selectedCount 项' : '管理历史记录')
                  : '历史记录',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            actions: [
              if (entries.isNotEmpty) ...[
                if (_editing)
                  TextButton(
                    onPressed: _clearing ? null : () => _toggleSelectAll(entries),
                    child: Text(allSelected ? '取消全选' : '全选'),
                  ),
                Padding(
                  padding: const EdgeInsets.only(right: 12, left: 4),
                  child: _editing
                      ? FilledButton.tonal(
                          onPressed: _clearing ? null : () => _setEditing(false),
                          child: const Text('完成'),
                        )
                      : IconButton.filledTonal(
                          tooltip: '管理历史记录',
                          onPressed: () => _setEditing(true),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                ),
              ],
            ],
          ),
          body: SafeArea(
            top: false,
            bottom: false,
            child: Stack(
              children: [
                HistoryListView(
                  entries: entries,
                  editing: _editing,
                  bottomPadding: _editing && entries.isNotEmpty ? 84.0 : 0.0,
                  itemBuilder: (history, borderRadius) => _HistoryCard(
                    history: history,
                    borderRadius: borderRadius,
                    editing: _editing,
                    selected: _selectedKeys.contains(history.key),
                    batchMode: batchMode,
                    busy: _clearing || _deleting.contains(history.key),
                    onToggleSelect: () => _toggleSelect(history),
                    onDelete: () => _deleteHistory(history),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16 + MediaQuery.paddingOf(context).bottom,
                  child: IgnorePointer(
                    ignoring: !_editing || entries.isEmpty,
                    child: AnimatedSlide(
                      offset: _editing && entries.isNotEmpty
                          ? Offset.zero
                          : const Offset(0, 1.3),
                      duration: dockAnimDuration,
                      curve: Curves.easeInOutCubicEmphasized,
                      child: AnimatedOpacity(
                        opacity: _editing && entries.isNotEmpty ? 1.0 : 0.0,
                        duration: dockAnimDuration,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 640),
                            child: Material(
                              color: colors.surfaceContainerHighest,
                              elevation: 6,
                              shadowColor:
                                  colors.shadow.withValues(alpha: 0.28),
                              shape: SuperellipseBorder(borderRadius: BorderRadius.circular(26)),
                              child: Padding(
                                padding: batchMode
                                    ? const EdgeInsets.fromLTRB(12, 8, 10, 8)
                                    : const EdgeInsets.fromLTRB(16, 8, 10, 8),
                                child: batchMode
                                    ? Row(
                                        children: [
                                          TextButton.icon(
                                            onPressed: _clearing
                                                ? null
                                                : () =>
                                                    _invertSelection(entries),
                                            icon: const Icon(
                                                Icons.select_all_rounded,
                                                size: 18),
                                            label: const Text('反选'),
                                          ),
                                          SizedBox(
                                            height: 18,
                                            child: VerticalDivider(
                                              width: 8,
                                              color: colors.outlineVariant,
                                            ),
                                          ),
                                          TextButton.icon(
                                            style: TextButton.styleFrom(
                                              foregroundColor: colors.error,
                                            ),
                                            onPressed: _clearing ||
                                                    _deleting.isNotEmpty
                                                ? null
                                                : _clearHistory,
                                            icon: const Icon(
                                                Icons.delete_sweep_outlined,
                                                size: 18),
                                            label: const Text('清空'),
                                          ),
                                          const Spacer(),
                                          FilledButton.icon(
                                            style: FilledButton.styleFrom(
                                              backgroundColor: colors.error,
                                              foregroundColor: colors.onError,
                                              shape: const SuperellipseBorder(borderRadius: BorderRadius.all(Radius.circular(1000))),
                                            ),
                                            onPressed: _clearing ||
                                                    _deleting.isNotEmpty
                                                ? null
                                                : () =>
                                                    _deleteSelected(entries),
                                            icon: const Icon(
                                                Icons.delete_rounded,
                                                size: 18),
                                            label: Text('删除 ($selectedCount)'),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '点按卡片可多选 · 或点右侧直删',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: colors.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          TextButton.icon(
                                            style: TextButton.styleFrom(
                                              foregroundColor: colors.error,
                                            ),
                                            onPressed: _clearing ||
                                                    _deleting.isNotEmpty
                                                ? null
                                                : _clearHistory,
                                            icon: const Icon(
                                                Icons.delete_sweep_outlined,
                                                size: 18),
                                            label: const Text('清空全部'),
                                          ),
                                        ],
                                      ),
                              )),
                          ),
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
    });
  }
}

class _HistoryCard extends StatefulWidget {
  const _HistoryCard({
    required this.history,
    required this.onDelete,
    required this.editing,
    required this.selected,
    required this.batchMode,
    required this.onToggleSelect,
    required this.busy,
    required this.borderRadius,
  });

  final History history;
  final bool editing;
  final bool selected;
  final bool batchMode;
  final VoidCallback onToggleSelect;
  final bool busy;
  final Future<void> Function() onDelete;
  final BorderRadius borderRadius;

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> with KazumiDialogOwner {
  final CollectController _collectController = inject<CollectController>();
  final HistoryPlaybackService _playbackService =
      inject<HistoryPlaybackService>();
  bool _updatingCollect = false;

  Future<void> _play() async {
    if (widget.editing || widget.busy || dialogs.isRunning) return;
    await dialogs.run((task) async {
      final cancelToken = RuleCancelToken();
      final result = await task.loading(
        message: '获取中',
        barrierDismissible: isDesktop(),
        onCancel: cancelToken.cancel,
        action: () =>
            _playbackService.open(widget.history, cancelToken: cancelToken),
      );
      switch (result) {
        case HistoryPlaybackReady(:final args):
          task.withContext(
              (context) => context.pushNamed('/video/', arguments: args));
        case HistoryPlaybackUnavailable(:final reason):
          KazumiDialog.showToast(message: reason);
      }
    }, errorMessage: '暂时无法继续播放，请稍后重试');
  }

  Future<void> _playNext() async {
    if (widget.editing || widget.busy || dialogs.isRunning) return;
    await dialogs.run((task) async {
      final cancelToken = RuleCancelToken();
      final result = await task.loading(
        message: '获取中',
        barrierDismissible: isDesktop(),
        onCancel: cancelToken.cancel,
        action: () => _playbackService.open(
          widget.history,
          cancelToken: cancelToken,
          nextEpisode: true,
        ),
      );
      switch (result) {
        case HistoryPlaybackReady(:final args):
          task.withContext(
              (context) => context.pushNamed('/video/', arguments: args));
        case HistoryPlaybackUnavailable(:final reason):
          KazumiDialog.showToast(message: reason);
          if (mounted) setState(() {});
      }
    }, errorMessage: '暂时无法播放下一集，请稍后重试');
  }

  Future<void> _changeCollect(CollectType type) async {
    if (_updatingCollect) return;
    setState(() => _updatingCollect = true);
    try {
      await _collectController.addCollect(widget.history.bangumiItem,
          type: type.value);
    } catch (_) {
      KazumiDialog.showToast(message: '修改收藏状态失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _updatingCollect = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (context) {
      // getCollectType reads storage, so track the observable list explicitly.
      _collectController.collectibles.length;
      final hasNext = _playbackService.hasNextEpisode(widget.history);
      return HistoryRecordTile(
        history: widget.history,
        borderRadius: widget.borderRadius,
        editing: widget.editing,
        selected: widget.selected,
        batchMode: widget.batchMode,
        onToggleSelect: widget.onToggleSelect,
        busy: widget.busy,
        onPlay: _play,
        onPlayNext: hasNext ? _playNext : null,
        onDelete: widget.onDelete,
        onDetails: () =>
            context.pushNamed('/info/', arguments: widget.history.bangumiItem),
        collectType: CollectType.fromValue(
            _collectController.getCollectType(widget.history.bangumiItem)),
        onChangeCollect: _updatingCollect ? null : _changeCollect,
      );
    });
  }
}
