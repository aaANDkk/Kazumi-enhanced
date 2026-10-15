import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kazumi/services/player/pip_utils.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/utils/device.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

abstract final class DesktopWindowService {
  static const Size minWindowSize = Size(380, 400);
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

  /// Restores window position with display boundary checks and DPI adaptation (aligned with Bettbox).
  static Future<void> applyInitialWindowPosition(Size targetSize) async {
    if (Platform.isMacOS) return;
    final left = GStorage.getSetting(SettingsKeys.windowLeft);
    final top = GStorage.getSetting(SettingsKeys.windowTop);
    if (left == null || top == null) {
      await windowManager.setAlignment(Alignment.center);
      return;
    }

    final savedDpr = GStorage.getSetting(SettingsKeys.windowScaleFactor);
    final currentDpr = windowManager.getDevicePixelRatio();

    final physLeft = left * savedDpr;
    final physTop = top * savedDpr;
    final physRight = physLeft + targetSize.width * savedDpr;
    final physBottom = physTop + targetSize.height * savedDpr;

    bool isPositionValid = false;
    try {
      final displays = await screenRetriever.getAllDisplays();
      isPositionValid = displays.any((display) {
        final pos = display.visiblePosition;
        if (pos == null) return false;
        final sf = (display.scaleFactor ?? 1.0).toDouble();
        final physDisplayBounds = Rect.fromLTWH(
          pos.dx * sf,
          pos.dy * sf,
          display.size.width * sf,
          display.size.height * sf,
        );
        return physDisplayBounds.contains(Offset(physLeft, physTop)) ||
            physDisplayBounds.contains(Offset(physRight, physBottom));
      });
    } catch (_) {}

    if (isPositionValid) {
      await windowManager.setPosition(Offset(
        physLeft / currentDpr,
        physTop / currentDpr,
      ));
    } else {
      await windowManager.setAlignment(Alignment.center);
    }
  }

  /// Checks if the window was previously maximized before close.
  static bool isSavedMaximized() {
    return GStorage.getSetting(SettingsKeys.windowIsMaximized);
  }

  /// Persists bounds and DPI scale factor if bounds are valid.
  static Future<void> saveWindowBounds(
    Rect bounds, {
    double? scaleFactor,
  }) async {
    if (!bounds.width.isFinite ||
        !bounds.height.isFinite ||
        bounds.width < minWindowSize.width ||
        bounds.height < minWindowSize.height) {
      return;
    }
    if (!bounds.left.isFinite || !bounds.top.isFinite) return;

    await GStorage.putSetting(SettingsKeys.windowWidth, bounds.width);
    await GStorage.putSetting(SettingsKeys.windowHeight, bounds.height);
    await GStorage.putSetting(SettingsKeys.windowLeft, bounds.left);
    await GStorage.putSetting(SettingsKeys.windowTop, bounds.top);
    if (scaleFactor != null && scaleFactor > 0) {
      await GStorage.putSetting(SettingsKeys.windowScaleFactor, scaleFactor);
    }
  }

  /// Flushes current window geometry synchronously or before exit/close.
  static Future<void> flushWindowGeometry() async {
    if (!isDesktop()) return;
    try {
      final isMax = await windowManager.isMaximized();
      await GStorage.putSetting(SettingsKeys.windowIsMaximized, isMax);
      final isAbnormal = isMax ||
          (await windowManager.isFullScreen()) ||
          (await windowManager.isMinimized()) ||
          PipUtils.isDesktopPIP;
      if (!isAbnormal) {
        final bounds = await windowManager.getBounds();
        await saveWindowBounds(
          bounds,
          scaleFactor: windowManager.getDevicePixelRatio(),
        );
      }
    } catch (_) {}
  }

  /// Restores normal desktop window geometry when exiting PIP mode.
  static Future<void> restoreFromPip() async {
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setAspectRatio(0);
    final targetSize = await getInitialWindowSize();
    await windowManager.setSize(targetSize);
    await applyInitialWindowPosition(targetSize);
    if (isSavedMaximized()) {
      await windowManager.maximize();
    }
  }
}
