import 'package:adhan/adhan.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_storage/get_storage.dart';
import 'package:muslim/src/core/di/dependency_injection.dart';
import 'package:muslim/src/core/extensions/localization_extension.dart';
import 'package:muslim/src/core/functions/print.dart';
import 'package:muslim/src/features/alarms_manager/data/models/local_notification_manager.dart';
import 'package:muslim/src/features/prayer_times/data/models/prayer_settings.dart';

class PrayerTimesRepo {
  late final GetStorage _box = GetStorage();
  static const String _settingsKey = 'prayer_settings';

  /// Default muadhin used when none is selected
  static const String defaultMuadhin = 'wadie_alyamani';

  Future<void> saveSettings(PrayerSettings settings) async {
    await _box.write(_settingsKey, settings.toJson());
    await schedulePrayerNotifications(settings);
  }

  Future<void> schedulePrayerNotifications(PrayerSettings settings) async {
    final notificationManager = sl<LocalNotificationManager>();
    
    // Auto-detect location if not set
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
      'sunrise_end': prayerTimes.sunrise.add(const Duration(minutes: 15)),
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

    // Determine the muadhin to use (user-selected or default)
    final selectedMuadhin = settings.muadhin.isNotEmpty 
        ? settings.muadhin 
        : defaultMuadhin;

    for (final entry in times.entries) {
      final prayerKey = entry.key;
      final prayerTime = entry.value;
      final isEnabled = settings.notifications[prayerKey] ?? false;

      if (isEnabled) {
        DateTime finalScheduledTime = prayerTime;
        if (prayerTime.isBefore(now)) {
          // If the time for today has passed, schedule for tomorrow
          final tomorrow = now.add(const Duration(days: 1));
          final tomorrowPrayerTimes = calculatePrayerTimes(settings, tomorrow);
          finalScheduledTime = _getPrayerTimeFromTimes(tomorrowPrayerTimes, prayerKey);
        }

        final title = (prayerKey == 'sunrise')
            ? SX.current.sunrise
            : (prayerKey == 'sunrise_end')
                ? SX.current.sunriseEnd
                : SX.current.getValue(prayerKey);

        final body = (prayerKey == 'sunrise')
            ? SX.current.sunriseNotificationBody
            : (prayerKey == 'sunrise_end')
                ? SX.current.sunriseEndNotificationBody
                : SX.current.prayerTimeReminder(SX.current.getValue(prayerKey));

        // Adhan only plays for actual prayer times (not sunrise/sunrise_end)
        final isAdhan = settings.playAdhanSound && 
                      prayerKey != 'sunrise' && 
                      prayerKey != 'sunrise_end';

        if (isAdhan) {
          await notificationManager.scheduleAdhanNotification(
            id: ids[prayerKey]!,
            title: title,
            body: body,
            scheduledDate: finalScheduledTime,
            payload: "adhan_${selectedMuadhin}_$prayerKey",
            soundFileName: selectedMuadhin,
          );
          hisnPrint("Scheduled adhan for $prayerKey at $finalScheduledTime with muadhin: $selectedMuadhin");
        } else {
          await notificationManager.addCustomDailyReminder(
            id: ids[prayerKey]!,
            title: title,
            body: body,
            time: Time(finalScheduledTime.hour, finalScheduledTime.minute),
            payload: "prayer_time_$prayerKey",
            requestPermission: false,
          );
          hisnPrint("Scheduled regular notification for $prayerKey at $finalScheduledTime");
        }
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
