import 'package:sixam_mart/features/item/domain/models/item_model.dart' as product_variation;
import 'package:sixam_mart/helper/product_image_helper.dart';

class OnlineCartModel {
  int? id;
  int? userId;
  int? moduleId;
  int? itemId;
  bool? isGuest;
  List<int>? addOnIds;
  List<int>? addOnQtys;
  String? itemType;
  double? price;
  int? quantity;
  List<Variation>? foodVariation;
  List<product_variation.Variation>? productVariation;
  String? createdAt;
  String? updatedAt;
  product_variation.Item? item;
  BogoCartDetails? bogoDetails;
  BundleCartDetails? bundleDetails;
  int? storeId;

  OnlineCartModel({
    this.id,
    this.userId,
    this.moduleId,
    this.itemId,
    this.isGuest,
    this.addOnIds,
    this.addOnQtys,
    this.itemType,
    this.price,
    this.quantity,
    this.foodVariation,
    this.createdAt,
    this.updatedAt,
    this.item,
    this.bogoDetails,
    this.bundleDetails,
    this.storeId,
  });

  OnlineCartModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    moduleId = json['module_id'];
    itemId = json['item_id'];
    isGuest = json['is_guest'];
    addOnIds = json['add_on_ids'] is List ? List<int>.from((json['add_on_ids'] as List).map((e) => e is int ? e : int.tryParse('\$e') ?? 0)) : <int>[];
    addOnQtys = json['add_on_qtys'] is List ? List<int>.from((json['add_on_qtys'] as List).map((e) => e is int ? e : int.tryParse('\$e') ?? 0)) : <int>[];
    itemType = json['item_type'];
    price = json['price']?.toDouble();
    quantity = json['quantity'];
    // The service module returns `variation` as a single object instead of a list;
    // guard the type rather than crash calling List.forEach's callback shape on a Map.
    if (json['variation'] is List) {
      foodVariation = [];
      productVariation = [];
      json['variation'].forEach((v) {
        if (v['name'] == null) {
          productVariation!.add(product_variation.Variation.fromJson(v));
        } else {
          foodVariation!.add(Variation.fromJson(v));
        }
      });
    }
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    item = json['item'] != null ? product_variation.Item.fromJson(json['item']) : null;
    bogoDetails = json['bogo_details'] != null ? BogoCartDetails.fromJson(json['bogo_details']) : null;
    bundleDetails = json['bundle_details'] != null ? BundleCartDetails.fromJson(json['bundle_details']) : null;
    storeId = json['store_id'] ?? (json['item'] is Map ? json['item']['store_id'] : null);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['user_id'] = userId;
    data['module_id'] = moduleId;
    data['item_id'] = itemId;
    data['is_guest'] = isGuest;
    data['add_on_ids'] = addOnIds;
    data['add_on_qtys'] = addOnQtys;
    data['item_type'] = itemType;
    data['price'] = price;
    data['quantity'] = quantity;
    if (foodVariation != null) {
      data['variation'] = foodVariation!.map((v) => v.toJson()).toList();
    }
    if (productVariation != null) {
      data['variation'] = productVariation!.map((v) => v.toJson()).toList();
    }
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (item != null) {
      data['item'] = item!.toJson();
    }
    return data;
  }
}

class Variation {
  String? name;
  Value? values;

  Variation({this.name, this.values});

  Variation.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    if (json['values'] != null) {
      if (json['values'] is Map) {
        values = Value.fromJson(json['values']);
      } else if (json['values'] is List) {
        List<String> labels = [];
        for (var item in json['values']) {
          if (item is String) {
            labels.add(item);
          } else if (item is Map) {
            labels.add(item['label']?.toString() ?? item['value']?.toString() ?? item.toString());
          }
        }
        values = Value(label: labels);
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    if (values != null) {
      data['values'] = values!.toJson();
    }
    return data;
  }
}

class Value {
  List<String>? label;

  Value({this.label});

  Value.fromJson(Map<String, dynamic> json) {
    if (json['label'] is List) {
      label = List<String>.from(json['label'].map((e) => e.toString()));
    } else {
      label = [json['label']?.toString() ?? ''];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['label'] = label;
    return data;
  }
}


/// A bundle cart entry has `item`/`item_id`/`variations`/`add_on_ids` all null —
/// this is the only per-item information it carries.
class BogoCartDetails {
  final String bogoGroupId;
  final int? bogoOfferId;
  final int? bundleId;
  final String? offerTitle;
  final String? offerSlug;

