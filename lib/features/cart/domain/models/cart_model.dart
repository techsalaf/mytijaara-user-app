import 'package:sixam_mart/api/json_reader.dart';
// `show`: online_cart_model also declares a `Variation`, which would collide with the
// item model's `Variation` used by `_variation` below. Only the BOGO type is needed here.
import 'package:sixam_mart/features/cart/domain/models/online_cart_model.dart' show BogoCartDetails, BundleCartDetails;
import 'package:sixam_mart/features/item/domain/models/item_model.dart';

class CartModel {
  int? _id;
  double? _price;
  double? _discountedPrice;
  List<Variation>? _variation;
  List<List<bool?>>? _foodVariations;
  double? _discountAmount;
  int? _quantity;
  List<AddOn>? _addOnIds;
  List<AddOns>? _addOns;
  bool? _isCampaign;
  int? _stock;
  Item? _item;
  int? _quantityLimit;
  bool? _isLoading;
  BogoCartDetails? _bogoDetails;
  BundleCartDetails? _bundleDetails;
  int? _bundleStoreId;

  CartModel(
    int? id,
    double? price,
    double discountedPrice,
    List<Variation> variation,
    List<List<bool?>> foodVariations,
    double discountAmount,
    int? quantity,
    List<AddOn> addOnIds,
    List<AddOns> addOns,
    bool isCampaign,
    int? stock,
    Item? item,
    int? quantityLimit,
    {bool isLoading = false}) {
    _id = id;
    _price = price;
    _discountedPrice = discountedPrice;
    _variation = variation;
    _foodVariations = foodVariations;
    _discountAmount = discountAmount;
    _quantity = quantity;
    _addOnIds = addOnIds;
    _addOns = addOns;
    _isCampaign = isCampaign;
    _stock = stock;
    _item = item;
    _quantityLimit = quantityLimit;
    _isLoading = isLoading;
  }

  /// A bundle cart row has no item/variations/add-ons of its own — see [BogoCartDetails].
  CartModel.bogoBundle({required BogoCartDetails bogoDetails, int? storeId}) {
    _bogoDetails = bogoDetails;
    _bundleStoreId = storeId;
    _id = int.tryParse(bogoDetails.bogoGroupId);
    _price = bogoDetails.bundlePrice;
    _discountedPrice = bogoDetails.finalPrice ?? bogoDetails.bundlePrice;
    _discountAmount = bogoDetails.discountAmount;
    _quantity = bogoDetails.quantity;
    _addOnIds = [];
    _addOns = [];
    _isCampaign = false;
    _item = null;
    _variation = [];
    _foodVariations = [];
    _quantityLimit = null;
    _stock = null;
    _isLoading = false;
  }

  /// A product bundle entry, the structural twin of [CartModel.bogoBundle]: no
  /// item, no variations, no add-ons of its own — [BundleCartDetails] is all it
  /// carries, and it prices itself.
  CartModel.bundle({required BundleCartDetails bundleDetails, int? storeId}) {
    _bundleDetails = bundleDetails;
    _bundleStoreId = storeId;
    /// The entry's own `id` is always 0, so the group id stands in as a local
    /// identity for list keys. It is a uuid, so this is usually null — the tile
    /// addresses the group by [BundleCartDetails.bundleGroupId], never by this.
    _id = int.tryParse(bundleDetails.bundleGroupId);
    _price = bundleDetails.finalPrice;
    _discountedPrice = bundleDetails.finalPrice;
    _discountAmount = bundleDetails.discountAmount;
    _quantity = bundleDetails.quantity;
    _addOnIds = [];
    _addOns = [];
    _isCampaign = false;
    _item = null;
    _variation = [];
    _foodVariations = [];
    _quantityLimit = null;
    _stock = null;
    _isLoading = false;
  }

  int? get id => _id;
  double? get price => _price;
  double? get discountedPrice => _discountedPrice;
  List<Variation>? get variation => _variation;
  List<List<bool?>>? get foodVariations => _foodVariations;
  double? get discountAmount => _discountAmount;
  // ignore: unnecessary_getters_setters
  int? get quantity => _quantity;
  // ignore: unnecessary_getters_setters
  set quantity(int? qty) => _quantity = qty;
  List<AddOn>? get addOnIds => _addOnIds;
  List<AddOns>? get addOns => _addOns;
  bool? get isCampaign => _isCampaign;
  int? get stock => _stock;
  Item? get item => _item;
  int? get quantityLimit => _quantityLimit;
  // ignore: unnecessary_getters_setters
  bool? get isLoading => _isLoading;
  set isLoading(bool? status) => _isLoading = status;
  bool get isBogoBundle => _bogoDetails != null;
  BogoCartDetails? get bogoDetails => _bogoDetails;
  bool get isBundle => _bundleDetails != null;
  BundleCartDetails? get bundleDetails => _bundleDetails;

