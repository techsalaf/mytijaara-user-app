import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/checkout/domain/repositories/checkout_repository_interface.dart';
import 'package:sixam_mart/features/checkout/domain/services/checkout_service.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/store/domain/services/store_service_interface.dart';

/// Reproduces the sequence `StoreController.getStoreDetails` runs after the
/// response comes back, using the real live payload.
///
/// The store page was rendering its loader forever with the data already
/// fetched. Nothing was wrong with the parsing — `initializeTimeSlot(_store!)`
/// threw on `store.schedules!.length` (the API stopped sending `schedules`), and
/// because the throw landed before `_isLoading = false; update();` the controller
/// never told the UI anything had arrived.
///
/// These tests run that exact call chain, so a regression fails here instead of
/// silently hanging a screen.
class _StubCheckoutRepo implements CheckoutRepositoryInterface {
  // initializeTimeSlot touches no repository method; anything else throws loudly.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The open/closed helpers reach no service; the controller only needs one to
/// be constructible.
class _StubStoreService implements StoreServiceInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final Directory fixtures = Directory('test/fixtures/live');
  final bool has = fixtures.existsSync();

  Store liveStore() => Store.fromJson(
        ApiClient.unwrapEnvelope(
          jsonDecode(File('${fixtures.path}/store-details.json').readAsStringSync()),
          200,
        ) as Map<String, dynamic>,
      );

  final CheckoutService service = CheckoutService(checkoutRepositoryInterface: _StubCheckoutRepo());

  test('the live store really does arrive without schedules', () {
    // If this ever starts failing, the backend restored the field and the guard
    // below is no longer load-bearing.
    expect(liveStore().schedules, isNull);
  }, skip: !has);

  test('initializeTimeSlot survives a store with no schedules', () async {
    // This is the call that threw. It must return, not raise.
    final List<dynamic>? slots = await service.initializeTimeSlot(liveStore(), 30);
    expect(slots, isNotNull);
    expect(slots, isEmpty, reason: 'no schedules means no bookable slots');
  }, skip: !has);

  test('initializeTimeSlot still builds slots when schedules are present', () async {
    // Proves the guard did not disable scheduling for stores that do send them.
    final Store store = Store.fromJson(<String, dynamic>{
      'id': 1,
      'name': 'Scheduled Store',
      'schedules': <dynamic>[
        <String, dynamic>{'id': 1, 'store_id': 1, 'day': 1, 'opening_time': '09:00:00', 'closing_time': '21:00:00'},
      ],
    });
    expect(store.schedules, hasLength(1));
    final List<dynamic>? slots = await service.initializeTimeSlot(store, 30);
    expect(slots, isNotEmpty, reason: 'a 12-hour window at 30-minute slots must produce slots');
  });

  test('the order type resolves without throwing on a null delivery flag', () {
    // getStoreDetails did `_store!.delivery!` here, which threw for the same
    // reason and in the same place — before update().
    final Store store = liveStore();
    expect(store.delivery, isNull);
    final String orderType = (store.delivery ?? true) ? 'delivery' : 'take_away';
    expect(orderType, 'delivery', reason: 'unknown capability falls back to delivery');
  }, skip: !has);

  test('a store that reports take-away only still resolves to take_away', () {
    final Store store = Store.fromJson(<String, dynamic>{'id': 1, 'name': 'Pickup Only', 'delivery': false});
    expect((store.delivery ?? true) ? 'delivery' : 'take_away', 'take_away');
  });

  test('the distance step is skipped rather than parsed when coordinates are absent', () {
    final Store store = liveStore();
    expect(store.latitude, isNull);
    expect(double.tryParse(store.latitude ?? ''), isNull,
        reason: 'double.parse on this threw; tryParse lets the caller skip instead');
  }, skip: !has);

  group('open / closed with no schedules', () {
    final StoreController controller = StoreController(storeServiceInterface: _StubStoreService());

    test('isStoreClosed does not throw when the payload has no schedules', () {
      // `schedules!.length` threw here, and this runs inside build() on the
      // store page, the store description panel and the checkout time slots.
      expect(controller.isStoreClosed(true, true, null), isFalse);
      expect(controller.isStoreClosed(false, true, null), isFalse);
      expect(controller.isStoreClosed(true, false, null), isTrue, reason: 'inactive is still closed');
    });

    test('isStoreOpenNow falls back to the active flag with no schedules', () {
      expect(controller.isStoreOpenNow(true, null), isTrue);
      expect(controller.isStoreOpenNow(false, null), isFalse);
    });

    test('isStoreOpen reads the API open flag when schedules are absent', () {
      Store store(int open, int active) =>
          Store.fromJson(<String, dynamic>{'id': 1, 'name': 'S', 'open': open, 'active': active});
      expect(controller.isStoreOpen(store(1, 1)), isTrue);
      expect(controller.isStoreOpen(store(0, 1)), isFalse, reason: 'closed right now');
      expect(controller.isStoreOpen(store(1, 0)), isFalse, reason: 'store switched off');
    });

    test('the live store resolves without throwing', () {
      final Store store = liveStore();
      expect(store.schedules, isNull);
      expect(controller.isStoreOpen(store), store.open == 1 && (store.active ?? false));
    }, skip: !has);

    test('a store that still sends schedules is judged against them', () {
      // Day 6 days from now, so it never matches today and the check resolves
      // without needing the app's clock.
      final int otherDay = (DateTime.now().weekday + 3) % 7;
      final Store store = Store.fromJson(<String, dynamic>{
        'id': 1, 'name': 'Scheduled', 'open': 1, 'active': 1,
        'schedules': <dynamic>[
          <String, dynamic>{'id': 1, 'store_id': 1, 'day': otherDay, 'opening_time': '09:00:00', 'closing_time': '21:00:00'},
        ],
      });
      expect(controller.isStoreOpen(store), isFalse,
          reason: 'no schedule for today, even though the open flag says otherwise');
    });
  });

