import 'package:flutter/material.dart';
import 'package:yesdhobi_ridervendor/models/rider_registration_model.dart';
import 'package:yesdhobi_ridervendor/screens/rider_dashboard_screen.dart';
import 'package:yesdhobi_ridervendor/services/rider_api_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

class RiderAuthService {
  static final RiderAuthService _instance = RiderAuthService._internal();
  static RiderAuthService get instance => _instance;

  RiderAuthService._internal() {
    _loadPersistedState();
  }

  RiderRegistrationModel _currentRegistration = RiderRegistrationModel();
  RiderOnboardingStatus _status = RiderOnboardingStatus.notStarted;
  bool _isLoggedIn = false;
  bool _isSelfieVerified = false;
  String? _selfieImagePath;
  bool _isOnline = true;

  RiderRegistrationModel get registrationModel => _currentRegistration;
  RiderOnboardingStatus get onboardingStatus => _status;
  bool get isLoggedIn => _isLoggedIn;
  bool get isSelfieVerified => _isSelfieVerified;
  String? get selfieImagePath => _selfieImagePath;
  bool get isOnline => _isOnline;

  Future<void> _loadPersistedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isSelfieVerified = prefs.getBool('rider_selfie_verified') ?? false;
      _selfieImagePath = prefs.getString('rider_selfie_image_path');
    } catch (_) {}
  }

  void setOnline(bool online) {
    _isOnline = online;
    RiderApiService.instance
        .setAvailability(online ? 'ONLINE' : 'OFFLINE')
        .catchError((e) {
      debugPrint('Sync rider availability error: $e');
      return <String, dynamic>{};
    });
  }

  void setSelfieVerified(bool verified, {String? imagePath}) async {
    _isSelfieVerified = verified;
    if (imagePath != null && imagePath.isNotEmpty) {
      _selfieImagePath = imagePath;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('rider_selfie_verified', verified);
      if (imagePath != null && imagePath.isNotEmpty) {
        await prefs.setString('rider_selfie_image_path', imagePath);
      }
    } catch (_) {}
  }

  void setOnboardingStatus(RiderOnboardingStatus status) {
    _status = status;
    _currentRegistration.status = status;
  }

  void setRegistrationModel(RiderRegistrationModel model) {
    _currentRegistration = model;
    _status = model.status;
  }

  void login({String? mobileNumber}) async {
    _isLoggedIn = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('rider_selfie_verified') == true) {
        _isSelfieVerified = true;
      }
      _selfieImagePath = prefs.getString('rider_selfie_image_path') ?? _selfieImagePath;
    } catch (_) {}

    // Known approved rider test account
    if (mobileNumber == '9999999999') {
      setOnboardingStatus(RiderOnboardingStatus.approved);
    }
  }

  void logout() async {
    _isLoggedIn = false;
    _isOnline = true;
    RiderApiService.instance.logout().catchError((e) {
      debugPrint('Rider logout error: $e');
    });
  }

  void updatePersonalDetails({
    required String fullName,
    required String mobileNumber,
    required String email,
    required String password,
    required DateTime dateOfBirth,
    required String profilePhotoPath,
    required int profilePhotoSize,
  }) {
    _currentRegistration.fullName = fullName;
    _currentRegistration.mobileNumber = mobileNumber;
    _currentRegistration.email = email;
    _currentRegistration.password = password;
    _currentRegistration.dateOfBirth = dateOfBirth;
    _currentRegistration.profilePhotoPath = profilePhotoPath;
    _currentRegistration.profilePhotoSize = profilePhotoSize;
    if (_status == RiderOnboardingStatus.notStarted) {
      setOnboardingStatus(RiderOnboardingStatus.personalDetailsCompleted);
    }
  }

  void updateVehicleDetails({
    required String vehicleType,
    required String vehicleNumber,
    required String drivingLicenseNumber,
    required String drivingLicensePhotoPath,
    required int drivingLicensePhotoSize,
  }) {
    _currentRegistration.vehicleType = vehicleType;
    _currentRegistration.vehicleNumber = vehicleNumber;
    _currentRegistration.drivingLicenseNumber = drivingLicenseNumber;
    _currentRegistration.drivingLicensePhotoPath = drivingLicensePhotoPath;
    _currentRegistration.drivingLicensePhotoSize = drivingLicensePhotoSize;
    if (_status == RiderOnboardingStatus.personalDetailsCompleted ||
        _status == RiderOnboardingStatus.notStarted) {
      setOnboardingStatus(RiderOnboardingStatus.vehicleDetailsCompleted);
    }
  }

  void submitDocumentsAndBank({
    required String aadhaarFrontPath,
    required int aadhaarFrontSize,
    required String aadhaarBackPath,
    required int aadhaarBackSize,
    required String panNumber,
    required String bankAccountNumber,
    required String ifscCode,
  }) {
    _currentRegistration.aadhaarFrontPath = aadhaarFrontPath;
    _currentRegistration.aadhaarFrontSize = aadhaarFrontSize;
    _currentRegistration.aadhaarBackPath = aadhaarBackPath;
    _currentRegistration.aadhaarBackSize = aadhaarBackSize;
    _currentRegistration.panNumber = panNumber;
    _currentRegistration.bankAccountNumber = bankAccountNumber;
    _currentRegistration.ifscCode = ifscCode;
    setOnboardingStatus(RiderOnboardingStatus.underReview);
  }

  /// Determines the screen for authenticated riders (always RiderDashboardScreen)
  Widget getNextScreenAfterLogin({String? mobileNumber}) {
    return const RiderDashboardScreen();
  }

  void resetForNewRider() {
    _currentRegistration = RiderRegistrationModel();
    _status = RiderOnboardingStatus.notStarted;
    _isLoggedIn = false;
  }
}
