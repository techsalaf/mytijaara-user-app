import 'package:sixam_mart/helper/type_converter_helper.dart';

class ProActiveOfferModel {
  bool? status;
  String? message;
  ProActiveBenefit? benefit;
  ProActivePlanDetails? planDetails;

  ProActiveOfferModel({this.status, this.message, this.benefit, this.planDetails});

  ProActiveOfferModel.fromJson(Map<String, dynamic> json) {
    status = TypeConverterHelper.getBool(json['status']);
    message = json['message'];
    benefit = json['benefit'] != null ? ProActiveBenefit.fromJson(json['benefit']) : null;
    planDetails = json['plan_details'] != null ? ProActivePlanDetails.fromJson(json['plan_details']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    if (benefit != null) {
      data['benefit'] = benefit!.toJson();
    }
    if (planDetails != null) {
      data['plan_details'] = planDetails!.toJson();
    }
    return data;
  }
}

class ProActiveBenefit {
  // common
  ProBenefitType? type;
  int? subscriptionId;
  int? planId;
  // discount
  double? percentage;
  double? maxAmount;
  bool? minOrderStatus;
  double? minOrderAmount;
  // coupon
  // delivery
  ProOfferType? offerType;
  double? chargeDiscountPercentage;

  ProActiveBenefit({this.type, this.subscriptionId, this.planId, this.percentage, this.maxAmount, this.minOrderStatus, this.minOrderAmount, this.offerType, this.chargeDiscountPercentage,});

  ProActiveBenefit.fromJson(Map<String, dynamic> json) {
    // common
    type = ProBenefitType.fromString(json['type']);
    subscriptionId = json['subscription_id'];
    planId = json['plan_id'];
    // discount
    percentage = json['percentage']?.toDouble();
    maxAmount = json['max_amount']?.toDouble();
    minOrderStatus = TypeConverterHelper.getBool(json['min_order_status']);
    minOrderAmount = json['min_order_amount']?.toDouble();
    // coupon
    // delivery
    offerType = ProOfferType.fromString(json['offer_type']);
    chargeDiscountPercentage = json['charge_discount_percentage']?.toDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    // common
    data['type'] = type?.name == 'deliveryFee' ? 'delivery_fee' : type?.name;
    data['subscription_id'] = subscriptionId;
    data['plan_id'] = planId;
    // discount
    data['percentage'] = percentage;
    data['max_amount'] = maxAmount;
    data['min_order_status'] = minOrderStatus;
    data['min_order_amount'] = minOrderAmount;
    // coupon
    // delivery
    data['offer_type'] = offerType?.toJson();
    data['charge_discount_percentage'] = chargeDiscountPercentage;
    return data;
  }
}

class ProActivePlanDetails {
  String? planName;
  double? totalSaved;
  int? totalOrders;
  String? startAt;
  String? endAt;
  int? daysRemaining;
  String? paidBy;

  ProActivePlanDetails({this.planName, this.totalSaved, this.totalOrders, this.startAt, this.endAt, this.daysRemaining, this.paidBy});

  ProActivePlanDetails.fromJson(Map<String, dynamic> json) {
    planName = json['plan_name'];
    totalSaved = json['total_saved']?.toDouble();
    totalOrders = json['total_orders'];
    startAt = json['start_at'];
    endAt = json['end_at'];
    daysRemaining = json['days_remaining'];
    paidBy = json['paid_by'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['plan_name'] = planName;
    data['total_saved'] = totalSaved;
    data['total_orders'] = totalOrders;
    data['start_at'] = startAt;
    data['end_at'] = endAt;
    data['days_remaining'] = daysRemaining;
    data['paid_by'] = paidBy;
    return data;
  }
}

enum ProBenefitType {
  discount,
  deliveryFee,
  coupon;

  static ProBenefitType? fromString(String? value) {
    if (value == null) return null;
    const map = {
      'discount': ProBenefitType.discount,
      'delivery_fee': ProBenefitType.deliveryFee,
      'coupon': ProBenefitType.coupon,
    };
    return map[value] ?? ProBenefitType.discount;
  }
}

enum ProOfferType {
  fullFree,
  partialFree;

  static ProOfferType? fromString(String? value) {
    if (value == null) return null;
    const map = {
      'full_free': ProOfferType.fullFree,
      'partial_free': ProOfferType.partialFree,
    };
    return map[value];
  }

  String toJson() {
    const map = {
      ProOfferType.fullFree: 'full_free',
      ProOfferType.partialFree: 'partial_free',
    };
    return map[this]!;
  }
}
