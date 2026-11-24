import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/bangumi/bangumi_tag.dart';
import 'package:kazumi/modules/collect/collect_type.dart';
import 'package:kazumi/modules/history/history_module.dart';
import 'package:kazumi/pages/history/history_record_tile.dart';

void main() {
  Widget wrapTile(
    History history, {
    VoidCallback? onPlayNext,
    Brightness brightness = Brightness.light,
  }) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        brightness: brightness,
      ),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 390,
            child: HistoryRecordTile(
              history: history,
              onPlay: () {},
              onPlayNext: onPlayNext,
              onDetails: () {},
              onDelete: () async {},
              collectType: CollectType.watching,
              onChangeCollect: (_) {},
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders inline progress capsule for active watching state',
      (tester) async {
    final history = _history(
      id: 1,
      progress: Progress(
        12,
        0,
        const Duration(minutes: 14, seconds: 23).inMilliseconds,
        totalDurationInMilli:
            const Duration(minutes: 23, seconds: 40).inMilliseconds,
      ),
      episode: 12,
      episodeName: '第 12 话',
    );

    await tester.pumpWidget(wrapTile(history, onPlayNext: () {}));
    expect(find.text('14:23 / 23:40'), findsOneWidget);
    expect(find.text('61%'), findsOneWidget);
    expect(find.text('下集'), findsOneWidget);
  });

  testWidgets(
      'renders completed 100% capsule and replay action when isCompleted is true',
      (tester) async {
    final history = _history(
      id: 2,
      progress: Progress(
        24,
        0,
        0,
        totalDurationInMilli:
            const Duration(minutes: 23, seconds: 40).inMilliseconds,
        isCompleted: true,
      ),
      episode: 24,
      episodeName: '第 24 话',
    );

    await tester.pumpWidget(wrapTile(history, brightness: Brightness.dark));
    expect(find.text('23:40 / 23:40'), findsOneWidget);
    expect(find.text('已看完'), findsOneWidget);
    expect(find.text('重播'), findsOneWidget);
  });

  testWidgets('renders unknown total duration capsule when only position exists',
      (tester) async {
    final history = _history(
      id: 3,
      progress: Progress(
        5,
        0,
        const Duration(minutes: 8, seconds: 15).inMilliseconds,
      ),
      episode: 5,
      episodeName: '第 05 话',
    );

    await tester.pumpWidget(wrapTile(history, onPlayNext: () {}));
    expect(find.text('看到 8:15'), findsOneWidget);
    expect(find.text('未知总长'), findsOneWidget);
  });

  testWidgets('renders unified empty progress capsule without blank gap',
      (tester) async {
    final history = _history(
      id: 4,
      progress: Progress(1, 0, 0),
      episode: 1,
      episodeName: '第 01 话',
    );

    await tester.pumpWidget(wrapTile(history, onPlayNext: () {}));
    expect(find.text('暂无观看进度'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
  });
}

History _history({
  required int id,
  required Progress progress,
  required int episode,
  required String episodeName,
}) {
  final item = BangumiItem(
    id: id,
    type: 2,
    name: 'Subject $id',
    nameCn: '番剧 $id',
    summary: '',
    airDate: '2026-01-01',
    airWeekday: 1,
    rank: 0,
    images: const {
      'large': '',
      'common': '',
      'medium': '',
      'small': '',
      'grid': '',
    },
    tags: const <BangumiTag>[],
    alias: const [],
    ratingScore: 0,
    votes: 0,
    votesCount: const [],
    info: '',
  );
  final history = History(
    item,
    episode,
    '樱花动漫',
    DateTime(2026, 11, 24, 21, 30),
    'https://example.com/$id',
    episodeName,
  );
  history.progresses[episode] = progress;
  return history;
}
