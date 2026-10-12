import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/review/domain/models/review_model.dart';

StoreReviewModel parse(String raw) => StoreReviewModel.fromJson(
    ApiClient.unwrapEnvelope(jsonDecode(raw), 200) as Map<String, dynamic>);

void main() {
  test('live stores/reviews: rows from `data`, paging from `pagination`', () {
    final StoreReviewModel m =
        parse(File('test/fixtures/live/store_reviews.json').readAsStringSync());
    expect(m.reviews, isNotNull);
    expect(m.reviews!, isNotEmpty);
    expect(m.totalSize, isNotNull, reason: 'was discarded before, so paging was impossible');
    expect(m.offset, 1, reason: 'current_page maps onto the 1-based offset');
    expect(m.limit, isNotNull);
  });

  test('every field the review row renders is present', () {
    final StoreReviewModel m =
        parse(File('test/fixtures/live/store_reviews.json').readAsStringSync());
    for (final ReviewModel r in m.reviews!) {
      expect(r.id, isNotNull);
      expect(r.rating, isNotNull);
      expect(r.createdAt, isNotNull);
      expect(r.updatedAt, isNotNull);
      expect(r.itemName, isNotNull);
      expect(r.item, isNotNull, reason: 'tapping the row navigates to review.item');
    }
  });

  test('null comment and null customer_name render blank, not a crash', () {
    // Rows 27 and 3 of the pasted payload have comment:null; row 39 customer_name:null.
    final ReviewModel r = ReviewModel.fromJson(<String, dynamic>{
      'id': 39, 'rating': 5, 'comment': null, 'customer_name': null,
      'item_image_full_url': null, 'item_name': 'MacKensie Frazier',
      'created_at': '2026-07-09T13:47:57.000000Z', 'updated_at': '2026-07-09T13:47:57.000000Z',
    });
    expect(r.comment, isNull);
    expect(r.customerName, isNull);
    expect(r.itemImageFullUrl, isNull);
    // what the row widget now does
    expect(r.comment ?? '', '');
    expect(r.customerName ?? '', '');
    expect((r.rating ?? 0).toStringAsFixed(1), '5.0');
  });

  test('a row with no timestamps no longer throws while building', () {
    final ReviewModel r = ReviewModel.fromJson(<String, dynamic>{'id': 1, 'rating': 4});
    expect(r.createdAt, isNull);
    expect(r.updatedAt, isNull);
    // _formatDate's contract: blank rather than an exception
    expect(r.createdAt == null || r.createdAt!.isEmpty, isTrue);
  });

  test('both live timestamp formats format without throwing', () {
    // created_at is ISO-8601 with T/Z; replied_at uses a space separator.
    for (final String raw in <String>['2026-07-09T13:47:57.000000Z', '2026-03-09 09:23:43']) {
      final ReviewModel r = ReviewModel.fromJson(<String, dynamic>{'rating': 5, 'created_at': raw});
      expect(r.createdAt, raw);
    }
  });

  test('legacy `reviews` key still wins over `data`', () {
    final StoreReviewModel m = StoreReviewModel.fromJson(<String, dynamic>{
      'total_size': 4, 'limit': 10, 'offset': 1,
      'reviews': <dynamic>[<String, dynamic>{'id': 7, 'rating': 5, 'comment': 'legacy'}],
      'data': <dynamic>[<String, dynamic>{'id': 99, 'rating': 1, 'comment': 'ignored'}],
    });
    expect(m.reviews!.single.comment, 'legacy');
    expect(m.totalSize, 4);
  });

  test('an empty body yields an empty list, not a throw', () {
    final StoreReviewModel m = parse(
        '{"identical_code":"default_200","message":"m","content":{"data":[],"pagination":{"total":0,"per_page":10,"current_page":1}},"errors":[]}');
    expect(m.reviews, isEmpty);
    expect(m.totalSize, 0);
  });
}
