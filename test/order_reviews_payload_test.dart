import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';

/// Parsing the `reviews` node the order track response carries.
///
/// `rating` came back as `5.0` where the model declares `int?`, and the raw assignment
/// threw `type 'double' is not a subtype of type 'int?'`. The throw happened inside the
/// `forEach` that builds the list, so it escaped `OrderModel.fromJson` entirely and the
/// order details screen never opened — a rated order simply could not be viewed.
void main() {
  Map<String, dynamic> review({dynamic rating = 5, dynamic itemId = 280, dynamic reviewId = 'rv-1'}) =>
      <String, dynamic>{
        'id': 1, 'item_id': itemId, 'user_id': 8, 'comment': 'Great', 'attachment': null,
        'rating': rating, 'order_id': 102662, 'created_at': '2026-09-19T10:20:06.000000Z',
        'updated_at': '2026-09-19T10:20:06.000000Z', 'status': 1, 'module_id': 4, 'review_id': reviewId,
      };

  group('Reviews.fromJson', () {
    test('a double rating parses instead of throwing — the bug', () {
      final Reviews parsed = Reviews.fromJson(review(rating: 5.0));

      expect(parsed.rating, 5);
    });

    test('a whole-number rating still parses', () {
      expect(Reviews.fromJson(review(rating: 5)).rating, 5);
    });

    test('a numeric string rating parses', () {
      expect(Reviews.fromJson(review(rating: '4')).rating, 4);
    });

    test('a missing rating is null, not a crash', () {
      expect(Reviews.fromJson(review(rating: null)).rating, isNull);
    });

    test('ids survive arriving as doubles or strings', () {
      expect(Reviews.fromJson(review(itemId: 280.0)).itemId, 280);
      expect(Reviews.fromJson(review(itemId: '280')).itemId, 280);
    });

    test('a numeric review_id does not break the String field', () {
      expect(Reviews.fromJson(review(reviewId: 17)).reviewId, '17');
    });
  });

  group('the order around it', () {
    test('a rated order parses end to end', () {
      final OrderModel order = OrderModel.fromJson(<String, dynamic>{
        'id': 102662, 'order_status': 'delivered',
        'reviews': <dynamic>[review(rating: 5.0), review(rating: 4.5, itemId: 278)],
      });

      expect(order.id, 102662);
      expect(order.reviews, hasLength(2));
      // Truncated the way num.toInt() truncates; nothing displays this value, the list
      // is read only to tell whether an item has already been reviewed.
      expect(order.reviews!.map((Reviews r) => r.rating), <int>[5, 4]);
      expect(order.reviews!.map((Reviews r) => r.itemId), <int>[280, 278]);
    });

    test('an order with no reviews leaves the list null', () {
      final OrderModel order = OrderModel.fromJson(<String, dynamic>{'id': 1, 'reviews': null});

      expect(order.reviews, isNull);
    });
  });
}

// SUMMARY
// Covers the order's reviews node: a rating sent as a double, a string or not at all no
// longer throws out of the list build and take the whole order with it, ids and review
// ids survive the same type drift, and a rated order parses end to end.
