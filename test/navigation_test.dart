import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:muslim/src/features/alarms_manager/presentation/controller/bloc/alarms_bloc.dart';
import 'package:muslim/src/features/home/data/data_source/app_dashboard_tabs.dart';
import 'package:muslim/src/features/home/presentation/controller/bloc/home_bloc.dart';
import 'package:muslim/src/features/home/presentation/screens/home_screen.dart';
import 'package:muslim/src/features/themes/data/models/theme_brightness_mode_enum.dart';
import 'package:muslim/src/features/themes/presentation/controller/cubit/theme_cubit.dart';

class MockHomeBloc extends Mock implements HomeBloc {}
class MockAlarmsBloc extends Mock implements AlarmsBloc {}
class MockThemeCubit extends Mock implements ThemeCubit {}

void main() {
  late MockHomeBloc mockHomeBloc;
  late MockAlarmsBloc mockAlarmsBloc;
  late MockThemeCubit mockThemeCubit;

  setUpAll(() {
    registerFallbackValue(HomeStartEvent());
    registerFallbackValue(AlarmsStartEvent());
  });

  setUp(() {
    mockHomeBloc = MockHomeBloc();
    mockAlarmsBloc = MockAlarmsBloc();
    mockThemeCubit = MockThemeCubit();

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
      locale: Locale('ar'),
      themeBrightnessMode: ThemeBrightnessModeEnum.system,
    ));
    when(() => mockThemeCubit.stream).thenAnswer((_) => const Stream.empty());

    final sl = GetIt.instance;
    sl.allowReassignment = true;
    sl.registerLazySingleton<HomeBloc>(() => mockHomeBloc);
    sl.registerLazySingleton<AlarmsBloc>(() => mockAlarmsBloc);
    sl.registerLazySingleton<ThemeCubit>(() => mockThemeCubit);
  });

  testWidgets('Pressing back on non-zero tab should navigate to tab 0', (tester) async {
    // Provide necessary localizations
    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<HomeBloc>.value(value: mockHomeBloc),
            BlocProvider<AlarmsBloc>.value(value: mockAlarmsBloc),
            BlocProvider<ThemeCubit>.value(value: mockThemeCubit),
          ],
          child: const HomeScreen(),
        ),
      ),
    );

    await tester.pump(); // Start building
    await tester.pump(); // Finish building HomeLoadedState

    // Find TabBarView to get the controller
    final tabBarView = tester.widget<TabBarView>(find.byType(TabBarView));
    final tabController = tabBarView.controller!;

    // Change tab to 1
    tabController.animateTo(1);
    await tester.pumpAndSettle();
    expect(tabController.index, 1);

    // Simulate system back button
    // final WidgetsAppState widgetsAppState = tester.state(find.byType(WidgetsApp));
    // await widgetsAppState.didPopRoute();
    await tester.pumpAndSettle();

    // Should be at tab 0
    expect(tabController.index, 0);
  });
}
