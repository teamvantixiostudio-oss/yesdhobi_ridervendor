import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yesdhobi_ridervendor/theme.dart';
import 'package:yesdhobi_ridervendor/widgets/app_logo.dart';
import 'package:yesdhobi_ridervendor/widgets/custom_text_field.dart';
import 'package:yesdhobi_ridervendor/widgets/custom_back_button.dart';
import 'package:yesdhobi_ridervendor/screens/rider_register_step1_screen.dart';
import 'package:yesdhobi_ridervendor/screens/rider_dashboard_screen.dart';
import 'package:yesdhobi_ridervendor/screens/identity_verification_screen.dart';
import 'package:yesdhobi_ridervendor/screens/application_review_screen.dart';
import 'package:yesdhobi_ridervendor/services/rider_auth_service.dart';
import 'package:yesdhobi_ridervendor/utils/registration_validators.dart';
import 'package:yesdhobi_ridervendor/services/rider_api_service.dart';

class RiderLoginScreen extends StatefulWidget {
  const RiderLoginScreen({super.key});

  @override
  State<RiderLoginScreen> createState() => _RiderLoginScreenState();
}

class _RiderLoginScreenState extends State<RiderLoginScreen> {
  late TextEditingController _mobileController;
  late TextEditingController _passwordController;

  String? _mobileError;
  String? _passwordError;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _mobileController = TextEditingController();
    _passwordController = TextEditingController();
  }

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
    } else {
      mobileErr = RegistrationValidators.validateMobileNumber(mobile);
    }

    if (password.isEmpty) {
      passErr = 'Please enter password';
    } else if (password.length < 6) {
      passErr = 'Password must be at least 6 characters';
    }

    setState(() {
      _mobileError = mobileErr;
      _passwordError = passErr;
    });

    if (mobileErr == null && passErr == null) {
      setState(() => _isLoading = true);

      try {
        final res = await RiderApiService.instance.riderLogin(mobile, password);

        if (!mounted) return;
        setState(() => _isLoading = false);

        final rider = res['rider'] as Map<String, dynamic>?;
        final onboardingStatus = (rider?['onboardingStatus']?.toString() ?? 'APPROVED').toUpperCase();

        if (onboardingStatus == 'UNDER_REVIEW' || onboardingStatus == 'PENDING_REVIEW') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ApplicationReviewScreen(isVendor: false),
            ),
          );
          return;
        }

        RiderAuthService.instance.login(mobileNumber: mobile);

        final prefs = await SharedPreferences.getInstance();
        final isVerifiedLocally = prefs.getBool('rider_selfie_verified') ?? false;

        bool hasServerSelfie = false;
        final riderProfileRaw = prefs.getString('rider_profile');
        if (riderProfileRaw != null) {
          try {
            final rp = jsonDecode(riderProfileRaw);
            if (rp['documents'] is Map && rp['documents']['selfie'] != null) {
              hasServerSelfie = true;
            }
          } catch (_) {}
        }
        final userRaw = prefs.getString('rider_user');
        if (userRaw != null) {
          try {
            final u = jsonDecode(userRaw);
            if (u['avatarUrl'] != null && u['avatarUrl'].toString().isNotEmpty) {
              hasServerSelfie = true;
            }
          } catch (_) {}
        }

        // Check if selfie verification is already completed locally or on server
        if (!mounted) return;
        if (isVerifiedLocally || hasServerSelfie || RiderAuthService.instance.isSelfieVerified) {
          RiderAuthService.instance.setSelfieVerified(true);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const RiderDashboardScreen()),
            (route) => false,
          );
        } else {
          // One-time prompt for new riders without verified selfie
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const IdentityVerificationScreen(),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        final err = e.toString().replaceAll('Exception:', '').trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err.isNotEmpty ? err : 'Unable to sign in. Please verify your credentials.'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
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
              const SizedBox(height: 12),
              const Text(
                'Rider Login',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your registered mobile number and password to access your delivery dashboard',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),

              // Mobile Number Field
              CustomTextField(
                label: 'Registered Mobile Number',
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
              const SizedBox(height: 20),

              // Password Field
              CustomTextField(
                label: 'Password',
                hint: 'Enter your password',
                controller: _passwordController,
                errorText: _passwordError,
                obscureText: _obscurePassword,
                suffixWidget: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF64748B),
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                onChanged: (val) {
                  if (_passwordError != null) {
                    setState(() {
                      _passwordError = val.isEmpty ? 'Please enter password' : null;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              // Forgot Password Link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Password reset instructions will be sent via SMS to your registered mobile.'),
                        backgroundColor: AppTheme.primaryColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
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
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),

              // Don't have an account? Register CTA
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        RiderAuthService.instance.resetForNewRider();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RiderRegisterStep1Screen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
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
