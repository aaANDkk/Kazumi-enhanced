import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

SystemUiOverlayStyle systemUiOverlayStyleForBrightness(Brightness brightness) {
  final iconBrightness =
      brightness == Brightness.light ? Brightness.dark : Brightness.light;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: iconBrightness,
    statusBarBrightness: brightness,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: iconBrightness,
    systemNavigationBarContrastEnforced: false,
  );
}

AppBarTheme appBarThemeForBrightness(Brightness brightness) {
  return AppBarTheme(
    systemOverlayStyle: systemUiOverlayStyleForBrightness(brightness),
  );
}

ThemeData oledDarkTheme(ThemeData defaultDarkTheme) {
  return defaultDarkTheme.copyWith(
    scaffoldBackgroundColor: Colors.black,
    colorScheme: defaultDarkTheme.colorScheme.copyWith(
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      surface: Colors.black,
      onSurface: Colors.white,
    ),
  );
}
