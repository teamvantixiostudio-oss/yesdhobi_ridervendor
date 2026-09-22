import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class RiderApiService {
  static final RiderApiService instance = RiderApiService._internal();
  RiderApiService._internal();

  final ApiClient _client = ApiClient.instance;

  Future<Map<String, dynamic>> riderLogin(String phone, String password) async {
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    final tenDigits = cleaned.length >= 10 ? cleaned.substring(cleaned.length - 10) : cleaned;

    final res = await _client.post('/auth/rider/login', {
      'phone': tenDigits,
      'password': password,
    });

    if (res.containsKey('accessToken')) {
      await _client.setTokens(
        accessToken: res['accessToken'],
        refreshToken: res['refreshToken'],
      );

      final prefs = await SharedPreferences.getInstance();
      if (res.containsKey('user')) {
        await prefs.setString('rider_user', jsonEncode(res['user']));
      }
    }
    return res;
  }

  Future<Map<String, dynamic>> vendorLogin(String phone, String password) async {
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    final tenDigits = cleaned.length >= 10 ? cleaned.substring(cleaned.length - 10) : cleaned;

    final res = await _client.post('/auth/vendor/login', {
      'phone': tenDigits,
      'password': password,
    });

    if (res.containsKey('accessToken')) {
      await _client.setTokens(
        accessToken: res['accessToken'],
        refreshToken: res['refreshToken'],
      );
    }
    return res;
  }

  Future<Map<String, dynamic>> getRiderDashboard() async {
    return await _client.get('/riders/me/dashboard');
  }

  Future<Map<String, dynamic>> getVendorDashboard() async {
    return await _client.get('/vendors/me/dashboard');
  }

  Future<List<Map<String, dynamic>>> getRiderRequests() async {
    final res = await _client.get('/riders/me/requests');
    if (res.containsKey('data') && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }
    return [];
  }

  Future<Map<String, dynamic>> acceptRequest(String requestId) async {
    return await _client.post('/riders/me/requests/$requestId/accept', {});
  }

  Future<Map<String, dynamic>> setAvailability(String availability) async {
    return await _client.post('/riders/me/availability', {'availability': availability});
  }
}
