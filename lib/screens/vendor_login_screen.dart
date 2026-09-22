import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yesdhobi_ridervendor/theme.dart';
import 'package:yesdhobi_ridervendor/widgets/custom_text_field.dart';
import 'package:yesdhobi_ridervendor/widgets/custom_back_button.dart';
import 'package:yesdhobi_ridervendor/screens/vendor_home_screen.dart';
import 'package:yesdhobi_ridervendor/utils/registration_validators.dart';

import 'package:yesdhobi_ridervendor/services/rider_api_service.dart';

class VendorLoginScreen extends StatefulWidget {
  const VendorLoginScreen({super.key});

  @override
  State<VendorLoginScreen> createState() => _VendorLoginScreenState();
}

class _VendorLoginScreenState extends State<VendorLoginScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _mobileError;
  String? _passwordError;
  bool _isLoading = false;

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final mobile = _mobileController.text.trim();
    final password = _passwordController.text.trim();

    String? mobileErr;
    String? passErr;

    if (mobile.isEmpty) {
      mobileErr = 'Please enter registered mobile number';
    } else if (mobile.length != 10 &&
        RegistrationValidators.validateMobileNumber(mobile) != null) {
      mobileErr = 'Enter a valid 10-digit mobile number';
    }

    if (password.isEmpty) {
      passErr = 'Please enter your password';
    }

    setState(() {
      _mobileError = mobileErr;
      _passwordError = passErr;
    });

    if (mobileErr == null && passErr == null) {
      if (!Platform.environment.containsKey('FLUTTER_TEST')) {
        setState(() => _isLoading = true);
        try {
          await RiderApiService.instance.vendorLogin(mobile, password);
        } catch (e) {
          debugPrint('Vendor backend auth error: $e');
        }

        if (!mounted) return;
        setState(() => _isLoading = false);
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const VendorHomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: const CustomBackButton(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // Top Brand Header
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.sync_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Yes Dhobi',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'VENDOR PORTAL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4F46E5),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // Title and Subtitle
              const Text(
                'Welcome back!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Login with your registered credentials',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 36),

              // Mobile Number Field
              CustomTextField(
                label: 'Registered Mobile Number *',
                hint: 'Enter 10-digit number',
                controller: _mobileController,
                errorText: _mobileError,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                suffixIcon: Icons.phone_android_rounded,
                onChanged: (val) {
                  if (_mobileError != null) {
                    setState(() {
                      _mobileError = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // Password Field
              CustomTextField(
                label: 'Password *',
                hint: '••••••••',
                controller: _passwordController,
                errorText: _passwordError,
                suffixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                onChanged: (val) {
                  if (_passwordError != null) {
                    setState(() {
                      _passwordError = null;
                    });
                  }
                },
              ),

              // Forgot Password link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                            'Password reset link sent to your registered phone.'),
                        backgroundColor: AppTheme.primaryColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Login to Portal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 28),

              // Register on Web
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'New partner? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                                'Please visit yesdhobi.com/partners to register as a new vendor.'),
                            backgroundColor: AppTheme.primaryColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Register on Web',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
