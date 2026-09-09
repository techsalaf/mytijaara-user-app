
class ModuleModel {
  int? id;
  String? moduleName;
  String? moduleType;
  String? slug;
  String? thumbnailFullUrl;
  String? iconFullUrl;
  int? themeId;
  String? shortDescription;
  String? description;
  int? storesCount;
  String? createdAt;
  String? updatedAt;
  List<ModuleZoneData>? zones;
  TopOffer? topOffer;
  String? minDeliveryTime;
  int? flashSale;
  int? freeDelivery;

  ModuleModel({
    this.id,
    this.moduleName,
    this.moduleType,
    this.slug,
    this.thumbnailFullUrl,
    this.storesCount,
    this.iconFullUrl,
    this.themeId,
    this.shortDescription,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.zones,
    this.topOffer,
    this.minDeliveryTime,
    this.flashSale,
    this.freeDelivery,
  });

  ModuleModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    moduleName = json['module_name'];
    moduleType = json['module_type'];
    slug = json['slug'];
    thumbnailFullUrl = json['thumbnail_full_url'];
    iconFullUrl = json['icon_full_url'];
    themeId = json['theme_id'];
    shortDescription = json['short_description'];
    description = json['description'];
    storesCount = json['stores_count'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    if (json['zones'] != null) {
      zones = <ModuleZoneData>[];
      json['zones'].forEach((v) => zones!.add(ModuleZoneData.fromJson(v)));
    }
    topOffer = json['top_offer'] != null
        ? TopOffer.fromJson(json['top_offer'])
        : null;
    minDeliveryTime = json['min_delivery_time'];
    flashSale = json['flash_sale'];
    freeDelivery = json['free_delivery'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['module_name'] = moduleName;
    data['module_type'] = moduleType;
    data['slug'] = slug;
    data['thumbnail_full_url'] = thumbnailFullUrl;
    data['icon_full_url'] = iconFullUrl;
    data['theme_id'] = themeId;
    data['short_description'] = shortDescription;
    data['description'] = description;
    data['stores_count'] = storesCount;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (zones != null) {
      data['zones'] = zones!.map((v) => v.toJson()).toList();
    }
    if (topOffer != null) {
      data['top_offer'] = topOffer!.toJson();
    }
    data['min_delivery_time'] = minDeliveryTime;
    data['flash_sale'] = flashSale;
    data['free_delivery'] = freeDelivery;
    return data;
  }
}

class ModuleZoneData {
  int? id;
  String? name;
  int? status;
  String? createdAt;
  String? updatedAt;
  bool? cashOnDelivery;
  bool? digitalPayment;

  ModuleZoneData({
    this.id,
    this.name,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.cashOnDelivery,
    this.digitalPayment,
  });

  ModuleZoneData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    cashOnDelivery = json['cash_on_delivery'];
    digitalPayment = json['digital_payment'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['status'] = status;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['cash_on_delivery'] = cashOnDelivery;
    data['digital_payment'] = digitalPayment;
    return data;
  }
}

class TopOffer {
  int? discount;
  String? discountType;

  TopOffer({this.discount, this.discountType});

  TopOffer.fromJson(Map<String, dynamic> json) {
    discount = json['discount'];
    discountType = json['discount_type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['discount'] = discount;
    data['discount_type'] = discountType;
    return data;
  }
}