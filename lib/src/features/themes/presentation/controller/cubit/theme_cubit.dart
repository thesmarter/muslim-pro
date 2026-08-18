import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:muslim/src/features/themes/data/models/app_theme_preset.dart';
import 'package:muslim/src/features/themes/data/models/theme_brightness_mode_enum.dart';
import 'package:muslim/src/features/themes/data/repository/theme_repo.dart';
import 'package:muslim/src/features/themes/presentation/components/app_back_button.dart';

part 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  final ThemeRepo themeRepo;
  ThemeCubit(this.themeRepo)
    : super(
        _buildInitialState(themeRepo),
      );

  static ThemeState _buildInitialState(ThemeRepo themeRepo) {
    final presetId = themeRepo.getThemePreset();
    final preset = presetId != null ? AppThemePreset.findById(presetId) : null;

    if (preset != null) {
      return ThemeState(
        deviceBrightness: Brightness.light,
        color: preset.schemeFor(Brightness.light).primary,
        useMaterial3: themeRepo.getUseMaterial3(),
        useOldTheme: themeRepo.getUseOldTheme(),
        fontFamily: themeRepo.fontFamily,
        backgroundColor: preset.schemeFor(Brightness.light).surface,
        overrideBackgroundColor: true,
        locale: themeRepo.appLocale,
        themeBrightnessMode: themeRepo.getThemeBrightnessMode(),
        themePresetId: presetId,
        themePreset: preset,
      );
    }

    return ThemeState(
      deviceBrightness: Brightness.light,
      color: themeRepo.getColor(),
      useMaterial3: themeRepo.getUseMaterial3(),
      useOldTheme: themeRepo.getUseOldTheme(),
      fontFamily: themeRepo.fontFamily,
      backgroundColor: themeRepo.getBackgroundColor(),
      overrideBackgroundColor: themeRepo.getOverrideBackgroundColor(),
      locale: themeRepo.appLocale,
      themeBrightnessMode: themeRepo.getThemeBrightnessMode(),
      themePresetId: null,
      themePreset: null,
    );
  }

  bool get shouldShowMigrationDialog {
    if (themeRepo.getThemeMigrationShown()) return false;
    return themeRepo.isExistingUser;
  }

  void markMigrationShown() {
    themeRepo.setThemeMigrationShown();
  }

  Future<void> applyRawhPresetForMigration() async {
    final rawh = AppThemePreset.findById('rawh');
    if (rawh != null) {
      await changePreset(rawh);
      markMigrationShown();
    }
  }

  void dismissMigration() {
    markMigrationShown();
  }

  Future start() async {}

  ///MARK: Theme Preset
  Future<void> changePreset(AppThemePreset preset) async {
    await themeRepo.setThemePreset(preset.id);
    final scheme = preset.schemeFor(state.appBrightness);
    await themeRepo.setColor(scheme.primary);
    await themeRepo.setBackgroundColor(scheme.surface);
    await themeRepo.setOverrideBackgroundColor(true);
    emit(
      state.copyWith(
        themePresetId: preset.id,
        themePreset: preset,
        color: scheme.primary,
        backgroundColor: scheme.surface,
        overrideBackgroundColor: true,
      ),
    );
  }

  ///MARK:Theme
  Future<void> changeDeviceBrightness(Brightness brightness) async {
    final preset = state.themePreset;
    if (preset != null) {
      final scheme = preset.schemeFor(brightness);
      emit(
        state.copyWith(
          deviceBrightness: brightness,
          color: scheme.primary,
          backgroundColor: scheme.surface,
        ),
      );
    } else {
      emit(state.copyWith(deviceBrightness: brightness));
    }
  }

  Future<void> changeBrightnessMode(
    ThemeBrightnessModeEnum brightnessMode,
  ) async {
    await themeRepo.setThemeBrightnessMode(brightnessMode);
    final preset = state.themePreset;
    Brightness newBrightness;
    switch (brightnessMode) {
      case ThemeBrightnessModeEnum.system:
        newBrightness = state.deviceBrightness;
      case ThemeBrightnessModeEnum.dark:
        newBrightness = Brightness.dark;
      case ThemeBrightnessModeEnum.light:
        newBrightness = Brightness.light;
    }
    if (preset != null) {
      final scheme = preset.schemeFor(newBrightness);
      emit(
        state.copyWith(
          themeBrightnessMode: brightnessMode,
          color: scheme.primary,
          backgroundColor: scheme.surface,
        ),
      );
    } else {
      emit(state.copyWith(themeBrightnessMode: brightnessMode));
    }
  }

  Future<void> toggleBrightnessMode() async {
    changeBrightnessMode(state.themeBrightnessMode.toggle());
  }

  Future<void> changeUseMaterial3(bool useMaterial3) async {
    await themeRepo.setUseMaterial3(useMaterial3);
    emit(state.copyWith(useMaterial3: useMaterial3));
  }

  Future<void> changeUseOldTheme(bool useOldTheme) async {
    await themeRepo.setUseOldTheme(useOldTheme);
    emit(state.copyWith(useOldTheme: useOldTheme));
  }

  Future<void> changeColor(Color color) async {
    await themeRepo.setColor(color);
    emit(state.copyWith(color: color, themePresetId: null, themePreset: null));
  }

  Future<void> changeBackgroundColor(Color color) async {
    await themeRepo.setBackgroundColor(color);
    emit(state.copyWith(backgroundColor: color));
  }

  Future<void> changeOverrideBackgroundColor(
    bool overrideBackgroundColor,
  ) async {
    await themeRepo.setOverrideBackgroundColor(overrideBackgroundColor);
    emit(state.copyWith(overrideBackgroundColor: overrideBackgroundColor));
  }

  ///MARK:Font Family
  Future<void> changeFontFamily(String fontFamily) async {
    await themeRepo.changFontFamily(fontFamily);
    emit(state.copyWith(fontFamily: fontFamily));
  }

  ///MARK: App Locale
  Future<void> changeAppLocale(String locale) async {
    await themeRepo.changAppLocale(locale);
    Intl.defaultLocale = Locale(locale).languageCode;
    emit(state.copyWith(locale: Locale(locale)));
  }
}
