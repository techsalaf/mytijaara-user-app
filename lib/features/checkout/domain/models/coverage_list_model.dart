import 'package:sixam_mart/api/json_reader.dart';
import 'package:sixam_mart/api/response_parser.dart';

/// What the customer must choose from before a delivery fee can be quoted, for
/// one `(zone, module)` pair.
///
/// From `GET delivery-charge/coverage-list`. [coverage] is **deliberately empty**
/// for `distance_wise` and `fixed_amount` — there is nothing to pick, so the
/// client draws no picker. An empty list is the answer, not a missing one.
///
/// The list is not narrowed to entries the admin has priced (an unpriced one is
/// charged the rule's minimum), so a customer never finds their area missing.
class CoverageListModel {
  /// `distance_wise`, `fixed_amount`, `area_wise`, `zip_code_wise`, or null when
  /// no rule is active for this `(zone, module)` — the zone's pivot pricing then
  /// applies and, as with the whole-zone types, nothing needs picking.
  final String? type;
  final List<CoverageOption> coverage;

  const CoverageListModel({this.type, this.coverage = const <CoverageOption>[]});

  static const String typeAreaWise = 'area_wise';
  static const String typeZipCodeWise = 'zip_code_wise';

  factory CoverageListModel.fromJson(Map<String, dynamic> json) => CoverageListModel(
    type: JsonReader.toStr(json['type']),
    coverage: ResponseParser.listOrEmpty(json['coverage'])
        .whereType<Map<dynamic, dynamic>>()
        .map((Map<dynamic, dynamic> e) => CoverageOption.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
  );

  /// Whether the customer has to choose before the quote means anything.
  ///
  /// Guarded on [coverage] as well as [type]: an area-wise rule with no options
  /// configured would otherwise render an empty picker the customer cannot
  /// satisfy. A missing pick is not refused by the quote — it falls back to the
  /// rule's own minimum — so showing nothing is the better failure.
  bool get requiresSelection =>
      (type == typeAreaWise || type == typeZipCodeWise) && coverage.isNotEmpty;

  /// Which key the pick is posted back under: `zip_code_id` or `area_id`.
  bool get isZipCode => type == typeZipCodeWise;
}

/// One pickable area or ZIP code. [name] carries the area's name, or the code
/// itself for `zip_code_wise`, so one list shape renders whichever is active.
class CoverageOption {
  final int? id;
  final String? name;

  const CoverageOption({this.id, this.name});

  factory CoverageOption.fromJson(Map<String, dynamic> json) => CoverageOption(
    id: JsonReader.toInt(json['id']),
    name: JsonReader.toStr(json['name']),
  );
}
