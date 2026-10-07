import 'package:flutter/foundation.dart';
import 'package:yesdhobi_ridervendor/models/vendor_service_model.dart';
import 'package:yesdhobi_ridervendor/services/api_client.dart';

class VendorServicesService extends ChangeNotifier {
  static final VendorServicesService _instance =
      VendorServicesService._internal();
  static VendorServicesService get instance => _instance;

  VendorServicesService._internal() {
    _initDefaultServices();
  }

  final ApiClient _client = ApiClient.instance;
  final List<VendorServiceModel> _services = [];
  bool _isLoading = false;

  List<VendorServiceModel> get services => List.unmodifiable(_services);
  bool get isLoading => _isLoading;

  void _initDefaultServices() {
    _services.clear();
    _services.addAll([
      VendorServiceModel(
        id: 'wash_fold',
        serviceCategoryId: 1,
        name: 'Wash & Fold',
        isEnabled: true,
        price: 25.0,
        unit: 'kg',
      ),
      VendorServiceModel(
        id: 'wash_iron',
        serviceCategoryId: 2,
        name: 'Wash & Iron',
        isEnabled: true,
        price: 45.0,
        unit: 'kg',
      ),
      VendorServiceModel(
        id: 'dry_clean',
        serviceCategoryId: 3,
        name: 'Dry Clean',
        isEnabled: true,
        price: 180.0,
        unit: 'piece',
      ),
      VendorServiceModel(
        id: 'steam_press',
        serviceCategoryId: 4,
        name: 'Steam Press Only',
        isEnabled: false,
        price: 15.0,
        unit: 'piece',
      ),
    ]);
  }

  Future<void> fetchServices() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _client.get('/vendors/me/services');
      if (res['data'] is List) {
        final items = res['data'] as List;
        if (items.isNotEmpty) {
          _services.clear();
          for (final item in items) {
            if (item is Map<String, dynamic>) {
              _services.add(VendorServiceModel.fromApiJson(item));
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching vendor services: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleService(String id, bool enabled) async {
    final index = _services.indexWhere((s) => s.id == id);
    if (index == -1) return;

    final target = _services[index];
    target.isEnabled = enabled;
    notifyListeners();

    try {
      if (target.serviceCategoryId != null) {
        final res = await _client.post('/vendors/me/services', {
          'serviceCategoryId': target.serviceCategoryId,
          'price': target.price,
          'unit': target.unit,
          'isEnabled': enabled,
        });
        if (res['id'] != null) {
          _services[index] = target.copyWith(id: res['id'].toString());
        }
      } else if (!target.id.startsWith('cat_') && !target.id.startsWith('svc_')) {
        await _client.patch('/vendors/me/services/${target.id}', {
          'isEnabled': enabled,
        });
      } else {
        final res = await _client.post('/vendors/me/services', {
          'name': target.name,
          'price': target.price,
          'unit': target.unit,
          'isEnabled': enabled,
        });
        if (res['id'] != null) {
          _services[index] = target.copyWith(id: res['id'].toString());
        }
      }
    } catch (e) {
      debugPrint('Error updating service toggle on backend: $e');
    }
  }

  Future<void> updateServicePrice(String id, double newPrice) async {
    final index = _services.indexWhere((s) => s.id == id);
    if (index == -1) return;

    final target = _services[index];
    target.price = newPrice;
    notifyListeners();

    try {
      if (target.serviceCategoryId != null) {
        final res = await _client.post('/vendors/me/services', {
          'serviceCategoryId': target.serviceCategoryId,
          'price': newPrice,
          'unit': target.unit,
          'isEnabled': target.isEnabled,
        });
        if (res['id'] != null) {
          _services[index] = target.copyWith(id: res['id'].toString());
        }
      } else if (!target.id.startsWith('cat_') && !target.id.startsWith('svc_')) {
        await _client.patch('/vendors/me/services/${target.id}', {
          'price': newPrice,
        });
      } else {
        final res = await _client.post('/vendors/me/services', {
          'name': target.name,
          'price': newPrice,
          'unit': target.unit,
          'isEnabled': target.isEnabled,
        });
        if (res['id'] != null) {
          _services[index] = target.copyWith(id: res['id'].toString());
        }
      }
    } catch (e) {
      debugPrint('Error updating service price on backend: $e');
    }
  }

  Future<void> addCustomService({
    required String name,
    required double price,
    required String unit,
  }) async {
    try {
      final res = await _client.post('/vendors/me/services', {
        'name': name,
        'price': price,
        'unit': unit,
        'isEnabled': true,
      });

      if (res['id'] != null) {
        _services.add(VendorServiceModel.fromApiJson(res));
      } else {
        final newId = 'custom_${DateTime.now().millisecondsSinceEpoch}';
        _services.add(
          VendorServiceModel(
            id: newId,
            name: name,
            isEnabled: true,
            price: price,
            unit: unit,
            isCustom: true,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error creating custom service on backend: $e');
      final newId = 'custom_${DateTime.now().millisecondsSinceEpoch}';
      _services.add(
        VendorServiceModel(
          id: newId,
          name: name,
          isEnabled: true,
          price: price,
          unit: unit,
          isCustom: true,
        ),
      );
    }
    notifyListeners();
  }

  Future<void> deleteService(String id) async {
    final index = _services.indexWhere((s) => s.id == id);
    if (index == -1) return;

    final target = _services[index];
    _services.removeAt(index);
    notifyListeners();

    try {
      if (!target.id.startsWith('cat_') && !target.id.startsWith('svc_') && !target.id.startsWith('custom_')) {
        await _client.delete('/vendors/me/services/${target.id}');
      }
    } catch (e) {
      debugPrint('Error deleting service on backend: $e');
    }
  }

  void resetToDefaults() {
    _initDefaultServices();
    notifyListeners();
  }
}
