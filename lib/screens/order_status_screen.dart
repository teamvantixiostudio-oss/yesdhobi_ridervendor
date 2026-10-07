import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yesdhobi_ridervendor/theme.dart';
import 'package:yesdhobi_ridervendor/models/order_flow_model.dart';
import 'package:yesdhobi_ridervendor/widgets/custom_back_button.dart';
import 'package:yesdhobi_ridervendor/widgets/app_bottom_nav.dart';
import 'package:yesdhobi_ridervendor/widgets/order_progress_stepper.dart';
import 'package:yesdhobi_ridervendor/widgets/vendor_card.dart';
import 'package:yesdhobi_ridervendor/widgets/order_info_card.dart';
import 'package:yesdhobi_ridervendor/screens/confirm_vendor_dropoff_screen.dart';

import 'package:yesdhobi_ridervendor/services/rider_api_service.dart';

class OrderStatusScreen extends StatefulWidget {
  final OrderFlowState? orderState;

  const OrderStatusScreen({
    super.key,
    this.orderState,
  });

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  late OrderFlowState _state;

  @override
  void initState() {
    super.initState();
    _state = widget.orderState ??
        OrderFlowState(
          orderId: '#YD-20240318-001',
          customerName: 'Sneha Kapoor',
          itemsQuantityText: '8-12 items (Premium Care)',
          vendorName: 'CleanPro Laundry Services',
          vendorRating: 4.8,
          vendorTag: '(Trusted Partner)',
          vendorAddress: 'Shop 12, Market Complex, Sector 22, Noida',
          stage: DeliveryStage.outForDrop,
        );
    _fetchFreshOrderDetails();
  }

  Future<void> _fetchFreshOrderDetails() async {
    final rawId = (_state.rawOrderId != null && _state.rawOrderId!.isNotEmpty)
        ? _state.rawOrderId!
        : _state.orderId.replaceFirst('#', '');
    if (rawId.isNotEmpty) {
      try {
        final orderData =
            await RiderApiService.instance.getRiderOrderDetails(rawId);
        if (orderData.isNotEmpty && mounted) {
          setState(() {
            _state = OrderFlowState.fromApiJson(orderData);
            _state.stage = DeliveryStage.outForDrop;
          });
        }
      } catch (e) {
        debugPrint('Refreshing live vendor details note: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const CustomBackButton(),
        title: const Text(
          'Order Status',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Delivery Progress Card
              OrderProgressStepper(
                currentStage: state.stage,
              ),
              const SizedBox(height: 16),

              // Drop-off Destination Card
              VendorCard(
                sectionTitle: 'DROP-OFF DESTINATION',
                vendorName: state.vendorName.isNotEmpty
                    ? state.vendorName
                    : 'CleanPro Laundry Services',
                rating: state.vendorRating,
                tag: state.vendorTag,
                address: state.vendorAddress,
                useStorefrontIcon: false,
                onCallTap: () async {
                  if (state.vendorPhone.isNotEmpty) {
                    final cleanPhone = state.vendorPhone.replaceAll(RegExp(r'[^\d+]'), '');
                    final telUri = Uri.parse('tel:$cleanPhone');
                    try {
                      if (await canLaunchUrl(telUri)) {
                        await launchUrl(telUri);
                        return;
                      }
                    } catch (_) {}
                  }
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Calling ${state.vendorName}...'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Order Information Card
              OrderInfoCard(
                orderId: state.orderId == '#YD-8924'
                    ? '#YD-20240318-001'
                    : state.orderId,
                customerName: state.customerName == 'Aarav Sharma'
                    ? 'Sneha Kapoor'
                    : state.customerName,
                itemsQuantity: state.itemsQuantityText,
              ),
              const SizedBox(height: 24),

              // Action Button 1: Navigate to Vendor
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: () => _launchVendorMaps(
                    state.vendorLatitude,
                    state.vendorLongitude,
                    state.vendorAddress,
                  ),
                  icon: const Icon(
                    Icons.navigation_outlined,
                    size: 20,
                    color: AppTheme.primaryColor,
                  ),
                  label: const Text(
                    'Navigate to Vendor',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
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
              const SizedBox(height: 14),

              // Action Button 2: Confirm Drop-off (Primary Action)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ConfirmVendorDropoffScreen(
                          orderState: state,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.check,
                    size: 20,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Confirm Drop-off',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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

  Future<void> _launchVendorMaps(
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
}
