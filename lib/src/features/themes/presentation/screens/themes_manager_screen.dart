import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:muslim/generated/l10n.dart';
import 'package:muslim/src/core/di/dependency_injection.dart';
import 'package:muslim/src/features/themes/data/models/app_colors.dart';
import 'package:muslim/src/features/themes/presentation/controller/cubit/theme_cubit.dart';

class ThemeManagerScreen extends StatelessWidget {
  const ThemeManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Text(
              S.of(context).themeManager,
            ),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
          ),
          body: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              ListTile(
                title: Text(S.of(context).themeAppColor),
                trailing: CircleAvatar(
                  backgroundColor: state.color,
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      Color selectedColor = state.color;
                      return AlertDialog(
                        title: Text(S.of(context).themeAppColor),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // شبكة الألوان المحددة مسبقاً
                              Text(
                                'الألوان المقترحة',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 16),
                              GridView.builder(
                                shrinkWrap: true,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: AppColors.availableColors.length,
                                itemBuilder: (context, index) {
                                  final color =
                                      AppColors.availableColors[index];
                                  final isSelected = color == selectedColor;
                                  return GestureDetector(
                                    onTap: () {
                                      selectedColor = color;
                                      context
                                          .read<ThemeCubit>()
                                          .changeColor(selectedColor);
                                      Navigator.of(context).pop();
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(12),
                                        border: isSelected
                                            ? Border.all(
                                                color: Colors.white, width: 3)
                                            : null,
                                        boxShadow: [
                                          BoxShadow(
                                            color: color.withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 24,
                                            )
                                          : null,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 16),
                              // منتقي الألوان المخصص
                              Text(
                                'اختيار لون مخصص',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 16),
                              ColorPicker(
                                hexInputBar: true,
                                enableAlpha: false,
                                pickerColor: selectedColor,
                                labelTypes: const [],
                                onColorChanged: (value) {
                                  selectedColor = value;
                                },
                              ),
                            ],
                          ),
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: Text(S.of(context).cancel),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          ElevatedButton(
                            child: Text(S.of(context).select),
                            onPressed: () {
                              context
                                  .read<ThemeCubit>()
                                  .changeColor(selectedColor);
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              SwitchListTile(
                value: state.brightness == Brightness.dark,
                title: Text(S.of(context).themeDarkMode),
                onChanged: (value) {
                  if (state.brightness == Brightness.dark) {
                    context
                        .read<ThemeCubit>()
                        .changeBrightness(Brightness.light);
                  } else {
                    context
                        .read<ThemeCubit>()
                        .changeBrightness(Brightness.dark);
                  }
                },
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
              SwitchListTile(
                value: state.overrideBackgroundColor,
                title: Text(S.of(context).themeOverrideBackground),
                onChanged: !state.useMaterial3
                    ? null
                    : (value) {
                        sl<ThemeCubit>().changeOverrideBackgroundColor(value);
                      },
              ),
              if (state.overrideBackgroundColor)
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
                                context
                                    .read<ThemeCubit>()
                                    .changeBackgroundColor(selectedColor);
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
