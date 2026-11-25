import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/bean/card/bangumi_card.dart';
import 'package:kazumi/bean/card/bangumi_timeline_card.dart';
import 'package:kazumi/bean/widget/anime_pastel_style.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/bangumi/bangumi_tag.dart';
import 'package:kazumi/modules/collect/collect_layout.dart';
import 'package:kazumi/modules/collect/collect_module.dart';
import 'package:kazumi/modules/collect/collect_type.dart';
import 'package:kazumi/modules/history/history_module.dart';
import 'package:kazumi/pages/collect/collect_library_view.dart';
import 'package:kazumi/utils/theme.dart';

void main() {
  test('animePosterColumns computes compact desktop and portrait column counts',
      () {
    expect(animePosterColumns(366, isPortrait: true), 3);
    expect(animePosterColumns(620, isPortrait: true), 4);
    expect(animePosterColumns(860, isPortrait: false), 5);
    expect(animePosterColumns(1200, isPortrait: false), 7);
    expect(animePosterColumns(1360, isPortrait: false), 8);
    expect(animePosterColumns(1560, isPortrait: false), 9);
  });

  test('filterMeaningfulAnimeTags strips noisy format and region metadata', () {
    expect(
      filterMeaningfulAnimeTags(
        const ['TV', 'WEB', '日本', '2026年', '奇幻', '治愈', '日常'],
        limit: 2,
      ),
      const ['奇幻', '治愈'],
    );
  });

  testWidgets('BangumiCardV renders theme-adaptive frame and clean badges',
      (tester) async {
    final topItem = _sampleBangumi(
      id: 101,
      nameCn: '葬送的芙莉莲',
      name: '葬送のフリーレン',
      score: 9.1,
      metaTags: const ['TV', '奇幻', '治愈'],
    );
    final watchingItem = _sampleBangumi(
      id: 102,
      nameCn: '孤独摇滚！',
      name: 'ぼっち・ざ・ろっく！',
      score: 8.8,
      metaTags: const ['WEB', '音乐'],
    );
    const width = 156.0;
    final height = BangumiCardV.extentFor(width, TextScaler.noScaling);

    await tester.pumpWidget(
      MaterialApp(
        theme: applySuperellipseTheme(
          ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
        ),
        home: Scaffold(
          body: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: width,
                height: height,
                child: BangumiCardV(
                  bangumiItem: topItem,
                  rankIndex: 0,
                  isWatching: false,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: width,
                height: height,
                child: BangumiCardV(
                  bangumiItem: watchingItem,
                  rankIndex: 5,
                  isWatching: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('葬送的芙莉莲'), findsOneWidget);
    expect(find.text('葬送のフリーレン'), findsOneWidget);
    expect(find.text('TOP 1'), findsOneWidget);
    expect(find.text('♥ 在追'), findsOneWidget);
    expect(find.text('9.1'), findsOneWidget);
    expect(find.text('TV'), findsNothing);
    expect(find.text('WEB'), findsNothing);
  });

  testWidgets(
      'BangumiTimelineCard renders watching badge, jp subtitle, and filtered tags',
      (tester) async {
    final watchingItem = _sampleBangumi(
      id: 201,
      nameCn: '孤独摇滚！',
      name: 'ぼっち・ざ・ろっく！',
      score: 8.8,
      info: '12话 / 2026年10月',
      metaTags: const ['TV', '日本', '音乐', '日常'],
    );
    final newItem = _sampleBangumi(
      id: 202,
      nameCn: '新番测试',
      name: 'Shinsaku Test',
      score: 0,
      info: '',
      metaTags: const ['WEB', '校园'],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: applySuperellipseTheme(
          ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.teal,
            brightness: Brightness.dark,
          ),
        ),
        home: Scaffold(
          body: Column(
            children: [
              SizedBox(
                width: 380,
                child: BangumiTimelineCard(
                  bangumiItem: watchingItem,
                  showRating: true,
                  isWatching: true,
                  onTap: () {},
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 380,
                child: BangumiTimelineCard(
                  bangumiItem: newItem,
                  showRating: true,
                  isWatching: false,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('♥ 在追'), findsOneWidget);
    expect(find.text('12 话'), findsOneWidget);
    expect(find.text('ぼっち・ざ・ろっく！'), findsOneWidget);
    expect(find.text('音乐'), findsOneWidget);
    expect(find.text('日常'), findsOneWidget);
    expect(find.text('TV'), findsNothing);
    expect(find.text('日本'), findsNothing);
    expect(find.text('8.8'), findsOneWidget);
    expect(find.text('刚开播'), findsOneWidget);
  });

  testWidgets(
      'CollectLibraryView renders linked watch progress in cards and list layouts',
      (tester) async {
    final item = _sampleBangumi(
      id: 301,
      nameCn: '药屋少女的呢喃',
      name: '薬屋のひとりごと',
      score: 8.6,
    );
    final entry = CollectedBangumi(
      item,
      DateTime(2026, 11, 25),
      CollectType.watching.value,
    );
    final history = History(
      item,
      14,
      '樱花动漫',
      DateTime(2026, 11, 25, 19, 0),
      'https://example.com/301',
      '第 14 话',
    );
    history.progresses[14] = Progress(
      14,
      0,
      const Duration(minutes: 14).inMilliseconds,
      totalDurationInMilli: const Duration(minutes: 24).inMilliseconds,
    );

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Future<void> pumpLayout(CollectLayout layout) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: applySuperellipseTheme(
            ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
          ),
          home: Scaffold(
            body: CollectLibraryView(
              entries: [entry],
              watchProgressMap: {item.id: history},
              showRating: true,
              onOpen: (_) {},
              onChangeType: (_, __) {},
              canEdit: (_) => true,
              layout: layout,
              onLayoutChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpLayout(CollectLayout.cards);
    expect(find.text('药屋少女的呢喃'), findsOneWidget);
    expect(find.text('看到 第 14 话 · 58%'), findsOneWidget);

    await pumpLayout(CollectLayout.list);
    expect(find.text('药屋少女的呢喃'), findsOneWidget);
    expect(find.text('看到 第 14 话'), findsOneWidget);
    expect(find.text('58%'), findsOneWidget);
  });

  testWidgets('AnimeSeparatedTabBar switches tabs smoothly with DefaultTabController',
      (tester) async {
    var tapped = -1;
    await tester.pumpWidget(
      MaterialApp(
        theme: applySuperellipseTheme(
          ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
        ),
        home: DefaultTabController(
          length: 3,
          child: Scaffold(
            body: AnimeSeparatedTabBar(
              itemCount: 3,
              scrollable: false,
              onTap: (i) => tapped = i,
              itemBuilder: (context, index, selection, fg) => Text(
                '标签 $index',
                style: TextStyle(color: fg),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('标签 2'));
    await tester.pumpAndSettle();
    expect(tapped, 2);
  });
}

BangumiItem _sampleBangumi({
  required int id,
  required String nameCn,
  required String name,
  double score = 8.5,
  String info = '',
  List<String> metaTags = const [],
}) {
  return BangumiItem(
    id: id,
    type: 2,
    name: name,
    nameCn: nameCn,
    summary: '',
    airDate: '2026-10-01',
    airWeekday: 3,
    rank: 1,
    images: const {
      'large': '',
      'common': '',
      'medium': '',
      'small': '',
      'grid': '',
    },
    tags: const <BangumiTag>[],
    alias: const [],
    ratingScore: score,
    votes: 1000,
    votesCount: const [],
    info: info,
    metaTags: metaTags,
  );
}
