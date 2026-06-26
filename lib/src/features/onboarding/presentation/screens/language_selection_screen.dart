import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:muslim/src/core/di/dependency_injection.dart';
import 'package:muslim/src/features/home/presentation/screens/home_screen.dart';
import 'package:muslim/src/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:muslim/src/features/settings/data/repository/app_settings_repo.dart';
import 'package:muslim/src/features/themes/presentation/controller/cubit/theme_cubit.dart';
import 'package:package_info_plus/package_info_plus.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const languages = <_LanguageOption>[
      _LanguageOption('ar', 'العربية', 'English', '🇸🇦'),
      _LanguageOption('en', 'English', 'English', '🇬🇧'),
      _LanguageOption('fr', 'Français', 'French', '🇫🇷'),
      _LanguageOption('tr', 'Türkçe', 'Turkish', '🇹🇷'),
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Icon(
                Icons.translate,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Choose Your Language',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select your preferred language for the app',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              ...languages.map((lang) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _onLanguageSelected(context, lang),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(lang.flag, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Column(
                          children: [
                            Text(
                              lang.nativeName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              lang.englishName,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  void _onLanguageSelected(BuildContext context, _LanguageOption lang) {
    sl<ThemeCubit>().changeAppLocale(lang.code);
    sl<GetStorage>().write('language_chosen', true);

    final version = sl<PackageInfo>().version;
    final currentVersion = sl<AppSettingsRepo>().currentVersion;
    final nextScreen = currentVersion != version
        ? const OnBoardingScreen()
        : const HomeScreen();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }
}

class _LanguageOption {
  final String code;
  final String nativeName;
  final String englishName;
  final String flag;
  const _LanguageOption(this.code, this.nativeName, this.englishName, this.flag);
}
