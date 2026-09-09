class ReorderResponseModel {
  int? cartCount;
  int? addedCount;
  int? skippedCount;
  List<UnavailableItem>? unavailableItems;
  List<dynamic>? skippedItems;
  String? message;

  ReorderResponseModel({
    this.cartCount,
    this.addedCount,
    this.skippedCount,
    this.unavailableItems,
    this.skippedItems,
    this.message,
  });

  ReorderResponseModel.fromJson(Map<String, dynamic> json) {
    cartCount = json['cart_count'];
    addedCount = json['added_count'];
    skippedCount = json['skipped_count'];
    if (json['unavailable_items'] != null) {
      unavailableItems = <UnavailableItem>[];
      json['unavailable_items'].forEach((v) {
        unavailableItems!.add(UnavailableItem.fromJson(v));
      });
    }
    skippedItems = json['skipped_items'] ?? [];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['cart_count'] = cartCount;
    data['added_count'] = addedCount;
    data['skipped_count'] = skippedCount;
    if (unavailableItems != null) {
      data['unavailable_items'] = unavailableItems!.map((v) => v.toJson()).toList();
    }
    data['skipped_items'] = skippedItems;
    data['message'] = message;
    return data;
  }
}

class UnavailableItem {
  int? id;
  String? name;
  String? code;
  String? message;

  UnavailableItem({this.id, this.name, this.code, this.message});

  UnavailableItem.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    code = json['code'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['code'] = code;
    data['message'] = message;
    return data;
  }
}
