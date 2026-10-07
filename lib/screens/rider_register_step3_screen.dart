import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yesdhobi_ridervendor/theme.dart';
import 'package:yesdhobi_ridervendor/widgets/app_logo.dart';
import 'package:yesdhobi_ridervendor/widgets/custom_text_field.dart';
import 'package:yesdhobi_ridervendor/widgets/custom_back_button.dart';
import 'package:yesdhobi_ridervendor/widgets/step_progress_bar.dart';
import 'package:yesdhobi_ridervendor/widgets/dashed_border_painter.dart';
import 'package:yesdhobi_ridervendor/models/rider_registration_model.dart';
import 'package:yesdhobi_ridervendor/utils/registration_validators.dart';
import 'package:yesdhobi_ridervendor/utils/image_picker_helper.dart';
import 'package:yesdhobi_ridervendor/screens/application_review_screen.dart';
import 'package:yesdhobi_ridervendor/services/rider_auth_service.dart';
import 'package:yesdhobi_ridervendor/services/rider_api_service.dart';

class RiderRegisterStep3Screen extends StatefulWidget {
  final RiderRegistrationModel? registrationModel;

  const RiderRegisterStep3Screen({
    super.key,
    this.registrationModel,
  });

  @override
  State<RiderRegisterStep3Screen> createState() =>
      _RiderRegisterStep3ScreenState();
}

class _RiderRegisterStep3ScreenState extends State<RiderRegisterStep3Screen> {
  late RiderRegistrationModel _model;
  bool _isSubmitting = false;

  late TextEditingController _panController;
  late TextEditingController _bankAccountController;
  late TextEditingController _ifscController;

  String? _aadhaarFrontError;
  String? _aadhaarBackError;
  String? _panError;
  String? _bankAccountError;
  String? _ifscError;

  @override
  void initState() {
    super.initState();
    _model = widget.registrationModel ?? RiderAuthService.instance.registrationModel;

    _panController = TextEditingController(text: _model.panNumber);
    _bankAccountController =
        TextEditingController(text: _model.bankAccountNumber);
    _ifscController = TextEditingController(text: _model.ifscCode);
  }

