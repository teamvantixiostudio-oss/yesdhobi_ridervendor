import 'package:flutter/material.dart';
import 'package:yesdhobi_ridervendor/theme.dart';
import 'package:yesdhobi_ridervendor/models/order_flow_model.dart';
import 'package:yesdhobi_ridervendor/widgets/app_bottom_nav.dart';
import 'package:yesdhobi_ridervendor/screens/rider_order_details_screen.dart';
import 'package:yesdhobi_ridervendor/services/rider_api_service.dart';

class OrderHistoryItem {
  final String orderId;
  final String rawId;
  final String date;
  final DateTime? dateTime;
  final String status;
  final String fromAddress;
  final String toAddress;
  final String payout;
  final String customerName;

  const OrderHistoryItem({
    required this.orderId,
    required this.rawId,
    required this.date,
    this.dateTime,
    required this.status,
    required this.fromAddress,
    required this.toAddress,
    required this.payout,
    required this.customerName,
  });
}

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  String selectedDateFilter = 'Last 30 Days';
  String selectedStatusFilter = 'All Statuses';
  bool _isLoading = true;
  List<OrderHistoryItem> _allOrders = [];

  @override
  void initState() {
    super.initState();
    _loadHistoryOrders();
  }

  Future<void> _loadHistoryOrders() async {
    setState(() => _isLoading = true);
    try {
      final data = await RiderApiService.instance.getRiderOrders(status: 'history');
      final mapped = <OrderHistoryItem>[];

      for (final raw in data) {
        final idStr = raw['id']?.toString() ?? '';
        final orderNum = raw['orderNumber']?.toString() ?? (idStr.length > 6 ? idStr.substring(0, 6) : idStr);
        final statusRaw = (raw['status']?.toString() ?? 'COMPLETED').toUpperCase();

        // Normalise status for rider display
        final displayStatus = (statusRaw == 'DELIVERED') ? 'COMPLETED' : statusRaw;

        final rawDate = raw['createdAt']?.toString() ?? raw['updatedAt']?.toString();
        DateTime? parsedDt;
        String formattedDate = 'Recent';
        if (rawDate != null) {
          try {
            parsedDt = DateTime.parse(rawDate).toLocal();
            formattedDate = _formatDate(parsedDt);
          } catch (_) {}
        }

        final customer = raw['customer'] as Map<String, dynamic>?;
        final customerName = customer?['name']?.toString() ?? 'Customer';

        final pAddr = raw['pickupAddress'] as Map<String, dynamic>?;
        final dAddr = raw['deliveryAddress'] as Map<String, dynamic>?;
        final vendor = raw['vendor'] as Map<String, dynamic>?;

        final fromAddress = pAddr?['formattedAddress']?.toString() ??
            pAddr?['street']?.toString() ??
            '$customerName (Pickup)';

        final toAddress = dAddr?['formattedAddress']?.toString() ??
            vendor?['shopName']?.toString() ??
            'Delivery Address';

        final fee = (raw['pickupFee'] ?? raw['deliveryFee'] ?? 60.0) as num;
        final payout = '₹${fee.toDouble().toStringAsFixed(2)}';

        mapped.add(
          OrderHistoryItem(
            orderId: orderNum.startsWith('#') ? orderNum : '#$orderNum',
            rawId: idStr,
            date: formattedDate,
            dateTime: parsedDt,
            status: displayStatus,
            fromAddress: fromAddress,
            toAddress: toAddress,
            payout: payout,
            customerName: customerName,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _allOrders = mapped;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final daySuffix = _daySuffix(dt.day);
    return '${dt.day}$daySuffix ${months[dt.month - 1]} ${dt.year}';
  }

  static String _daySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  List<OrderHistoryItem> get filteredOrders {
    final now = DateTime.now();

    return _allOrders.where((order) {
      // 1. Status Filter
      if (selectedStatusFilter != 'All Statuses') {
        if (order.status != selectedStatusFilter) {
          return false;
        }
      }

      // 2. Date Filter
      if (order.dateTime != null) {
        if (selectedDateFilter == 'Last 7 Days') {
          if (now.difference(order.dateTime!).inDays > 7) return false;
        } else if (selectedDateFilter == 'Last 30 Days') {
          if (now.difference(order.dateTime!).inDays > 30) return false;
        }
      }

      return true;
    }).toList();
  }

  void _openOrderDetails(OrderHistoryItem item) {
    final state = OrderFlowState(
      orderId: item.orderId,
      customerName: item.customerName,
      customerAddress: item.fromAddress,
      deliveryAddress: item.toAddress,
      payout: item.payout,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RiderOrderDetailsScreen(orderState: state),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = filteredOrders;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHistoryOrders,
          color: AppTheme.primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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

                // Title and Subtitle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Order History',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Overview of all your past orders',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    if (_isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      ),
                  ],
                ),
                const SizedBox(height: 18),

                // Filters Row
                Row(
                  children: [
                    // Filter 1: Date Dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedDateFilter,
                            isDense: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                color: Color(0xFF64748B), size: 20),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  selectedDateFilter = val;
                                });
                              }
                            },
                            items: const [
                              DropdownMenuItem(
                                value: 'Last 30 Days',
                                child: Text('Last 30 Days'),
                              ),
                              DropdownMenuItem(
                                value: 'Last 7 Days',
                                child: Text('Last 7 Days'),
                              ),
                              DropdownMenuItem(
                                value: 'All Time',
                                child: Text('All Time'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Filter 2: Status Dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedStatusFilter,
                            isDense: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                color: Color(0xFF64748B), size: 20),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  selectedStatusFilter = val;
                                });
                              }
                            },
                            items: const [
                              DropdownMenuItem(
                                value: 'All Statuses',
                                child: Text('All Statuses'),
                              ),
                              DropdownMenuItem(
                                value: 'COMPLETED',
                                child: Text('Completed'),
                              ),
                              DropdownMenuItem(
                                value: 'CANCELLED',
                                child: Text('Cancelled'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Orders List
                if (orders.isNotEmpty)
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: orders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (ctx, index) {
                      final order = orders[index];
                      final isCompleted = order.status == 'COMPLETED';

                      return InkWell(
                        onTap: () => _openOrderDetails(order),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header: ID and Date
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        order.orderId,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        order.date,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isCompleted
                                          ? const Color(0xFFECFDF5)
                                          : const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      order.status,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isCompleted
                                          ? const Color(0xFF059669)
                                          : const Color(0xFFDC2626),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // From Address
                              Text(
                                'From: ${order.fromAddress}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF334155),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // To Address
                              Text(
                                'To: ${order.toAddress}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF334155),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 14),

                              const Divider(height: 1, color: Color(0xFFF1F5F9)),
                              const SizedBox(height: 12),

                              // Payout Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Earnings Payout',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    order.payout,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isCompleted
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded, size: 44, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'No Orders Found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isLoading
                              ? 'Fetching order records...'
                              : 'You do not have any past orders matching the selected filter.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}
