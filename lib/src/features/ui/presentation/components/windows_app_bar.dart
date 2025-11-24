import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/generated/lang/app_localizations.dart';
import 'package:muslim/src/core/di/dependency_injection.dart';
import 'package:muslim/src/core/extensions/extension_platform.dart';
import 'package:muslim/src/features/themes/data/models/theme_brightness_mode_enum.dart';
import 'package:muslim/src/features/themes/presentation/controller/cubit/theme_cubit.dart';
import 'package:muslim/src/features/ui/presentation/components/windows_button.dart';
import 'package:window_manager/window_manager.dart';

class UIAppBar extends StatefulWidget {
  final BuildContext? shellContext;

  const UIAppBar({super.key, this.shellContext});

  @override
  State<UIAppBar> createState() => _UIAppBarState();
}

class _UIAppBarState extends State<UIAppBar> {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        padding: const EdgeInsets.only(left: 10),
        height: kToolbarHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (kIsWeb)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(S.of(context).elmoslemPro),
              ),
            if (PlatformExtension.isDesktop)
              Expanded(
                child: DragToMoveArea(
                  child: Row(
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Image.asset("assets/images/app_icon.png"),
                        ),
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(S.of(context).elmoslemPro),
                      ),
                    ],
                  ),
                ),
              ),
            BlocBuilder<ThemeCubit, ThemeState>(
              builder: (context, state) {
                return Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8.0),
                    child: ChoiceChip(
                      selected: state.deviceBrightness == Brightness.dark,
                      showCheckmark: false,
                      label: Icon(switch (state.themeBrightnessMode) {
                        ThemeBrightnessModeEnum.dark => Icons.dark_mode,
                        ThemeBrightnessModeEnum.light => Icons.light_mode,
                        ThemeBrightnessModeEnum.system =>
                          Icons.brightness_medium_outlined,
                      }),
                      onSelected: (v) {
                        sl<ThemeCubit>().toggleBrightnessMode();
                      },
                    ),
                  ),
                );
              },
            ),
            if (!kIsWeb) const WindowButtons(),
          ],
        ),
      ),
    );
  }
}