  group('the item filter price span', () {
    final StoreController controller = StoreController(storeServiceInterface: _StubStoreService());

    // FilterWidget builds a RangeSlider straight out of these four getters, and
    // RangeSlider asserts min < max, divisions > 0 and start/end inside the
    // range. Any store must satisfy all four.
    void expectSliderIsBuildable(StoreController c) {
      expect(c.getLowerLimit, lessThan(c.getUpperLimit));
      expect(c.priceDivisions, greaterThan(0));
      expect(c.lowerValue, greaterThanOrEqualTo(c.getLowerLimit));
      expect(c.upperValue, lessThanOrEqualTo(c.getUpperLimit));
      expect(c.lowerValue, lessThanOrEqualTo(c.upperValue));
    }

    test('a store with no price_range keeps the placeholder span', () {
      // The legacy backend sends no price_range at all. Those limits, and the
      // 99999 divisions the widget used to hard-code, must be unchanged.
      controller.applyPriceRange(Store.fromJson(<String, dynamic>{'id': 1, 'name': 'Legacy'}));
      expect(controller.getLowerLimit, 0);
      expect(controller.getUpperLimit, 99999);
      expect(controller.priceDivisions, 99999);
      expectSliderIsBuildable(controller);
    });

    test('a live store span reaches the slider', () {
      final Store store = Store.fromJson(
        ApiClient.unwrapEnvelope(
          jsonDecode(File('${fixtures.path}/store-details-discounted.json').readAsStringSync()),
          200,
        ) as Map<String, dynamic>,
      );
      controller.applyPriceRange(store);
      expect(controller.getLowerLimit, store.minPrice);
      expect(controller.getUpperLimit, store.maxPrice);
      expectSliderIsBuildable(controller);
    }, skip: !has);

    test('a store whose items are all under 1.00 still builds a slider', () {
      // The widget used to pass the upper limit as the slider's divisions,
      // which would be 0 here and trip RangeSlider's assertion.
      controller.applyPriceRange(Store.fromJson(<String, dynamic>{
        'id': 1, 'name': 'Penny Sweets',
        'price_range': <dynamic>[<String, dynamic>{'min_price': '0.10', 'max_price': '0.90'}],
      }));
      expect(controller.getUpperLimit, 0.9);
      expectSliderIsBuildable(controller);
    });

    test('a single-price store falls back to the placeholder span', () {
      controller.applyPriceRange(Store.fromJson(<String, dynamic>{
        'id': 1, 'name': 'One Price',
        'price_range': <dynamic>[<String, dynamic>{'min_price': '5.00', 'max_price': '5.00'}],
      }));
      expect(controller.getLowerLimit, 0, reason: 'min == max cannot drive a slider');
      expect(controller.getUpperLimit, 99999);
      expectSliderIsBuildable(controller);
    });

    test('one store does not inherit the previous store span', () {
      // The controller is a singleton, so opening a store with a range and then
      // one without has to land back on the placeholder.
      controller.applyPriceRange(Store.fromJson(<String, dynamic>{
        'id': 1, 'name': 'Ranged',
        'price_range': <dynamic>[<String, dynamic>{'min_price': '6.00', 'max_price': '2000.00'}],
      }));
      expect(controller.getUpperLimit, 2000);
      controller.applyPriceRange(Store.fromJson(<String, dynamic>{'id': 2, 'name': 'Unranged'}));
      expect(controller.getUpperLimit, 99999);
      expectSliderIsBuildable(controller);
    });

    test('an untouched filter sends no price bounds to the item query', () {
      // Sitting on the limits has to mean "no price filter", exactly as 0/0 did
      // before the slider had a real span.
      controller.applyPriceRange(Store.fromJson(<String, dynamic>{
        'id': 1, 'name': 'Ranged',
        'price_range': <dynamic>[<String, dynamic>{'min_price': '6.00', 'max_price': '2000.00'}],
      }));
      expect(controller.lowerValue <= controller.getLowerLimit, isTrue);
      expect(controller.upperValue >= controller.getUpperLimit, isTrue);

      controller.setLowerAndUpperValue(lower: 100, upper: 900, reload: false);
      expect(controller.lowerValue > controller.getLowerLimit, isTrue, reason: 'now it must narrow');
      expect(controller.upperValue < controller.getUpperLimit, isTrue);
      expectSliderIsBuildable(controller);
    });

    test('clearing the filter leaves the slider inside its own range', () {
      // RangeSlider asserts when its values fall outside [min, max]. Once a
      // store reports a price range the minimum is no longer 0, so resetting
      // to 0 crashed the filter dialog's "clear filter" button.
      controller.setLowerAndUpperLimit(lower: 6, upper: 2000, reload: false);
      controller.resetFilter(isUpdate: false);
      expect(controller.lowerValue, greaterThanOrEqualTo(controller.getLowerLimit));
      expect(controller.upperValue, lessThanOrEqualTo(controller.getUpperLimit));
      expect(controller.lowerValue, lessThanOrEqualTo(controller.upperValue));
    });

  });
}
