import 'package:sixam_mart/features/item/domain/models/item_model.dart' show Item;

/// Lightweight model for the store detail screen's category-grouped item list.
///
/// The `/api/v1/store-categories/items` endpoint historically returned the full
/// ~85-field item object per card. The heavy shared [Item] model is depended on
/// across many features, so this keeps a slim model: only the fields the store
/// item card renders, plus the ids needed to open/add an item. Add-to-cart,
/// favourite, and item-detail all re-fetch the full item by id, so the card
/// never needs the heavy fields. [StoreCardItem.toItem] bridges to a minimal
/// [Item] only where the shared card widgets require that type.
class StoreCategoryItemModel {
  final int? totalSize;
  final int? limit;
  final int? offset;
  final String? categorySource;
  final List<StoreItemCategory>? categories;
  final Map<String, List<StoreCardItem>>? categoryWiseItems;

  StoreCategoryItemModel({
    this.totalSize,
    this.limit,
    this.offset,
    this.categorySource,
    this.categories,
    this.categoryWiseItems,
  });

  factory StoreCategoryItemModel.fromJson(Map<String, dynamic> json) {
    final catWiseMap = json['category_wise_items'] as Map<String, dynamic>?;
    Map<String, List<StoreCardItem>>? parsedCatWiseItems;
    if (catWiseMap != null) {
      parsedCatWiseItems = catWiseMap.map((key, value) => MapEntry(
            key,
            value is List
                ? value.map((i) => StoreCardItem.fromJson(i as Map<String, dynamic>)).toList()
                : <StoreCardItem>[],
          ));
    }

    return StoreCategoryItemModel(
      totalSize: json['total_size'] as int?,
      limit: json['limit'] as int?,
      offset: json['offset'] as int?,
      categorySource: json['category_source'] as String?,
      categories: json['categories'] is List
          ? (json['categories'] as List).map((i) => StoreItemCategory.fromJson(i as Map<String, dynamic>)).toList()
          : null,
      categoryWiseItems: parsedCatWiseItems,
    );
  }

  Map<String, dynamic> toJson() => {
        'total_size': totalSize,
        'limit': limit,
        'offset': offset,
        'category_source': categorySource,
        'categories': categories?.map((e) => e.toJson()).toList(),
        'category_wise_items': categoryWiseItems?.map((key, value) => MapEntry(key, value.map((e) => e.toJson()).toList())),
      };
}

class StoreItemCategory {
  final int? id;
  final String? name;
  final String? imageFullUrl;
  final int? itemsCount;

  StoreItemCategory({this.id, this.name, this.imageFullUrl, this.itemsCount});

  factory StoreItemCategory.fromJson(Map<String, dynamic> json) => StoreItemCategory(
        id: json['id'] as int?,
        name: json['name'] as String?,
        imageFullUrl: json['image_full_url'] as String?,
        itemsCount: json['items_count'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'image_full_url': imageFullUrl,
        'items_count': itemsCount,
      };
}

/// Slim per-item payload — only what the store item card shows plus the ids
/// needed to open the item / add it to cart (both re-fetch full details by id).
class StoreCardItem {
  final int? id;
  final String? name;
  final String? slug;
  final String? moduleType;
  final int? storeId;
  final num? price;
  final num? discount;
  final String? discountType;
  final num? avgRating;
  final int? ratingCount;
  final int? veg;
  final int? stock;
  final int? status;
  final String? availableTimeStarts;
  final String? availableTimeEnds;
  final String? imageFullUrl;
  final int? isHalal;
  final int? halalTagStatus;

  StoreCardItem({
    this.id, this.name, this.slug, this.moduleType, this.storeId,
    this.price, this.discount, this.discountType, this.avgRating, this.ratingCount,
    this.veg, this.stock, this.status, this.availableTimeStarts, this.availableTimeEnds,
    this.imageFullUrl, this.isHalal, this.halalTagStatus,
  });

  factory StoreCardItem.fromJson(Map<String, dynamic> json) => StoreCardItem(
        id: json['id'] as int?,
        name: json['name'] as String?,
        slug: json['slug'] as String?,
        moduleType: json['module_type'] as String?,
        storeId: json['store_id'] as int?,
        price: json['price'] as num?,
        discount: json['discount'] as num?,
        discountType: json['discount_type'] as String?,
        avgRating: json['avg_rating'] as num?,
        ratingCount: json['rating_count'] as int?,
        veg: json['veg'] as int?,
        stock: json['stock'] as int?,
        status: json['status'] as int?,
        availableTimeStarts: json['available_time_starts'] as String?,
        availableTimeEnds: json['available_time_ends'] as String?,
        imageFullUrl: json['image_full_url'] as String?,
        isHalal: json['is_halal'] as int?,
        halalTagStatus: json['halal_tag_status'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'module_type': moduleType,
        'store_id': storeId,
        'price': price,
        'discount': discount,
        'discount_type': discountType,
        'avg_rating': avgRating,
        'rating_count': ratingCount,
        'veg': veg,
        'stock': stock,
        'status': status,
        'available_time_starts': availableTimeStarts,
        'available_time_ends': availableTimeEnds,
        'image_full_url': imageFullUrl,
        'is_halal': isHalal,
        'halal_tag_status': halalTagStatus,
      };

  /// Builds a minimal [Item] carrying only the card fields. Used solely to
  /// satisfy the shared card widgets ([CartCountView], [CustomFavouriteWidget])
  /// and item navigation, all of which re-fetch full details by id.
  Item toItem() => Item(
        id: id,
        name: name,
        slug: slug,
        moduleType: moduleType,
        storeId: storeId,
        imageFullUrl: imageFullUrl,
        price: price?.toDouble() ?? 0,
        discount: discount?.toDouble() ?? 0,
        discountType: discountType,
        avgRating: avgRating?.toDouble(),
        ratingCount: ratingCount,
        veg: veg ?? 0,
        stock: stock,
        availableTimeStarts: availableTimeStarts,
        availableTimeEnds: availableTimeEnds,
        isStoreHalalActive: halalTagStatus == 1,
        isHalalItem: isHalal == 1,
      );
}
