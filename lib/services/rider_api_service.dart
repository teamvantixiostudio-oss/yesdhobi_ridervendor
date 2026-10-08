import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class RiderApiService {
  static final RiderApiService instance = RiderApiService._internal();
  RiderApiService._internal();

  final ApiClient _client = ApiClient.instance;

  String _cleanPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    return digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
  }

  // ---- Auth & Onboarding ----

  Future<Map<String, dynamic>> riderLogin(String phone, String password) async {
    final tenDigits = _cleanPhone(phone);
    final res = await _client.post('/auth/rider/login', {
      'phone': tenDigits,
      'password': password,
    });

    if (res.containsKey('accessToken')) {
      await _client.setTokens(
        accessToken: res['accessToken'],
        refreshToken: res['refreshToken'],
        role: 'RIDER',
      );

      final prefs = await SharedPreferences.getInstance();
      if (res.containsKey('user')) {
        await prefs.setString('rider_user', jsonEncode(res['user']));
      }
      if (res.containsKey('rider')) {
        await prefs.setString('rider_profile', jsonEncode(res['rider']));
      }
    }
    return res;
  }

  Future<Map<String, dynamic>> riderRegister({
    required String fullName,
    required String mobileNumber,
    required String password,
    String? email,
    DateTime? dateOfBirth,
    int? zoneId,
  }) async {
    final tenDigits = _cleanPhone(mobileNumber);
    final body = {
      'fullName': fullName,
      'mobileNumber': tenDigits,
      'password': password,
      if (email != null && email.isNotEmpty) 'email': email,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth.toIso8601String(),
      if (zoneId != null) 'zoneId': zoneId,
    };

    final res = await _client.post('/auth/rider/register', body);
    if (res.containsKey('accessToken')) {
      await _client.setTokens(
        accessToken: res['accessToken'],
        refreshToken: res['refreshToken'],
        role: 'RIDER',
      );
      final prefs = await SharedPreferences.getInstance();
      if (res.containsKey('user')) {
        await prefs.setString('rider_user', jsonEncode(res['user']));
      }
      if (res.containsKey('rider')) {
        await prefs.setString('rider_profile', jsonEncode(res['rider']));
      }
    }
    return res;
  }

  Future<Map<String, dynamic>> updateVehicleDetails({
    required String vehicleType,
    required String vehicleNumber,
    required String drivingLicenseNumber,
    String? drivingLicensePhoto,
  }) async {
    return await _client.put('/riders/me/vehicle', {
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'drivingLicenseNumber': drivingLicenseNumber,
      if (drivingLicensePhoto != null) 'drivingLicensePhoto': drivingLicensePhoto,
    });
  }

  Future<Map<String, dynamic>> submitDocumentsAndBank({
    required String panNumber,
    required String bankAccountNumber,
    required String ifscCode,
    String? aadhaarNumber,
    String? aadhaarFront,
    String? aadhaarBack,
    String? profilePhoto,
    String? bankName,
  }) async {
    return await _client.put('/riders/me/documents', {
      'panNumber': panNumber,
      'bankAccountNumber': bankAccountNumber,
      'ifscCode': ifscCode,
      if (aadhaarNumber != null && aadhaarNumber.isNotEmpty) 'aadhaarNumber': aadhaarNumber,
      if (aadhaarFront != null) 'aadhaarFront': aadhaarFront,
      if (aadhaarBack != null) 'aadhaarBack': aadhaarBack,
      if (profilePhoto != null) 'profilePhoto': profilePhoto,
      if (bankName != null) 'bankName': bankName,
    });
  }

  Future<Map<String, dynamic>> uploadSelfie(String imageBase64) async {
    return await _client.post('/riders/me/selfie', {
      'image': imageBase64,
    });
  }

  Future<Map<String, dynamic>> getRiderProfile() async {
    return await _client.get('/riders/me');
  }

  Future<Map<String, dynamic>> getOnboardingStatus() async {
    return await _client.get('/riders/me/onboarding');
  }

  Future<Map<String, dynamic>> setAvailability(String availability) async {
    return await _client.post('/riders/me/availability', {
      'availability': availability.toUpperCase(),
    });
  }

  Future<void> updateLocation(double lat, double lng, {String? orderId}) async {
    try {
      await _client.post('/riders/me/location', {
        'lat': lat,
        'lng': lng,
        if (orderId != null) 'orderId': orderId,
      });
    } catch (_) {}
  }

  // ---- Requests & Orders ----

  Future<List<Map<String, dynamic>>> getRiderRequests() async {
    try {
      final res = await _client.get('/riders/me/requests');
      if (res.containsKey('data') && res['data'] is List) {
        return List<Map<String, dynamic>>.from(res['data']);
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> acceptRequest(String requestId) async {
    return await _client.post('/riders/me/requests/$requestId/accept', {});
  }

  Future<Map<String, dynamic>> declineRequest(String requestId) async {
    return await _client.post('/riders/me/requests/$requestId/decline', {});
  }

  Future<List<Map<String, dynamic>>> getRiderOrders({String status = 'active'}) async {
    try {
      final res = await _client.get('/riders/me/orders?status=$status');
      if (res.containsKey('data') && res['data'] is List) {
        return List<Map<String, dynamic>>.from(res['data']);
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> getRiderOrderDetails(String orderId) async {
    return await _client.get('/riders/me/orders/$orderId');
  }

  Future<Map<String, dynamic>> updateOrderWeight(
    String orderId,
    double weightKg, {
    int? itemsCount,
    String? note,
  }) async {
    return await _client.post('/riders/me/orders/$orderId/weigh', {
      'weightKg': weightKg,
      if (itemsCount != null) 'itemsCount': itemsCount,
      if (note != null) 'note': note,
    });
  }

  /// "Arrived at location". Records the moment the rider reaches the doorstep
  /// (or the shop) so the customer's tracking screen and the admin panel stop
  /// guessing. Safe to call twice - the server replies `alreadyMarked`.
  Future<Map<String, dynamic>> markArrived(String orderId) async {
    return await _client.post('/riders/me/orders/$orderId/arrived', {});
  }

  Future<Map<String, dynamic>> confirmPickup(String orderId, String otp) async {
    return await _client.post('/riders/me/orders/$orderId/confirm-pickup', {'otp': otp});
  }

  Future<Map<String, dynamic>> confirmDropoff(String orderId, String otp) async {
    return await _client.post('/riders/me/orders/$orderId/confirm-dropoff', {'otp': otp});
  }

  Future<Map<String, dynamic>> confirmHandover(String orderId, String otp) async {
    return await _client.post('/riders/me/orders/$orderId/confirm-handover', {'otp': otp});
  }

  Future<Map<String, dynamic>> confirmDelivery(String orderId, String otp, {bool collectedCash = true}) async {
    return await _client.post('/riders/me/orders/$orderId/confirm-delivery', {
      'otp': otp,
      'collectedCash': collectedCash,
    });
  }

  Future<Map<String, dynamic>> getRiderEarnings() async {
    return await _client.get('/riders/me/earnings');
  }

  Future<Map<String, dynamic>> requestPayout({double? amount}) async {
    return await _client.post('/riders/me/payouts', {
      if (amount != null) 'amount': amount,
    });
  }

  Future<void> logout() async {
    await _client.clearAuth('RIDER');
  }
}
