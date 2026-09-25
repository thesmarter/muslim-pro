import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:muslim/app.dart';
import 'package:muslim/src/features/alarms_manager/data/models/local_notification_manager.dart';
import 'package:muslim/src/features/alarms_manager/presentation/controller/bloc/alarms_bloc.dart';
import 'package:muslim/src/features/azkar_filters/presentation/controller/cubit/azkar_filters_cubit.dart';
import 'package:muslim/src/features/backup_restore/presentation/controller/cubit/backup_restore_cubit.dart';
import 'package:muslim/src/features/bookmark/presentation/controller/bloc/bookmark_bloc.dart';
import 'package:muslim/src/features/effects_manager/data/models/zikr_effects.dart';
import 'package:muslim/src/features/home/presentation/controller/bloc/home_bloc.dart';
import 'package:muslim/src/features/home_search/presentation/controller/cubit/search_cubit.dart';
import 'package:muslim/src/features/prayer_times/presentation/controller/prayer_times_bloc.dart';
import 'package:muslim/src/features/prayer_times/presentation/controller/prayer_times_state.dart';
import 'package:muslim/src/features/settings/data/repository/app_settings_repo.dart';
import 'package:muslim/src/features/settings/presentation/controller/cubit/settings_cubit.dart';
import 'package:muslim/src/features/themes/data/models/theme_brightness_mode_enum.dart';
import 'package:muslim/src/features/themes/presentation/controller/cubit/theme_cubit.dart';
import 'package:muslim/src/features/update/presentation/controller/update_cubit.dart';
import 'package:muslim/src/features/zikr_audio_player/presentation/controller/cubit/zikr_audio_player_cubit.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MockSettingsCubit extends Mock implements SettingsCubit {}
class MockThemeCubit extends Mock implements ThemeCubit {}
class MockAzkarFiltersCubit extends Mock implements AzkarFiltersCubit {}
class MockAlarmsBloc extends Mock implements AlarmsBloc {}
class MockBookmarkBloc extends Mock implements BookmarkBloc {}
class MockHomeBloc extends Mock implements HomeBloc {}
class MockSearchCubit extends Mock implements SearchCubit {}
class MockZikrAudioPlayerCubit extends Mock implements ZikrAudioPlayerCubit {}
class MockBackupRestoreCubit extends Mock implements BackupRestoreCubit {}
class MockUpdateCubit extends Mock implements UpdateCubit {}
class MockPrayerTimesBloc extends Mock implements PrayerTimesBloc {}
class MockGetStorage extends Mock implements GetStorage {}
class MockAppSettingsRepo extends Mock implements AppSettingsRepo {}
class MockPackageInfo extends Mock implements PackageInfo {}
class MockLocalNotificationManager extends Mock implements LocalNotificationManager {}

