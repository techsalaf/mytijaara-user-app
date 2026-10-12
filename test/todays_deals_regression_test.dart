import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';

/// Regression cover for the grocery home "Today's Deals" section.
///
/// `GET /items/discounted` returns `{data, pagination}` and **no `categories`
/// key at all**. `TodaysDealsSectionWidget` reads `ItemController.discountedItemList`,
/// which is filled by `_prepareDiscountedItems`:
///
/// ```dart
/// _discountedItemList!.addAll(itemModel.items!);
/// if (firstTimeCategoryLoad) _categoryList!.addAll(itemModel.categories!);  // threw
/// _isLoading = false;
/// update();                                                                // never ran
/// ```
///
/// `grocery_module_screen.dart` reveals the section with
/// `firstTimeCategoryLoad: true`, so the null-check threw on every load. The
/// throw landed *before* `update()`, so the list was populated but no rebuild
/// was ever issued and the section stayed on its shimmer.
///
/// These tests assert the model's shape contract, which is what the controller
/// now relies on: `items` non-null and `categories` legitimately null.
void main() {
  final Directory fixtures = Directory('test/fixtures/live');
  final bool has = fixtures.existsSync();

  ItemModel parse(String name) => ItemModel.fromJson(
        ApiClient.unwrapEnvelope(
          jsonDecode(File('${fixtures.path}/$name.json').readAsStringSync()),
          200,
        ) as Map<String, dynamic>,
      );

  test('grocery /items/discounted yields items and a null categories list', () {
    final ItemModel model = parse('grocery-items-discounted');
    expect(model.items, isNotNull);
    expect(model.items, isNotEmpty, reason: "Today's Deals must have products to render");
    expect(model.items!.first.name, isNotNull);
    expect(model.items!.first.price, isNotNull);
    // The crash came from here: this endpoint carries no `categories`.
    expect(model.categories, isNull,
        reason: 'items/discounted returns only data + pagination — nothing to force-unwrap');
  }, skip: !has);

  test('the same holds for the other modules sharing this section', () {
    for (final String name in <String>['items-discounted', 'items-popular']) {
      final ItemModel model = parse(name);
      expect(model.items, isNotEmpty, reason: name);
      expect(model.categories, isNull, reason: '$name carries no categories');
    }
  }, skip: !has);

  test('an endpoint that does carry categories still populates both lists', () {
    // categories/featured/items is the one home endpoint returning both, so the
    // null-safety above must not have made `categories` unreadable everywhere.
    final ItemModel model = parse('categories-featured-items');
    expect(model.items, isNotEmpty);
    expect(model.categories, isNotEmpty);
  }, skip: !has);

  test('a payload with neither key parses to nulls rather than throwing', () {
    final ItemModel model = ItemModel.fromJson(<String, dynamic>{
      'pagination': <String, dynamic>{'current_page': 1, 'per_page': 25, 'total': 0},
    });
    expect(model.items, isNull);
    expect(model.categories, isNull);
    expect(model.totalSize, 0);
  });

  test('an empty data list yields an empty item list, not null', () {
    final ItemModel model = ItemModel.fromJson(<String, dynamic>{
      'data': <dynamic>[],
      'pagination': <String, dynamic>{'current_page': 1, 'per_page': 25, 'total': 0},
    });
    expect(model.items, isEmpty);
  });
}
