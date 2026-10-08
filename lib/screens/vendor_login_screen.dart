import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yesdhobi_ridervendor/theme.dart';
import 'package:yesdhobi_ridervendor/screens/forgot_password_screen.dart';
import 'package:yesdhobi_ridervendor/widgets/custom_text_field.dart';
import 'package:yesdhobi_ridervendor/widgets/custom_back_button.dart';
import 'package:yesdhobi_ridervendor/widgets/app_logo.dart';
import 'package:yesdhobi_ridervendor/screens/vendor_home_screen.dart';
import 'package:yesdhobi_ridervendor/screens/application_review_screen.dart';
import 'package:yesdhobi_ridervendor/utils/registration_validators.dart';
import 'package:yesdhobi_ridervendor/services/vendor_order_service.dart';

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
  bool _obscurePassword = true;

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

    // Either identifier is fine: the Registration ID from the onboarding
    // confirmation screen, or the mobile the shop registered with.
    if (mobile.isEmpty) {
      mobileErr = 'Enter your Registration ID or registered mobile number';
    } else if (VendorOrderService.looksLikeRegistrationId(mobile)) {
      mobileErr = null;
    } else if (RegExp(r'^[A-Za-z]').hasMatch(mobile)) {
      mobileErr = 'Registration IDs look like VD100008';
    } else {
      mobileErr = RegistrationValidators.validateMobileNumber(mobile);
    }

    if (password.isEmpty) {
      passErr = 'Please enter your password';
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
        final res = await VendorOrderService.instance.vendorLogin(mobile, password);

        if (!mounted) return;
        setState(() => _isLoading = false);

        final vendor = res['vendor'] as Map<String, dynamic>?;
        final status = (vendor?['status']?.toString() ?? 'ACTIVE').toUpperCase();

        if (status == 'PENDING_VERIFICATION') {
          // Vendor registered on web, but pending admin verification
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ApplicationReviewScreen(isVendor: true),
            ),
          );
          return;
        }

        // Active vendor -> go to VendorHomeScreen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const VendorHomeScreen()),
          (route) => false,
        );
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

  void _showRegistrationInfo() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.storefront_rounded, color: Color(0xFF2563EB)),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Vendor Partner Onboarding',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildOnboardingStep(
              number: '1',
              title: 'Register on yesdhobi.com',
              subtitle: 'Submit your laundry shop details, daily capacity, and services on the partner portal.',
            ),
            const SizedBox(height: 12),
            _buildOnboardingStep(
              number: '2',
              title: 'Admin Portal Approval',
              subtitle: 'Yes Dhobi admins review your shop and activate your partner account in the Admin Portal.',
            ),
            const SizedBox(height: 12),
            _buildOnboardingStep(
              number: '3',
              title: 'Log In with Registered Mobile',
              subtitle: 'Once approved, sign in with your mobile number & password to start receiving orders!',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Understood', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingStep({
    required String number,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: const Color(0xFF2563EB),
          child: Text(
            number,
            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
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
                  const YesDhobiLogo(
                    height: 28,
                    variant: LogoVariant.navy,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Text(
                      'PARTNER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2563EB),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Welcome Titles
              const Text(
                'Vendor Portal Login',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Access your laundry shop dashboard, manage incoming orders and track earnings',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Registration ID or registered mobile
              CustomTextField(
                label: 'Registration ID or Mobile Number',
                hint: 'VD100008 or 91234 56789',
                controller: _mobileController,
                errorText: _mobileError,
                keyboardType: TextInputType.text,
                maxLength: 20,
                inputFormatters: const [],
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
              const SizedBox(height: 18),

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
                      _passwordError = val.isEmpty ? 'Please enter your password' : null;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              // Forgot Password link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen(role: 'vendor'),
                    ),
                  ),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 52,
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
                      onTap: _showRegistrationInfo,
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
