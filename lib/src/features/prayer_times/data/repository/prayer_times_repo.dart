import 'package:adhan/adhan.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_storage/get_storage.dart';
import 'package:muslim/src/core/di/dependency_injection.dart';
import 'package:muslim/src/core/extensions/localization_extension.dart';
import 'package:muslim/src/core/functions/print.dart';
import 'package:muslim/src/features/alarms_manager/data/models/local_notification_manager.dart';
import 'package:muslim/src/features/prayer_times/data/models/prayer_settings.dart';
import 'package:muslim/src/features/prayer_times/data/repository/adhan_audio_service.dart';
import 'package:muslim/src/features/prayer_times/data/repository/countdown_notification_service.dart';

class PrayerTimesRepo {
  late final GetStorage _box = GetStorage();
  static const String _settingsKey = 'prayer_settings';
  final Geocoding _geocoding = Geocoding();

  static const String defaultMuadhin = 'wadie_alyamani';

  static const int _adhanIdBase = 3000;
  static const int _adhanScheduleDays = 30;

  static const int _preAdhanScheduledBaseId = 7000;
  static const int _postAdhanScheduledBaseId = 8000;
  static const int _preAdhanMinutes = 20;
  static const int _postAdhanMinutes = 10;

  Future<void> saveSettings(PrayerSettings settings) async {
    await _box.write(_settingsKey, settings.toJson());
    await schedulePrayerNotifications(settings);
  }

  Future<void> schedulePrayerNotifications(PrayerSettings settings) async {
    final notificationManager = sl<LocalNotificationManager>();
    final adhanService = sl<AdhanAudioService>();
    final countdownService = sl<CountdownNotificationService>();

    if (settings.latitude == 0 && settings.longitude == 0) {
      try {
        final position = await getCurrentPosition();
        final placemark = await getPlacemark(position.latitude, position.longitude);
        final newSettings = settings.copyWith(
          latitude: position.latitude,
          longitude: position.longitude,
          cityName: placemark?.locality ?? placemark?.name,
          countryName: placemark?.country,
        );
        await saveSettings(newSettings);
        hisnPrint("Location auto-detected: ${newSettings.cityName}");
      } catch (e) {
        hisnPrint("Error auto-detecting location: $e");
        return;
      }
    }

    if (settings.latitude == 0 && settings.longitude == 0) return;

    // Cancel ALL existing notifications and alarms
    for (int i = 2000; i <= 2010; i++) {
      await notificationManager.cancelNotificationById(id: i);
    }
    await adhanService.cancelAllAdhanAlarms();
    await countdownService.cancelAllCountdowns();
    await notificationManager.cancelPreAdhanScheduledNotifications();
    await notificationManager.cancelPostAdhanScheduledNotifications();

    final now = DateTime.now();
    final selectedMuadhin = settings.muadhin.isNotEmpty
        ? settings.muadhin
        : defaultMuadhin;

    // ─────────────────────────────────────────────────────
    // 1. ADHAN PRAYERS: Schedule 30 days ahead via native AlarmManager
    //    فجر, ظهر, عصر, مغرب, عشاء
    // ─────────────────────────────────────────────────────
    final adhanPrayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

    for (int dayOffset = 0; dayOffset < _adhanScheduleDays; dayOffset++) {
      final date = now.add(Duration(days: dayOffset));
      final pt = calculatePrayerTimes(settings, date);

      for (int pIndex = 0; pIndex < adhanPrayers.length; pIndex++) {
        final prayerKey = adhanPrayers[pIndex];
        final prayerTime = _getPrayerTimeFromTimes(pt, prayerKey);
        final isEnabled = settings.notifications[prayerKey] ?? false;

        if (!isEnabled) continue;
        if (dayOffset == 0 && prayerTime.isBefore(now)) continue;

        final id = _adhanIdBase + dayOffset * 10 + pIndex;
        final prayerName = SX.current.getValue(prayerKey);

        await adhanService.scheduleAdhanAlarm(
          muadhin: selectedMuadhin,
          prayerName: prayerName,
          time: prayerTime,
          volume: settings.adhanVolume,
          id: id,
          playSound: settings.playAdhanSound,
        );
        hisnPrint("Scheduled adhan alarm [$id] for $prayerKey on $date at $prayerTime");
      }
    }

    // ─────────────────────────────────────────────────────
    // 2. NON-ADHAN NOTIFICATIONS: sunrise + sunrise_end
    //    تستخدم flutter_local_notifications مع matchDateTimeComponents
    //    لتكرار الإشعار يومياً تلقائياً
    // ─────────────────────────────────────────────────────
    final todayPt = calculatePrayerTimes(settings, now);
    final nonAdhanTimes = <String, DateTime>{
      'sunrise': todayPt.sunrise,
      'sunrise_end': todayPt.sunrise.add(const Duration(minutes: 15)),
    };

    for (final entry in nonAdhanTimes.entries) {
      final prayerKey = entry.key;
      final prayerTime = entry.value;
      final isEnabled = settings.notifications[prayerKey] ?? false;

      if (!isEnabled) continue;

      DateTime scheduledTime = prayerTime;
      if (prayerTime.isBefore(now)) {
        scheduledTime = prayerTime.add(const Duration(days: 1));
      }

      final title = prayerKey == 'sunrise'
          ? SX.current.sunrise
          : SX.current.sunriseEnd;

      final body = prayerKey == 'sunrise'
          ? SX.current.sunriseNotificationBody
          : SX.current.sunriseEndNotificationBody;

      await notificationManager.addCustomDailyReminder(
        id: prayerKey == 'sunrise' ? 2001 : 2002,
        title: title,
        body: body,
        time: Time(scheduledTime.hour, scheduledTime.minute),
        payload: "prayer_time_$prayerKey",
        requestPermission: false,
      );
    hisnPrint("Scheduled daily notification for $prayerKey at ${scheduledTime.hour}:${scheduledTime.minute}");
    }

    // ─────────────────────────────────────────────────────
    // 3. COUNTDOWN NOTIFICATIONS: Pre-adhan, Post-adhan, and Sunrise End
    //    إشعارات العد التنازلي قبل الأذان وبعده وانتهاء الشروق
    // ─────────────────────────────────────────────────────
    await _scheduleCountdownNotifications(settings, todayPt, now);
  }

