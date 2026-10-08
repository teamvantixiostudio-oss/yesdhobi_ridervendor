import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yesdhobi_ridervendor/models/vendor_order_model.dart';
import 'api_client.dart';

class VendorOrderService {
  static final VendorOrderService instance = VendorOrderService._internal();

  VendorOrderService._internal();

  final ApiClient _client = ApiClient.instance;

  final List<VendorOrderModel> _orders = [];
  final List<VendorOrderModel> _newRequests = [];
  final ValueNotifier<VendorOrderModel?> activeOtpOrder = ValueNotifier<VendorOrderModel?>(null);
  final ValueNotifier<int> orderUpdateNotifier = ValueNotifier<int>(0);

  /// Set when an order the shop has not seen before turns up in the "new"
  /// tab, so the UI can put it in front of them. Cleared once shown.
  final ValueNotifier<VendorOrderModel?> incomingRequest = ValueNotifier<VendorOrderModel?>(null);

  Timer? _pollTimer;
  final Set<String> _seenRequestIds = <String>{};
  bool _firstFetchDone = false;

  String _shopName = 'Star Bright Laundry';
  String _vendorDisplayId = '#V-8947';
  double _todayRevenue = 0.0;
  bool _isLoading = false;

  String _shopAddress = '';
  String _city = '';
  String _pincode = '';
  double? _latitude;
  double? _longitude;
  String _vendorPhone = '';
  String _ownerName = '';

  List<VendorOrderModel> get orders => List.unmodifiable(_orders);
  List<VendorOrderModel> get newRequests => List.unmodifiable(_newRequests);
  double get todayRevenue => _todayRevenue;
  bool get isLoading => _isLoading;
  String get shopName => _shopName;
  String get vendorDisplayId => _vendorDisplayId;
  String get shopAddress => _shopAddress;
  String get city => _city;
  String get pincode => _pincode;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  String get vendorPhone => _vendorPhone;
  String get ownerName => _ownerName;

