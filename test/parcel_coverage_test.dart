import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/features/checkout/domain/models/checkout_summary_body_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/coverage_list_model.dart';
import 'package:sixam_mart/features/parcel/controllers/parcel_controller.dart';
import 'package:sixam_mart/features/parcel/domain/services/parcel_service_interface.dart';

/// The area / ZIP pick in the parcel flow.
///
/// A parcel is priced by the sender zone's delivery rule, the same rule a store
/// checkout is priced by, so a zone configured `area_wise` or `zip_code_wise`
/// asks a parcel customer the same question. The contract these guard:
///
///   * an empty coverage list is the answer, not a failure — most zones price by
///     distance or a flat amount and must show no picker at all;
///   * the pick survives a reload unless the new list proves it wrong, because
///     the load is fired un-awaited from `initState`;
///   * exactly one of `area_id` / `zip_code_id` is ever posted;
///   * both go to the quote, so the fee on screen is the fee charged.

/// Only `getParcelCoverageList` is reachable from the code under test; every
/// other member throws, so a change that starts calling one fails loudly here
/// instead of silently passing against a stub that returns null.
class _FakeParcelService implements ParcelServiceInterface {
  _FakeParcelService(this.responses);

  /// Queued answers, one per `loadParcelCoverage` call.
  final List<CoverageListModel?> responses;
  final List<({int zoneId, int? moduleId})> calls = <({int zoneId, int? moduleId})>[];

  @override
  Future<CoverageListModel?> getParcelCoverageList({required int zoneId, int? moduleId}) async {
    calls.add((zoneId: zoneId, moduleId: moduleId));
    return responses.removeAt(0);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
        '${invocation.memberName} is not expected to be called by the coverage path',
      );
}

CoverageListModel _coverage(String rawBody) =>
    CoverageListModel.fromJson(jsonDecode(rawBody) as Map<String, dynamic>);

/// A live `area_wise` body, trimmed, shape intact.
const String _areaWiseBody = '''
{"type":"area_wise",
 "coverage":[
   {"id":11,"name":"Gulshan"},
   {"id":12,"name":"Banani"},
   {"id":13,"name":"Dhanmondi"}
 ]}''';

const String _zipWiseBody = '''
{"type":"zip_code_wise",
 "coverage":[{"id":901,"name":"1212"},{"id":902,"name":"1230"}]}''';

/// What a distance-priced zone answers: the rule needs nothing picked.
const String _distanceWiseBody = '{"type":"distance_wise","coverage":[]}';

