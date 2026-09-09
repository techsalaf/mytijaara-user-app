class LastOrderModel {
  final int? orderId;
  final int? moduleId;
  final double? orderAmount;
  final String? createdAt;
  final LastOrderStore? store;
  final List<LastOrderItemPreview> itemsPreview;
  final int? extraItemsCount;
  final int? itemCount;
  final bool? canReorder;

  LastOrderModel({this.orderId, this.moduleId, this.orderAmount, this.createdAt, this.store,
    this.itemsPreview = const <LastOrderItemPreview>[], this.extraItemsCount, this.itemCount, this.canReorder,
  });

  factory LastOrderModel.fromJson(Map<String, dynamic> json) {
    return LastOrderModel(
      orderId: _toInt(json['order_id']),
      moduleId: _toInt(json['module_id']),
      orderAmount: _toDouble(json['order_amount']),
      createdAt: json['created_at']?.toString(),
      store: json['store'] is Map<String, dynamic> ? LastOrderStore.fromJson(json['store']) : null,
      itemsPreview: (json['items_preview'] is List)
          ? (json['items_preview'] as List).whereType<Map<String, dynamic>>().map(LastOrderItemPreview.fromJson).toList()
          : const <LastOrderItemPreview>[],
      extraItemsCount: _toInt(json['extra_items_count']),
      itemCount: _toInt(json['item_count']),
      canReorder: json['can_reorder'] == true || json['can_reorder'] == 1,
    );
  }
}

class LastOrderStore {
  final int? id;
  final String? name;
  final String? slug;
  final String? logoFullUrl;

  LastOrderStore({this.id, this.name, this.slug, this.logoFullUrl});

  factory LastOrderStore.fromJson(Map<String, dynamic> json) => LastOrderStore(
    id: _toInt(json['id']),
    name: json['name']?.toString(),
    slug: json['slug']?.toString(),
    logoFullUrl: json['logo_full_url']?.toString(),
  );
}

class LastOrderItemPreview {
  final int? id;
  final String? name;
  final String? imageFullUrl;
  final int? quantity;

  LastOrderItemPreview({this.id, this.name, this.imageFullUrl, this.quantity});

  factory LastOrderItemPreview.fromJson(Map<String, dynamic> json) => LastOrderItemPreview(
    id: _toInt(json['id']),
    name: json['name']?.toString(),
    imageFullUrl: json['image_full_url']?.toString(),
    quantity: _toInt(json['quantity']),
  );
}

int? _toInt(dynamic v) {
  if(v == null) return null;
  if(v is int) return v;
  if(v is num) return v.toInt();
  return int.tryParse(v.toString());
}

double? _toDouble(dynamic v) {
  if(v == null) return null;
  if(v is num) return v.toDouble();
  return double.tryParse(v.toString());
}
