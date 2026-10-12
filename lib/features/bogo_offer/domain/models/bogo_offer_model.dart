import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/product_image_helper.dart';

class BogoHomeModel {
  final bool? isLive;
  final String? title;
  final String? description;
  final int? totalOffers;
  final List<BogoOfferCardModel>? offers;

  const BogoHomeModel({this.isLive, this.title, this.description, this.totalOffers, this.offers});

  factory BogoHomeModel.fromJson(Map<String, dynamic> json) => BogoHomeModel(
    isLive: json['is_live'] == true || json['is_live'] == 1,
    title: json['title'],
    description: json['description'],
    totalOffers: int.tryParse('${json['total_offers']}'),
    offers: json['offers'] is List ? (json['offers'] as List).map((offer) => BogoOfferCardModel.fromJson(offer)).toList() : null,
  );
}

/// The "offer card" shape shared by the home preview and the offer list endpoint.
class BogoOfferCardModel {
  final int? id;
  final String? slug;
  final String? title;
  final String? description;
  final String? imageFullUrl;
  final int? buyQty;
  final int? getQty;
  final String? offerLabel;
  final List<String>? orderTypes;
  final String? startDate;
  final String? endDate;
  final String? validUntil;
  final int? usageLimitPerCustomer;
  final int? remainingUses;

  const BogoOfferCardModel({
    this.id, this.slug, this.title, this.description, this.imageFullUrl,
    this.buyQty, this.getQty, this.offerLabel, this.orderTypes,
    this.startDate, this.endDate, this.validUntil,
    this.usageLimitPerCustomer, this.remainingUses,
  });

  factory BogoOfferCardModel.fromJson(Map<String, dynamic> json) => BogoOfferCardModel(
    id: json['id'],
    slug: json['slug']?.toString(),
    title: json['title'],
    description: json['description'],
    imageFullUrl: json['image_full_url'],
    buyQty: int.tryParse('${json['buy_qty']}'),
    getQty: int.tryParse('${json['get_qty']}'),
    offerLabel: json['offer_label'],
    orderTypes: json['order_types'] is List ? (json['order_types'] as List).map((type) => type.toString()).toList() : null,
    startDate: json['start_date'],
    endDate: json['end_date'],
    validUntil: json['valid_until'],
    usageLimitPerCustomer: json['usage_limit_per_customer'] != null ? int.tryParse('${json['usage_limit_per_customer']}') : null,
    remainingUses: json['remaining_uses'] != null ? int.tryParse('${json['remaining_uses']}') : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'slug': slug, 'title': title, 'description': description,
    'image_full_url': imageFullUrl, 'buy_qty': buyQty, 'get_qty': getQty,
    'offer_label': offerLabel, 'order_types': orderTypes,
    'start_date': startDate, 'end_date': endDate, 'valid_until': validUntil,
    'usage_limit_per_customer': usageLimitPerCustomer, 'remaining_uses': remainingUses,
  };
}

/// The list endpoints report paging two ways: the legacy flat `total_size` / `limit` /
/// `offset` keys, and the documented `pagination` node (`total`, `per_page`,
/// `current_page`). Read whichever the backend sent so either parses.
class _BogoPaging {
  final int? totalSize;
  final String? limit;
  final int? offset;

  const _BogoPaging({this.totalSize, this.limit, this.offset});

  factory _BogoPaging.fromJson(Map<String, dynamic> json) {
    final dynamic pagination = json['pagination'];
    final Map<String, dynamic>? page = pagination is Map<String, dynamic> ? pagination : null;
    return _BogoPaging(
      totalSize: int.tryParse('${json['total_size'] ?? page?['total']}'),
      limit: (json['limit'] ?? page?['per_page'])?.toString(),
      offset: int.tryParse('${json['offset'] ?? page?['current_page']}'),
    );
  }
}

/// `offers` / `bundles` are the legacy names for the rows the documented envelope
/// returns under `data`.
List<dynamic>? _bogoRows(Map<String, dynamic> json, String legacyKey) {
  final dynamic rows = json[legacyKey] ?? json['data'];
  return rows is List ? rows : null;
}

class BogoOfferListModel {
  int? totalSize;
  String? limit;
  int? offset;
  List<BogoOfferCardModel>? offers;

  BogoOfferListModel({this.totalSize, this.limit, this.offset, this.offers});

  BogoOfferListModel.fromJson(Map<String, dynamic> json) {
    final _BogoPaging paging = _BogoPaging.fromJson(json);
    totalSize = paging.totalSize;
    limit = paging.limit;
    offset = paging.offset;
    final List<dynamic>? rows = _bogoRows(json, 'offers');
    if(rows != null) {
      offers = rows.map((offer) => BogoOfferCardModel.fromJson(offer)).toList();
    }
  }
}

