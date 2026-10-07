import 'package:flutter/material.dart';
import 'package:yesdhobi_ridervendor/theme.dart';
import 'package:yesdhobi_ridervendor/widgets/app_logo.dart';
import 'package:yesdhobi_ridervendor/screens/vendor_login_screen.dart';
import 'package:yesdhobi_ridervendor/screens/rider_register_step1_screen.dart';
import 'package:yesdhobi_ridervendor/screens/rider_login_screen.dart';
import 'package:yesdhobi_ridervendor/services/rider_auth_service.dart';

class PortalSelectionScreen extends StatefulWidget {
  const PortalSelectionScreen({super.key});

  @override
  State<PortalSelectionScreen> createState() => _PortalSelectionScreenState();
}

class _PortalSelectionScreenState extends State<PortalSelectionScreen> {
  String selectedPortal = 'Rider';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Official Logo
              const Center(
                child: YesDhobiLogo(
                  height: 34,
                  variant: LogoVariant.navy,
                ),
              ),
              const SizedBox(height: 48),

              // Title and Subtitle
              const Text(
                'Welcome to Yes Dhobi',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please select your portal to continue using the application.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Rider Card
              _buildPortalCard(
                title: 'Delivery Rider',
                description:
                    'Deliver laundry in your neighborhood & earn up to 40k-80k monthly.',
                icon: Icons.local_shipping_outlined,
                iconContainerColor: const Color(0xFFEEF2FF),
                iconColor: AppTheme.primaryColor,
                isSelected: selectedPortal == 'Rider',
                onTap: () {
                  setState(() {
                    selectedPortal = 'Rider';
                  });
                },
              ),

              const SizedBox(height: 16),

              // Vendor Card
              _buildPortalCard(
                title: 'Vendor',
                description:
                    'Manage your laundry business, track orders & earnings.',
                icon: Icons.storefront_outlined,
                iconContainerColor: const Color(0xFFFEF9C3),
                iconColor: const Color(0xFFD97706),
                isSelected: selectedPortal == 'Vendor',
                onTap: () {
                  setState(() {
                    selectedPortal = 'Vendor';
                  });
                },
              ),

              const Spacer(),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (selectedPortal == 'Vendor') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const VendorLoginScreen()),
                      );
                    } else {
                      // Navigate directly to Personal Details (Step 1)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RiderRegisterStep1Screen(
                            registrationModel:
                                RiderAuthService.instance.registrationModel,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    selectedPortal == 'Rider'
                        ? 'Continue as Rider'
                        : 'Continue as Vendor',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Returning user login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already a user? ',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (selectedPortal == 'Vendor') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const VendorLoginScreen()),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RiderLoginScreen()),
                        );
                      }
                    },
                    child: const Text(
                      'Log in',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortalCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconContainerColor,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconContainerColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
