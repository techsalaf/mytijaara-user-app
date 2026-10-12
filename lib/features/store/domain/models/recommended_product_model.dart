import 'package:sixam_mart/api/response_parser.dart';
import 'package:sixam_mart/common/models/pagination_model.dart';

import 'dart:convert';

import 'package:sixam_mart/features/item/domain/models/item_model.dart';

/// Isolate entry point for `JsonParseHelper.parse`. Must stay top-level and pure.
/// Safe because [Item.fromJson] itself is pure — the `Get.find<SplashController>()`
/// call in that file lives in `ItemModel.fromJson`, a different class this never
/// touches. Do not route `ItemModel` through this helper.
/// The envelope is unwrapped here rather than in `ApiClient`: `rawBody: true`
/// skips decoding, so it also skips the central unwrap, and the model would
/// otherwise be handed `{identical_code, message, content, errors}`.
RecommendedItemModel recommendedItemModelFromRawJson(String rawJson) =>
    RecommendedItemModel.fromJson(
      ResponseParser.payloadOf(jsonDecode(rawJson)) as Map<String, dynamic>,
    );

class RecommendedItemModel {
  int? totalSize;
  String? limit;
  String? offset;
  List<Item>? items;

  RecommendedItemModel({this.totalSize, this.limit, this.offset, this.items});

  RecommendedItemModel.fromJson(Map<String, dynamic> json) {
    // Paging arrives flat on the legacy format and nested under `pagination`
    // now. Property names are unchanged, so no caller needs an edit.
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
      data['products'] = items!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
