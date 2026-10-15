import 'dart:io';

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

    test('validates and restores saved window position', () async {
      const targetSize = Size(1000, 700);

      expect(DesktopWindowService.getSavedPosition(targetSize), isNull);

      await GStorage.putSetting(SettingsKeys.windowLeft, 120.0);
      await GStorage.putSetting(SettingsKeys.windowTop, 80.0);

      final pos = DesktopWindowService.getSavedPosition(targetSize);
      expect(pos, isNotNull);
      expect(pos!.dx, 120.0);
      expect(pos.dy, 80.0);
    });

    test('rejects anomalous or out-of-screen window positions', () async {
      const targetSize = Size(1000, 700);

      await GStorage.putSetting(SettingsKeys.windowLeft, 100.0);
      await GStorage.putSetting(SettingsKeys.windowTop, -100.0); // top < -20
      expect(DesktopWindowService.getSavedPosition(targetSize), isNull);

      await GStorage.putSetting(SettingsKeys.windowLeft, 20000.0); // extreme
      await GStorage.putSetting(SettingsKeys.windowTop, 100.0);
      expect(DesktopWindowService.getSavedPosition(targetSize), isNull);
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
