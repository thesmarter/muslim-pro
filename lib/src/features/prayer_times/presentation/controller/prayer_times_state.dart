import 'package:adhan/adhan.dart';
import 'package:equatable/equatable.dart';
import 'package:muslim/src/features/prayer_times/data/models/prayer_settings.dart';

enum PrayerTimesStatus { initial, loading, loaded, error }

class LocationSuggestion {
  final double latitude;
  final double longitude;
  final String? cityName;
  final String? countryName;

  const LocationSuggestion({
    required this.latitude,
    required this.longitude,
    this.cityName,
    this.countryName,
  });
}

class PrayerTimesState extends Equatable {
  final PrayerTimesStatus status;
  final PrayerSettings settings;
  final PrayerTimes? prayerTimes;
  final String? errorMessage;
  final List<LocationSuggestion> searchResults;

  const PrayerTimesState({
    this.status = PrayerTimesStatus.initial,
    this.settings = const PrayerSettings(),
    this.prayerTimes,
    this.errorMessage,
    this.searchResults = const [],
  });

  PrayerTimesState copyWith({
    PrayerTimesStatus? status,
    PrayerSettings? settings,
    PrayerTimes? prayerTimes,
    String? errorMessage,
    List<LocationSuggestion>? searchResults,
  }) {
    return PrayerTimesState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      prayerTimes: prayerTimes ?? this.prayerTimes,
      errorMessage: errorMessage ?? this.errorMessage,
      searchResults: searchResults ?? this.searchResults,
    );
  }

  @override
  List<Object?> get props => [status, settings, prayerTimes, errorMessage, searchResults];
}
