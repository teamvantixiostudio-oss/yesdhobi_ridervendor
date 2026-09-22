import 'package:flutter/material.dart';
import 'package:yesdhobi_ridervendor/models/rider_registration_model.dart';
import 'package:yesdhobi_ridervendor/screens/rider_dashboard_screen.dart';

class RiderAuthService {
  static final RiderAuthService _instance = RiderAuthService._internal();
  static RiderAuthService get instance => _instance;

  RiderAuthService._internal();

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

  void setOnline(bool online) {
    _isOnline = online;
  }

  void setSelfieVerified(bool verified, {String? imagePath}) {
    _isSelfieVerified = verified;
    if (imagePath != null) {
      _selfieImagePath = imagePath;
    }
  }

  void setOnboardingStatus(RiderOnboardingStatus status) {
    _status = status;
    _currentRegistration.status = status;
  }

  void setRegistrationModel(RiderRegistrationModel model) {
    _currentRegistration = model;
    _status = model.status;
  }

  void login({String? mobileNumber}) {
    _isLoggedIn = true;
    // Known approved rider test account
    if (mobileNumber == '9999999999') {
      setOnboardingStatus(RiderOnboardingStatus.approved);
    }
  }

  void logout() {
    _isLoggedIn = false;
    _isSelfieVerified = false;
    _selfieImagePath = null;
    _isOnline = true;
  }

  void updatePersonalDetails({
    required String fullName,
    required String mobileNumber,
    required String email,
    required DateTime dateOfBirth,
    required String profilePhotoPath,
    required int profilePhotoSize,
  }) {
    _currentRegistration.fullName = fullName;
    _currentRegistration.mobileNumber = mobileNumber;
    _currentRegistration.email = email;
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
