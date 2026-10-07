import 'package:flutter_test/flutter_test.dart';
import 'package:yesdhobi_ridervendor/utils/registration_validators.dart';

void main() {
  group('RegistrationValidators Tests', () {
    test('Full Name validation', () {
      expect(RegistrationValidators.validateFullName('Ramesh Kumar'), isNull);
      expect(RegistrationValidators.validateFullName("John O'Connor"), isNull);
      expect(RegistrationValidators.validateFullName('Amit-Patel'), isNull);

      expect(RegistrationValidators.validateFullName(''), isNotNull);
      expect(RegistrationValidators.validateFullName('   '), isNotNull);
      expect(RegistrationValidators.validateFullName('Ramesh123'), isNotNull);
      expect(RegistrationValidators.validateFullName('@@@'), isNotNull);
      expect(RegistrationValidators.validateFullName('A'), isNotNull);
      expect(RegistrationValidators.validateFullName('Ramesh   Kumar'), isNotNull);
    });

    test('Mobile Number validation (10 Indian digits)', () {
      expect(RegistrationValidators.validateMobileNumber('9876543210'), isNull);
      expect(RegistrationValidators.validateMobileNumber('8123456789'), isNull);
      expect(RegistrationValidators.validateMobileNumber('7000000000'), isNull);
      expect(RegistrationValidators.validateMobileNumber('6222222222'), isNull);

      expect(RegistrationValidators.validateMobileNumber(''), isNotNull);
      expect(RegistrationValidators.validateMobileNumber('98765'), isNotNull);
      expect(RegistrationValidators.validateMobileNumber('1234567890'), isNotNull); // Doesn't start with 6-9
      expect(RegistrationValidators.validateMobileNumber('987654321012'), isNotNull);
      expect(RegistrationValidators.validateMobileNumber('abcdefghij'), isNotNull);
    });

    test('Email Address validation (Strictly @gmail.com)', () {
      expect(RegistrationValidators.validateEmail('ramesh@gmail.com'), isNull);
      expect(RegistrationValidators.validateEmail('rahul.sharma@gmail.com'), isNull);
      expect(RegistrationValidators.validateEmail('user_123@gmail.com'), isNull);

      expect(RegistrationValidators.validateEmail(''), isNotNull);
      expect(RegistrationValidators.validateEmail('ramesh'), isNotNull);
      expect(RegistrationValidators.validateEmail('ramesh@'), isNotNull);
      expect(RegistrationValidators.validateEmail('@gmail.com'), isNotNull);
      expect(RegistrationValidators.validateEmail('ramesh@gmail'), isNotNull);
      expect(RegistrationValidators.validateEmail('user@yahoo.com'), isNotNull);
      expect(RegistrationValidators.validateEmail('rahul@domain.co.in'), isNotNull);
    });

    test('Date of Birth (18+ requirement)', () {
      final now = DateTime.now();
      final eighteenYearsAgo = DateTime(now.year - 19, now.month, now.day);
      final twentyYearsAgo = DateTime(now.year - 20, 1, 1);
      final tenYearsAgo = DateTime(now.year - 10, now.month, now.day);
      final futureDate = DateTime(now.year + 1, 1, 1);

      expect(RegistrationValidators.validateDateOfBirth(eighteenYearsAgo), isNull);
      expect(RegistrationValidators.validateDateOfBirth(twentyYearsAgo), isNull);

      expect(RegistrationValidators.validateDateOfBirth(null), isNotNull);
      expect(RegistrationValidators.validateDateOfBirth(futureDate), isNotNull);
      expect(RegistrationValidators.validateDateOfBirth(tenYearsAgo), isNotNull);
    });

    test('Vehicle Number validation', () {
      expect(RegistrationValidators.validateVehicleNumber('MH02AA1234', 'Motorcycle'), isNull);
      expect(RegistrationValidators.validateVehicleNumber('MH 02 AA 1234', 'Motorcycle'), isNull);
      expect(RegistrationValidators.validateVehicleNumber('KA01MN1234', 'Scooter'), isNull);
      expect(RegistrationValidators.validateVehicleNumber('DL1CAB1234', 'Motorcycle'), isNull);
      expect(RegistrationValidators.validateVehicleNumber('', 'Bicycle'), isNull); // Optional for bicycle

      expect(RegistrationValidators.validateVehicleNumber('', 'Motorcycle'), isNotNull);
      expect(RegistrationValidators.validateVehicleNumber('123', 'Motorcycle'), isNotNull);
      expect(RegistrationValidators.validateVehicleNumber('ABC', 'Motorcycle'), isNotNull);
      expect(RegistrationValidators.validateVehicleNumber('123456789', 'Motorcycle'), isNotNull);
    });

    test('Driving License Number validation', () {
      expect(RegistrationValidators.validateDrivingLicenseNumber('DL-1420110012345', 'Motorcycle'), isNull);
      expect(RegistrationValidators.validateDrivingLicenseNumber('KA0120180001234', 'Motorcycle'), isNull);

      expect(RegistrationValidators.validateDrivingLicenseNumber('', 'Motorcycle'), isNotNull);
      expect(RegistrationValidators.validateDrivingLicenseNumber('123', 'Motorcycle'), isNotNull);
    });

    test('PAN Card Number validation (5 letters + 4 digits + 1 letter)', () {
      expect(RegistrationValidators.validatePanNumber('ABCDE1234F'), isNull);
      expect(RegistrationValidators.validatePanNumber('BNZPK1234A'), isNull);

      expect(RegistrationValidators.validatePanNumber(''), isNotNull);
      expect(RegistrationValidators.validatePanNumber('ABCDE123'), isNotNull);
      expect(RegistrationValidators.validatePanNumber('12345ABCDE'), isNotNull);
      expect(RegistrationValidators.validatePanNumber('ABCDE12345'), isNotNull);
    });

    test('Bank Account Number validation', () {
      expect(RegistrationValidators.validateBankAccountNumber('50100123456789'), isNull);
      expect(RegistrationValidators.validateBankAccountNumber('123456789012'), isNull);

      expect(RegistrationValidators.validateBankAccountNumber(''), isNotNull);
      expect(RegistrationValidators.validateBankAccountNumber('1234'), isNotNull);
      expect(RegistrationValidators.validateBankAccountNumber('ABC123456789'), isNotNull);
    });

    test('Bank IFSC Code validation', () {
      expect(RegistrationValidators.validateIfscCode('HDFC0000123'), isNull);
      expect(RegistrationValidators.validateIfscCode('SBIN0001234'), isNull);
      expect(RegistrationValidators.validateIfscCode('ICIC0001234'), isNull);

      expect(RegistrationValidators.validateIfscCode(''), isNotNull);
      expect(RegistrationValidators.validateIfscCode('HDFC123'), isNotNull);
      expect(RegistrationValidators.validateIfscCode('123456789'), isNotNull);
      expect(RegistrationValidators.validateIfscCode('HDFC@000123'), isNotNull);
    });

    test('Image size limit validation (<= 5MB)', () {
      expect(RegistrationValidators.validateProfilePhoto('/path/to/img.jpg', 1024 * 1024), isNull);
      expect(RegistrationValidators.validateProfilePhoto(null, null), isNotNull);
      expect(RegistrationValidators.validateProfilePhoto('/path/to/img.jpg', 6 * 1024 * 1024), isNotNull); // 6MB > 5MB
    });
  });
}