  /// True for any entry that is a whole bundle rather than a cart row: it has no
  /// item to price from, prices itself from the server's figures, and is added,
  /// re-quantified and removed as one thing.
  bool get isAtomicBundle => isBogoBundle || isBundle;
  int? get storeId => _item?.storeId ?? _bundleStoreId;

  // What this row looks like in a thumbnail strip. A bundle has no item of its own, so
  // reading the item's picture leaves it blank — the pictures are its members'.
  List<String> get thumbnails {
    if(_bogoDetails != null) {
      return _bogoDetails!.itemThumbnails;
    }
    if(_bundleDetails != null) {
      return _bundleDetails!.itemThumbnails;
    }
    final String? image = _item?.imageFullUrl;
    return image != null ? <String>[image] : const <String>[];
  }

  CartModel.fromJson(Map<String, dynamic> json) {
    _id = json['cart_id'];
    _price = JsonReader.toDouble(json['price']);
    _discountedPrice = json['discounted_price']?.toDouble();
    // The service module returns `variation` as a single object ({variant_key, name,
    // price, discount, discount_type}) instead of a list; List.forEach's callback shape
    // doesn't match Map.forEach's, so guard the type rather than crash on that module.
    if (json['variation'] is List) {
      _variation = [];
      json['variation'].forEach((v) {
        _variation!.add(Variation.fromJson(v));
      });
    }
    if (json['food_variations'] != null) {
      _foodVariations = [];
      for (int index = 0; index < json['food_variations'].length; index++) {
        _foodVariations!.add([]);
        for (int i = 0; i < json['food_variations'][index].length; i++) {
          _foodVariations![index].add(json['food_variations'][index][i]);
        }
      }
    }
    _discountAmount = json['discount_amount']?.toDouble();
    _quantity = json['quantity'];
    _stock = json['stock'];
    if (json['add_on_ids'] != null) {
      _addOnIds = [];
      final List<dynamic> rawIds = json['add_on_ids'] as List<dynamic>;
      final List<dynamic>? rawQtys = json['add_on_qtys'] as List<dynamic>?;
      for (int i = 0; i < rawIds.length; i++) {
        final dynamic v = rawIds[i];
        if (v is Map) {
          _addOnIds!.add(AddOn.fromJson(Map<String, dynamic>.from(v)));
        } else {
          final dynamic rawQty = (rawQtys != null && i < rawQtys.length) ? rawQtys[i] : 1;
          final int? qty = rawQty is int ? rawQty : int.tryParse('$rawQty');
          _addOnIds!.add(AddOn(id: v is int ? v : int.tryParse('$v'), quantity: qty ?? 1));
        }
      }
    }
    final dynamic addOnsRaw = json['add_ons'] ?? (json['item'] is Map ? (json['item'] as Map)['addons'] : null);
    if (addOnsRaw is List) {
      _addOns = addOnsRaw
          .whereType<Map>()
          .map<AddOns>((Map v) => AddOns.fromJson(Map<String, dynamic>.from(v)))
          .toList();
    }
    _isCampaign = json['is_campaign'];
    if (json['item'] != null) {
      _item = Item.fromJson(json['item']);
    }
    if (json['quantity_limit'] != null) {
      _quantityLimit = int.parse(json['quantity_limit']);
    }
    _isLoading = json['is_loading'] ?? false;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['cart_id'] = _id;
    data['price'] = _price;
    data['discounted_price'] = _discountedPrice;
    if (_variation != null) {
      data['variation'] = _variation!.map((v) => v.toJson()).toList();
    }
    data['food_variations'] = _foodVariations;
    data['discount_amount'] = _discountAmount;
    data['quantity'] = _quantity;
    if (_addOnIds != null) {
      // data['add_on_ids'] = addOnIds;
      data['add_on_ids'] = _addOnIds!.map((v) => v.toJson()).toList();
    }
    if (_addOns != null) {
      data['add_ons'] = _addOns!.map((v) => v.toJson()).toList();
    }
    data['is_campaign'] = _isCampaign;
    data['stock'] = _stock;
    if (_item != null) {
      data['item'] = _item!.toJson();
    }
    data['quantity_limit'] = _quantityLimit?.toString();
    // data['is_loading'] = _isLoading?? false;
    return data;
  }
}

class AddOn {
  int? id;
  int? quantity;

  AddOn({this.id, this.quantity});

  AddOn.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    quantity = json['quantity'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['quantity'] = quantity;
    return data;
  }
}
