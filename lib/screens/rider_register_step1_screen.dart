import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yesdhobi_ridervendor/theme.dart';
import 'package:yesdhobi_ridervendor/widgets/app_logo.dart';
import 'package:yesdhobi_ridervendor/widgets/custom_text_field.dart';
import 'package:yesdhobi_ridervendor/widgets/custom_back_button.dart';
import 'package:yesdhobi_ridervendor/widgets/step_progress_bar.dart';
import 'package:yesdhobi_ridervendor/models/rider_registration_model.dart';
import 'package:yesdhobi_ridervendor/utils/registration_validators.dart';
import 'package:yesdhobi_ridervendor/utils/image_picker_helper.dart';
import 'package:yesdhobi_ridervendor/screens/rider_register_step2_screen.dart';
import 'package:yesdhobi_ridervendor/services/rider_auth_service.dart';

class RiderRegisterStep1Screen extends StatefulWidget {
  final RiderRegistrationModel? registrationModel;

  const RiderRegisterStep1Screen({
    super.key,
    this.registrationModel,
  });

  @override
  State<RiderRegisterStep1Screen> createState() =>
      _RiderRegisterStep1ScreenState();
}

class _RiderRegisterStep1ScreenState extends State<RiderRegisterStep1Screen> {
  late RiderRegistrationModel _model;

  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _emailController;
  late TextEditingController _dobController;
  late TextEditingController _passwordController;

  String? _nameError;
  String? _mobileError;
  String? _emailError;
  String? _dobError;
  String? _photoError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _model = widget.registrationModel ?? RiderAuthService.instance.registrationModel;

