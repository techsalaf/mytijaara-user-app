class CustomerInformation {
  final String? name;
  final String? phone;
  final String? address;
  final String? road;
  final String? house;
  final String? floor;
  final String? latitude;
  final String? longitude;

  const CustomerInformation({this.name, this.phone, this.address, this.road, this.house,
    this.floor, this.latitude, this.longitude,
  });

  factory CustomerInformation.fromJson(Map<String, dynamic> json) => CustomerInformation(
    name: json['name']?.toString(),
    phone: json['phone']?.toString(),
    address: json['address']?.toString(),
    road: json['road']?.toString(),
    house: json['house']?.toString(),
    floor: json['floor']?.toString(),
    latitude: json['latitude']?.toString(),
    longitude: json['longitude']?.toString(),
  );
}

class CategoryRef {
  final int? id;
  final String? name;

  const CategoryRef({this.id, this.name});

  factory CategoryRef.fromJson(Map<String, dynamic> json) => CategoryRef(
    id: int.tryParse(json['id']?.toString() ?? ''),
    name: json['name']?.toString(),
  );
}

class CustomServiceRequestModel {
  final int? id;
  final String? description;
  final CustomerInformation? customerInformation;
  final String? bookingDate;
  final String? bookingTime;
  final String? status;
  final String? statusLabel;
  final int? bidCount;
  final String? lastBidAt;
  final bool? isRejected;
  final int? selectedOfferId;
  final BidModel? selectedOffer;
  final CategoryRef? category;
  final CategoryRef? subCategory;
  final List<BidModel>? bids;
  final String? createdAt;
  final String? updatedAt;

  const CustomServiceRequestModel({
    this.id, this.description, this.customerInformation,
    this.bookingDate, this.bookingTime, this.status, this.statusLabel,
    this.bidCount, this.lastBidAt, this.isRejected, this.selectedOfferId, this.selectedOffer,
    this.category, this.subCategory, this.bids, this.createdAt, this.updatedAt,
  });

  factory CustomServiceRequestModel.fromJson(Map<String, dynamic> json) => CustomServiceRequestModel(
    id: int.tryParse(json['id']?.toString() ?? ''),
    description: json['description']?.toString(),
    customerInformation: json['customer_information'] != null
        ? CustomerInformation.fromJson(json['customer_information'] as Map<String, dynamic>)
        : null,
    bookingDate: json['booking_date']?.toString(),
    bookingTime: json['booking_time']?.toString(),
    status: json['status']?.toString(),
    statusLabel: json['status_label']?.toString(),
    bidCount: int.tryParse(json['bid_count']?.toString() ?? ''),
    lastBidAt: json['last_bid_at']?.toString(),
    isRejected: json['is_rejected'] as bool?,
    selectedOfferId: int.tryParse(json['selected_offer_id']?.toString() ?? ''),
    selectedOffer: json['selected_offer'] != null
        ? BidModel.fromJson(json['selected_offer'] as Map<String, dynamic>)
        : null,
    category: json['category'] != null
        ? CategoryRef.fromJson(json['category'] as Map<String, dynamic>)
        : null,
    subCategory: json['sub_category'] != null
        ? CategoryRef.fromJson(json['sub_category'] as Map<String, dynamic>)
        : null,
    bids: (json['bids'] as List<dynamic>?)
        ?.map((e) => BidModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    createdAt: json['created_at']?.toString(),
    updatedAt: json['updated_at']?.toString(),
  );
}

class BidProviderModel {
  final int? id;
  final String? name;
  final String? imageFullUrl;
  final double? avgRating;
  final int? reviewCount;

  const BidProviderModel({this.id, this.name, this.imageFullUrl, this.avgRating, this.reviewCount});

  factory BidProviderModel.fromJson(Map<String, dynamic> json) => BidProviderModel(
    id: int.tryParse(json['id']?.toString() ?? ''),
    name: json['name']?.toString(),
    imageFullUrl: json['image_full_url']?.toString(),
    avgRating: double.tryParse(json['avg_rating']?.toString() ?? ''),
    reviewCount: int.tryParse(json['review_count']?.toString() ?? ''),
  );
}

class BidModel {
  final int? id;
  final int? customServiceRequestId;
  final double? offerPrice;
  final String? note;
  final bool? isSelected;
  final bool? isDenied;
  final BidProviderModel? provider;
  final String? createdAt;
  final String? updatedAt;