  @override
  void dispose() {
    _panController.dispose();
    _bankAccountController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  Future<void> _pickAadhaarFront() async {
    final result = await ImagePickerHelper.showSourceSelector(
      context,
      title: 'Upload Aadhaar Card Front',
    );

    if (result != null && result.isSuccess && result.path != null) {
      setState(() {
        _model.aadhaarFrontPath = result.path;
        _model.aadhaarFrontSize = result.sizeInBytes;
        _aadhaarFrontError = null;
      });
    } else if (result != null &&
        result.errorMessage != null &&
        result.errorMessage != 'No photo captured' &&
        result.errorMessage != 'No image selected') {
      if (!mounted) return;
      setState(() {
        _aadhaarFrontError = result.errorMessage;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage!),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickAadhaarBack() async {
    final result = await ImagePickerHelper.showSourceSelector(
      context,
      title: 'Upload Aadhaar Card Back',
    );

    if (result != null && result.isSuccess && result.path != null) {
      setState(() {
        _model.aadhaarBackPath = result.path;
        _model.aadhaarBackSize = result.sizeInBytes;
        _aadhaarBackError = null;
      });
    } else if (result != null &&
        result.errorMessage != null &&
        result.errorMessage != 'No photo captured' &&
        result.errorMessage != 'No image selected') {
      if (!mounted) return;
      setState(() {
        _aadhaarBackError = result.errorMessage;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage!),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _submitProfile() async {
    final panVal = _panController.text.trim().toUpperCase();
    final bankVal = _bankAccountController.text.trim();
    final ifscVal = _ifscController.text.trim().toUpperCase();

    final frontErr = RegistrationValidators.validateAadhaarFront(
      _model.aadhaarFrontPath,
      _model.aadhaarFrontSize,
    );
    final backErr = RegistrationValidators.validateAadhaarBack(
      _model.aadhaarBackPath,
      _model.aadhaarBackSize,
    );
    final panErr = RegistrationValidators.validatePanNumber(panVal);
    final bankErr = RegistrationValidators.validateBankAccountNumber(bankVal);
    final ifscErr = RegistrationValidators.validateIfscCode(ifscVal);

    setState(() {
      _aadhaarFrontError = frontErr;
      _aadhaarBackError = backErr;
      _panError = panErr;
      _bankAccountError = bankErr;
      _ifscError = ifscErr;
    });

    if (frontErr == null &&
        backErr == null &&
        panErr == null &&
        bankErr == null &&
        ifscErr == null) {
      _model.panNumber = panVal;
      _model.bankAccountNumber = bankVal;
      _model.ifscCode = ifscVal;

      setState(() => _isSubmitting = true);

      final regPassword = _model.password.isNotEmpty
          ? _model.password
          : (RiderAuthService.instance.registrationModel.password.isNotEmpty
              ? RiderAuthService.instance.registrationModel.password
              : 'Partner@123');

      try {
        await RiderApiService.instance.riderRegister(
          fullName: _model.fullName,
          mobileNumber: _model.mobileNumber,
          password: regPassword,
          email: _model.email.isNotEmpty ? _model.email : null,
          dateOfBirth: _model.dateOfBirth,
        );

        if (_model.vehicleNumber.isNotEmpty && _model.drivingLicenseNumber.isNotEmpty) {
          await RiderApiService.instance.updateVehicleDetails(
            vehicleType: _model.vehicleType,
            vehicleNumber: _model.vehicleNumber,
            drivingLicenseNumber: _model.drivingLicenseNumber,
          );
        }

        await RiderApiService.instance.submitDocumentsAndBank(
          panNumber: panVal,
          bankAccountNumber: bankVal,
          ifscCode: ifscVal,
        );
      } catch (e) {
        debugPrint('Rider backend onboarding note: $e');
        final err = e.toString().replaceAll('Exception:', '').trim();
        if (!err.toLowerCase().contains('already exists')) {
          if (!mounted) return;
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(err.isNotEmpty ? err : 'Registration failed. Please check your details.'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          return;
        }
      }

      RiderAuthService.instance.submitDocumentsAndBank(
        aadhaarFrontPath: _model.aadhaarFrontPath!,
        aadhaarFrontSize: _model.aadhaarFrontSize ?? 0,
        aadhaarBackPath: _model.aadhaarBackPath!,
        aadhaarBackSize: _model.aadhaarBackSize ?? 0,
        panNumber: panVal,
        bankAccountNumber: bankVal,
        ifscCode: ifscVal,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const ApplicationReviewScreen(isVendor: false),
        ),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please complete all verification and bank details.'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const CustomBackButton(),
        title: const YesDhobiLogo(
          height: 28,
          variant: LogoVariant.navy,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Documents & Bank',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Step 3: Verification documents and payout bank account details',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Step Progress Bar (100%)
              const StepProgressBar(
                step: 3,
                progress: 1.0,
                percentageText: '100% Complete',
              ),
              const SizedBox(height: 28),

              // Aadhaar Card Verification Section
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Aadhaar Card Verification',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                      fontFamily: 'Manrope',
                    ),
                  ),
                  Text(
                    ' *',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _buildAadhaarCard(
                      label: 'Front Photo',
                      imagePath: _model.aadhaarFrontPath,
                      hasError: _aadhaarFrontError != null,
                      onTap: _pickAadhaarFront,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildAadhaarCard(
                      label: 'Back Photo',
                      imagePath: _model.aadhaarBackPath,
                      hasError: _aadhaarBackError != null,
                      onTap: _pickAadhaarBack,
                    ),
                  ),
                ],
              ),

              if (_aadhaarFrontError != null || _aadhaarBackError != null) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Text(
                    _aadhaarFrontError ?? _aadhaarBackError!,
                    style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // PAN Card Number Field
              CustomTextField(
                label: 'PAN Card Number',
                hint: 'ABCDE1234F',
                controller: _panController,
                errorText: _panError,
                textCapitalization: TextCapitalization.characters,
                maxLength: 10,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(10),
                ],
                onChanged: (val) {
                  if (_panError != null || val.length == 10) {
                    setState(() {
                      _panError = RegistrationValidators.validatePanNumber(val);
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // Bank Account Number Field
              CustomTextField(
                label: 'Bank Account Number',
                hint: '50100123456789',
                controller: _bankAccountController,
                errorText: _bankAccountError,
                keyboardType: TextInputType.number,
                maxLength: 18,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(18),
                ],
                onChanged: (val) {
                  if (_bankAccountError != null) {
                    setState(() {
                      _bankAccountError =
                          RegistrationValidators.validateBankAccountNumber(val);
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // Bank IFSC Code Field
              CustomTextField(
                label: 'Bank IFSC Code',
                hint: 'HDFC0000123',
                controller: _ifscController,
                errorText: _ifscError,
                textCapitalization: TextCapitalization.characters,
                maxLength: 11,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(11),
                ],
                onChanged: (val) {
                  if (_ifscError != null || val.length == 11) {
                    setState(() {
                      _ifscError = RegistrationValidators.validateIfscCode(val);
                    });
                  }
                },
              ),

              const SizedBox(height: 36),

              // Submit Profile Button (Yellow Button)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    foregroundColor: const Color(0xFF1E293B),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF1E293B),
                          ),
                        )
                      : const Text(
                          'Submit Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAadhaarCard({
    required String label,
    required String? imagePath,
    required bool hasError,
    required VoidCallback onTap,
  }) {
    final bool isUploaded = imagePath != null;

    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: hasError
              ? const Color(0xFFEF4444)
              : (isUploaded ? const Color(0xFF10B981) : const Color(0xFFCBD5E1)),
          borderRadius: 12,
          dashWidth: 6,
          dashSpace: 4,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
          decoration: BoxDecoration(
            color: isUploaded ? const Color(0xFFF0FDF4) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isUploaded) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(imagePath),
                    height: 48,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) {
                      return const Icon(
                        Icons.check_circle,
                        color: Color(0xFF10B981),
                        size: 28,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle,
                        color: Color(0xFF10B981), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const Icon(
                  Icons.description_outlined,
                  color: Color(0xFF64748B),
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
