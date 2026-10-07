import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yesdhobi_ridervendor/theme.dart';
import 'package:yesdhobi_ridervendor/widgets/app_logo.dart';
import 'package:yesdhobi_ridervendor/screens/rider_login_screen.dart';
import 'package:yesdhobi_ridervendor/screens/vendor_login_screen.dart';
import 'package:yesdhobi_ridervendor/services/rider_api_service.dart';

class ApplicationReviewScreen extends StatefulWidget {
  final bool isVendor;

  const ApplicationReviewScreen({
    super.key,
    this.isVendor = false,
  });

  @override
  State<ApplicationReviewScreen> createState() => _ApplicationReviewScreenState();
}

class _ApplicationReviewScreenState extends State<ApplicationReviewScreen> {
  /// This screen used to say "Application Under Review" no matter what the
  /// admin had actually decided, so a rejected rider saw the same waiting
  /// screen and assumed they had been let in. It now asks the server.
  bool _rejected = false;
  bool _approved = false;
  String? _serverMessage;
  String? _rejectionReason;

  bool get isVendor => widget.isVendor;

  @override
  void initState() {
    super.initState();
    if (!isVendor) _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final res = await RiderApiService.instance.getOnboardingStatus();
      if (!mounted) return;
      setState(() {
        _rejected = res['rejected'] == true;
        _approved = res['canWork'] == true;
        _serverMessage = res['message']?.toString();
        _rejectionReason = res['rejectionReason']?.toString();
      });
    } catch (e) {
      // leave the waiting state as it is; the rider can pull again by reopening
      debugPrint('Could not read onboarding status: $e');
    }
  }

  String get _title {
    if (_rejected) return 'Application Not Approved';
    if (_approved) return 'You Are Verified';
    return isVendor ? 'Shop Application Under Review' : 'Application Under Review';
  }

  String get _subtitle {
    if (_rejected) {
      final reason = (_rejectionReason == null || _rejectionReason!.isEmpty) ? '' : '\n\nReason: $_rejectionReason';
      return '${_serverMessage ?? 'Your proposal has been rejected. Please try again after 24 hours.'}$reason';
    }
    if (_approved) return _serverMessage ?? 'You are verified. Log in and go online to start receiving pickup requests.';
    return isVendor
        ? 'Thank you for registering on yesdhobi.com. Your laundry shop details are being verified by Yes Dhobi Admin. You will be able to access the portal once activated in the Admin Portal.'
        : 'Thank you for registering. Our team is verifying your documents and vehicle details.';
  }

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber.replaceAll(RegExp(r'\D'), ''),
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Calling $phoneNumber...'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Calling $phoneNumber...'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => isVendor ? const VendorLoginScreen() : const RiderLoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _navigateToLogin(context);
      },
      child: Scaffold(
        backgroundColor: AppTheme.primaryColor,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),

                          // Top Official Logo
                          const Center(
                            child: YesDhobiLogo(
                              height: 34,
                              variant: LogoVariant.white,
                            ),
                          ),
                          const SizedBox(height: 36),

                          Text(
                            _title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _subtitle,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 36),

                          // Timeline Steps
                          _buildTimelineStep(
                            title: isVendor ? 'Web Registration Submitted' : 'Application Received',
                            isCompleted: true,
                            isActive: false,
                            isLast: false,
                          ),
                          _buildTimelineStep(
                            title: 'Admin Verification & KYC Review',
                            subtitle: 'Under review in Yes Dhobi Admin Portal',
                            isCompleted: false,
                            isActive: true,
                            isLast: false,
                          ),
                          _buildTimelineStep(
                            title: isVendor ? 'Shop Equipment & Rate Check' : 'Document & Vehicle Check',
                            isCompleted: false,
                            isActive: false,
                            isLast: false,
                          ),
                          _buildTimelineStep(
                            title: 'Portal Access Activation',
                            isCompleted: false,
                            isActive: false,
                            isLast: true,
                          ),

                          const Spacer(),
                          const SizedBox(height: 24),

                          // Support Card
                          GestureDetector(
                            onTap: () =>
                                _makePhoneCall(context, '1800-123-9090'),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 18, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Need Help? Call partner support',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '1800-123-9090',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.secondaryColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Back to Login CTA Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton(
                              onPressed: () => _navigateToLogin(context),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: Colors.white, width: 1.5),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                isVendor ? 'Back to Vendor Login' : 'Continue to Rider Login',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    String? subtitle,
    required bool isCompleted,
    required bool isActive,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? AppTheme.secondaryColor
                        : (isActive ? Colors.white : Colors.white.withOpacity(0.25)),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 12, color: Color(0xFF1E293B))
                        : (isActive
                            ? Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.primaryColor,
                                ),
                              )
                            : null),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted
                          ? AppTheme.secondaryColor
                          : Colors.white.withOpacity(0.2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.w500,
                      color: isActive || isCompleted ? Colors.white : Colors.white60,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
