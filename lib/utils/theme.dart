import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kazumi/utils/superellipse.dart';

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

ThemeData applySuperellipseTheme(ThemeData theme) {
  final colors = theme.colorScheme;
  const fullCapsule = SuperellipseBorder(
    borderRadius: BorderRadius.all(Radius.circular(1000)),
  );
  return theme.copyWith(
    cardTheme: const CardThemeData(
      shape: SuperellipseBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    dialogTheme: const DialogThemeData(
      shape: SuperellipseBorder(
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: SuperellipseBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    popupMenuTheme: const PopupMenuThemeData(
      shape: SuperellipseBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    menuTheme: const MenuThemeData(
      style: MenuStyle(
        shape: WidgetStatePropertyAll(
          SuperellipseBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      shape: SuperellipseBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: ShapeDecoration(
        color: colors.inverseSurface,
        shape: const SuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      textStyle: theme.textTheme.bodySmall?.copyWith(
        color: colors.onInverseSurface,
      ),
    ),
    chipTheme: const ChipThemeData(
      shape: SuperellipseBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      shape: SuperellipseBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      indicatorShape: SuperellipseBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      indicatorShape: SuperellipseBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    navigationDrawerTheme: const NavigationDrawerThemeData(
      indicatorShape: SuperellipseBorder(
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: SuperellipseInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    searchBarTheme: const SearchBarThemeData(
      shape: WidgetStatePropertyAll(
        SuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(shape: fullCapsule),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(shape: fullCapsule),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(shape: fullCapsule),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(shape: fullCapsule),
    ),
    segmentedButtonTheme: const SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(fullCapsule),
      ),
    ),
    datePickerTheme: const DatePickerThemeData(
      shape: SuperellipseBorder(
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
    ),
    timePickerTheme: const TimePickerThemeData(
      shape: SuperellipseBorder(
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
    ),
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
