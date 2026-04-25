import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/src/features/prayer_times/data/repository/prayer_times_repo.dart';
import 'package:muslim/src/features/prayer_times/presentation/controller/prayer_times_event.dart';
import 'package:muslim/src/features/prayer_times/presentation/controller/prayer_times_state.dart';

class PrayerTimesBloc extends Bloc<PrayerTimesEvent, PrayerTimesState> {
  final PrayerTimesRepo repo;

  PrayerTimesBloc(this.repo) : super(const PrayerTimesState()) {
    on<LoadPrayerTimes>(_onLoadPrayerTimes);
    on<UpdatePrayerSettings>(_onUpdatePrayerSettings);
    on<DetectLocation>(_onDetectLocation);
    on<SearchLocation>(_onSearchLocation);
  }

  Future<void> _onSearchLocation(SearchLocation event, Emitter<PrayerTimesState> emit) async {
    emit(state.copyWith(status: PrayerTimesStatus.loading));
    try {
      final locations = await repo.searchLocation(event.query);
      if (locations.isEmpty) {
        emit(state.copyWith(status: PrayerTimesStatus.error, errorMessage: "Location not found. Please try a different city name."));
        return;
      }

      final position = locations.first;
      final placemark = await repo.getPlacemark(position.latitude, position.longitude);

      final newSettings = state.settings.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
        cityName: placemark?.locality ?? event.query,
        countryName: placemark?.country,
      );

      await repo.saveSettings(newSettings);
      final prayerTimes = repo.calculatePrayerTimes(newSettings, DateTime.now());
      emit(state.copyWith(status: PrayerTimesStatus.loaded, settings: newSettings, prayerTimes: prayerTimes));
    } catch (e) {
      emit(state.copyWith(status: PrayerTimesStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onLoadPrayerTimes(LoadPrayerTimes event, Emitter<PrayerTimesState> emit) async {
    emit(state.copyWith(status: PrayerTimesStatus.loading));
    final settings = repo.getSettings();
    if (settings.latitude == 0 && settings.longitude == 0) {
      // If no location is set, we might want to automatically detect it or show a placeholder
      emit(state.copyWith(status: PrayerTimesStatus.initial, settings: settings));
      return;
    }
    final prayerTimes = repo.calculatePrayerTimes(settings, DateTime.now());
    emit(state.copyWith(status: PrayerTimesStatus.loaded, settings: settings, prayerTimes: prayerTimes));
  }

  Future<void> _onUpdatePrayerSettings(UpdatePrayerSettings event, Emitter<PrayerTimesState> emit) async {
    await repo.saveSettings(event.settings);
    final prayerTimes = repo.calculatePrayerTimes(event.settings, DateTime.now());
    emit(state.copyWith(status: PrayerTimesStatus.loaded, settings: event.settings, prayerTimes: prayerTimes));
  }

  Future<void> _onDetectLocation(DetectLocation event, Emitter<PrayerTimesState> emit) async {
    emit(state.copyWith(status: PrayerTimesStatus.loading));
    try {
      final position = await repo.getCurrentPosition();
      final placemark = await repo.getPlacemark(position.latitude, position.longitude);

      final newSettings = state.settings.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
        cityName: placemark?.locality,
        countryName: placemark?.country,
      );

      await repo.saveSettings(newSettings);
      final prayerTimes = repo.calculatePrayerTimes(newSettings, DateTime.now());
      emit(state.copyWith(status: PrayerTimesStatus.loaded, settings: newSettings, prayerTimes: prayerTimes));
    } catch (e) {
      emit(state.copyWith(status: PrayerTimesStatus.error, errorMessage: e.toString()));
    }
  }
}