void main() {
  setUpAll(() {
    registerFallbackValue(const HomeStartEvent());
    registerFallbackValue(AlarmsStartEvent());
    registerFallbackValue('language_chosen');
  });

  setUp(() async {
    await GetIt.instance.reset();
    final sl = GetIt.instance;
    sl.allowReassignment = true;

    // Headless: window_manager has no native side in `flutter test`.
    // No-op the channel so DesktopWindowWrapper initState doesn't throw
    // MissingPluginException on desktop hosts (Platform.isWindows is true).
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('window_manager'),
      (MethodCall call) async => null,
    );

    final mockSettings = MockSettingsCubit();
    final mockTheme = MockThemeCubit();
    final mockFilters = MockAzkarFiltersCubit();
    final mockAlarms = MockAlarmsBloc();
    final mockBookmark = MockBookmarkBloc();
    final mockHome = MockHomeBloc();
    final mockSearch = MockSearchCubit();
    final mockAudio = MockZikrAudioPlayerCubit();
    final mockBackup = MockBackupRestoreCubit();
    final mockUpdate = MockUpdateCubit();
    final mockPrayer = MockPrayerTimesBloc();
    final mockStorage = MockGetStorage();
    final mockSettingsRepo = MockAppSettingsRepo();
    final mockPackageInfo = MockPackageInfo();
    final mockNotifications = MockLocalNotificationManager();

    when(() => mockTheme.state).thenReturn(const ThemeState(
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
    when(() => mockTheme.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockTheme.shouldShowThemeSelection).thenReturn(false);

    when(() => mockUpdate.state).thenReturn(UpdateInitial());
    when(() => mockUpdate.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockUpdate.checkForUpdate()).thenAnswer((_) async {});
    when(() => mockUpdate.close()).thenAnswer((_) async {});
    when(() => mockTheme.close()).thenAnswer((_) async {});
    when(() => mockSettings.close()).thenAnswer((_) async {});
    when(() => mockFilters.close()).thenAnswer((_) async {});
    when(() => mockAlarms.close()).thenAnswer((_) async {});
    when(() => mockBookmark.close()).thenAnswer((_) async {});
    when(() => mockHome.close()).thenAnswer((_) async {});
    when(() => mockSearch.close()).thenAnswer((_) async {});
    when(() => mockAudio.close()).thenAnswer((_) async {});
    when(() => mockBackup.close()).thenAnswer((_) async {});
    when(() => mockPrayer.close()).thenAnswer((_) async {});

    when(() => mockSettings.state).thenReturn(const SettingsState(
      zikrEffects: ZikrEffects(
        soundEffectVolume: 1.0,
        soundEveryPraise: false,
        soundEveryZikr: false,
        soundEveryTitle: false,
        vibrateEveryPraise: false,
        vibrateEveryZikr: false,
        vibrateEveryTitle: false,
        vibrateEveryPraiseDuration: 0,
        vibrateEveryZikrDuration: 0,
        vibrateEveryTitleDuration: 0,
      ),
      isCardReadMode: false,
      enableWakeLock: false,
      useHindiDigits: false,
      fontSize: 16,
      showDiacritics: true,
      praiseWithVolumeKeys: false,
      allowZikrSessionRestoration: false,
      ignoreNotificationPermission: true,
      showAudioBar: false,
    ));
    when(() => mockSettings.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockFilters.state).thenReturn(const AzkarFiltersState(
      filters: [],
      enableFilters: false,
      enableHokmFilters: false,
    ));
    when(() => mockFilters.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockAlarms.state).thenReturn(AlarmsLoadingState());
    when(() => mockAlarms.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockBookmark.state).thenReturn(BookmarkLoadingState());
    when(() => mockBookmark.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockHome.state).thenReturn(HomeLoadingState());
    when(() => mockHome.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockSearch.state).thenReturn(const SearchLoadingState());
    when(() => mockSearch.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockSearch.start()).thenAnswer((_) async {});

    when(() => mockAudio.state).thenReturn(const ZikrAudioPlayerState());
    when(() => mockAudio.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockBackup.state).thenReturn(BackupRestoreInitial());
    when(() => mockBackup.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockPrayer.state).thenReturn(const PrayerTimesState());
    when(() => mockPrayer.stream).thenAnswer((_) => const Stream.empty());

    // Force the light onboarding path: language not chosen yet, so App shows
    // LanguageSelectionScreen instead of the heavy HomeScreen.
    when(() => mockStorage.read(any())).thenReturn(null);
    when(() => mockSettingsRepo.isLanguageChosen).thenReturn(false);
    when(() => mockSettingsRepo.currentVersion).thenReturn('');
    when(() => mockPackageInfo.version).thenReturn('3.3.3');
    when(() => mockNotifications.isPermissionGranted()).thenAnswer((_) async => false);
    when(() => mockNotifications.appOpenNotification()).thenAnswer((_) async {});
    when(() => mockNotifications.handleLaunchNotification()).thenReturn(null);

    sl.registerLazySingleton<SettingsCubit>(() => mockSettings);
    sl.registerLazySingleton<ThemeCubit>(() => mockTheme);
    sl.registerLazySingleton<AzkarFiltersCubit>(() => mockFilters);
    sl.registerLazySingleton<AlarmsBloc>(() => mockAlarms);
    sl.registerLazySingleton<BookmarkBloc>(() => mockBookmark);
    sl.registerLazySingleton<HomeBloc>(() => mockHome);
    sl.registerLazySingleton<SearchCubit>(() => mockSearch);
    sl.registerLazySingleton<ZikrAudioPlayerCubit>(() => mockAudio);
    sl.registerLazySingleton<BackupRestoreCubit>(() => mockBackup);
    sl.registerLazySingleton<UpdateCubit>(() => mockUpdate);
    sl.registerLazySingleton<PrayerTimesBloc>(() => mockPrayer);
    sl.registerLazySingleton<GetStorage>(() => mockStorage);
    sl.registerLazySingleton<AppSettingsRepo>(() => mockSettingsRepo);
    sl.registerFactory<PackageInfo>(() => mockPackageInfo);
    sl.registerLazySingleton<LocalNotificationManager>(() => mockNotifications);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets('App smoke test builds MaterialApp with mocked blocs',
      (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(MaterialApp), findsOneWidget);
    // LanguageSelectionScreen is the light home when `isLanguageChosen` false.
    expect(find.text('Choose Your Language'), findsOneWidget);

    // Flush AppState's Future.delayed(6s) update check so no Timer is pending
    // at test teardown (flutter_test fails on pending timers).
    await tester.pump(const Duration(seconds: 7));
  });
}
