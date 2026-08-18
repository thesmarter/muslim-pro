import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:muslim/generated/lang/app_localizations.dart';
import 'package:muslim/src/core/di/dependency_injection.dart';
import 'package:muslim/src/features/themes/data/models/app_theme_preset.dart';
import 'package:muslim/src/features/themes/data/models/theme_brightness_mode_enum.dart';
import 'package:muslim/src/features/themes/presentation/controller/cubit/theme_cubit.dart';

class ThemeManagerScreen extends StatelessWidget {
  const ThemeManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        final isDark = state.appBrightness == Brightness.dark;
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Text(S.of(context).themeManager),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
          ),
          body: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              ListTile(
                title: Text(
                  S.of(context).themePresets,
                  style: TextStyle(
                    fontSize: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: AppThemePreset.presets.length,
                  itemBuilder: (context, index) {
                    final preset = AppThemePreset.presets[index];
                    final isSelected = state.themePresetId == preset.id;
                    final scheme = preset.schemeFor(state.appBrightness);
                    final previewBg = isDark
                        ? preset.previewBackground
                        : scheme.surface;
                    final previewText = isDark
                        ? Colors.white70
                        : scheme.onSurface.withValues(alpha: 0.7);
                    final selectedText = isDark
                        ? preset.previewPrimary
                        : scheme.primary;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () {
                          context.read<ThemeCubit>().changePreset(preset);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 80,
                          decoration: BoxDecoration(
                            color: previewBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? selectedText : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: preset.previewPrimary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: preset.previewSecondary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                preset.name,
                                style: TextStyle(
                                  color: isSelected ? selectedText : previewText,
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: selectedText,
                                  size: 14,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 32),
              ListTile(
                title: Text(S.of(context).themeAppColor),
                trailing: CircleAvatar(backgroundColor: state.color),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      Color selectedColor = state.color;
                      return AlertDialog(
                        clipBehavior: Clip.hardEdge,
                        contentPadding: EdgeInsets.zero,
                        content: SingleChildScrollView(
                          child: ColorPicker(
                            hexInputBar: true,
                            enableAlpha: false,
                            pickerColor: state.color,
                            labelTypes: const [],
                            onColorChanged: (value) {
                              selectedColor = value;
                            },
                          ),
                        ),
                        actions: <Widget>[
                          ElevatedButton(
                            child: Text(S.of(context).select),
                            onPressed: () {
                              context.read<ThemeCubit>().changeColor(
                                selectedColor,
                              );
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              ListTile(
                title: Text(S.of(context).themeApperance),
                subtitle: Wrap(
                  spacing: 10,
                  children: ThemeBrightnessModeEnum.values
                      .map(
                        (e) => ChoiceChip(
                          label: Text(e.localeName(context)),
                          selected: e == state.themeBrightnessMode,
                          onSelected: (value) {
                            context.read<ThemeCubit>().changeBrightnessMode(e);
                          },
                        ),
                      )
                      .toList(),
                ),
              ),

              SwitchListTile(
                value: state.useMaterial3,
                title: Text(S.of(context).themeUseMaterial3),
                onChanged: (value) {
                  sl<ThemeCubit>().changeUseMaterial3(value);
                },
              ),
              if (!state.useMaterial3)
                SwitchListTile(
                  value: state.useOldTheme,
                  title: Text(S.of(context).themeUserOldTheme),
                  onChanged: state.useMaterial3
                      ? null
                      : (value) {
                          sl<ThemeCubit>().changeUseOldTheme(value);
                        },
                ),
              if (state.themePreset == null)
                SwitchListTile(
                  value: state.overrideBackgroundColor,
                  title: Text(S.of(context).themeOverrideBackground),
                  onChanged: !state.useMaterial3
                      ? null
                      : (value) {
                          sl<ThemeCubit>().changeOverrideBackgroundColor(value);
                        },
                ),
              if (state.overrideBackgroundColor && state.themePreset == null)
                ListTile(
                  title: Text(S.of(context).themeBackgroundColor),
                  trailing: CircleAvatar(
                    backgroundColor: state.backgroundColor,
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        Color selectedColor = state.backgroundColor;
                        return AlertDialog(
                          title: Text(S.of(context).themeBackgroundColor),
                          content: SingleChildScrollView(
                            child: ColorPicker(
                              hexInputBar: true,
                              enableAlpha: false,
                              pickerColor: selectedColor,
                              onColorChanged: (value) {
                                selectedColor = value;
                              },
                            ),
                          ),
                          actions: <Widget>[
                            ElevatedButton(
                              child: Text(S.of(context).select),
                              onPressed: () {
                                context.read<ThemeCubit>().changeBackgroundColor(selectedColor);
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
