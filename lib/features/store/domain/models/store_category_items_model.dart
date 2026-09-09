import 'package:sixam_mart/features/item/domain/models/item_model.dart' show Item;

class StoreCategoryItemsModel {
  final int? totalSize;
  final int? limit;
  final int? offset;
  final String? categorySource;
  final List<Category>? categories;
  final Map<String, List<CategoryWiseItem>>? categoryWiseItems;

  StoreCategoryItemsModel({
    this.totalSize,
    this.limit,
    this.offset,
    this.categorySource,
    this.categories,
    this.categoryWiseItems,
  });

  factory StoreCategoryItemsModel.fromJson(Map<String, dynamic> json) {
    var catWiseMap = json['category_wise_items'] as Map<String, dynamic>?;
    Map<String, List<CategoryWiseItem>>? parsedCatWiseItems;
    
    if (catWiseMap != null) {
      parsedCatWiseItems = catWiseMap.map((key, value) {
        return MapEntry(
          key,
          value is List
              ? value.map((i) => CategoryWiseItem.fromJson(i as Map<String, dynamic>)).toList()
              : [],
        );
      });
    }

    return StoreCategoryItemsModel(
      totalSize: json['total_size'] as int?,
      limit: json['limit'] as int?,
      offset: json['offset'] as int?,
      categorySource: json['category_source'] as String?,
      categories: json['categories'] is List
          ? (json['categories'] as List).map((i) => Category.fromJson(i as Map<String, dynamic>)).toList()
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

class Category {
  final int? id;
  final String? name;
  final String? imageFullUrl;
  final int? itemsCount;

  Category({this.id, this.name, this.imageFullUrl, this.itemsCount});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
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

class CategoryWiseItem {
  final int? id;
  final String? name;
  final String? description;
  final String? image;
  final String? video;
  final String? videoLink;
  final int? categoryId;
  final List<CategoryIdRelation>? categoryIds;
  final List<dynamic>? variations;
  final List<AddOn>? addOns;
  final List<dynamic>? attributes;
  final List<dynamic>? choiceOptions;
  final num? price;
  final num? tax;
  final String? taxType;
  final num? discount;
  final String? discountType;
  final String? availableTimeStarts;
  final String? availableTimeEnds;
  final int? veg;
  final int? status;
  final int? storeId;
  final int? storeCategoryId;
  final String? createdAt;
  final String? updatedAt;
  final int? orderCount;
  final num? avgRating;
  final int? ratingCount;
  final int? moduleId;
  final int? stock;
  final String? unitId;
  final List<ImageStorage>? images;
  final List<FoodVariation>? foodVariations;
  final String? slug;
  final int? recommended;
  final int? organic;
  final int? maximumCartQuantity;
  final int? isApproved;
  final int? isHalal;
  final int? catGroup;
  final String? moduleType;
  final String? storeName;
  final int? isCampaign;
  final int? zoneId;
  final int? flashSale;
  final num? storeDiscount;
  final bool? scheduleOrder;
  final String? deliveryTime;
  final bool? freeDelivery;
  final dynamic unit;
  final int? minDeliveryTime;
  final int? maxDeliveryTime;
  final int? commonConditionId;
  final int? brandId;
  final int? isBasic;
  final int? isPrescriptionRequired;
  final String? unitValue;
  final String? manufacturer;
  final int? halalTagStatus;
  final int? verifiedSeller;
  final String? storeCategoryName;
  final List<String>? nutritionsName;
  final List<String>? allergiesName;
  final List<dynamic>? genericName;
  final List<TaxData>? taxData;
  final String? videoFullUrl;
  final String? videoSourceType;
  final String? videoPreviewType;
  final String? videoPreviewUrl;
  final String? videoThumbnailUrl;
  final String? videoEmbedUrl;
  final bool? videoPreviewAvailable;
  final String? videoUnavailableReason;
  final String? unitType;
  final String? imageFullUrl;
  final List<dynamic>? imagesFullUrl;
  final int? videoSize;
  final String? videoPreviewModalType;
  final String? videoPreviewModalUrl;
  final bool? hasVideoPreview;
  final bool? hasVideoSource;
  final List<Translation>? translations;
  final List<ModuleStorage>? storage;
  final StoreCategory? storeCategory;
  final Module? module;
  // final String? ecommerceItemDetails;

  CategoryWiseItem({
    this.id, this.name, this.description, this.image, this.video, this.videoLink,
    this.categoryId, this.categoryIds, this.variations, this.addOns, this.attributes,
    this.choiceOptions, this.price, this.tax, this.taxType, this.discount, this.discountType,
    this.availableTimeStarts, this.availableTimeEnds, this.veg, this.status, this.storeId,
    this.storeCategoryId, this.createdAt, this.updatedAt, this.orderCount, this.avgRating,
    this.ratingCount, this.moduleId, this.stock, this.unitId, this.images, this.foodVariations,
    this.slug, this.recommended, this.organic, this.maximumCartQuantity, this.isApproved,
    this.isHalal, this.catGroup, this.moduleType, this.storeName, this.isCampaign, this.zoneId,
    this.flashSale, this.storeDiscount, this.scheduleOrder, this.deliveryTime, this.freeDelivery,
    this.unit, this.minDeliveryTime, this.maxDeliveryTime, this.commonConditionId, this.brandId,
    this.isBasic, this.isPrescriptionRequired, this.unitValue, this.manufacturer, this.halalTagStatus,
    this.verifiedSeller, this.storeCategoryName, this.nutritionsName, this.allergiesName,
    this.genericName, this.taxData, this.videoFullUrl, this.videoSourceType, this.videoPreviewType,
    this.videoPreviewUrl, this.videoThumbnailUrl, this.videoEmbedUrl, this.videoPreviewAvailable,
    this.videoUnavailableReason, this.unitType, this.imageFullUrl, this.imagesFullUrl, this.videoSize,
    this.videoPreviewModalType, this.videoPreviewModalUrl, this.hasVideoPreview, this.hasVideoSource,
    this.translations, this.storage, this.storeCategory, this.module, /*this.ecommerceItemDetails,*/
  });

  factory CategoryWiseItem.fromJson(Map<String, dynamic> json) => CategoryWiseItem(
    id: json['id'] as int?,
    name: json['name'] as String?,
    description: json['description'] as String?,
    image: json['image'] as String?,
    video: json['video'] as String?,
    videoLink: json['video_link'] as String?,
    categoryId: json['category_id'] as int?,
    categoryIds: json['category_ids'] is List ? (json['category_ids'] as List).map((i) => CategoryIdRelation.fromJson(i)).toList() : null,
    variations: json['variations'] is List ? List<dynamic>.from(json['variations']) : null,
    addOns: json['add_ons'] is List ? (json['add_ons'] as List).map((i) => AddOn.fromJson(i)).toList() : null,
    attributes: json['attributes'] is List ? List<dynamic>.from(json['attributes']) : null,
    choiceOptions: json['choice_options'] is List ? List<dynamic>.from(json['choice_options']) : null,
    price: json['price'] as num?,
    tax: json['tax'] as num?,
    taxType: json['tax_type'] as String?,
    discount: json['discount'] as num?,
    discountType: json['discount_type'] as String?,
    availableTimeStarts: json['available_time_starts'] as String?,
    availableTimeEnds: json['available_time_ends'] as String?,
    veg: json['veg'] as int?,
    status: json['status'] as int?,
    storeId: json['store_id'] as int?,
    storeCategoryId: json['store_category_id'] as int?,
    createdAt: json['created_at'] as String?,
    updatedAt: json['updated_at'] as String?,
    orderCount: json['order_count'] as int?,
    avgRating: json['avg_rating'] as num?,
    ratingCount: json['rating_count'] as int?,
    moduleId: json['module_id'] as int?,
    stock: json['stock'] as int?,
    unitId: json['unit_id']?.toString(),
    images: json['images'] is List ? (json['images'] as List).whereType<Map<String, dynamic>>().map((i) => ImageStorage.fromJson(i)).toList() : null,
    foodVariations: json['food_variations'] is List ? (json['food_variations'] as List).map((i) => FoodVariation.fromJson(i)).toList() : null,
    slug: json['slug'] as String?,
    recommended: json['recommended'] as int?,
    organic: json['organic'] as int?,
    maximumCartQuantity: json['maximum_cart_quantity'] as int?,
    isApproved: json['is_approved'] as int?,
    isHalal: json['is_halal'] as int?,
    catGroup: json['cat_group'] as int?,
    moduleType: json['module_type'] as String?,
    storeName: json['store_name'] as String?,
    isCampaign: json['is_campaign'] as int?,
    zoneId: json['zone_id'] as int?,
    flashSale: json['flash_sale'] as int?,
    storeDiscount: json['store_discount'] as num?,
    scheduleOrder: json['schedule_order'] as bool?,
    deliveryTime: json['delivery_time'] as String?,
    freeDelivery: json['free_delivery'] as bool?,
    unit: json['unit'],
    minDeliveryTime: json['min_delivery_time'] as int?,
    maxDeliveryTime: json['max_delivery_time'] as int?,
    commonConditionId: json['common_condition_id'] as int?,
    brandId: json['brand_id'] as int?,
    isBasic: json['is_basic'] as int?,
    isPrescriptionRequired: json['is_prescription_required'] as int?,
    unitValue: json['unit_value'] as String?,
    manufacturer: json['manufacturer'] as String?,
    halalTagStatus: json['halal_tag_status'] as int?,
    verifiedSeller: json['verified_seller'] as int?,
    storeCategoryName: json['store_category_name'] as String?,
    nutritionsName: json['nutritions_name'] is List ? List<String>.from(json['nutritions_name']) : null,
    allergiesName: json['allergies_name'] is List ? List<String>.from(json['allergies_name']) : null,
    genericName: json['generic_name'] is List ? List<dynamic>.from(json['generic_name']) : null,
    taxData: json['tax_data'] is List ? (json['tax_data'] as List).map((i) => TaxData.fromJson(i)).toList() : null,
    videoFullUrl: json['video_full_url'] as String?,
    videoSourceType: json['video_source_type'] as String?,
    videoPreviewType: json['video_preview_type'] as String?,
    videoPreviewUrl: json['video_preview_url'] as String?,
    videoThumbnailUrl: json['video_thumbnail_url'] as String?,
    videoEmbedUrl: json['video_embed_url'] as String?,
    videoPreviewAvailable: json['video_preview_available'] as bool?,
    videoUnavailableReason: json['video_unavailable_reason'] as String?,
    unitType: json['unit_type'] as String?,
    imageFullUrl: json['image_full_url'] as String?,
    imagesFullUrl: json['images_full_url'] is List ? List<dynamic>.from(json['images_full_url']) : null,
    videoSize: json['video_size'] as int?,
    videoPreviewModalType: json['video_preview_modal_type'] as String?,
    videoPreviewModalUrl: json['video_preview_modal_url'] as String?,
    hasVideoPreview: json['has_video_preview'] as bool?,
    hasVideoSource: json['has_video_source'] as bool?,
    translations: json['translations'] is List ? (json['translations'] as List).map((i) => Translation.fromJson(i)).toList() : null,
    storage: json['storage'] is List ? (json['storage'] as List).map((i) => ModuleStorage.fromJson(i)).toList() : null,
    storeCategory: json['store_category'] is Map<String, dynamic> ? StoreCategory.fromJson(json['store_category']) : null,
    module: json['module'] != null ? Module.fromJson(json['module']) : null,
    // ecommerceItemDetails: json['ecommerce_item_details'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'description': description, 'image': image, 'video': video, 'video_link': videoLink,
    'category_id': categoryId, 'category_ids': categoryIds?.map((e) => e.toJson()).toList(), 'variations': variations,
    'add_ons': addOns?.map((e) => e.toJson()).toList(), 'attributes': attributes, 'choice_options': choiceOptions,
    'price': price, 'tax': tax, 'tax_type': taxType, 'discount': discount, 'discount_type': discountType,
    'available_time_starts': availableTimeStarts, 'available_time_ends': availableTimeEnds, 'veg': veg, 'status': status,
    'store_id': storeId, 'store_category_id': storeCategoryId, 'created_at': createdAt, 'updated_at': updatedAt,
    'order_count': orderCount, 'avg_rating': avgRating, 'rating_count': ratingCount, 'module_id': moduleId, 'stock': stock,
    'unit_id': unitId, 'images': images?.map((e) => e.toJson()).toList(), 'food_variations': foodVariations?.map((e) => e.toJson()).toList(),
    'slug': slug, 'recommended': recommended, 'organic': organic, 'maximum_cart_quantity': maximumCartQuantity,
    'is_approved': isApproved, 'is_halal': isHalal, 'cat_group': catGroup, 'module_type': moduleType, 'store_name': storeName,
    'is_campaign': isCampaign, 'zone_id': zoneId, 'flash_sale': flashSale, 'store_discount': storeDiscount, 'schedule_order': scheduleOrder,
    'delivery_time': deliveryTime, 'free_delivery': freeDelivery, 'unit': unit, 'min_delivery_time': minDeliveryTime,
    'max_delivery_time': maxDeliveryTime, 'common_condition_id': commonConditionId, 'brand_id': brandId, 'is_basic': isBasic,
    'is_prescription_required': isPrescriptionRequired, 'unit_value': unitValue, 'manufacturer': manufacturer,
    'halal_tag_status': halalTagStatus, 'verified_seller': verifiedSeller, 'store_category_name': storeCategoryName,
    'nutritions_name': nutritionsName, 'allergies_name': allergiesName, 'generic_name': genericName, 'tax_data': taxData?.map((e) => e.toJson()).toList(),
    'video_full_url': videoFullUrl, 'video_source_type': videoSourceType, 'video_preview_type': videoPreviewType,
    'video_preview_url': videoPreviewUrl, 'video_thumbnail_url': videoThumbnailUrl, 'video_embed_url': videoEmbedUrl,
    'video_preview_available': videoPreviewAvailable, 'video_unavailable_reason': videoUnavailableReason, 'unit_type': unitType,
    'image_full_url': imageFullUrl, 'images_full_url': imagesFullUrl, 'video_size': videoSize, 'video_preview_modal_type': videoPreviewModalType,
    'video_preview_modal_url': videoPreviewModalUrl, 'has_video_preview': hasVideoPreview, 'has_video_source': hasVideoSource,
    'translations': translations?.map((e) => e.toJson()).toList(), 'storage': storage?.map((e) => e.toJson()).toList(), 'store_category': storeCategory?.toJson(),
    'module': module?.toJson(),
    // 'ecommerce_item_details': ecommerceItemDetails,
  };

  Item toItem() => Item(
    id: id,
    name: name,
    description: description,
    imageFullUrl: imageFullUrl,
    categoryId: categoryId,
    price: price?.toDouble() ?? 0,
    tax: tax?.toDouble(),
    discount: discount?.toDouble() ?? 0,
    discountType: discountType,
    availableTimeStarts: availableTimeStarts,
    availableTimeEnds: availableTimeEnds,
    storeId: storeId,
    storeName: storeName,
    zoneId: zoneId,
    scheduleOrder: scheduleOrder,
    avgRating: avgRating?.toDouble(),
    ratingCount: ratingCount,
    veg: veg ?? 0,
    moduleId: moduleId,
    moduleType: moduleType,
    unitType: unitType,
    stock: stock,
    organic: organic,
    quantityLimit: maximumCartQuantity,
    flashSale: flashSale,
    isStoreHalalActive: halalTagStatus == 1,
    isHalalItem: isHalal == 1,
    slug: slug,
    freeDelivery: freeDelivery,
    nutritionsName: nutritionsName,
    allergiesName: allergiesName,
  );
}

class StoreCategory {
  final int? id;
  final int? storeId;
  final String? name;
  final String? slug;
  final String? image;
  final int? priority;
  final int? status;
  final String? createdAt;
  final String? updatedAt;
  final String? imageFullUrl;
  final List<Translation>? translations;
  final List<ModuleStorage>? storage;

  StoreCategory({
    this.id, this.storeId, this.name, this.slug, this.image,
    this.priority, this.status, this.createdAt, this.updatedAt, this.imageFullUrl,
    this.translations, this.storage,
  });

  factory StoreCategory.fromJson(Map<String, dynamic> json) => StoreCategory(
    id: json['id'] as int?,
    storeId: json['store_id'] as int?,
    name: json['name'] as String?,
    slug: json['slug'] as String?,
    image: json['image'] as String?,
    priority: json['priority'] as int?,
    status: json['status'] as int?,
    createdAt: json['created_at'] as String?,
    updatedAt: json['updated_at'] as String?,
    imageFullUrl: json['image_full_url'] as String?,
    translations: json['translations'] is List ? (json['translations'] as List).map((i) => Translation.fromJson(i)).toList() : null,
    storage: json['storage'] is List ? (json['storage'] as List).map((i) => ModuleStorage.fromJson(i)).toList() : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'store_id': storeId, 'name': name, 'slug': slug, 'image': image,
    'priority': priority, 'status': status, 'created_at': createdAt, 'updated_at': updatedAt,
    'image_full_url': imageFullUrl, 'translations': translations?.map((e) => e.toJson()).toList(),
    'storage': storage?.map((e) => e.toJson()).toList(),
  };
}

class CategoryIdRelation {
  final String? id;
  final int? position;
  final String? name;

  CategoryIdRelation({this.id, this.position, this.name});

  factory CategoryIdRelation.fromJson(Map<String, dynamic> json) => CategoryIdRelation(
    id: json['id']?.toString(),
    position: json['position'] as int?,
    name: json['name'] as String?,
  );

  Map<String, dynamic> toJson() => {'id': id, 'position': position, 'name': name};
}

class AddOn {
  final int? id;
  final String? name;
  final num? price;
  final String? createdAt;
  final String? updatedAt;
  final int? storeId;
  final int? status;
  final int? addonCategoryId;
  final List<dynamic>? taxIds;
  final List<Translation>? translations;

  AddOn({
    this.id, this.name, this.price, this.createdAt, this.updatedAt,
    this.storeId, this.status, this.addonCategoryId, this.taxIds, this.translations,
  });

  factory AddOn.fromJson(Map<String, dynamic> json) => AddOn(
    id: json['id'] as int?,
    name: json['name'] as String?,
    price: json['price'] as num?,
    createdAt: json['created_at'] as String?,
    updatedAt: json['updated_at'] as String?,
    storeId: json['store_id'] as int?,
    status: json['status'] as int?,
    addonCategoryId: json['addon_category_id'] as int?,
    taxIds: json['tax_ids'] is List ? List<dynamic>.from(json['tax_ids']) : null,
    translations: json['translations'] is List ? (json['translations'] as List).map((i) => Translation.fromJson(i)).toList() : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'price': price, 'created_at': createdAt, 'updated_at': updatedAt,
    'store_id': storeId, 'status': status, 'addon_category_id': addonCategoryId, 'tax_ids': taxIds,
    'translations': translations?.map((e) => e.toJson()).toList(),
  };
}

class ImageStorage {
  final String? img;
  final String? storage;

  ImageStorage({this.img, this.storage});

  factory ImageStorage.fromJson(Map<String, dynamic> json) => ImageStorage(
    img: json['img'] as String?,
    storage: json['storage'] as String?,
  );

  Map<String, dynamic> toJson() => {'img': img, 'storage': storage};
}

class FoodVariation {
  final String? name;
  final String? type;
  final String? min;
  final String? max;
  final String? required;
  final List<FoodVariationValue>? values;

  FoodVariation({this.name, this.type, this.min, this.max, this.required, this.values});

  factory FoodVariation.fromJson(Map<String, dynamic> json) => FoodVariation(
    name: json['name'] as String?,
    type: json['type'] as String?,
    min: json['min']?.toString(),
    max: json['max']?.toString(),
    required: json['required'] as String?,
    values: json['values'] is List ? (json['values'] as List).map((i) => FoodVariationValue.fromJson(i)).toList() : null,
  );

  Map<String, dynamic> toJson() => {
    'name': name, 'type': type, 'min': min, 'max': max, 'required': required,
    'values': values?.map((e) => e.toJson()).toList(),
  };
}

class FoodVariationValue {
  final String? label;
  final String? optionPrice;

  FoodVariationValue({this.label, this.optionPrice});

  factory FoodVariationValue.fromJson(Map<String, dynamic> json) => FoodVariationValue(
    label: json['label'] as String?,
    optionPrice: json['optionPrice'] as String?,
  );

  Map<String, dynamic> toJson() => {'label': label, 'optionPrice': optionPrice};
}

class TaxData {
  final int? id;
  final String? name;
  final num? taxRate;

  TaxData({this.id, this.name, this.taxRate});

  factory TaxData.fromJson(Map<String, dynamic> json) => TaxData(
    id: json['id'] as int?,
    name: json['name'] as String?,
    taxRate: json['tax_rate'] as num?,
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'tax_rate': taxRate};
}

class Translation {
  final int? id;
  final String? translationableType;
  final int? translationableId;
  final String? locale;
  final String? key;
  final String? value;
  final String? createdAt;
  final String? updatedAt;

  Translation({
    this.id, this.translationableType, this.translationableId,
    this.locale, this.key, this.value, this.createdAt, this.updatedAt,
  });

  factory Translation.fromJson(Map<String, dynamic> json) => Translation(
    id: json['id'] as int?,
    translationableType: json['translationable_type'] as String?,
    translationableId: json['translationable_id'] as int?,
    locale: json['locale'] as String?,
    key: json['key'] as String?,
    value: json['value'] as String?,
    createdAt: json['created_at'] as String?,
    updatedAt: json['updated_at'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'translationable_type': translationableType, 'translationable_id': translationableId,
    'locale': locale, 'key': key, 'value': value, 'created_at': createdAt, 'updated_at': updatedAt,
  };
}

class Module {
  final int? id;
  final String? moduleName;
  final String? moduleType;
  final String? thumbnail;
  final String? status;
  final int? storesCount;
  final String? createdAt;
  final String? updatedAt;
  final String? icon;
  final int? themeId;
  final String? description;
  final int? allZoneService;
  final String? slug;
  final String? iconFullUrl;
  final String? thumbnailFullUrl;
  final List<Translation>? translations;
  final List<ModuleStorage>? storage;

  Module({
    this.id, this.moduleName, this.moduleType, this.thumbnail, this.status,
    this.storesCount, this.createdAt, this.updatedAt, this.icon, this.themeId,
    this.description, this.allZoneService, this.slug, this.iconFullUrl, this.thumbnailFullUrl,
    this.translations, this.storage,
  });

  factory Module.fromJson(Map<String, dynamic> json) => Module(
    id: json['id'] as int?,
    moduleName: json['module_name'] as String?,
    moduleType: json['module_type'] as String?,
    thumbnail: json['thumbnail'] as String?,
    status: json['status'] as String?,
    storesCount: json['stores_count'] as int?,
    createdAt: json['created_at'] as String?,
    updatedAt: json['updated_at'] as String?,
    icon: json['icon'] as String?,
    themeId: json['theme_id'] as int?,
    description: json['description'] as String?,
    allZoneService: json['all_zone_service'] as int?,
    slug: json['slug'] as String?,
    iconFullUrl: json['icon_full_url'] as String?,
    thumbnailFullUrl: json['thumbnail_full_url'] as String?,
    translations: json['translations'] is List ? (json['translations'] as List).map((i) => Translation.fromJson(i)).toList() : null,
    storage: json['storage'] is List ? (json['storage'] as List).map((i) => ModuleStorage.fromJson(i)).toList() : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'module_name': moduleName, 'module_type': moduleType, 'thumbnail': thumbnail, 'status': status,
    'stores_count': storesCount, 'created_at': createdAt, 'updated_at': updatedAt, 'icon': icon, 'theme_id': themeId,
    'description': description, 'all_zone_service': allZoneService, 'slug': slug, 'icon_full_url': iconFullUrl,
    'thumbnail_full_url': thumbnailFullUrl, 'translations': translations?.map((e) => e.toJson()).toList(),
    'storage': storage?.map((e) => e.toJson()).toList(),
  };
}

class ModuleStorage {
  final int? id;
  final String? dataType;
  final String? dataId;
  final String? key;
  final String? value;
  final String? createdAt;
  final String? updatedAt;

  ModuleStorage({this.id, this.dataType, this.dataId, this.key, this.value, this.createdAt, this.updatedAt});

  factory ModuleStorage.fromJson(Map<String, dynamic> json) => ModuleStorage(
    id: json['id'] as int?,
    dataType: json['data_type'] as String?,
    dataId: json['data_id']?.toString(),
    key: json['key'] as String?,
    value: json['value'] as String?,
    createdAt: json['created_at'] as String?,
    updatedAt: json['updated_at'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'data_type': dataType, 'data_id': dataId, 'key': key, 'value': value, 'created_at': createdAt, 'updated_at': updatedAt,
  };
}
