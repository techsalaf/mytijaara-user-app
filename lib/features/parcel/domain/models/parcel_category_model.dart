import 'package:sixam_mart/api/json_reader.dart';
class ParcelCategoryModel {
  int? id;
  String? imageFullUrl;
  String? name;
  String? description;
  String? createdAt;
  String? updatedAt;
  double? parcelPerKmShippingCharge;
  double? parcelMinimumShippingCharge;

  /// The flat amount this category adds on top of whatever the zone's active
  /// delivery rule priced. This is how a category is charged now; the two
  /// `parcel_*_shipping_charge` fields above are the superseded per-km model,
  /// kept only for the client-side fallback estimate.
  double? charge;

  ParcelCategoryModel({
    this.id,
    this.imageFullUrl,
    this.name,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.parcelPerKmShippingCharge,
    this.parcelMinimumShippingCharge,
    this.charge,
  });

  ParcelCategoryModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    imageFullUrl = json['image_full_url'];
    name = json['name'];
    description = json['description'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    parcelPerKmShippingCharge = JsonReader.toDouble(json['parcel_per_km_shipping_charge']) ?? 0;
    parcelMinimumShippingCharge = JsonReader.toDouble(json['parcel_minimum_shipping_charge']) ?? 0;
    charge = JsonReader.toDouble(json['charge']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['image_full_url'] = imageFullUrl;
    data['name'] = name;
    data['description'] = description;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['parcel_per_km_shipping_charge'] = parcelPerKmShippingCharge;
    data['parcel_minimum_shipping_charge'] = parcelMinimumShippingCharge;
    data['charge'] = charge;
    return data;
  }
}
