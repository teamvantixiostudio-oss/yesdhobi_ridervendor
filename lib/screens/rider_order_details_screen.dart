import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yesdhobi_ridervendor/models/order_flow_model.dart';
import 'package:yesdhobi_ridervendor/theme.dart';
import 'package:yesdhobi_ridervendor/screens/pickup_verification_screen.dart';
import 'package:yesdhobi_ridervendor/screens/confirm_vendor_dropoff_screen.dart';
import 'package:yesdhobi_ridervendor/screens/confirm_pickup_screen.dart';
import 'package:yesdhobi_ridervendor/widgets/custom_back_button.dart';
import 'package:yesdhobi_ridervendor/widgets/app_bottom_nav.dart';
import 'package:yesdhobi_ridervendor/services/rider_api_service.dart';
import 'package:yesdhobi_ridervendor/screens/order_chat_screen.dart';

class RiderOrderDetailsScreen extends StatelessWidget {
  final OrderFlowState? orderState;

  const RiderOrderDetailsScreen({
    super.key,
    this.orderState,
  });

  @override
  Widget build(BuildContext context) {
    final state = orderState ??
        OrderFlowState(
          orderId: '#YD-20240318-001',
          customerName: 'Rahul Sharma',
          customerInitials: 'RS',
          customerAddress: 'B-402, Shanti Vihar, Sector 45',
          estimatedLoad: '12-15 items',
        );
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const CustomBackButton(),
        title: const Text(
          'Order Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Step Tracker Card
              Container(
                padding: const EdgeInsets.all(16),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'CURRENT STEP',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Pickup Accepted',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Visual stepper bar
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Accepted',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Arrived',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Picked Up',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Map Section (Mocking maps beautifully)
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Mock Road lines/Grid drawing
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CustomPaint(
                          painter: MapMockPainter(),
                        ),
                      ),
                    ),
                    // Navigation details banner overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E293B),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.navigation_outlined, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      '1.4 km away from pickup',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'ETA 6 MIN',
                              style: TextStyle(
                                color: Color(0xFF3045E8),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Customer Info Card
              Container(
                padding: const EdgeInsets.all(16),
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
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFFEEF2FF),
                          child: Text(
                            state.customerInitials,
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.customerName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Customer',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFEEF2FF),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.phone_outlined, color: AppTheme.primaryColor),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32, color: Color(0xFFE2E8F0)),
                    _buildDetailRow(
                      icon: Icons.location_on_outlined,
                      label: 'PICKUP ADDRESS',
                      value: state.customerAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.inventory_2_outlined,
                      label: 'EST. LOAD SIZE',
                      value: state.estimatedLoad.isNotEmpty ? state.estimatedLoad : '12-15 items',
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.tag,
                      label: 'ORDER ID',
                      value: state.orderId,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              _ArrivedButton(state: state),
              _ContactRow(state: state),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () => _launchGoogleMaps(
                    state.pickupLatitude,
                    state.pickupLongitude,
                    state.customerAddress,
                  ),
                  icon: const Icon(Icons.near_me_outlined),
                  label: const Text(
                    'Navigate to Pickup Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: state.stage == DeliveryStage.delivered || state.rawStatus == 'DELIVERED'
                      ? null
                      : () {
                          if (state.isDeliveryLeg) {
                            if (state.stage == DeliveryStage.outForDrop || state.rawStatus == 'OUT_FOR_DELIVERY') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ConfirmPickupScreen(orderState: state),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ConfirmVendorDropoffScreen(orderState: state),
                                ),
                              );
                            }
                          } else {
                            if (state.stage == DeliveryStage.pickedUp ||
                                state.stage == DeliveryStage.outForDrop ||
                                state.rawStatus == 'PICKED_UP') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ConfirmVendorDropoffScreen(orderState: state),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PickupVerificationScreen(orderState: state),
                                ),
                              );
                            }
                          }
                        },
                  icon: Icon(
                    state.stage == DeliveryStage.delivered || state.rawStatus == 'DELIVERED'
                        ? Icons.check_circle_rounded
                        : state.isDeliveryLeg
                            ? (state.stage == DeliveryStage.outForDrop || state.rawStatus == 'OUT_FOR_DELIVERY'
                                ? Icons.home_rounded
                                : Icons.storefront_rounded)
                            : (state.stage == DeliveryStage.pickedUp ||
                                    state.stage == DeliveryStage.outForDrop ||
                                    state.rawStatus == 'PICKED_UP'
                                ? Icons.storefront_rounded
                                : Icons.local_shipping_rounded),
                    size: 22,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state.stage == DeliveryStage.delivered || state.rawStatus == 'DELIVERED'
                        ? const Color(0xFF64748B)
                        : state.isDeliveryLeg
                            ? (state.stage == DeliveryStage.outForDrop || state.rawStatus == 'OUT_FOR_DELIVERY'
                                ? const Color(0xFF10B981)
                                : const Color(0xFF2563EB))
                            : (state.stage == DeliveryStage.pickedUp ||
                                    state.stage == DeliveryStage.outForDrop ||
                                    state.rawStatus == 'PICKED_UP'
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF10B981)),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  label: Text(
                    state.stage == DeliveryStage.delivered || state.rawStatus == 'DELIVERED'
                        ? 'Order Completed'
                        : state.isDeliveryLeg
                            ? (state.stage == DeliveryStage.outForDrop || state.rawStatus == 'OUT_FOR_DELIVERY'
                                ? 'Deliver to Customer'
                                : 'Collect from Partner Shop')
                            : (state.stage == DeliveryStage.pickedUp ||
                                    state.stage == DeliveryStage.outForDrop ||
                                    state.rawStatus == 'PICKED_UP'
                                ? 'Drop Off at Partner Shop'
                                : 'PickUp Laundry'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  Future<void> _launchGoogleMaps(
      double? lat, double? lng, String address) async {
    Uri uri;
    if (lat != null && lng != null) {
      uri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    } else if (address.isNotEmpty) {
      final encoded = Uri.encodeComponent(address);
      uri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$encoded');
    } else {
      return;
    }

    try {
      final bool launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Could not launch maps: $e');
    }
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF64748B)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Custom Painter to draw a mock route map
class MapMockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    // Draw some grid roads
    canvas.drawLine(Offset(0, size.height * 0.3), Offset(size.width, size.height * 0.2), paint);
    canvas.drawLine(Offset(size.width * 0.4, 0), Offset(size.width * 0.4, size.height), paint);
    canvas.drawLine(Offset(size.width * 0.7, 0), Offset(size.width * 0.7, size.height), paint);
    canvas.drawLine(Offset(0, size.height * 0.7), Offset(size.width, size.height * 0.8), paint);

    // Draw route line (blue)
    final routePaint = Paint()
      ..color = AppTheme.primaryColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.75)
      ..lineTo(size.width * 0.4, size.height * 0.7)
      ..lineTo(size.width * 0.4, size.height * 0.25)
      ..lineTo(size.width * 0.7, size.height * 0.2)
      ..lineTo(size.width * 0.8, size.height * 0.3);
    canvas.drawPath(path, routePaint);

    // Start point pin indicator (grey circle)
    final pinPaint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.75), 6, pinPaint);

    // Destination pin indicator (blue pin mockup)
    final destPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.3), 8, destPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// "Arrived at Location" - the rider taps this on reaching the customer (or
