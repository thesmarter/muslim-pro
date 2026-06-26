import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:muslim/src/core/di/dependency_injection.dart';
import 'package:muslim/src/core/extensions/localization_extension.dart';
import 'package:muslim/src/core/functions/print.dart';
import 'package:muslim/src/features/alarms_manager/data/models/local_notification_manager.dart';

class CountdownNotificationService {
  static final CountdownNotificationService _instance = CountdownNotificationService._internal();
  factory CountdownNotificationService() => _instance;
  CountdownNotificationService._internal();

  final Map<int, Timer> _activeTimers = {};

  static const int _preAdhanCountdownBaseId = 4000;
  static const int _postAdhanCountdownBaseId = 5000;
  static const int _sunriseEndCountdownBaseId = 6000;

  Future<void> startPreAdhanCountdown({
    required int prayerIndex,
    required String prayerName,
    required DateTime adhanTime,
    required int minutesBefore,
  }) async {
    final id = _preAdhanCountdownBaseId + prayerIndex;
    await cancelAllCountdowns(); // Cancel all other countdowns first
    await _cancelTimer(id);

    final now = DateTime.now();
    final countdownStartTime = adhanTime.subtract(Duration(minutes: minutesBefore));

    if (now.isBefore(countdownStartTime)) {
      final delay = countdownStartTime.difference(now);
      _activeTimers[id] = Timer(delay, () {
        _startPeriodicCountdown(
          id: id,
          targetTime: adhanTime,
          titleBuilder: (remaining) => SX.current.countdownToAdhan(prayerName),
          bodyBuilder: (remaining) => _formatCountdownBody(remaining, prayerName),
          interval: const Duration(minutes: 1),
        );
      });
    } else if (now.isBefore(adhanTime)) {
      _startPeriodicCountdown(
        id: id,
        targetTime: adhanTime,
        titleBuilder: (remaining) => SX.current.countdownToAdhan(prayerName),
        bodyBuilder: (remaining) => _formatCountdownBody(remaining, prayerName),
        interval: const Duration(minutes: 1),
      );
    }
  }

  Future<void> startPostAdhanCountdown({
    required int prayerIndex,
    required String prayerName,
    required DateTime adhanTime,
    required int durationMinutes,
  }) async {
    final id = _postAdhanCountdownBaseId + prayerIndex;
    await cancelAllCountdowns(); // Cancel all other countdowns first
    await _cancelTimer(id);

    final iqamahTime = adhanTime.add(Duration(minutes: durationMinutes));
    final now = DateTime.now();

    if (now.isBefore(iqamahTime)) {
      _startPeriodicCountdown(
        id: id,
        targetTime: iqamahTime,
        titleBuilder: (remaining) => SX.current.countdownToIqamah(prayerName),
        bodyBuilder: (remaining) => _formatIqamahCountdownBody(remaining, prayerName),
        interval: const Duration(minutes: 1),
      );
    }
  }

  Future<void> startSunriseEndCountdown({
    required DateTime sunriseTime,
    required int durationMinutes,
  }) async {
    const id = _sunriseEndCountdownBaseId;
    await cancelAllCountdowns(); // Cancel all other countdowns first
    await _cancelTimer(id);

    final sunriseEndTime = sunriseTime.add(Duration(minutes: durationMinutes));
    final now = DateTime.now();

    if (now.isBefore(sunriseEndTime)) {
      _startPeriodicCountdown(
        id: id,
        targetTime: sunriseEndTime,
        titleBuilder: (remaining) => SX.current.countdownToSunriseEnd,
        bodyBuilder: (remaining) => _formatSunriseEndCountdownBody(remaining),
        interval: const Duration(minutes: 1),
      );
    }
  }

