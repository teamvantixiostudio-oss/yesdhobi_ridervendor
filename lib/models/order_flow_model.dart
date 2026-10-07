enum DeliveryStage {
  accepted,
  pickedUp,
  outForDrop,
  delivered,
}

class LaundryItem {
  final String id;
  final String category;
  final double quantity;
  final double rate;
  final String unit;
  final String? imagePath;
  final String title;

  LaundryItem({
    required this.id,
    required this.category,
    required this.quantity,
    required this.rate,
    this.unit = 'kg',
    this.imagePath,
    required this.title,
  });

  // Backwards compatibility helpers
  double get weight => quantity;
  double get ratePerKg => rate;
  double get totalPrice => quantity * rate;
}

class OrderFlowState {
  String orderId;
  String? rawOrderId;
  String customerName;
  String customerAddress;
  String deliveryAddress;
  String customerInitials;
  String customerPhone;
  double customerRating;
  String customerAvatarUrl;
  String estimatedLoad;
  String travelDistance;
  String estimatedTime;
  String payout;
  double estimatedPrice;
  String vendorName;
  double vendorRating;
  String vendorTag;
  String vendorAddress;
  String vendorPhone;
  String itemsQuantityText;
  DeliveryStage stage;
  List<LaundryItem> items;
  String customerOtp;
  String vendorOtp;
  String dropoffTime;
  double? pickupLatitude;
  double? pickupLongitude;
  double? vendorLatitude;
  double? vendorLongitude;
  String? rawStatus;
  String myLeg;

  bool get isDeliveryLeg => myLeg == 'DELIVERY';

  OrderFlowState({
    this.orderId = '#YD-90823',
    this.rawOrderId,
    this.customerName = 'Rahul Sharma',
    this.customerAddress = 'B-402, Shanti Vihar, Sector 45',
    this.deliveryAddress = 'Yes Dhobi Hub, Sector 44 Branch',
    this.customerInitials = 'RS',
    this.customerPhone = '+91 98765 43210',
    this.customerRating = 4.9,
    this.customerAvatarUrl = '',
    this.estimatedLoad = '12-15 Items (Approx. 4kg)',
    this.travelDistance = '2.8 km total',
    this.estimatedTime = '15-20 Mins',
    this.payout = '₹65.00',
    this.estimatedPrice = 450.0,
    this.vendorName = 'Star Bright Laundry',
    this.vendorRating = 4.9,
    this.vendorTag = 'Professional Partner',
    this.vendorAddress = 'Shop No. 12, Sector 15, HSR Layout, Bengaluru',
    this.vendorPhone = '+91 91234 56789',
    this.itemsQuantityText = '12-15 items (Wash & Fold)',
    this.stage = DeliveryStage.accepted,
    List<LaundryItem>? items,
    this.customerOtp = '5812',
    this.vendorOtp = '5812',
    this.dropoffTime = '10:45 AM',
    this.pickupLatitude = 12.9352,
    this.pickupLongitude = 77.6245,
    this.vendorLatitude = 12.9121,
    this.vendorLongitude = 77.6446,
    this.rawStatus,
    this.myLeg = 'PICKUP',
  }) : items = items ?? [];

