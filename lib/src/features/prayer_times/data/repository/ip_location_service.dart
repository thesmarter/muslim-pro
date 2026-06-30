import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:muslim/src/core/functions/print.dart';

class IPLocationResult {
  final double latitude;
  final double longitude;
  final String? city;
  final String? country;
  final String? countryCode;
  final String? timezone;

  const IPLocationResult({
    required this.latitude,
    required this.longitude,
    this.city,
    this.country,
    this.countryCode,
    this.timezone,
  });
}

class IPLocationService {
  static final IPLocationService _instance = IPLocationService._internal();
  factory IPLocationService() => _instance;
  IPLocationService._internal();

  /// Get location based on IP address using ipapi.co
  Future<IPLocationResult?> getLocationByIP() async {
    try {
      final response = await http.get(
        Uri.parse('https://ipapi.co/json/'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        hisnPrint("IP Location response: $data");

        final latitude = (data['latitude'] as num?)?.toDouble();
        final longitude = (data['longitude'] as num?)?.toDouble();

        if (latitude != null && longitude != null) {
          return IPLocationResult(
            latitude: latitude,
            longitude: longitude,
            city: data['city'] as String?,
            country: data['country_name'] as String?,
            countryCode: data['country_code'] as String?,
            timezone: data['timezone'] as String?,
          );
        }
      }
    } catch (e) {
      hisnPrint("Error getting IP location: $e");
    }

    // Fallback to ip-api.com
    return _fallbackIPGeolocation();
  }

  /// Fallback IP geolocation using ip-api.com
  Future<IPLocationResult?> _fallbackIPGeolocation() async {
    try {
      final response = await http.get(
        Uri.parse('http://ip-api.com/json/'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        hisnPrint("Fallback IP Location response: $data");

        final latitude = (data['lat'] as num?)?.toDouble();
        final longitude = (data['lon'] as num?)?.toDouble();

        if (latitude != null && longitude != null) {
          return IPLocationResult(
            latitude: latitude,
            longitude: longitude,
            city: data['city'] as String?,
            country: data['country'] as String?,
            countryCode: data['countryCode'] as String?,
            timezone: data['timezone'] as String?,
          );
        }
      }
    } catch (e) {
      hisnPrint("Error getting fallback IP location: $e");
    }

    return null;
  }
}
