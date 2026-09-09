class VehicleModel {
  int? id;
  String? name;
  String? description;
  String? thumbnail;
  String? images;
  int? providerId;
  int? brandId;
  int? categoryId;
  String? model;
  String? type;
  String? engineCapacity;
  String? enginePower;
  String? seatingCapacity;
  bool? airCondition;
  String? fuelType;
  String? transmissionType;
  int? multipleVehicles;
  bool? tripHourly;
  bool? tripDistance;
  bool? tripDayWise;
  double? hourlyPrice;
  double? distancePrice;
  double? dayWisePrice;
  String? discountType;
  double? discountPrice;
  String? tag;
  String? documents;
  int? status;
  int? newTag;
  int? totalTrip;
  double? avgRating;
  int? totalReviews;
  String? createdAt;
  String? updatedAt;
  int? zoneId;
  int? vehicleIdentitiesCount;
  int? totalVehicles;
  String? thumbnailFullUrl;
  List<String>? imagesFullUrl;
  List<String>? documentsFullUrl;
  Brand? brand;
  Provider? provider;
  int? verifiedSeller;

  VehicleModel(
      {this.id,
        this.name,
        this.description,
        this.thumbnail,
        this.images,
        this.providerId,
        this.brandId,
        this.categoryId,
        this.model,
        this.type,
        this.engineCapacity,
        this.enginePower,
        this.seatingCapacity,
        this.airCondition,
        this.fuelType,
        this.transmissionType,
        this.multipleVehicles,
        this.tripHourly,
        this.tripDistance,
        this.tripDayWise,
        this.hourlyPrice,
        this.distancePrice,
        this.dayWisePrice,
        this.discountType,
        this.discountPrice,
        this.tag,
        this.documents,
        this.status,
        this.newTag,
        this.totalTrip,
        this.avgRating,
        this.totalReviews,
        this.createdAt,
        this.updatedAt,
        this.zoneId,
        this.vehicleIdentitiesCount,
        this.totalVehicles,
        this.thumbnailFullUrl,
        this.imagesFullUrl,
        this.documentsFullUrl,
        this.brand,
        this.provider,
        this.verifiedSeller,
      });

  VehicleModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    thumbnail = json['thumbnail'];
    images = json['images'];
    providerId = json['provider_id'];
    brandId = json['brand_id'];
    categoryId = json['category_id'];
    model = json['model'];
    type = json['type'];
    engineCapacity = json['engine_capacity'];
    enginePower = json['engine_power'];
    seatingCapacity = json['seating_capacity'];
    airCondition = json['air_condition'].toString() == '1';
    fuelType = json['fuel_type'];
    transmissionType = json['transmission_type'];
    multipleVehicles = json['multiple_vehicles'];
    tripHourly = json['trip_hourly'].toString() == '1';
    tripDistance = json['trip_distance'].toString() == '1';
    tripDayWise = json['trip_day_wise'].toString() == '1';
    hourlyPrice = json['hourly_price']?.toDouble();
    distancePrice = json['distance_price']?.toDouble();
    dayWisePrice = json['day_wise_price']?.toDouble();
    discountType = json['discount_type'];
    discountPrice = json['discount_price']?.toDouble();
    tag = json['tag'];
    documents = json['documents'];
    status = json['status'];
    newTag = json['new_tag'];
    totalTrip = json['total_trip'];
    // avgRating = json['avg_rating']?.toDouble();
    avgRating = json['avg_rating'] != null ? double.parse(json['avg_rating'].toString()) : 0;
    totalReviews = json['total_reviews'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    zoneId = json['zone_id'];
    vehicleIdentitiesCount = json['total_vehicle_count'];
    totalVehicles = json['total_vehicles'];
    thumbnailFullUrl = json['thumbnail_full_url'];
    imagesFullUrl = (json['images_full_url'] as List?)?.whereType<String>().toList();
    if (json['documents_full_url'] != null) {
      documentsFullUrl = <String>[];
      json['documents_full_url'].forEach((v) {
        if(v != null) {
          documentsFullUrl!.add(v);
        }
      });
    }
    brand = json['brand'] != null ? Brand.fromJson(json['brand']) : null;
    provider = json['provider'] != null
        ? Provider.fromJson(json['provider'])
        : null;
    verifiedSeller = json['verified_seller'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['description'] = description;
    data['thumbnail'] = thumbnail;
    data['images'] = images;
    data['provider_id'] = providerId;
    data['brand_id'] = brandId;
    data['category_id'] = categoryId;
    data['model'] = model;
    data['type'] = type;
    data['engine_capacity'] = engineCapacity;
    data['engine_power'] = enginePower;
    data['seating_capacity'] = seatingCapacity;
    data['air_condition'] = airCondition;
    data['fuel_type'] = fuelType;
    data['transmission_type'] = transmissionType;
    data['multiple_vehicles'] = multipleVehicles;
    data['trip_hourly'] = tripHourly;
    data['trip_distance'] = tripDistance;
    data['trip_day_wise'] = tripDayWise;
    data['hourly_price'] = hourlyPrice;
    data['distance_price'] = distancePrice;
    data['day_wise_price'] = dayWisePrice;
    data['discount_type'] = discountType;
    data['discount_price'] = discountPrice;
    data['tag'] = tag;
    data['documents'] = documents;
    data['status'] = status;
    data['new_tag'] = newTag;
    data['total_trip'] = totalTrip;
    data['avg_rating'] = avgRating;
    data['total_reviews'] = totalReviews;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['zone_id'] = zoneId;
    data['total_vehicle_count'] = vehicleIdentitiesCount;
    data['total_vehicles'] = totalVehicles;
    data['thumbnail_full_url'] = thumbnailFullUrl;
    data['images_full_url'] = imagesFullUrl;
    if (documentsFullUrl != null) {
      data['documents_full_url'] = documentsFullUrl!.map((v) => v).toList();
    }
    if (brand != null) {
      data['brand'] = brand!.toJson();
    }
    if (provider != null) {
      data['provider'] = provider!.toJson();
    }
    data['verified_seller'] = verifiedSeller;
    return data;
  }
}

class Brand {
  int? id;
  String? name;
  String? image;
  String? imageFullUrl;

  Brand({this.id, this.name, this.image, this.imageFullUrl});

  Brand.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    image = json['image'];
    imageFullUrl = json['image_full_url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['image'] = image;
    data['image_full_url'] = imageFullUrl;
    return data;
  }
}

class Provider {
  int? id;
  String? name;
  String? logo;
  String? coverPhoto;
  List<int>? rating;
  double? avgRating;
  int? ratingCount;
  bool? gstStatus;
  String? gstCode;
  String? logoFullUrl;
  String? coverPhotoFullUrl;
  String? metaImageFullUrl;
  Discount? discount;
  List<Translations>? translations;
  List<Storage>? storage;
  int? verifiedSeller;

  Provider(
      {this.id,
        this.name,
        this.logo,
        this.coverPhoto,
        this.rating,
        this.avgRating,
        this.ratingCount,
        this.gstStatus,
        this.gstCode,
        this.logoFullUrl,
        this.coverPhotoFullUrl,
        this.metaImageFullUrl,
        this.discount,
        this.translations,
        this.verifiedSeller,
        this.storage});

  Provider.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    logo = json['logo'];
    coverPhoto = json['cover_photo'];
    // rating = json['rating'];
    if(json['rating'] != null) {
      rating = [];
      json['rating'].forEach((v) {
        rating!.add(v);
      });
    }
    avgRating = json['avg_rating']?.toDouble();
    ratingCount = json['rating_count'];
    gstStatus = json['gst_status'];
    gstCode = json['gst_code'];
    logoFullUrl = json['logo_full_url'];
    coverPhotoFullUrl = json['cover_photo_full_url'];
    metaImageFullUrl = json['meta_image_full_url'];
    discount = json['discount'] != null ? Discount.fromJson(json['discount']) : null;
    if (json['translations'] != null) {
      translations = <Translations>[];
      json['translations'].forEach((v) {
        translations!.add(Translations.fromJson(v));
      });
    }
    if (json['storage'] != null) {
      storage = <Storage>[];
      json['storage'].forEach((v) {
        storage!.add(Storage.fromJson(v));
      });
    }
    verifiedSeller = json['verified_seller'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['logo'] = logo;
    data['cover_photo'] = coverPhoto;
    data['rating'] = rating;
    data['avg_rating'] = avgRating;
    data['rating_count'] = ratingCount;
    data['gst_status'] = gstStatus;
    data['gst_code'] = gstCode;
    data['logo_full_url'] = logoFullUrl;
    data['cover_photo_full_url'] = coverPhotoFullUrl;
    data['meta_image_full_url'] = metaImageFullUrl;
    if (discount != null) {
      data['discount'] = discount!.toJson();
    }
    if (translations != null) {
      data['translations'] = translations!.map((v) => v.toJson()).toList();
    }
    if (storage != null) {
      data['storage'] = storage!.map((v) => v.toJson()).toList();
    }
    data['verified_seller'] = verifiedSeller;
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

  Discount({this.id, this.startDate, this.endDate, this.startTime, this.endTime, this.minPurchase, this.maxDiscount, this.discount, this.discountType, this.storeId, this.createdAt, this.updatedAt});

  Discount.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    startDate = json['start_date'];
    endDate = json['end_date'];
    startTime = json['start_time'];
    endTime = json['end_time'];
    minPurchase = json['min_purchase']?.toDouble();
    maxDiscount = json['max_discount']?.toDouble();
    discount = json['discount']?.toDouble();
    discountType = json['discount_type'];
    storeId = json['store_id'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
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

class Translations {
  int? id;
  String? translationableType;
  int? translationableId;
  String? locale;
  String? key;
  String? value;
  String? createdAt;
  String? updatedAt;

  Translations(
      {this.id,
        this.translationableType,
        this.translationableId,
        this.locale,
        this.key,
        this.value,
        this.createdAt,
        this.updatedAt});

  Translations.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    translationableType = json['translationable_type'];
    translationableId = json['translationable_id'];
    locale = json['locale'];
    key = json['key'];
    value = json['value'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['translationable_type'] = translationableType;
    data['translationable_id'] = translationableId;
    data['locale'] = locale;
    data['key'] = key;
    data['value'] = value;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class Storage {
  int? id;
  String? dataType;
  String? dataId;
  String? key;
  String? value;
  String? createdAt;
  String? updatedAt;

  Storage(
      {this.id,
        this.dataType,
        this.dataId,
        this.key,
        this.value,
        this.createdAt,
        this.updatedAt});

  Storage.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    dataType = json['data_type'];
    dataId = json['data_id'];
    key = json['key'];
    value = json['value'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['data_type'] = dataType;
    data['data_id'] = dataId;
    data['key'] = key;
    data['value'] = value;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}