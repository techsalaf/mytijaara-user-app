import 'package:sixam_mart/features/item/domain/models/item_model.dart';

class NewItemListResponse {
  int? totalSize;
  int? limit;
  int? offset;
  List<NewItem>? items;

  NewItemListResponse({this.totalSize, this.limit, this.offset, this.items});

  NewItemListResponse.fromJson(Map<String, dynamic> json) {
    totalSize = _toInt(json['total_size']);
    limit = _toInt(json['limit']);
    offset = _toInt(json['offset']);
    if (json['items'] != null) {
      items = <NewItem>[];
      for (final dynamic v in json['items']) {
        items!.add(NewItem.fromJson(v));
      }
    }
  }
}

class NewItem {
  int? id;
  String? name;
  String? slug;
  String? imageFullUrl;
  double? price;
  int? veg;
  String? unitType;
  int? recommended;
  int? organic;
  int? isHalal;
  int? stock;
  int? maximumCartQuantity;
  double? discount;
  String? discountType;
  int? ratingCount;
  double? avgRating;
  int? hasVariant;
  String? availableTimeStarts;
  String? availableTimeEnds;
  int? halalTagStatus;
  String? storeName;
  int? storeId;
  String? storeLogoFullUrl;
  int? storeCategoryId;
  String? storeCategoryName;
  String? moduleType;
  bool? freeDelivery;
  int? verifiedSeller;
  double? discountedPrice;
  String? storeImage;
  int? wishlist;

  NewItem({
    this.id, this.name, this.slug, this.imageFullUrl, this.price,
    this.veg, this.unitType, this.recommended, this.organic, this.isHalal,
    this.stock, this.maximumCartQuantity, this.discount, this.discountType, this.ratingCount,
    this.avgRating, this.hasVariant, this.availableTimeStarts, this.availableTimeEnds, this.halalTagStatus,
    this.storeName, this.storeId, this.storeLogoFullUrl, this.storeCategoryId, this.storeCategoryName,
    this.moduleType, this.freeDelivery, this.verifiedSeller, this.discountedPrice, this.storeImage,
    this.wishlist,
  });

  NewItem.fromJson(Map<String, dynamic> json) {
    id = _toInt(json['id']);
    name = json['name']?.toString();
    slug = json['slug']?.toString();
    imageFullUrl = json['image_full_url']?.toString();
    price = _toDouble(json['price']);
    veg = _toInt(json['veg']);
    unitType = json['unit_type']?.toString();
    recommended = _toInt(json['recommended']);
    organic = _toInt(json['organic']);
    isHalal = _toInt(json['is_halal']);
    stock = _toInt(json['stock']);
    maximumCartQuantity = _toInt(json['maximum_cart_quantity']);
    discount = _toDouble(json['discount']);
    discountType = json['discount_type']?.toString();
    ratingCount = _toInt(json['rating_count']);
    avgRating = _toDouble(json['avg_rating']);
    hasVariant = _toInt(json['has_variant']);
    availableTimeStarts = json['available_time_starts']?.toString();
    availableTimeEnds = json['available_time_ends']?.toString();
    halalTagStatus = _toInt(json['halal_tag_status']);
    storeName = json['store_name']?.toString();
    storeId = _toInt(json['store_id']);
    storeLogoFullUrl = json['store_logo_full_url']?.toString();
    storeCategoryId = _toInt(json['store_category_id']);
    storeCategoryName = json['store_category_name']?.toString();
    moduleType = json['module_type']?.toString();
    freeDelivery = json['free_delivery'] is bool
        ? json['free_delivery'] as bool
        : (_toInt(json['free_delivery']) ?? 0) == 1;
    verifiedSeller = _toInt(json['verified_seller']);
    discountedPrice = _toDouble(json['discounted_price']);
    storeImage = json['store_image']?.toString();
    wishlist = _toInt(json['wishlist']);
  }

  Item toItem() {
    return Item(
      id: id, name: name, imageFullUrl: imageFullUrl, price: price, veg: veg,
      unitType: unitType, organic: organic, stock: stock, quantityLimit: maximumCartQuantity, discount: discount,
      discountType: discountType, ratingCount: ratingCount, avgRating: avgRating, availableTimeStarts: availableTimeStarts, availableTimeEnds: availableTimeEnds,
      isStoreHalalActive: halalTagStatus == 1, isHalalItem: isHalal == 1, storeName: storeName, storeId: storeId, moduleType: moduleType,
      verifiedSeller: verifiedSeller, slug: slug, storeImageFullUrl: storeLogoFullUrl ?? storeImage, freeDelivery: freeDelivery,
    );
  }
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is bool) return value ? 1 : 0;
  return int.tryParse(value.toString());
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
