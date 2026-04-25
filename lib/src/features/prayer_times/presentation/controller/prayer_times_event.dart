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
