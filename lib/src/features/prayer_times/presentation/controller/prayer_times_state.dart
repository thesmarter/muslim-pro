import 'package:adhan/adhan.dart';
import 'package:equatable/equatable.dart';
import 'package:muslim/src/features/prayer_times/data/models/prayer_settings.dart';

enum PrayerTimesStatus { initial, loading, loaded, error }

class PrayerTimesState extends Equatable {
  final PrayerTimesStatus status;
  final PrayerSettings settings;
  final PrayerTimes? prayerTimes;
  final String? errorMessage;

  const PrayerTimesState({
    this.status = PrayerTimesStatus.initial,
    this.settings = const PrayerSettings(),
    this.prayerTimes,
    this.errorMessage,
  });

  PrayerTimesState copyWith({
    PrayerTimesStatus? status,
    PrayerSettings? settings,
    PrayerTimes? prayerTimes,
    String? errorMessage,
  }) {
    return PrayerTimesState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      prayerTimes: prayerTimes ?? this.prayerTimes,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, settings, prayerTimes, errorMessage];
}
