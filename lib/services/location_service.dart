import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class RiderGeoAddress {
  final double latitude;
  final double longitude;
  final String area;
  final String city;
  final String pincode;
  final String formatted;
  final String? building;
  final String? street;

  RiderGeoAddress({
    required this.latitude,
    required this.longitude,
    required this.area,
    required this.city,
    required this.pincode,
    required this.formatted,
    this.building,
    this.street,
  });
}

class LocationService {
  static final LocationService instance = LocationService._();
  LocationService._();

  static const String awsApiKey =
      'v1.public.eyJqdGkiOiIzNDgzZTFjMC01N2ZjLTRkZTYtODM0OS0xYzE4ZTRiNTIwZDcifYygLYhkH3uJ1gQKmlS63fWlZqkzwuWBrKS09slqUhs-pQTyD6lY8hmpmVwlPi3WIInOUSs8oc7hGvd_NJwLf6SlKaBh1Ci7fHCtKVWlyGVCnQzg4gNF1oc-tWI_4UO2j9Ghu-TGuII60MboUZBMSCKijerOKdWx3Q05pVF8FrhND80Kjjxl80Ezd67P9sqvVLqyE3HvSc4bvT0AWwg7wo0NM0YB7YfnIoTxpR40Kl10Y4PquQ9BT1Nk1gGWfCAnEWdkqHGNEQqZdHzlewr6bQXyuLSzKfpdHINmUmY6vusKQ9YuDMVsar7EkPs-RszYKQz54G19scq83LHvBx2KfSc.Njg1MGZlZTUtYTI2ZS00MDdlLWJjNDktMDNmZDlkNzVmMjQ0';

  static const String awsRegion = 'ap-south-1';

  /// Get real-time device coordinates via Geolocator
  Future<Map<String, double>?> getDeviceCoordinates() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location service disabled
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return null;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return {'lat': pos.latitude, 'lng': pos.longitude};
    } catch (_) {
      return null;
    }
  }

  /// Reverse geocodes coordinates to a human-readable address via AWS Location Service
  Future<RiderGeoAddress?> reverseGeocode(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://places.geo.$awsRegion.amazonaws.com/v2/reverse-geocode?key=$awsApiKey',
      );
      final resp = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'QueryPosition': [lng, lat],
              'MaxResults': 1,
            }),
          )
          .timeout(const Duration(seconds: 7));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final items = data['ResultItems'] as List?;
        if (items != null && items.isNotEmpty) {
          final first = items[0] as Map<String, dynamic>;
          final addr = first['Address'] as Map<String, dynamic>? ?? {};

          final label = addr['Label']?.toString() ?? first['Title']?.toString() ?? '';
          final locality = addr['Locality']?.toString() ?? 'Hyderabad';
          final district = addr['District']?.toString() ?? '';
          final subdistrict = addr['SubDistrict']?.toString() ?? '';
          final street = addr['Street']?.toString() ?? '';
          final building = addr['Building']?.toString() ?? '';
          final postal = addr['PostalCode']?.toString() ?? '';

          final areaCandidate = [building, street, district, subdistrict]
              .where((s) => s.isNotEmpty)
              .join(', ');
          final area = areaCandidate.isNotEmpty ? areaCandidate : locality;

          return RiderGeoAddress(
            latitude: lat,
            longitude: lng,
            area: area,
            city: locality,
            pincode: postal,
            formatted: label.isNotEmpty ? label : '$area, $locality $postal',
            building: building.isNotEmpty ? building : null,
            street: street.isNotEmpty ? street : null,
          );
        }
      }
    } catch (_) {}
    return null;
  }

  /// Calculates real driving distance and duration between rider & stop via AWS Location Routes API
  Future<Map<String, dynamic>?> calculateRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      final url = Uri.parse(
        'https://routes.geo.$awsRegion.amazonaws.com/v2/routes?key=$awsApiKey',
      );
      final resp = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'Origin': [originLng, originLat],
              'Destination': [destLng, destLat],
            }),
          )
          .timeout(const Duration(seconds: 7));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final routes = data['Routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final summary = routes[0]['Summary'] as Map<String, dynamic>;
          final distMeters = (summary['Distance'] as num?)?.toDouble() ?? 0.0;
          final durationSec = (summary['Duration'] as num?)?.toInt() ?? 0;
          return {
            'distanceKm': (distMeters / 1000.0),
            'durationMinutes': (durationSec / 60.0).ceil(),
            'distanceMeters': distMeters,
            'durationSeconds': durationSec,
          };
        }
      }
    } catch (_) {}
    return null;
  }

  /// Generates a live AWS Static Map image URL centered at coordinates
  String getStaticMapUrl({
    required double lat,
    required double lng,
    int width = 600,
    int height = 300,
    int zoom = 15,
  }) {
    return 'https://maps.geo.$awsRegion.amazonaws.com/v2/static/map?key=$awsApiKey&center=$lng,$lat&zoom=$zoom&width=$width&height=$height';
  }
}
