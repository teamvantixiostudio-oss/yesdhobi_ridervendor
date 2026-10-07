import 'package:flutter/material.dart';
import 'package:yesdhobi_ridervendor/theme.dart';
import 'package:yesdhobi_ridervendor/widgets/vendor_bottom_nav.dart';
import 'package:yesdhobi_ridervendor/widgets/vendor_persistent_otp_banner.dart';
import 'package:yesdhobi_ridervendor/services/vendor_order_service.dart';

class VendorEarningsScreen extends StatefulWidget {
  const VendorEarningsScreen({super.key});

  @override
  State<VendorEarningsScreen> createState() => _VendorEarningsScreenState();
}

class _VendorEarningsScreenState extends State<VendorEarningsScreen> {
  String selectedPeriod = 'This Week';
  bool _isLoading = true;
  bool _isRequestingPayout = false;
  Map<String, dynamic>? _earningsData;

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    setState(() => _isLoading = true);
    try {
      final res = await VendorOrderService.instance.getEarnings();
      if (mounted) {
        setState(() {
          _earningsData = res;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get netEarnings {
    if (_earningsData != null) {
      final key = selectedPeriod == 'Today'
          ? 'today'
          : (selectedPeriod == 'This Month' ? 'month' : 'week');
      final amt = (_earningsData![key]?['amount'] as num?)?.toDouble() ?? 0.0;
      return '₹${amt.toStringAsFixed(2)}';
    }
    return '₹0.00';
  }

  String get ordersProcessed {
    if (_earningsData != null) {
      final key = selectedPeriod == 'Today'
          ? 'today'
          : (selectedPeriod == 'This Month' ? 'month' : 'week');
      final count = (_earningsData![key]?['orders'] as num?)?.toInt() ?? 0;
      return '$count';
    }
    return '0';
  }

  String get avgOrderValue {
    if (_earningsData != null) {
      final key = selectedPeriod == 'Today'
          ? 'today'
          : (selectedPeriod == 'This Month' ? 'month' : 'week');
      final avg = (_earningsData![key]?['averageValue'] as num?)?.toDouble() ?? 0.0;
      return '₹${avg.toStringAsFixed(2)}';
    }
    return '₹0.00';
  }

  double get outstandingBalance {
    return (_earningsData?['outstanding'] as num?)?.toDouble() ?? 0.0;
  }

  String get nextPayoutDateText {
    final nextDateStr = _earningsData?['nextPayoutDate']?.toString();
    if (nextDateStr != null) {
      try {
        final dt = DateTime.parse(nextDateStr).toLocal();
        final months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        return 'Next Payout Date: ${dt.day} ${months[dt.month - 1]}';
      } catch (_) {}
    }
    return 'Next Payout Date: Upcoming Monday';
  }

  List<Map<String, dynamic>> get livePayoutHistory {
    final list = _earningsData?['payoutHistory'] as List?;
    if (list != null && list.isNotEmpty) {
      return list.map((e) => e as Map<String, dynamic>).toList();
    }
    return const [];
  }

  List<Map<String, dynamic>> get liveTransactions {
    final list = _earningsData?['transactions'] as List?;
    if (list != null && list.isNotEmpty) {
      return list.map((e) => e as Map<String, dynamic>).toList();
    }
    return const [];
  }

  Future<void> _handlePayoutRequest() async {
    final outstanding = outstandingBalance;
    if (outstanding <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pending payout balance available to request.'),
          backgroundColor: Color(0xFF64748B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isRequestingPayout = true);
    try {
      await VendorOrderService.instance.requestPayout(amount: outstanding);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Early payout request of ₹${outstanding.toStringAsFixed(2)} submitted successfully.',
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      await _loadEarnings();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payout request: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isRequestingPayout = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final payouts = livePayoutHistory;
    final transactions = liveTransactions;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadEarnings,
          color: AppTheme.primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Persistent OTP Banner
                const VendorPersistentOtpBanner(),

                // Header with refresh spinner if loading
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Earnings',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (_isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Period Filter
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      _buildPeriodTab('Today'),
                      _buildPeriodTab('This Week'),
                      _buildPeriodTab('This Month'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Selected Period Net Earnings Card (Blue)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${selectedPeriod.toUpperCase()} NET EARNINGS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withValues(alpha: 0.85),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        netEarnings,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Divider(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Orders Processed',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ordersProcessed,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Average Value',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                avgOrderValue,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Next Payout Card (Yellow Border / Styling)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nextPayoutDateText,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF92400E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${outstandingBalance.toStringAsFixed(2)} pending',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF78350F),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isRequestingPayout ? null : _handlePayoutRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isRequestingPayout
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Request Now',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Payout History Section
                const Text(
                  'Payout History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 14),

                if (payouts.isNotEmpty)
                  ...payouts.map((p) {
                    final pid = p['id']?.toString() ?? '';
                    final shortId = pid.length > 6 ? '#PAY-${pid.substring(0, 6)}' : '#PAY-$pid';
                    final amt = (p['amount'] as num?)?.toDouble() ?? 0.0;
                    final status = p['status']?.toString() ?? 'Transferred';
                    final dateRaw = p['requestedAt']?.toString() ?? p['createdAt']?.toString();
                    String dateStr = 'Recent';
                    if (dateRaw != null) {
                      try {
                        final dt = DateTime.parse(dateRaw).toLocal();
                        dateStr = '${dt.day} ${_monthName(dt.month)} ${dt.year}';
                      } catch (_) {}
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildPayoutHistoryCard(
                        payoutId: shortId,
                        date: dateStr,
                        amount: '₹${amt.toStringAsFixed(2)}',
                        status: status,
                      ),
                    );
                  })
                else if (transactions.isNotEmpty)
                  ...transactions.map((t) {
                    final desc = t['description']?.toString() ?? 'Order Earnings';
                    final orderNum = t['orderNumber']?.toString();
                    final title = orderNum != null ? 'Order #$orderNum' : desc;
                    final amt = (t['amount'] as num?)?.toDouble() ?? 0.0;
                    final dateRaw = t['createdAt']?.toString();
                    String dateStr = 'Recent';
                    if (dateRaw != null) {
                      try {
                        final dt = DateTime.parse(dateRaw).toLocal();
                        dateStr = '${dt.day} ${_monthName(dt.month)} ${dt.year}';
                      } catch (_) {}
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildPayoutHistoryCard(
                        payoutId: title,
                        date: dateStr,
                        amount: '₹${amt.toStringAsFixed(2)}',
                        status: 'Credited',
                      ),
                    );
                  })
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet_outlined,
                            size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'No Payouts Yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Earnings are automatically transferred weekly or can be requested early when pending balance is available.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
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
      bottomNavigationBar: const VendorBottomNav(currentIndex: 2),
    );
  }

  static String _monthName(int month) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return (month >= 1 && month <= 12) ? m[month - 1] : '';
  }

  Widget _buildPeriodTab(String title) {
    final isSelected = selectedPeriod == title;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedPeriod = title;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPayoutHistoryCard({
    required String payoutId,
    required String date,
    required String amount,
    required String status,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                payoutId,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                date,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: status.toLowerCase().contains('transfer') || status.toLowerCase().contains('credit')
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
