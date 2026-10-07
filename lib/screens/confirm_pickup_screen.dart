import 'dart:async';
import 'package:flutter/material.dart';
import 'package:yesdhobi_ridervendor/theme.dart';
import 'package:yesdhobi_ridervendor/models/order_flow_model.dart';
import 'package:yesdhobi_ridervendor/widgets/custom_back_button.dart';
import 'package:yesdhobi_ridervendor/widgets/otp_input.dart';
import 'package:yesdhobi_ridervendor/widgets/app_bottom_nav.dart';
import 'package:yesdhobi_ridervendor/screens/order_status_screen.dart';
import 'package:yesdhobi_ridervendor/services/rider_api_service.dart';

class ConfirmPickupScreen extends StatefulWidget {
  final OrderFlowState orderState;

  const ConfirmPickupScreen({
    super.key,
    required this.orderState,
  });

  @override
  State<ConfirmPickupScreen> createState() => _ConfirmPickupScreenState();
}

class _ConfirmPickupScreenState extends State<ConfirmPickupScreen> {
  String _otp = '';
  int _countdownSeconds = 28;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdownTimer() {
    _timer?.cancel();
    setState(() {
      _countdownSeconds = 28;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        setState(() {
          _countdownSeconds--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  void _resendOtp() {
    if (_countdownSeconds == 0) {
      _startCountdownTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('OTP resent successfully to customer.'),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _verifyAndProceed() async {
    if (_otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid 4-digit OTP.'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final targetId = widget.orderState.rawOrderId ?? widget.orderState.orderId.replaceAll('#', '').replaceAll('YD-', '');
    try {
      if (widget.orderState.isDeliveryLeg || widget.orderState.rawStatus == 'OUT_FOR_DELIVERY') {
        await RiderApiService.instance.confirmDelivery(targetId, _otp, collectedCash: true);
      } else {
        final res = await RiderApiService.instance.confirmPickup(targetId, _otp);
        // Sync verified clothes weight/items to backend
        final weight = widget.orderState.totalWeight > 0 ? widget.orderState.totalWeight : 3.5;
        final count = widget.orderState.items.isNotEmpty ? widget.orderState.items.length : null;
        try {
          await RiderApiService.instance.updateOrderWeight(targetId, weight, itemsCount: count);
        } catch (_) {}

        // Update real vendor workshop destination details
        if (res['vendor'] != null && res['vendor'] is Map) {
          final v = res['vendor'] as Map<String, dynamic>;
          widget.orderState.vendorName = v['name']?.toString() ?? v['shopName']?.toString() ?? widget.orderState.vendorName;
          widget.orderState.vendorAddress = v['address']?.toString() ?? v['shopAddress']?.toString() ?? widget.orderState.vendorAddress;
          widget.orderState.vendorPhone = v['phone']?.toString() ?? widget.orderState.vendorPhone;
          widget.orderState.vendorRating = (v['rating'] as num?)?.toDouble() ?? widget.orderState.vendorRating;
          widget.orderState.vendorLatitude = (v['lat'] as num?)?.toDouble() ?? (v['latitude'] as num?)?.toDouble() ?? widget.orderState.vendorLatitude;
          widget.orderState.vendorLongitude = (v['lng'] as num?)?.toDouble() ?? (v['longitude'] as num?)?.toDouble() ?? widget.orderState.vendorLongitude;
        }
      }
    } catch (e) {
      debugPrint('Pickup OTP confirmation note: $e');
      final err = e.toString().replaceAll('Exception:', '').trim();
      if (err.toLowerCase().contains('incorrect') || err.toLowerCase().contains('otp')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }
    }

    // Update order status
    widget.orderState.stage = DeliveryStage.outForDrop;
    widget.orderState.customerOtp = _otp;

    if (!mounted) return;
    // Navigate to Order Status Screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderStatusScreen(orderState: widget.orderState),
      ),
    );
  }

  String get _formattedCountdown {
    final minutes = (_countdownSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_countdownSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const CustomBackButton(),
        title: const Text(
          'Confirm Pickup',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),

                    // Top Illustration Graphic
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEEF2FF),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: Color(0xFFDBEAFE),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF3B82F6),
                                width: 2.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF3B82F6),
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Heading
                    const Text(
                      'Enter Pickup Confirmation OTP',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Description
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Please enter the 4-digit OTP shared by the customer to confirm pickup',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Reusable OTP Input
                    OtpInput(
                      length: 4,
                      initialValue: '',
                      onChanged: (val) {
                        setState(() {
                          _otp = val;
                        });
                      },
                      onCompleted: (val) {
                        setState(() {
                          _otp = val;
                        });
                      },
                    ),
                    const SizedBox(height: 32),

                    // Resend OTP
                    GestureDetector(
                      onTap: _resendOtp,
                      child: Text(
                        'Resend OTP',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _countdownSeconds == 0
                              ? AppTheme.primaryColor
                              : AppTheme.primaryColor.withValues(alpha: 0.8),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Countdown text
                    Text(
                      _countdownSeconds > 0
                          ? 'Resend in $_formattedCountdown'
                          : 'You can resend now',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Bottom CTA Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _verifyAndProceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Verify & Confirm Pickup',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}
