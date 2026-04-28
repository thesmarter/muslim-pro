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
import 'package:muslim/src/features/quran/presentation/screens/quran_read_screen.dart';
import 'package:muslim/src/features/settings/data/repository/app_settings_repo.dart';
import 'package:muslim/src/features/zikr_viewer/presentation/screens/zikr_viewer_screen.dart';
import 'package:path/path.dart' as path;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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
      );

      // Create notification channels for Android
      if (Platform.isAndroid) {
        final androidPlugin = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidPlugin != null) {
          // Create Adhan channel
          const adhanChannel = AndroidNotificationChannel(
            'com.detatech.Azkar.adhan', // Aligned with AdhanAudioService
            'الأذان (Adhan)',
            description: 'إشعارات الأذان والصلاة',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            enableLights: true,
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
            importance: Importance.defaultImportance,
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

  @pragma("vm:entry-point")
  static Future<void> onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse,
  ) async {
    final String? payload = notificationResponse.payload;
    final String? actionId = notificationResponse.actionId;
    hisnPrint("actionStream: $payload, actionId: $actionId");

    if (actionId == 'stop_adhan') {
      await sl<AdhanAudioService>().stopAdhan();
      // Cancel the notification as well
      if (notificationResponse.id != null) {
        await sl<LocalNotificationManager>().cancelNotificationById(id: notificationResponse.id!);
      }
      return;
    }

    if (payload != null && payload.isNotEmpty) {
      if (payload.startsWith('adhan_') || payload.startsWith('test_adhan_')) {
        final parts = payload.split('_');
        String? muadhinId;
        
        if (payload.startsWith('adhan_')) {
          // Payload format: adhan_muadhinId_prayerKey
          // If muadhinId contains underscores, it's between first and last part
          if (parts.length >= 3) {
            muadhinId = parts.sublist(1, parts.length - 1).join('_');
          }
        } else if (payload.startsWith('test_adhan_')) {
          // Payload format: test_adhan_muadhinId
          if (parts.length >= 3) {
            muadhinId = parts.sublist(2).join('_');
          }
        }

        if (muadhinId != null) {
          hisnPrint("Playing adhan for muadhin: $muadhinId");
          await sl<AdhanAudioService>().playAdhan(muadhinId);
          
          // Schedule cancellation after 10 minutes if not stopped
          Future.delayed(const Duration(minutes: 10), () async {
            await sl<AdhanAudioService>().stopAdhan();
            if (notificationResponse.id != null) {
              await sl<LocalNotificationManager>().cancelNotificationById(id: notificationResponse.id!);
            }
          });
        }
      } else {
        onNotificationClick(payload);
      }
    } else {
      hisnPrint("actionStream: Else");
    }

    // Logging all notification operations
    hisnPrint("Notification received/handled: ${payload ?? 'no-payload'}");
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> cancelNotificationById({required int id}) async {
    await flutterLocalNotificationsPlugin.cancel(id: id);
  }

  NotificationDetails _buildNotificationDetails(
    NotifyChannel channel,
    String? title,
    String? body, {
    String? soundName,
    bool playAdhan = false,
  }) {
    final BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
      body ?? '',
      htmlFormatBigText: true,
      contentTitle: title,
      htmlFormatContentTitle: true,
    );

    final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      channel.key,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: bigTextStyleInformation,
      icon: '@mipmap/ic_launcher',
      sound: soundName != null ? RawResourceAndroidNotificationSound(soundName) : null,
      fullScreenIntent: playAdhan,
      category: playAdhan ? AndroidNotificationCategory.alarm : null,
      ongoing: playAdhan,
      autoCancel: !playAdhan,
      actions: playAdhan
          ? [
              AndroidNotificationAction(
                'stop_adhan',
                SX.current.stopAdhan,
                showsUserInterface: true,
              ),
            ]
          : null,
    );

    final DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: soundName != null ? '$soundName.caf' : null,
      interruptionLevel: playAdhan ? InterruptionLevel.critical : InterruptionLevel.active,
    );

    return NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
  }

  /// Show Adhan Notification
  Future<void> scheduleAdhanNotification({
    required int id,
    required String title,
    String? body,
    required DateTime scheduledDate,
    required String payload,
  }) async {
    // Ensure permissions are granted before scheduling
    await requestPermissionWithDialog();

    // Extract muadhinId for custom notification sound
    String? soundName;
    final parts = payload.split('_');
    hisnPrint("Scheduling adhan notification - Payload: $payload, parts: $parts");
    
    if (payload.startsWith('adhan_') && parts.length >= 3) {
      soundName = parts.sublist(1, parts.length - 1).join('_');
    }
    
    hisnPrint("Extracted soundName for scheduling: $soundName");

    await _safeZonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: _buildNotificationDetails(
        NotificationsChannels.adhan,
        title,
        body,
        soundName: soundName,
        playAdhan: true,
      ),
      payload: payload,
    );
  }

  Future<void> showAdhanNotification({
    required int id,
    required String title,
    String? body,
    required String payload,
  }) async {
    // Extract muadhinId for custom notification sound
    String? soundName;
    final parts = payload.split('_');
    hisnPrint("Extracting soundName from payload: $payload, parts: $parts");
    
    if (payload.startsWith('test_adhan_') && parts.length >= 3) {
      soundName = parts.sublist(2).join('_');
    } else if (payload.startsWith('adhan_') && parts.length >= 3) {
      soundName = parts.sublist(1, parts.length - 1).join('_');
    }
    
    hisnPrint("Extracted soundName: $soundName");

    await flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _buildNotificationDetails(
        NotificationsChannels.adhan,
        title,
        body,
        soundName: soundName,
        playAdhan: true,
      ),
      payload: payload,
    );

    // If it's a test or immediate notification, trigger the player manually for foreground
    if (payload.startsWith('test_adhan_') || payload.startsWith('adhan_')) {
      if (soundName != null) {
        hisnPrint("Manually triggering adhan sound for: $soundName");
        try {
          await sl<AdhanAudioService>().playAdhan(soundName);
        } catch (e) {
          hisnPrint("Error in manual adhan trigger: $e");
        }
      } else {
        hisnPrint("Warning: soundName is null, cannot trigger manual adhan");
      }
    }

    // Auto-stop adhan and clear notification after 10 minutes
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
      notificationDetails: _buildNotificationDetails(
        NotificationsChannels.inApp,
        title,
        body,
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
      notificationDetails: _buildNotificationDetails(
        NotificationsChannels.scheduled,
        SX.current.haveNotOpenedAppLongTime,
        'فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ',
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
      notificationDetails: _buildNotificationDetails(
        NotificationsChannels.scheduled,
        title,
        body,
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
      notificationDetails: _buildNotificationDetails(
        NotificationsChannels.scheduled,
        title,
        body,
      ),
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  ///
  static void onNotificationClick(String payload) {
    final context = App.navigatorKey.currentState?.context;
    if (context == null) return;

    /// go to quran page if clicked
    if (payload == "الكهف") {
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
    key: 'com.detatech.Azkar.adhan',
    name: 'الأذان (Adhan)',
    description: 'إشعارات الأذان والصلاة',
  );
}
