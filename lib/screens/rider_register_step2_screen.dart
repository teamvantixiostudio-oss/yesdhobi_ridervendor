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
import 'package:yesdhobi_ridervendor/screens/rider_register_step3_screen.dart';
import 'package:yesdhobi_ridervendor/services/rider_auth_service.dart';

class RiderRegisterStep2Screen extends StatefulWidget {
  final RiderRegistrationModel? registrationModel;

  const RiderRegisterStep2Screen({
    super.key,
    this.registrationModel,
  });

  @override
  State<RiderRegisterStep2Screen> createState() =>
      _RiderRegisterStep2ScreenState();
}

class _RiderRegisterStep2ScreenState extends State<RiderRegisterStep2Screen> {
  late RiderRegistrationModel _model;
  late TextEditingController _vehicleNumberController;
  late TextEditingController _dlNumberController;

  String? _vehicleNumberError;
  String? _dlNumberError;
  String? _dlPhotoError;

  @override
  void initState() {
    super.initState();
    _model = widget.registrationModel ?? RiderAuthService.instance.registrationModel;

    _vehicleNumberController =
        TextEditingController(text: _model.vehicleNumber);
    _dlNumberController =
        TextEditingController(text: _model.drivingLicenseNumber);
  }

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _dlNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickDrivingLicensePhoto() async {
    final result = await ImagePickerHelper.showSourceSelector(
      context,
      title: 'Upload Driving License Front',
    );

    if (result != null && result.isSuccess && result.path != null) {
      setState(() {
        _model.drivingLicensePhotoPath = result.path;
        _model.drivingLicensePhotoSize = result.sizeInBytes;
        _dlPhotoError = null;
      });
    } else if (result != null &&
        result.errorMessage != null &&
        result.errorMessage != 'No photo captured' &&
        result.errorMessage != 'No image selected') {
      if (!mounted) return;
      setState(() {
        _dlPhotoError = result.errorMessage;
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

  void _proceedToStep3() {
    final vehicleNumVal = _vehicleNumberController.text.trim().toUpperCase();
    final dlNumVal = _dlNumberController.text.trim().toUpperCase();

    final vehicleErr = RegistrationValidators.validateVehicleNumber(
      vehicleNumVal,
      _model.vehicleType,
    );
    final dlErr = RegistrationValidators.validateDrivingLicenseNumber(
      dlNumVal,
      _model.vehicleType,
    );
    final photoErr = RegistrationValidators.validateDrivingLicensePhoto(
      _model.drivingLicensePhotoPath,
      _model.drivingLicensePhotoSize,
    );

    setState(() {
      _vehicleNumberError = vehicleErr;
      _dlNumberError = dlErr;
      _dlPhotoError = photoErr;
    });

    if (vehicleErr == null && dlErr == null && photoErr == null) {
      _model.vehicleNumber = vehicleNumVal;
      _model.drivingLicenseNumber = dlNumVal;

      RiderAuthService.instance.updateVehicleDetails(
        vehicleType: _model.vehicleType,
        vehicleNumber: vehicleNumVal,
        drivingLicenseNumber: dlNumVal,
        drivingLicensePhotoPath: _model.drivingLicensePhotoPath!,
        drivingLicensePhotoSize: _model.drivingLicensePhotoSize ?? 0,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RiderRegisterStep3Screen(
            registrationModel: _model,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please complete all required vehicle details.'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasDlPhoto = _model.drivingLicensePhotoPath != null;

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
                'Vehicle Details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Step 2: Tell us how you plan to make deliveries',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Step Progress Bar (67%)
              const StepProgressBar(
                step: 2,
                progress: 0.67,
                percentageText: '67% Complete',
              ),
              const SizedBox(height: 28),

              // Vehicle Type Segmented Selector
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Vehicle Type',
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
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildVehicleOption('Motorcycle'),
                    _buildVehicleOption('Scooter'),
                    _buildVehicleOption('Bicycle'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Vehicle Number Field
              CustomTextField(
                label: 'Vehicle Number',
                hint: 'MH 02 AA 1234',
                controller: _vehicleNumberController,
                errorText: _vehicleNumberError,
                textCapitalization: TextCapitalization.characters,
                maxLength: 13,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
                  LengthLimitingTextInputFormatter(13),
                ],
                onChanged: (val) {
                  if (_vehicleNumberError != null) {
                    setState(() {
                      _vehicleNumberError =
                          RegistrationValidators.validateVehicleNumber(
                        val,
                        _model.vehicleType,
                      );
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // Driving License Number Field
              CustomTextField(
                label: 'Driving License Number',
                hint: 'DL-1420110012345',
                controller: _dlNumberController,
                errorText: _dlNumberError,
                textCapitalization: TextCapitalization.characters,
                maxLength: 16,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-]')),
                  LengthLimitingTextInputFormatter(16),
                ],
                onChanged: (val) {
                  if (_dlNumberError != null || val.length >= 15) {
                    setState(() {
                      _dlNumberError =
                          RegistrationValidators.validateDrivingLicenseNumber(
                        val,
                        _model.vehicleType,
                      );
                    });
                  }
                },
              ),
              const SizedBox(height: 24),

              // Driving License Photo Upload Container
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Driving License Photo',
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

              GestureDetector(
                onTap: _pickDrivingLicensePhoto,
                child: CustomPaint(
                  painter: DashedBorderPainter(
                    color: _dlPhotoError != null
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFCBD5E1),
                    borderRadius: 14,
                    dashWidth: 6,
                    dashSpace: 4,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: hasDlPhoto
                          ? const Color(0xFFF8FAFC)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: hasDlPhoto
                        ? Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  File(_model.drivingLicensePhotoPath!),
                                  height: 100,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) {
                                    return Container(
                                      height: 100,
                                      color: const Color(0xFFEEF2FF),
                                      child: const Center(
                                        child: Icon(Icons.document_scanner,
                                            color: AppTheme.primaryColor),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle,
                                      color: Color(0xFF10B981), size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'Driving License Photo Selected',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tap to retake / change photo',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEEF2FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_outlined,
                                  color: AppTheme.primaryColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Upload Front of Driving License',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Ensure all details are clearly readable',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              if (_dlPhotoError != null) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Text(
                    _dlPhotoError!,
                    style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 36),

              // Bottom Button: Next: Verification Documents
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _proceedToStep3,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Next: Verification Documents',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  Widget _buildVehicleOption(String title) {
    final bool isSelected = _model.vehicleType == title;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _model.vehicleType = title;
          });
        },
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }
}
