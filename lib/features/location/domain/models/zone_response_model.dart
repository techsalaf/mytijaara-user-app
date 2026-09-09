class ZoneResponseModel {
  final bool _isSuccess;
  final List<int> _zoneIds;
  final String? _message;
  final List<ZoneData> _zoneData;
  final List<int> _areaIds;
  final int? statusCode;
  final String? _zoneId;
  ZoneResponseModel(this._isSuccess, this._message, this._zoneIds, this._zoneData, this._areaIds, this.statusCode, this._zoneId);

  String? get message => _message;
  List<int> get zoneIds => _zoneIds;
  bool get isSuccess => _isSuccess;
  List<ZoneData> get zoneData => _zoneData;
  List<int> get areaIds => _areaIds;
  int? get status => statusCode;
  String? get zoneId => _zoneId;
}

class ZoneData {
  int? id;
  int? status;
  bool? cashOnDelivery;
  bool? digitalPayment;
  bool? offlinePayment;
  double? increaseDeliveryFee;
  int? increaseDeliveryFeeStatus;
  String? increaseDeliveryFeeMessage;
  List<Modules>? modules;

  ZoneData({
    this.id, this.status, this.cashOnDelivery, this.digitalPayment, this.offlinePayment,
    this.increaseDeliveryFee, this.increaseDeliveryFeeStatus, this.increaseDeliveryFeeMessage, this.modules,
  });

