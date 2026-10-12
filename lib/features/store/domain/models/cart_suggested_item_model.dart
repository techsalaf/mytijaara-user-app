import 'package:sixam_mart/api/response_parser.dart';
import 'package:sixam_mart/common/models/pagination_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';

class CartSuggestItemModel {
  int? totalSize;
  String? limit;
  String? offset;
  List<Item>? items;

  CartSuggestItemModel({this.totalSize, this.limit, this.offset, this.items});

  CartSuggestItemModel.fromJson(Map<String, dynamic> json) {
    // Paging arrives flat (`total_size`/`limit`/`offset`) on the legacy format
    // and nested under `pagination` now. Property names are unchanged, so no
    // caller needs an edit.
    final PaginationModel _pg = PaginationModel.fromJson(json);
    totalSize = _pg.totalSize;
    limit = _pg.limit?.toString();
    offset = _pg.offset?.toString();
    // The list is `data` now; `items` was the legacy key.
    final List<dynamic>? entries = ResponseParser.listOf(json, legacyKey: 'items');
    if (entries != null) {
      items = <Item>[];
      for (final dynamic v in entries) {
        items!.add(Item.fromJson(v));
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_size'] = totalSize;
    data['limit'] = limit;
    data['offset'] = offset;
    if (items != null) {
      data['items'] = items!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
