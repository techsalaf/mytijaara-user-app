import 'dart:convert';

import 'package:sixam_mart/api/json_reader.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/helper/type_converter_helper.dart';

class OrderDetailsModel {
  int? id;
  int? itemId;
  int? orderId;
  double? price;
  Item? itemDetails;
  List<Variation>? variation;
  List<FoodVariation>? foodVariation;
  List<AddOn>? addOns;
  double? discountOnItem;
  double? discountPercentage;
  bool isHappyHour = false;
  bool isStoreDiscount = false;
  String? discountType;
  int? quantity;
  double? taxAmount;
  String? variant;
  String? createdAt;
  String? updatedAt;
  int? itemCampaignId;
  double? totalAddOnPrice;
  String? imageFullUrl;
  bool? isGuest;
  ParcelCancellation? parcelCancellation;
  OrderBogoDetailsModel? bogoDetails;
  OrderBundleDetailsModel? bundleDetails;

  bool get isBogoBundle => bogoDetails != null;
  bool get isBundle => bundleDetails != null;

  OrderDetailsModel({
    this.id,
    this.itemId,
    this.orderId,
    this.price,
    this.itemDetails,
    this.variation,
    this.foodVariation,
    this.addOns,
    this.discountOnItem,
    this.discountPercentage,
    this.discountType,
    this.quantity,
    this.taxAmount,
    this.variant,
    this.createdAt,
    this.updatedAt,
    this.itemCampaignId,
    this.totalAddOnPrice,
    this.imageFullUrl,
    this.isGuest,
    this.parcelCancellation,
    this.bogoDetails,
    this.bundleDetails,
  });

  OrderDetailsModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    itemId = json['item_id'];
    orderId = json['order_id'];
    price = num.tryParse(json['price']?.toString() ?? '')?.toDouble();
    itemDetails = json['item_details'] != null ? Item.fromJson(json['item_details']) : null;
    variation = [];
    foodVariation = [];
    if (json['variation'] != null && json['variation'].isNotEmpty) {
      if (json['variation'][0]['values'] != null) {
        json['variation'].forEach((v) {
          foodVariation!.add(FoodVariation.fromJson(v));
        });
      } else {
        json['variation'].forEach((v) {
          variation!.add(Variation.fromJson(v));
        });
      }
    }
    if (json['add_ons'] != null) {
      addOns = [];
      json['add_ons'].forEach((v) {
        addOns!.add(AddOn.fromJson(v));
      });
    }
    discountOnItem = json['discount_on_item']?.toDouble();
    discountPercentage = num.tryParse(json['discount_percentage']?.toString() ?? '')?.toDouble();
    isHappyHour = json['is_happy_hour'] == true || json['is_happy_hour'] == 1;
    isStoreDiscount = TypeConverterHelper.getBool(json['is_store_discount']);
    discountType = json['discount_type'];
    quantity = json['quantity'];
    taxAmount = json['tax_amount']?.toDouble();
    variant = json['variant'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    itemCampaignId = json['item_campaign_id'];
    totalAddOnPrice = json['total_add_on_price']?.toDouble();
    imageFullUrl = json['image_full_url'];
    isGuest = TypeConverterHelper.getBool(json['is_guest']);
    parcelCancellation = json['parcel_cancellation'] != null ? ParcelCancellation.fromJson(json['parcel_cancellation']) : null;
    bogoDetails = json['bogo_details'] != null ? OrderBogoDetailsModel.fromJson(json['bogo_details']) : null;
    bundleDetails = json['bundle_details'] != null ? OrderBundleDetailsModel.fromJson(json['bundle_details']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['item_id'] = itemId;
    data['order_id'] = orderId;
    data['price'] = price;
    if (itemDetails != null) {
      data['item_details'] = itemDetails!.toJson();
    }
    if (variation != null) {
      data['variation'] = variation!.map((v) => v.toJson()).toList();
    } else if (foodVariation != null) {
      data['variation'] = foodVariation!.map((v) => v.toJson()).toList();
    }
    if (addOns != null) {
      data['add_ons'] = addOns!.map((v) => v.toJson()).toList();
    }
    data['discount_on_item'] = discountOnItem;
    data['discount_percentage'] = discountPercentage;
    data['is_happy_hour'] = isHappyHour;
    data['is_store_discount'] = isStoreDiscount;
    data['discount_type'] = discountType;
    data['quantity'] = quantity;
    data['tax_amount'] = taxAmount;
    data['variant'] = variant;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['item_campaign_id'] = itemCampaignId;
    data['total_add_on_price'] = totalAddOnPrice;
    data['image_full_url'] = imageFullUrl;
    data['is_guest'] = isGuest;
    if (parcelCancellation != null) {
      data['parcel_cancellation'] = parcelCancellation!.toJson();
    }
    return data;
  }
}

/// A bundle order line has no `item_details`/`variation`/`add_ons` of its own — see the
/// API doc's "Same conventions as the cart" note. This is the only per-item info it carries.
class OrderBogoDetailsModel {
  int? bogoOfferId;
  String? offerTitle;
  int? bundleId;
  int? quantity;
  double? bundlePrice;
  double? totalPrice;
  List<OrderBogoItemModel>? buyItems;
  List<OrderBogoItemModel>? freeItems;