  const BidModel({this.id, this.customServiceRequestId, this.offerPrice, this.note,
    this.isSelected, this.isDenied, this.provider, this.createdAt, this.updatedAt});

  factory BidModel.fromJson(Map<String, dynamic> json) => BidModel(
    id: int.tryParse(json['id']?.toString() ?? ''),
    customServiceRequestId: int.tryParse(json['custom_service_request_id']?.toString() ?? ''),
    offerPrice: double.tryParse(json['offer_price']?.toString() ?? ''),
    note: json['note']?.toString(),
    isSelected: json['is_selected'] as bool?,
    isDenied: json['is_denied'] as bool?,
    provider: json['provider'] != null
        ? BidProviderModel.fromJson(json['provider'] as Map<String, dynamic>)
        : null,
    createdAt: json['created_at']?.toString(),
    updatedAt: json['updated_at']?.toString(),
  );
}

class OfferProviderModel {
  final int? id;
  final String? name;
  final String? logoFullUrl;

  const OfferProviderModel({this.id, this.name, this.logoFullUrl});

  factory OfferProviderModel.fromJson(Map<String, dynamic> json) => OfferProviderModel(
    id: int.tryParse(json['id']?.toString() ?? ''),
    name: json['name']?.toString(),
    logoFullUrl: json['logo_full_url']?.toString(),
  );
}

class OfferModel {
  final int? bookingId;
  final double? price;
  final OfferProviderModel? provider;

  const OfferModel({this.bookingId, this.price, this.provider});

  factory OfferModel.fromJson(Map<String, dynamic> json) => OfferModel(
    bookingId: int.tryParse(json['booking_id']?.toString() ?? ''),
    price: double.tryParse(json['price']?.toString() ?? ''),
    provider: json['provider'] != null
        ? OfferProviderModel.fromJson(json['provider'] as Map<String, dynamic>)
        : null,
  );
}

class CustomServiceListItemModel {
  final int? id;
  final String? description;
  final int? categoryId;
  final String? categoryName;
  final String? categoryImageFullUrl;
  final String? status;
  final String? statusLabel;
  final int? bidCount;
  final OfferModel? offer;
  final String? createdAt;

  const CustomServiceListItemModel({this.id, this.description, this.categoryId,
    this.categoryName, this.categoryImageFullUrl, this.status, this.statusLabel,
    this.bidCount, this.offer, this.createdAt});

  factory CustomServiceListItemModel.fromJson(Map<String, dynamic> json) => CustomServiceListItemModel(
    id: int.tryParse(json['id']?.toString() ?? ''),
    description: json['description']?.toString(),
    categoryId: int.tryParse(json['category_id']?.toString() ?? ''),
    categoryName: json['category_name']?.toString(),
    categoryImageFullUrl: json['category_image_full_url']?.toString(),
    status: json['status']?.toString(),
    statusLabel: json['status_label']?.toString(),
    bidCount: int.tryParse(json['bid_count']?.toString() ?? ''),
    offer: json['offer'] != null
        ? OfferModel.fromJson(json['offer'] as Map<String, dynamic>)
        : null,
    createdAt: json['created_at']?.toString(),
  );
}

class CustomServiceRequestListResult {
  final List<CustomServiceListItemModel> items;
  final int totalSize;
  final int? offset;

  const CustomServiceRequestListResult({required this.items, required this.totalSize, this.offset});

  factory CustomServiceRequestListResult.fromJson(Map<String, dynamic> json) => CustomServiceRequestListResult(
    items: (json['data'] as List<dynamic>? ?? [])
        .map((e) => CustomServiceListItemModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    totalSize: int.tryParse(json['total_size']?.toString() ?? '') ?? 0,
    offset: int.tryParse(json['offset']?.toString() ?? ''),
  );
}

class CustomServiceDetailResponse {
  final CustomServiceRequestModel detail;
  final List<BidModel> bids;

  const CustomServiceDetailResponse({required this.detail, required this.bids});
}
