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
    if(json['store'] != null) {
      _store = AllCartsStore.fromJson(json['store']);
    }
    if(json['carts'] != null) {
      _carts = [];
      _onlineCarts = [];
      json['carts'].forEach((v) {
        _carts!.add(CartModel.fromJson(_normalizeCartJson(v)));
        _onlineCarts!.add(OnlineCartModel.fromJson(v));
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

  AllCartsStore({int? id, String? name, String? slug, String? logo, String? logoFullUrl,
    int? itemCount, String? deliveryTime, double? distanceKm,
  }) {
    _id = id;
    _name = name;
    _slug = slug;
    _logo = logo;
    _logoFullUrl = logoFullUrl;
    _itemCount = itemCount;
    _deliveryTime = deliveryTime;
    _distanceKm = distanceKm;
  }

  int? get id => _id;
  String? get name => _name;
  String? get slug => _slug;
  String? get logo => _logo;
  String? get logoFullUrl => _logoFullUrl;
  int? get itemCount => _itemCount;
  String? get deliveryTime => _deliveryTime;
  double? get distanceKm => _distanceKm;

  AllCartsStore.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _name = json['name'];
    _slug = json['slug'];
    _logo = json['logo'];
    _logoFullUrl = json['logo_full_url'];
    _itemCount = json['item_count'];
    _deliveryTime = json['delivery_time'];
    _distanceKm = json['distance_km'] != null ? double.tryParse(json['distance_km'].toString()) : null;
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
    return data;
  }
}