  ZoneData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    status = json['status'];
    cashOnDelivery = json['cash_on_delivery'];
    digitalPayment = json['digital_payment'];
    offlinePayment = json['offline_payment'];
    increaseDeliveryFee = json['increased_delivery_fee']?.toDouble();
    increaseDeliveryFeeStatus = json['increased_delivery_fee_status'];
    increaseDeliveryFeeMessage = json['increase_delivery_charge_message'];
    if (json['modules'] != null) {
      modules = <Modules>[];
      json['modules'].forEach((v) {
        modules!.add(Modules.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['status'] = status;
    data['cash_on_delivery'] = cashOnDelivery;
    data['digital_payment'] = digitalPayment;
    data['offline_payment'] = offlinePayment;
    if (modules != null) {
      data['modules'] = modules!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class MinimumDeliveryTime {
  int? value;
  String? unit;

  MinimumDeliveryTime({this.value, this.unit});

  MinimumDeliveryTime.fromJson(Map<String, dynamic> json) {
    value = json['value'];
    unit = json['unit'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['value'] = value;
    data['unit'] = unit;
    return data;
  }
}

class DeliveryOptions {
  int? id;
  int? zoneId;
  String? deliveryType;
  double? extraCharge;
  double? reduceCharge;
  MinimumDeliveryTime? addDeliveryTime;
  MinimumDeliveryTime? reduceDeliveryTime;
  String? createdAt;
  String? updatedAt;

  DeliveryOptions({
    this.id, this.zoneId, this.deliveryType, this.extraCharge, this.reduceCharge,
    this.addDeliveryTime, this.reduceDeliveryTime, this.createdAt, this.updatedAt,
  });

  DeliveryOptions.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    zoneId = json['zone_id'];
    deliveryType = json['delivery_type'];
    extraCharge = double.tryParse(json['extra_charge'].toString());
    reduceCharge = double.tryParse(json['reduce_charge'].toString());
    addDeliveryTime = json['add_delivery_time'] != null
        ? MinimumDeliveryTime.fromJson(json['add_delivery_time'])
        : null;
    reduceDeliveryTime = json['reduce_delivery_time'] != null
        ? MinimumDeliveryTime.fromJson(json['reduce_delivery_time'])
        : null;
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['zone_id'] = zoneId;
    data['delivery_type'] = deliveryType;
    data['extra_charge'] = extraCharge;
    data['reduce_charge'] = reduceCharge;
    if (addDeliveryTime != null) {
      data['add_delivery_time'] = addDeliveryTime!.toJson();
    }
    if (reduceDeliveryTime != null) {
      data['reduce_delivery_time'] = reduceDeliveryTime!.toJson();
    }
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class Modules {
  int? id;
  String? moduleName;
  String? moduleType;
  String? thumbnail;
  String? status;
  int? storesCount;
  String? createdAt;
  String? updatedAt;
  String? icon;
  int? themeId;
  String? description;
  int? allZoneService;
  bool? additionalDeliveryOptionStatus;
  List<DeliveryOptions>? deliveryOptions;
  Pivot? pivot;

  Modules({
    this.id, this.moduleName, this.moduleType, this.thumbnail, this.status,
    this.storesCount, this.createdAt, this.updatedAt, this.icon, this.themeId,
    this.description, this.allZoneService, this.additionalDeliveryOptionStatus, this.deliveryOptions, this.pivot,
  });

  Modules.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    moduleName = json['module_name'];
    moduleType = json['module_type'];
    thumbnail = json['thumbnail'];
    status = json['status'];
    storesCount = json['stores_count'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    icon = json['icon'];
    themeId = json['theme_id'];
    description = json['description'];
    allZoneService = json['all_zone_service'];
    additionalDeliveryOptionStatus = json['additional_delivery_option_status'] ?? false;
    if (json['delivery_options'] != null) {
      deliveryOptions = <DeliveryOptions>[];
      json['delivery_options'].forEach((v) {
        deliveryOptions!.add(DeliveryOptions.fromJson(v));
      });
    }
    pivot = json['pivot'] != null ? Pivot.fromJson(json['pivot']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['module_name'] = moduleName;
    data['module_type'] = moduleType;
    data['thumbnail'] = thumbnail;
    data['status'] = status;
    data['stores_count'] = storesCount;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['icon'] = icon;
    data['theme_id'] = themeId;
    data['description'] = description;
    data['all_zone_service'] = allZoneService;
    data['additional_delivery_option_status'] = additionalDeliveryOptionStatus;
    if (deliveryOptions != null) {
      data['delivery_options'] = deliveryOptions!.map((v) => v.toJson()).toList();
    }
    if (pivot != null) {
      data['pivot'] = pivot!.toJson();
    }
    return data;
  }
}

class Pivot {
  int? zoneId;
  int? moduleId;
  double? perKmShippingCharge;
  double? minimumShippingCharge;
  double? maximumShippingCharge;
  double? maximumCodOrderAmount;
  String? deliveryChargeType;
  double? fixedShippingCharge;
  MinimumDeliveryTime? minimumDeliveryTime;
  double? minimumDeliveryCharge;

  Pivot({
    this.zoneId, this.moduleId, this.perKmShippingCharge, this.minimumShippingCharge, this.maximumShippingCharge,
    this.maximumCodOrderAmount, this.deliveryChargeType, this.fixedShippingCharge, this.minimumDeliveryTime, this.minimumDeliveryCharge,
  });

  Pivot.fromJson(Map<String, dynamic> json) {
    zoneId = json['zone_id'];
    moduleId = json['module_id'];
    perKmShippingCharge = json['per_km_shipping_charge']?.toDouble();
    minimumShippingCharge = json['minimum_shipping_charge']?.toDouble();
    maximumShippingCharge =  json['maximum_shipping_charge']?.toDouble();
    maximumCodOrderAmount = json['maximum_cod_order_amount']?.toDouble();
    deliveryChargeType = json['delivery_charge_type'];
    fixedShippingCharge = double.tryParse(json['fixed_shipping_charge'].toString()) ?? 0.0;
    final dynamic rawMinDeliveryTime = json['minimum_delivery_time'];
    if(rawMinDeliveryTime is Map<String, dynamic>) {
      minimumDeliveryTime = MinimumDeliveryTime.fromJson(rawMinDeliveryTime);
    } else if(rawMinDeliveryTime != null) {
      minimumDeliveryTime = MinimumDeliveryTime(value: int.tryParse(rawMinDeliveryTime.toString()), unit: 'min');
    }
    minimumDeliveryCharge = json['minimum_delivery_charge']?.toDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['zone_id'] = zoneId;
    data['module_id'] = moduleId;
    data['per_km_shipping_charge'] = perKmShippingCharge;
    data['minimum_shipping_charge'] = minimumShippingCharge;
    data['maximum_shipping_charge'] = maximumShippingCharge;
    data['maximum_cod_order_amount'] = maximumCodOrderAmount;
    data['delivery_charge_type'] = deliveryChargeType;
    data['fixed_shipping_charge'] = fixedShippingCharge;
    if (minimumDeliveryTime != null) {
      data['minimum_delivery_time'] = minimumDeliveryTime!.toJson();
    }
    data['minimum_delivery_charge'] = minimumDeliveryCharge;
    return data;
  }
}
