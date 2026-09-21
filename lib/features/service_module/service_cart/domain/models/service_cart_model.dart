import 'package:sixam_mart/features/service_module/service_home/domain/models/service_model.dart';

/// Service Module — booking cart row. Served through core `customer/cart/*`
/// endpoints (dispatched by `moduleId` header). Each row represents one
/// `(service, variant_key)` pair; variant-less services have a null `variantKey`.
/// `price` is server-computed; `lineTotal` = price × quantity.
class ServiceCartModel {
  final int? id;
  final int? userId;
  final int? moduleId;
  final int? providerId;
  final int? serviceId;
  final bool? isGuest;
  final double? price;
  int? quantity;
  final double? lineTotal;
  final double? taxAmount;
  final double? taxPercent;
  final String? taxStatus;
  final String? variantKey;
  final ServiceCartVariation? variation;
  final String? createdAt;
  final String? updatedAt;
  final Service? service;

  ServiceCartModel({this.id, this.userId, this.moduleId, this.providerId, this.serviceId,
    this.isGuest, this.price, this.quantity, this.lineTotal, this.taxAmount, this.taxPercent,
    this.taxStatus, this.variantKey, this.variation, this.createdAt, this.updatedAt, this.service,
  });

  factory ServiceCartModel.fromJson(Map<String, dynamic> json) => ServiceCartModel(
    id: int.tryParse(json['id']?.toString() ?? ''),
    userId: int.tryParse(json['user_id']?.toString() ?? ''),
    moduleId: int.tryParse(json['module_id']?.toString() ?? ''),
    providerId: int.tryParse(json['provider_id']?.toString() ?? ''),
    serviceId: int.tryParse(json['service_id']?.toString() ?? ''),
    isGuest: json['is_guest'] == true || json['is_guest']?.toString() == '1',
    price: double.tryParse(json['price']?.toString() ?? ''),
    quantity: int.tryParse(json['quantity']?.toString() ?? ''),
    lineTotal: double.tryParse(json['line_total']?.toString() ?? ''),
    taxAmount: double.tryParse(json['tax_amount']?.toString() ?? ''),
    taxPercent: double.tryParse(json['tax_percent']?.toString() ?? ''),
    taxStatus: json['tax_status']?.toString(),
    variantKey: json['variant_key']?.toString(),
    variation: json['variation'] is Map<String, dynamic>
        ? ServiceCartVariation.fromJson(json['variation'] as Map<String, dynamic>)
        : null,
    createdAt: json['created_at']?.toString(),
    updatedAt: json['updated_at']?.toString(),
    service: json['service'] != null ? Service.fromJson(json['service'] as Map<String, dynamic>) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'module_id': moduleId,
    'provider_id': providerId,
    'service_id': serviceId,
    'is_guest': isGuest,
    'price': price,
    'quantity': quantity,
    'line_total': lineTotal,
    'tax_amount': taxAmount,
    'tax_percent': taxPercent,
    'tax_status': taxStatus,
    'variant_key': variantKey,
    'variation': variation?.toJson(),
    'created_at': createdAt,
    'updated_at': updatedAt,
    'service': service?.toJson(),
  };
}

/// The selected variation stored on a booking-cart row.
/// Shape matches the server response: `{variant_key, name, price, discount, discount_type}`.
class ServiceCartVariation {
  final String? variantKey;
  final String? name;
  final double? price;
  final double? discount;
  final String? discountType;

  ServiceCartVariation({this.variantKey, this.name, this.price, this.discount, this.discountType});

  factory ServiceCartVariation.fromJson(Map<String, dynamic> json) => ServiceCartVariation(
    variantKey: json['variant_key']?.toString(),
    name: json['name']?.toString(),
    price: double.tryParse(json['price']?.toString() ?? ''),
    discount: double.tryParse(json['discount']?.toString() ?? ''),
    discountType: json['discount_type']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'variant_key': variantKey, 'name': name, 'price': price,
    'discount': discount, 'discount_type': discountType,
  };
}
