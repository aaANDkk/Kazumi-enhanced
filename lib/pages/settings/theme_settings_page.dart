import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/card/palette_card.dart';
import 'package:kazumi/utils/constants.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/bean/settings/theme_provider.dart';
import 'package:kazumi/bean/settings/color_type.dart';
import 'package:kazumi/bean/settings/settings_detail_scaffold.dart';
import 'package:kazumi/bean/settings/settings_dropdown_tile.dart';
import 'package:kazumi/bean/settings/settings_list.dart';
import 'package:window_manager/window_manager.dart';
import 'package:kazumi/utils/device.dart';
import 'package:kazumi/utils/font_manager.dart';
import 'package:kazumi/utils/theme.dart';

class ThemeSettingsPage extends StatefulWidget {
  const ThemeSettingsPage({super.key});

  @override
  State<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends State<ThemeSettingsPage> {
  late dynamic defaultThemeMode;
  late dynamic defaultThemeColor;
  late bool oledEnhance;
  late bool useDynamicColor;
  late bool showWindowButton;
  late bool useCustomFont;
  late String customFontName;
  late String customFontPath;
  late final ThemeProvider themeProvider;

  @override
  void initState() {
    super.initState();
    defaultThemeMode = GStorage.getSetting(SettingsKeys.themeMode);
    defaultThemeColor = GStorage.getSetting(SettingsKeys.themeColor);
    oledEnhance = GStorage.getSetting(SettingsKeys.oledEnhance);
    useDynamicColor = GStorage.getSetting(SettingsKeys.useDynamicColor);
    showWindowButton = GStorage.getSetting(SettingsKeys.showWindowButton);
    useCustomFont = GStorage.getSetting(SettingsKeys.useCustomFont);
    customFontName = GStorage.getSetting(SettingsKeys.customFontName);
    customFontPath = GStorage.getSetting(SettingsKeys.customFontPath);
    themeProvider = context.read<ThemeProvider>();
  }

  void _applyThemeFont() {
    dynamic color;
    if (defaultThemeColor == 'default') {
      color = Colors.green;
    } else {
      color = Color(int.parse(defaultThemeColor, radix: 16));
    }
    setTheme(color);
  }

  Future<void> _handleCustomFontToggle(bool? value) async {
    final enable = value ?? !useCustomFont;
    if (enable) {
      if (customFontPath.isEmpty || !File(customFontPath).existsSync()) {
        final success = await FontManager.pickAndApplyCustomFont();
        if (!mounted) return;
        if (success) {
          useCustomFont = true;
          customFontName = GStorage.getSetting(SettingsKeys.customFontName);
          customFontPath = GStorage.getSetting(SettingsKeys.customFontPath);
          themeProvider.setCustomFont(true);
          _applyThemeFont();
          setState(() {});
          KazumiDialog.showToast(message: '已应用自定义字体: $customFontName');
        } else {
          KazumiDialog.showToast(message: '未选择 TTF 字体文件');
        }
      } else {
        final success = await FontManager.loadCustomFont(customFontPath);
        if (!mounted) return;
        if (success) {
          useCustomFont = true;
          await GStorage.putSetting(SettingsKeys.useCustomFont, true);
          themeProvider.setCustomFont(true);
          _applyThemeFont();
          setState(() {});
        }
      }
    } else {
      useCustomFont = false;
      await FontManager.disableCustomFont();
      themeProvider.setCustomFont(false);
      _applyThemeFont();
      if (!mounted) return;
      setState(() {});
      KazumiDialog.showToast(message: '已切换为系统默认字体');
    }
  }

  Future<void> _pickNewFont() async {
    final success = await FontManager.pickAndApplyCustomFont();
    if (!mounted) return;
    if (success) {
      useCustomFont = true;
      customFontName = GStorage.getSetting(SettingsKeys.customFontName);
      customFontPath = GStorage.getSetting(SettingsKeys.customFontPath);
      themeProvider.setCustomFont(true);
      _applyThemeFont();
      setState(() {});
      KazumiDialog.showToast(message: '已应用自定义字体: $customFontName');
    }
  }

  void setTheme(Color? color) {
    var defaultDarkTheme = ThemeData(
        useMaterial3: true,
        fontFamily: themeProvider.currentFontFamily,
        brightness: Brightness.dark,
        colorSchemeSeed: color,
        progressIndicatorTheme: progressIndicatorTheme2024,
        sliderTheme: sliderTheme2024,
        pageTransitionsTheme: pageTransitionsTheme2024);
    var oledTheme = oledDarkTheme(defaultDarkTheme);
    themeProvider.setTheme(
      ThemeData(
          useMaterial3: true,
          fontFamily: themeProvider.currentFontFamily,
          brightness: Brightness.light,
          colorSchemeSeed: color,
          progressIndicatorTheme: progressIndicatorTheme2024,
          sliderTheme: sliderTheme2024,
          pageTransitionsTheme: pageTransitionsTheme2024),
      oledEnhance ? oledTheme : defaultDarkTheme,
    );
    defaultThemeColor = color?.toARGB32().toRadixString(16) ?? 'default';
    GStorage.putSetting(SettingsKeys.themeColor, defaultThemeColor);
  }

  void resetTheme() {
    var defaultDarkTheme = ThemeData(
        useMaterial3: true,
        fontFamily: themeProvider.currentFontFamily,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.green,
        progressIndicatorTheme: progressIndicatorTheme2024,
        sliderTheme: sliderTheme2024,
        pageTransitionsTheme: pageTransitionsTheme2024);
    var oledTheme = oledDarkTheme(defaultDarkTheme);
    themeProvider.setTheme(
      ThemeData(
          useMaterial3: true,
          fontFamily: themeProvider.currentFontFamily,
          brightness: Brightness.light,
          colorSchemeSeed: Colors.green,
          progressIndicatorTheme: progressIndicatorTheme2024,
          sliderTheme: sliderTheme2024,
          pageTransitionsTheme: pageTransitionsTheme2024),
      oledEnhance ? oledTheme : defaultDarkTheme,
    );
    defaultThemeColor = 'default';
    GStorage.putSetting(SettingsKeys.themeColor, 'default');
  }

  void updateTheme(String theme) async {
    if (theme == 'dark') {
      themeProvider.setThemeMode(ThemeMode.dark);
    }
    if (theme == 'light') {
      themeProvider.setThemeMode(ThemeMode.light);
    }
    if (theme == 'system') {
      themeProvider.setThemeMode(ThemeMode.system);
    }
    await GStorage.putSetting(SettingsKeys.themeMode, theme);
    setState(() {
      defaultThemeMode = theme;
    });

    // Update Windows title bar theme
    if (Platform.isWindows) {
      await windowManager.setBrightness(
          themeProvider.isEffectiveDark() ? Brightness.dark : Brightness.light);
    }
  }

  void updateOledEnhance() {
    dynamic color;
    oledEnhance = GStorage.getSetting(SettingsKeys.oledEnhance);
    if (defaultThemeColor == 'default') {
      color = Colors.green;
    } else {
      color = Color(int.parse(defaultThemeColor, radix: 16));
    }
    setTheme(color);
  }

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      title: const Text('外观设置'),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: Text('外观'),
            tiles: [
              SettingsDropdownTile<String>(
                leading: Icons.dark_mode_rounded,
                title: const Text('深色模式'),
                value: defaultThemeMode,
                fallbackLabel: '跟随系统',
                options: const {'system': '跟随系统', 'light': '浅色', 'dark': '深色'},
                onChanged: updateTheme,
              ),
              SettingsTile(
                  leading: Icons.palette_rounded,
                  enabled: !useDynamicColor,
                  onPressed: (_) async {
                    KazumiDialog.show(builder: (context) {
                      return AlertDialog(
                        title: Text('配色方案'),
                        content: StatefulBuilder(builder:
                            (BuildContext context, StateSetter setState) {
                          final List<Map<String, dynamic>> colorThemes =
                              colorThemeTypes;
                          return Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: isDesktop() ? 8 : 0,
                            children: [
                              ...colorThemes.map(
                                (e) {
                                  final index = colorThemes.indexOf(e);
                                  return GestureDetector(
                                    onTap: () {
                                      index == 0
                                          ? resetTheme()
                                          : setTheme(e['color']);
                                      KazumiDialog.dismiss();
                                    },
                                    child: Column(
                                      children: [
                                        PaletteCard(
                                          color: e['color'],
                                          selected: (e['color']
                                                      .value
                                                      .toRadixString(16) ==
                                                  defaultThemeColor ||
                                              (defaultThemeColor == 'default' &&
                                                  index == 0)),
                                        ),
                                        Text(e['label']),
                                      ],
                                    ),
                                  );
                                },
                              )
                            ],
                          );
                        }),
                      );
                    });
                  },
                  title: Text('配色方案'),
                ),
                SettingsTile.switchTile(
                  leading: Icons.colorize_rounded,
                  enabled: !Platform.isIOS,
                  onToggle: (value) async {
                    useDynamicColor = value ?? !useDynamicColor;
                    await GStorage.putSetting(
                        SettingsKeys.useDynamicColor, useDynamicColor);
                    themeProvider.setDynamic(useDynamicColor);
                    setState(() {});
                  },
                  title: Text('动态配色'),
                  initialValue: useDynamicColor,
                ),
                SettingsTile.switchTile(
                  leading: Icons.font_download_rounded,
                  onToggle: (value) async {
                    await _handleCustomFontToggle(value);
                  },
                  title: const Text('自定义字体'),
                  description: Text(
                    useCustomFont
                        ? (customFontName.isNotEmpty
                            ? '已启用: $customFontName'
                            : '已开启，点击选择 TTF 字体')
                        : '默认系统字体，开启后可选用自定义 TTF 字体',
                  ),
                  initialValue: useCustomFont,
                ),
                if (useCustomFont)
                  SettingsTile(
                    leading: Icons.folder_open_rounded,
                    title: const Text('选择 / 更换 TTF 字体'),
                    description: Text(customFontName.isNotEmpty
                        ? customFontName
                        : '进入文件管理选择 .ttf 字体文件'),
                    onPressed: (context) async {
                      await _pickNewFont();
                    },
                  ),
              ],
              bottomInfo: Text('动态配色仅支持安卓12及以上和桌面平台'),
            ),
          SettingsSection(
            title: Text('显示'),
            tiles: [
              SettingsTile.switchTile(
                leading: Icons.contrast_rounded,
                onToggle: (value) async {
                  oledEnhance = value ?? !oledEnhance;
                  await GStorage.putSetting(
                      SettingsKeys.oledEnhance, oledEnhance);
                  updateOledEnhance();
                  setState(() {});
                },
                title: Text('OLED优化'),
                description: Text('深色模式下使用纯黑背景'),
                initialValue: oledEnhance,
              ),
            ],
          ),
          if (isDesktop())
            SettingsSection(
              title: Text('窗口'),
              tiles: [
                SettingsTile.switchTile(
                  leading: Icons.web_asset_rounded,
                  onToggle: (value) async {
                    showWindowButton = value ?? !showWindowButton;
                    await GStorage.putSetting(
                        SettingsKeys.showWindowButton, showWindowButton);
                    setState(() {});
                  },
                  title: Text('使用系统标题栏'),
                  description: Text('重启应用生效'),
                  initialValue: showWindowButton,
                ),
              ],
            ),
          if (Platform.isAndroid)
            SettingsSection(
              title: Text('屏幕'),
              tiles: [
                SettingsTile(
                  leading: Icons.sixty_fps_rounded,
                  onPressed: (_) async {
                    context.pushNamed('/settings/theme/display');
                  },
                  title: Text('屏幕帧率'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
