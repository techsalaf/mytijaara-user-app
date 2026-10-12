import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/api/response_parser.dart';
import 'package:sixam_mart/features/brands/domain/models/brands_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/search/domain/models/top_category_model.dart';
import 'package:sixam_mart/features/search/domain/models/trending_search_model.dart';
import 'package:sixam_mart/features/service_module/service_home/domain/models/service_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';

/// Every endpoint the search screen (and its result section) calls, driven from
/// an unedited live capture in test/fixtures/live. A backend shape change that
/// would blank a section on that screen fails here instead of on a device.
Map<String, dynamic> body(String name) {
  final String raw = File('test/fixtures/live/$name.json').readAsStringSync();
  return ApiClient.unwrapEnvelope(jsonDecode(raw), 200) as Map<String, dynamic>;
}

void main() {
  group('GET items/search — item results tab', () {
    test('items come from `data` and paging from `pagination`', () {
      final ItemModel model = ItemModel.fromJson(body('search_items_search'));
      expect(model.items, isNotNull);
      expect(model.items!.length, 10);
      expect(model.totalSize, 51, reason: 'pagination.total drives hasMoreSearchItems');
      expect(model.limit, '10', reason: 'pagination.per_page is the page size');
      expect(model.offset, 1, reason: 'pagination.current_page is the 1-based page');
    });

    test('the sibling `categories` list is not mistaken for the item list', () {
      final ItemModel model = ItemModel.fromJson(body('search_items_search'));
      expect(model.categories, isNotNull);
      expect(model.items!.first.name, isNotNull);
      expect(model.items!.first.storeId, isNotNull);
    });
  });

  group('GET stores/search — store results tab', () {
    late Store first;
    late StoreModel model;

    setUp(() {
      model = StoreModel.fromJson(body('search_stores_search'));
      first = model.stores!.first;
    });

    test('stores come from `data` and paging from `pagination`', () {
      expect(model.stores!.length, 10);
      expect(model.totalSize, 16,
          reason: 'the tab count reads this, not the loaded page length');
    });

    test('the store discount now arrives as avg_item_discount_percentage', () {
      // `store_discount` is null on this payload — reading only `discount` left
      // the result row without its "-20%" chip.
      expect(first.discount, isNull);
      expect(first.avgItemDiscountPercentage, 20);
    });

    test('running offers replace the dropped `offer_label`', () {
      expect(first.offerLabel, isNull);
      expect(first.offers, isNotNull);
      expect(first.offers!.map((StoreOffer o) => o.type), contains('flash_sale'));
    });

    test('distance_km is populated and distance is still metres', () {
      expect(first.distanceKm, closeTo(49.71, 0.01));
      expect(first.distance, greaterThan(1000),
          reason: 'formatDistance() takes metres — this must not be divided first');
    });

    test('top_items back the per-store item carousel', () {
      expect(first.topItems, isNotNull);
      expect(first.topItems!.length, 5);
      expect(first.topItems!.first.price, isNotNull);
    });
  });

  test('GET stores/exclusive-deals parses from `data`', () {
    final StoreModel model = StoreModel.fromJson(body('search_exclusive_deals'));
    expect(model.stores, isNotEmpty);
    expect(model.stores!.first.name, isNotNull);
    // This endpoint keeps a store-level `store_discount`, which Store.fromJson
    // folds into `discount`.
    expect(model.stores!.first.discount?.discount, 10);
  });

  test('GET categories/top parses from `data` (global-search Top Categories)', () {
    final TopCategoryModel model = TopCategoryModel.fromJson(body('search_categories_top'));
    expect(model.categories, isNotNull);
    expect(model.categories!.length, 10);
    expect(model.totalSize, 68, reason: 'captured with no moduleId — all modules');
    expect(model.categories!.first.imageFullUrl, isNotNull);
    expect(model.categories!.first.moduleId, isNotNull);
  });

  test('GET trending-searches still uses the named `trending_searches` list', () {
    final TrendingSearchModel model = TrendingSearchModel.fromJson(body('search_trending'));
    expect(model.trendingSearches, isNotNull);
    expect(model.trendingSearches!.length, 10);
    expect(model.trendingSearches!.first.keyword, isNotEmpty);
  });

  test('GET brand parses from `data` (Top Brands row)', () {
    final List<BrandModel> brands = ResponseParser
        .listOrEmpty(body('search_top_brands'))
        .map((dynamic e) => BrandModel.fromJson(e as Map<String, dynamic>))
        .toList();
    expect(brands, isNotEmpty);
    expect(brands.first.id, isNotNull);
    expect(brands.first.name, isNotNull);
  });

  test('GET service/search still answers with flat paging and `services`', () {
    // The service module has not migrated — both shapes must stay readable.
    final ServiceModel model = ServiceModel.fromJson(body('search_service_search'));
    expect(model.services, isNotNull);
    expect(model.services, isNotEmpty);
    expect(model.totalSize, isNotNull);
    expect(model.offset, 1);
  });
}
