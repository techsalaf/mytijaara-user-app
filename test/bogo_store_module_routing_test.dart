import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/features/bogo_offer/helper/bogo_helper.dart';
import 'package:sixam_mart/features/cart/domain/models/all_carts_model.dart';
import 'package:sixam_mart/features/cart/domain/models/online_cart_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/route_helper.dart';

/// Which module a BOGO offer's store is opened under.
///
/// The offer list is browsed per module tab, so the store behind a bundle is
/// routinely in a different module than the one the app is in. The store route
/// used to carry no module at all and fell back to the active one, and every
/// store request is filtered by the module in its header: `store-categories/items`
/// came back with no categories, `items/recommended` with no data and
/// `bogo/store-offers` 404'd, while `stores/details` still resolved — so the page
/// rendered its header and looked merely empty rather than broken.
///
/// The live case: offer under the pharmacy tab (module 2), bundle store
/// Café Monarch (id 45, module 4 / food).
void main() {
  Store storeIn({int? moduleId}) => Store(id: 45, slug: 'cafe-monarch45', moduleId: moduleId);

  group('storeModuleId', () {
    test('uses the store\'s own module, not the offer\'s', () {
      expect(BogoHelper.storeModuleId(storeIn(moduleId: 4), 2), 4);
    });

    test('falls back to the offer\'s module when the store node omits module_id', () {
      expect(BogoHelper.storeModuleId(storeIn(), 2), 2);
    });

    test('is null when neither carries a module', () {
      expect(BogoHelper.storeModuleId(storeIn(), null), isNull);
      expect(BogoHelper.storeModuleId(null, null), isNull);
    });
  });

  group('store route', () {
    test('carries the store\'s module rather than the active one', () {
      final Store store = storeIn(moduleId: 4);
      final String route = RouteHelper.getStoreRoute(
        id: store.id, page: 'store', slug: store.slug ?? '',
        moduleId: BogoHelper.storeModuleId(store, 2)?.toString(),
      );

      expect(route, contains('module=4'));
      expect(route, isNot(contains('module=2')));
      expect(route, contains('id=45'));
    });
  });

  // The global cart files a group by the module_id the server stamped on its rows,
  // which comes from the header the add request carried. Adding a bundle under the
  // browsing module filed a food store's cart under grocery, and this is the rule
  // that then put it on the wrong tab. Mirrors CartController.getCartsForModule.
  group('global cart tab placement', () {
    bool belongsToModule(AllCartsModel group, int moduleId) =>
        (group.onlineCarts ?? <OnlineCartModel>[]).any((OnlineCartModel row) => row.moduleId == moduleId);

    AllCartsModel bogoGroupStamped(int moduleId) => AllCartsModel.fromJson(<String, dynamic>{
      'store': <String, dynamic>{'id': 45, 'name': 'Café Monarch', 'slug': 'cafe-monarch45'},
      'carts': <dynamic>[
        <String, dynamic>{
          'id': 900, 'module_id': moduleId,
          'bogo_details': <String, dynamic>{'bogo_group_id': 'g-1', 'quantity': 1, 'bundle_price': 100},
        },
      ],
    });

    test('a bundle stamped with the store\'s module sits on that module\'s tab only', () {
      final AllCartsModel group = bogoGroupStamped(4);

      expect(belongsToModule(group, 4), isTrue);
      expect(belongsToModule(group, 2), isFalse);
    });

    test('the bug: stamped with the browsing module, it shows under that one instead', () {
      final AllCartsModel group = bogoGroupStamped(2);

      expect(belongsToModule(group, 2), isTrue);
      expect(belongsToModule(group, 4), isFalse);
    });

    test('a bundle row is placed even though it carries no item of its own', () {
      final AllCartsModel group = bogoGroupStamped(4);

      expect(group.carts!.single.item, isNull);
      expect(group.onlineCarts!.single.moduleId, 4);
    });
  });
}

// SUMMARY
// Covers the module a BOGO offer's store belongs to: the store's own module wins, the
// offer's module stands in when the payload omits it, the store route carries that
// module instead of whichever one the app happens to be in, and the global cart files
// a bundle group on the tab of the module its rows were stamped with.
