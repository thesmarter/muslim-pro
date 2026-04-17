import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:muslim/src/core/functions/print.dart';
import 'package:muslim/src/features/update/data/models/update_info_model.dart';

class UpdateRepo {
  final GetStorage _storage;
  static const String _updateKey = 'update_info_cache';
  static const String _lastCheckKey = 'last_update_check_time';
  
  // URL of your Vercel deployment
  static const String _baseUrl = 'https://muslimpro-landing.vercel.app';
  static const String _apiUrl = '$_baseUrl/api/update';
  static const String _logUrl = '$_baseUrl/api/log';

  UpdateRepo(this._storage);

  Future<UpdateInfo?> fetchUpdateInfo({bool forceRefresh = false}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastCheck = _storage.read<int>(_lastCheckKey) ?? 0;
    final cachedData = _storage.read(_updateKey);

    // إذا لم نطلب تحديثاً إجبارياً، وكان هناك كاش لم يمر عليه 12 ساعة، نستخدمه
    if (!forceRefresh && cachedData != null && (now - lastCheck) < 43200000) {
      return UpdateInfo.fromJson(Map<String, dynamic>.from(cachedData as Map));
    }

    try {
      final response = await http.get(Uri.parse(_apiUrl)).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body) as Map<String, dynamic>;
        final updateInfo = UpdateInfo.fromJson(data);
        
        // حفظ البيانات ووقت الفحص
        await _storage.write(_updateKey, data);
        await _storage.write(_lastCheckKey, now);
        
        logUpdateAction('check');
        return updateInfo;
      }
    } catch (e) {
      hisnPrint('Error fetching update info: $e');
    }

    // إذا فشل الاتصال، نستخدم الكاش الموجود مهما كان وقته
    if (cachedData != null) {
      return UpdateInfo.fromJson(Map<String, dynamic>.from(cachedData as Map));
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
