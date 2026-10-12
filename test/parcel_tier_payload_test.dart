import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/features/checkout/domain/models/checkout_summary_body_model.dart';
import 'package:sixam_mart/features/parcel/domain/models/parcel_tier_model.dart';

/// `GET /api/v1/parcel-weight` and `GET /api/v1/parcel-dimension` — the two
/// tiers a parcel fee is priced by, on top of the zone's delivery rule and the
/// parcel category.
///
/// The contract these guard is that **an empty list is the answer, not a
/// failure**, and that the two states producing an empty picker are not the same
/// state: `status:false` means this `(zone, module)` does not price by the tier,
/// while `status:true` with `data:[]` means it does but nothing is configured.
/// Collapsing them would be harmless today and wrong the moment either side
/// wants to explain itself to the customer.
void main() {
  group('parcel-weight', () {
    // Trimmed from a real 200, shape intact.
    const String liveBody = '''
    {"status":true,
     "unit":{"type":"weight","unit":"kg","label":"kg","name":"Kilogram","supported":["kg","lb"]},
     "data":[
       {"id":47,"name":"Extra Light","from_weight":0,"to_weight":2,"charge":10},
       {"id":48,"name":"Light","from_weight":2,"to_weight":4,"charge":20}
     ]}''';

    test('parses the bands and the unit block', () {
      final ParcelTierListModel<ParcelWeightModel> tier = ParcelTierListModel<ParcelWeightModel>.fromJson(
        jsonDecode(liveBody) as Map<String, dynamic>, ParcelWeightModel.fromJson,
      );

      expect(tier.status, isTrue);
      expect(tier.requiresSelection, isTrue);
      expect(tier.data, hasLength(2));
      expect(tier.unit!.unit, 'kg');
      expect(tier.unit!.label, 'kg');
      expect(tier.unit!.supported, <String>['kg', 'lb']);

      final ParcelWeightModel light = tier.data[1];
      expect(light.id, 48);
      expect(light.charge, 20);
      // Whole numbers render as whole numbers — `2.0~4.0 kg` reads as a
      // rounding artefact of a band an admin typed as `2` to `4`.
      expect(light.range(tier.unit), '2~4 kg');
    });

    test('a switched-off tier is not the same as a configured-empty one', () {
      final ParcelTierListModel<ParcelWeightModel> off = ParcelTierListModel<ParcelWeightModel>.fromJson(
        jsonDecode('{"status":false,"data":[]}') as Map<String, dynamic>, ParcelWeightModel.fromJson,
      );
      final ParcelTierListModel<ParcelWeightModel> onButEmpty = ParcelTierListModel<ParcelWeightModel>.fromJson(
        jsonDecode('{"status":true,"unit":{"type":"weight","unit":"kg","label":"kg"},"data":[]}') as Map<String, dynamic>,
        ParcelWeightModel.fromJson,
      );

      expect(off.status, isFalse);
      expect(onButEmpty.status, isTrue);
      // Both draw no picker, for different reasons — a switched-on tier with
      // nothing configured would otherwise render a list the customer cannot
      // satisfy, and a missing pick is not refused by the quote.
      expect(off.requiresSelection, isFalse);
      expect(onButEmpty.requiresSelection, isFalse);
    });

    test('a unit switch changes the label, never the stored numbers', () {
      // The same band as configured, reported under pounds. Its *meaning*
      // changes; its value does not. Nothing may convert one into the other.
      const String inPounds = '''
      {"status":true,
       "unit":{"type":"weight","unit":"lb","label":"lb","name":"Pound","supported":["kg","lb"]},
       "data":[{"id":48,"name":"Light","from_weight":2,"to_weight":4,"charge":20}]}''';

      final ParcelTierListModel<ParcelWeightModel> tier = ParcelTierListModel<ParcelWeightModel>.fromJson(
        jsonDecode(inPounds) as Map<String, dynamic>, ParcelWeightModel.fromJson,
      );

      expect(tier.data.single.fromWeight, 2);
      expect(tier.data.single.toWeight, 4);
      expect(tier.data.single.range(tier.unit), '2~4 lb');
    });

    test('survives a dropped unit block and dropped bounds', () {
      final ParcelTierListModel<ParcelWeightModel> tier = ParcelTierListModel<ParcelWeightModel>.fromJson(
        jsonDecode('{"status":true,"data":[{"id":9,"name":"Any","charge":"5"}]}') as Map<String, dynamic>,
        ParcelWeightModel.fromJson,
      );

      expect(tier.unit, isNull);
      // A numeric string is still a number — the whole list must not go down
      // because one field changed shape.
      expect(tier.data.single.charge, 5);
      expect(tier.data.single.range(tier.unit), '');
    });
  });

  group('parcel-dimension', () {
    const String liveBody = '''
    {"status":true,
     "unit":{"type":"dimension","unit":"cm","label":"cm","name":"Centimeter","supported":["cm","in"]},
     "data":[{"id":12,"name":"Small","max_length":100,"max_width":50,"max_height":80,"charge":15}]}''';

    test('parses the size classes', () {
      final ParcelTierListModel<ParcelDimensionModel> tier = ParcelTierListModel<ParcelDimensionModel>.fromJson(
        jsonDecode(liveBody) as Map<String, dynamic>, ParcelDimensionModel.fromJson,
      );

      expect(tier.requiresSelection, isTrue);
      final ParcelDimensionModel small = tier.data.single;
      expect(small.id, 12);
      expect(small.charge, 15);
      expect(small.bounds(tier.unit), '100 × 50 × 80 cm');
    });
  });

  // Entering the set-location screen clears both picks outright
  // (`clearTierSelections`), so every parcel is described from scratch. These
  // cover the *other* question: once the customer has picked on that screen,
  // what may a reload take away — an edited sender address landing in another
  // zone, or a refetch that fails.
  group('a pick already made survives a reload', () {
    // Mirrors ParcelController._survivingPick. Only a real list of bands that
    // does not contain the id disproves it; everything else leaves it standing.
    int? survivingPick(ParcelTierListModel<ParcelWeightModel>? tier, int? id) {
      if (id == null) return null;
      if (tier == null || !tier.requiresSelection) return id;
      return tier.data.any((ParcelWeightModel row) => row.id == id) ? id : null;
    }

    ParcelTierListModel<ParcelWeightModel> tierFrom(String body) =>
        ParcelTierListModel<ParcelWeightModel>.fromJson(
          jsonDecode(body) as Map<String, dynamic>, ParcelWeightModel.fromJson,
        );

    test('a failed request does not discard the pick', () {
      // The repository answers null for any non-200. Dropping the pick here made
      // a flaky connection look like the app forgetting what the customer chose.
      expect(survivingPick(null, 48), 48);
    });

    test('a tier this zone does not price by does not discard the pick', () {
      final ParcelTierListModel<ParcelWeightModel> off = tierFrom('{"status":false,"data":[]}');
      // An id posted at a switched-off tier costs nothing, so an address edit
      // passing through such a zone must not cost the customer their pick.
      expect(survivingPick(off, 48), 48);
    });

    test('a switched-on tier with nothing configured does not discard it either', () {
      final ParcelTierListModel<ParcelWeightModel> empty = tierFrom('{"status":true,"data":[]}');
      expect(survivingPick(empty, 48), 48);
    });

    test('bands that do not offer the id drop it — it belongs to another zone', () {
      final ParcelTierListModel<ParcelWeightModel> other = tierFrom(
        '{"status":true,"data":[{"id":90,"name":"Heavy","from_weight":8,"to_weight":12,"charge":40}]}',
      );
      expect(survivingPick(other, 48), isNull);
    });

    test('bands that still offer the id keep it', () {
      final ParcelTierListModel<ParcelWeightModel> same = tierFrom(
        '{"status":true,"data":[{"id":48,"name":"Light","from_weight":2,"to_weight":4,"charge":20}]}',
      );
      expect(survivingPick(same, 48), 48);
    });
  });

  group('checkout-summary body', () {
    test('sends the tier ids and receiver details, and omits absent ones', () {
      const CheckoutSummaryBodyModel withTiers = CheckoutSummaryBodyModel(
        orderType: 'parcel', orderAmount: 40, distance: 3.2,
        latitude: '23.73', longitude: '90.37', parcelCategoryId: 4,
        weightId: 48, dimensionId: 12,
      );

      final Map<String, dynamic> json = withTiers.toJson();
      expect(json['order_type'], 'parcel');
      expect(json['weight_id'], 48);
      expect(json['dimension_id'], 12);
      // Absent rather than explicitly null — the endpoint validates presence, so
      // a null would fail validation where a missing key passes.
      expect(json.containsKey('area_id'), isFalse);
      expect(json.containsKey('receiver_details'), isFalse);
    });

    test('the signature moves when a tier pick moves', () {
      const CheckoutSummaryBodyModel base = CheckoutSummaryBodyModel(
        orderType: 'parcel', orderAmount: 40, parcelCategoryId: 4, weightId: 48,
      );

      // The fee moves with the pick, so an unchanged signature would let the
      // screen keep showing a quote priced for the previous band.
      expect(base.copyWithTiers(weightId: 49).signature, isNot(base.signature));
      // Weight and dimension are independent switches, so setting one must not
      // clear the other — unlike the area/zip pair, where only one can be set.
      expect(base.copyWithTiers(dimensionId: 12).weightId, 48);
    });
  });
}
