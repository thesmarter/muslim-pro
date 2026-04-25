import 'package:equatable/equatable.dart';

class PrayerSettings extends Equatable {
  final double latitude;
  final double longitude;
  final String? cityName;
  final String? countryName;
  final String calculationMethod;
  final Map<String, int> adjustments; // minutes to add/subtract for each prayer

  const PrayerSettings({
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.cityName,
    this.countryName,
    this.calculationMethod = 'muslim_world_league',
    this.adjustments = const {
      'fajr': 0,
      'sunrise': 0,
      'dhuhr': 0,
      'asr': 0,
      'maghrib': 0,
      'isha': 0,
    },
  });

  PrayerSettings copyWith({
    double? latitude,
    double? longitude,
    String? cityName,
    String? countryName,
    String? calculationMethod,
    Map<String, int>? adjustments,
  }) {
    return PrayerSettings(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      cityName: cityName ?? this.cityName,
      countryName: countryName ?? this.countryName,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      adjustments: adjustments ?? this.adjustments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'cityName': cityName,
      'countryName': countryName,
      'calculationMethod': calculationMethod,
      'adjustments': adjustments,
    };
  }

  factory PrayerSettings.fromJson(Map<String, dynamic> json) {
    return PrayerSettings(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      cityName: json['cityName'] as String?,
      countryName: json['countryName'] as String?,
      calculationMethod: json['calculationMethod'] as String? ?? 'muslim_world_league',
      adjustments: (json['adjustments'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as int),
          ) ??
          const {
            'fajr': 0,
            'sunrise': 0,
            'dhuhr': 0,
            'asr': 0,
            'maghrib': 0,
            'isha': 0,
          },
    );
  }

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        cityName,
        countryName,
        calculationMethod,
        adjustments,
      ];
}
