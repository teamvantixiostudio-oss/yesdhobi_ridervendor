import 'package:flutter/material.dart';
import 'package:yesdhobi_ridervendor/theme.dart';
import 'package:yesdhobi_ridervendor/widgets/app_logo.dart';
import 'package:yesdhobi_ridervendor/widgets/custom_back_button.dart';
import 'package:yesdhobi_ridervendor/widgets/dashed_border_painter.dart';
import 'package:yesdhobi_ridervendor/utils/image_picker_helper.dart';
import 'package:yesdhobi_ridervendor/screens/selfie_confirmation_screen.dart';

import 'package:yesdhobi_ridervendor/screens/front_camera_selfie_screen.dart';

class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends State<IdentityVerificationScreen> {
  bool _isLoading = false;

  Future<void> _handleTakeSelfie() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FrontCameraSelfieScreen(),
      ),
    );
  }

  Future<void> _handleUploadGallery() async {
    setState(() {
      _isLoading = true;
    });

    final result = await ImagePickerHelper.pickFromGallery(context);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    if (result.isSuccess && result.path != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SelfieConfirmationScreen(imagePath: result.path!),
        ),
      );
    } else if (result.errorMessage != null &&
        result.errorMessage != 'No image selected') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage!),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
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
                'Identity Verification',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Step 1: Selfie',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),

              // Dashed Box for Selfie Area
              CustomPaint(
                painter: DashedBorderPainter(
                  color: const Color(0xFFCBD5E1),
                  strokeWidth: 1.5,
                  dashWidth: 6,
                  dashSpace: 4,
                  borderRadius: 16,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 32.0, horizontal: 20.0),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEEF2FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.face_rounded,
                          size: 38,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Upload Your Selfie',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Take a quick selfie to verify your identity.\nMake sure your face is clearly visible.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Guidelines Section
              const Text(
                'GUIDELINES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildGuidelineItem('Face clearly visible'),
                    const SizedBox(height: 12),
                    _buildGuidelineItem('Good lighting'),
                    const SizedBox(height: 12),
                    _buildGuidelineItem('No sunglasses or masks'),
                    const SizedBox(height: 12),
                    _buildGuidelineItem('Match your registered photo'),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Take Selfie Button (Primary Blue)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleTakeSelfie,
                  icon: const Icon(Icons.camera_alt_rounded, size: 22),
                  label: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Take Selfie',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Upload From Gallery Button (Outlined Blue)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleUploadGallery,
                  icon: const Icon(Icons.photo_library_rounded, size: 22),
                  label: const Text(
                    'Upload From Gallery',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(
                      color: AppTheme.primaryColor,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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

  Widget _buildGuidelineItem(String text) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Color(0xFFECFDF5),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.check_rounded,
            color: Color(0xFF10B981),
            size: 14,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF334155),
          ),
        ),
      ],
    );
  }
}
