import 'package:sixam_mart/features/cart/domain/models/online_cart_model.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
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
    totalSize = json['total_size'];
    limit = json['limit'] is String ? int.tryParse(json['limit']) : json['limit'];
    offset = json['offset'] is String ? int.tryParse(json['offset']) : json['offset'];
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
  List<OnlineCartModel>? cartItems;
  bool? cartUpdated;

  AiChatMetadata({this.products, this.stores, this.categories, this.cartItems, this.cartUpdated});

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

    if (json['cart_items'] is List) {
      cartItems = <OnlineCartModel>[];
      for (var v in (json['cart_items'] as List)) {
        if (v is Map<String, dynamic>) {
          try {
            cartItems!.add(OnlineCartModel.fromJson(v));
          } catch (_) {}
        }
      }
    }
  }

  bool get hasProducts => products != null && products!.isNotEmpty;
  bool get hasStores => stores != null && stores!.isNotEmpty;
  bool get hasCategories => categories != null && categories!.isNotEmpty;
  bool get hasCartItems => cartItems != null && cartItems!.isNotEmpty;
  bool get isEmpty => !hasProducts && !hasStores && !hasCategories && !hasCartItems;

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
    if (cartItems != null) {
      data['cart_items'] = cartItems!.map((v) => v.toJson()).toList();
    }
    if (cartUpdated != null) {
      data['cart_updated'] = cartUpdated;
    }
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