void main() {
  group('CoverageListModel, read by the parcel flow', () {
    test('area_wise asks for a pick and posts it as area_id', () {
      final CoverageListModel coverage = _coverage(_areaWiseBody);
      expect(coverage.requiresSelection, isTrue);
      expect(coverage.isZipCode, isFalse);
      expect(coverage.coverage.map((CoverageOption o) => o.name), <String>['Gulshan', 'Banani', 'Dhanmondi']);
    });

    test('zip_code_wise asks for a pick and posts it as zip_code_id', () {
      final CoverageListModel coverage = _coverage(_zipWiseBody);
      expect(coverage.requiresSelection, isTrue);
      expect(coverage.isZipCode, isTrue);
    });

    test('distance_wise asks for nothing — the empty list is the answer', () {
      expect(_coverage(_distanceWiseBody).requiresSelection, isFalse);
    });

    test('an area_wise rule with nothing configured still asks for nothing', () {
      // Otherwise the customer gets an empty dropdown they cannot satisfy, and
      // the send button they cannot get past.
      expect(_coverage('{"type":"area_wise","coverage":[]}').requiresSelection, isFalse);
    });

    test('a rule this zone has none of parses without a type', () {
      final CoverageListModel coverage = _coverage('{"type":null,"coverage":[]}');
      expect(coverage.type, isNull);
      expect(coverage.requiresSelection, isFalse);
    });
  });

  group('ParcelController.loadParcelCoverage', () {
    test('asks for the sender zone and the active module', () async {
      final _FakeParcelService service = _FakeParcelService(<CoverageListModel?>[_coverage(_areaWiseBody)]);
      final ParcelController controller = ParcelController(parcelServiceInterface: service);

      await controller.loadParcelCoverage(zoneId: 7, moduleId: 3);

      expect(service.calls.single.zoneId, 7);
      expect(service.calls.single.moduleId, 3);
      expect(controller.needsCoverageSelection, isTrue);
    });

    test('a zone that prices by distance draws no picker and blocks nothing', () async {
      final _FakeParcelService service = _FakeParcelService(<CoverageListModel?>[_coverage(_distanceWiseBody)]);
      final ParcelController controller = ParcelController(parcelServiceInterface: service);

      await controller.loadParcelCoverage(zoneId: 7);

      expect(controller.needsCoverageSelection, isFalse);
      expect(controller.isCoverageSelectionMissing, isFalse);
      // The whole point: an unconfigured zone must behave exactly as before.
      expect(controller.canEstimateClientSide, isTrue);
    });

    test('keeps a pick the reloaded list still offers', () async {
      final _FakeParcelService service = _FakeParcelService(<CoverageListModel?>[
        _coverage(_areaWiseBody), _coverage(_areaWiseBody),
      ]);
      final ParcelController controller = ParcelController(parcelServiceInterface: service);

      await controller.loadParcelCoverage(zoneId: 7);
      controller.setCoverageSelection(12);

      // An edited sender address reloads the list for the new zone.
      await controller.loadParcelCoverage(zoneId: 9);

      expect(controller.selectedAreaId, 12);
      expect(controller.selectedCoverageOption?.name, 'Banani');
    });

    test('drops a pick the new zone does not offer', () async {
      final _FakeParcelService service = _FakeParcelService(<CoverageListModel?>[
        _coverage(_areaWiseBody),
        _coverage('{"type":"area_wise","coverage":[{"id":80,"name":"Uttara"}]}'),
      ]);
      final ParcelController controller = ParcelController(parcelServiceInterface: service);

      await controller.loadParcelCoverage(zoneId: 7);
      controller.setCoverageSelection(12);
      await controller.loadParcelCoverage(zoneId: 9);

      // Id 12 belongs to the old zone's areas; keeping it would quote a fee for
      // somewhere else entirely.
      expect(controller.selectedAreaId, isNull);
      expect(controller.isCoverageSelectionMissing, isTrue);
    });

    test('a failed request does not discard the pick', () async {
      final _FakeParcelService service = _FakeParcelService(<CoverageListModel?>[
        _coverage(_areaWiseBody), null,
      ]);
      final ParcelController controller = ParcelController(parcelServiceInterface: service);

      await controller.loadParcelCoverage(zoneId: 7);
      controller.setCoverageSelection(12);
      await controller.loadParcelCoverage(zoneId: 7);

      // Absence of evidence is not evidence against the pick — dropping it here
      // makes a flaky connection look like the app forgetting a choice.
      expect(controller.selectedAreaId, 12);
    });

    test('a failed request does not discard the list either, so the row stays editable', () async {
      final _FakeParcelService service = _FakeParcelService(<CoverageListModel?>[
        _coverage(_areaWiseBody), null,
      ]);
      final ParcelController controller = ParcelController(parcelServiceInterface: service);

      await controller.loadParcelCoverage(zoneId: 7);
      controller.setCoverageSelection(12);

      // The review screen reloads coverage on entry. Overwriting the list with a
      // failed request's null used to hide the Area/ZIP row entirely, so coming
      // back from review left the customer with a pick they could see no trace
      // of and no way to change.
      await controller.loadParcelCoverage(zoneId: 7);

      expect(controller.coverage, isNotNull);
      expect(controller.needsCoverageSelection, isTrue);
      expect(controller.selectedCoverageOption?.name, 'Banani');
    });

    test('a zone that asks for nothing does not discard the pick either', () async {
      final _FakeParcelService service = _FakeParcelService(<CoverageListModel?>[
        _coverage(_areaWiseBody), _coverage(_distanceWiseBody),
      ]);
      final ParcelController controller = ParcelController(parcelServiceInterface: service);

      await controller.loadParcelCoverage(zoneId: 7);
      controller.setCoverageSelection(12);
      await controller.loadParcelCoverage(zoneId: 9);

      // An id posted at a rule that does not price by it costs nothing, so an
      // address edit passing through such a zone must not cost the pick.
      expect(controller.selectedAreaId, 12);
      expect(controller.isCoverageSelectionMissing, isFalse);
    });
  });

  group('ParcelController coverage selection', () {
    test('a zip_code_wise zone records the pick as a zip id, never an area id', () async {
      final _FakeParcelService service = _FakeParcelService(<CoverageListModel?>[_coverage(_zipWiseBody)]);
      final ParcelController controller = ParcelController(parcelServiceInterface: service);
      await controller.loadParcelCoverage(zoneId: 7);

      controller.setCoverageSelection(902);

      expect(controller.selectedZipCodeId, 902);
      expect(controller.selectedAreaId, isNull);
      expect(controller.selectedCoverageOption?.name, '1230');
    });

    test('switching zones clears the other id rather than posting both', () async {
      final _FakeParcelService service = _FakeParcelService(<CoverageListModel?>[
        _coverage(_areaWiseBody), _coverage(_zipWiseBody),
      ]);
      final ParcelController controller = ParcelController(parcelServiceInterface: service);

      await controller.loadParcelCoverage(zoneId: 7);
      controller.setCoverageSelection(12);
      expect(controller.selectedAreaId, 12);

      await controller.loadParcelCoverage(zoneId: 9);
      controller.setCoverageSelection(901);

      expect(controller.selectedZipCodeId, 901);
      expect(controller.selectedAreaId, isNull);
    });

    test('clearCoverageSelection empties both, for a fresh parcel', () async {
      final _FakeParcelService service = _FakeParcelService(<CoverageListModel?>[_coverage(_areaWiseBody)]);
      final ParcelController controller = ParcelController(parcelServiceInterface: service);
      await controller.loadParcelCoverage(zoneId: 7);
      controller.setCoverageSelection(11);

      controller.clearCoverageSelection(notify: false);

      // The controller is a singleton; without this the previous parcel's area
      // arrives pre-selected for a route the customer has not described yet.
      expect(controller.selectedAreaId, isNull);
      expect(controller.selectedZipCodeId, isNull);
      expect(controller.isCoverageSelectionMissing, isTrue);
    });

    test('canEstimateClientSide is false exactly when the zone prices by coverage', () async {
      final _FakeParcelService service = _FakeParcelService(<CoverageListModel?>[
        _coverage(_areaWiseBody), _coverage(_distanceWiseBody),
      ]);
      final ParcelController controller = ParcelController(parcelServiceInterface: service);

      await controller.loadParcelCoverage(zoneId: 7);
      // `distance × per-km` is a different rule's answer here, not a rough one —
      // and the distance still resolves, so nothing else would catch it.
      expect(controller.canEstimateClientSide, isFalse);

      await controller.loadParcelCoverage(zoneId: 9);
      expect(controller.canEstimateClientSide, isTrue);
    });
  });

  group('CheckoutSummaryBodyModel carries the pick to the quote', () {
    CheckoutSummaryBodyModel body({int? areaId, int? zipCodeId}) => CheckoutSummaryBodyModel(
      orderType: 'parcel', orderAmount: 60, parcelCategoryId: 4,
      areaId: areaId, zipCodeId: zipCodeId,
    );

    test('an unset pick sends neither key', () {
      final Map<String, dynamic> json = body().toJson();
      // The endpoint validates presence, so an explicit null fails where an
      // absent key passes.
      expect(json.containsKey('area_id'), isFalse);
      expect(json.containsKey('zip_code_id'), isFalse);
    });

    test('an area pick sends area_id only', () {
      final Map<String, dynamic> json = body(areaId: 12).toJson();
      expect(json['area_id'], 12);
      expect(json.containsKey('zip_code_id'), isFalse);
    });

    test('a zip pick sends zip_code_id only', () {
      final Map<String, dynamic> json = body(zipCodeId: 901).toJson();
      expect(json['zip_code_id'], 901);
      expect(json.containsKey('area_id'), isFalse);
    });

    test('changing the pick changes the signature, so the quote refires', () {
      // `getCheckoutSummary` skips a body whose signature has not moved; if the
      // pick were not in the signature the fee would never update.
      expect(body(areaId: 12).signature, isNot(body(areaId: 13).signature));
      expect(body(areaId: 12).signature, body(areaId: 12).signature);
    });

    test('copyWithCoverage replaces both ids rather than merging them', () {
      final Map<String, dynamic> json = body(areaId: 12).copyWithCoverage(zipCodeId: 901).toJson();
      expect(json['zip_code_id'], 901);
      expect(json.containsKey('area_id'), isFalse);
    });
  });
}
