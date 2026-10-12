import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/search/domain/models/search_suggestion_model.dart';

/// Drives the *unedited* live captures in test/fixtures/live through the model,
/// so a backend change that breaks suggestions fails here rather than on a device.
SearchSuggestionModel parseFixture(String name) {
  final String raw = File('test/fixtures/live/$name.json').readAsStringSync();
  final dynamic body = ApiClient.unwrapEnvelope(jsonDecode(raw), 200);
  return SearchSuggestionModel.fromJson(body as Map<String, dynamic>);
}

void main() {
  test('live mart suggestions: item matches are parsed', () {
    // GET items/item-or-store-search?name=pizza — 10 items under `data`, no stores.
    final SearchSuggestionModel m = parseFixture('search_suggestions_mart');
    expect(m.items, isNotNull);
    expect(m.items!.length, 10, reason: 'this was 0 before the fix');
    expect(m.items!.every((e) => e.id != null && e.name != null), isTrue);
  });

  test('live mart suggestions: store matches are parsed and not confused with items', () {
    // GET items/item-or-store-search?name=hungry — 0 items, 1 store.
    final SearchSuggestionModel m = parseFixture('search_suggestions_mart_store');
    expect(m.stores!.length, 1);
    expect(m.stores!.single.name, 'Hungry Puppetssss');
    expect(m.stores!.single.logoFullUrl, isNotNull);
    expect(m.items, isEmpty, reason: 'the empty `data` list must not leak into stores');
  });

  test('live service suggestions still parse from `items`', () {
    final SearchSuggestionModel m = parseFixture('search_suggestions_service');
    // This environment has no matching services; what matters is that it parses.
    expect(m.items ?? const [], isEmpty);
    expect(m.stores ?? const [], isEmpty);
  });
}