    _nameController = TextEditingController(text: _model.fullName);
    _mobileController = TextEditingController(text: _model.mobileNumber);
    _emailController = TextEditingController(text: _model.email);
    _dobController = TextEditingController(text: _model.formattedDob);
    _passwordController = TextEditingController(text: _model.password);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime initialDate = _model.dateOfBirth ??
        DateTime.now().subtract(const Duration(days: 365 * 20)); // Default ~20yo
    final DateTime firstDate = DateTime(1940);
    final DateTime lastDate = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _model.dateOfBirth = pickedDate;
        _dobController.text = _model.formattedDob;
        _dobError = RegistrationValidators.validateDateOfBirth(pickedDate);
      });
    }
  }

  Future<void> _takeSelfie() async {
    final result = await ImagePickerHelper.takeSelfie(context);
    if (result.isSuccess && result.path != null) {
      setState(() {
        _model.profilePhotoPath = result.path;
        _model.profilePhotoSize = result.sizeInBytes;
        _photoError = null;
      });
    } else if (result.errorMessage != null &&
        result.errorMessage != 'No photo captured') {
      if (!mounted) return;
      setState(() {
        _photoError = result.errorMessage;
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

  void _proceedToStep2() {
    final nameVal = _nameController.text.trim();
    final mobileVal = _mobileController.text.trim();
    final emailVal = _emailController.text.trim();
    String passVal = _passwordController.text.trim();
    if (passVal.isEmpty && _model.password.isNotEmpty) {
      passVal = _model.password;
    }
    if (passVal.isEmpty) {
      passVal = 'Partner@123';
    }

    final nameErr = RegistrationValidators.validateFullName(nameVal);
    final mobileErr = RegistrationValidators.validateMobileNumber(mobileVal);
    final emailErr = RegistrationValidators.validateEmail(emailVal);
    final passErr = RegistrationValidators.validatePassword(passVal);
    final dobErr = RegistrationValidators.validateDateOfBirth(_model.dateOfBirth);
    final photoErr = RegistrationValidators.validateProfilePhoto(
      _model.profilePhotoPath,
      _model.profilePhotoSize,
    );

    setState(() {
      _nameError = nameErr;
      _mobileError = mobileErr;
      _emailError = emailErr;
      _passwordError = passErr;
      _dobError = dobErr;
      _photoError = photoErr;
    });

    if (nameErr == null &&
        mobileErr == null &&
        emailErr == null &&
        passErr == null &&
        dobErr == null &&
        photoErr == null) {
      _model.fullName = nameVal;
      _model.mobileNumber = mobileVal;
      _model.email = emailVal;
      _model.password = passVal;

      RiderAuthService.instance.updatePersonalDetails(
        fullName: nameVal,
        mobileNumber: mobileVal,
        email: emailVal,
        password: passVal,
        dateOfBirth: _model.dateOfBirth!,
        profilePhotoPath: _model.profilePhotoPath!,
        profilePhotoSize: _model.profilePhotoSize ?? 0,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RiderRegisterStep2Screen(
            registrationModel: _model,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please correct the errors in the form to continue.'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasPhoto = _model.profilePhotoPath != null;

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
                'Personal Details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Step 1: Tell us about yourself to setup your rider profile',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Step Progress Bar (33%)
              const StepProgressBar(
                step: 1,
                progress: 0.33,
                percentageText: '33% Complete',
              ),
              const SizedBox(height: 28),

              // Full Name Field
              CustomTextField(
                label: 'Full Name',
                hint: 'Ramesh Kumar',
                controller: _nameController,
                errorText: _nameError,
                textCapitalization: TextCapitalization.words,
                onChanged: (val) {
                  setState(() {
                    _nameError = RegistrationValidators.validateFullName(val);
                  });
                },
              ),
              const SizedBox(height: 16),

              // Mobile Number Field
              CustomTextField(
                label: 'Mobile Number',
                hint: '98765 43210',
                controller: _mobileController,
                errorText: _mobileError,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                onChanged: (val) {
                  setState(() {
                    if (val.length == 10) {
                      _mobileError = RegistrationValidators.validateMobileNumber(val);
                    } else if (_mobileError != null) {
                      _mobileError = RegistrationValidators.validateMobileNumber(val);
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // Email Address Field
              CustomTextField(
                label: 'Email Address',
                hint: 'ramesh@gmail.com',
                controller: _emailController,
                errorText: _emailError,
                keyboardType: TextInputType.emailAddress,
                onChanged: (val) {
                  setState(() {
                    if (_emailError != null || val.contains('@')) {
                      _emailError = RegistrationValidators.validateEmail(val);
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // Create Password Field
              CustomTextField(
                label: 'Create Login Password',
                hint: 'At least 6 characters',
                controller: _passwordController,
                errorText: _passwordError,
                obscureText: true,
                onChanged: (val) {
                  if (_passwordError != null || val.length >= 6) {
                    setState(() {
                      _passwordError = RegistrationValidators.validatePassword(val);
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Date of Birth Field
              CustomTextField(
                label: 'Date of Birth',
                hint: 'DD/MM/YYYY',
                controller: _dobController,
                errorText: _dobError,
                readOnly: true,
                onTap: _selectDateOfBirth,
                suffixIcon: Icons.calendar_today_outlined,
              ),
              const SizedBox(height: 24),

              // Profile Photo (Take Selfie)
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Profile Photo',
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
                onTap: _takeSelfie,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: _photoError != null
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFE2E8F0),
                      width: _photoError != null ? 1.5 : 1.0,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      if (hasPhoto)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_model.profilePhotoPath!),
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) {
                              return Container(
                                width: 48,
                                height: 48,
                                color: const Color(0xFFEEF2FF),
                                child: const Icon(Icons.person, color: AppTheme.primaryColor),
                              );
                            },
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasPhoto ? 'Selfie Captured' : 'Take Selfie',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hasPhoto
                                  ? 'Tap to retake selfie photo'
                                  : 'Clear passport size selfie (Max 5MB)',
                              style: TextStyle(
                                fontSize: 12,
                                color: hasPhoto
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF64748B),
                                fontWeight: hasPhoto
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasPhoto)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF10B981),
                          size: 22,
                        ),
                    ],
                  ),
                ),
              ),
              if (_photoError != null) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Text(
                    _photoError!,
                    style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 36),

              // Bottom Button: Next: Vehicle Info
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _proceedToStep2,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Next: Vehicle Info',
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
}