  OrderBogoDetailsModel({
    this.bogoOfferId, this.offerTitle, this.bundleId, this.quantity,
    this.bundlePrice, this.totalPrice, this.buyItems, this.freeItems,
  });

  OrderBogoDetailsModel.fromJson(Map<String, dynamic> json) {
    bogoOfferId = JsonReader.toInt(json['bogo_offer_id']);
    offerTitle = json['offer_title'];
    bundleId = JsonReader.toInt(json['bundle_id']);
    quantity = JsonReader.toInt(json['quantity']);
    bundlePrice = JsonReader.toDouble(json['bundle_price']);
    totalPrice = JsonReader.toDouble(json['total_price']);
    // Rows are read defensively: one malformed member must not cost the whole order.
    if (json['buy_items'] is List) {
      buyItems = (json['buy_items'] as List).whereType<Map>()
          .map((Map item) => OrderBogoItemModel.fromJson(Map<String, dynamic>.from(item))).toList();
    }
    if (json['free_items'] is List) {
      freeItems = (json['free_items'] as List).whereType<Map>()
          .map((Map item) => OrderBogoItemModel.fromJson(Map<String, dynamic>.from(item))).toList();
    }
  }
}

class OrderBogoItemModel {
  int? itemId;
  String? name;
  String? imageFullUrl;
  double? price;
  int? quantity;

  OrderBogoItemModel({this.itemId, this.name, this.imageFullUrl, this.price, this.quantity});

  /// `item_details` arrives as a JSON-encoded **string** on order details, not a map —
  /// assigning it straight to a `Map` threw and took the whole order screen with it.
  static Map<String, dynamic>? _detailsOf(dynamic raw) {
    if(raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    if(raw is String && raw.isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(raw);
        if(decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  OrderBogoItemModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? itemDetails = _detailsOf(json['item_details'] ?? json['food_details']);
    itemId = JsonReader.toInt(json['item_id'] ?? json['food_id']);
    name = itemDetails?['name'] ?? json['name'] ?? json['item_name'] ?? json['food_name'];
    imageFullUrl = itemDetails?['image_full_url'] ?? json['image_full_url'] ?? json['item_image_full_url'] ?? json['food_image_full_url'];
    price = JsonReader.toDouble(json['price']);
    quantity = JsonReader.toInt(json['quantity']);
  }
}


class OrderBundleDetailsModel {
  String? bundleGroupId;
  int? bundleId;
  String? name;
  int? quantity;
  double? bundlePrice;
  double? totalPrice;
  double? discount;
  List<OrderBundleItemModel>? items;

  OrderBundleDetailsModel({
    this.bundleGroupId, this.bundleId, this.name, this.quantity,
    this.bundlePrice, this.totalPrice, this.discount, this.items,
  });

  OrderBundleDetailsModel.fromJson(Map<String, dynamic> json) {
    bundleGroupId = json['bundle_group_id']?.toString();
    bundleId = JsonReader.toInt(json['bundle_id']);
    name = json['name'];
    quantity = JsonReader.toInt(json['quantity']);
    bundlePrice = JsonReader.toDouble(json['bundle_price']);
    totalPrice = JsonReader.toDouble(json['total_price']);
    discount = JsonReader.toDouble(json['discount']);
    // Rows are read defensively: one malformed member must not cost the whole order.
    if (json['items'] is List) {
      items = (json['items'] as List).whereType<Map>()
          .map((Map item) => OrderBundleItemModel.fromJson(Map<String, dynamic>.from(item))).toList();
    }
  }
}

class OrderBundleItemModel {
  int? id;
  int? itemId;
  String? name;
  String? imageFullUrl;
  double? price;
  int? quantity;

  OrderBundleItemModel({this.id, this.itemId, this.name, this.imageFullUrl, this.price, this.quantity});

  static Map<String, dynamic>? _detailsOf(dynamic raw) {
    if(raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    if(raw is String && raw.isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(raw);
        if(decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  OrderBundleItemModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? details = _detailsOf(json['item_details']);
    id = JsonReader.toInt(json['id']);
    itemId = JsonReader.toInt(json['item_id']);
    // Read as tolerantly as a BOGO member is: the bundle endpoints spell a member's name
    // and picture as bare keys and its price as `unit_price`, and reading only
    // `item_details` left those members nameless, priceless and unreviewable.
    name = details?['name'] ?? json['name'] ?? json['item_name'] ?? json['bundle_name'];
    price = JsonReader.toDouble(json['price'] ?? json['unit_price']);
    quantity = JsonReader.toInt(json['quantity']);
    imageFullUrl = details?['image_full_url']?.toString() ?? json['image_full_url']?.toString();
  }
}

class AddOn {
  String? name;
  double? price;
  int? quantity;

  AddOn({
    this.name,
    this.price,
    this.quantity,
  });

  AddOn.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    price = JsonReader.toDouble(json['price']);
    quantity = int.parse(json['quantity'].toString());
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['price'] = price;
    data['quantity'] = quantity;
    return data;
  }
}
