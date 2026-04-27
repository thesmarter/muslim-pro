import 'package:adhan/adhan.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_storage/get_storage.dart';
import 'package:muslim/src/core/di/dependency_injection.dart';
import 'package:muslim/src/core/extensions/localization_extesion.dart';
import 'package:muslim/src/features/alarms_manager/data/models/local_notification_manager.dart';
import 'package:muslim/src/features/prayer_times/data/models/prayer_settings.dart';

class PrayerTimesRepo {
  final GetStorage _box = GetStorage();
  static const String _settingsKey = 'prayer_settings';

  Future<void> saveSettings(PrayerSettings settings) async {
    await _box.write(_settingsKey, settings.toJson());
    await schedulePrayerNotifications(settings);
  }

  Future<void> schedulePrayerNotifications(PrayerSettings settings) async {
    final notificationManager = sl<LocalNotificationManager>();
    
    // Cancel existing prayer notifications first
    // Using a specific range of IDs for prayer times (e.g., 2000-2010)
    for (int i = 2000; i <= 2010; i++) {
      await notificationManager.cancelNotificationById(id: i);
    }

    if (settings.latitude == 0 && settings.longitude == 0) return;

    final now = DateTime.now();
    final prayerTimes = calculatePrayerTimes(settings, now);
    
    final Map<String, DateTime> times = {
      'fajr': prayerTimes.fajr,
      'sunrise': prayerTimes.sunrise,
      'sunrise_end': prayerTimes.sunrise.add(const Duration(minutes: 15)), // Example: 15 mins after sunrise
      'dhuhr': prayerTimes.dhuhr,
      'asr': prayerTimes.asr,
      'maghrib': prayerTimes.maghrib,
      'isha': prayerTimes.isha,
    };

    final Map<String, int> ids = {
      'fajr': 2000,
      'sunrise': 2001,
      'sunrise_end': 2002,
      'dhuhr': 2003,
      'asr': 2004,
      'maghrib': 2005,
      'isha': 2006,
    };

    for (var entry in times.entries) {
      final prayerKey = entry.key;
      final prayerTime = entry.value;
      final isEnabled = settings.notifications[prayerKey] ?? false;

      if (isEnabled && prayerTime.isAfter(now)) {
        String title = "";
        String body = SX.current.prayerTimeReminder(SX.current.getValue(prayerKey));

        if (prayerKey == 'sunrise') {
          title = SX.current.sunrise;
          body = SX.current.sunriseNotificationBody;
        } else if (prayerKey == 'sunrise_end') {
          title = SX.current.sunriseEnd;
          body = SX.current.sunriseEndNotificationBody;
        } else {
          title = SX.current.getValue(prayerKey);
        }

        await notificationManager.addCustomDailyReminder(
          id: ids[prayerKey]!,
          title: title,
          body: body,
          time: Time(prayerTime.hour, prayerTime.minute),
          payload: "prayer_time_$prayerKey",
          requestPermission: false,
        );
      }
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
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
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

    // Apply adjustments
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
