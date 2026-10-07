class VendorServiceModel {
  final String id;
  String name;
  bool isEnabled;
  double price;
  String unit; // 'kg', 'piece', 'pair', 'item'
  final bool isCustom;
  final int? serviceCategoryId;

  VendorServiceModel({
    required this.id,
    required this.name,
    required this.isEnabled,
    required this.price,
    required this.unit,
    this.isCustom = false,
    this.serviceCategoryId,
  });

  factory VendorServiceModel.fromApiJson(Map<String, dynamic> json) {
    final catId = json['serviceCategoryId'] is int ? json['serviceCategoryId'] as int : null;
    final rawId = json['id']?.toString();
    return VendorServiceModel(
      id: (rawId != null && rawId.isNotEmpty) ? rawId : (catId != null ? 'cat_$catId' : 'svc_${DateTime.now().millisecondsSinceEpoch}'),
      name: json['name']?.toString() ?? 'Service',
      isEnabled: json['isEnabled'] == true,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit']?.toString() ?? 'kg',
      isCustom: json['isCustom'] == true,
      serviceCategoryId: catId,
    );
  }

  String get formattedPrice {
    final priceStr =
        price % 1 == 0 ? price.toInt().toString() : price.toStringAsFixed(2);
    return '₹$priceStr / $unit';
  }

  VendorServiceModel copyWith({
    String? id,
    String? name,
    bool? isEnabled,
    double? price,
    String? unit,
    bool? isCustom,
    int? serviceCategoryId,
  }) {
    return VendorServiceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isEnabled: isEnabled ?? this.isEnabled,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      isCustom: isCustom ?? this.isCustom,
      serviceCategoryId: serviceCategoryId ?? this.serviceCategoryId,
    );
  }
}