/// `GET /stores/bogo-offers` returns one store's bundle for each offer as a single
/// flat object — the offer-level fields ([BogoOfferCardModel]) and this store's bundle
/// ([BogoBundleModel]) merged into one JSON map. Both factories read their own subset of keys
/// from that same map, so no new parsing is needed — just running both over it.
class StoreBogoOfferModel {
  final BogoOfferCardModel offer;
  final BogoBundleModel bundle;

  const StoreBogoOfferModel({required this.offer, required this.bundle});

  factory StoreBogoOfferModel.fromJson(Map<String, dynamic> json, {Store? store}) {
    final BogoBundleModel bundle = BogoBundleModel.fromJson(json);
    return StoreBogoOfferModel(
      offer: BogoOfferCardModel.fromJson(json),
      bundle: (store != null && bundle.store == null) ? bundle.copyWith(store: store) : bundle,
    );
  }
}

class StoreBogoOfferListModel {
  int? totalSize;
  String? limit;
  int? offset;
  List<StoreBogoOfferModel>? offers;

  StoreBogoOfferListModel({this.totalSize, this.limit, this.offset, this.offers});

  StoreBogoOfferListModel.fromJson(Map<String, dynamic> json, {Store? store}) {
    final _BogoPaging paging = _BogoPaging.fromJson(json);
    totalSize = paging.totalSize;
    limit = paging.limit;
    offset = paging.offset;
    final List<dynamic>? rows = _bogoRows(json, 'offers');
    if(rows != null) {
      offers = rows.map((offer) => StoreBogoOfferModel.fromJson(offer, store: store)).toList();
    }
  }
}

class BogoOfferDetailsResponseModel {
  int? id;
  String? slug;
  String? title;
  String? description;
  String? imageFullUrl;
  int? buyQty;
  int? getQty;
  String? offerLabel;
  String? validUntil;
  int? usageLimitPerCustomer;
  int? remainingUses;
  int? totalSize;
  String? limit;
  int? offset;
  List<BogoBundleModel>? bundles;

  BogoOfferDetailsResponseModel({
    this.id, this.slug, this.title, this.description, this.imageFullUrl, this.buyQty, this.getQty,
    this.offerLabel, this.validUntil, this.usageLimitPerCustomer,
    this.remainingUses, this.totalSize, this.limit, this.offset, this.bundles,
  });

  BogoOfferDetailsResponseModel.fromJson(Map<String, dynamic> json) {
    // The documented response nests the offer card under `offer` beside the bundle
    // page; the flat form carries the same keys on the root.
    final Map<String, dynamic> offer = json['offer'] is Map<String, dynamic> ? json['offer'] : json;
    id = offer['id'];
    slug = offer['slug']?.toString();
    title = offer['title'];
    description = offer['description'];
    imageFullUrl = offer['image_full_url'];
    buyQty = int.tryParse('${offer['buy_qty']}');
    getQty = int.tryParse('${offer['get_qty']}');
    offerLabel = offer['offer_label'];
    validUntil = offer['valid_until'];
    usageLimitPerCustomer = offer['usage_limit_per_customer'];
    remainingUses = offer['remaining_uses'];

    final _BogoPaging paging = _BogoPaging.fromJson(json);
    totalSize = paging.totalSize;
    limit = paging.limit;
    offset = paging.offset;
    final List<dynamic>? rows = _bogoRows(json, 'bundles');
    if(rows != null) {
      bundles = rows.map((bundle) => BogoBundleModel.fromJson(bundle)).toList();
    }
  }
}

class BogoBundleModel {
  final int? bundleId;
  final int? buyCount;
  final int? getCount;
  final List<String?>? itemThumbnails;
  final Store? store;
  final double? bundlePrice;
  final double? originalPrice;
  final double? discountPercentage;
  final double? discountAmount;
  final double? finalPrice;
  final bool? isHappyHour;
  final BogoHappyHourSummary? happyHour;
  final List<BogoOfferItemModel> buyItems;
  final List<BogoOfferItemModel> freeItems;

  const BogoBundleModel({
    this.bundleId, this.buyCount, this.getCount, this.itemThumbnails, this.store,
    this.bundlePrice, this.originalPrice, this.discountPercentage, this.discountAmount,
    this.finalPrice, this.isHappyHour, this.happyHour, required this.buyItems, required this.freeItems,
  });

