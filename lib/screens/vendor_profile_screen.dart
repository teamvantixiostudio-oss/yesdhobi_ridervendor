import 'package:flutter/material.dart';
import 'package:yesdhobi_ridervendor/widgets/vendor_bottom_nav.dart';
import 'package:yesdhobi_ridervendor/screens/portal_selection_screen.dart';
import 'package:yesdhobi_ridervendor/widgets/vendor_persistent_otp_banner.dart';

class VendorProfileScreen extends StatelessWidget {
  const VendorProfileScreen({super.key});

  void _handleLogout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const PortalSelectionScreen()),
      (route) => false,
    );
  }

  void _handleEditProfile(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Edit profile settings will be available shortly.'),
        backgroundColor: const Color(0xFF2563EB),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Persistent OTP Banner
              const VendorPersistentOtpBanner(),

              // Title
              const Text(
                'My Shop Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),

              // Shop Profile Card (White rounded card with avatar)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Avatar with circular border
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFEEF2FF),
                        border: Border.all(
                          color: const Color(0xFF3B82F6),
                          width: 3,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'SB',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Verified Partner Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF10B981),
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'VERIFIED PARTNER',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Shop Name
                    const Text(
                      'Star Bright Laundry',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Owner Name
                    const Text(
                      'Owner: Rajesh Kumar',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Rating & Reviews
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFF59E0B),
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '4.8',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(148 reviews)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Business Information Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Business Information',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildInfoRow(
                      label: 'Mobile Number',
                      value: '+91 98765 43210',
                    ),
                    const SizedBox(height: 16),

                    _buildInfoRow(
                      label: 'Shop Address',
                      value:
                          'Star Bright Laundry, Shop No. 12, Sector 15,\nHSR Layout, Bengaluru',
                    ),
                    const SizedBox(height: 16),

                    _buildInfoRow(
                      label: 'Business Hours',
                      value: '08:00 AM - 09:00 PM',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Button 1: Edit Shop Profile (Blue)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _handleEditProfile(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Edit Shop Profile',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Button 2: Logout Account (Red Outlined)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => _handleLogout(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(
                      color: Color(0xFFEF4444),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Logout Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const VendorBottomNav(currentIndex: 3),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
