import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/store/domain/services/store_service_interface.dart';

/// Only the two members StoreController needs to build the featured / visit-again
/// lists; everything else on the interface throws if it is ever reached.
class _FakeStoreService implements StoreServiceInterface {
  _FakeStoreService({required this.stores, required this.modules});

  final List<Store> stores;
  final List<Modules> modules;

  @override
  List<Modules> moduleList() => modules;

  @override
  Future<List<Store>?> getFeaturedStoreList({required DataSourceEnum source, bool fromHome = false}) async => stores;

  @override
  Future<List<Store>?> getVisitAgainStoreList({required DataSourceEnum source}) async => stores;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

List<Store> _liveFeaturedStores() {
  final String raw = File('test/fixtures/live/featured_stores_food.json').readAsStringSync();
  final dynamic body = ApiClient.unwrapEnvelope(jsonDecode(raw), 200);
  return StoreModel.fromJson(body as Map<String, dynamic>).stores!;
}

/// A zone serving the food module (4), the way `config/get-zone-id` reports it.
List<Modules> _zoneModules({int zoneId = 3, List<int> moduleIds = const <int>[1, 4, 5]}) =>
    moduleIds.map((int id) => Modules(id: id, pivot: Pivot(zoneId: zoneId))).toList();

void main() {
  test('the live featured payload no longer carries zone_id', () {
    // This is what broke the section: the filter compared the zone's real id
    // against a null, so no store could ever match.
    final List<Store> stores = _liveFeaturedStores();
    expect(stores.length, 5);
    expect(stores.every((Store s) => s.zoneId == null), isTrue);
    expect(stores.every((Store s) => s.moduleId == 4), isTrue);
  });

  test('featured stores survive the zone filter when the payload omits zone_id', () async {
    final StoreController controller = StoreController(
      storeServiceInterface: _FakeStoreService(stores: _liveFeaturedStores(), modules: _zoneModules()),
    );

    await controller.getFeaturedStoreList(dataSource: DataSourceEnum.client, notify: false);

    expect(controller.featuredStoreList, isNotNull);
    expect(controller.featuredStoreList!.length, 5, reason: 'this was 0 before the fix');
  });

  test('visit-again stores go through the same filter', () async {
    final StoreController controller = StoreController(
      storeServiceInterface: _FakeStoreService(stores: _liveFeaturedStores(), modules: _zoneModules()),
    );

    await controller.getVisitAgainStoreList(dataSource: DataSourceEnum.client);

    expect(controller.visitAgainStoreList!.length, 5, reason: 'this was 0 before the fix');
  });

  test('a store in a module the zone does not serve is still dropped', () async {
    final StoreController controller = StoreController(
      storeServiceInterface: _FakeStoreService(
        stores: _liveFeaturedStores(),
        // Zone serves grocery and parcel only — none of these food stores belong.
        modules: _zoneModules(moduleIds: const <int>[1, 5]),
      ),
    );

    await controller.getFeaturedStoreList(dataSource: DataSourceEnum.client, notify: false);

    expect(controller.featuredStoreList, isEmpty);
  });

  test('a legacy store that still reports zone_id is matched on it', () async {
    final List<Store> stores = <Store>[
      Store(id: 1, moduleId: 4, zoneId: 3),
      Store(id: 2, moduleId: 4, zoneId: 99),
    ];
    final StoreController controller = StoreController(
      storeServiceInterface: _FakeStoreService(stores: stores, modules: _zoneModules()),
    );

    await controller.getFeaturedStoreList(dataSource: DataSourceEnum.client, notify: false);

    expect(controller.featuredStoreList!.map((Store s) => s.id), <int>[1]);
  });

  test('a module served by two of the address zones does not duplicate a store', () async {
    final List<Modules> modules = <Modules>[
      Modules(id: 4, pivot: Pivot(zoneId: 3)),
      Modules(id: 4, pivot: Pivot(zoneId: 7)),
    ];
    final StoreController controller = StoreController(
      storeServiceInterface: _FakeStoreService(stores: _liveFeaturedStores(), modules: modules),
    );

    await controller.getFeaturedStoreList(dataSource: DataSourceEnum.client, notify: false);

    expect(controller.featuredStoreList!.length, 5, reason: 'each store appears once, not once per zone');
  });

  test('no cached zone data yet — trust the scoping the API already applied', () async {
    final StoreController controller = StoreController(
      storeServiceInterface: _FakeStoreService(stores: _liveFeaturedStores(), modules: const <Modules>[]),
    );

    await controller.getFeaturedStoreList(dataSource: DataSourceEnum.client, notify: false);

    expect(controller.featuredStoreList!.length, 5);
  });
}
