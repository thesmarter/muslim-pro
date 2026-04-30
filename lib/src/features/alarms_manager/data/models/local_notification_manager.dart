import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:muslim/app.dart';
import 'package:muslim/src/core/di/dependency_injection.dart';
import 'package:muslim/src/core/extensions/extension.dart';
import 'package:muslim/src/core/extensions/localization_extension.dart';
import 'package:muslim/src/core/functions/print.dart';
import 'package:muslim/src/features/alarms_manager/data/repository/alarm_database_helper.dart';
import 'package:muslim/src/features/alarms_manager/data/repository/alarms_repo.dart';
import 'package:muslim/src/features/alarms_manager/presentation/components/permission_dialog.dart';
import 'package:muslim/src/features/prayer_times/data/repository/adhan_audio_service.dart';
import 'package:muslim/src/features/prayer_times/presentation/screens/prayer_times_screen.dart';
import 'package:muslim/src/features/quran/presentation/screens/quran_read_screen.dart';
import 'package:muslim/src/features/settings/data/repository/app_settings_repo.dart';
import 'package:muslim/src/features/zikr_viewer/presentation/screens/zikr_viewer_screen.dart';
import 'package:path/path.dart' as path;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

@pragma("vm:entry-point")
Future<void> onDidReceiveNotificationResponse(
  NotificationResponse notificationResponse,
) async {
  debugPrint("onDidReceiveNotificationResponse - actionId: ${notificationResponse.actionId}, payload: ${notificationResponse.payload}");
  
  // Ensure Service Locator is initialized if this is a background isolate
  try {
    if (!sl.isRegistered<AdhanAudioService>()) {
      debugPrint("Initializing Service Locator in background...");
      await initSL();
    }
  } catch (e) {
    debugPrint("Error initializing SL in notification response: $e");
  }

  final String? payload = notificationResponse.payload;
  final String? actionId = notificationResponse.actionId;
  debugPrint("onDidReceiveNotificationResponse - payload: $payload, actionId: $actionId");

  // Handle "Stop Adhan" action button
  if (actionId == 'stop_adhan') {
    try {
      final adhanService = sl<AdhanAudioService>();
      await adhanService.stopAdhan();
    } catch (e) {
      debugPrint("Error stopping adhan audio: $e");
    }
    
    if (notificationResponse.id != null) {
      try {
        final notificationManager = sl<LocalNotificationManager>();
        await notificationManager.cancelNotificationById(id: notificationResponse.id!);
      } catch (e) {
        debugPrint("Error canceling notification: $e");
      }
    }
    return;
  }

  // Handle notification tap (open relevant screen)
  if (payload != null && payload.isNotEmpty) {
    if (payload.startsWith('adhan_') || payload.startsWith('test_adhan_')) {
      // Stop any playing adhan when user taps the notification
      try {
        await sl<AdhanAudioService>().stopAdhan();
      } catch (e) {
        debugPrint("Error stopping adhan on tap: $e");
      }
      LocalNotificationManager.onNotificationClick(payload);
    } else {
      LocalNotificationManager.onNotificationClick(payload);
    }
  }
}

class LocalNotificationManager {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationResponse? launchNotificationResponse;
  bool _isDialogShowing = false;

  Future<void> init() async {
    try {
      await _configureLocalTimeZone();

      const AndroidInitializationSettings androidInitializationSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosInitializationSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      final WindowsInitializationSettings windowsInitializationSettings =
          _windowsInitializationSettings();

      final InitializationSettings settings = InitializationSettings(
        android: androidInitializationSettings,
        iOS: iosInitializationSettings,
        windows: windowsInitializationSettings,
      );

      await flutterLocalNotificationsPlugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: onDidReceiveNotificationResponse,
      );

      // Create notification channels for Android
      if (Platform.isAndroid) {
        final androidPlugin = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidPlugin != null) {
          // Delete old channels to ensure fresh settings
          await androidPlugin.deleteNotificationChannel(channelId: 'com.detatech.Azkar.adhan.v2');
          
          // Create Adhan channel - sound will be set per-notification
          const adhanChannel = AndroidNotificationChannel(
            'com.detatech.Azkar.adhan.v3',
            'الأذان (Adhan)',
            description: 'إشعارات الأذان ومواقيت الصلاة',
            importance: Importance.max,
            enableLights: true,
            playSound: true,
          );
          
          await androidPlugin.createNotificationChannel(adhanChannel);
          
          // Create other channels
          await androidPlugin.createNotificationChannel(AndroidNotificationChannel(
            NotificationsChannels.inApp.key,
            NotificationsChannels.inApp.name,
            description: NotificationsChannels.inApp.description,
            importance: Importance.high,
          ));
          
          await androidPlugin.createNotificationChannel(AndroidNotificationChannel(
            NotificationsChannels.scheduled.key,
            NotificationsChannels.scheduled.name,
            description: NotificationsChannels.scheduled.description,
          ));
          
          hisnPrint("Notification channels created successfully");
        }
      }

