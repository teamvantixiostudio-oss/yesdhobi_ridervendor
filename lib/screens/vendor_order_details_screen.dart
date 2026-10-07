import 'package:flutter/material.dart';
import 'package:yesdhobi_ridervendor/widgets/custom_back_button.dart';
import 'package:yesdhobi_ridervendor/models/vendor_order_model.dart';
import 'package:yesdhobi_ridervendor/services/vendor_order_service.dart';
import 'package:yesdhobi_ridervendor/screens/vendor_rider_booked_screen.dart';

class VendorOrderDetailsScreen extends StatefulWidget {
  final VendorOrderModel? order;
  final String orderId;
  final String customerName;
  final String customerPhone;

  const VendorOrderDetailsScreen({
    super.key,
    this.order,
    this.orderId = '#YD-9612',
    this.customerName = 'Amit Patel',
    this.customerPhone = '+91 99887 76655',
  });

  @override
  State<VendorOrderDetailsScreen> createState() =>
      _VendorOrderDetailsScreenState();
}

class _VendorOrderDetailsScreenState extends State<VendorOrderDetailsScreen> {
  late VendorOrderModel _order;

  @override
  void initState() {
    super.initState();
    _order = widget.order ??
        VendorOrderService.instance.getOrderById(widget.orderId) ??
        VendorOrderModel(
          orderId: widget.orderId,
          customerName: widget.customerName,
          customerPhone: widget.customerPhone,
          serviceType: 'Premium Wash & Iron',
          itemCount: 6,
          itemsDescription: '6 Items • Premium Wash & Iron',
        );
  }