  /// `Y-m-d H:i:s`, null when the offer is open ended. A delivery scheduled past this is
  /// refused at checkout, so the app checks it while the customer is still picking.
  final String? offerStartDate;
  final String? offerEndDate;
  final int quantity;
  final double bundlePrice;

  final double? originalPrice;
  final double totalPrice;

  final double? finalPrice;
  final double? totalFinalPrice;

  /// A Happy Hour is the one promotion that stacks on top of a bundle: while one is
  /// running these are non-zero and [isHappyHour] is true, and `final_price` drops
  /// below `bundle_price` by [discountAmount]. Bare name is per bundle, `total_` is
  /// the whole group.
  final double discountPercentage;
  final double discountAmount;
  final double totalDiscountAmount;
  final bool isHappyHour;
  final bool isAvailable;
  final String? unavailableReason;
  final List<String> itemThumbnails;
  final List<String> buyItemThumbnails;
  final List<String> freeItemThumbnails;

  const BogoCartDetails({
    required this.bogoGroupId, this.bogoOfferId, this.bundleId, this.offerTitle, this.offerSlug,
    this.offerStartDate, this.offerEndDate,
    required this.quantity, required this.bundlePrice, this.originalPrice, required this.totalPrice,
    this.finalPrice, this.totalFinalPrice,
    this.discountPercentage = 0, this.discountAmount = 0, this.totalDiscountAmount = 0, this.isHappyHour = false,
    required this.isAvailable, this.unavailableReason, required this.itemThumbnails,
    required this.buyItemThumbnails, required this.freeItemThumbnails,
  });

  /// One entry per member, empty string when it has no picture — dropping those made a
  /// bundle look shorter than it is, and an all-imageless side vanish entirely.
  static List<String> _thumbnailsFrom(dynamic items) {
    List<String> thumbnails = [];
    if (items is List) {
      for (final dynamic row in items) {
        thumbnails.add(ProductImageHelper.fullUrl(_memberImage(row)) ?? '');
      }
    }
    return thumbnails;
  }

  /// A cart row's bundle member spells its picture as a bare `image` file name on the
  /// nested item and sends no `image_full_url` at all — that is the offer endpoint's
  /// spelling for the same field, kept first for the shapes that do carry it.
  static dynamic _memberImage(dynamic row) {
    if(row is! Map) {
      return null;
    }
    final dynamic item = row['item'];
    if(row['image_full_url'] != null || item is! Map) {
      return row['image_full_url'];
    }
    return item['image_full_url'] ?? item['image'];
  }

  factory BogoCartDetails.fromJson(Map<String, dynamic> json) {
    final List<String> buyThumbnails = _thumbnailsFrom(json['buy_items']);
    final List<String> freeThumbnails = _thumbnailsFrom(json['free_items']);
    return BogoCartDetails(
      bogoGroupId: '${json['bogo_group_id']}',
      bogoOfferId: json['bogo_offer_id'],
      bundleId: json['bundle_id'],
      offerTitle: json['offer_title'],
      offerSlug: json['offer_slug'],
      offerStartDate: json['offer_start_date'],
      offerEndDate: json['offer_end_date'],
      quantity: int.tryParse('${json['quantity']}') ?? 1,
      bundlePrice: double.tryParse('${json['bundle_price']}') ?? 0,
      originalPrice: double.tryParse('${json['original_price']}'),
      totalPrice: double.tryParse('${json['total_price']}') ?? 0,
      finalPrice: double.tryParse('${json['final_price']}'),
      totalFinalPrice: double.tryParse('${json['total_final_price']}'),
      discountPercentage: double.tryParse('${json['discount_percentage']}') ?? 0,
      discountAmount: double.tryParse('${json['discount_amount']}') ?? 0,
      totalDiscountAmount: double.tryParse('${json['total_discount_amount']}') ?? 0,
      isHappyHour: json['is_happy_hour'] == true || json['is_happy_hour'] == 1,
      isAvailable: json['is_available'] ?? true,
      unavailableReason: json['unavailable_reason'],
      itemThumbnails: [...buyThumbnails, ...freeThumbnails],
      buyItemThumbnails: buyThumbnails,
      freeItemThumbnails: freeThumbnails,
    );
  }
}

/// A product bundle folded into one cart entry.
///
/// The entry is not a cart row: its `id` is `0` and its `item` is null, so it
/// must never be sent to the item-row endpoints (`cart/update`,
/// `cart/remove-item`). Everything it carries lives here.
///
/// [totalFinalPrice] is `final_price × quantity` and is what the cart bills —
/// not [bundlePrice], which is the bundle's own price before a happy hour
/// replaces its discount.
class BundleCartDetails {
  final String bundleGroupId;
  final int? bundleId;
  final String? name;
  final String? imageFullUrl;

