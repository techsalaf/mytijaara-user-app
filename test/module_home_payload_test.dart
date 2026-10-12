import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/api/response_parser.dart';
import 'package:sixam_mart/common/models/pagination_model.dart';
import 'package:sixam_mart/features/brands/domain/models/brands_model.dart';
import 'package:sixam_mart/features/flash_sale/domain/models/flash_sale_model.dart';
import 'package:sixam_mart/features/item/domain/models/basic_medicine_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';

/// Covers every list section on the module home screens (food, grocery,
/// pharmacy, e-commerce) against payloads captured from the live backend.
///
/// `ItemModel.fromJson` runs a variation filter that consults
/// `SplashController.getModuleConfig`. No controller is registered here, so the
/// filter fails open and every item is kept — which is exactly the behaviour
/// being asserted: an unavailable module config must not empty a home section.
void main() {
  final Directory fixtures = Directory('test/fixtures/live');
  final bool has = fixtures.existsSync();

  dynamic payload(String name) => ApiClient.unwrapEnvelope(
        jsonDecode(File('${fixtures.path}/$name.json').readAsStringSync()),
        200,
      );

  group('item sections', () {
    for (final String name in <String>['items-discounted', 'items-popular', 'items-most-reviewed']) {
      test('$name populates ItemModel with items and paging', () {
        final ItemModel model = ItemModel.fromJson(payload(name) as Map<String, dynamic>);
        expect(model.items, isNotNull, reason: name);
        expect(model.items, isNotEmpty, reason: name);
        expect(model.items!.first.id, isNotNull);
        expect(model.items!.first.name, isNotNull);
        expect(model.items!.first.price, isNotNull);
        // Paging now arrives under `pagination`; the getters keep their old names.
        expect(model.totalSize, isNotNull, reason: '$name totalSize');
        expect(model.offset, isNotNull, reason: '$name offset (current_page)');
        expect(model.limit, isNotNull, reason: '$name limit (per_page)');
      }, skip: !has);
    }

    test('categories/featured/items keeps its two lists apart', () {
      // This body holds `data` (items) and `categories` side by side. Reading
      // categories via a `data` fallback would return the items again.
      final ItemModel model = ItemModel.fromJson(payload('categories-featured-items') as Map<String, dynamic>);
      expect(model.items, isNotEmpty);
      expect(model.categories, isNotEmpty);
      expect(model.categories!.first.name, isNotNull);
      expect(model.categories!.length, isNot(equals(model.items!.length)),
          reason: 'categories must not be the item list read twice');
    }, skip: !has);

    test('items/basic populates BasicMedicineModel for the pharmacy home', () {
      final BasicMedicineModel model = BasicMedicineModel.fromJson(payload('items-basic') as Map<String, dynamic>);
      expect(model.products, isNotEmpty);
      expect(model.products!.first.id, isNotNull);
      expect(model.totalSize, isNotNull);
    }, skip: !has);
  });

  group('store sections', () {
    for (final String name in <String>[
      'stores-recommended', 'stores-latest', 'stores-verified', 'stores-quick-delivery', 'stores-featured',
    ]) {
      test('$name populates StoreModel', () {
        final StoreModel model = StoreModel.fromJson(payload(name) as Map<String, dynamic>);
        expect(model.stores, isNotNull, reason: name);
        expect(model.stores, isNotEmpty, reason: name);
        expect(model.stores!.first.id, isNotNull);
        expect(model.stores!.first.name, isNotNull);
        expect(model.totalSize, isNotNull, reason: '$name totalSize');
      }, skip: !has);
    }
  });

  group('other home sections', () {
    test('campaigns/basic and campaigns/item expose their lists', () {
      expect(ResponseParser.listOrEmpty(payload('campaigns-basic')), isNotEmpty);
      expect(ResponseParser.listOrEmpty(payload('campaigns-item')), isNotEmpty);
    }, skip: !has);

    test('campaigns/item entries parse through Item, which force-converts price', () {
      // Item.fromJson does `json['price'].toDouble()` — an absent price throws,
      // exactly as it did for the flash-sale row. Parse a real entry to catch it.
      final List<dynamic> camps = ResponseParser.listOrEmpty(payload('campaigns-item'));
      final Item item = Item.fromJson(camps.first as Map<String, dynamic>);
      expect(item.id, isNotNull);
      expect(item.price, isNotNull);
    }, skip: !has);

    test('every store on the home lists survives Store.fromJson', () {
      for (final String name in <String>['stores-featured', 'stores-recommended', 'stores-quick-delivery']) {
        final StoreModel model = StoreModel.fromJson(payload(name) as Map<String, dynamic>);
        for (final Store s in model.stores!) {
          expect(s.id, isNotNull, reason: '$name entry missing id');
        }
      }
    }, skip: !has);

    test('brand exposes the top-brands list', () {
      final List<dynamic> brands = ResponseParser.listOrEmpty(payload('brand'));
      expect(brands, isNotEmpty);
      expect(BrandModel.fromJson(brands.first as Map<String, dynamic>).id, isNotNull);
    }, skip: !has);

    test('flash-sales is a plain object — unwrapping alone is the whole fix', () {
      final FlashSaleModel model = FlashSaleModel.fromJson(payload('flash-sales') as Map<String, dynamic>);
      expect(model.activeProducts, isNotEmpty);
    }, skip: !has);

    test('other-banners is a plain object', () {
      expect(payload('other-banners'), isA<Map<String, dynamic>>());
      expect((payload('other-banners') as Map<String, dynamic>).containsKey('bottom_section_banner_full_url'), isTrue);
    }, skip: !has);
  });

  group('paging equivalence across the two formats', () {
    test('a live pagination block and the legacy flat keys agree', () {
      final Map<String, dynamic> live = payload('items-popular') as Map<String, dynamic>;
      final PaginationModel fromLive = PaginationModel.fromJson(live);
      final PaginationModel fromLegacy = PaginationModel.fromJson(<String, dynamic>{
        'total_size': fromLive.totalSize,
        'limit': fromLive.limit,
        'offset': fromLive.offset,
      });
      expect(fromLegacy.totalSize, fromLive.totalSize);
      expect(fromLegacy.limit, fromLive.limit);
      expect(fromLegacy.offset, fromLive.offset);
    }, skip: !has);
  });
}
