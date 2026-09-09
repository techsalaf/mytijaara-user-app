import 'package:sixam_mart/features/pro/domain/models/pro_active_offer_model.dart';
import 'package:sixam_mart/helper/type_converter_helper.dart';

enum ProPlanType {
  freeTrial('free_trial'),
  paid('paid');

  final String value;
  const ProPlanType(this.value);
}

class ProPlanModel {
  bool? proMemberStatus;
  String? proBrand;
  List<PlanItem>? plans;
  PlanBenefits? benefits;

  ProPlanModel({
    this.proMemberStatus,
    this.proBrand,
    this.plans,
    this.benefits,
  });

  ProPlanModel.fromJson(Map<String, dynamic> json) {
    proMemberStatus = TypeConverterHelper.getBool(json['pro_member_status']);
    proBrand = json['pro_brand'];
    if (json['plans'] != null) {
      plans = List<PlanItem>.from(json['plans'].map((e) => PlanItem.fromJson(e)));
    }
    benefits = json['benefits'] != null ? PlanBenefits.fromJson(json['benefits']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['pro_member_status'] = proMemberStatus;
    data['pro_brand'] = proBrand;
    if (plans != null) {
      data['plans'] = plans!.map((e) => e.toJson()).toList();
    }
    if (benefits != null) {
      data['benefits'] = benefits!.toJson();
    }
    return data;
  }
}

class PlanItem {
  int? id;
  String? planName;
  ProPlanType? planType;
  double? price;
  int? duration;
  String? durationLabel;
  bool? status;

  PlanItem({
    this.id,
    this.planName,
    this.planType,
    this.price,
    this.duration,
    this.durationLabel,
    this.status,
  });

  PlanItem.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    planName = json['plan_name'];
    planType = _getPlanType(json['plan_type']);
    price = json['price']?.toDouble();
    duration = json['duration'];
    durationLabel = json['duration_label'];
    status = TypeConverterHelper.getBool(json['status']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['plan_name'] = planName;
    data['plan_type'] = planType?.value;
    data['price'] = price;
    data['duration'] = duration;
    data['duration_label'] = durationLabel;
    data['status'] = status;
    return data;
  }

  ProPlanType _getPlanType(dynamic value) {
    return ProPlanType.values.firstWhere((type) => type.value == value, orElse: () => ProPlanType.paid);
  }
}

class PlanBenefits {
  String? activeType;
  DiscountBenefit? discount;
  DeliveryFeeBenefit? deliveryFee;
  CouponBenefit? coupon;

  PlanBenefits({
    this.activeType,
    this.discount,
    this.deliveryFee,
    this.coupon,
  });

  PlanBenefits.fromJson(Map<String, dynamic> json) {
    activeType = json['active_type'];
    discount = json['discount'] != null ? DiscountBenefit.fromJson(json['discount']) : null;
    deliveryFee = json['delivery_fee'] != null ? DeliveryFeeBenefit.fromJson(json['delivery_fee']) : null;
    coupon = json['coupon'] != null ? CouponBenefit.fromJson(json['coupon']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['active_type'] = activeType;
    if (discount != null) data['discount'] = discount!.toJson();
    if (deliveryFee != null) data['delivery_fee'] = deliveryFee!.toJson();
    if (coupon != null) data['coupon'] = coupon!.toJson();
    return data;
  }
}

class DiscountBenefit {
  int? active;
  String? setupMode;
  DiscountConfig? config;
  Map<String, DiscountConfig>? modules;

  DiscountBenefit({
    this.active,
    this.setupMode,
    this.config,
    this.modules,
  });

  DiscountBenefit.fromJson(Map<String, dynamic> json) {
    active = json['active'];
    setupMode = json['setup_mode'];
    config = json['config'] != null ? DiscountConfig.fromJson(json['config']) : null;
    if (json['modules'] != null && json['modules'] is Map) {
      modules = {};
      (json['modules'] as Map<String, dynamic>).forEach((key, value) {
        if (value != null) {
          modules![key] = DiscountConfig.fromJson(value);
        }
      });
    }
  }

  /// Resolves the discount config for a given module.
  /// central -> single config; individual -> per-module config.
  DiscountConfig? configForModule(String? moduleType) {
    if (setupMode == 'central') return config;
    if (setupMode == 'individual') {
      return (moduleType != null && modules != null) ? modules![moduleType] : null;
    }
    return config ?? ((modules != null && modules!.isNotEmpty) ? modules!.values.first : null);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['active'] = active;
    data['setup_mode'] = setupMode;
    if (config != null) data['config'] = config!.toJson();
    if (modules != null) {
      data['modules'] = modules!.map((key, value) => MapEntry(key, value.toJson()));
    }
    return data;
  }
}

class DiscountConfig {
  double? percentage;
  double? maxAmount;
  bool? minOrderStatus;
  double? minOrderAmount;

  DiscountConfig({
    this.percentage,
    this.maxAmount,
    this.minOrderStatus,
    this.minOrderAmount,
  });

  DiscountConfig.fromJson(Map<String, dynamic> json) {
    percentage = json['percentage']?.toDouble();
    maxAmount = json['max_amount']?.toDouble();
    minOrderStatus = TypeConverterHelper.getBool(json['min_order_status']);
    minOrderAmount = json['min_order_amount']?.toDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['percentage'] = percentage;
    data['max_amount'] = maxAmount;
    data['min_order_status'] = minOrderStatus;
    data['min_order_amount'] = minOrderAmount;
    return data;
  }
}

class DeliveryFeeBenefit {
  int? active;
  Map<String, DeliveryFeeModuleBenefit>? modules;

  DeliveryFeeBenefit({
    this.active,
    this.modules,
  });

  DeliveryFeeBenefit.fromJson(Map<String, dynamic> json) {
    active = json['active'];
    if (json['modules'] != null && json['modules'] is Map) {
      modules = {};
      (json['modules'] as Map<String, dynamic>).forEach((key, value) {
        if (value != null) {
          modules![key] = DeliveryFeeModuleBenefit.fromJson(value);
        }
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['active'] = active;
    if (modules != null) {
      data['modules'] = modules!.map((key, value) => MapEntry(key, value.toJson()));
    }
    return data;
  }
}

class DeliveryFeeModuleBenefit {
  ProOfferType? offerType;
  bool? minOrderStatus;
  double? minOrderAmount;
  double? chargeDiscountPercentage;

  DeliveryFeeModuleBenefit({
    this.offerType,
    this.minOrderStatus,
    this.minOrderAmount,
    this.chargeDiscountPercentage,
  });

  DeliveryFeeModuleBenefit.fromJson(Map<String, dynamic> json) {
    offerType = ProOfferType.fromString(json['offer_type']);
    minOrderStatus = TypeConverterHelper.getBool(json['min_order_status']);
    minOrderAmount = json['min_order_amount']?.toDouble();
    chargeDiscountPercentage = json['charge_discount_percentage']?.toDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['offer_type'] = offerType?.toJson();
    data['min_order_status'] = minOrderStatus;
    data['min_order_amount'] = minOrderAmount;
    data['charge_discount_percentage'] = chargeDiscountPercentage;
    return data;
  }
}

class CouponBenefit {
  bool? active;

  CouponBenefit({this.active});

  CouponBenefit.fromJson(Map<String, dynamic> json) {
    active = TypeConverterHelper.getBool(json['active']);
  }

  Map<String, dynamic> toJson() => {'active': active};
}
