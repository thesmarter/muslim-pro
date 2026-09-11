// ignore_for_file: unreachable_from_main
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:muslim/app.dart';
import 'package:muslim/generated/lang/app_localizations.dart';
import 'package:muslim/src/core/di/dependency_injection.dart' as service_locator;
import 'package:muslim/src/core/di/dependency_injection.dart';
import 'package:muslim/src/core/extensions/extension_platform.dart';
import 'package:muslim/src/core/extensions/localization_extension.dart';
import 'package:muslim/src/core/functions/print.dart';
import 'package:muslim/src/core/utils/app_bloc_observer.dart';
import 'package:muslim/src/core/values/constant.dart';
import 'package:muslim/src/features/alarms_manager/data/models/local_notification_manager.dart';
import 'package:muslim/src/features/prayer_times/data/repository/adhan_audio_service.dart';
import 'package:muslim/src/features/prayer_times/data/repository/prayer_times_repo.dart';
import 'package:muslim/src/features/themes/data/repository/theme_repo.dart';
import 'package:muslim/src/features/ui/data/repository/local_repo.dart';
import 'package:quran_library/quran_library.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:window_manager/window_manager.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  hisnPrint("Handling a background message: ${message.messageId}");
  if (message.notification != null) {
    hisnPrint("Message Notification Title: ${message.notification!.title}");
    hisnPrint("Message Notification Body: ${message.notification!.body}");
  }
}

/// Headless entrypoint launched daily by MaintenanceAlarmReceiver (Android).
/// Prayer times drift day by day through the year, so this recomputes and
/// re-registers every alarm/notification from scratch to keep them accurate
/// even when the user does not open the app.
@pragma('vm:entry-point')
Future<void> prayerMaintenanceMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool storageOk = false;
  bool tzOk = false;
  bool scheduledOk = false;
  try {
    service_locator.initSL();

    await loadLocalizations();

    try {
      await GetStorage.init(kAppStorageKey);
      storageOk = true;
    } catch (e) {
      hisnPrint("Prayer maintenance storage init failed: $e");
    }

    try {
      await sl<LocalNotificationManager>().init();
      tzOk = true;
    } catch (e) {
      hisnPrint("Prayer maintenance notification init failed: $e, trying tz UTC fallback.");
      try {
        tz.initializeTimeZones();
        tz.setLocalLocation(tz.getLocation('UTC'));
        tzOk = true;
        hisnPrint("Prayer maintenance tz fallback to UTC initialized.");
      } catch (e2) {
        hisnPrint("Prayer maintenance tz UTC fallback failed: $e2");
      }
    }

    try {
      final repo = sl<PrayerTimesRepo>();
      final settings = repo.getSettings();
      if (settings.latitude == 0 && settings.longitude == 0) {
        hisnPrint("Prayer maintenance skipped: lat/lng not set (0,0), no empty schedule.");
      } else {
        await repo.schedulePrayerNotifications(settings);
        scheduledOk = true;
        hisnPrint("Daily prayer times reschedule completed in background.");
      }
    } catch (e) {
      hisnPrint("Prayer maintenance schedule failed: $e");
    }
  } catch (e) {
    hisnPrint("Prayer maintenance error: $e");
  }
  try {
    if (scheduledOk) {
      await const MethodChannel('prayer_maintenance').invokeMethod('done');
    } else {
      hisnPrint(
        "Prayer maintenance reporting failed "
        "(storageOk=$storageOk, tzOk=$tzOk, scheduledOk=$scheduledOk).",
      );
      await const MethodChannel('prayer_maintenance').invokeMethod('failed');
    }
  } catch (_) {}
}

