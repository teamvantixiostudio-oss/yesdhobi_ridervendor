import 'dart:io';
import 'package:flutter/material.dart';
import 'package:yesdhobi_ridervendor/theme.dart';
import 'package:yesdhobi_ridervendor/widgets/app_logo.dart';
import 'package:yesdhobi_ridervendor/widgets/custom_back_button.dart';
import 'package:yesdhobi_ridervendor/screens/rider_dashboard_screen.dart';
import 'package:yesdhobi_ridervendor/services/rider_auth_service.dart';

import 'package:yesdhobi_ridervendor/screens/front_camera_selfie_screen.dart';

import 'dart:convert';
import 'package:yesdhobi_ridervendor/services/rider_api_service.dart';

class SelfieConfirmationScreen extends StatelessWidget {
  final String imagePath;

  const SelfieConfirmationScreen({
    super.key,
    required this.imagePath,
  });

  void _handleConfirm(BuildContext context) async {
    // Mark selfie as verified locally
    RiderAuthService.instance.setSelfieVerified(true, imagePath: imagePath);

    // Upload selfie to backend in background
    try {
      final file = File(imagePath);
      if (file.existsSync()) {
        final bytes = await file.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        await RiderApiService.instance.uploadSelfie(base64Image);
      }
    } catch (e) {
      debugPrint('Selfie upload error: $e');
    }

    if (!context.mounted) return;

    // Navigate to Rider Dashboard
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RiderDashboardScreen()),
      (route) => false,
    );
  }

  void _handleRetake(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const FrontCameraSelfieScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool fileExists = File(imagePath).existsSync();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Identity Verification',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Step 2: Selfie',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Selfie Preview Container with Green Verification Border & Badge
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF10B981),
                        width: 3.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: fileExists
                        ? Image.file(
                            File(imagePath),
                            fit: BoxFit.cover,
                          )
                        : const Center(
                            child: Icon(
                              Icons.person_rounded,
                              size: 100,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Looking good! Text
              const Text(
                'Looking good!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your selfie has been captured. Please confirm to proceed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 36),

              // Button 1: Confirm & Continue (Blue)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => _handleConfirm(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Confirm & Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Button 2: Retake Photo (Outlined)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () => _handleRetake(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF334155),
                    side: const BorderSide(
                      color: Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Retake Photo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
