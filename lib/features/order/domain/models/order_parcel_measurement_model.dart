import 'package:sixam_mart/api/json_reader.dart';

/// One measurement band recorded against a parcel order — the weight band or the
/// size class — as `GET customer/order/track` reports it.
///
/// Both blocks answer the same shape (`id`, `name`, `label`, `unit`) and differ
/// only in the numeric bounds they carry, so one model covers both. Deliberately
/// separate from `ParcelWeightModel` / `ParcelDimensionModel`: those are the
/// *pickable* rows from `parcel-weight` / `parcel-dimension`, which carry a
/// `charge` and take their unit from the list envelope rather than the row.
///
/// **Both blocks are nullable.** A zone that does not price by weight, or by
/// size, records nothing — and an order placed before the tiers were configured
/// has neither. Absent is the answer, not a failure: [maybeFrom] returns null and
/// the caller renders no row.
///
/// The API sends a display-ready [label] (`10 - 20 kg`, `50 × 20 × 10 in`). Use
/// it as sent; [fallbackLabel] only composes one from the bounds for a payload
/// that omitted it. **Never convert the numbers** — a unit switch changes what a
/// stored band means, not its value, exactly as `MeasurementUnitModel` states.
class OrderParcelMeasurement {
  final int? id;

  /// The admin's name for the band, e.g. `medium weight`.
  final String? name;

  /// The band written out, e.g. `10 - 20 kg`. Server-formatted and already
  /// carrying its unit, so it is rendered verbatim.
  final String? label;

  /// The configured unit enum — `kg`, `lb`, `cm`, `in`. Only used to build
  /// [fallbackLabel]; [label] already includes it.
  final String? unit;

  const OrderParcelMeasurement({this.id, this.name, this.label, this.unit});

  /// The weight band at `json`, or null when the order has none.
  static OrderParcelMeasurement? weightFrom(dynamic json) {
    if (json is! Map) return null;
    final Map<String, dynamic> map = Map<String, dynamic>.from(json);
    return OrderParcelMeasurement(
      id: JsonReader.toInt(map['id']),
      name: JsonReader.toStr(map['name']),
      label: JsonReader.toStr(map['label']) ?? _weightFallback(map),
      unit: JsonReader.toStr(map['unit']),
    );
  }

  /// The size class at `json`, or null when the order has none.
  static OrderParcelMeasurement? dimensionFrom(dynamic json) {
    if (json is! Map) return null;
    final Map<String, dynamic> map = Map<String, dynamic>.from(json);
    return OrderParcelMeasurement(
      id: JsonReader.toInt(map['id']),
      name: JsonReader.toStr(map['name']),
      label: JsonReader.toStr(map['label']) ?? _dimensionFallback(map),
      unit: JsonReader.toStr(map['unit']),
    );
  }

  /// Whether there is anything worth drawing a row for. A block carrying only an
  /// id says nothing to the customer, so it is treated as absent.
  bool get hasContent => (name?.isNotEmpty ?? false) || (label?.isNotEmpty ?? false);

  /// What the row shows: the band's name with its range beside it, or whichever
  /// of the two the payload actually carried.
  String get displayText {
    final String safeName = name ?? '';
    final String safeLabel = label ?? '';
    if (safeName.isEmpty) return safeLabel;
    if (safeLabel.isEmpty) return safeName;
    return '$safeName · $safeLabel';
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id, 'name': name, 'label': label, 'unit': unit,
  };

  /// `10 - 20 kg` from the raw bounds, for a payload that sent no `label`.
  static String? _weightFallback(Map<String, dynamic> json) {
    final double? from = JsonReader.toDouble(json['from_weight']);
    final double? to = JsonReader.toDouble(json['to_weight']);
    if (from == null && to == null) return null;
    return '${_trim(from)} - ${_trim(to)}${_suffix(json['unit'])}';
  }

  /// `50 × 20 × 10 in` from the raw bounds, for a payload that sent no `label`.
  static String? _dimensionFallback(Map<String, dynamic> json) {
    final double? length = JsonReader.toDouble(json['max_length']);
    final double? width = JsonReader.toDouble(json['max_width']);
    final double? height = JsonReader.toDouble(json['max_height']);
    if (length == null && width == null && height == null) return null;
    return '${_trim(length)} × ${_trim(width)} × ${_trim(height)}${_suffix(json['unit'])}';
  }

  static String _suffix(dynamic unit) {
    final String? value = JsonReader.toStr(unit);
    return (value != null && value.isNotEmpty) ? ' $value' : '';
  }

  /// `2.0` reads as `2`, `2.5` stays `2.5` — admins configure whole numbers far
  /// more often than not, and `10.0 - 20.0 kg` looks like a rounding artefact.
  static String _trim(double? value) {
    if (value == null) return '0';
    return value == value.roundToDouble() ? value.toInt().toString() : value.toString();
  }
}