  Future<void> _scheduleCountdownNotifications(
    PrayerSettings settings,
    PrayerTimes todayPt,
    DateTime now,
  ) async {
    final notificationManager = sl<LocalNotificationManager>();
    final countdownService = sl<CountdownNotificationService>();
    await countdownService.cancelAllCountdowns();

    final adhanPrayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

    // ─────────────────────────────────────────────────────
    // Schedule pre-adhan and post-adhan notifications for ALL 30 days
    // using zonedSchedule (persists across app restarts)
    // ─────────────────────────────────────────────────────
    for (int dayOffset = 0; dayOffset < _adhanScheduleDays; dayOffset++) {
      final date = now.add(Duration(days: dayOffset));
      final pt = calculatePrayerTimes(settings, date);

      for (int pIndex = 0; pIndex < adhanPrayers.length; pIndex++) {
        final prayerKey = adhanPrayers[pIndex];
        final prayerTime = _getPrayerTimeFromTimes(pt, prayerKey);
        final isEnabled = settings.notifications[prayerKey] ?? false;

        if (!isEnabled) continue;

        final prayerName = SX.current.getValue(prayerKey);

        // Pre-adhan notification (20 min before)
        final preAdhanTime = prayerTime.subtract(const Duration(minutes: _preAdhanMinutes));
        if (preAdhanTime.isAfter(now)) {
          final preId = _preAdhanScheduledBaseId + dayOffset * 10 + pIndex;
          await notificationManager.schedulePreAdhanNotification(
            id: preId,
            title: SX.current.adhanCountdownTitle(prayerName),
            body: '$prayerName - ${SX.current.countdownToAdhan(prayerName)}',
            scheduledDate: preAdhanTime,
            payload: 'prayer_time_pre_adhan_$prayerKey',
          );
        }

        // Post-adhan (iqamah) notification (10 min after)
        final iqamahTime = prayerTime.add(const Duration(minutes: _postAdhanMinutes));
        if (iqamahTime.isAfter(now)) {
          final postId = _postAdhanScheduledBaseId + dayOffset * 10 + pIndex;
          await notificationManager.schedulePostAdhanNotification(
            id: postId,
            title: SX.current.iqamahCountdownTitle(prayerName),
            body: '$prayerName - ${SX.current.countdownToIqamah(prayerName)}',
            scheduledDate: iqamahTime,
            payload: 'prayer_time_post_adhan_$prayerKey',
          );
        }
      }
    }

    hisnPrint("Scheduled pre/post adhan notifications for $_adhanScheduleDays days");

    // ─────────────────────────────────────────────────────
    // Also start live countdown for current/next prayer (foreground only)
    // This gives a nice ticking countdown when app is open
    // ─────────────────────────────────────────────────────
    // Case 1: We're in the pre-adhan period for a prayer (20 min before)
    for (int pIndex = 0; pIndex < adhanPrayers.length; pIndex++) {
      final prayerKey = adhanPrayers[pIndex];
      final prayerTime = _getPrayerTimeFromTimes(todayPt, prayerKey);
      final isEnabled = settings.notifications[prayerKey] ?? false;

      if (!isEnabled) continue;

      final prayerName = SX.current.getValue(prayerKey);
      final preAdhanStart = prayerTime.subtract(const Duration(minutes: _preAdhanMinutes));

      if (now.isAfter(preAdhanStart) && now.isBefore(prayerTime)) {
        await countdownService.startPreAdhanCountdown(
          prayerIndex: pIndex,
          prayerName: prayerName,
          adhanTime: prayerTime,
          minutesBefore: _preAdhanMinutes,
          cityName: settings.cityName,
          countryName: settings.countryName,
        );
        return;
      }
    }

    // Case 2: We're in the post-adhan period (10 min after prayer)
    for (int pIndex = 0; pIndex < adhanPrayers.length; pIndex++) {
      final prayerKey = adhanPrayers[pIndex];
      final prayerTime = _getPrayerTimeFromTimes(todayPt, prayerKey);
      final isEnabled = settings.notifications[prayerKey] ?? false;

      if (!isEnabled) continue;

      final prayerName = SX.current.getValue(prayerKey);
      final postAdhanEnd = prayerTime.add(const Duration(minutes: _postAdhanMinutes));

      if (now.isAfter(prayerTime) && now.isBefore(postAdhanEnd)) {
        await countdownService.startPostAdhanCountdown(
          prayerIndex: pIndex,
          prayerName: prayerName,
          adhanTime: prayerTime,
          durationMinutes: _postAdhanMinutes,
          cityName: settings.cityName,
          countryName: settings.countryName,
        );
        return;
      }
    }

    // Case 3: Schedule countdown for the next upcoming prayer
    for (int pIndex = 0; pIndex < adhanPrayers.length; pIndex++) {
      final prayerKey = adhanPrayers[pIndex];
      final prayerTime = _getPrayerTimeFromTimes(todayPt, prayerKey);
      final isEnabled = settings.notifications[prayerKey] ?? false;

      if (!isEnabled) continue;

      final prayerName = SX.current.getValue(prayerKey);

      if (now.isBefore(prayerTime)) {
        await countdownService.startPreAdhanCountdown(
          prayerIndex: pIndex,
          prayerName: prayerName,
          adhanTime: prayerTime,
          minutesBefore: _preAdhanMinutes,
          cityName: settings.cityName,
          countryName: settings.countryName,
        );
        return;
      }
    }

    // Case 4: Sunrise end countdown
    if (settings.notifications['sunrise'] ?? false) {
      final sunriseTime = todayPt.sunrise;
      final sunriseEndTime = sunriseTime.add(const Duration(minutes: 15));

      if (now.isAfter(sunriseTime) && now.isBefore(sunriseEndTime)) {
        await countdownService.startSunriseEndCountdown(
          sunriseTime: sunriseTime,
          durationMinutes: 15,
          cityName: settings.cityName,
          countryName: settings.countryName,
        );
        return;
      }
    }
  }

