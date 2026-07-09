import 'dart:async';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hijri/hijri_calendar.dart';
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

  String _getHijriDate() {
    final hijri = HijriCalendar.now();
    final hijriMonths = [
      '', 'محرم', 'صفر', 'ربيع الأول', 'ربيع الثاني',
      'جمادى الأولى', 'جمادى الآخرة', 'رجب', 'شعبان',
      'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة',
    ];
    final monthName = hijriMonths[hijri.hMonth];
    return '${hijri.hDay} $monthName ${hijri.hYear}';
  }

  String _getLocationDisplay(String? cityName, String? countryName) {
    final city = cityName ?? '';
    final country = countryName ?? '';
    if (city.isNotEmpty && country.isNotEmpty) return '$city - $country';
    if (city.isNotEmpty) return city;
    if (country.isNotEmpty) return country;
    return '';
  }

  Future<void> startPreAdhanCountdown({
    required int prayerIndex,
    required String prayerName,
    required DateTime adhanTime,
    required int minutesBefore,
    String? cityName,
    String? countryName,
  }) async {
    final id = _preAdhanCountdownBaseId + prayerIndex;
    await _cancelTimer(id);

    final now = DateTime.now();
    final countdownStartTime = adhanTime.subtract(Duration(minutes: minutesBefore));

    void onAdhanReached() {
      startPostAdhanCountdown(
        prayerIndex: prayerIndex,
        prayerName: prayerName,
        adhanTime: adhanTime,
        durationMinutes: _postAdhanDurationMinutes,
        cityName: cityName,
        countryName: countryName,
      );
    }

    if (now.isBefore(countdownStartTime)) {
      final delay = countdownStartTime.difference(now);
      _activeTimers[id] = Timer(delay, () {
        _startPeriodicCountdown(
          id: id,
          targetTime: adhanTime,
          title: SX.current.adhanCountdownTitle(prayerName),
          interval: const Duration(seconds: 1),
          onComplete: onAdhanReached,
          cityName: cityName,
          countryName: countryName,
          prayerName: prayerName,
        );
      });
    } else if (now.isBefore(adhanTime)) {
      _startPeriodicCountdown(
        id: id,
        targetTime: adhanTime,
        title: SX.current.adhanCountdownTitle(prayerName),
        interval: const Duration(seconds: 1),
        onComplete: onAdhanReached,
        cityName: cityName,
        countryName: countryName,
        prayerName: prayerName,
      );
    }
  }

  static const int _postAdhanDurationMinutes = 10;

  Future<void> startPostAdhanCountdown({
    required int prayerIndex,
    required String prayerName,
    required DateTime adhanTime,
    required int durationMinutes,
    String? cityName,
    String? countryName,
  }) async {
    final id = _postAdhanCountdownBaseId + prayerIndex;
    await _cancelTimer(id);

    final iqamahTime = adhanTime.add(Duration(minutes: durationMinutes));
    final now = DateTime.now();

    if (now.isBefore(iqamahTime)) {
      _startPeriodicCountdown(
        id: id,
        targetTime: iqamahTime,
        title: SX.current.iqamahCountdownTitle(prayerName),
        interval: const Duration(seconds: 1),
        cityName: cityName,
        countryName: countryName,
        prayerName: prayerName,
      );
    }
  }

  Future<void> startSunriseEndCountdown({
    required DateTime sunriseTime,
    required int durationMinutes,
    String? cityName,
    String? countryName,
  }) async {
    const id = _sunriseEndCountdownBaseId;
    await _cancelTimer(id);

    final sunriseEndTime = sunriseTime.add(Duration(minutes: durationMinutes));
    final now = DateTime.now();

    if (now.isBefore(sunriseEndTime)) {
      _startPeriodicCountdown(
        id: id,
        targetTime: sunriseEndTime,
        title: SX.current.sunriseEndCountdownTitle,
        interval: const Duration(seconds: 1),
        cityName: cityName,
        countryName: countryName,
        prayerName: SX.current.sunriseEndCountdownTitle,
      );
    }
  }

  void _startPeriodicCountdown({
    required int id,
    required DateTime targetTime,
    required String title,
    required Duration interval,
    VoidCallback? onComplete,
    String? cityName,
    String? countryName,
    String? prayerName,
  }) {
    _showCountdownNotification(id, targetTime, title, cityName, countryName, prayerName);

    _activeTimers[id] = Timer.periodic(interval, (timer) {
      final remaining = targetTime.difference(DateTime.now());
      if (remaining.isNegative || remaining.inSeconds <= 0) {
        _cancelTimer(id);
        onComplete?.call();
        return;
      }
      _showCountdownNotification(id, targetTime, title, cityName, countryName, prayerName);
    });
  }

  void _showCountdownNotification(
    int id,
    DateTime targetTime,
    String title,
    String? cityName,
    String? countryName,
    String? prayerName,
  ) {
    final now = DateTime.now();
    final remaining = targetTime.difference(now);

    if (remaining.isNegative || remaining.inSeconds <= 0) {
      _cancelTimer(id);
      return;
    }

    final timeStr = _formatTime(remaining);
    final hijriDate = _getHijriDate();
    final location = _getLocationDisplay(cityName, countryName);

    // Title: location + Hijri date
    final notificationTitle = location.isNotEmpty ? '$location - $hijriDate' : hijriDate;

    // Body: prayer name + remaining time
    final prayerLabel = prayerName ?? title;
    final body = '$prayerLabel - $timeStr';

    final notificationManager = sl<LocalNotificationManager>();
    final androidPlugin = notificationManager.flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      const String channelId = 'countdown_channel';

      const androidDetails = AndroidNotificationDetails(
        channelId,
        'عداد تنازلي',
        channelDescription: 'إشعارات العد التنازلي للصلوات',
        importance: Importance.low,
        priority: Priority.low,
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        color: Color(0xFFE53935),
        ongoing: true,
        playSound: false,
        enableVibration: false,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      notificationManager.flutterLocalNotificationsPlugin
          .show(
            id: id,
            title: notificationTitle,
            body: body,
            notificationDetails: details,
          )
          .catchError((e) => hisnPrint("Error showing countdown: $e"));
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

  String _formatTime(Duration remaining) {
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    String pad(int n) => n.toString().padLeft(2, '0');

    if (hours > 0) {
      return '${pad(hours)}:${pad(minutes)}:${pad(seconds)}';
    }
    return '${pad(minutes)}:${pad(seconds)}';
  }
}
