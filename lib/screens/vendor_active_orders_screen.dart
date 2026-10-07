import 'package:flutter/material.dart';
import 'package:yesdhobi_ridervendor/widgets/custom_back_button.dart';
import 'package:yesdhobi_ridervendor/widgets/vendor_bottom_nav.dart';
import 'package:yesdhobi_ridervendor/screens/vendor_order_details_screen.dart';
import 'package:yesdhobi_ridervendor/models/vendor_order_model.dart';
import 'package:yesdhobi_ridervendor/services/vendor_order_service.dart';
import 'package:yesdhobi_ridervendor/widgets/vendor_persistent_otp_banner.dart';

class VendorActiveOrdersScreen extends StatefulWidget {
  const VendorActiveOrdersScreen({super.key});

  @override
  State<VendorActiveOrdersScreen> createState() =>
      _VendorActiveOrdersScreenState();
}

class _VendorActiveOrdersScreenState extends State<VendorActiveOrdersScreen> {
  String selectedTab = 'In Progress';

  @override
  void initState() {
    super.initState();
    VendorOrderService.instance.fetchOrders();
  }

  List<VendorOrderModel> _getFilteredOrders(List<VendorOrderModel> allOrders) {
    if (selectedTab == 'In Progress') {
      return allOrders
          .where((o) => !o.isPackaged && !o.isCompleted)
          .toList();
    } else if (selectedTab == 'Ready') {
      return allOrders
          .where((o) => o.isPackaged && !o.isRiderBooked && !o.isCompleted)
          .toList();
    } else {
      // Out for Delivery
      return allOrders
          .where((o) => o.isRiderBooked && !o.isCompleted)
          .toList();
    }
  }

  double _getProgress(VendorOrderModel order) {
    if (order.isCompleted) return 1.0;
    if (order.isRiderBooked) return 0.9;
    if (order.isPackaged) return 0.65;
    return 0.35;
  }

  String _getEstTime(VendorOrderModel order) {
    if (order.isCompleted) return 'Delivered & Handover Complete';
    if (order.isRiderBooked) {
      return 'Out with Rider ${order.assignedRiderName ?? "Zack Colah"}';
    }
    if (order.isPackaged) return 'Ready for Rider Pickup';
    return 'Est: 2 hrs remaining';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: VendorOrderService.instance.orderUpdateNotifier,
      builder: (context, _, child) {
        final allOrders = VendorOrderService.instance.orders;
        final filteredOrders = _getFilteredOrders(allOrders);

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF8FAFC),
            elevation: 0,
            leading: const CustomBackButton(),
            title: const Text(
              'Active Tasks',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Persistent OTP Popup Banner
                const VendorPersistentOtpBanner(),

                // Tabs Bar
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildTab('In Progress'),
                      _buildTab('Ready'),
                      _buildTab('Out for Delivery'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Tasks List
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => VendorOrderService.instance.fetchOrders(),
                    child: filteredOrders.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      0.25),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.assignment_turned_in_outlined,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No tasks in "$selectedTab"',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 10.0),
                            itemCount: filteredOrders.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 14),
                          itemBuilder: (ctx, index) {
                            final order = filteredOrders[index];
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VendorOrderDetailsScreen(
                                      order: order,
                                      orderId: order.orderId,
                                      customerName: order.customerName,
                                      customerPhone: order.customerPhone,
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: const Color(0xFFF1F5F9)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          order.orderId,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        Text(
                                          '${order.itemCount} Items',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      order.customerName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Progress bar
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: _getProgress(order),
                                        minHeight: 5,
                                        backgroundColor:
                                            const Color(0xFFF1F5F9),
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                          Color(0xFF2563EB),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    Text(
                                      _getEstTime(order),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: const VendorBottomNav(currentIndex: 1),
        );
      },
    );
  }

  Widget _buildTab(String title) {
    final isSelected = selectedTab == title;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = title;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color:
                    isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }
}
