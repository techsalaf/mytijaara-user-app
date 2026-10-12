import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/features/store/domain/models/store_category_item_model.dart';
import 'package:sixam_mart/helper/json_parse_helper.dart';

// Builds a category_wise_items payload big enough to cross (or stay under) the
// isolate threshold, so both branches of JsonParseHelper.parse are exercised.
String buildCatalogJson({required int itemsPerCategory, int categoryCount = 3}) {
  final List<Map<String, dynamic>> categories = <Map<String, dynamic>>[];
  final Map<String, dynamic> categoryWiseItems = <String, dynamic>{};

  for (int c = 0; c < categoryCount; c++) {
    final int categoryId = c + 1;
    categories.add(<String, dynamic>{
      'id': categoryId, 'name': 'Category $categoryId', 'image_full_url': 'https://example.com/c$categoryId.png',
      'items_count': itemsPerCategory,
    });
    categoryWiseItems['$categoryId'] = List<Map<String, dynamic>>.generate(itemsPerCategory, (int i) {
      return <String, dynamic>{
        'id': categoryId * 1000 + i, 'name': 'Item $categoryId-$i padded out to a realistic name length',
        'slug': 'item-$categoryId-$i', 'module_type': 'food', 'store_id': 7,
        'price': 12.5, 'discount': 5, 'discount_type': 'percent', 'avg_rating': 4.25, 'rating_count': 18,
        'veg': 1, 'stock': 100, 'status': 1,
        'available_time_starts': '00:00:00', 'available_time_ends': '23:59:59',
        'image_full_url': 'https://example.com/items/$categoryId/$i/image-with-a-realistic-path.png',
        'is_halal': 1, 'halal_tag_status': 1,
      };
    });
  }

  return jsonEncode(<String, dynamic>{
    'total_size': itemsPerCategory * categoryCount, 'limit': null, 'offset': null,
    'category_source': 'store', 'categories': categories, 'category_wise_items': categoryWiseItems,
  });
}

void expectParsedCorrectly(StoreCategoryItemModel model, {required int itemsPerCategory, int categoryCount = 3}) {
  expect(model.categories, hasLength(categoryCount));
  expect(model.categories!.first.name, 'Category 1');
  expect(model.categoryWiseItems, hasLength(categoryCount));
  expect(model.categoryWiseItems!['1'], hasLength(itemsPerCategory));

  final StoreCardItem first = model.categoryWiseItems!['1']!.first;
  expect(first.id, 1000);
  expect(first.price, 12.5);
  expect(first.discountType, 'percent');
  expect(first.isHalal, 1);
  // toItem() is what bridges to the shared card widgets — verify the mapping survives.
  expect(first.toItem().isHalalItem, isTrue);
  expect(first.toItem().price, 12.5);
}

void main() {
  group('storeCategoryItemModelFromRawJson', () {
    test('parses categories and category-wise items', () {
      final String raw = buildCatalogJson(itemsPerCategory: 4);
      expectParsedCorrectly(storeCategoryItemModelFromRawJson(raw), itemsPerCategory: 4);
    });

    test('is a pure top-level function, so it is a valid isolate entry point', () {
      // A tear-off of a top-level function is sendable; this guards against anyone
      // converting it into a closure or adding a Get.find to the parse chain.
      const StoreCategoryItemModel Function(String) entryPoint = storeCategoryItemModelFromRawJson;
      expect(entryPoint(buildCatalogJson(itemsPerCategory: 1)).categories, hasLength(3));
    });
  });

  group('JsonParseHelper.parse', () {
    test('returns the same result below the isolate threshold (sync path)', () async {
      final String raw = buildCatalogJson(itemsPerCategory: 2);
      expect(raw.length, lessThan(JsonParseHelper.isolateThresholdBytes));

      final StoreCategoryItemModel model = await JsonParseHelper.parse(raw, storeCategoryItemModelFromRawJson);
      expectParsedCorrectly(model, itemsPerCategory: 2);
    });

    test('returns the same result above the isolate threshold', () async {
      final String raw = buildCatalogJson(itemsPerCategory: 250);
      expect(raw.length, greaterThan(JsonParseHelper.isolateThresholdBytes));

      final StoreCategoryItemModel model = await JsonParseHelper.parse(raw, storeCategoryItemModelFromRawJson);
      expectParsedCorrectly(model, itemsPerCategory: 250);
      expect(model.totalSize, 750);
    });

    test('propagates FormatException on a malformed body, matching the old inline decode', () async {
      await expectLater(
        JsonParseHelper.parse('<html>502 Bad Gateway</html>', storeCategoryItemModelFromRawJson),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
