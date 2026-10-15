import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:kazumi/services/platform/desktop_window_service.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:logger/logger.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late PathProviderPlatform originalPaths;

  setUpAll(() async {
    Logger.level = Level.off;
    directory =
        await Directory.systemTemp.createTemp('kazumi_desktop_window_test_');
    originalPaths = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _TestPaths(directory.path);
    Hive.init(directory.path);
    await GStorage.init();
  });

  setUp(() async {
    await GStorage.resetSettings([
      SettingsKeys.windowWidth,
      SettingsKeys.windowHeight,
      SettingsKeys.windowLeft,
      SettingsKeys.windowTop,
      SettingsKeys.windowScaleFactor,
      SettingsKeys.windowIsMaximized,
    ]);
  });

  tearDownAll(() async {
    await Hive.close();
    PathProviderPlatform.instance = originalPaths;
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  group('DesktopWindowService', () {
    test('returns default window size when no saved geometry exists', () async {
      final size = await DesktopWindowService.getInitialWindowSize();
      expect(
        size == DesktopWindowService.defaultNormalSize ||
            size == DesktopWindowService.defaultLowResSize,
        isTrue,
      );
    });

    test('restores saved window size when valid dimensions are stored',
        () async {
      await GStorage.putSetting(SettingsKeys.windowWidth, 1420.0);
      await GStorage.putSetting(SettingsKeys.windowHeight, 920.0);

      final size = await DesktopWindowService.getInitialWindowSize();
      expect(size.width, 1420.0);
      expect(size.height, 920.0);
    });

    test('falls back to default size when stored dimensions are too small',
        () async {
      await GStorage.putSetting(SettingsKeys.windowWidth, 200.0);
      await GStorage.putSetting(SettingsKeys.windowHeight, 150.0);

      final size = await DesktopWindowService.getInitialWindowSize();
      expect(
        size == DesktopWindowService.defaultNormalSize ||
            size == DesktopWindowService.defaultLowResSize,
        isTrue,
      );
    });

    test('saves valid window bounds and scale factor', () async {
      await DesktopWindowService.saveWindowBounds(
        const Rect.fromLTWH(120.0, 80.0, 1100.0, 750.0),
        scaleFactor: 1.5,
      );

      expect(GStorage.getSetting(SettingsKeys.windowWidth), 1100.0);
      expect(GStorage.getSetting(SettingsKeys.windowHeight), 750.0);
      expect(GStorage.getSetting(SettingsKeys.windowLeft), 120.0);
      expect(GStorage.getSetting(SettingsKeys.windowTop), 80.0);
      expect(GStorage.getSetting(SettingsKeys.windowScaleFactor), 1.5);
    });

    test('rejects too small window bounds when saving', () async {
      await DesktopWindowService.saveWindowBounds(
        const Rect.fromLTWH(100.0, 100.0, 100.0, 100.0),
      );

      expect(GStorage.getSetting(SettingsKeys.windowWidth), 0.0);
      expect(GStorage.getSetting(SettingsKeys.windowHeight), 0.0);
    });

    test('restores saved maximized state', () async {
      expect(DesktopWindowService.isSavedMaximized(), isFalse);

      await GStorage.putSetting(SettingsKeys.windowIsMaximized, true);
      expect(DesktopWindowService.isSavedMaximized(), isTrue);

      await GStorage.putSetting(SettingsKeys.windowIsMaximized, false);
      expect(DesktopWindowService.isSavedMaximized(), isFalse);
    });
  });
}

class _TestPaths extends PathProviderPlatform {
  _TestPaths(this.path);
  final String path;

  @override
  Future<String?> getApplicationSupportPath() async => path;
}
