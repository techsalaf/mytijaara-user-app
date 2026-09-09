class StoreModel {
  int? totalSize;
  String? limit;
  int? offset;
  List<Store>? stores;

  StoreModel({this.totalSize, this.limit, this.offset, this.stores});

  StoreModel.fromJson(Map<String, dynamic> json) {
    totalSize = _toInt(json['total_size']);
    limit = json['limit']?.toString();
    offset = _toInt(json['offset']);
    if (json['stores'] != null) {
      stores = [];
      json['stores'].forEach((v) {
        stores!.add(Store.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_size'] = totalSize;
    data['limit'] = limit;
    data['offset'] = offset;
    if (stores != null) {
      data['stores'] = stores!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Store {
  int? id;
  String? name;
  String? phone;
  String? email;
  String? logoFullUrl;
  String? latitude;
  String? longitude;
  String? address;
  double? minimumOrder;
  String? currency;
  bool? freeDelivery;
  String? coverPhotoFullUrl;
  bool? delivery;
  bool? takeAway;
  bool? scheduleOrder;
  double? avgRating;
  double? tax;
  int? ratingCount;
  int? featured;
  int? zoneId;
  int? selfDeliverySystem;
  bool? posSystem;
  double? minimumShippingCharge;
  double? maximumShippingCharge;
  double? perKmShippingCharge;
  int? open;
  bool? active;
  String? deliveryTime;
  List<int>? categoryIds;
  List<String>? categoryNames;
  int? veg;
  int? nonVeg;
  int? moduleId;
  String? moduleType;
  int? orderPlaceToScheduleInterval;
  Discount? discount;
  List<Schedules>? schedules;
  int? vendorId;
  bool? prescriptionOrder;
  bool? cutlery;
  String? slug;
  bool? announcementActive;
  String? announcementMessage;
  int? itemCount;
  List<Items>? items;
  List<TopItem>? topItems;
  bool? extraPackagingStatus;
  double? extraPackagingAmount;
  List<int>? ratings;
  int? reviewsCommentsCount;
  int? reviewsCount;
  StoreSubscription? storeSubscription;
  String? storeBusinessModel;
  double? distance;
  double? distanceKm;
  int? minDeliveryTime;
  int? maxDeliveryTime;
  String? storeOpeningTime;
  int? verifiedSeller;
  double? avgItemDiscountPercentage;
  List<StoreOffer>? offers;
  int? ad;
  // new fields
  Discount? proDiscount;
  bool? isNew;
  bool? sponsored;
  String? offerLabel; //ex: buy 1 get 1
  List<String?>? storeItemImageList;
  String? description;
  List<dynamic>? activeCoupons;


  Store({
    this.id, this.name, this.phone, this.email, this.logoFullUrl,
    this.latitude, this.longitude, this.address, this.minimumOrder, this.currency,
    this.freeDelivery, this.coverPhotoFullUrl, this.delivery, this.takeAway, this.scheduleOrder,
    this.avgRating, this.tax, this.featured, this.zoneId, this.ratingCount,
    this.selfDeliverySystem, this.posSystem, this.minimumShippingCharge, this.maximumShippingCharge, this.perKmShippingCharge,
    this.open, this.active, this.deliveryTime, this.categoryIds, this.categoryNames,
    this.veg, this.nonVeg, this.moduleId, this.moduleType, this.orderPlaceToScheduleInterval,
    this.discount, this.schedules, this.vendorId, this.prescriptionOrder, this.cutlery,
    this.slug, this.announcementActive, this.announcementMessage, this.itemCount, this.items,
    this.topItems, this.extraPackagingStatus, this.extraPackagingAmount, this.ratings, this.reviewsCommentsCount,
    this.reviewsCount, this.storeSubscription, this.storeBusinessModel, this.distance, this.distanceKm,
    this.minDeliveryTime, this.maxDeliveryTime, this.storeOpeningTime, this.verifiedSeller, this.avgItemDiscountPercentage,
    this.offers, this.ad, this.proDiscount, this.isNew, this.sponsored,
    this.offerLabel, this.storeItemImageList, this.description, this.activeCoupons,
  });

  Store.fromJson(Map<String, dynamic> json) {
    id = _toInt(json['id']);
    name = json['name']?.toString();
    phone = json['phone']?.toString();
    email = json['email']?.toString();
    logoFullUrl = json['logo_full_url']?.toString() ?? '';
    latitude = json['latitude']?.toString();
    longitude = json['longitude']?.toString();
    address = json['address']?.toString();
    minimumOrder = json['minimum_order'] == null ? 0 : _toDouble(json['minimum_order']);
    currency = json['currency']?.toString();
    freeDelivery = _toBool(json['free_delivery']);
    coverPhotoFullUrl = json['cover_photo_full_url']?.toString() ?? '';
    delivery = _toBool(json['delivery']);
    takeAway = _toBool(json['take_away']);
    scheduleOrder = _toBool(json['schedule_order']);
    avgRating = _toDouble(json['avg_rating']);
    tax = _toDouble(json['tax']);
    ratingCount = _toInt(json['rating_count']);
    reviewsCount = _toInt(json['reviews_count']);
    selfDeliverySystem = _toInt(json['self_delivery_system']);
    posSystem = _toBool(json['pos_system']);
    minimumShippingCharge = _toDouble(json['minimum_shipping_charge']);
    maximumShippingCharge = _toDouble(json['maximum_shipping_charge']);
    perKmShippingCharge = _toDouble(json['per_km_shipping_charge']) ?? 0;
    open = _toInt(json['open']);
    active = _toBool(json['active']);
    featured = _toInt(json['featured']) ?? 0;
    zoneId = _toInt(json['zone_id']);
    deliveryTime = json['delivery_time']?.toString();
    veg = _toInt(json['veg']);
    nonVeg = _toInt(json['non_veg']);
    moduleId = _toInt(json['module_id']);
    moduleType = json['module_type']?.toString();
    orderPlaceToScheduleInterval = _toInt(json['order_place_to_schedule_interval']);
    if (json['category_ids'] is List) {
      categoryIds = (json['category_ids'] as List).map((dynamic v) => _toInt(v) ?? 0).toList();
    } else {
      if(json['categories'] != null && json['categories'] is List && json['categories'].isNotEmpty){
        categoryIds = List.from(json['categories'].map((e)=>e['id']));
      }else{
        categoryIds = [];
      }
    }
    if (json['category_names'] is List) {
      categoryNames = (json['category_names'] as List).map((dynamic v) => v?.toString() ?? '').toList();
    }
    // Some endpoints (e.g. stores/exclusive-deals) expose the store discount under
    // `store_discount`; fall back to it when `discount` isn't present.
    final dynamic discountJson = json['discount'] is Map<String, dynamic>
        ? json['discount']
        : (json['store_discount'] is Map<String, dynamic> ? json['store_discount'] : null);
    discount = discountJson != null ? Discount.fromJson(discountJson) : null;
    if (json['schedules'] != null) {
      schedules = <Schedules>[];
      json['schedules'].forEach((v) {
        schedules!.add(Schedules.fromJson(v));
      });
    }
    vendorId = _toInt(json['vendor_id']);
    prescriptionOrder = _toBool(json['prescription_order']) ?? false;
    cutlery = _toBool(json['cutlery']);
    slug = json['slug']?.toString();
    announcementActive = json['announcement'] == 1 || json['announcement'] == true;
    announcementMessage = json['announcement_message']?.toString();
    itemCount = _toInt(json['total_items']);
    if (json['items'] != null) {
      items = <Items>[];
      json['items'].forEach((v) {
        items!.add(Items.fromJson(v));
      });
    }
    if (json['top_items'] != null) {
      topItems = <TopItem>[];
      json['top_items'].forEach((v) {
        topItems!.add(TopItem.fromJson(v));
      });
    }
    extraPackagingStatus = _toBool(json['extra_packaging_status']) ?? false;
    extraPackagingAmount = _toDouble(json['extra_packaging_amount']) ?? 0;
    if (json['ratings'] != null && json['ratings'] != 0) {
      ratings = [];
      json['ratings'].forEach((v) {
        ratings!.add(v is int ? v : _toInt(v) ?? 0);
      });
    }
    reviewsCommentsCount = _toInt(json['reviews_comments_count']);
    storeSubscription = json['store_sub'] != null ? StoreSubscription.fromJson(json['store_sub']) : null;
    storeBusinessModel = json['store_business_model']?.toString();
    distance = _toDouble(json['distance']) ?? 0;
    distanceKm = _toDouble(json['distance_km']);
    minDeliveryTime = _toInt(json['min_delivery_time']);
    maxDeliveryTime = _toInt(json['max_delivery_time']);
    storeOpeningTime = json['current_opening_time']?.toString();
    verifiedSeller = _toInt(json['verified_seller']);
    avgItemDiscountPercentage = _toDouble(json['avg_item_discount_percentage']);
    if (json['offers'] is List) {
      offers = (json['offers'] as List).map((dynamic v) => StoreOffer.fromJson(v)).toList();
    }
    ad = _toInt(json['ad']);
    proDiscount = json['pro_discount'] != null ? Discount.fromJson(json['pro_discount']) : null;
    isNew = _toBool(json['is_new']);
    sponsored = _toBool(json['sponsored']);
    offerLabel = json['offer_label']?.toString();
    if (json['store_item_image_list'] != null) {
      storeItemImageList = [];
      json['store_item_image_list'].forEach((v) => storeItemImageList!.add(v));
    }
    description = json['description']?.toString();
    if (json['active_coupons'] != null) {
      activeCoupons = json['active_coupons'] is List ? json['active_coupons'] : [];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['phone'] = phone;
    data['email'] = email;
    data['logo_full_url'] = logoFullUrl;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['address'] = address;
    data['minimum_order'] = minimumOrder;
    data['currency'] = currency;
    data['free_delivery'] = freeDelivery;
    data['cover_photo_full_url'] = coverPhotoFullUrl;
    data['delivery'] = delivery;
    data['take_away'] = takeAway;
    data['schedule_order'] = scheduleOrder;
    data['avg_rating'] = avgRating;
    data['tax'] = tax;
    data['rating_count'] = ratingCount;
    data['reviews_count'] = reviewsCount;
    data['self_delivery_system'] = selfDeliverySystem;
    data['pos_system'] = posSystem;
    data['minimum_shipping_charge'] = minimumShippingCharge;
    data['maximum_shipping_charge'] = maximumShippingCharge;
    data['per_km_shipping_charge'] = perKmShippingCharge;
    data['open'] = open;
    data['active'] = active;
    data['veg'] = veg;
    data['featured'] = featured;
    data['zone_id'] = zoneId;
    data['non_veg'] = nonVeg;
    data['module_id'] = moduleId;
    data['module_type'] = moduleType;
    data['order_place_to_schedule_interval'] = orderPlaceToScheduleInterval;
    data['delivery_time'] = deliveryTime;
    data['min_delivery_time'] = minDeliveryTime;
    data['max_delivery_time'] = maxDeliveryTime;
    data['category_ids'] = categoryIds;
    data['category_names'] = categoryNames;
    if (discount != null) {
      data['discount'] = discount!.toJson();
    }
    if (schedules != null) {
      data['schedules'] = schedules!.map((v) => v.toJson()).toList();
    }
    data['vendor_id'] = vendorId;
    data['prescription_order'] = prescriptionOrder;
    data['cutlery'] = cutlery;
    data['slug'] = slug;
    data['announcement'] = announcementActive;
    data['announcement_message'] = announcementMessage;
    data['total_items'] = itemCount;
    if (items != null) {
      data['items'] = items!.map((v) => v.toJson()).toList();
    }
    if (topItems != null) {
      data['top_items'] = topItems!.map((v) => v.toJson()).toList();
    }
    data['extra_packaging_status'] = extraPackagingStatus;
    data['extra_packaging_amount'] = extraPackagingAmount;
    data['ratings'] = ratings;
    data['reviews_comments_count'] = reviewsCommentsCount;
    if (storeSubscription != null) {
      data['store_sub'] = storeSubscription!.toJson();
    }
    data['store_business_model'] = storeBusinessModel;
    data['distance'] = distance;
    data['distance_km'] = distanceKm;
    data['verified_seller'] = verifiedSeller;
    data['avg_item_discount_percentage'] = avgItemDiscountPercentage;
    if (offers != null) {
      data['offers'] = offers!.map((v) => v.toJson()).toList();
    }
    data['ad'] = ad;
    if (proDiscount != null) {
      data['pro_discount'] = proDiscount!.toJson();
    }
    data['is_new'] = isNew;
    data['sponsored'] = sponsored;
    data['offer_label'] = offerLabel;
    data['store_item_image_list'] = storeItemImageList;
    data['description'] = description;
    data['active_coupons'] = activeCoupons;
    return data;
  }
}

class Discount {
  int? id;
  String? startDate;
  String? endDate;
  String? startTime;
  String? endTime;
  double? minPurchase;
  double? maxDiscount;
  double? discount;
  String? discountType;
  int? storeId;
  String? createdAt;
  String? updatedAt;

  Discount({
    this.id, this.startDate, this.endDate, this.startTime, this.endTime,
    this.minPurchase, this.maxDiscount, this.discount, this.discountType, this.storeId,
    this.createdAt, this.updatedAt,
  });

  Discount.fromJson(Map<String, dynamic> json) {
    id = _toInt(json['id']);
    startDate = json['start_date']?.toString();
    endDate = json['end_date']?.toString();
    final String? rawStart = json['start_time']?.toString();
    startTime = (rawStart != null && rawStart.length >= 5) ? rawStart.substring(0, 5) : rawStart;
    final String? rawEnd = json['end_time']?.toString();
    endTime = (rawEnd != null && rawEnd.length >= 5) ? rawEnd.substring(0, 5) : rawEnd;
    minPurchase = _toDouble(json['min_purchase']);
    maxDiscount = _toDouble(json['max_discount']);
    discount = _toDouble(json['discount']);
    discountType = json['discount_type']?.toString();
    storeId = _toInt(json['store_id']);
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['start_date'] = startDate;
    data['end_date'] = endDate;
    data['start_time'] = startTime;
    data['end_time'] = endTime;
    data['min_purchase'] = minPurchase;
    data['max_discount'] = maxDiscount;
    data['discount'] = discount;
    data['discount_type'] = discountType;
    data['store_id'] = storeId;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class Schedules {
  int? id;
  int? storeId;
  int? day;
  String? openingTime;
  String? closingTime;

  Schedules({this.id, this.storeId, this.day, this.openingTime, this.closingTime});

  Schedules.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    storeId = json['store_id'];
    day = json['day'];
    openingTime = json['opening_time'].substring(0, 5);
    closingTime = json['closing_time'].substring(0, 5);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['store_id'] = storeId;
    data['day'] = day;
    data['opening_time'] = openingTime;
    data['closing_time'] = closingTime;
    return data;
  }
}

class Refund {
  int? id;
  int? orderId;
  List<String>? imageFullUrl;
  String? customerReason;
  String? customerNote;
  String? adminNote;

  Refund({this.id, this.orderId, this.imageFullUrl, this.customerReason, this.customerNote, this.adminNote});

  Refund.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    orderId = json['order_id'];
    if (json['image_full_url'] != null) {
      imageFullUrl = [];
      json['image_full_url'].forEach((v) {
        if (v != null) {
          imageFullUrl!.add(v);
        }
      });
    }
    customerReason = json['customer_reason'];
    customerNote = json['customer_note'];
    adminNote = json['admin_note'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['order_id'] = orderId;
    data['image_full_url'] = imageFullUrl;
    data['customer_reason'] = customerReason;
    data['customer_note'] = customerNote;
    data['admin_note'] = adminNote;
    return data;
  }
}

class Items {
  int? id;
  String? name;
  String? description;
  String? imageFullUrl;
  int? categoryId;
  String? categoryIds;
  String? variations;
  String? addOns;
  String? attributes;
  String? choiceOptions;
  double? price;
  double? tax;
  String? taxType;
  double? discount;
  String? discountType;
  String? availableTimeStarts;
  String? availableTimeEnds;
  int? veg;
  int? status;
  int? storeId;
  String? createdAt;
  String? updatedAt;
  int? orderCount;
  double? avgRating;
  int? ratingCount;
  String? rating;
  int? moduleId;
  int? stock;
  int? unitId;
  List<String>? images;
  String? foodVariations;
  String? slug;
  int? recommended;
  int? organic;
  int? maximumCartQuantity;
  int? isApproved;
  String? unitType;

  Items({
    this.id, this.name, this.description, this.imageFullUrl, this.categoryId,
    this.categoryIds, this.variations, this.addOns, this.attributes, this.choiceOptions,
    this.price, this.tax, this.taxType, this.discount, this.discountType,
    this.availableTimeStarts, this.availableTimeEnds, this.veg, this.status, this.storeId,
    this.createdAt, this.updatedAt, this.orderCount, this.avgRating, this.ratingCount,
    this.rating, this.moduleId, this.stock, this.unitId, this.images,
    this.foodVariations, this.slug, this.recommended, this.organic, this.maximumCartQuantity,
    this.isApproved, this.unitType,
  });

  Items.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    imageFullUrl = json['image_full_url'];
    categoryId = json['category_id'];
    categoryIds = json['category_ids'];
    variations = json['variations'];
    addOns = json['add_ons'];
    attributes = json['attributes'];
    choiceOptions = json['choice_options'];
    price = json['price']?.toDouble();
    tax = json['tax']?.toDouble();
    taxType = json['tax_type'];
    discount = json['discount']?.toDouble();
    discountType = json['discount_type'];
    availableTimeStarts = json['available_time_starts'];
    availableTimeEnds = json['available_time_ends'];
    veg = json['veg'];
    status = json['status'];
    storeId = json['store_id'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    orderCount = json['order_count'];
    avgRating = json['avg_rating']?.toDouble();
    ratingCount = json['rating_count'];
    rating = json['rating'];
    moduleId = json['module_id'];
    stock = json['stock'];
    unitId = json['unit_id'];
    images = json['images'] is List ? (json['images'] as List).cast<String>() : null;
    foodVariations = json['food_variations'];
    slug = json['slug'];
    recommended = json['recommended'];
    organic = json['organic'];
    maximumCartQuantity = json['maximum_cart_quantity'];
    isApproved = json['is_approved'];
    unitType = json['unit_type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['description'] = description;
    data['image_full_url'] = imageFullUrl;
    data['category_id'] = categoryId;
    data['category_ids'] = categoryIds;
    data['variations'] = variations;
    data['add_ons'] = addOns;
    data['attributes'] = attributes;
    data['choice_options'] = choiceOptions;
    data['price'] = price;
    data['tax'] = tax;
    data['tax_type'] = taxType;
    data['discount'] = discount;
    data['discount_type'] = discountType;
    data['available_time_starts'] = availableTimeStarts;
    data['available_time_ends'] = availableTimeEnds;
    data['veg'] = veg;
    data['status'] = status;
    data['store_id'] = storeId;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['order_count'] = orderCount;
    data['avg_rating'] = avgRating;
    data['rating_count'] = ratingCount;
    data['rating'] = rating;
    data['module_id'] = moduleId;
    data['stock'] = stock;
    data['unit_id'] = unitId;
    data['images'] = images;
    data['food_variations'] = foodVariations;
    data['slug'] = slug;
    data['recommended'] = recommended;
    data['organic'] = organic;
    data['maximum_cart_quantity'] = maximumCartQuantity;
    data['is_approved'] = isApproved;
    data['unit_type'] = unitType;
    return data;
  }
}

class TopItem {
  int? id;
  String? name;
  String? imageFullUrl;
  double? price;
  double? discountedPrice;
  double? discount;
  String? discountType;
  int? orderCount;
  double? avgRating;

  TopItem({
    this.id, this.name, this.imageFullUrl, this.price, this.discountedPrice,
    this.discount, this.discountType, this.orderCount, this.avgRating,
  });

  TopItem.fromJson(Map<String, dynamic> json) {
    id = _toInt(json['id']);
    name = json['name']?.toString();
    imageFullUrl = json['image_full_url']?.toString();
    price = _toDouble(json['price']);
    discountedPrice = _toDouble(json['discounted_price']);
    discount = _toDouble(json['discount']);
    discountType = json['discount_type']?.toString();
    orderCount = _toInt(json['order_count']);
    avgRating = _toDouble(json['avg_rating']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['image_full_url'] = imageFullUrl;
    data['price'] = price;
    data['discounted_price'] = discountedPrice;
    data['discount'] = discount;
    data['discount_type'] = discountType;
    data['order_count'] = orderCount;
    data['avg_rating'] = avgRating;
    return data;
  }
}

class StoreOffer {
  String? type;
  int? id;
  String? name;

  StoreOffer({this.type, this.id, this.name});

  StoreOffer.fromJson(Map<String, dynamic> json) {
    type = json['type']?.toString();
    id = _toInt(json['id']);
    name = json['name']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['id'] = id;
    data['name'] = name;
    return data;
  }
}

class StoreSubscription {
  int? id;
  int? packageId;
  int? storeId;
  String? expiryDate;
  String? maxOrder;
  String? maxProduct;
  int? pos;
  int? mobileApp;
  int? chat;
  int? review;
  int? selfDelivery;
  int? status;
  int? totalPackageRenewed;
  String? createdAt;
  String? updatedAt;

  StoreSubscription({
    this.id, this.packageId, this.storeId, this.expiryDate, this.maxOrder,
    this.maxProduct, this.pos, this.mobileApp, this.chat, this.review,
    this.selfDelivery, this.status, this.totalPackageRenewed, this.createdAt, this.updatedAt,
  });

  StoreSubscription.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    packageId = json['package_id'];
    storeId = json['store_id'];
    expiryDate = json['expiry_date'];
    maxOrder = json['max_order'];
    maxProduct = json['max_product'];
    pos = json['pos'];
    mobileApp = json['mobile_app'];
    chat = (json['chat'] != null && json['chat'] != 'null') ? json['chat'] : 0;
    review = json['review'] ?? 0;
    selfDelivery = json['self_delivery'];
    status = json['status'];
    totalPackageRenewed = json['total_package_renewed'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['package_id'] = packageId;
    data['store_id'] = storeId;
    data['expiry_date'] = expiryDate;
    data['max_order'] = maxOrder;
    data['max_product'] = maxProduct;
    data['pos'] = pos;
    data['mobile_app'] = mobileApp;
    data['chat'] = chat;
    data['review'] = review;
    data['self_delivery'] = selfDelivery;
    data['status'] = status;
    data['total_package_renewed'] = totalPackageRenewed;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
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

bool? _toBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final String s = value.toString().toLowerCase();
  if (s == 'true' || s == '1') return true;
  if (s == 'false' || s == '0') return false;
  return null;
}
