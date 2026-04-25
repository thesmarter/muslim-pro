import 'package:adhan/adhan.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_storage/get_storage.dart';
import 'package:muslim/src/features/prayer_times/data/models/prayer_settings.dart';

class PrayerTimesRepo {
  final GetStorage _box = GetStorage();
  static const String _settingsKey = 'prayer_settings';

  Future<void> saveSettings(PrayerSettings settings) async {
    await _box.write(_settingsKey, settings.toJson());
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
