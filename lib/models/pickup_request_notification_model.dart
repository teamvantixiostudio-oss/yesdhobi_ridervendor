import 'package:yesdhobi_ridervendor/models/order_flow_model.dart';

enum PickupRequestStatus {
  pending,
  offered,
  accepted,
  declined,
  expired,
}

class PickupRequestNotificationModel {
  final String requestId;
  final String orderId;
  final String customerName;
  final String customerType;
  final String customerTag;
  final int previousOrdersCount;
  final String customerAvatarUrl;
  final String pickupAddress;
  final String pickupArea;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double distanceKm;
  final String estimatedItemsText;
  final double payout;
  final int totalSeconds;
  final DateTime createdAt;
  final DateTime expiresAt;
  PickupRequestStatus status;

  PickupRequestNotificationModel({
    required this.requestId,
    required this.orderId,
    required this.customerName,
    this.customerType = 'Regular Customer',
    this.customerTag = 'VIP',
    this.previousOrdersCount = 24,
    this.customerAvatarUrl = '',
    required this.pickupAddress,
    required this.pickupArea,
    this.pickupLatitude = 12.9352,
    this.pickupLongitude = 77.6245,
    this.distanceKm = 1.8,
    this.estimatedItemsText = '8–12 items',
    this.payout = 120.0,
    this.totalSeconds = 12,
    DateTime? createdAt,
    DateTime? expiresAt,
    this.status = PickupRequestStatus.offered,
  })  : createdAt = createdAt ?? DateTime.now(),
        expiresAt = expiresAt ??
            DateTime.now().add(Duration(seconds: totalSeconds));

  int get remainingSeconds {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return 0;
    return expiresAt.difference(now).inSeconds;
  }

  bool get isExpired => remainingSeconds <= 0 || status == PickupRequestStatus.expired;

  String get formattedPayout => '₹${payout.toInt()}';

  String get formattedDistance => '${distanceKm.toStringAsFixed(1)} km away';

  String get fullAddress => '$pickupAddress, $pickupArea';

  OrderFlowState toOrderFlowState() {
    return OrderFlowState(
      orderId: orderId,
      customerName: customerName,
      customerAddress: fullAddress,
      pickupLatitude: pickupLatitude,
      pickupLongitude: pickupLongitude,
      deliveryAddress: 'Yes Dhobi Hub, Sector 44 Branch',
      customerInitials: customerName.isNotEmpty
          ? customerName
              .split(' ')
              .where((e) => e.isNotEmpty)
              .map((e) => e[0])
              .take(2)
              .join()
              .toUpperCase()
          : 'SK',
      customerPhone: '+91 98765 43210',
      customerRating: 4.9,
      customerAvatarUrl: customerAvatarUrl,
      estimatedLoad: '$estimatedItemsText (Approx. 3.5kg)',
      travelDistance: '$distanceKm km total',
      estimatedTime: '15-20 Mins',
      payout: '₹${payout.toStringAsFixed(2)}',
      estimatedPrice: payout * 3.5,
      vendorName: 'Star Bright Laundry',
      vendorRating: 4.9,
      vendorTag: 'Professional Partner',
      vendorAddress: 'Shop No. 12, Sector 15, HSR Layout, Bengaluru',
      vendorPhone: '+91 91234 56789',
      itemsQuantityText: '$estimatedItemsText (Wash & Fold)',
      stage: DeliveryStage.accepted,
      customerOtp: '5831',
      vendorOtp: '5831',
      dropoffTime: '11:15 AM',
      items: [
        LaundryItem(
          id: 'item_1',
          category: 'Wash & Fold',
          quantity: 3.5,
          rate: 25.0,
          unit: 'kg',
          title: 'Mixed Clothes (Wash & Fold)',
        ),
      ],
    );
  }

  static PickupRequestNotificationModel createDefaultSample() {
    return PickupRequestNotificationModel(
      requestId: 'REQ-9624',
      orderId: '#YD-9624',
      customerName: 'Sneha Kapoor',
      customerType: 'Regular Customer',
      customerTag: 'VIP',
      previousOrdersCount: 24,
      pickupAddress: 'Flat 4B, Silver Oak Apartments',
      pickupArea: 'Sector 6, HSR Layout, Bengaluru',
      distanceKm: 1.8,
      estimatedItemsText: '8–12 items',
      payout: 120.0,
      totalSeconds: 15,
    );
  }

  factory PickupRequestNotificationModel.fromApiJson(Map<String, dynamic> json) {
    final pickup = json['pickup'] as Map<String, dynamic>? ?? {};
    final remaining = (json['remainingSeconds'] as num?)?.toInt() ?? 15;
    final payoutVal = (json['payout'] as num?)?.toDouble() ?? 65.0;
    final distVal = (json['distanceKm'] as num?)?.toDouble() ?? 2.5;

    DateTime? expDate;
    if (json['expiresAt'] != null) {
      expDate = DateTime.tryParse(json['expiresAt'].toString());
    }

    final ordNum = json['orderNumber']?.toString();
    final ordId = json['orderId']?.toString() ?? '';
    final displayId = ordNum != null ? '#YD-$ordNum' : (ordId.isNotEmpty ? '#YD-$ordId' : '#YD-10001');

    return PickupRequestNotificationModel(
      requestId: json['requestId']?.toString() ?? '',
      orderId: displayId,
      customerName: json['customerName']?.toString() ?? 'Customer',
      customerType: json['customerTier']?.toString() ?? 'Standard Customer',
      customerTag: json['leg'] == 'DELIVERY' ? 'Delivery Leg' : 'Pickup Leg',
      pickupAddress: pickup['address']?.toString() ?? 'Customer Address',
      pickupArea: pickup['name']?.toString() ?? '',
      pickupLatitude: (pickup['lat'] as num?)?.toDouble(),
      pickupLongitude: (pickup['lng'] as num?)?.toDouble(),
      distanceKm: distVal,
      estimatedItemsText: json['estimatedItemsText']?.toString() ?? '${json['serviceSummary'] ?? 'Laundry Items'}',
      payout: payoutVal,
      totalSeconds: remaining > 0 ? remaining : 15,
      expiresAt: expDate,
    );
  }
}