  void _startPeriodicCountdown({
    required int id,
    required DateTime targetTime,
    required String Function(Duration remaining) titleBuilder,
    required String Function(Duration remaining) bodyBuilder,
    required Duration interval,
  }) {
    _showCountdownNotification(id, targetTime, titleBuilder, bodyBuilder);

    _activeTimers[id] = Timer.periodic(interval, (timer) {
      _showCountdownNotification(id, targetTime, titleBuilder, bodyBuilder);
    });

    Future.delayed(targetTime.difference(DateTime.now()), () {
      _cancelTimer(id);
    });
  }

  Future<void> _showCountdownNotification(
    int id,
    DateTime targetTime,
    String Function(Duration remaining) titleBuilder,
    String Function(Duration remaining) bodyBuilder,
  ) async {
    final now = DateTime.now();
    final remaining = targetTime.difference(now);

    if (remaining.isNegative || remaining.inSeconds <= 0) {
      await _cancelTimer(id);
      return;
    }

    final title = titleBuilder(remaining);
    final body = bodyBuilder(remaining);

    final notificationManager = sl<LocalNotificationManager>();
    final androidPlugin = notificationManager.flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final bigTextStyleInformation = BigTextStyleInformation(
        body,
        htmlFormatBigText: true,
        contentTitle: title,
        htmlFormatContentTitle: true,
      );

      const String channelId = 'countdown_channel';

      final androidDetails = AndroidNotificationDetails(
        channelId,
        'عداد تنازلي',
        channelDescription: 'إشعارات العد التنازلي للصلوات',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: bigTextStyleInformation,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        ongoing: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await notificationManager.flutterLocalNotificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
      );
    }
  }

  Future<void> _cancelTimer(int id) async {
    _activeTimers[id]?.cancel();
    _activeTimers.remove(id);

    try {
      final notificationManager = sl<LocalNotificationManager>();
      await notificationManager.cancelNotificationById(id: id);
    } catch (e) {
      hisnPrint("Error canceling countdown notification: $e");
    }
  }

  Future<void> cancelAllCountdowns() async {
    final keys = List<int>.from(_activeTimers.keys);
    for (final key in keys) {
      await _cancelTimer(key);
    }
    _activeTimers.clear();
  }

  Future<void> cancelPreAdhanCountdowns() async {
    for (int i = 0; i < 10; i++) {
      await _cancelTimer(_preAdhanCountdownBaseId + i);
    }
  }

  Future<void> cancelPostAdhanCountdowns() async {
    for (int i = 0; i < 10; i++) {
      await _cancelTimer(_postAdhanCountdownBaseId + i);
    }
  }

  Future<void> cancelSunriseEndCountdown() async {
    await _cancelTimer(_sunriseEndCountdownBaseId);
  }

  String _formatCountdownBody(Duration remaining, String prayerName) {
    if (remaining.inHours > 0) {
      final hours = remaining.inHours;
      final minutes = remaining.inMinutes % 60;
      return SX.current.countdownMinutesToAdhanBody(prayerName, hours, minutes);
    }
    final minutes = remaining.inMinutes;
    if (minutes <= 5) {
      return SX.current.countdownMinutesToAdhanBodyFinal(prayerName, minutes);
    }
    return SX.current.countdownMinutesToAdhanBody(prayerName, 0, minutes);
  }

  String _formatIqamahCountdownBody(Duration remaining, String prayerName) {
    if (remaining.inHours > 0) {
      final hours = remaining.inHours;
      final minutes = remaining.inMinutes % 60;
      return SX.current.countdownMinutesToIqamahBody(prayerName, hours, minutes);
    }
    final minutes = remaining.inMinutes;
    return SX.current.countdownMinutesToIqamahBody(prayerName, 0, minutes);
  }

  String _formatSunriseEndCountdownBody(Duration remaining) {
    if (remaining.inHours > 0) {
      final hours = remaining.inHours;
      final minutes = remaining.inMinutes % 60;
      return SX.current.countdownSunriseEndBody(hours, minutes);
    }
    final minutes = remaining.inMinutes;
    return SX.current.countdownSunriseEndBody(0, minutes);
  }
}
