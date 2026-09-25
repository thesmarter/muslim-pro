import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:muslim/generated/lang/app_localizations.dart';
import 'package:muslim/src/features/themes/data/models/app_theme_preset.dart';
import 'package:muslim/src/features/themes/data/models/theme_brightness_mode_enum.dart';
import 'package:muslim/src/features/themes/presentation/components/theme_selection_dialog.dart';
import 'package:muslim/src/features/themes/presentation/controller/cubit/theme_cubit.dart';

class MockThemeCubit extends Mock implements ThemeCubit {}

void main() {
  late MockThemeCubit mockThemeCubit;

  setUp(() {
    mockThemeCubit = MockThemeCubit();
    // Start on Rawh (Cairo) so swapping to AlHeek (Amiri) lerps two
    // fully-specified preset button text styles against each other.
    when(() => mockThemeCubit.state).thenReturn(ThemeState(
      color: Colors.green,
      deviceBrightness: Brightness.light,
      useMaterial3: true,
      backgroundColor: Colors.white,
      overrideBackgroundColor: false,
      useOldTheme: false,
      fontFamily: 'Roboto',
      locale: const Locale('en'),
      themeBrightnessMode: ThemeBrightnessModeEnum.system,
      themePresetId: 'rawh',
      themePreset: AppThemePreset.findById('rawh'),
    ));
    when(() => mockThemeCubit.stream).thenAnswer((_) => const Stream.empty());
  });

  testWidgets(
      'Tapping another preset does not throw TextStyle.lerp inherit assert',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        locale: const Locale('en'),
        home: BlocProvider<ThemeCubit>.value(
          value: mockThemeCubit,
          child: const ThemeSelectionDialog(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Swap preview theme Rawh -> AlHeek; the dialog buttons animate their
    // text style over 200ms. Pre-fix this threw:
    // "Failed to interpolate TextStyles with different inherit values."
    await tester.tap(find.text('AlHeek'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.byType(ThemeSelectionDialog), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('Confirm pops instantly and applies preset exactly once',
      (tester) async {
    final preset = AppThemePreset.findById('alheek')!;
    registerFallbackValue(preset);
    when(() => mockThemeCubit.changePreset(any()))
        .thenAnswer((_) async {});
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        locale: const Locale('en'),
        home: BlocProvider<ThemeCubit>.value(
          value: mockThemeCubit,
          child: Builder(
            builder: (context) {
              Future.microtask(() => showDialog(
                    context: context,
                    builder: (_) => BlocProvider<ThemeCubit>.value(
                      value: mockThemeCubit,
                      child: const ThemeSelectionDialog(),
                    ),
                  ));
              return const Scaffold(body: Text('under'));
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ThemeSelectionDialog), findsOneWidget);

    await tester.tap(find.text('AlHeek'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Double-tap confirm before frames flush: second tap must be ignored,
    // otherwise the extra pop closes the route underneath (frozen app).
    await tester.tap(find.text('Confirm Selection'));
    await tester.tap(find.text('Confirm Selection'));
    await tester.pumpAndSettle();

    expect(find.byType(ThemeSelectionDialog), findsNothing);
    expect(find.text('under'), findsOneWidget);
    verify(() => mockThemeCubit.changePreset(any())).called(1);
  });
}
