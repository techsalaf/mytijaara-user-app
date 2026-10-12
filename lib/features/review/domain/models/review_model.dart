import 'package:sixam_mart/api/response_parser.dart';
import 'package:sixam_mart/common/models/pagination_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';

/// `GET /api/v1/stores/reviews` — `{data: [...], pagination: {...}}`.
///
/// The pagination block was being discarded: the request sent no `offset`/`limit`
/// and the repository returned a bare list, so a store with more than the default
/// 25 reviews only ever showed the first 25 with no way to reach the rest. The
/// endpoint does honour `offset`/`limit` (1-based pages, verified live) even though
/// the docs list only `store_id`.
class StoreReviewModel {
  int? totalSize;
  int? limit;
  int? offset;
  List<ReviewModel>? reviews;

  StoreReviewModel({this.totalSize, this.limit, this.offset, this.reviews});

  StoreReviewModel.fromJson(Map<String, dynamic> json) {
    final PaginationModel pagination = PaginationModel.fromJson(json);
    totalSize = pagination.totalSize;
    limit = pagination.limit;
    offset = pagination.offset;
    final List<dynamic>? entries = ResponseParser.listOf(json, legacyKey: 'reviews');
    if (entries != null) {
      reviews = <ReviewModel>[];
      for (final dynamic v in entries) {
        reviews!.add(ReviewModel.fromJson(v));
      }
    }
  }
}

class ReviewModel {
  int? id;
  String? comment;
  int? rating;
  String? itemName;
  String? itemImageFullUrl;
  String? customerName;
  String? createdAt;
  String? updatedAt;
  String? reply;
  Item? item;

  ReviewModel({
    this.id,
    this.comment,
    this.rating,
    this.itemName,
    this.itemImageFullUrl,
    this.customerName,
    this.createdAt,
    this.updatedAt,
    this.reply,
    this.item,
  });

  ReviewModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    comment = json['comment'];
    rating = json['rating'];
    itemName = json['item_name'];
    itemImageFullUrl = json['item_image_full_url'];
    customerName = json['customer_name'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    reply = json['reply'];
    item = json['item'] != null ? Item.fromJson(json['item']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['comment'] = comment;
    data['rating'] = rating;
    data['item_name'] = itemName;
    data['item_image_full_url'] = itemImageFullUrl;
    data['customer_name'] = customerName;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['reply'] = reply;
    if (item != null) {
      data['item'] = item!.toJson();
    }
    return data;
  }
}