/// the shop) and the customer's tracking screen updates immediately, instead
/// of them wondering where the rider is until the OTP step.
///
/// Its own small stateful widget so the details screen can stay stateless.
class _ArrivedButton extends StatefulWidget {
  final OrderFlowState state;

  const _ArrivedButton({required this.state});

  @override
  State<_ArrivedButton> createState() => _ArrivedButtonState();
}

class _ArrivedButtonState extends State<_ArrivedButton> {
  bool _sending = false;
  bool _arrived = false;

  bool get _finished =>
      widget.state.stage == DeliveryStage.delivered || widget.state.rawStatus == 'DELIVERED';

  String? get _orderId {
    final raw = widget.state.rawOrderId;
    if (raw != null && raw.isNotEmpty) return raw;
    final display = widget.state.orderId.replaceAll('#', '').trim();
    return display.isEmpty ? null : display;
  }

  Future<void> _markArrived() async {
    final id = _orderId;
    if (_sending || id == null) return;
    setState(() => _sending = true);
    try {
      final res = await RiderApiService.instance.markArrived(id);
      if (!mounted) return;
      setState(() {
        _arrived = true;
        _sending = false;
      });
      final already = res['alreadyMarked'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(already ? 'Already marked as arrived.' : 'The customer has been told you have arrived.'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception:', '').trim()),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: (_sending || _arrived) ? null : _markArrived,
          icon: Icon(_arrived ? Icons.check_circle_outline : Icons.location_on_outlined),
          label: Text(
            _arrived ? 'Customer notified' : "I've Arrived at Location",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _arrived ? const Color(0xFF94A3B8) : const Color(0xFF0EA5E9),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFF94A3B8),
            disabledForegroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}

/// Message the customer or the laundry partner about this order.
///
/// Each opens its own thread - the server keeps them apart, so what the rider
/// says to the shop is never visible to the customer. Calling lives inside the
/// chat screen, where the number comes from the server and is only real while
/// a call makes sense for this stage of the order.
class _ContactRow extends StatelessWidget {
  final OrderFlowState state;

  const _ContactRow({required this.state});

  String? get _orderId {
    final raw = state.rawOrderId;
    if (raw != null && raw.isNotEmpty) return raw;
    final display = state.orderId.replaceAll('#', '').trim();
    return display.isEmpty ? null : display;
  }

  void _open(BuildContext context, String party, String label) {
    final id = _orderId;
    if (id == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderChatScreen(orderId: id, party: party, partyLabel: label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_orderId == null) return const SizedBox.shrink();
    final hasVendor = state.vendorName.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _open(context, 'customer', 'Customer'),
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Customer'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: AppTheme.primaryColor,
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          if (hasVendor) ...[
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _open(context, 'vendor', 'Laundry partner'),
                icon: const Icon(Icons.storefront_outlined, size: 18),
                label: const Text('Shop'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