  String _cleanPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    return digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
  }

  void _applyVendorData(Map<String, dynamic>? vendor) {
    if (vendor == null) return;
    final name = vendor['shopName']?.toString() ?? vendor['name']?.toString();
    if (name != null && name.isNotEmpty) {
      _shopName = name;
    }
    final vid = vendor['id']?.toString() ?? '';
    if (vid.isNotEmpty) {
      _vendorDisplayId = vid.length > 6 ? '#V-${vid.substring(0, 6)}' : '#V-$vid';
    }
    if (vendor['shopAddress'] != null) _shopAddress = vendor['shopAddress'].toString();
    if (vendor['city'] != null) _city = vendor['city'].toString();
    if (vendor['pincode'] != null) _pincode = vendor['pincode'].toString();
    if (vendor['latitude'] != null) _latitude = (vendor['latitude'] as num).toDouble();
    if (vendor['longitude'] != null) _longitude = (vendor['longitude'] as num).toDouble();
    if (vendor['phone'] != null) _vendorPhone = vendor['phone'].toString();
    if (vendor['ownerName'] != null) _ownerName = vendor['ownerName'].toString();
  }

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('vendor_profile');
      if (cached != null) {
        final decoded = jsonDecode(cached);
        if (decoded is Map<String, dynamic>) {
          _applyVendorData(decoded);
        }
      }
    } catch (_) {}
  }

  // ---- Auth ----

  /// Partners sign in with the Registration ID issued at onboarding
  /// (VD100008) or with their registered mobile number. The server takes one
  /// or the other - never both - so pick based on what was typed.
  static bool looksLikeRegistrationId(String value) =>
      RegExp(r'^VD\d{4,}$', caseSensitive: false).hasMatch(value.trim());

  Future<Map<String, dynamic>> vendorLogin(String identifier, String password) async {
    final trimmed = identifier.trim();
    final body = looksLikeRegistrationId(trimmed)
        ? {'registrationId': trimmed.toUpperCase(), 'password': password}
        : {'phone': _cleanPhone(trimmed), 'password': password};
    final res = await _client.post('/auth/vendor/login', body);

    if (res.containsKey('accessToken')) {
      await _client.setTokens(
        accessToken: res['accessToken'],
        refreshToken: res['refreshToken'],
        role: 'VENDOR',
      );

      final prefs = await SharedPreferences.getInstance();
      if (res.containsKey('user')) {
        await prefs.setString('vendor_user', jsonEncode(res['user']));
      }
      if (res.containsKey('vendor')) {
        final vendor = res['vendor'] as Map<String, dynamic>;
        await prefs.setString('vendor_profile', jsonEncode(vendor));
        _applyVendorData(vendor);
      }
    }
    return res;
  }

  Future<Map<String, dynamic>> getVendorProfile() async {
    final res = await _client.get('/vendors/me');
    if (res['vendor'] != null && res['vendor'] is Map<String, dynamic>) {
      _applyVendorData(res['vendor'] as Map<String, dynamic>);
    } else if (res['data'] != null && res['data'] is Map<String, dynamic>) {
      _applyVendorData(res['data'] as Map<String, dynamic>);
    }
    return res;
  }

  Future<void> updateShopGpsLocation(double lat, double lng, {String? address}) async {
    final updateData = <String, dynamic>{
      'latitude': lat,
      'longitude': lng,
    };
    if (address != null && address.isNotEmpty) {
      updateData['shopAddress'] = address;
    }
    final res = await _client.patch('/vendors/me', updateData);
    if (res['vendor'] != null && res['vendor'] is Map<String, dynamic>) {
      _applyVendorData(res['vendor'] as Map<String, dynamic>);
    } else if (res['data'] != null && res['data'] is Map<String, dynamic>) {
      _applyVendorData(res['data'] as Map<String, dynamic>);
    }
  }

  // ---- Orders ----

  /// Keep the shop's queue current while they are signed in.
  ///
  /// The server offers an order to one partner at a time, for 90 seconds, as
  /// soon as a rider accepts the pickup. Nothing was watching for that: the
  /// list was only loaded when the screen opened or the shop pulled to
  /// refresh, so an offer could come and expire without anyone noticing.
  void startPolling({Duration every = const Duration(seconds: 3)}) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(every, (_) => fetchOrders());
    fetchOrders();
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Newly arrived offers, ignoring the ones already on screen. The very first
  /// fetch after signing in only primes the set - we do not want to pop a
  /// dialog for every order that was already waiting.
  void _flagNewArrivals() {
    final current = <String>{};
    VendorOrderModel? arrival;
    for (final r in _newRequests) {
      final key = r.rawId ?? r.orderId;
      current.add(key);
      if (_firstFetchDone && !_seenRequestIds.contains(key)) arrival ??= r;
    }
    _seenRequestIds
      ..clear()
      ..addAll(current);
    _firstFetchDone = true;
    if (arrival != null) incomingRequest.value = arrival;
  }

  Future<void> fetchOrders() async {
    _isLoading = true;
    try {
      // Fetch new/incoming requests
      final newRes = await _client.get('/vendors/me/orders?tab=new');
      final newItems = (newRes['data'] is List) ? (newRes['data'] as List) : [];
      _newRequests.clear();
      for (final it in newItems) {
        if (it is Map<String, dynamic>) {
          _newRequests.add(VendorOrderModel.fromApiJson(it));
        }
      }

      _flagNewArrivals();

      // Fetch active/in-progress orders
      final activeRes = await _client.get('/vendors/me/orders?tab=active');
      final activeItems = (activeRes['data'] is List) ? (activeRes['data'] as List) : [];
      _orders.clear();
      for (final it in activeItems) {
        if (it is Map<String, dynamic>) {
          _orders.add(VendorOrderModel.fromApiJson(it));
        }
      }

      // Fetch today's earnings
      try {
        final earnings = await _client.get('/vendors/me/earnings');
        if (earnings['today'] != null && earnings['today']['amount'] != null) {
          _todayRevenue = (earnings['today']['amount'] as num).toDouble();
        }
      } catch (_) {}

      // Auto-set active OTP order for banner if not already set or completed
      if (activeOtpOrder.value == null || activeOtpOrder.value!.isCompleted) {
        try {
          final withOtp = _orders.firstWhere(
            (o) => !o.isCompleted && (o.dropoffOtp.isNotEmpty || o.handoverOtp.isNotEmpty),
          );
          activeOtpOrder.value = withOtp;
        } catch (_) {
          if (_orders.isNotEmpty && !_orders.first.isCompleted) {
            activeOtpOrder.value = _orders.first;
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching vendor orders: $e');
    } finally {
      _isLoading = false;
      orderUpdateNotifier.value++;
    }
  }

  VendorOrderModel? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((o) => o.orderId == orderId || o.rawId == orderId);
    } catch (_) {
      try {
        return _newRequests.firstWhere((o) => o.orderId == orderId || o.rawId == orderId);
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> acceptNewRequest(VendorOrderModel order) async {
    final targetId = (order.rawId != null && order.rawId!.isNotEmpty)
        ? order.rawId!
        : order.orderId.replaceFirst('#', '');
    try {
      await _client.post('/vendors/me/orders/$targetId/accept', {});
    } catch (e) {
      debugPrint('Error accepting order on backend: $e');
      rethrow;
    }
    _newRequests.removeWhere((o) => o.orderId == order.orderId);
    if (!_orders.any((o) => o.orderId == order.orderId)) {
      _orders.insert(0, order);
    }
    orderUpdateNotifier.value++;
    await fetchOrders();
  }

  Future<void> rejectNewRequest(String orderId, {String? reason}) async {
    final order = getOrderById(orderId);
    final targetId = (order?.rawId != null && order!.rawId!.isNotEmpty)
        ? order.rawId!
        : orderId.replaceFirst('#', '');
    try {
      await _client.post('/vendors/me/orders/$targetId/reject', {
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });
    } catch (e) {
      debugPrint('Error rejecting order on backend: $e');
      rethrow;
    }
    _newRequests.removeWhere((o) => o.orderId == orderId || o.rawId == targetId);
    orderUpdateNotifier.value++;
    await fetchOrders();
  }

  Future<VendorOrderModel> markAsPackagedAndAssignRider(VendorOrderModel order) async {
    VendorOrderModel target = getOrderById(order.orderId) ?? order;
    final targetId = (target.rawId != null && target.rawId!.isNotEmpty)
        ? target.rawId!
        : target.orderId.replaceFirst('#', '');

    try {
      // Transition to READY and broadcast delivery request to riders
      await _client.post('/vendors/me/orders/$targetId/book-rider', {});
    } catch (e) {
      debugPrint('Error booking rider on backend: $e');
    }

    if (!_orders.contains(target)) {
      _orders.insert(0, target);
    }
    _newRequests.removeWhere((o) => o.orderId == target.orderId);

    target.isPackaged = true;
    target.isRiderBooked = true;
    target.assignedRiderName = target.assignedRiderName ?? 'Assigned Partner';

    activeOtpOrder.value = target;
    orderUpdateNotifier.value++;
    await fetchOrders();
    return target;
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    final order = getOrderById(orderId);
    final targetId = (order?.rawId != null && order!.rawId!.isNotEmpty)
        ? order.rawId!
        : orderId.replaceFirst('#', '');
    await _client.post('/vendors/me/orders/$targetId/status', {'status': status});
    await fetchOrders();
  }

  void verifyOtpAndCompleteOrder(String orderId) {
    final order = getOrderById(orderId);
    if (order != null) {
      order.isPackaged = true;
      order.isRiderBooked = true;
      order.isCompleted = true;
    }

    if (activeOtpOrder.value?.orderId == orderId) {
      activeOtpOrder.value = null;
    }
    orderUpdateNotifier.value++;
  }

  int get newRequestsCount => _newRequests.length;
  int get inProgressCount => _orders.where((o) => !o.isPackaged && !o.isCompleted).length;
  int get readyCount => _orders.where((o) => o.isPackaged && !o.isRiderBooked && !o.isCompleted).length;
  int get outForDeliveryCount => _orders.where((o) => o.isRiderBooked && !o.isCompleted).length;
  int get completedCount => _orders.where((o) => o.isCompleted).length;

  Future<Map<String, dynamic>> getEarnings() async {
    final res = await _client.get('/vendors/me/earnings');
    return res;
  }

  Future<Map<String, dynamic>> requestPayout({double? amount}) async {
    return await _client.post('/vendors/me/payouts', {
      if (amount != null) 'amount': amount,
    });
  }

  Future<void> logout() async {
    stopPolling();
    await _client.clearAuth('VENDOR');
    _orders.clear();
    _newRequests.clear();
    activeOtpOrder.value = null;
    orderUpdateNotifier.value++;
  }

  void reset() {
    stopPolling();
    _seenRequestIds.clear();
    _firstFetchDone = false;
    incomingRequest.value = null;
    activeOtpOrder.value = null;
    orderUpdateNotifier.value = 0;
  }
}