  /// `Y-m-d H:i:s` — the visibility window. A scheduled delivery outside it is
  /// refused, so the app checks while the customer is still picking.
  final String? startDate;
  final String? endDate;

  final int quantity;
  final double basePrice;
  final double bundlePrice;
  final double discountPercentage;
  final double discountAmount;

  /// What to charge for one copy. Diverges from [bundlePrice] only while a happy
  /// hour is open, at which point the happy hour's rate has replaced the
  /// bundle's own — it does not stack.
  final double finalPrice;
  final double totalFinalPrice;
  final double totalDiscountAmount;
  final bool isHappyHour;

  final bool isAvailable;

  /// Names the member at fault — render it rather than a generic message. It is
  /// computed for the quantity being requested, so a bundle can list as
  /// available and still be refused at a higher one.
  final String? unavailableReason;

  final List<BundleCartMember> items;

  const BundleCartDetails({
    required this.bundleGroupId, this.bundleId, this.name, this.imageFullUrl, this.startDate,
    this.endDate, required this.quantity, this.basePrice = 0, this.bundlePrice = 0, this.discountPercentage = 0,
    this.discountAmount = 0, this.finalPrice = 0, this.totalFinalPrice = 0, this.totalDiscountAmount = 0, this.isHappyHour = false,
    this.isAvailable = true, this.unavailableReason, this.items = const [],
  });

  factory BundleCartDetails.fromJson(Map<String, dynamic> json) {
    final dynamic rows = json['items'];
    return BundleCartDetails(
      bundleGroupId: '${json['bundle_group_id']}',
      bundleId: int.tryParse('${json['bundle_id']}'),
      name: json['name']?.toString(),
      imageFullUrl: json['image_full_url']?.toString(),
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
      quantity: int.tryParse('${json['quantity']}') ?? 1,
      basePrice: double.tryParse('${json['base_price']}') ?? 0,
      bundlePrice: double.tryParse('${json['bundle_price']}') ?? 0,
      discountPercentage: double.tryParse('${json['discount_percentage']}') ?? 0,
      discountAmount: double.tryParse('${json['discount_amount']}') ?? 0,
      finalPrice: double.tryParse('${json['final_price']}') ?? 0,
      totalFinalPrice: double.tryParse('${json['total_final_price']}') ?? 0,
      totalDiscountAmount: double.tryParse('${json['total_discount_amount']}') ?? 0,
      isHappyHour: json['is_happy_hour'] == true,
      isAvailable: json['is_available'] != false,
      unavailableReason: json['unavailable_reason']?.toString(),
      items: rows is List
          ? rows.whereType<Map>().map((row) => BundleCartMember.fromJson(Map<String, dynamic>.from(row))).toList()
          : const [],
    );
  }

  /// What the members cost bought separately, per copy — struck through beside
  /// the price when the bundle actually saves something.
  bool get hasSaving => basePrice > finalPrice;

  double get totalBasePrice => basePrice * quantity;

  /// One entry per member, empty string where a member has no picture. Empty
  /// entries are kept: dropping them makes a bundle look shorter than it is.
  List<String> get itemThumbnails => items.map((item) => item.imageFullUrl ?? '').toList();
}

/// One member of a bundle as the cart reports it — fewer fields than the browse
/// payload carries, which is why the cart tile links to the bundle rather than
/// trying to render a full item.
class BundleCartMember {
  final int? itemId;
  final int? serviceId;
  final String? name;
  final String? imageFullUrl;
  final double unitPrice;
  final String? variationSummary;

  const BundleCartMember({
    this.itemId, this.serviceId, this.name, this.imageFullUrl, this.unitPrice = 0, this.variationSummary,
  });

  factory BundleCartMember.fromJson(Map<String, dynamic> json) => BundleCartMember(
    itemId: int.tryParse('${json['item_id']}'),
    serviceId: int.tryParse('${json['service_id']}'),
    name: json['name']?.toString(),
    // Resolved the way a bundle member's picture is everywhere else: the cart spells it
    // as a bare file name, and handing that to an image widget draws the placeholder.
    imageFullUrl: ProductImageHelper.fullUrl(json['image_full_url'] ?? json['image']),
    unitPrice: double.tryParse('${json['unit_price']}') ?? 0,
    variationSummary: json['variation_summary']?.toString(),
  );

  int? get targetId => itemId ?? serviceId;
}
