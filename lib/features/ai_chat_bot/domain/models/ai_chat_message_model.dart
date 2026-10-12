import 'package:sixam_mart/common/models/pagination_model.dart';
import 'package:sixam_mart/features/bogo_offer/domain/models/bogo_offer_model.dart';
import 'package:sixam_mart/features/bundle/domain/models/bundle_model.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/happy_hour/domain/models/happy_hour_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/util/app_constants.dart';

class AiChatMessageModel {
  int? totalSize;
  int? limit;
  int? offset;
  int? conversationId;
  List<AiChatMessage>? messages;

  AiChatMessageModel({this.totalSize, this.limit, this.offset, this.conversationId, this.messages});

  AiChatMessageModel.fromJson(Map<String, dynamic> json) {
    // Paging arrives flat on the legacy format and nested under `pagination`
    // now. Property names are unchanged, so no caller needs an edit.
    final PaginationModel _pg = PaginationModel.fromJson(json);
    totalSize = _pg.totalSize;
    limit = _pg.limit;
    offset = _pg.offset;
    conversationId = json['conversation_id'];

    final dynamic rawMessages = json['data'] ?? json['messages'];
    if (rawMessages != null) {
      messages = <AiChatMessage>[];
      rawMessages.forEach((v) {
        messages!.add(AiChatMessage.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_size'] = totalSize;
    data['limit'] = limit;
    data['offset'] = offset;
    data['conversation_id'] = conversationId;
    if (messages != null) {
      data['data'] = messages!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class AiChatMessage {
  int? id;
  int? conversationId;
  String? role;
  String? content;
  String? toolName;
  AiChatMetadata? metadata;
  String? createdAt;
  String? updatedAt;
  bool sending;

  AiChatMessage({
    this.id,
    this.conversationId,
    this.role,
    this.content,
    this.toolName,
    this.metadata,
    this.createdAt,
    this.updatedAt,
    this.sending = false,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  AiChatMessage.fromJson(Map<String, dynamic> json)
      : sending = false {
    id = json['id'];
    conversationId = json['conversation_id'];
    role = json['role'];
    content = json['content'] ?? json['message'];
    toolName = json['tool_name'];
    metadata = json['metadata'] != null && json['metadata'] is Map<String, dynamic>
        ? AiChatMetadata.fromJson(json['metadata'])
        : null;
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['conversation_id'] = conversationId;
    data['role'] = role;
    data['content'] = content;
    data['tool_name'] = toolName;
    if (metadata != null) {
      data['metadata'] = metadata!.toJson();
    }
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class AiChatMetadata {
  List<Item>? products;
  List<Store>? stores;
  List<CategoryModel>? categories;
  List<AiChatBogoOffer>? bogoOffers;
  List<Bundle>? bundles;
  List<HappyHourModel>? happyHours;
  AiChatCart? cart;
  bool? cartUpdated;

  AiChatMetadata({this.products, this.stores, this.categories, this.bogoOffers, this.bundles, this.happyHours,
    this.cart, this.cartUpdated,
  });

  AiChatMetadata.fromJson(Map<String, dynamic> json) {
    cartUpdated = json['cart_updated'] is bool ? json['cart_updated'] as bool : null;

    if (json['products'] is List) {
      products = <Item>[];
      for (var v in (json['products'] as List)) {
        if (v is Map<String, dynamic>) {
          try {
            products!.add(Item.fromJson(_normalizeProductJson(v)));
          } catch (_) {}
        }
      }
    }

    if (json['stores'] is List) {
      stores = <Store>[];
      for (var v in (json['stores'] as List)) {
        if (v is Map<String, dynamic>) {
          try {
            stores!.add(Store.fromJson(_normalizeStoreJson(v)));
          } catch (_) {}
        }
      }
    }

    if (json['categories'] is List) {
      categories = <CategoryModel>[];
      for (var v in (json['categories'] as List)) {
        if (v is Map<String, dynamic>) {
          try {
            categories!.add(CategoryModel.fromJson(_normalizeCategoryJson(v)));
          } catch (_) {}
        }
      }
    }

    if (json['bogo_offers'] is List) {
      bogoOffers = <AiChatBogoOffer>[];
      for (var v in (json['bogo_offers'] as List)) {
        if (v is Map<String, dynamic>) {
          try {
            bogoOffers!.add(AiChatBogoOffer.fromJson(v));
          } catch (_) {}
        }
      }
    }

    if (json['bundles'] is List) {
      bundles = <Bundle>[];
      for (var v in (json['bundles'] as List)) {
        if (v is Map<String, dynamic>) {
          try {
            bundles!.add(Bundle.fromJson(v));
          } catch (_) {}
        }
      }
    }

    if (json['happy_hours'] is List) {
      happyHours = <HappyHourModel>[];
      for (var v in (json['happy_hours'] as List)) {
        if (v is Map<String, dynamic>) {
          try {
            happyHours!.add(HappyHourModel.fromJson(v));
          } catch (_) {}
        }
      }
    }

    if (json['cart'] is Map<String, dynamic>) {
      try {
        cart = AiChatCart.fromJson(json['cart']);
      } catch (_) {}
    }
  }

  bool get hasProducts => products != null && products!.isNotEmpty;
  bool get hasStores => stores != null && stores!.isNotEmpty;
  bool get hasCategories => categories != null && categories!.isNotEmpty;
  bool get hasBogoOffers => bogoOffers != null && bogoOffers!.isNotEmpty;
  bool get hasBundles => bundles != null && bundles!.isNotEmpty;
  bool get hasHappyHours => happyHours != null && happyHours!.isNotEmpty;
  bool get hasCart => cart != null && cart!.stores.isNotEmpty;
  bool get isEmpty => !hasProducts && !hasStores && !hasCategories && !hasBogoOffers && !hasBundles
      && !hasHappyHours && !hasCart;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (products != null) {
      data['products'] = products!.map((v) => v.toJson()).toList();
    }
    if (stores != null) {
      data['stores'] = stores!.map((v) => v.toJson()).toList();
    }
    if (categories != null) {
      data['categories'] = categories!.map((v) => v.toJson()).toList();
    }
    if (happyHours != null) {
      data['happy_hours'] = happyHours!.map((v) => v.toJson()).toList();
    }
    if (cart != null) {
      data['cart'] = cart!.toJson();
    }
    if (cartUpdated != null) {
      data['cart_updated'] = cartUpdated;
    }
    return data;
  }
}

/// A BOGO offer as the chat sends it, with the module it belongs to.
///
/// [BogoOfferCardModel] carries no module of its own — the BOGO screen supplies it
/// from the tab the offer was listed under. The chat can surface an offer from any
/// module, so the id travels beside the offer instead.
class AiChatBogoOffer {
  final BogoOfferCardModel offer;
  final int? moduleId;

  const AiChatBogoOffer({required this.offer, this.moduleId});

  factory AiChatBogoOffer.fromJson(Map<String, dynamic> json) => AiChatBogoOffer(
    offer: BogoOfferCardModel.fromJson(json),
    moduleId: int.tryParse('${json['module_id']}'),
  );
}

class AiChatCart {
  List<AiChatCartStoreGroup> stores;
  double? grandTotal;
  int? totalItems;

  AiChatCart({required this.stores, this.grandTotal, this.totalItems});

  AiChatCart.fromJson(Map<String, dynamic> json) : stores = <AiChatCartStoreGroup>[] {
    grandTotal = (json['grand_total'] as num?)?.toDouble();
    totalItems = json['total_items'] is String ? int.tryParse(json['total_items']) : json['total_items'];

    if (json['stores'] is List) {
      for (var v in (json['stores'] as List)) {
        if (v is Map<String, dynamic>) {
          try {
            stores.add(AiChatCartStoreGroup.fromJson(v));
          } catch (_) {}
        }
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['stores'] = stores.map((v) => v.toJson()).toList();
    data['grand_total'] = grandTotal;
    data['total_items'] = totalItems;
    return data;
  }
}

class AiChatCartStoreGroup {
  int? storeId;
  String? storeName;
  List<AiChatCartItem> items;
  double? storeSubtotal;

  AiChatCartStoreGroup({this.storeId, this.storeName, required this.items, this.storeSubtotal});

  AiChatCartStoreGroup.fromJson(Map<String, dynamic> json) : items = <AiChatCartItem>[] {
    storeId = json['store_id'];
    storeName = json['store_name'];
    storeSubtotal = (json['store_subtotal'] as num?)?.toDouble();

    if (json['items'] is List) {
      for (var v in (json['items'] as List)) {
        if (v is Map<String, dynamic>) {
          try {
            items.add(AiChatCartItem.fromJson(v));
          } catch (_) {}
        }
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['store_id'] = storeId;
    data['store_name'] = storeName;
    data['items'] = items.map((v) => v.toJson()).toList();
    data['store_subtotal'] = storeSubtotal;
    return data;
  }
}

class AiChatCartItem {
  int? cartId;
  int? itemId;
  String? name;
  String? variation;
  String? image;
  String? imageFullUrl;
  int? quantity;
  double? unitPrice;
  double? lineTotal;

  AiChatCartItem({
    this.cartId, this.itemId, this.name, this.variation, this.image,
    this.imageFullUrl, this.quantity, this.unitPrice, this.lineTotal,
  });

  AiChatCartItem.fromJson(Map<String, dynamic> json) {
    cartId = json['cart_id'];
    itemId = json['item_id'];
    name = json['name'];
    variation = json['variation'];
    image = json['image'];
    imageFullUrl = json['image_full_url'];
    quantity = json['quantity'] is String ? int.tryParse(json['quantity']) : json['quantity'];
    unitPrice = (json['unit_price'] as num?)?.toDouble();
    lineTotal = (json['line_total'] as num?)?.toDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['cart_id'] = cartId;
    data['item_id'] = itemId;
    data['name'] = name;
    data['variation'] = variation;
    data['image'] = image;
    data['image_full_url'] = imageFullUrl;
    data['quantity'] = quantity;
    data['unit_price'] = unitPrice;
    data['line_total'] = lineTotal;
    return data;
  }
}

/// Maps the AI-chat metadata "product" payload to the standard [Item] JSON shape
/// expected by [Item.fromJson]. The metadata response uses simplified field names
/// (`image` filename only, `veg` as bool) which the existing Item parser can't read.
/// We never mutate the original map, so callers are unaffected.
Map<String, dynamic> _normalizeProductJson(Map<String, dynamic> raw) {
  final Map<String, dynamic> json = Map<String, dynamic>.from(raw);

  if (json['veg'] is bool) {
    json['veg'] = (json['veg'] as bool) ? 1 : 0;
  }

  if ((json['image_full_url'] == null || json['image_full_url'].toString().isEmpty)
      && json['image'] != null && json['image'].toString().isNotEmpty) {
    json['image_full_url'] = '${AppConstants.baseUrl}/storage/app/public/product/${json['image']}';
  }

  json['discount'] ??= 0;
  json['price'] ??= 0;

  return json;
}

Map<String, dynamic> _normalizeStoreJson(Map<String, dynamic> raw) {
  final Map<String, dynamic> json = Map<String, dynamic>.from(raw);

  if (json['featured'] is bool) {
    json['featured'] = (json['featured'] as bool) ? 1 : 0;
  }
  json['featured'] ??= 0;

  if (json['veg'] is bool) {
    json['veg'] = (json['veg'] as bool) ? 1 : 0;
  }
  if (json['non_veg'] is bool) {
    json['non_veg'] = (json['non_veg'] as bool) ? 1 : 0;
  }

  if (json['open'] == null && json['is_open'] != null) {
    json['open'] = (json['is_open'] is bool)
        ? ((json['is_open'] as bool) ? 1 : 0)
        : json['is_open'];
  }

  if (json['distance'] == null && json['distance_km'] != null) {
    json['distance'] = (json['distance_km'] as num).toDouble();
  }

  if (json['total_items'] == null && json['items_count'] != null) {
    json['total_items'] = json['items_count'];
  }

  json['active'] ??= true;
  json['open'] ??= 1;
  json['latitude'] ??= '0';
  json['longitude'] ??= '0';

  if ((json['logo_full_url'] == null || json['logo_full_url'].toString().isEmpty)
      && json['logo'] != null && json['logo'].toString().isNotEmpty) {
    json['logo_full_url'] = '${AppConstants.baseUrl}/storage/app/public/store/${json['logo']}';
  } else if ((json['logo_full_url'] == null || json['logo_full_url'].toString().isEmpty)
      && json['store_logo'] != null && json['store_logo'].toString().isNotEmpty) {
    json['logo_full_url'] = '${AppConstants.baseUrl}/storage/app/public/store/${json['store_logo']}';
  }

  if ((json['cover_photo_full_url'] == null || json['cover_photo_full_url'].toString().isEmpty)
      && json['cover_photo'] != null && json['cover_photo'].toString().isNotEmpty) {
    json['cover_photo_full_url'] = '${AppConstants.baseUrl}/storage/app/public/store/cover/${json['cover_photo']}';
  }

  return json;
}

Map<String, dynamic> _normalizeCategoryJson(Map<String, dynamic> raw) {
  final Map<String, dynamic> json = Map<String, dynamic>.from(raw);

  if ((json['image_full_url'] == null || json['image_full_url'].toString().isEmpty)
      && json['image'] != null && json['image'].toString().isNotEmpty) {
    json['image_full_url'] = '${AppConstants.baseUrl}/storage/app/public/category/${json['image']}';
  }

  return json;
}

// SUMMARY
// The AI chat's message payloads. Holds a page of messages, a single message with its
// role and text, and the metadata a reply carries — recommended products, stores and
// categories, BOGO offers and bundles, and a snapshot of the cart the bot just changed —
// each normalised into the models the rest of the app already renders.
