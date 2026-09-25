import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:muslim/generated/lang/app_localizations.dart';
import 'package:muslim/src/features/alarms_manager/presentation/controller/bloc/alarms_bloc.dart';
import 'package:muslim/src/features/home/data/data_source/app_dashboard_tabs.dart';
import 'package:muslim/src/features/home/presentation/controller/bloc/home_bloc.dart';
import 'package:muslim/src/features/home/presentation/screens/home_screen.dart';
import 'package:muslim/src/features/prayer_times/presentation/controller/prayer_times_bloc.dart';
import 'package:muslim/src/features/prayer_times/presentation/controller/prayer_times_state.dart';
import 'package:muslim/src/features/showcase_tour/data/repository/showcase_tour_repo.dart';
import 'package:muslim/src/features/themes/data/models/theme_brightness_mode_enum.dart';
import 'package:muslim/src/features/themes/presentation/controller/cubit/theme_cubit.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

class MockHomeBloc extends Mock implements HomeBloc {}
class MockAlarmsBloc extends Mock implements AlarmsBloc {}
class MockThemeCubit extends Mock implements ThemeCubit {}
class MockPrayerTimesBloc extends Mock implements PrayerTimesBloc {}
class MockShowcaseTourRepo extends Mock implements ShowcaseTourRepo {}

void main() {
  late MockHomeBloc mockHomeBloc;
  late MockAlarmsBloc mockAlarmsBloc;
  late MockThemeCubit mockThemeCubit;
  late MockPrayerTimesBloc mockPrayerTimesBloc;
  late MockShowcaseTourRepo mockShowcaseRepo;

  setUpAll(() {
    registerFallbackValue(const HomeStartEvent());
    registerFallbackValue(AlarmsStartEvent());
  });

  setUp(() async {
    await GetIt.instance.reset();
    mockHomeBloc = MockHomeBloc();
    mockAlarmsBloc = MockAlarmsBloc();
    mockThemeCubit = MockThemeCubit();
    mockPrayerTimesBloc = MockPrayerTimesBloc();
    mockShowcaseRepo = MockShowcaseTourRepo();

    final arrangement = List.generate(appDashboardTabs.length, (index) => index);

    when(() => mockHomeBloc.state).thenReturn(HomeLoadedState(
      titles: const [],
      bookmarkedContents: const [],
      isSearching: false,
      dashboardArrangement: arrangement,
      freqFilters: const [],
      bookmarkedTitlesIds: const [],
    ));
    when(() => mockHomeBloc.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockAlarmsBloc.state).thenReturn(AlarmsLoadingState());
    when(() => mockAlarmsBloc.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockThemeCubit.state).thenReturn(const ThemeState(
      color: Colors.green,
      deviceBrightness: Brightness.light,
      useMaterial3: true,
      backgroundColor: Colors.white,
      overrideBackgroundColor: false,
      useOldTheme: false,
      fontFamily: 'Roboto',
      locale: Locale('en'),
      themeBrightnessMode: ThemeBrightnessModeEnum.system,
    ));
    when(() => mockThemeCubit.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockPrayerTimesBloc.state)
        .thenReturn(const PrayerTimesState());
    when(() => mockPrayerTimesBloc.stream)
        .thenAnswer((_) => const Stream.empty());

    // Mark the showcase tour completed so no overlay tour starts during pump.
    when(() => mockShowcaseRepo.isTourCompleted).thenReturn(true);

    final sl = GetIt.instance;
    sl.allowReassignment = true;
    sl.registerLazySingleton<HomeBloc>(() => mockHomeBloc);
    sl.registerLazySingleton<AlarmsBloc>(() => mockAlarmsBloc);
    sl.registerLazySingleton<ThemeCubit>(() => mockThemeCubit);
    sl.registerLazySingleton<ShowcaseTourRepo>(() => mockShowcaseRepo);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets('Pressing back on non-zero tab should navigate to tab 0',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        locale: const Locale('en'),
        home: MultiBlocProvider(
          providers: [
            BlocProvider<HomeBloc>.value(value: mockHomeBloc),
            BlocProvider<AlarmsBloc>.value(value: mockAlarmsBloc),
            BlocProvider<ThemeCubit>.value(value: mockThemeCubit),
            BlocProvider<PrayerTimesBloc>.value(value: mockPrayerTimesBloc),
          ],
          child: const DashboardScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // DashboardScreen (the body of HomeScreen) now uses PersistentTabView
    // (not TabBarView). ZoomDrawer/SideMenu are intentionally bypassed here:
    // they need PackageInfo/GetStorage and trigger debug ListTile assertions
    // that can't run headless without touching lib/. DashboardScreen still
    // exercises the real tab back-navigation (PersistentTabView + history).
    final persistentTabView =
        tester.widget<PersistentTabView>(find.byType(PersistentTabView));
    final navController = persistentTabView.controller!;
    expect(navController.index, 0);

    // Change tab to 1.
    navController.jumpToTab(1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(navController.index, 1);

    // Simulate system back button via the real WidgetsApp back dispatch.
    // This exercises PopScope inside PersistentTabView (jumpToPreviousTab),
    // instead of being a commented-out false-positive.
    // (WidgetsAppState is private in current Flutter, so use dynamic.)
    final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
    await widgetsAppState.didPopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Should be back at tab 0.
    expect(navController.index, 0);
  });
}
