import 'package:equatable/equatable.dart';

class PrayerSettings extends Equatable {
  final double latitude;
  final double longitude;
  final String? cityName;
  final String? countryName;
  final String calculationMethod;
  final Map<String, int> adjustments; // minutes to add/subtract for each prayer
  final Map<String, bool> notifications; // whether notifications are enabled for each prayer
  final String muadhin; // selected muadhin ID
  final bool playAdhanSound; // whether to play adhan sound or default notification sound
  final double adhanVolume; // volume for adhan playback (0.0 to 1.0)
  final bool repeatAdhan; // whether to repeat adhan until stopped manually

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
    this.notifications = const {
      'fajr': true,
      'sunrise': true,
      'sunrise_end': true,
      'dhuhr': true,
      'asr': true,
      'maghrib': true,
      'isha': true,
    },
    this.muadhin = 'wadie_alyamani',
    this.playAdhanSound = true,
    this.adhanVolume = 0.5,
    this.repeatAdhan = false,
  });

  PrayerSettings copyWith({
    double? latitude,
    double? longitude,
    String? cityName,
    String? countryName,
    String? calculationMethod,
    Map<String, int>? adjustments,
    Map<String, bool>? notifications,
    String? muadhin,
    bool? playAdhanSound,
    double? adhanVolume,
    bool? repeatAdhan,
  }) {
    return PrayerSettings(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      cityName: cityName ?? this.cityName,
      countryName: countryName ?? this.countryName,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      adjustments: adjustments ?? this.adjustments,
      notifications: notifications ?? this.notifications,
      muadhin: muadhin ?? this.muadhin,
      playAdhanSound: playAdhanSound ?? this.playAdhanSound,
      adhanVolume: adhanVolume ?? this.adhanVolume,
      repeatAdhan: repeatAdhan ?? this.repeatAdhan,
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
      'notifications': notifications,
      'muadhin': muadhin,
      'playAdhanSound': playAdhanSound,
      'adhanVolume': adhanVolume,
      'repeatAdhan': repeatAdhan,
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
      notifications: (json['notifications'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as bool),
          ) ??
          const {
            'fajr': true,
            'sunrise': true,
            'sunrise_end': true,
            'dhuhr': true,
            'asr': true,
            'maghrib': true,
            'isha': true,
          },
      muadhin: json['muadhin'] as String? ?? 'wadie_alyamani',
      playAdhanSound: json['playAdhanSound'] as bool? ?? true,
      adhanVolume: (json['adhanVolume'] as num?)?.toDouble() ?? 0.5,
      repeatAdhan: json['repeatAdhan'] as bool? ?? false,
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
        notifications,
        muadhin,
        playAdhanSound,
        adhanVolume,
        repeatAdhan,
      ];
}