  void _handleMarkPackaged() {
    if (_order.isPackaged && _order.isRiderBooked) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VendorRiderBookedScreen(order: _order),
        ),
      ).then((_) {
        setState(() {});
      });
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Package & Truck Icon in Light-Blue Circle
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEF2FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: Color(0xFF2563EB),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 18),

                // Title
                const Text(
                  'Mark as Packed & Assign Rider?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Order ${_order.orderId} will be marked as packed, the nearest rider (Zack Colah) will be automatically assigned, and a pickup OTP will be generated.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),

                // Summary Pill
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CUSTOMER & ITEMS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_order.customerName} · ${_order.itemCount} items (${_order.serviceType})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action 1: Confirm & Assign
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(dialogCtx); // Close dialog
                      final updated = await VendorOrderService.instance
                          .markAsPackagedAndAssignRider(_order);
                      setState(() {
                        _order = updated;
                      });

                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              VendorRiderBookedScreen(order: _order),
                        ),
                      ).then((_) {
                        setState(() {});
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Confirm & Assign Rider',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Action 2: Cancel
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(dialogCtx);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
        title: Text(
          'Order ${_order.orderId}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Card
              Container(
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
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEEF2FF),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _order.customerInitials,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _order.customerName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _order.customerPhone,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEEF2FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.phone_rounded,
                        color: Color(0xFF2563EB),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Order Items List Card
              Container(
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Items (${_order.itemCount})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_order.itemsList.isNotEmpty)
                      ..._order.itemsList.map((item) {
                        final name = item['name']?.toString() ?? 'Garment Item';
                        final qty = item['quantity']?.toString() ?? '1';
                        final service = item['service']?.toString() ?? _order.serviceType;
                        return Column(
                          children: [
                            const Divider(color: Color(0xFFF1F5F9)),
                            _buildLaundryItemRow(name, '$service (x$qty)'),
                          ],
                        );
                      })
                    else ...[
                      const Divider(color: Color(0xFFF1F5F9)),
                      _buildLaundryItemRow(_order.serviceType, '${_order.itemCount} items'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Special Instructions Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFFD97706),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Special Instructions',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Please use mild starch for cotton shirts and gentle detergent for denim.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF78350F),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Processing Stage Controls
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Update Laundry Stage',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _order.status.replaceAll('_', ' '),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStatusBtn('WASHING', 'Washing'),
                        _buildStatusBtn('IRONING', 'Ironing'),
                        _buildStatusBtn('QUALITY_CHECK', 'Quality Check'),
                        _buildStatusBtn('READY', 'Ready & Packed'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Order Tracker Section
              const Text(
                'Order Tracker',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(20),
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
                    _buildTrackerStep(
                      title: 'Order Accepted',
                      subtitle: '10:35 AM, Today',
                      stepState: TrackerStepState.completed,
                      showConnector: true,
                    ),
                    _buildTrackerStep(
                      title: 'Order Received',
                      subtitle: '10:30 AM, Today',
                      stepState: TrackerStepState.completed,
                      showConnector: true,
                    ),
                    _buildTrackerStep(
                      title: 'Packing',
                      subtitle:
                          _order.isPackaged ? 'Completed' : 'Current step',
                      stepState: _order.isPackaged
                          ? TrackerStepState.completed
                          : TrackerStepState.active,
                      showConnector: true,
                    ),
                    _buildTrackerStep(
                      title: 'Picked by Rider',
                      subtitle: _order.isRiderBooked
                          ? 'Assigned to ${_order.assignedRiderName ?? "Zack Colah"}'
                          : 'Not assigned',
                      stepState: _order.isRiderBooked
                          ? TrackerStepState.active
                          : TrackerStepState.inactive,
                      showConnector: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Button (Single merged flow for Packing & Nearest Rider Assignment)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _handleMarkPackaged,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _order.isRiderBooked
                        ? const Color(0xFF10B981)
                        : const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _order.isRiderBooked
                        ? 'Rider Assigned • View Pickup OTP (${_order.pickupOtp})'
                        : (_order.isPackaged
                            ? 'Packed • Assign Rider'
                            : 'Mark as Packed'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLaundryItemRow(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackerStep({
    required String title,
    required String subtitle,
    required TrackerStepState stepState,
    required bool showConnector,
  }) {
    Color dotColor;
    Color titleColor;
    Color subtitleColor;

    switch (stepState) {
      case TrackerStepState.completed:
        dotColor = const Color(0xFF10B981);
        titleColor = const Color(0xFF0F172A);
        subtitleColor = const Color(0xFF64748B);
        break;
      case TrackerStepState.active:
        dotColor = const Color(0xFF2563EB);
        titleColor = const Color(0xFF2563EB);
        subtitleColor = const Color(0xFF2563EB);
        break;
      case TrackerStepState.inactive:
        dotColor = const Color(0xFFCBD5E1);
        titleColor = const Color(0xFF64748B);
        subtitleColor = const Color(0xFF94A3B8);
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: stepState == TrackerStepState.inactive
                      ? Colors.transparent
                      : dotColor,
                  shape: BoxShape.circle,
                  border: stepState == TrackerStepState.inactive
                      ? Border.all(color: dotColor, width: 2)
                      : null,
                ),
              ),
              if (showConnector)
                Expanded(
                  child: Container(
                    width: 2,
                    color: stepState == TrackerStepState.completed
                        ? const Color(0xFF10B981)
                        : const Color(0xFFE2E8F0),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Padding(
            padding: const EdgeInsets.only(bottom: 22.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBtn(String targetStatus, String label) {
    final bool isCurrent = _order.status == targetStatus;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: isCurrent ? const Color(0xFF2563EB) : Colors.white,
        foregroundColor: isCurrent ? Colors.white : const Color(0xFF0F172A),
        side: BorderSide(
          color: isCurrent ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      onPressed: () async {
        try {
          final id = (_order.rawId != null && _order.rawId!.isNotEmpty)
              ? _order.rawId!
              : _order.orderId.replaceFirst('#', '');
          await VendorOrderService.instance.updateOrderStatus(id, targetStatus);
          setState(() {
            _order.status = targetStatus;
            if (targetStatus == 'READY') {
              _order.isPackaged = true;
            }
          });
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order status updated to $label'),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 2),
            ),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update status: $e'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      },
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

enum TrackerStepState {
  completed,
  active,
  inactive,
}
