class TopOfferModel {
  int? moduleId;
  double? discount;
  String? discountType;

  TopOfferModel({this.moduleId, this.discount, this.discountType});

  TopOfferModel.fromJson(Map<String, dynamic> json) {
    moduleId = json['module_id'] is int ? json['module_id'] : int.tryParse(json['module_id']?.toString() ?? '');
    discount = (json['discount'] as num?)?.toDouble();
    discountType = json['discount_type']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['module_id'] = moduleId;
    data['discount'] = discount;
    data['discount_type'] = discountType;
    return data;
  }
}
