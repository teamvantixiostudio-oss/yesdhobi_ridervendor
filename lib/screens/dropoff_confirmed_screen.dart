import 'package:flutter/material.dart';
import 'package:yesdhobi_ridervendor/theme.dart';
import 'package:yesdhobi_ridervendor/models/order_flow_model.dart';
import 'package:yesdhobi_ridervendor/widgets/app_bottom_nav.dart';
import 'package:yesdhobi_ridervendor/screens/rider_dashboard_screen.dart';
import 'package:yesdhobi_ridervendor/screens/rider_earnings_screen.dart';

class DropoffConfirmedScreen extends StatelessWidget {
  final OrderFlowState? orderState;

  const DropoffConfirmedScreen({
    super.key,
    this.orderState,
  });

  @override
  Widget build(BuildContext context) {
    final state = orderState ??
        OrderFlowState(
          orderId: '#YD-9612',
          customerName: 'Amit Patel',
          vendorName: 'Star Bright Laundry',
          itemsQuantityText: '5 items',
          dropoffTime: '10:45 AM',
        );

    final vendorName = state.vendorName.isNotEmpty
        ? state.vendorName
        : 'Star Bright Laundry';
    final customerName = state.customerName.isNotEmpty
        ? state.customerName
        : 'Amit Patel';
    final orderId = state.orderId.isNotEmpty ? state.orderId : '#YD-9612';
    final itemsCountText = state.items.isNotEmpty
        ? '${state.items.length} items'
        : (state.itemsQuantityText.contains('5 items')
            ? '5 items'
            : state.itemsQuantityText);
    final dropoffTime =
        state.dropoffTime.isNotEmpty ? state.dropoffTime : '10:45 AM';

    final bool isCustomerDelivered = state.rawStatus == 'DELIVERED' ||
        (state.isDeliveryLeg && state.stage == DeliveryStage.delivered);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RiderDashboardScreen()),
          (route) => false,
        );
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),

                      // Success Circle with Glowing Effect
                      Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(0.15),
                                blurRadius: 20,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      Text(
                        isCustomerDelivered ? 'Delivery Completed!' : 'Drop-off Confirmed!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Subtitle
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          isCustomerDelivered
                              ? 'Clean clothes have been successfully delivered to $customerName'
                              : 'Clothes have been successfully handed over to $vendorName',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                            height: 1.45,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Handover Summary Card
                      Container(
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isCustomerDelivered ? 'DELIVERY SUMMARY' : 'HANDOVER SUMMARY',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF94A3B8),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 16),

                            _buildSummaryRow(
                              label: 'Order ID',
                              value: orderId,
                              valueColor: AppTheme.primaryColor,
                            ),
                            const Divider(height: 24, color: Color(0xFFF1F5F9)),

                            _buildSummaryRow(
                              label: 'Customer',
                              value: customerName,
                            ),
                            const Divider(height: 24, color: Color(0xFFF1F5F9)),

                            if (!isCustomerDelivered) ...[
                              _buildSummaryRow(
                                label: 'Partner Shop',
                                value: vendorName,
                              ),
                              const Divider(height: 24, color: Color(0xFFF1F5F9)),
                            ],

                            _buildSummaryRow(
                              label: 'Items',
                              value: itemsCountText,
                            ),
                            const Divider(height: 24, color: Color(0xFFF1F5F9)),

                            _buildSummaryRow(
                              label: isCustomerDelivered ? 'Delivery Time' : 'Drop-off Time',
                              value: dropoffTime,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Action 1: Back to Home (Filled Royal Blue Button)
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const RiderDashboardScreen(),
                              ),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Back to Home',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Action 2: View Earnings (Outlined Royal Blue Button)
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RiderEarningsScreen(),
                              ),
                            );
                          },
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
                          child: const Text(
                            'View Earnings',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    Color valueColor = const Color(0xFF0F172A),
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}
