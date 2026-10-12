import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/api/response_parser.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/store/domain/models/cart_suggested_item_model.dart';
import 'package:sixam_mart/features/store/domain/models/recommended_product_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_banner_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_category_item_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';

/// Every endpoint the store details screen calls, against payloads captured live
/// for a store that actually has content.
///
/// Two of these — recommended items and the category-grouped catalog — are
/// fetched with `getData(rawBody: true)` and parsed on a worker isolate. That
/// path deliberately skips decoding, which also skips the envelope unwrap in
/// `ApiClient`, so their isolate entry points have to unwrap it themselves.
/// The `fromRawJson` tests below exercise exactly that path.
void main() {
  final Directory fixtures = Directory('test/fixtures/live');
  final bool has = fixtures.existsSync();

  String raw(String name) => File('${fixtures.path}/$name.json').readAsStringSync();
  dynamic payload(String name) => ApiClient.unwrapEnvelope(jsonDecode(raw(name)), 200);

  group('decoded through ApiClient', () {
    test('stores/details is a plain object — Store.fromJson after unwrap', () {
      final Store store = Store.fromJson(payload('store-details') as Map<String, dynamic>);
      expect(store.id, isNotNull);
      expect(store.name, isNotNull);
      expect(store.moduleId, isNotNull);
    }, skip: !has);

    test('stores/details renders the header fields the page depends on', () {
      final Store store = Store.fromJson(payload('store-details') as Map<String, dynamic>);
      // Images are null on this environment (no artwork uploaded), and the model
      // normalises that to '' so CustomImage gets a placeholder rather than null.
      expect(store.logoFullUrl, isNotNull);
      expect(store.coverPhotoFullUrl, isNotNull);
      expect(store.avgRating, isNotNull);
      expect(store.deliveryTime, isNotNull);
      expect(store.open, isNotNull);
      expect(store.active, isNotNull);
      expect(store.freeDelivery, isNotNull);
      expect(store.minDeliveryTime, isNotNull);
      expect(store.maxDeliveryTime, isNotNull);
    }, skip: !has);

    test('the fields stores/details no longer sends parse to null, not a crash', () {
      // The endpoint was trimmed from ~71 fields to 30. Everything below is gone
      // from BOTH the details and the list responses, so nothing can supply it.
      // The store page must degrade rather than throw — several of these were
      // force-unwrapped at the use site and took the screen down.
      final Store store = Store.fromJson(payload('store-details') as Map<String, dynamic>);
      expect(store.delivery, isNull, reason: 'drives the order-type toggle');
      expect(store.takeAway, isNull);
      expect(store.scheduleOrder, isNull);
      expect(store.schedules, isNull);
      expect(store.minimumOrder, 0, reason: 'model substitutes 0 when minimum_order is absent');
      expect(store.address, isNull);
      expect(store.latitude, isNull);
      expect(store.zoneId, isNull);
      expect(store.activeCoupons, isNull, reason: 'coupon row is guarded on null before use');
      // prescriptionOrder defaults to false in the model rather than staying
      // null, so its force-unwrap was never actually at risk.
      expect(store.prescriptionOrder, isFalse);
    }, skip: !has);

    test('rating count falls back to reviews_count, which replaced rating_count', () {
      // stores/details stopped sending `rating_count` and sends `reviews_count`
      // instead. Without the fallback the store header reads "0 reviews" on a
      // store that has them.
      final Store store = Store.fromJson(payload('store-details') as Map<String, dynamic>);
      expect(store.reviewsCount, greaterThan(0));
      expect(store.ratingCount, store.reviewsCount);
    }, skip: !has);

    test('items_count fills the item count that `total_items` used to', () {
      // Store cards print '${store.itemCount} items'. The key was renamed, so
      // without the fallback every card reads "null items".
      final Store store = Store.fromJson(payload('store-details') as Map<String, dynamic>);
      expect(store.itemCount, isNotNull);
      expect(store.itemCount, greaterThan(0));
    }, skip: !has);

    test('price_range fills the span the item filter slider covers', () {
      final Store store = Store.fromJson(payload('store-details-discounted') as Map<String, dynamic>);
      expect(store.minPrice, isNotNull);
      expect(store.maxPrice, isNotNull);
      expect(store.maxPrice!, greaterThan(store.minPrice!));
    }, skip: !has);

    test('a store price range survives a toJson/fromJson round trip', () {
      // Stores are cached through toJson, so a field the cache drops comes back
      // as a store whose filter slider has no span.
      final Store store = Store.fromJson(payload('store-details-discounted') as Map<String, dynamic>);
      final Store cached = Store.fromJson(store.toJson());
      expect(cached.minPrice, store.minPrice);
      expect(cached.maxPrice, store.maxPrice);
      expect(cached.itemCount, store.itemCount);
    }, skip: !has);

    test('store_discount arrives without its cap or its minimum', () {
      // It shrank to {discount, discount_type}. Both of the dropped values were
      // force-unwrapped when pricing the cart and when drawing the offer strip.
      final Store store = Store.fromJson(payload('store-details-discounted') as Map<String, dynamic>);
      expect(store.discount, isNotNull);
      expect(store.discount!.discount, greaterThan(0));
      expect(store.discount!.discountType, isNotNull);
      expect(store.discount!.minPurchase, isNull);
      expect(store.discount!.maxDiscount, isNull);
    }, skip: !has);

    test('a legacy full store payload still parses every field', () {
      // Proves the model was not narrowed — if the backend restores these keys
      // they are read again with no further change.
      final Store store = Store.fromJson(<String, dynamic>{
        'id': 1, 'name': 'Full Store', 'delivery': true, 'take_away': true,
        'schedule_order': true, 'minimum_order': 50, 'prescription_order': true,
        'address': '176 New Market', 'latitude': '23.7', 'longitude': '90.4', 'zone_id': 1,
        'active_coupons': <dynamic>[<String, dynamic>{'code': 'SAVE10'}],
      });
      expect(store.delivery, isTrue);
      expect(store.takeAway, isTrue);
      expect(store.scheduleOrder, isTrue);
      expect(store.minimumOrder, 50);
      expect(store.prescriptionOrder, isTrue);
      expect(store.address, '176 New Market');
      expect(store.zoneId, 1);
      expect(store.activeCoupons, hasLength(1));
    });

    test('a legacy store keeps reading total_items and a full discount', () {
      final Store store = Store.fromJson(<String, dynamic>{
        'id': 1, 'name': 'Legacy Store', 'total_items': 42,
        'discount': <String, dynamic>{
          'discount': 10, 'discount_type': 'percent', 'min_purchase': 100, 'max_discount': 25,
        },
      });
      expect(store.itemCount, 42, reason: 'the items_count fallback must not shadow the old key');
      expect(store.discount!.minPurchase, 100);
      expect(store.discount!.maxDiscount, 25);
    });

    test('items/latest?store_id fills the catalog list', () {
      final ItemModel model = ItemModel.fromJson(payload('store-items') as Map<String, dynamic>);
      expect(model.items, isNotEmpty);
      expect(model.items!.first.id, isNotNull);
      expect(model.items!.first.price, isNotNull);
      expect(model.totalSize, isNotNull);
    }, skip: !has);

    test('items/suggested fills the cart-suggestion row', () {
      final CartSuggestItemModel model =
          CartSuggestItemModel.fromJson(payload('items-suggested') as Map<String, dynamic>);
      expect(model.items, isNotEmpty, reason: 'list moved from `items` to `data`');
      expect(model.items!.first.id, isNotNull);
    }, skip: !has);

    test('banners/{store_id} fills the store banner slider', () {
      final List<StoreBannerModel> banners = ResponseParser.listOrEmpty(payload('store-banners'))
          .map((dynamic e) => StoreBannerModel.fromJson(e))
          .toList();
      expect(banners, isNotEmpty);
    }, skip: !has);

    test('stores/reviews fills the review list', () {
      expect(ResponseParser.listOrEmpty(payload('store-reviews')), isNotEmpty);
    }, skip: !has);
  });

  group('parsed on an isolate — the rawBody path', () {
    test('recommended items unwrap the envelope themselves', () {
      // The raw string still carries {identical_code, message, content, errors}.
      final Map<String, dynamic> envelope = jsonDecode(raw('store-recommended-items')) as Map<String, dynamic>;
      expect(envelope.containsKey('identical_code'), isTrue,
          reason: 'the fixture must be the un-unwrapped body, or this proves nothing');

      final RecommendedItemModel model = recommendedItemModelFromRawJson(raw('store-recommended-items'));
      // Empty for this store, but paging must come through — which only happens
      // if the envelope was unwrapped before the model saw the body.
      expect(model.items, isNotNull, reason: 'null here means the envelope was parsed instead of the payload');
      expect(model.totalSize, isNotNull);
    }, skip: !has);

    test('the category catalog unwraps the envelope and keeps its two lists apart', () {
      final StoreCategoryItemModel model = storeCategoryItemModelFromRawJson(raw('store-category-items'));
      expect(model.categories, isNotEmpty, reason: 'categories is a named list, never `data`');
      expect(model.categoryWiseItems, isNotNull);
      expect(model.categoryWiseItems!.keys, isNotEmpty);
      expect(model.categories!.first.name, isNotNull);
      // This endpoint kept the flat paging keys while the rest of core moved.
      expect(model.totalSize, isNotNull, reason: 'store-categories/items still sends total_size');
    }, skip: !has);

    test('an un-enveloped raw body still parses, so a legacy host keeps working', () {
      final Map<String, dynamic> legacy = <String, dynamic>{
        'total_size': 1, 'limit': '50', 'offset': '1',
        'items': <dynamic>[<String, dynamic>{'id': 7, 'name': 'Olive Oil', 'price': 12, 'discount': 0}],
      };
      final RecommendedItemModel model = recommendedItemModelFromRawJson(jsonEncode(legacy));
      expect(model.items, hasLength(1));
      expect(model.items!.single.id, 7);
      expect(model.totalSize, 1);
    });
  });

  group('ResponseParser.payloadOf', () {
    test('unwraps an envelope and passes anything else through', () {
      expect(
        ResponseParser.payloadOf(<String, dynamic>{
          'identical_code': 'default_200', 'message': 'ok',
          'content': <String, dynamic>{'data': <dynamic>[]}, 'errors': <dynamic>[],
        }),
        <String, dynamic>{'data': <dynamic>[]},
      );
      final Map<String, dynamic> legacy = <String, dynamic>{'items': <dynamic>[]};
      expect(ResponseParser.payloadOf(legacy), same(legacy));
      expect(ResponseParser.payloadOf(<dynamic>[1, 2]), <dynamic>[1, 2]);
    });

    test('leaves an envelope whose content is null alone', () {
      final Map<String, dynamic> body = <String, dynamic>{
        'identical_code': 'default_200', 'message': 'done', 'content': null, 'errors': <dynamic>[],
      };
      expect(ResponseParser.payloadOf(body), same(body));
    });
  });
}
