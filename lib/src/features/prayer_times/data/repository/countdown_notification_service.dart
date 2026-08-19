import 'dart:async';

import 'package:flutter/services.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:muslim/src/core/extensions/localization_extension.dart';
import 'package:muslim/src/core/functions/print.dart';

class CountdownNotificationService {
  static final CountdownNotificationService _instance = CountdownNotificationService._internal();
  factory CountdownNotificationService() => _instance;
  CountdownNotificationService._internal();

  static const MethodChannel _channel = MethodChannel('countdown_service');

  final Map<int, Timer> _chainingTimers = {};

  static const int _preAdhanCountdownBaseId = 4000;
  static const int _postAdhanCountdownBaseId = 5000;
  static const int _sunriseEndCountdownBaseId = 6000;

  static const int _postAdhanDurationMinutes = 10;

  Future<void> startPreAdhanCountdown({
    required int prayerIndex,
    required String prayerName,
    required DateTime adhanTime,
    required int minutesBefore,
    String? cityName,
    String? countryName,
  }) async {
    await _cancelChainingTimer(_preAdhanCountdownBaseId + prayerIndex);

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
      _chainingTimers[_preAdhanCountdownBaseId + prayerIndex] = Timer(delay, () {
        _startNativeCountdown(
          id: _preAdhanCountdownBaseId + prayerIndex,
          targetTime: adhanTime,
          prayerName: prayerName,
          title: SX.current.adhanCountdownTitle(prayerName),
          cityName: cityName,
          countryName: countryName,
          onComplete: onAdhanReached,
        );
      });
    } else if (now.isBefore(adhanTime)) {
      _startNativeCountdown(
        id: _preAdhanCountdownBaseId + prayerIndex,
        targetTime: adhanTime,
        prayerName: prayerName,
        title: SX.current.adhanCountdownTitle(prayerName),
        cityName: cityName,
        countryName: countryName,
        onComplete: onAdhanReached,
      );
    }
  }

  Future<void> startPostAdhanCountdown({
    required int prayerIndex,
    required String prayerName,
    required DateTime adhanTime,
    required int durationMinutes,
    String? cityName,
    String? countryName,
  }) async {
    await _cancelChainingTimer(_postAdhanCountdownBaseId + prayerIndex);

    final iqamahTime = adhanTime.add(Duration(minutes: durationMinutes));
    final now = DateTime.now();

    if (now.isBefore(iqamahTime)) {
      _startNativeCountdown(
        id: _postAdhanCountdownBaseId + prayerIndex,
        targetTime: iqamahTime,
        prayerName: prayerName,
        title: SX.current.iqamahCountdownTitle(prayerName),
        cityName: cityName,
        countryName: countryName,
      );
    }
  }

  Future<void> startSunriseEndCountdown({
    required DateTime sunriseTime,
    required int durationMinutes,
    String? cityName,
    String? countryName,
  }) async {
    await _cancelChainingTimer(_sunriseEndCountdownBaseId);

    final sunriseEndTime = sunriseTime.add(Duration(minutes: durationMinutes));
    final now = DateTime.now();

    if (now.isBefore(sunriseEndTime)) {
      final sunriseName = SX.current.sunriseEndCountdownTitle;
      _startNativeCountdown(
        id: _sunriseEndCountdownBaseId,
        targetTime: sunriseEndTime,
        prayerName: sunriseName,
        title: sunriseName,
        cityName: cityName,
        countryName: countryName,
      );
    }
  }

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

  String _buildHeader(String? cityName, String? countryName) {
    final location = _getLocationDisplay(cityName, countryName);
    final hijriDate = _getHijriDate();
    if (location.isNotEmpty && hijriDate.isNotEmpty) return '$location - $hijriDate';
    if (hijriDate.isNotEmpty) return hijriDate;
    return location;
  }

  void _startNativeCountdown({
    required int id,
    required DateTime targetTime,
    required String prayerName,
    required String title,
    String? cityName,
    String? countryName,
    VoidCallback? onComplete,
  }) {
    final targetMillis = targetTime.millisecondsSinceEpoch;
    final header = _buildHeader(cityName, countryName);

    _channel.invokeMethod('startCountdown', {
      'targetTimeMillis': targetMillis,
      'prayerName': prayerName,
      'title': title,
      'city': cityName ?? '',
      'country': countryName ?? '',
      'type': 'pre_adhan',
      'header': header,
    }).then((_) {
      hisnPrint("Native countdown started for $prayerName");
    }).catchError((e) {
      hisnPrint("Error starting native countdown: $e");
    });

    if (onComplete != null) {
      final remaining = targetTime.difference(DateTime.now());
      if (remaining.inMilliseconds > 0) {
        _chainingTimers[id] = Timer(remaining, () {
          _chainingTimers.remove(id);
          onComplete.call();
        });
      }
    }
  }

  Future<void> _cancelChainingTimer(int id) async {
    _chainingTimers[id]?.cancel();
    _chainingTimers.remove(id);
  }

  Future<void> cancelAllCountdowns() async {
    for (final key in List<int>.from(_chainingTimers.keys)) {
      _chainingTimers[key]?.cancel();
    }
    _chainingTimers.clear();

    try {
      await _channel.invokeMethod('stopCountdown');
    } catch (e) {
      hisnPrint("Error stopping native countdown: $e");
    }
  }

  Future<void> cancelPreAdhanCountdowns() async {
    for (int i = 0; i < 10; i++) {
      await _cancelChainingTimer(_preAdhanCountdownBaseId + i);
    }
    try {
      await _channel.invokeMethod('stopCountdown');
    } catch (_) {}
  }

  Future<void> cancelPostAdhanCountdowns() async {
    for (int i = 0; i < 10; i++) {
      await _cancelChainingTimer(_postAdhanCountdownBaseId + i);
    }
    try {
      await _channel.invokeMethod('stopCountdown');
    } catch (_) {}
  }

  Future<void> cancelSunriseEndCountdown() async {
    await _cancelChainingTimer(_sunriseEndCountdownBaseId);
    try {
      await _channel.invokeMethod('stopCountdown');
    } catch (_) {}
  }
}