      final NotificationAppLaunchDetails? notificationAppLaunchDetails =
          await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
      if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
        launchNotificationResponse = notificationAppLaunchDetails!.notificationResponse;
      }
    } catch (e) {
      hisnPrint(e);
    }
  }

  WindowsInitializationSettings _windowsInitializationSettings() {
    String? iconPath;
    if (Platform.isWindows) {
      final String exePath = Platform.resolvedExecutable;
      final String appDir = path.dirname(exePath);
      iconPath = path.join(
        appDir,
        'data',
        'flutter_assets',
        'assets/images/app_icon.png',
      );
      if (!File(iconPath).existsSync()) {
        iconPath = null;
      }
    }

    return WindowsInitializationSettings(
      appName: SX.appName,
      appUserModelId: 'com.detatech.Azkar',
      //run `[guid]::NewGuid()` on windows
      guid: '82fd58ee-c707-40ba-b2f8-799d8cb40e12',
      iconPath: iconPath,
    );
  }

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
  }

  Future<bool> requestPermissionWithDialog({bool triggerOnStartup = false}) async {
    if (_isDialogShowing) return false;

    /// if the user ignored the notification permission, don't show the dialog
    final appSettingsRepo = sl<AppSettingsRepo>();
    if (appSettingsRepo.ignoreNotificationPermission) return false;

    if (triggerOnStartup) {
      /// if the user has no alarms, don't show the dialog
      final hasAlarms = await _hasAnyActiveAlarms();
      if (!hasAlarms) return false;
    }

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    bool notificationsAllowed = false;
    bool exactAlarmsAllowed = true;

    if (Platform.isAndroid) {
      notificationsAllowed = await androidPlugin?.areNotificationsEnabled() ?? false;
      exactAlarmsAllowed = await androidPlugin?.canScheduleExactNotifications() ?? true;
    } else if (Platform.isIOS) {
      notificationsAllowed = await isPermissionGranted();
      exactAlarmsAllowed = true;
    }

    if (notificationsAllowed && exactAlarmsAllowed) return true;

    final BuildContext? context = App.navigatorKey.currentContext;
    if (context == null || !context.mounted) return false;

    _isDialogShowing = true;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PermissionDialog(
          flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin,
        );
      },
    );
    _isDialogShowing = false;

    return result ?? false;
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> cancelNotificationById({required int id}) async {
    await flutterLocalNotificationsPlugin.cancel(id: id);
  }

  /// Build notification details for Adhan notifications.
  /// The adhan sound file name (without extension) from res/raw is used
  /// as the notification sound. This way, Android plays the adhan audio
  /// automatically when the notification fires — no user interaction needed.
  NotificationDetails _buildAdhanNotificationDetails({
    required String title,
    String? body,
    required String soundFileName,
  }) {
    final BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
      body ?? '',
      htmlFormatBigText: true,
      contentTitle: title,
      htmlFormatContentTitle: true,
    );

    // Use a unique channel ID for each muadhin to ensure the specific sound is tied to the channel
    final String channelId = 'com.detatech.Azkar.adhan.$soundFileName';
    final String channelName = 'الأذان ($soundFileName)';

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'إشعارات الأذان المخصصة',
      importance: Importance.max,
      priority: Priority.max,
      styleInformation: bigTextStyleInformation,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      color: const Color(0xFF1B5E20), // Islamic Green
      ledColor: const Color(0xFF1B5E20),
      ledOnMs: 1000,
      ledOffMs: 500,
      playSound: true,
      // Tie the sound to the notification as well
      sound: RawResourceAndroidNotificationSound(soundFileName),
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      actions: [
        AndroidNotificationAction(
          'stop_adhan',
          SX.current.stopAdhan,
        ),
      ],
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: '$soundFileName.mp3',
      interruptionLevel: InterruptionLevel.critical,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  /// Build notification details for regular (non-adhan) notifications
  NotificationDetails _buildRegularNotificationDetails(
    NotifyChannel channel, {
    String? title,
    String? body,
  }) {
    final BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
      body ?? '',
      htmlFormatBigText: true,
      contentTitle: title,
      htmlFormatContentTitle: true,
    );

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channel.key,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: bigTextStyleInformation,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      color: const Color(0xFF1B5E20),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  /// Schedule an Adhan notification for a specific prayer time.
  /// The adhan sound plays automatically when the notification fires.
  Future<void> scheduleAdhanNotification({
    required int id,
    required String title,
    String? body,
    required DateTime scheduledDate,
    required String payload,
    required String soundFileName,
  }) async {
    await requestPermissionWithDialog();

    hisnPrint("Scheduling adhan notification - id: $id, title: $title, "
        "sound: $soundFileName, date: $scheduledDate, payload: $payload");

    await _ensureAdhanChannelExists(soundFileName);

    await _safeZonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: _buildAdhanNotificationDetails(
        title: title,
        body: body,
        soundFileName: soundFileName,
      ),
      payload: payload,
    );
  }

  /// Show an immediate Adhan notification (for testing).
  /// Also triggers the AudioPlayer for full audio playback in foreground.
  Future<void> showAdhanNotification({
    required int id,
    required String title,
    String? body,
    required String payload,
    required String soundFileName,
    required String muadhinId,
  }) async {
    hisnPrint("Showing immediate adhan notification - sound: $soundFileName, muadhin: $muadhinId");

    await _ensureAdhanChannelExists(soundFileName);

    await flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _buildAdhanNotificationDetails(
        title: title,
        body: body,
        soundFileName: soundFileName,
      ),
      payload: payload,
    );

    // Auto-stop after 10 minutes
    Future.delayed(const Duration(minutes: 10), () async {
      await sl<AdhanAudioService>().stopAdhan();
      await cancelNotificationById(id: id);
    });
  }

  /// Show Notification
  Future<void> showCustomNotification({
    required String title,
    String? body,
    required String payload,
  }) async {
    await flutterLocalNotificationsPlugin.show(
      id: 999,
      title: title,
      body: body,
      notificationDetails: _buildRegularNotificationDetails(
        NotificationsChannels.inApp,
        title: title,
        body: body,
      ),
      payload: payload,
    );
  }

  /// Show Notification App Open
  Future<void> appOpenNotification() async {
    final scheduleNotificationDateTime = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(days: 3));

    await _safeZonedSchedule(
      id: 1000,
      title: SX.current.haveNotOpenedAppLongTime,
      body: 'فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ',
      scheduledDate: scheduleNotificationDateTime,
      notificationDetails: _buildRegularNotificationDetails(
        NotificationsChannels.scheduled,
        title: SX.current.haveNotOpenedAppLongTime,
        body: 'فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ',
      ),
      payload: "2",
    );
  }

  Future<void> _safeZonedSchedule({
    required int id,
    required String? title,
    required String? body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: payload,
      );
    } catch (e) {
      hisnPrint("Error scheduling exact alarm, falling back to inexact: $e");
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: payload,
      );
    }
  }

  tz.TZDateTime _nextInstanceOfTime(Time time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfWeekdayAndTime(int weekday, Time time) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(time);
    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Add weekly notification
  Future<void> addCustomWeeklyReminder({
    required int id,
    required String title,
    String? body,
    required String payload,
    required Time time,
    required int weekday,
    bool requestPermission = true,
  }) async {
    if (requestPermission) {
      await requestPermissionWithDialog();
    }
    await _safeZonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOfWeekdayAndTime(weekday, time),
      notificationDetails: _buildRegularNotificationDetails(
        NotificationsChannels.scheduled,
        title: title,
        body: body,
      ),
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: payload,
    );
  }

  /// Add Daily notification
  Future<void> addCustomDailyReminder({
    required int id,
    required String title,
    String? body,
    required Time time,
    required String payload,
    bool requestPermission = true,
  }) async {
    if (requestPermission) {
      await requestPermissionWithDialog();
    }
    await _safeZonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOfTime(time),
      notificationDetails: _buildRegularNotificationDetails(
        NotificationsChannels.scheduled,
        title: title,
        body: body,
      ),
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  static void onNotificationClick(String payload) {
    final context = App.navigatorKey.currentState?.context;
    if (context == null) return;

    /// go to adhan screen if clicked
    if (payload.startsWith('adhan_') || payload.startsWith('test_adhan_')) {
      context.push(const PrayerTimesScreen());
    }
    /// go to quran page if clicked
    else if (payload == "الكهف") {
      context.push(const QuranReadScreen(startPage: 293));
    }
    /// ignore constant alarms if clicked
    else if (payload == "555" || payload == "666") {
    }
    /// go to zikr page if clicked
    else {
      final int? pageIndex = int.tryParse(payload);
      if (pageIndex != null) {
        context.push(ZikrViewerScreen(index: pageIndex));
      }
    }
  }

  void handleLaunchNotification() {
    if (launchNotificationResponse != null) {
      final String? payload = launchNotificationResponse!.payload;
      if (payload != null && payload.isNotEmpty) {
        onNotificationClick(payload);
      }
      launchNotificationResponse = null;
    }
  }

  Future<bool> isPermissionGranted() async {
    if (Platform.isAndroid) {
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    } else if (Platform.isIOS) {
      final iosPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final permissions = await iosPlugin?.checkPermissions();
      return permissions?.isEnabled ?? false;
    }
    return false;
  }

  /// Ensure a specific notification channel exists for a given muadhin sound.
  /// This is necessary because Android notification channel sounds are immutable after creation.
  Future<void> _ensureAdhanChannelExists(String soundFileName) async {
    if (!Platform.isAndroid) return;

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final String channelId = 'com.detatech.Azkar.adhan.$soundFileName';
      final String channelName = 'الأذان ($soundFileName)';

      await androidPlugin.createNotificationChannel(AndroidNotificationChannel(
        channelId,
        channelName,
        description: 'إشعارات الأذان المخصصة لـ $soundFileName',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(soundFileName),
        enableLights: true,
        enableVibration: true,
      ));
    }
  }

  Future<bool> _hasAnyActiveAlarms() async {
    final alarmsRepo = sl<AlarmsRepo>();
    final alarmDatabaseHelper = sl<AlarmDatabaseHelper>();

    if (alarmsRepo.isCaveAlarmEnabled) return true;
    if (alarmsRepo.isFastAlarmEnabled) return true;

    final alarms = await alarmDatabaseHelper.getAlarms();
    if (alarms.any((alarm) => alarm.isActive)) return true;

    return false;
  }
}

class Time {
  final int hour;
  final int minute;
  Time(this.hour, [this.minute = 0]);
}

class NotifyChannel {
  final String key;
  final String name;
  final String description;
  NotifyChannel({
    required this.key,
    required this.name,
    required this.description,
  });
}

class NotificationsChannels {
  static NotifyChannel get inApp => NotifyChannel(
    key: 'in_app_notification',
    name: SX.current.channelInAppName,
    description: SX.current.channelInAppNameDesc,
  );
  static NotifyChannel get scheduled => NotifyChannel(
    key: 'scheduled_channel',
    name: SX.current.channelScheduledName,
    description: SX.current.channelScheduledNameDesc,
  );
  static NotifyChannel get adhan => NotifyChannel(
    key: 'com.detatech.Azkar.adhan.v3',
    name: 'الأذان (Adhan)',
    description: 'إشعارات الأذان ومواقيت الصلاة',
  );
}