// ignore: unreachable_member
Future<void> initServices() async {
  WidgetsFlutterBinding.ensureInitialized();

  Bloc.observer = AppBlocObserver();

  // GetX يحتاج مفتاح التنقل قبل أي استخدام لـ Get.context داخل quran_library.
  Get.addKey(App.navigatorKey);

  // تسجيل الاعتماديات — ننتظره لضمان sl<PackageInfo>() جاهز في app.dart.
  // التكلفة ~50ms فقط؛ الثقيل الحقيقي (قرآن/إشعارات) أصبح في الخلفية.
  await service_locator.initSL();

  // الترتيب الصحيح: التخزين أولاً، ثم الترجمات التي تقرأ منه.
  try {
    await GetStorage.init(kAppStorageKey);
  } catch (e) {
    hisnPrint(e);
  }

  await loadLocalizations();

  // كل ما هو ثقيل يعمل في الخلفية بدون حجب أول فريم.
  _initHeavyInBackground();

  unawaited(phoneDeviceBars());

  if (PlatformExtension.isDesktopOrWeb) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await initWindowsManager();
}

/// تهيئة ثقيلة غير حاجبة: قرآن + إشعارات + أذان + Firebase + جدولة الصلوات.
Future<void> _initHeavyInBackground() async {
  try {
    await QuranLibrary.init();
  } catch (e) {
    hisnPrint("Error initializing QuranLibrary: $e");
  }

  try {
    await sl<LocalNotificationManager>().init();
    await sl<AdhanAudioService>().init();
  } catch (e) {
    hisnPrint(e);
  }

  // Auto-sync prayer times and reschedule notifications on app start
  // Defer to next frame to avoid blocking the UI during startup
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      final prayerRepo = sl<PrayerTimesRepo>();
      final settings = prayerRepo.getSettings();
      await prayerRepo.schedulePrayerNotifications(settings);
      hisnPrint("Prayer times synced and rescheduled on app start.");
    } catch (e) {
      hisnPrint("Error scheduling prayer notifications: $e");
    }
  });

  // تشغيل إعدادات Firebase في الخلفية بدون تعطيل تشغيل التطبيق
  _setupFirebase();
}

Future<void> _setupFirebase() async {
  if (!PlatformExtension.isPhone) return;

  try {
    await Firebase.initializeApp();
    final messaging = FirebaseMessaging.instance;
    
    // طلب الإذن والاشتراك في المواضيع بدون انتظار (non-blocking)
    messaging.requestPermission();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      hisnPrint("Got a message whilst in the foreground!");
      hisnPrint("Message data: ${message.data}");

      if (message.notification != null) {
        hisnPrint("Message also contained a notification: ${message.notification!.title}");
        
        sl<LocalNotificationManager>().showCustomNotification(
          title: message.notification!.title ?? '',
          body: message.notification!.body ?? '',
          payload: message.data['index']?.toString() ?? '',
        );
      }
    });

    // الاشتراك في المواضيع يتم في الخلفية ولا يعطل التطبيق عند فشل الاتصال
    messaging.subscribeToTopic('all');
    messaging.subscribeToTopic('info');
    messaging.subscribeToTopic('dev');
  } catch (e) {
    hisnPrint('Firebase init error: $e');
  }
}

// ignore: unreachable_member
Future phoneDeviceBars() async {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

// ignore: unreachable_member
Future initWindowsManager() async {
  if (!PlatformExtension.isDesktop) return;

  await windowManager.ensureInitialized();

  final WindowOptions windowOptions = WindowOptions(
    size: sl<UIRepo>().desktopWindowSize,
    center: true,
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setTitleBarStyle(
      TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    await windowManager.show();
    await windowManager.focus();
  });
}

// ignore: unreachable_member
Future loadLocalizations() async {
  Locale? localeToSet = sl<ThemeRepo>().appLocale;
  final languageCode = PlatformExtension.languageCode;
  localeToSet ??= Locale.fromSubtags(languageCode: languageCode ?? "en");
  Intl.defaultLocale = localeToSet.languageCode;
  final s = await S.delegate.load(localeToSet);
  SX.init(s);
}
