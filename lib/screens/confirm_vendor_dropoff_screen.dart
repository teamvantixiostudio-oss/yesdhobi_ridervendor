import 'dart:async';
import 'package:flutter/material.dart';
import 'package:yesdhobi_ridervendor/theme.dart';
import 'package:yesdhobi_ridervendor/models/order_flow_model.dart';
import 'package:yesdhobi_ridervendor/widgets/custom_back_button.dart';
import 'package:yesdhobi_ridervendor/widgets/otp_input.dart';
import 'package:yesdhobi_ridervendor/widgets/vendor_card.dart';
import 'package:yesdhobi_ridervendor/widgets/app_bottom_nav.dart';
import 'package:yesdhobi_ridervendor/screens/dropoff_confirmed_screen.dart';
import 'package:yesdhobi_ridervendor/screens/rider_order_details_screen.dart';
import 'package:yesdhobi_ridervendor/services/vendor_order_service.dart';
import 'package:yesdhobi_ridervendor/services/rider_api_service.dart';

class ConfirmVendorDropoffScreen extends StatefulWidget {
  final OrderFlowState? orderState;

  const ConfirmVendorDropoffScreen({
    super.key,
    this.orderState,
  });

  @override
  State<ConfirmVendorDropoffScreen> createState() =>
      _ConfirmVendorDropoffScreenState();
}

class _ConfirmVendorDropoffScreenState
    extends State<ConfirmVendorDropoffScreen> {
  late OrderFlowState _state;
  String _otp = '';
  int _countdownSeconds = 28;
  Timer? _timer;
  // See confirm_pickup_screen: one submit per tap, and never twice.
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _state = widget.orderState ??
        OrderFlowState(
          orderId: '#YD-9612',
          customerName: 'Amit Patel',
          vendorName: 'Star Bright Laundry',
          vendorRating: 4.9,
          vendorTag: 'Professional Partner',
          vendorAddress: 'Shop No. 12, Sector 15, HSR Layout, Bengaluru',
        );
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
          content: const Text('OTP requested from vendor.'),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _verifyAndConfirm() async {
    if (_submitting) return;
    if (_otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter the complete 4-digit Vendor OTP.'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final targetId = (_state.rawOrderId != null && _state.rawOrderId!.isNotEmpty)
        ? _state.rawOrderId!
        : _state.orderId.replaceFirst('#', '');
    setState(() => _submitting = true);
    try {
      if (_state.isDeliveryLeg || _state.rawStatus == 'READY') {
        await RiderApiService.instance.confirmHandover(targetId, _otp);
      } else {
        await RiderApiService.instance.confirmDropoff(targetId, _otp);
      }
    } catch (e) {
      // The handoff was not recorded, so do not advance the rider.
      debugPrint('Dropoff OTP confirmation failed: $e');
      if (!mounted) return;
      setState(() => _submitting = false);
      final err = e.toString().replaceAll('Exception:', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err.isEmpty ? 'Could not confirm the handover. Please try again.' : err),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final isHandover = _state.isDeliveryLeg || _state.rawStatus == 'READY';
    if (isHandover) {
      _state.stage = DeliveryStage.outForDrop;
      _state.rawStatus = 'OUT_FOR_DELIVERY';
      _state.vendorOtp = _otp;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Order collected from partner shop! Proceed to customer delivery.'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RiderOrderDetailsScreen(orderState: _state),
        ),
      );
    } else {
      _state.stage = DeliveryStage.delivered;
      _state.vendorOtp = _otp;
      _state.dropoffTime = _clockTime(DateTime.now());

      // Mark completed in VendorOrderService and dismiss OTP banner
      VendorOrderService.instance.verifyOtpAndCompleteOrder(_state.orderId);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DropoffConfirmedScreen(orderState: _state),
        ),
      );
    }
  }

  /// 12-hour clock without touching BuildContext after an await.
  static String _clockTime(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${t.hour < 12 ? 'AM' : 'PM'}';
  }

  String get _formattedCountdown {
    final minutes = (_countdownSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_countdownSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final bool isHandover = _state.isDeliveryLeg || _state.rawStatus == 'READY';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: const CustomBackButton(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isHandover ? const Color(0xFFECFDF5) : const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isHandover ? 'COLLECTION' : 'DROP OFF',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isHandover ? const Color(0xFF10B981) : AppTheme.primaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Titles
              Text(
                isHandover ? 'Confirm Order Collection' : 'Confirm Vendor Drop-off',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Order ${_state.orderId}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),

              // Drop-off / Collection Vendor Card
              VendorCard(
                sectionTitle: isHandover ? 'LAUNDRY PARTNER SHOP' : 'DROP-OFF VENDOR',
                vendorName: _state.vendorName.isNotEmpty ? _state.vendorName : 'Star Bright Laundry',
                rating: _state.vendorRating > 0 ? _state.vendorRating : 4.9,
                tag: _state.vendorTag.isNotEmpty ? _state.vendorTag : 'Professional Partner',
                address: _state.vendorAddress.isNotEmpty ? _state.vendorAddress : 'Shop No. 12, Sector 15, HSR Layout, Bengaluru',
                useStorefrontIcon: true,
                onCallTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Calling ${_state.vendorName.isNotEmpty ? _state.vendorName : "Partner Shop"}...'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Enter Vendor OTP Card
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHandover ? 'Enter Handover OTP' : 'Enter Vendor Drop-off OTP',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isHandover
                          ? 'Ask the partner shop for the 4-digit Handover OTP to collect packaged clothes'
                          : 'Ask the vendor for the 4-digit OTP to confirm clothes drop-off',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

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
                    const SizedBox(height: 20),

                    // Resend OTP
                    Center(
                      child: Column(
                        children: [
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
                          const SizedBox(height: 6),
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Verify & Confirm Drop-off CTA (Royal Blue Button)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _verifyAndConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isHandover ? 'Verify & Collect Order' : 'Verify & Confirm Drop-off',
                    style: const TextStyle(
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
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}
