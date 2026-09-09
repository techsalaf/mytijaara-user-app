class MonthlyOrderModel {
  int? totalSize;
  String? limit;
  int? offset;
  List<MonthlyOrder> items;

  MonthlyOrderModel({this.totalSize, this.limit, this.offset, this.items = const <MonthlyOrder>[]});

  factory MonthlyOrderModel.fromJson(Map<String, dynamic> json) {
    return MonthlyOrderModel(
      totalSize: _toInt(json['total_size']),
      limit: json['limit']?.toString(),
      offset: _toInt(json['offset']),
      items: (json['items'] is List)
          ? (json['items'] as List).whereType<Map<String, dynamic>>().map(MonthlyOrder.fromJson).toList()
          : <MonthlyOrder>[],
    );
  }
}

class MonthlyOrder {
  final int? id;
  final int? orderId;
  final int? moduleId;
  final String? moduleType;
  final String? remindAt;
  final String? status;
  final MonthlyOrderStore? store;
  final int? itemsCount;
  final List<MonthlyOrderItemPreview> itemsPreview;

  MonthlyOrder({this.id, this.orderId, this.moduleId, this.moduleType, this.remindAt,
    this.status, this.store, this.itemsCount, this.itemsPreview = const <MonthlyOrderItemPreview>[],
  });

  factory MonthlyOrder.fromJson(Map<String, dynamic> json) {
    return MonthlyOrder(
      id: _toInt(json['id']),
      orderId: _toInt(json['order_id']),
      moduleId: _toInt(json['module_id']),
      moduleType: json['module_type']?.toString(),
      remindAt: json['remind_at']?.toString(),
      status: json['status']?.toString(),
      store: json['store'] is Map<String, dynamic> ? MonthlyOrderStore.fromJson(json['store']) : null,
      itemsCount: _toInt(json['items_count']),
      itemsPreview: (json['items_preview'] is List)
          ? (json['items_preview'] as List).whereType<Map<String, dynamic>>().map(MonthlyOrderItemPreview.fromJson).toList()
          : const <MonthlyOrderItemPreview>[],
    );
  }
}

class MonthlyOrderStore {
  final int? id;
  final String? name;
  final String? logoFullUrl;

  MonthlyOrderStore({this.id, this.name, this.logoFullUrl});

  factory MonthlyOrderStore.fromJson(Map<String, dynamic> json) => MonthlyOrderStore(
    id: _toInt(json['id']),
    name: json['name']?.toString(),
    logoFullUrl: json['logo_full_url']?.toString() ?? json['logo']?.toString(),
  );
}

class MonthlyOrderItemPreview {
  final int? id;
  final String? itemType;
  final String? name;
  final String? imageFullUrl;
  final double? price;
  final double? oldPrice;
  final int? quantity;
  final bool isAvailable;

  MonthlyOrderItemPreview({this.id, this.itemType, this.name, this.imageFullUrl, this.price,
    this.oldPrice, this.quantity, this.isAvailable = true,
  });

  factory MonthlyOrderItemPreview.fromJson(Map<String, dynamic> json) => MonthlyOrderItemPreview(
    id: _toInt(json['id']),
    itemType: json['item_type']?.toString(),
    name: json['name']?.toString(),
    imageFullUrl: json['image_full_url']?.toString() ?? json['image']?.toString(),
    price: _toDouble(json['price']),
    oldPrice: _toDouble(json['old_price']),
    quantity: _toInt(json['quantity']),
    isAvailable: json['is_available'] == null ? true : json['is_available'] == true,
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
