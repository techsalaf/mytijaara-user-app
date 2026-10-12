import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/cart/domain/models/online_cart_model.dart';

class AllCartsModel {
  AllCartsStore? _store;
  List<CartModel>? _carts;
  List<OnlineCartModel>? _onlineCarts;

  AllCartsModel({AllCartsStore? store, List<CartModel>? carts, List<OnlineCartModel>? onlineCarts}) {
    _store = store;
    _carts = carts;
    _onlineCarts = onlineCarts;
  }

  AllCartsStore? get store => _store;
  List<CartModel>? get carts => _carts;
  List<OnlineCartModel>? get onlineCarts => _onlineCarts;

  AllCartsModel.fromJson(Map<String, dynamic> json) {
    // The service module's get-all response wraps the group's store under `provider`
    // instead of `store` — same fields (id, name, slug, logo_full_url, distance_km).
    final dynamic storeJson = json['store'] ?? json['provider'];
    if(storeJson != null) {
      _store = AllCartsStore.fromJson(storeJson);
    }
    if(json['carts'] != null) {
      _carts = [];
      _onlineCarts = [];
      json['carts'].forEach((v) {
        // A BOGO bundle row carries no item/variation/add-on of its own; it is
        // represented by `bogo_details` alone — see [BogoCartDetails].
        if(v is Map && v['bogo_details'] != null) {
          _carts!.add(CartModel.bogoBundle(
            bogoDetails: BogoCartDetails.fromJson(Map<String, dynamic>.from(v['bogo_details'])),
            storeId: _store?.id,
          ));
        } else if(v is Map && v['bundle_details'] != null) {
          // Likewise, a product-bundle row carries no item of its own — see [BundleCartDetails].
          _carts!.add(CartModel.bundle(
            bundleDetails: BundleCartDetails.fromJson(Map<String, dynamic>.from(v['bundle_details'])),
            storeId: _store?.id,
          ));
        } else {
          _carts!.add(CartModel.fromJson(_normalizeCartJson(v)));
        }
        final OnlineCartModel onlineCart = OnlineCartModel.fromJson(v);
        // The group knows the store even when the row does not — a bundle row carries
        // no item, so this is the only place its store id can come from.
        onlineCart.storeId ??= _store?.id;
        _onlineCarts!.add(onlineCart);
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if(_store != null) {
      data['store'] = _store!.toJson();
    }
    if(_carts != null) {
      data['carts'] = _carts!.map((v) => v.toJson()).toList();
    }
    return data;
  }

  // The /get-all endpoint returns the cart id under `id` while CartModel.fromJson
  // expects `cart_id`. Bridge the two so the existing model can parse it.
  static Map<String, dynamic> _normalizeCartJson(Map<String, dynamic> raw) {
    final Map<String, dynamic> normalized = Map<String, dynamic>.from(raw);
    if(!normalized.containsKey('cart_id') && normalized.containsKey('id')) {
      normalized['cart_id'] = normalized['id'];
    }
    return normalized;
  }
}

class AllCartsStore {
  int? _id;
  String? _name;
  String? _slug;
  String? _logo;
  String? _logoFullUrl;
  int? _itemCount;
  String? _deliveryTime;
  double? _distanceKm;

  /// The distance already written out for display, in the platform's configured
  /// unit. Mirrors `Store.distanceLabel`; null on a payload without it, so the
  /// caller's own formatting stays the fallback.
  String? _distanceLabel;

  AllCartsStore({int? id, String? name, String? slug, String? logo, String? logoFullUrl,
    int? itemCount, String? deliveryTime, double? distanceKm, String? distanceLabel,
  }) {
    _id = id;
    _name = name;
    _slug = slug;
    _logo = logo;
    _logoFullUrl = logoFullUrl;
    _itemCount = itemCount;
    _deliveryTime = deliveryTime;
    _distanceKm = distanceKm;
    _distanceLabel = distanceLabel;
  }

  int? get id => _id;
  String? get name => _name;
  String? get slug => _slug;
  String? get logo => _logo;
  String? get logoFullUrl => _logoFullUrl;
  int? get itemCount => _itemCount;
  String? get deliveryTime => _deliveryTime;
  double? get distanceKm => _distanceKm;
  String? get distanceLabel => _distanceLabel;

  AllCartsStore.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _name = json['name'];
    _slug = json['slug'];
    _logo = json['logo'];
    _logoFullUrl = json['logo_full_url'];
    _itemCount = json['item_count'];
    _deliveryTime = json['delivery_time'];
    _distanceKm = json['distance_km'] != null ? double.tryParse(json['distance_km'].toString()) : null;
    // `distance_lavel` is accepted alongside the correctly spelled key because the
    // misspelling has been seen in the wild. Blank normalises to null.
    final String label = (json['distance_label'] ?? json['distance_lavel'] ?? '').toString().trim();
    _distanceLabel = label.isEmpty ? null : label;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = _id;
    data['name'] = _name;
    data['slug'] = _slug;
    data['logo'] = _logo;
    data['logo_full_url'] = _logoFullUrl;
    data['item_count'] = _itemCount;
    data['delivery_time'] = _deliveryTime;
    data['distance_km'] = _distanceKm;
    data['distance_label'] = _distanceLabel;
    return data;
  }
}