  DateTime _getPrayerTimeFromTimes(PrayerTimes times, String key) {
    switch (key) {
      case 'fajr': return times.fajr;
      case 'sunrise': return times.sunrise;
      case 'sunrise_end': return times.sunrise.add(const Duration(minutes: 15));
      case 'dhuhr': return times.dhuhr;
      case 'asr': return times.asr;
      case 'maghrib': return times.maghrib;
      case 'isha': return times.isha;
      default: return times.fajr;
    }
  }

  PrayerSettings getSettings() {
    final data = _box.read(_settingsKey);
    if (data == null) {
      return const PrayerSettings();
    }
    return PrayerSettings.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<Position> getCurrentPosition() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return Future.error('Location services are disabled.');
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return Future.error('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return Future.error('Location permissions are permanently denied, we cannot request permissions.');
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );
    } catch (e) {
      hisnPrint("Error getting current position: $e");
      return Future.error('Failed to get location: $e');
    }
  }

  Future<Placemark?> getPlacemark(double latitude, double longitude) async {
    try {
      final placemarks = await _geocoding.placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        return placemarks.first;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<List<Location>> searchLocation(String query) async {
    try {
      return await _geocoding.locationFromAddress(query);
    } catch (e) {
      return [];
    }
  }

  PrayerTimes calculatePrayerTimes(PrayerSettings settings, DateTime date) {
    final coordinates = Coordinates(settings.latitude, settings.longitude);
    final params = _getCalculationMethod(settings.calculationMethod);

    params.adjustments.fajr = settings.adjustments['fajr'] ?? 0;
    params.adjustments.sunrise = settings.adjustments['sunrise'] ?? 0;
    params.adjustments.dhuhr = settings.adjustments['dhuhr'] ?? 0;
    params.adjustments.asr = settings.adjustments['asr'] ?? 0;
    params.adjustments.maghrib = settings.adjustments['maghrib'] ?? 0;
    params.adjustments.isha = settings.adjustments['isha'] ?? 0;

    final dateComponents = DateComponents.from(date);
    return PrayerTimes(coordinates, dateComponents, params);
  }

  CalculationParameters _getCalculationMethod(String method) {
    switch (method) {
      case 'muslim_world_league':
        return CalculationMethod.muslim_world_league.getParameters();
      case 'egyptian':
        return CalculationMethod.egyptian.getParameters();
      case 'karachi':
        return CalculationMethod.karachi.getParameters();
      case 'umm_al_qura':
        return CalculationMethod.umm_al_qura.getParameters();
      case 'dubai':
        return CalculationMethod.dubai.getParameters();
      case 'moon_sighting_committee':
        return CalculationMethod.moon_sighting_committee.getParameters();
      case 'north_america':
        return CalculationMethod.north_america.getParameters();
      case 'kuwait':
        return CalculationMethod.kuwait.getParameters();
      case 'qatar':
        return CalculationMethod.qatar.getParameters();
      case 'singapore':
        return CalculationMethod.singapore.getParameters();
      case 'tehran':
        return CalculationMethod.tehran.getParameters();
      case 'turkey':
        return CalculationMethod.turkey.getParameters();
      default:
        return CalculationMethod.muslim_world_league.getParameters();
    }
  }
}
