import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:kazumi/services/logging/logger.dart';
import 'package:kazumi/services/player/pip_utils.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/utils/device.dart';
import 'package:window_manager/window_manager.dart';

abstract final class DesktopWindowService {
  static const Size minWindowSize = Size(500, 380);
  static const Size defaultLowResSize = Size(840, 600);
  static const Size defaultNormalSize = Size(1280, 860);

  /// Computes the initial window size, preferring saved geometry.
  static Future<Size> getInitialWindowSize() async {
    final savedWidth = GStorage.getSetting(SettingsKeys.windowWidth);
    final savedHeight = GStorage.getSetting(SettingsKeys.windowHeight);
    if (savedWidth.isFinite &&
        savedHeight.isFinite &&
        savedWidth >= minWindowSize.width &&
        savedHeight >= minWindowSize.height) {
      return Size(savedWidth, savedHeight);
    }
    final lowResolution = await isLowResolution();
    return lowResolution ? defaultLowResSize : defaultNormalSize;
  }

  /// Checks if the saved window position is valid (not off-screen).
  static bool hasValidSavedPosition(Size targetSize) {
    final left = GStorage.getSetting(SettingsKeys.windowLeft);
    final top = GStorage.getSetting(SettingsKeys.windowTop);
    if (left == null || top == null) return false;
    if (!left.isFinite || !top.isFinite) return false;

    // Reject extreme coordinate anomalies
    if (top < -20 || top > 10000 || left < -10000 || left > 10000) {
      return false;
    }

    try {
      final displays = WidgetsBinding.instance.platformDispatcher.displays;
      if (displays.isNotEmpty) {
        bool onAnyScreen = false;
        for (final display in displays) {
          final displayWidth = display.size.width;
          final displayHeight = display.size.height;
          // Ensure title bar/top-left area intersects with this display
          if (left < displayWidth - 50 &&
              left + targetSize.width > 50 &&
              top < displayHeight - 50 &&
              top + 50 > 0) {
            onAnyScreen = true;
            break;
          }
        }
        if (!onAnyScreen) return false;
      }
    } catch (_) {}

    return true;
  }

  /// Retrieves the validated saved position or null if unavailable/invalid.
  static Offset? getSavedPosition(Size targetSize) {
    if (!hasValidSavedPosition(targetSize)) return null;
    final left = GStorage.getSetting(SettingsKeys.windowLeft)!;
    final top = GStorage.getSetting(SettingsKeys.windowTop)!;
    return Offset(left, top);
  }

  /// Checks if the window was previously maximized before close.
  static bool isSavedMaximized() {
    return GStorage.getSetting(SettingsKeys.windowIsMaximized);
  }

  /// Captures current window size, position, and maximized state and persists them.
  static Future<void> captureAndSaveGeometry() async {
    if (!isDesktop()) return;
    try {
      final isMaximized = await windowManager.isMaximized();
      final isFullScreen = await windowManager.isFullScreen();
      final isMinimized = await windowManager.isMinimized();

      // Never overwrite regular window geometry during fullscreen, minimize, or PIP
      if (isFullScreen || isMinimized || PipUtils.isDesktopPIP) {
        return;
      }

      await GStorage.putSetting(SettingsKeys.windowIsMaximized, isMaximized);

      // Only record width/height/position for normal (non-maximized) state
      if (!isMaximized) {
        final bounds = await windowManager.getBounds();
        if (bounds.width.isFinite &&
            bounds.height.isFinite &&
            bounds.width >= minWindowSize.width &&
            bounds.height >= minWindowSize.height) {
          await GStorage.putSetting(SettingsKeys.windowWidth, bounds.width);
          await GStorage.putSetting(SettingsKeys.windowHeight, bounds.height);
          if (bounds.left.isFinite && bounds.top.isFinite) {
            await GStorage.putSetting(SettingsKeys.windowLeft, bounds.left);
            await GStorage.putSetting(SettingsKeys.windowTop, bounds.top);
          }
        }
      }
    } catch (e) {
      KazumiLogger().w('Failed to capture window geometry: $e');
    }
  }

  /// Restores normal desktop window geometry when exiting PIP mode.
  static Future<void> restoreFromPip() async {
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setAspectRatio(0);
    final targetSize = await getInitialWindowSize();
    final savedPosition = getSavedPosition(targetSize);
    final savedIsMaximized = isSavedMaximized();

    await windowManager.setSize(targetSize);
    if (savedPosition != null) {
      await windowManager.setPosition(savedPosition);
    } else {
      await windowManager.center();
    }
    if (savedIsMaximized) {
      await windowManager.maximize();
    }
  }
}
