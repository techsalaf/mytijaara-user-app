import 'package:sixam_mart/features/service_module/service_home/domain/models/service_model.dart';

class BookingLineItemModel {
  int? id;
  int? serviceId;
  int? serviceCampaignId;
  bool? isCampaign;
  String? serviceName;
  bool? isCustom;
  int? categoryId;
  int? subCategoryId;
  int? quantity;
  double? price;
  double? originalPrice;
  double? calculatedPrice;
  double? discountAmount;
  String? discountType;
  String? discountBy;
  double? discountPercentage;
  double? taxAmount;
  double? taxPercentage;
  String? taxStatus;
  List<ServiceVariation>? variation;
  String? description;
  String? imageFullUrl;

  BookingLineItemModel({this.id, this.serviceId, this.serviceCampaignId, this.isCampaign, this.serviceName, this.isCustom,
    this.categoryId, this.subCategoryId, this.quantity, this.price, this.originalPrice, this.calculatedPrice,
    this.discountAmount, this.discountType, this.discountBy, this.discountPercentage, this.taxAmount, this.taxPercentage,
    this.taxStatus, this.variation, this.description, this.imageFullUrl,
  });

  // The booking API is inconsistent about where the service image lands on a
  // line item, so accept the known shapes rather than one fixed key.
  static String? _readImage(Map<String, dynamic> json) {
    final Object? nested = json['service'];
    final String? url = json['image_full_url']?.toString()
        ?? json['thumbnail_full_url']?.toString()
        ?? (nested is Map<String, dynamic>
            ? (nested['thumbnail_full_url']?.toString() ?? nested['image_full_url']?.toString())
            : null);
    return (url == null || url.isEmpty) ? null : url;
  }

  factory BookingLineItemModel.fromJson(Map<String, dynamic> json) => BookingLineItemModel(
    id: int.tryParse(json['id']?.toString() ?? ''),
    serviceId: int.tryParse(json['service_id']?.toString() ?? ''),
    serviceCampaignId: int.tryParse(json['service_campaign_id']?.toString() ?? ''),
    isCampaign: json['is_campaign'] == 1 || json['is_campaign'] == true,
    serviceName: json['service_name']?.toString(),
    isCustom: json['is_custom'] == 1 || json['is_custom'] == true,
    categoryId: int.tryParse(json['category_id']?.toString() ?? ''),
    subCategoryId: int.tryParse(json['sub_category_id']?.toString() ?? ''),
    quantity: int.tryParse(json['quantity']?.toString() ?? ''),
    price: double.tryParse(json['price']?.toString() ?? ''),
    originalPrice: double.tryParse(json['original_price']?.toString() ?? ''),
    calculatedPrice: double.tryParse(json['calculated_price']?.toString() ?? ''),
    discountAmount: double.tryParse(json['discount_amount']?.toString() ?? ''),
    discountType: json['discount_type']?.toString(),
    discountBy: json['discount_by']?.toString(),
    discountPercentage: double.tryParse(json['discount_percentage']?.toString() ?? ''),
    taxAmount: double.tryParse(json['tax_amount']?.toString() ?? ''),
    taxPercentage: double.tryParse(json['tax_percentage']?.toString() ?? ''),
    taxStatus: json['tax_status']?.toString(),
    variation: (json['variation'] as List<dynamic>?)?.map((e) => ServiceVariation.fromJson(e as Map<String, dynamic>)).toList(),
    description: json['description']?.toString(),
    imageFullUrl: _readImage(json),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'service_id': serviceId, 'service_campaign_id': serviceCampaignId, 'is_campaign': isCampaign,
    'service_name': serviceName, 'is_custom': isCustom, 'category_id': categoryId,
    'sub_category_id': subCategoryId, 'quantity': quantity, 'price': price, 'original_price': originalPrice,
    'calculated_price': calculatedPrice, 'discount_amount': discountAmount, 'discount_type': discountType,
    'discount_by': discountBy, 'discount_percentage': discountPercentage, 'tax_amount': taxAmount,
    'tax_percentage': taxPercentage, 'tax_status': taxStatus,
    'variation': variation?.map((e) => e.toJson()).toList(), 'description': description,
    'image_full_url': imageFullUrl,
  };
}