  factory OrderFlowState.fromApiJson(Map<String, dynamic> json) {
    final rawId = json['id']?.toString() ?? '';
    final orderNum = json['orderNumber'] != null ? '#YD-${json['orderNumber']}' : (rawId.length > 8 ? '#YD-${rawId.substring(0, 8)}' : '#YD-$rawId');
    final customer = json['customer'] as Map<String, dynamic>?;
    final custUser = customer?['user'] as Map<String, dynamic>?;
    final custName = custUser?['name']?.toString() ?? json['customerName']?.toString() ?? 'Customer';
    final custPhone = custUser?['phone']?.toString() ?? json['customerPhone']?.toString() ?? '';

    final address = json['address'] as Map<String, dynamic>?;
    final custAddr = address != null ? [address['line1'], address['line2'], address['city']].where((s) => s != null && s.toString().isNotEmpty).join(', ') : 'Customer Address';

    final vendor = json['vendor'] as Map<String, dynamic>?;
    final vName = vendor?['name']?.toString() ?? vendor?['shopName']?.toString() ?? 'Star Bright Laundry';
    final vAddr = vendor?['address']?.toString() ?? vendor?['shopAddress']?.toString() ?? 'Partner Shop Address';
    final vPhone = vendor?['phone']?.toString() ?? '+91 91234 56789';
    final vRating = (vendor?['rating'] as num?)?.toDouble() ?? 4.9;
    final vLat = (vendor?['lat'] as num?)?.toDouble() ?? (vendor?['latitude'] as num?)?.toDouble() ?? 12.9121;
    final vLng = (vendor?['lng'] as num?)?.toDouble() ?? (vendor?['longitude'] as num?)?.toDouble() ?? 77.6446;

    final itemsList = (json['items'] is List) ? (json['items'] as List) : [];
    final count = itemsList.fold<int>(0, (sum, it) => sum + ((it['quantity'] as num?)?.toInt() ?? 1));
    final sSummary = json['serviceSummary']?.toString() ?? (itemsList.isNotEmpty ? itemsList[0]['service']?.toString() ?? 'Wash & Care' : 'Wash & Care');

    final status = (json['status']?.toString() ?? 'ASSIGNED').toUpperCase();
    final leg = json['myLeg']?.toString().toUpperCase() ??
        (['READY', 'OUT_FOR_DELIVERY', 'DELIVERED'].contains(status) ? 'DELIVERY' : 'PICKUP');

    DeliveryStage st = DeliveryStage.accepted;
    if (leg == 'DELIVERY') {
      if (status == 'OUT_FOR_DELIVERY') {
        st = DeliveryStage.outForDrop;
      } else if (status == 'DELIVERED') {
        st = DeliveryStage.delivered;
      } else {
        st = DeliveryStage.accepted;
      }
    } else {
      if (status == 'PICKED_UP' || status == 'IN_LAUNDRY') {
        st = DeliveryStage.pickedUp;
      } else if (status == 'READY' || status == 'OUT_FOR_DELIVERY') {
        st = DeliveryStage.outForDrop;
      } else if (status == 'DELIVERED') {
        st = DeliveryStage.delivered;
      }
    }

    final total = (json['finalAmount'] ?? json['totalAmount'] ?? json['total'] ?? 0);

    return OrderFlowState(
      orderId: orderNum,
      rawOrderId: rawId,
      customerName: custName,
      customerAddress: custAddr,
      customerPhone: custPhone,
      customerInitials: custName.isNotEmpty ? custName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase() : 'C',
      estimatedLoad: '$count Items ($sSummary)',
      vendorName: vName,
      vendorAddress: vAddr,
      vendorPhone: vPhone,
      vendorRating: vRating,
      vendorLatitude: vLat,
      vendorLongitude: vLng,
      estimatedPrice: (total as num).toDouble(),
      stage: st,
      customerOtp: json['customerPickupOtp']?.toString() ?? json['customerDeliveryOtp']?.toString() ?? '1234',
      vendorOtp: json['vendorDropOtp']?.toString() ?? json['vendorHandoverOtp']?.toString() ?? '1234',
      rawStatus: status,
      myLeg: leg,
    );
  }

  double get totalWeight =>
      items.where((item) => item.unit == 'kg').fold(0.0, (sum, item) => sum + item.quantity);

  double get totalPrice =>
      items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get totalActualPrice => totalPrice;

  double get washAndFoldTotal => items
      .where((item) => item.category == 'Wash & Fold')
      .fold(0.0, (sum, item) => sum + item.totalPrice);

  double get shoesTotal => items
      .where((item) => item.category == 'Shoes')
      .fold(0.0, (sum, item) => sum + item.totalPrice);

  double get dryCleanTotal => items
      .where((item) => item.category == 'Dry Clean')
      .fold(0.0, (sum, item) => sum + item.totalPrice);
}
