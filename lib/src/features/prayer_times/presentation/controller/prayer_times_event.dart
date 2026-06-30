import 'package:equatable/equatable.dart';
import 'package:muslim/src/features/prayer_times/data/models/prayer_settings.dart';

abstract class PrayerTimesEvent extends Equatable {
  const PrayerTimesEvent();

  @override
  List<Object?> get props => [];
}

class LoadPrayerTimes extends PrayerTimesEvent {}

class UpdatePrayerSettings extends PrayerTimesEvent {
  final PrayerSettings settings;
  const UpdatePrayerSettings(this.settings);

  @override
  List<Object?> get props => [settings];
}

class DetectLocation extends PrayerTimesEvent {}

class SearchLocation extends PrayerTimesEvent {
  final String query;
  const SearchLocation(this.query);

  @override
  List<Object?> get props => [query];
}

class SearchLocationSuggestions extends PrayerTimesEvent {
  final String query;
  const SearchLocationSuggestions(this.query);

  @override
  List<Object?> get props => [query];
}

class DetectLocationByIP extends PrayerTimesEvent {}

class SelectLocation extends PrayerTimesEvent {
  final double latitude;
  final double longitude;
  final String? cityName;
  final String? countryName;

  const SelectLocation({
    required this.latitude,
    required this.longitude,
    this.cityName,
    this.countryName,
  });

  @override
  List<Object?> get props => [latitude, longitude, cityName, countryName];
}
