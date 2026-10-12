import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/api/response_parser.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/home/domain/models/cashback_model.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_model.dart';
import 'package:sixam_mart/features/smart_banner/domain/models/smart_banner_model.dart';
import 'package:sixam_mart/features/search/domain/models/search_suggestion_model.dart';
import 'package:sixam_mart/features/service_module/service_home/domain/models/service_model.dart';

/// End-to-end parsing checks for the splash → home endpoints whose payload shape
/// changed, driven through the same two steps a repository performs:
/// [ApiClient.unwrapEnvelope] then [ResponseParser.listOf].
///
/// Each endpoint is asserted twice — the enveloped payload (trimmed from
/// `docs/New-api-responses.md`) and the legacy payload the current backend
/// returns — and both must yield the same models. That equivalence is what makes
/// this change safe to ship before the backend cuts over.
void main() {
  /// What a repository does: unwrap the envelope, then pull the list out.
  List<dynamic> parse(String rawJson, {String? legacyKey, int statusCode = 200}) {
    final dynamic decoded = jsonDecode(rawJson);
    final dynamic body = ApiClient.unwrapEnvelope(decoded, statusCode);
    return ResponseParser.listOrEmpty(body, legacyKey: legacyKey);
  }

  group('GET /api/v1/module', () {
    const String enveloped = '''
    {"identical_code":"default_200","message":"Successfully fetched","content":{"data":[
      {"id":1,"module_name":"Grocery","module_type":"grocery","thumbnail":"g.png"},
      {"id":4,"module_name":"Food","module_type":"food","thumbnail":"f.png"}]},"errors":[]}''';

    const String legacy = '''
    [{"id":1,"module_name":"Grocery","module_type":"grocery","thumbnail":"g.png"},
     {"id":4,"module_name":"Food","module_type":"food","thumbnail":"f.png"}]''';

    test('both formats yield the same modules', () {
      for (final String raw in <String>[enveloped, legacy]) {
        final List<ModuleModel> modules =
            parse(raw).map((dynamic e) => ModuleModel.fromJson(e)).toList();
        expect(modules, hasLength(2), reason: 'payload: $raw');
        expect(modules.first.id, 1);
        expect(modules.first.moduleType, 'grocery');
        expect(modules.last.moduleName, 'Food');
      }
    });
  });

  group('GET /api/v1/categories', () {
    const String enveloped = '''
    {"identical_code":"default_200","message":"Successfully fetched","content":{"data":[
      {"id":2,"name":"Vegetables","image":"v.png","parent_id":0},
      {"id":3,"name":"Fruits","image":"f.png","parent_id":0}]},"errors":[]}''';

    const String legacy = '''
    [{"id":2,"name":"Vegetables","image":"v.png","parent_id":0},
     {"id":3,"name":"Fruits","image":"f.png","parent_id":0}]''';

    test('both formats yield the same categories', () {
      for (final String raw in <String>[enveloped, legacy]) {
        final List<CategoryModel> categories =
            parse(raw).map((dynamic e) => CategoryModel.fromJson(e)).toList();
        expect(categories, hasLength(2), reason: 'payload: $raw');
        expect(categories.first.id, 2);
        expect(categories.first.name, 'Vegetables');
      }
    });
  });

  group('GET /api/v1/customer/notifications', () {
    // Note each notification carries its own nested `data` object. The list-level
    // `data` key and the per-item one must not be confused — the extractor takes
    // the list at the top level only.
    const String enveloped = '''
    {"identical_code":"default_200","message":"Successfully fetched","content":{"data":[
      {"id":11,"data":{"title":"Order placed","description":"Your order is confirmed"},"created_at":"2026-08-27T08:13:03.000000Z"}],
      "pagination":{"current_page":1,"last_page":1,"per_page":25,"total":1}},"errors":[]}''';

    const String legacy = '''
    [{"id":11,"data":{"title":"Order placed","description":"Your order is confirmed"},"created_at":"2026-08-27T08:13:03.000000Z"}]''';

    test('both formats yield the same notifications', () {
      for (final String raw in <String>[enveloped, legacy]) {
        final List<NotificationModel> items =
            parse(raw).map((dynamic e) => NotificationModel.fromJson(e)).toList();
        expect(items, hasLength(1), reason: 'payload: $raw');
        expect(items.single.id, 11);
        expect(items.single.data!.title, 'Order placed');
      }
    });
  });

  group('GET /api/v1/cashback/list', () {
    const String enveloped = '''
    {"identical_code":"default_200","message":"Successfully fetched","content":{"data":[
      {"id":5,"cashback_type":"percentage","cashback_amount":10,"max_discount":50}],
      "pagination":{"current_page":1,"last_page":1,"per_page":25,"total":1}},"errors":[]}''';

    const String legacy = '[{"id":5,"cashback_type":"percentage","cashback_amount":10,"max_discount":50}]';

    test('both formats yield the same cashback offers', () {
      for (final String raw in <String>[enveloped, legacy]) {
        final List<CashBackModel> offers =
            parse(raw).map((dynamic e) => CashBackModel.fromJson(e)).toList();
        expect(offers, hasLength(1), reason: 'payload: $raw');
        expect(offers.single.id, 5);
      }
    });
  });

  group('GET /api/v1/smart-banners', () {
    // SmartBannerModel takes the whole body, so it is the model itself that has
    // to tolerate both `data` and the legacy `smart_banners` key.
    const String enveloped = '''
    {"identical_code":"default_200","message":"Successfully fetched","content":{"data":[
      {"title":"Are you hungry?","subtitle":"Explore our food and enjoy.","position":"top",
       "redirect_type":"module_home","redirect_target_id":null,"module_id":4}],
      "pagination":{"current_page":1,"last_page":1,"per_page":25,"total":1}},"errors":[]}''';

    const String legacy = '''
    {"smart_banners":[
      {"title":"Are you hungry?","subtitle":"Explore our food and enjoy.","position":"top",
       "redirect_type":"module_home","redirect_target_id":null,"module_id":4}]}''';

    test('both formats yield the same smart banners', () {
      for (final String raw in <String>[enveloped, legacy]) {
        final dynamic body = ApiClient.unwrapEnvelope(jsonDecode(raw), 200);
        final SmartBannerModel model = SmartBannerModel.fromJson(body as Map<String, dynamic>);
        expect(model.smartBanners, hasLength(1), reason: 'payload: $raw');
        expect(model.smartBanners!.single.title, 'Are you hungry?');
        expect(model.smartBanners!.single.position, 'top');
      }
    });

    test('an unrelated body leaves the list null rather than throwing', () {
      final SmartBannerModel model = SmartBannerModel.fromJson(<String, dynamic>{'message': 'ok'});
      expect(model.smartBanners, isNull);
    });
  });

  group('GET /api/v1/stores/get-stores/all?featured=1', () {
    // The store list moved from a named `stores` key to `data`.
    const String enveloped = '''
    {"identical_code":"default_200","message":"Successfully fetched",
     "content":{"data":[{"id":7,"name":"Fresh Mart"}],
     "pagination":{"current_page":1,"last_page":1,"per_page":50,"total":1}},"errors":[]}''';

    const String legacy = '{"stores":[{"id":7,"name":"Fresh Mart"}],"total_size":1,"limit":"50","offset":1}';

    test('both formats expose the same raw store entries', () {
      for (final String raw in <String>[enveloped, legacy]) {
        final List<dynamic> stores = parse(raw, legacyKey: 'stores');
        expect(stores, hasLength(1), reason: 'payload: $raw');
        expect(stores.single['id'], 7);
        expect(stores.single['name'], 'Fresh Mart');
      }
    });
  });

  group('GET /api/v1/customer/address/list', () {
    const String enveloped = '''
    {"identical_code":"default_200","message":"Successfully fetched",
     "content":{"data":[{"id":31,"address_type":"home","address":"176 New Market"}]},"errors":[]}''';

    const String legacy = '{"addresses":[{"id":31,"address_type":"home","address":"176 New Market"}]}';

    test('both formats expose the same raw address entries', () {
      for (final String raw in <String>[enveloped, legacy]) {
        final List<dynamic> addresses = parse(raw, legacyKey: 'addresses');
        expect(addresses, hasLength(1), reason: 'payload: $raw');
        expect(addresses.single['id'], 31);
      }
    });
  });

  group('GET /api/v1/customer/cart/get-all', () {
    // This one's `content` is a bare array, so unwrapping alone is enough and the
    // repository's existing iteration keeps working.
    const String enveloped = '''
    {"identical_code":"default_200","message":"Successfully fetched",
     "content":[{"module_id":1,"cart_items":[]}],"errors":[]}''';

    const String legacy = '[{"module_id":1,"cart_items":[]}]';

    test('both formats expose the same cart groups', () {
      for (final String raw in <String>[enveloped, legacy]) {
        final List<dynamic> carts = parse(raw);
        expect(carts, hasLength(1), reason: 'payload: $raw');
        expect(carts.single['module_id'], 1);
      }
    });
  });

  group('GET /api/v1/customer/order/last', () {
    const String enveloped = '''
    {"identical_code":"default_200","message":"Successfully fetched","content":{"data":[
      {"id":102957,"order_status":"delivered","module_id":1}],
      "pagination":{"current_page":1,"last_page":1,"per_page":25,"total":1}},"errors":[]}''';

    const String legacy = '[{"id":102957,"order_status":"delivered","module_id":1}]';

    test('both formats expose the same last orders', () {
      for (final String raw in <String>[enveloped, legacy]) {
        final List<dynamic> orders = parse(raw);
        expect(orders, hasLength(1), reason: 'payload: $raw');
        expect(orders.single['id'], 102957);
      }
    });

    test('a body with no list still resolves to null, not an exception', () {
      final dynamic body = ApiClient.unwrapEnvelope(
        jsonDecode('{"identical_code":"default_200","message":"none","content":{"foo":1},"errors":[]}'),
        200,
      );
      expect(ResponseParser.listOf(body), isNull);
    });
  });

  group('POST /api/v1/auth/guest/request', () {
    test('201 Created is unwrapped and the guest id is readable', () {
      const String raw =
          '{"identical_code":"default_store_201","message":"Successfully created","content":{"guest_id":6778},"errors":[]}';
      final dynamic body = ApiClient.unwrapEnvelope(jsonDecode(raw), 201);
      expect(body['guest_id'].toString(), '6778');
    });

    test('the legacy flat body still reads the same way', () {
      final dynamic body = ApiClient.unwrapEnvelope(jsonDecode('{"guest_id":6778}'), 200);
      expect(body['guest_id'].toString(), '6778');
    });
  });

  group('GET /api/v1/items/item-or-store-search  (search suggestions)', () {
    // Captured live from 6ammart-dev (moduleId 4). The item list is under `data`;
    // `stores` kept its name. Both lists sit in the same body, which is why the store
    // list must never fall back to `data`.
    const String enveloped = """
    {"identical_code":"default_200","message":"Successfully fetched","content":{
      "data":[{"id":412,"name":"adfg","image_full_url":"https://x/a.webp","module_id":4,
               "module":{"id":4,"name":"Food","image":null,"type":"food"}},
              {"id":396,"name":"Aromatic Biryani Rice","image_full_url":"https://x/b.webp","module_id":4,
               "module":{"id":4,"name":"Food","image":null,"type":"food"}}],
      "stores":[{"id":46,"name":"Hungry Puppetssss","logo":"l.webp","logo_full_url":"https://x/l.webp",
                 "module_id":4,"open":1,"distance":51058.9,"distance_km":51.06,
                 "module":{"id":4,"name":"Food","image":null,"type":"food"}}],
      "pagination":{"current_page":1,"last_page":1,"per_page":25,"total":2}},"errors":[]}""";

    // What `service/item-or-store-search` still returns, and what the mart endpoint
    // used to return: the item list named `items`.
    const String legacy = """
    {"items":[{"id":412,"name":"adfg","image_full_url":"https://x/a.webp","module_id":4,
               "module":{"id":4,"name":"Food","image":null,"type":"food"}},
              {"id":396,"name":"Aromatic Biryani Rice","image_full_url":"https://x/b.webp","module_id":4,
               "module":{"id":4,"name":"Food","image":null,"type":"food"}}],
     "stores":[{"id":46,"name":"Hungry Puppetssss","logo":"l.webp","logo_full_url":"https://x/l.webp",
                "module_id":4,"open":1,
                "module":{"id":4,"name":"Food","image":null,"type":"food"}}]}""";

    SearchSuggestionModel model(String raw) => SearchSuggestionModel.fromJson(
      ApiClient.unwrapEnvelope(jsonDecode(raw), 200) as Map<String, dynamic>);

    test('the new `data` key yields the item suggestions', () {
      final SearchSuggestionModel m = model(enveloped);
      expect(m.items, isNotNull, reason: 'reading only `items` returned null here');
      expect(m.items!.length, 2);
      expect(m.items!.first.name, 'adfg');
      expect(m.items!.first.module?.type, 'food');
    });

    test('the legacy `items` key parses identically', () {
      final SearchSuggestionModel a = model(enveloped);
      final SearchSuggestionModel b = model(legacy);
      expect(b.items!.length, a.items!.length);
      expect(b.items!.map((e) => e.name), a.items!.map((e) => e.name));
      expect(b.stores!.map((e) => e.name), a.stores!.map((e) => e.name));
    });

    test('stores never receive the item list', () {
      // namedListOf must not fall back to `data`, which holds the items.
      final SearchSuggestionModel m = model(enveloped);
      expect(m.stores!.length, 1);
      expect(m.stores!.single.name, 'Hungry Puppetssss');
      expect(m.stores!.map((e) => e.name), isNot(contains('adfg')));
    });

    test('a body with only stores leaves items null, not mis-filled', () {
      const String storesOnly =
          '{"identical_code":"default_200","message":"m","content":{"data":[],"stores":[{"id":46,"name":"S"}],"pagination":{"total":0}},"errors":[]}';
      final SearchSuggestionModel m = model(storesOnly);
      expect(m.items, isEmpty);
      expect(m.stores!.single.name, 'S');
    });
  });

  group('GET /api/v1/service/search', () {
    test('flat `services` still wins, and `data` is accepted', () {
      final ServiceModel flat = ServiceModel.fromJson(ApiClient.unwrapEnvelope(jsonDecode(
        '{"total_size":2,"limit":10,"offset":1,"services":[{"id":1,"name":"Clean"}],"categories":[{"id":9,"name":"Home"}]}'), 200) as Map<String, dynamic>);
      expect(flat.services!.single.name, 'Clean');
      expect(flat.categories!.single.name, 'Home');
      expect(flat.totalSize, 2);

      final ServiceModel migrated = ServiceModel.fromJson(ApiClient.unwrapEnvelope(jsonDecode(
        '{"identical_code":"default_200","message":"m","content":{"data":[{"id":1,"name":"Clean"}],"categories":[{"id":9,"name":"Home"}],"pagination":{"total":2,"per_page":10,"current_page":1}},"errors":[]}'), 200) as Map<String, dynamic>);
      expect(migrated.services!.single.name, 'Clean');
      expect(migrated.categories!.single.name, 'Home',
          reason: 'categories must not be handed the services list');
      expect(migrated.totalSize, 2);
    });
  });
}
