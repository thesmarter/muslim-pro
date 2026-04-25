import 'package:bloc/bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:muslim/generated/lang/app_localizations.dart';
import 'package:muslim/src/core/di/dependency_injection.dart' as service_locator;
import 'package:muslim/src/core/di/dependency_injection.dart';
import 'package:muslim/src/core/extensions/extension_platform.dart';
import 'package:muslim/src/core/extensions/localization_extesion.dart';
import 'package:muslim/src/core/functions/print.dart';
import 'package:muslim/src/core/utils/app_bloc_observer.dart';
import 'package:muslim/src/core/values/constant.dart';
import 'package:muslim/src/features/alarms_manager/data/models/local_notification_manager.dart';
import 'package:muslim/src/features/themes/data/repository/theme_repo.dart';
import 'package:muslim/src/features/ui/data/repository/local_repo.dart';
import 'package:quran_library/quran_library.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
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

Future<void> initServices() async {
  WidgetsFlutterBinding.ensureInitialized();

  await QuranLibrary.init();

  Bloc.observer = AppBlocObserver();

  service_locator.initSL();
  
  await loadLocalizations();
  
  try {
    await GetStorage.init(kAppStorageKey);
    await sl<LocalNotificationManager>().init();
  } catch (e) {
    hisnPrint(e);
  }

  // تشغيل إعدادات Firebase في الخلفية بدون تعطيل تشغيل التطبيق
  _setupFirebase();

  await phoneDeviceBars();

  if (PlatformExtension.isDesktopOrWeb) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await initWindowsManager();
}

Future<void> _setupFirebase() async {
  if (!PlatformExtension.isPhone) return;

  try {
    await Firebase.initializeApp();
    final messaging = FirebaseMessaging.instance;
    
    // طلب الإذن والاشتراك في المواضيع بدون انتظار (non-blocking)
    messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

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

Future phoneDeviceBars() async {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

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

Future loadLocalizations() async {
  Locale? localeToSet = sl<ThemeRepo>().appLocale;
  final languageCode = PlatformExtension.languageCode;
  localeToSet ??= Locale.fromSubtags(languageCode: languageCode ?? "en");
  Intl.defaultLocale = localeToSet.languageCode;
  final s = await S.delegate.load(localeToSet);
  SX.init(s);
}
