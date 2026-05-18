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

class PrayerTimesRepo {
  late final GetStorage _box = GetStorage();
  static const String _settingsKey = 'prayer_settings';

  static const String defaultMuadhin = 'wadie_alyamani';

  static const int _adhanIdBase = 3000;
  static const int _adhanScheduleDays = 30;

  Future<void> saveSettings(PrayerSettings settings) async {
    await _box.write(_settingsKey, settings.toJson());
    await schedulePrayerNotifications(settings);
  }

  Future<void> schedulePrayerNotifications(PrayerSettings settings) async {
    final notificationManager = sl<LocalNotificationManager>();
    final adhanService = sl<AdhanAudioService>();

    if (settings.latitude == 0 && settings.longitude == 0) {
      try {
        final position = await getCurrentPosition();
        final placemark = await getPlacemark(position.latitude, position.longitude);
        final newSettings = settings.copyWith(
          latitude: position.latitude,
          longitude: position.longitude,
          cityName: placemark?.locality,
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

    return await Geolocator.getCurrentPosition();
  }

  Future<Placemark?> getPlacemark(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
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
      return await locationFromAddress(query);
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
