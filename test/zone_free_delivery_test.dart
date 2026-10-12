import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/models/config_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/helper/zone_free_delivery_helper.dart';

/// Captured from `GET api/v1/config/get-zone-id` for a location sitting in two zones at
/// once, which is the case the store's own zone has to resolve.
const String _wire = '''
{
  "identical_code": "default_200",
  "message": "Successfully fetched",
  "content": {
    "zone_id": "[3,1]",
    "zone_data": [
      {"id": 3, "status": 1, "cash_on_delivery": true, "digital_payment": true, "offline_payment": true,
       "modules": [
         {"id": 6, "module_name": "Rental", "module_type": "rental",
          "free_delivery": {"status": false, "type": null, "minimum_order_amount": null}},
         {"id": 5, "module_name": "Parcel", "module_type": "parcel",
          "free_delivery": {"status": false, "type": null, "minimum_order_amount": null}}
       ]},
      {"id": 1, "status": 1, "cash_on_delivery": true, "digital_payment": true, "offline_payment": true,
       "modules": [
         {"id": 1, "module_name": "Grocery", "module_type": "grocery",
          "free_delivery": {"status": true, "type": "specific_criteria", "minimum_order_amount": 100.0}},
         {"id": 4, "module_name": "Food", "module_type": "food",
          "free_delivery": {"status": true, "type": "all_store", "minimum_order_amount": null}},
         {"id": 3, "module_name": "Shop", "module_type": "ecommerce",
          "free_delivery": {"status": false, "type": null, "minimum_order_amount": null}}
       ]}
    ]
  },
  "errors": []
}''';

List<ZoneData> zonesOf(String wire) {
  final dynamic content = ApiClient.unwrapEnvelope(jsonDecode(wire), 200);
  return (content['zone_data'] as List<dynamic>)
      .map((dynamic zone) => ZoneData.fromJson(zone as Map<String, dynamic>))
      .toList();
}

void main() {
  final List<ZoneData> zones = zonesOf(_wire);

  ZoneFreeDeliveryStatus? progressFor({required int zoneId, required int moduleId, required double subtotal}) {
    final Modules? module = ZoneFreeDeliveryHelper.moduleIn(zones, zoneId: zoneId, moduleId: moduleId);
    return ZoneFreeDeliveryHelper.progressOf(setting: module?.freeDelivery, subtotal: subtotal);
  }

  group('free delivery — the rule the store\'s zone sets for its module', () {
    test('an amount rule counts the cart up to it', () {
      final ZoneFreeDeliveryStatus? status = progressFor(zoneId: 1, moduleId: 1, subtotal: 60);

      expect(status, isNotNull);
      expect(status!.isFree, isFalse);
      expect(status.remaining, 40, reason: '100 minimum, 60 in the cart');
      expect(status.percentage, 0.6);
    });

    test('reaching the amount turns the bar into free delivery', () {
      expect(progressFor(zoneId: 1, moduleId: 1, subtotal: 100)?.isFree, isTrue);
      expect(progressFor(zoneId: 1, moduleId: 1, subtotal: 140)?.isFree, isTrue);
    });

    test('a zone free for every store says so from the first item', () {
      final ZoneFreeDeliveryStatus? status = progressFor(zoneId: 1, moduleId: 4, subtotal: 60);

      expect(status?.isFree, isTrue, reason: 'all_store');
      expect(status?.remaining, 0);
    });

    test('a module with the rule switched off shows nothing', () {
      expect(progressFor(zoneId: 1, moduleId: 3, subtotal: 60), isNull);
    });
  });

  group('free delivery — which zone and module answer', () {
    test('the store\'s zone decides, not the other zone the customer is also in', () {
      // Module 1 offers a 100 rule in zone 1 and is not sold in zone 3 at all.
      expect(ZoneFreeDeliveryHelper.moduleIn(zones, zoneId: 1, moduleId: 1)?.freeDelivery?.status, isTrue);
      expect(ZoneFreeDeliveryHelper.moduleIn(zones, zoneId: 3, moduleId: 1), isNull);
    });

    test('each module in a zone carries its own rule', () {
      expect(ZoneFreeDeliveryHelper.moduleIn(zones, zoneId: 1, moduleId: 1)?.freeDelivery?.type, 'specific_criteria');
      expect(ZoneFreeDeliveryHelper.moduleIn(zones, zoneId: 1, moduleId: 4)?.freeDelivery?.type, 'all_store');
      expect(ZoneFreeDeliveryHelper.moduleIn(zones, zoneId: 1, moduleId: 3)?.freeDelivery?.type, isNull);
    });

    test('a store with no zone or module of its own resolves to nothing', () {
      expect(ZoneFreeDeliveryHelper.moduleIn(zones, zoneId: null, moduleId: 1), isNull);
      expect(ZoneFreeDeliveryHelper.moduleIn(zones, zoneId: 1, moduleId: null), isNull);
      expect(ZoneFreeDeliveryHelper.moduleIn(zones, zoneId: 99, moduleId: 1), isNull);
      expect(ZoneFreeDeliveryHelper.moduleIn(const <ZoneData>[], zoneId: 1, moduleId: 1), isNull);
    });
  });

  group('free delivery — the platform offer standing in for a zone that sets none', () {

    test('a zone rule of its own is answered before the platform is asked', () {
      // What `progressFor` decides between: the zone answers whenever its switch is on,
      // and only a zone with nothing set falls through to the platform's offer.
      final ZoneFreeDelivery? zoneRule =
          ZoneFreeDeliveryHelper.moduleIn(zones, zoneId: 1, moduleId: 1)?.freeDelivery;
      expect(zoneRule?.status, isTrue);
      expect(ZoneFreeDeliveryHelper.progressOf(setting: zoneRule, subtotal: 60)?.remaining, 40);

      final ZoneFreeDelivery? unset =
          ZoneFreeDeliveryHelper.moduleIn(zones, zoneId: 1, moduleId: 3)?.freeDelivery;
      expect(unset?.status, isFalse, reason: 'this is the one that hands over');
    });
  });

  test('the rule survives the address cache, which is where zone data is kept', () {
    // ZoneData rides inside the saved address in shared prefs, so a rule that does not
    // round-trip is lost on the next cold start.
    final Modules module = ZoneFreeDeliveryHelper.moduleIn(zones, zoneId: 1, moduleId: 1)!;
    final Modules restored = Modules.fromJson(jsonDecode(jsonEncode(module.toJson())) as Map<String, dynamic>);

    expect(restored.freeDelivery?.status, isTrue);
    expect(restored.freeDelivery?.type, 'specific_criteria');
    expect(restored.freeDelivery?.minimumOrderAmount, 100.0);
  });
}
