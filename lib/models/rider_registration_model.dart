enum RiderOnboardingStatus {
  notStarted,
  personalDetailsCompleted,
  vehicleDetailsCompleted,
  documentsCompleted,
  underReview,
  approved,
}

class RiderRegistrationModel {
  RiderOnboardingStatus status;

  // Step 1: Personal Details
  String fullName;
  String mobileNumber;
  String email;
  String password;
  DateTime? dateOfBirth;
  String? profilePhotoPath;
  int? profilePhotoSize;

  // Step 2: Vehicle Details
  String vehicleType; // 'Motorcycle', 'Scooter', 'Bicycle'
  String vehicleNumber;
  String drivingLicenseNumber;
  String? drivingLicensePhotoPath;
  int? drivingLicensePhotoSize;

  // Step 3: Documents & Bank
  String? aadhaarFrontPath;
  int? aadhaarFrontSize;
  String? aadhaarBackPath;
  int? aadhaarBackSize;
  String panNumber;
  String bankAccountNumber;
  String ifscCode;

  RiderRegistrationModel({
    this.status = RiderOnboardingStatus.notStarted,
    this.fullName = '',
    this.mobileNumber = '',
    this.email = '',
    this.password = '',
    this.dateOfBirth,
    this.profilePhotoPath,
    this.profilePhotoSize,
    this.vehicleType = 'Motorcycle',
    this.vehicleNumber = '',
    this.drivingLicenseNumber = '',
    this.drivingLicensePhotoPath,
    this.drivingLicensePhotoSize,
    this.aadhaarFrontPath,
    this.aadhaarFrontSize,
    this.aadhaarBackPath,
    this.aadhaarBackSize,
    this.panNumber = '',
    this.bankAccountNumber = '',
    this.ifscCode = '',
  });

  String get formattedDob {
    if (dateOfBirth == null) return '';
    final day = dateOfBirth!.day.toString().padLeft(2, '0');
    final month = dateOfBirth!.month.toString().padLeft(2, '0');
    final year = dateOfBirth!.year.toString();
    return '$day/$month/$year';
  }
}
