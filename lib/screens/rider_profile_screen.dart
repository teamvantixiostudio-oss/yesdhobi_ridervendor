import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yesdhobi_ridervendor/theme.dart';
import 'package:yesdhobi_ridervendor/services/rider_auth_service.dart';
import 'package:yesdhobi_ridervendor/services/rider_api_service.dart';
import 'package:yesdhobi_ridervendor/widgets/app_bottom_nav.dart';
import 'package:yesdhobi_ridervendor/screens/portal_selection_screen.dart';

class RiderProfileScreen extends StatefulWidget {
  const RiderProfileScreen({super.key});

  @override
  State<RiderProfileScreen> createState() => _RiderProfileScreenState();
}

class _RiderProfileScreenState extends State<RiderProfileScreen> {
  String _riderName = 'Rider Partner';
  String _riderPhone = '';
  String _vehicleType = 'Motorcycle';
  String _vehicleNumber = '';
  String? _avatarUrl;
  String? _localSelfiePath;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Load from local cache first
    _localSelfiePath = RiderAuthService.instance.selfieImagePath ??
        prefs.getString('rider_selfie_image_path');

    final userRaw = prefs.getString('rider_user');
    if (userRaw != null) {
      try {
        final u = jsonDecode(userRaw);
        if (u['name'] != null) _riderName = u['name'].toString();
        if (u['phone'] != null) _riderPhone = u['phone'].toString();
        if (u['avatarUrl'] != null) _avatarUrl = u['avatarUrl'].toString();
      } catch (_) {}
    }

    final riderRaw = prefs.getString('rider_profile');
    if (riderRaw != null) {
      try {
        final r = jsonDecode(riderRaw);
        if (r['vehicleNumber'] != null) _vehicleNumber = r['vehicleNumber'].toString();
        if (r['vehicleType'] != null) _vehicleType = r['vehicleType'].toString();
        if (_avatarUrl == null && r['documents'] is Map && r['documents']['selfie'] != null) {
          _avatarUrl = r['documents']['selfie'].toString();
        }
      } catch (_) {}
    }

    final reg = RiderAuthService.instance.registrationModel;
    if (_riderName == 'Rider Partner' && reg.fullName.isNotEmpty) _riderName = reg.fullName;
    if (_riderPhone.isEmpty && reg.mobileNumber.isNotEmpty) _riderPhone = reg.mobileNumber;
    if (_vehicleNumber.isEmpty && reg.vehicleNumber.isNotEmpty) _vehicleNumber = reg.vehicleNumber;

    if (mounted) setState(() {});

    // 2. Fetch fresh profile from backend
    try {
      final profile = await RiderApiService.instance.getRiderProfile();
      if (profile['user'] is Map) {
        final u = profile['user'];
        if (u['name'] != null) _riderName = u['name'].toString();
        if (u['phone'] != null) _riderPhone = u['phone'].toString();
        if (u['avatarUrl'] != null) _avatarUrl = u['avatarUrl'].toString();
        await prefs.setString('rider_user', jsonEncode(u));
      }
      if (profile['vehicleNumber'] != null) {
        _vehicleNumber = profile['vehicleNumber'].toString();
      }
      if (profile['vehicleType'] != null) {
        _vehicleType = profile['vehicleType'].toString();
      }
      if (_avatarUrl == null && profile['documents'] is Map && profile['documents']['selfie'] != null) {
        _avatarUrl = profile['documents']['selfie'].toString();
      }
      await prefs.setString('rider_profile', jsonEncode(profile));

      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _handleLogout(BuildContext context) {
    RiderAuthService.instance.logout();
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
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildAvatarImage() {
    // 1. Check local selfie file from photo capture
    if (_localSelfiePath != null && _localSelfiePath!.isNotEmpty) {
      final file = File(_localSelfiePath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: 84,
          height: 84,
          fit: BoxFit.cover,
        );
      }
    }

    // 2. Check server-hosted avatar URL
    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      return Image.network(
        _avatarUrl!,
        width: 84,
        height: 84,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
      );
    }

    // 3. Fallback default avatar icon
    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 84,
      height: 84,
      color: const Color(0xFFE2E8F0),
      child: const Icon(
        Icons.person_rounded,
        size: 54,
        color: Color(0xFF2563EB),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _riderName.isNotEmpty ? _riderName : 'Rider Partner';
    final displayPhone = _riderPhone.isNotEmpty
        ? (_riderPhone.startsWith('+') ? _riderPhone : '+91 $_riderPhone')
        : '+91 98765 43210';
    final displayPlate = _vehicleNumber.isNotEmpty ? _vehicleNumber : 'DL-3C-AL-9023';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Brand Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.sync_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Yes Dhobi',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'RIDER',
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
              const SizedBox(height: 16),

              // Title & Subtitle
              const Text(
                'My Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Manage your personal and vehicle details',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 18),

              // Profile Card
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
                  children: [
                    // Avatar with circular border (Live Selfie Display)
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF3B82F6),
                          width: 3,
                        ),
                        color: const Color(0xFFEEF2FF),
                      ),
                      alignment: Alignment.center,
                      child: ClipOval(
                        child: _buildAvatarImage(),
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
                    const SizedBox(height: 10),

                    // Rider Name
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Phone Number
                    Text(
                      displayPhone,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Statistics Row
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          _buildStatColumn('240', 'All Deliveries'),
                          Container(
                            height: 28,
                            width: 1,
                            color: const Color(0xFFE2E8F0),
                          ),
                          _buildStatColumn('4.8★', 'My Rating'),
                          Container(
                            height: 28,
                            width: 1,
                            color: const Color(0xFFE2E8F0),
                          ),
                          _buildStatColumn('2.5 yrs', 'Tenure'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Vehicle & Identity Card
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
                      'Vehicle & Identity',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildInfoRow(
                      label: 'Vehicle Registered',
                      value: _vehicleType,
                    ),
                    const SizedBox(height: 14),

                    _buildInfoRow(
                      label: 'Vehicle Number',
                      value: displayPlate,
                    ),
                    const SizedBox(height: 14),

                    _buildInfoRow(
                      label: 'Aadhaar Status',
                      value: 'Verified',
                      valueColor: const Color(0xFF10B981),
                    ),
                    const SizedBox(height: 14),

                    _buildInfoRow(
                      label: 'License Status',
                      value: 'Verified (Expires 2031)',
                      valueColor: const Color(0xFF10B981),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Button 1: Edit Profile Settings (Blue)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => _handleEditProfile(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Edit Profile Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Button 2: Logout Partner Portal (Red Outlined)
              SizedBox(
                width: double.infinity,
                height: 54,
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
                    'Logout Partner Portal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor ?? const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