  factory BogoBundleModel.fromJson(Map<String, dynamic> json) {
    // The API names this node `store` in 6amMart; `restaurant` is accepted as a
    // fallback so a shared backend response parses either way.
    final dynamic storeJson = json['store'] ?? json['restaurant'];
    final Store? store = storeJson != null ? Store.fromJson(storeJson) : null;

    return BogoBundleModel(
      bundleId: json['bundle_id'],
      buyCount: json['buy_count'],
      getCount: json['get_count'],
      itemThumbnails: json['item_thumbnails'] is List ? (json['item_thumbnails'] as List).map(ProductImageHelper.fullUrl).toList() : null,
      store: store,
      bundlePrice: double.tryParse('${json['bundle_price']}'),
      originalPrice: double.tryParse('${json['original_price']}'),
      discountPercentage: double.tryParse('${json['discount_percentage']}'),
      discountAmount: double.tryParse('${json['discount_amount']}'),
      finalPrice: double.tryParse('${json['final_price']}'),
      isHappyHour: json['is_happy_hour'] == true,
      happyHour: json['happy_hour'] != null ? BogoHappyHourSummary.fromJson(json['happy_hour']) : null,
      buyItems: json['buy_items'] is List ? (json['buy_items'] as List).map((item) => BogoOfferItemModel.fromBundleItemJson(
        item, storeId: store?.id, storeName: store?.name,
      )).toList() : [],
      freeItems: json['free_items'] is List ? (json['free_items'] as List).map((item) => BogoOfferItemModel.fromBundleItemJson(
        item, storeId: store?.id, storeName: store?.name, isFree: true,
      )).toList() : [],
    );
  }

  BogoBundleModel copyWith({Store? store}) => BogoBundleModel(
    bundleId: bundleId, buyCount: buyCount, getCount: getCount, itemThumbnails: itemThumbnails,
    store: store ?? this.store, bundlePrice: bundlePrice, originalPrice: originalPrice,
    discountPercentage: discountPercentage, discountAmount: discountAmount, finalPrice: finalPrice,
    isHappyHour: isHappyHour, happyHour: happyHour, buyItems: buyItems, freeItems: freeItems,
  );
}

class BogoHappyHourSummary {
  final int? id;
  final String? slug;
  final String? title;
  final double? discount;
  final String? endTime;

  const BogoHappyHourSummary({this.id, this.slug, this.title, this.discount, this.endTime});

  factory BogoHappyHourSummary.fromJson(Map<String, dynamic> json) => BogoHappyHourSummary(
    id: json['id'],
    slug: json['slug']?.toString(),
    title: json['title'],
    discount: double.tryParse('${json['discount']}'),
    endTime: json['end_time'],
  );
}

/// Pairs a real [Item] with the fixed quantity/variation it's included at
/// within a BOGO combo — info the shared Item model has no field for.
class BogoOfferItemModel {
  final Item item;
  final int quantity;
  final String variationText;
  final String addOnText;

  /// A free line of the bundle. Its [Item.price] is what the customer is spared, not
  /// what they pay — see the BOGO API guide — so the price is shown struck through.
  final bool isFree;

  const BogoOfferItemModel({
    required this.item,
    required this.quantity,
    required this.variationText,
    this.addOnText = '',
    this.isFree = false,
  });

  static String _summariseAddOns(dynamic addOns) {
    if(addOns is! List) {
      return '';
    }
    final List<String> parts = [];
    for(final addOn in addOns) {
      if(addOn is! Map) {
        continue;
      }
      final String name = '${addOn['name'] ?? ''}'.trim();
      if(name.isEmpty) {
        continue;
      }
      final int quantity = int.tryParse('${addOn['quantity']}') ?? 1;
      parts.add(quantity > 1 ? '$name x $quantity' : name);
    }
    return parts.join(', ');
  }

  factory BogoOfferItemModel.fromBundleItemJson(Map<String, dynamic> json, {int? storeId, String? storeName, bool isFree = false}) {
    final double price = double.tryParse('${json['price']}') ?? 0;
    return BogoOfferItemModel(
      quantity: int.tryParse('${json['quantity']}') ?? 1,
      variationText: json['variation_summary'] ?? '',
      addOnText: _summariseAddOns(json['add_ons']),
      // The payload marks free lines itself; the caller's flag covers the free_items
      // list being read as a whole.
      isFree: json['is_free'] == true || isFree,
      item: Item(
        id: json['item_id'] ?? json['food_id'] ?? json['id'],
        slug: json['slug']?.toString(),
        name: json['name'],
        imageFullUrl: ProductImageHelper.fullUrl(json['image_full_url']),
        price: price,
        discount: 0,
        discountType: 'amount',
        avgRating: double.tryParse('${json['avg_rating']}'),
        ratingCount: int.tryParse('${json['rating_count']}'),
        veg: json['veg'] is bool ? (json['veg'] == true ? 1 : 0) : int.tryParse('${json['veg']}'),
        storeId: storeId,
        storeName: storeName,
        variations: const [],
        foodVariations: const [],
        addOns: const [],
        choiceOptions: const [],
      ),
    );
  }
}
