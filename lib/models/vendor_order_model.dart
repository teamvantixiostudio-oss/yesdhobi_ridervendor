class VendorOrderModel {
  final String orderId;
  final String? rawId;
  final String customerName;
  final String customerPhone;
  final String customerInitials;
  final String serviceType;
  final int itemCount;
  final String itemsDescription;
  final String pickupPointName;
  final String pickupAddress;
  final String dropoffPointName;
  final String dropoffAddress;
  final String distanceText;
  final String estimatedTimeText;
  final String estimatedWeightText;
  bool isPackaged;
  bool isRiderBooked;
  bool isCompleted;
  String? assignedRiderName;
  String deliveryOption; // 'Standard' or 'Express'
  String? riderNotes;
  String pickupOtp;
  String dropoffOtp;
  String handoverOtp;
  String status;
  final List<Map<String, dynamic>> itemsList;

  VendorOrderModel({
    required this.orderId,
    this.rawId,
    required this.customerName,
    required this.customerPhone,
    String? customerInitials,
    this.serviceType = 'Premium Wash & Iron',
    this.itemCount = 6,
    this.itemsDescription = '6 Items • Premium Wash & Iron',
    this.pickupPointName = 'Yes Dhobi Partner Shop',
    this.pickupAddress = 'Shop Address',
    this.dropoffPointName = 'Customer Address',
    this.dropoffAddress = 'Customer Delivery Address',
    this.distanceText = '4.2 km',
    this.estimatedTimeText = '~15 min',
    this.estimatedWeightText = '~3.5 kg',
    this.isPackaged = false,
    this.isRiderBooked = false,
    this.isCompleted = false,
    this.assignedRiderName,
    this.deliveryOption = 'Standard',
    this.riderNotes,
    this.pickupOtp = '5831',
    this.dropoffOtp = '',
    this.handoverOtp = '',
    this.status = 'IN_LAUNDRY',
    this.itemsList = const [],
  }) : customerInitials = customerInitials ??
            (customerName.isNotEmpty
                ? customerName
                    .split(' ')
                    .where((e) => e.isNotEmpty)
                    .map((e) => e[0])
                    .take(2)
                    .join()
                    .toUpperCase()
                : 'C');

  factory VendorOrderModel.fromApiJson(Map<String, dynamic> json) {
    final rawId = json['id']?.toString() ?? '';
    final orderNum = json['orderNumber'] != null ? '#YD-${json['orderNumber']}' : (rawId.length > 8 ? '#YD-${rawId.substring(0, 8)}' : '#YD-$rawId');
    final customer = json['customer'] as Map<String, dynamic>?;
    final custUser = customer?['user'] as Map<String, dynamic>?;
    final custName = custUser?['name']?.toString() ?? json['customerName']?.toString() ?? 'Customer';
    final custPhone = custUser?['phone']?.toString() ?? json['customerPhone']?.toString() ?? '';

    final items = (json['items'] is List) ? (json['items'] as List) : [];
    final count = items.fold<int>(0, (sum, it) => sum + ((it['quantity'] as num?)?.toInt() ?? 1));
    final sSummary = json['serviceSummary']?.toString() ?? (items.isNotEmpty ? items[0]['service']?.toString() ?? 'Laundry Care' : 'Laundry Care');

    final status = (json['status']?.toString() ?? 'IN_LAUNDRY').toUpperCase();
    final bool isPackaged = status == 'READY' || status == 'OUT_FOR_DELIVERY' || status == 'DELIVERED';
    final bool isRiderBooked = json['deliveryRiderId'] != null || json['deliveryRider'] != null || status == 'OUT_FOR_DELIVERY' || status == 'DELIVERED';
    final bool isCompleted = status == 'DELIVERED';
    final rider = json['deliveryRider'] as Map<String, dynamic>?;
    final riderUser = rider?['user'] as Map<String, dynamic>?;
    final riderName = riderUser?['name']?.toString() ?? json['deliveryRider']?['name']?.toString();

    final address = json['address'] as Map<String, dynamic>?;
    final dropAddr = address != null ? [address['line1'], address['line2'], address['city']].where((s) => s != null && s.toString().isNotEmpty).join(', ') : 'Customer Delivery Address';

    final dropOtp = json['otps']?['riderDrop']?.toString() ??
                    json['vendorDropOtp']?.toString() ??
                    '';
    final handOtp = json['otps']?['riderHandover']?.toString() ??
                    json['vendorHandoverOtp']?.toString() ??
                    '';

    final isHandoverStage = isPackaged || isRiderBooked || status == 'READY' || status == 'OUT_FOR_DELIVERY';
    final activeOtp = isHandoverStage
        ? (handOtp.isNotEmpty ? handOtp : dropOtp)
        : (dropOtp.isNotEmpty ? dropOtp : handOtp);

    return VendorOrderModel(
      orderId: orderNum,
      rawId: rawId,
      customerName: custName,
      customerPhone: custPhone,
      serviceType: sSummary,
      itemCount: count > 0 ? count : 1,
      itemsDescription: '$count Items • $sSummary',
      pickupAddress: json['vendor']?['shopAddress']?.toString() ?? 'Shop Address',
      dropoffAddress: dropAddr,
      isPackaged: isPackaged,
      isRiderBooked: isRiderBooked,
      isCompleted: isCompleted,
      assignedRiderName: riderName,
      dropoffOtp: dropOtp,
      handoverOtp: handOtp,
      pickupOtp: activeOtp.isNotEmpty ? activeOtp : '5831',
      status: status,
      itemsList: items.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
    );
  }
}
