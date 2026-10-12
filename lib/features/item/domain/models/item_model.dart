import 'package:sixam_mart/api/json_reader.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/api/response_parser.dart';
import 'package:sixam_mart/common/models/pagination_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/item/domain/models/basic_medicine_model.dart';

class ItemModel {
  int? totalSize;
  int? minPrice;
  int? maxPrice;
  String? limit;
  int? offset;
  List<Item>? items;
  List<Categories>? categories;

  ItemModel({this.totalSize, this.limit, this.offset, this.items, this.categories});

  ItemModel.fromJson(Map<String, dynamic> json) {
    // Paging arrives either flat (`total_size`/`limit`/`offset`) or nested under
    // `pagination`. These field names stay as they are — the app treats `offset`
    // as a 1-based page number, which `current_page` maps onto directly.
    final PaginationModel pagination = PaginationModel.fromJson(json);
    totalSize = pagination.totalSize;
    limit = pagination.limit?.toString();
    offset = pagination.offset;
    minPrice = json['min_price'];
    maxPrice = json['max_price'];

    // `products` (unfiltered) and `items` (filtered) were the legacy keys; both
    // are now `data`. The filter is applied to `data`, since it only drops items
    // whose variation data this build cannot render correctly — showing one of
    // those is worse than omitting it.
    if (json['products'] is List) {
      items = [];
      for (final dynamic v in json['products'] as List<dynamic>) {
        items!.add(Item.fromJson(v));
      }
    }
    final List<dynamic>? renderable = (json['items'] is List)
        ? json['items'] as List<dynamic>
        : (json['products'] is List ? null : ResponseParser.listOf(json));
    if (renderable != null) {
      items = [];
      for (final dynamic v in renderable) {
        if (_isRenderable(v)) {
          items!.add(Item.fromJson(v));
        }
      }
    }

    // `categories` sits beside the item list in the same body (see
    // `categories/featured/items`), so it is read by name — never via `data`.
    final List<dynamic> categoryJson = ResponseParser.namedListOf(json, 'categories');
    if (categoryJson.isNotEmpty) {
      categories = <Categories>[];
      for (final dynamic v in categoryJson) {
        categories!.add(Categories.fromJson(v));
      }
    }
  }

