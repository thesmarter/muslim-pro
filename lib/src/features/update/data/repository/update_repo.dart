import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:muslim/src/core/functions/print.dart';
import 'package:muslim/src/features/update/data/models/update_info_model.dart';

class UpdateRepo {
  // URL of your Vercel deployment
  static const String _baseUrl = 'https://muslimpro-landing.vercel.app';
  static const String _apiUrl = '$_baseUrl/api/update';
  static const String _logUrl = '$_baseUrl/api/log';

  Future<UpdateInfo?> fetchUpdateInfo() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl)).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body) as Map<String, dynamic>;
        final updateInfo = UpdateInfo.fromJson(data);
        
        logUpdateAction('check');
        return updateInfo;
      }
    } catch (e) {
      hisnPrint('Error fetching update info: $e');
    }

    return null;
  }

  Future<void> logUpdateAction(String action) async {
    try {
      await http.post(
        Uri.parse(_logUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'action': action}),
      ).timeout(const Duration(seconds: 3));
    } catch (e) {
      // Fail silently if offline, logging is secondary
      hisnPrint('Silent error logging action: $e');
    }
  }
}
