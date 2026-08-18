part of 'theme_cubit.dart';

class ThemeState extends Equatable {
  final Color color;
  final Brightness deviceBrightness;
  final bool useMaterial3;
  final Color backgroundColor;
  final bool overrideBackgroundColor;
  final bool useOldTheme;
  final String fontFamily;
  final Locale? locale;
  final ThemeBrightnessModeEnum themeBrightnessMode;
  final String? themePresetId;
  final AppThemePreset? themePreset;
  const ThemeState({
    required this.color,
    required this.deviceBrightness,
    required this.useMaterial3,
    required this.backgroundColor,
    required this.overrideBackgroundColor,
    required this.useOldTheme,
    required this.fontFamily,
    required this.locale,
    required this.themeBrightnessMode,
    this.themePresetId,
    this.themePreset,
  });

  Brightness get appBrightness {
    switch (themeBrightnessMode) {
      case ThemeBrightnessModeEnum.system:
        return deviceBrightness;

      case ThemeBrightnessModeEnum.dark:
        return Brightness.dark;

      case ThemeBrightnessModeEnum.light:
        return Brightness.light;
    }
  }

  ThemeData get theme {
    final brightness = appBrightness;

    if (themePreset != null) {
      final customTheme = themePreset!.themeFor(brightness);
      if (customTheme != null) {
        return customTheme;
      }
      final scheme = themePreset!.schemeFor(brightness);
      return ThemeData(
        colorScheme: scheme,
        useMaterial3: useMaterial3,
        fontFamily: fontFamily,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: appBarTheme(),
        scaffoldBackgroundColor: scheme.surface,
        actionIconTheme: ActionIconThemeData(
          backButtonIconBuilder: (context) => const AppBackButton(),
        ),
      );
    }

    if (useOldTheme && !useMaterial3) {
      return ThemeData(
        useMaterial3: false,
        brightness: brightness,
        colorSchemeSeed: color,
        fontFamily: fontFamily,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: appBarTheme(),
        actionIconTheme: ActionIconThemeData(
          backButtonIconBuilder: (context) => const AppBackButton(),
        ),
      );
    }
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: color,
        brightness: brightness,
        surface: overrideBackgroundColor ? backgroundColor : null,
      ),
      appBarTheme: appBarTheme(),
      useMaterial3: useMaterial3,
      fontFamily: fontFamily,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (context) => const AppBackButton(),
      ),
    );
  }

  AppBarTheme appBarTheme() {
    return const AppBarTheme(
      scrolledUnderElevation: 10,
      elevation: 0,
      centerTitle: true,
    );
  }

  ThemeState copyWith({
    Color? color,
    Brightness? deviceBrightness,
    bool? useMaterial3,
    Color? backgroundColor,
    bool? overrideBackgroundColor,
    bool? useOldTheme,
    String? fontFamily,
    Locale? locale,
    ThemeBrightnessModeEnum? themeBrightnessMode,
    String? themePresetId,
    AppThemePreset? themePreset,
  }) {
    return ThemeState(
      color: color ?? this.color,
      deviceBrightness: deviceBrightness ?? this.deviceBrightness,
      useMaterial3: useMaterial3 ?? this.useMaterial3,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      overrideBackgroundColor: overrideBackgroundColor ?? this.overrideBackgroundColor,
      useOldTheme: useOldTheme ?? this.useOldTheme,
      fontFamily: fontFamily ?? this.fontFamily,
      locale: locale ?? this.locale,
      themeBrightnessMode: themeBrightnessMode ?? this.themeBrightnessMode,
      themePresetId: themePresetId ?? this.themePresetId,
      themePreset: themePreset ?? this.themePreset,
    );
  }

  @override
  List<Object?> get props {
    return [
      color,
      deviceBrightness,
      useMaterial3,
      backgroundColor,
      overrideBackgroundColor,
      useOldTheme,
      fontFamily,
      locale,
      themeBrightnessMode,
      themePresetId,
      themePreset,
    ];
  }
}