  /// Excludes items whose variations this build cannot render — a module on the
  /// new variation format whose item carries `variations` but no `food_variations`.
  ///
  /// Fails open: if the module config cannot be resolved (no [SplashController]
  /// registered yet, or config not loaded) the item is kept. Dropping items
  /// because config happened to be unavailable would empty a whole home section
  /// for a reason that has nothing to do with the item.
  static bool _isRenderable(dynamic v) {
    if (v is! Map) return false;
    if (v['module_type'] == null) return true;
    bool newVariation;
    try {
      newVariation = Get.find<SplashController>().getModuleConfig(v['module_type']).newVariation ?? false;
    } catch (_) {
      return true;
    }
    if (!newVariation) return true;
    if (v['variations'] is! List || (v['variations'] as List).isEmpty) return true;
    return v['food_variations'] is List && (v['food_variations'] as List).isNotEmpty;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_size'] = totalSize;
    data['min_price'] = minPrice;
    data['max_price'] = maxPrice;
    data['limit'] = limit;
    data['offset'] = offset;
    if (items != null) {
      data['products'] = items!.map((v) => v.toJson()).toList();
    }
    if (categories != null) {
      data['categories'] = categories!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Item {
  int? id;
  String? name;
  String? description;
  String? imageFullUrl;
  List<String>? imagesFullUrl;
  String? video;
  String? videoLink;
  String? videoFullUrl;
  String? videoSourceType;
  String? videoPreviewType;
  String? videoPreviewUrl;
  String? videoThumbnailUrl;
  String? videoEmbedUrl;
  String? videoPreviewModalType;
  String? videoPreviewModalUrl;
  bool? hasVideoPreview;
  bool? hasVideoSource;
  int? categoryId;
  List<CategoryIds>? categoryIds;
  List<Variation>? variations;
  List<FoodVariation>? foodVariations;
  List<AddOns>? addOns;
  List<ChoiceOptions>? choiceOptions;
  double? price;
  double? tax;
  double? discount;
  String? discountType;
  String? availableTimeStarts;
  String? availableTimeEnds;
  int? storeId;
  String? storeName;
  int? zoneId;
  bool? scheduleOrder;
  double? avgRating;
  int? ratingCount;
  int? veg;
  int? moduleId;
  String? moduleType;
  String? unitType;
  int? stock;
  String? availableDateStarts;
  int? organic;
  int? quantityLimit;
  int? flashSale;
  bool? isStoreHalalActive;
  bool? isHalalItem;
  bool? isPrescriptionRequired;
  List<String>? nutritionsName;
  List<String>? allergiesName;
  List<String>? genericName;
  StoreDetails? storeDetails;
  String? slug;
  int? verifiedSeller;
  String? storeImageFullUrl;
  String? storeLogoFullUrl;
  bool? freeDelivery;
  String? offerLabel;
  int? brandId;
  String? brandName;

  Item({
    this.id,
    this.name,
    this.description,
    this.imageFullUrl,
    this.imagesFullUrl,
    this.video,
    this.videoLink,
    this.videoFullUrl,
    this.videoSourceType,
    this.videoPreviewType,
    this.videoPreviewUrl,
    this.videoThumbnailUrl,
    this.videoEmbedUrl,
    this.videoPreviewModalType,
    this.videoPreviewModalUrl,
    this.hasVideoPreview,
    this.hasVideoSource,
    this.categoryId,
    this.categoryIds,
    this.variations,
    this.foodVariations,
    this.addOns,
    this.choiceOptions,
    this.price,
    this.tax,
    this.discount,
    this.discountType,
    this.availableTimeStarts,
    this.availableTimeEnds,
    this.storeId,
    this.storeName,
    this.zoneId,
    this.scheduleOrder,
    this.avgRating,
    this.ratingCount,
    this.veg,
    this.moduleId,
    this.moduleType,
    this.unitType,
    this.stock,
    this.organic,
    this.quantityLimit,
    this.flashSale,
    this.isStoreHalalActive,
    this.isHalalItem,
    this.isPrescriptionRequired,
    this.nutritionsName,
    this.allergiesName,
    this.genericName,
    this.storeDetails,
    this.slug,
    this.verifiedSeller,
    // new
    this.storeImageFullUrl,
    this.storeLogoFullUrl,
    this.freeDelivery,
    this.offerLabel,
    this.brandId,
    this.brandName,
  });

  Item.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    imageFullUrl = json['image_full_url'];
    video = json['video'];
    videoLink = json['video_link'];
    videoFullUrl = json['video_full_url'];
    videoSourceType = json['video_source_type'];
    videoPreviewType = json['video_preview_type'];
    videoPreviewUrl = json['video_preview_url'];
    videoThumbnailUrl = json['video_thumbnail_url'];
    videoEmbedUrl = json['video_embed_url'];
    videoPreviewModalType = json['video_preview_modal_type'];
    videoPreviewModalUrl = json['video_preview_modal_url'];
    hasVideoPreview = json['has_video_preview'];
    hasVideoSource = json['has_video_source'];
    if(json['images_full_url'] != null){
      imagesFullUrl = [];
      json['images_full_url'].forEach((v) {
        if(v != null) {
          imagesFullUrl!.add(v.toString());
        }
      });
    }
    categoryId = json['category_id'];
    if (json['category_ids'] != null) {
      categoryIds = [];
      json['category_ids'].forEach((v) {
        categoryIds!.add(CategoryIds.fromJson(v));
      });
    }
    variations = [];
    if (json['variations'] != null) {
      json['variations'].forEach((v) {
        variations!.add(Variation.fromJson(v));
      });
    }
    foodVariations = [];
    if (json['food_variations'] != null && json['food_variations'].isNotEmpty) {
      json['food_variations'].forEach((v) {
        foodVariations!.add(FoodVariation.fromJson(v));
      });
    }
    // `add_ons` is the legacy key; the current API sends `addons` and, on some
    // payloads, omits `add_ons` entirely — the cart's embedded item is one
    // (`/customer/cart/list` returns `addons: []` and no `add_ons`).
    //
    // The `addons` fallback used to be nested inside `if (json['add_ons'] != null)`,
    // so it was unreachable in exactly the case that needed it: `addOns` stayed null
    // and the cart item widget threw on `item!.addOns!`. Either key now populates it.
    final dynamic legacyAddOns = json['add_ons'];
    final dynamic newAddOns = json['addons'];
    // `add_ons` wins when it actually carries entries. It has been seen arriving as
    // the string "[]" rather than a list, which is what the first-element check
    // guards against — that case falls through to `addons` as before.
    final List<dynamic>? addOnSource = (legacyAddOns is List && legacyAddOns.isNotEmpty && legacyAddOns[0] != '[')
        ? legacyAddOns
        : (newAddOns is List ? newAddOns : (legacyAddOns is List ? legacyAddOns : null));
    if (addOnSource != null) {
      addOns = [];
      for (final dynamic v in addOnSource) {
        addOns!.add(AddOns.fromJson(v));
      }
    }
    if (json['choice_options'] != null) {
      choiceOptions = [];
      json['choice_options'].forEach((v) {
        choiceOptions!.add(ChoiceOptions.fromJson(v));
      });
    }
    price = JsonReader.toDouble(json['price']);
    tax = json['tax']?.toDouble();
    discount = JsonReader.toDouble(json['discount']);
    discountType = json['discount_type'];
    availableTimeStarts = json['available_time_starts'];
    availableTimeEnds = json['available_time_ends'];
    storeId = json['store_id'];
    storeName = json['store_name'];
    zoneId = json['zone_id'];
    scheduleOrder = json['schedule_order'];
    avgRating = json['avg_rating']?.toDouble()??0;
    ratingCount = json['rating_count'];
    moduleId = json['module_id'] is String ? int.tryParse(json['module_id']) : json['module_id'];
    moduleType = json['module_type'];
    veg = json['veg'] != null ? int.parse(json['veg'].toString()) : 0;
    stock = json['stock'];
    unitType = json['unit_type'];
    availableDateStarts = json['available_date_starts'];
    organic = json['organic'];
    quantityLimit = json['maximum_cart_quantity'];
    flashSale = json['flash_sale'];
    isStoreHalalActive = json['halal_tag_status'] == 1;
    isHalalItem = json['is_halal'] == 1;
    isPrescriptionRequired = json['is_prescription_required'] == 1;
    nutritionsName = json['nutritions_name']?.cast<String>();
    allergiesName = json['allergies_name']?.cast<String>();
    genericName = json['generic_name']?.cast<String>();
    storeDetails = json['store_details'] != null
        ? StoreDetails.fromJson(json['store_details'])
        : null;
    slug = json['slug'];
    verifiedSeller = json['verified_seller'];
    storeImageFullUrl = json['store_image_full_url'];
    storeLogoFullUrl = json['store_logo_full_url'];
    freeDelivery = json['free_delivery'];
    offerLabel = json['offer_label'];
    brandId = json['brand_id'];
    brandName = json['brand_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['description'] = description;
    data['image_full_url'] = imageFullUrl;
    data['images_full_url'] = imagesFullUrl;
    data['video'] = video;
    data['video_link'] = videoLink;
    data['video_full_url'] = videoFullUrl;
    data['video_source_type'] = videoSourceType;
    data['video_preview_type'] = videoPreviewType;
    data['video_preview_url'] = videoPreviewUrl;
    data['video_thumbnail_url'] = videoThumbnailUrl;
    data['video_embed_url'] = videoEmbedUrl;
    data['video_preview_modal_type'] = videoPreviewModalType;
    data['video_preview_modal_url'] = videoPreviewModalUrl;
    data['has_video_preview'] = hasVideoPreview;
    data['has_video_source'] = hasVideoSource;
    data['category_id'] = categoryId;
    if (categoryIds != null) {
      data['category_ids'] = categoryIds!.map((v) => v.toJson()).toList();
    }
    if (variations != null) {
      data['variations'] = variations!.map((v) => v.toJson()).toList();
    }
    if (foodVariations != null) {
      data['food_variations'] = foodVariations!.map((v) => v.toJson()).toList();
    }
    if (addOns != null) {
      data['add_ons'] = addOns!.map((v) => v.toJson()).toList();
    }
    if (choiceOptions != null) {
      data['choice_options'] = choiceOptions!.map((v) => v.toJson()).toList();
    }
    data['price'] = price;
    data['tax'] = tax;
    data['discount'] = discount;
    data['discount_type'] = discountType;
    data['available_time_starts'] = availableTimeStarts;
    data['available_time_ends'] = availableTimeEnds;
    data['store_id'] = storeId;
    data['store_name'] = storeName;
    data['zone_id'] = zoneId;
    data['schedule_order'] = scheduleOrder;
    data['avg_rating'] = avgRating;
    data['rating_count'] = ratingCount;
    data['veg'] = veg;
    data['module_id'] = moduleId;
    data['module_type'] = moduleType;
    data['stock'] = stock;
    data['unit_type'] = unitType;
    data['available_date_starts'] = availableDateStarts;
    data['organic'] = organic;
    data['maximum_cart_quantity'] = quantityLimit;
    data['flash_sale'] = flashSale;
    data['halal_tag_status'] = isStoreHalalActive;
    data['is_halal'] = isHalalItem;
    data['is_prescription_required'] = isPrescriptionRequired;
    data['nutritions_name'] = nutritionsName;
    data['allergies_name'] = allergiesName;
    data['generic_name'] = genericName;
    if (storeDetails != null) {
      data['store_details'] = storeDetails!.toJson();
    }
    data['slug'] = slug;
    data['verified_seller'] = verifiedSeller;
    data['store_image_full_url'] = storeImageFullUrl;
    data['store_logo_full_url'] = storeLogoFullUrl;
    data['free_delivery'] = freeDelivery;
    data['offer_label'] = offerLabel;
    data['brand_id'] = brandId;
    data['brand_name'] = brandName;
    return data;
  }
}

class CategoryIds {
  int? id;
  int? position;

  CategoryIds({this.id, this.position});

  CategoryIds.fromJson(Map<String, dynamic> json) {
    id = int.tryParse(json['id'].toString())??0;
    position = int.tryParse(json['position'].toString())??0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['position'] = position;
    return data;
  }
}

class Variation {
  String? type;
  double? price;
  int? stock;

  Variation({this.type, this.price, this.stock});

  Variation.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    // The cart returns this price as a string ("500"), so `.toDouble()` on it threw.
    price = JsonReader.toDouble(json['price']);
    stock = JsonReader.toInt(json['stock']) ?? 0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['price'] = price;
    data['stock'] = stock;
    return data;
  }
}

class AddOns {
  int? id;
  String? name;
  double? price;

  AddOns({
    this.id,
    this.name,
    this.price,
  });

  AddOns.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    price = JsonReader.toDouble(json['price']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['price'] = price;
    return data;
  }
}

class ChoiceOptions {
  String? name;
  String? title;
  List<String>? options;

  ChoiceOptions({this.name, this.title, this.options});

  ChoiceOptions.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    title = json['title'];
    options = json['options'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['title'] = title;
    data['options'] = options;
    return data;
  }
}

class FoodVariation {
  String? name;
  bool? multiSelect;
  int? min;
  int? max;
  bool? required;
  List<VariationValue>? variationValues;

  FoodVariation({this.name, this.multiSelect, this.min, this.max, this.required, this.variationValues});

  FoodVariation.fromJson(Map<String, dynamic> json) {
    if (json['max'] != null) {
      name = json['name'];
      multiSelect = json['type'] == 'multi';
      min = multiSelect! ? int.parse(json['min'].toString()) : 0;
      max = multiSelect! ? int.parse(json['max'].toString()) : 0;
      required = json['required'] == 'on';
      if (json['values'] != null) {
        variationValues = [];
        json['values'].forEach((v) {
          variationValues!.add(VariationValue.fromJson(v));
        });
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['type'] = multiSelect;
    data['min'] = min;
    data['max'] = max;
    data['required'] = required;
    if (variationValues != null) {
      data['values'] = variationValues!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class VariationValue {
  String? level;
  double? optionPrice;
  bool? isSelected;

  VariationValue({this.level, this.optionPrice, this.isSelected});

  VariationValue.fromJson(Map<String, dynamic> json) {
    level = json['label'];
    optionPrice = double.tryParse(json['optionPrice']?.toString() ?? '');
    isSelected = json['isSelected'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['label'] = level;
    data['optionPrice'] = optionPrice;
    data['isSelected'] = isSelected;
    return data;
  }
}

class StoreDetails {
  int? id;
  String? name;
  String? phone;
  String? email;
  String? slug;
  int? zoneId;
  bool? showLowStockCount;
  int? minimumStockForWarning;

  StoreDetails({
    this.id,
    this.name,
    this.phone,
    this.email,
    this.slug,
    this.zoneId,
    this.showLowStockCount,
    this.minimumStockForWarning,
  });

  StoreDetails.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    phone = json['phone'];
    email = json['email'];
    slug = json['slug'];
    zoneId = json['zone_id'];
    showLowStockCount = (json['show_low_stock_count'] == 1 || json['show_low_stock_count'] == true) ? true : false ;
    minimumStockForWarning = json['minimum_stock_for_warning'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['phone'] = phone;
    data['email'] = email;
    data['slug'] = slug;
    data['zone_id'] = zoneId;
    data['show_low_stock_count'] = showLowStockCount;
    data['minimum_stock_for_warning'] = minimumStockForWarning;
    return data;
  }
}
