import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'package:kazumi/bean/appbar/sys_app_bar.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/bean/widget/anime_pastel_style.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/bangumi/sync_priority.dart';
import 'package:kazumi/modules/collect/collect_layout.dart';
import 'package:kazumi/modules/collect/collect_sync_plan.dart';
import 'package:kazumi/modules/collect/collect_type.dart';
import 'package:kazumi/modules/history/history_module.dart';
import 'package:kazumi/pages/collect/collect_controller.dart';
import 'package:kazumi/pages/collect/collect_library_view.dart';
import 'package:kazumi/pages/collect/collect_sync_dialog.dart';
import 'package:kazumi/pages/history/history_controller.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/utils/superellipse.dart';

class CollectPage extends StatefulWidget {
  const CollectPage({
    super.key,
    required this.controller,
    this.historyController,
  });

  final CollectController controller;
  final HistoryController? historyController;

  @override
  State<CollectPage> createState() => _CollectPageState();
}

class _CollectPageState extends State<CollectPage> with KazumiDialogOwner {
  CollectController get collectController => widget.controller;
  bool get _syncDialogOpen => dialogs.isRunning;
  final Set<int> _pendingIds = {};
  final _libraryKey = GlobalKey<CollectLibraryViewState>();
  late CollectLayout _layout;

  Future<bool> _syncStep(
    CollectSyncStep step, {
    required ValueChanged<String> onError,
    required void Function(String message, int current, int total) onProgress,
  }) =>
      switch (step) {
        CollectSyncStep.webDav => collectController.syncCollectibles(
            onError: onError,
          ),
        CollectSyncStep.bangumi => collectController.syncCollectiblesBangumi(
            onError: onError,
            onProgress: onProgress,
          ),
        CollectSyncStep.upload => collectController.uploadCollectiblesToWebDav(
            onError: onError,
          ),
      };

  @override
  void initState() {
    super.initState();
    collectController.scrollToTop = _scrollToTop;
    // Read once; page switches never change the saved default.
    _layout = CollectLayout.fromValue(
      GStorage.getSetting(SettingsKeys.defaultCollectLayout),
    );
    collectController.loadCollectibles();
    final historyCtrl = widget.historyController;
    if (historyCtrl != null && historyCtrl.histories.isEmpty) {
      historyCtrl.init();
    }
  }

  @override
  void dispose() {
    if (collectController.scrollToTop == _scrollToTop) {
      collectController.scrollToTop = null;
    }
    super.dispose();
  }

  void _scrollToTop() {
    _libraryKey.currentState?.scrollToTop();
  }

  void _changeLayout(CollectLayout layout) {
    if (_layout == layout) return;
    setState(() => _layout = layout);
  }

  Future<void> _changeType(BangumiItem item, CollectType type) async {
    if (_syncDialogOpen || _pendingIds.contains(item.id)) return;
    setState(() => _pendingIds.add(item.id));
    try {
      await collectController.addCollect(item, type: type.value);
    } catch (_) {
      KazumiDialog.showToast(message: '修改收藏状态失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _pendingIds.remove(item.id));
    }
  }

  Future<void> _sync() async {
    if (_syncDialogOpen || _pendingIds.isNotEmpty) return;
    final plan = CollectSyncPlan(
      webDavEnabled: GStorage.getSetting(SettingsKeys.webDavEnable),
      webDavCollectiblesEnabled:
          GStorage.getSetting(SettingsKeys.webDavEnableCollect),
      bangumiEnabled: GStorage.getSetting(SettingsKeys.bangumiSyncEnable),
    );
    await dialogs.run((task) async {
      final destination = await task.show<CollectSyncDestination>(
        builder: (_) => CollectSyncDialog(
          plan: plan,
          priority: BangumiSyncPriority.fromValue(
            GStorage.getSetting(SettingsKeys.bangumiSyncPriority),
          ),
          onSync: _syncStep,
        ),
      );
      task.withContext((context) => context.pushNamed(switch (destination) {
            CollectSyncDestination.webDavSettings => '/settings/webdav/',
            CollectSyncDestination.bangumiSettings => '/settings/bangumi/',
          }));
    }, errorMessage: '同步未完成，请稍后重试');
  }

  Map<int, History> _buildLatestHistoryMap() {
    final historyCtrl = widget.historyController;
    if (historyCtrl == null) return const <int, History>{};
    final map = <int, History>{};
    for (final h in historyCtrl.histories) {
      final existing = map[h.bangumiItem.id];
      if (existing == null || h.lastWatchTime.isAfter(existing.lastWatchTime)) {
        map[h.bangumiItem.id] = h;
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AnimePastelPalette.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 680;

    return Scaffold(
      extendBody: true,
      appBar: SysAppBar(
        needTopOffset: false,
        toolbarHeight: 68,
        backgroundColor: Colors.transparent,
        title: Observer(
          builder: (context) {
            final entries = collectController.collectibles;
            var watching = 0;
            var plan = 0;
            var watched = 0;
            for (final e in entries) {
              if (e.type == CollectType.watching.value) {
                watching++;
              } else if (e.type == CollectType.planToWatch.value) {
                plan++;
              } else if (e.type == CollectType.watched.value) {
                watched++;
              }
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✿ MY ANIME SHELF · 追番收藏馆',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: palette.sakura,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '我的追番',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (isWide && entries.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Text(
                        '在看 $watching · 想看 $plan · 看过 $watched',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: palette.subtext,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Tooltip(
              message: '同步收藏',
              child: Material(
                type: MaterialType.transparency,
                shape:
                    SuperellipseBorder(borderRadius: BorderRadius.circular(14)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  customBorder: SuperellipseBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onTap: _syncDialogOpen || _pendingIds.isNotEmpty
                      ? null
                      : _sync,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: palette.sakuraSoft,
                      shape: SuperellipseBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: palette.frameBorder, width: 0.9),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sync_rounded,
                            size: 16,
                            color: palette.sakura,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '同步',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: palette.sakura,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: AnimePastelBackdrop(
        child: SafeArea(
          top: false,
          bottom: false,
          child: Observer(
            builder: (context) => CollectLibraryView(
              key: _libraryKey,
              entries: collectController.collectibles.toList(),
              watchProgressMap: _buildLatestHistoryMap(),
              showRating: GStorage.getSetting(SettingsKeys.showRating),
              layout: _layout,
              onLayoutChanged: _changeLayout,
              canEdit: (item) =>
                  !_syncDialogOpen && !_pendingIds.contains(item.id),
              onOpen: (item) => context.pushNamed('/info/', arguments: item),
              onChangeType: (item, type) => unawaited(_changeType(item, type)),
            ),
          ),
        ),
      ),
    );
  }
}
