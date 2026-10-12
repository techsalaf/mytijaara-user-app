import 'package:sixam_mart/api/json_reader.dart';
import 'package:sixam_mart/api/response_parser.dart';
import 'package:sixam_mart/common/models/measurement_unit_model.dart';

/// One priced tier a parcel is charged by — the weight bands from
/// `GET parcel-weight`, or the size classes from `GET parcel-dimension`.
///
/// Both endpoints answer the same envelope, so both share this model; only the
/// row type differs. Each tier adds its matched row's `charge` flat on top of
/// whatever the zone's active delivery rule priced.
///
/// Three states, and they are **not** interchangeable:
///
/// - `status: false` — this `(zone, module)` does not price by this tier at all.
///   Render no picker.
/// - `status: true` with an empty [data] — the tier is switched on but the
///   platform has no active band configured. An admin problem, not an app one;
///   still render no picker, because there is nothing the customer could satisfy.
/// - `status: true` with rows — the customer picks one.
///
/// An empty list is the answer, not a failure — the same contract
/// `delivery-charge/coverage-list` states, and [requiresSelection] collapses the
/// first two cases the way `CoverageListModel.requiresSelection` does.
///
/// The two switches are independent: a rule may price by weight and not by size,
/// so both endpoints must be called.
class ParcelTierListModel<T> {
  final bool status;

  /// The unit the rows are measured in. Suffix its label beside the numbers —
  /// never convert them.
  final MeasurementUnitModel? unit;

  final List<T> data;

  const ParcelTierListModel({this.status = false, this.unit, this.data = const <Never>[]});

  factory ParcelTierListModel.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) rowFromJson) {
    return ParcelTierListModel<T>(
      status: json['status'] == true || json['status'] == 1,
      unit: MeasurementUnitModel.maybeFrom(json['unit']),
      data: ResponseParser.listOrEmpty(json['data'])
          .whereType<Map<dynamic, dynamic>>()
          .map((Map<dynamic, dynamic> e) => rowFromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  /// Whether the customer has to choose before the fee means anything.
  ///
  /// Guarded on [data] as well as [status]: a switched-on tier with nothing
  /// configured would otherwise render an empty picker the customer cannot
  /// satisfy. A missing pick is not refused by the quote — the engine re-checks
  /// the same switch and charges nothing for the tier — so showing nothing is
  /// the better failure.
  bool get requiresSelection => status && data.isNotEmpty;
}

/// One weight band. [charge] is added flat when the parcel falls in it.
class ParcelWeightModel {
  final int? id;
  final String? name;
  final double? fromWeight;
  final double? toWeight;
  final double? charge;

  const ParcelWeightModel({this.id, this.name, this.fromWeight, this.toWeight, this.charge});

  factory ParcelWeightModel.fromJson(Map<String, dynamic> json) => ParcelWeightModel(
    id: JsonReader.toInt(json['id']),
    name: JsonReader.toStr(json['name']),
    fromWeight: JsonReader.toDouble(json['from_weight']),
    toWeight: JsonReader.toDouble(json['to_weight']),
    charge: JsonReader.toDouble(json['charge']),
  );

  /// The band written out — `0~2 kg`. Empty when the API sent neither bound, so
  /// a row with only a name still renders.
  String range(MeasurementUnitModel? unit) {
    if (fromWeight == null && toWeight == null) return '';
    return '${_trim(fromWeight)}~${_trim(toWeight)}${unit?.suffix ?? ''}';
  }
}

/// One size class. The three bounds are maxima, not a band.
class ParcelDimensionModel {
  final int? id;
  final String? name;
  final double? maxLength;
  final double? maxWidth;
  final double? maxHeight;
  final double? charge;

  const ParcelDimensionModel({this.id, this.name, this.maxLength, this.maxWidth, this.maxHeight, this.charge});

  factory ParcelDimensionModel.fromJson(Map<String, dynamic> json) => ParcelDimensionModel(
    id: JsonReader.toInt(json['id']),
    name: JsonReader.toStr(json['name']),
    maxLength: JsonReader.toDouble(json['max_length']),
    maxWidth: JsonReader.toDouble(json['max_width']),
    maxHeight: JsonReader.toDouble(json['max_height']),
    charge: JsonReader.toDouble(json['charge']),
  );

  /// The class written out — `100 × 50 × 80 cm`. Empty when no bound was sent.
  String bounds(MeasurementUnitModel? unit) {
    if (maxLength == null && maxWidth == null && maxHeight == null) return '';
    return '${_trim(maxLength)} × ${_trim(maxWidth)} × ${_trim(maxHeight)}${unit?.suffix ?? ''}';
  }
}

/// `2.0` reads as `2`, `2.5` stays `2.5` — admins configure whole numbers far
/// more often than not, and `0.0~2.0 kg` looks like a rounding artefact.
String _trim(double? value) {
  if (value == null) return '0';
  return value == value.roundToDouble() ? value.toInt().toString() : value.toString();
}
