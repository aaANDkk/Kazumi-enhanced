import 'dart:async';

import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/history/history_module.dart';
import 'package:kazumi/repositories/history_repository.dart';
import 'package:mobx/mobx.dart';

part 'history_controller.g.dart';

class HistoryController = _HistoryController with _$HistoryController;

abstract class _HistoryController with Store {
  _HistoryController(this._historyRepository) {
    _historySubscription = _historyRepository.changes.listen((_) {
      _scheduleRefresh();
    });
  }

  final IHistoryRepository _historyRepository;
  StreamSubscription<void>? _historySubscription;
  Timer? _refreshDebounceTimer;

  @observable
  ObservableList<History> histories = ObservableList<History>();

  void _scheduleRefresh() {
    _refreshDebounceTimer?.cancel();
    _refreshDebounceTimer = Timer(const Duration(milliseconds: 200), () {
      init();
    });
  }

  void init() {
    final temp = _historyRepository.getAllHistories();
    histories.clear();
    histories.addAll(temp);
  }

  Future<void> updateHistory(
    PlaybackHistoryIdentity identity,
    Duration progress, {
    Duration duration = Duration.zero,
    bool flush = false,
  }) async {
    await _historyRepository.updateHistory(
      identity: identity,
      progress: progress,
      duration: duration,
      flush: flush,
    );
    init();
  }

  Future<void> flush() => _historyRepository.flush();

  Progress? lastWatching(
    BangumiItem bangumiItem,
    String adapterName, {
    String entryKind = HistoryEntryKind.online,
  }) {
    return _historyRepository.getLastWatchingProgress(
      bangumiItem,
      adapterName,
      entryKind: entryKind,
    );
  }

  Progress? findProgress(
    BangumiItem bangumiItem,
    String adapterName,
    int episode, {
    String entryKind = HistoryEntryKind.online,
  }) {
    return _historyRepository.findProgress(
      bangumiItem,
      adapterName,
      episode,
      entryKind: entryKind,
    );
  }

  Future<void> deleteHistory(History history) async {
    await _historyRepository.deleteHistory(history);
    init();
  }

  Future<void> deleteHistories(Iterable<History> items) async {
    for (final item in items) {
      await _historyRepository.deleteHistory(item);
    }
    init();
  }

  Future<void> clearAll() async {
    await _historyRepository.clearAllHistories();
    histories.clear();
  }

  void dispose() {
    _refreshDebounceTimer?.cancel();
    _historySubscription?.cancel();
  }
}
