import 'package:sixam_mart/api/json_reader.dart';

class MeasurementUnitModel {
  /// `distance`, `weight` or `dimension`.
  final String? type;

  /// The configured enum — `km` `mi` `kg` `lb` `cm` `in`. **Match on this.**
  final String? unit;

  final String? label;

  /// Translated full name, e.g. "Kilogram".
  final String? name;

  /// Every value the setting accepts.
  final List<String> supported;

  const MeasurementUnitModel({this.type, this.unit, this.label, this.name, this.supported = const <String>[]});

  factory MeasurementUnitModel.fromJson(Map<String, dynamic> json) => MeasurementUnitModel(
    type: JsonReader.toStr(json['type']),
    unit: JsonReader.toStr(json['unit']),
    label: JsonReader.toStr(json['label']),
    name: JsonReader.toStr(json['name']),
    supported: JsonReader.toStringList(json['supported']) ?? const <String>[],
  );

  static MeasurementUnitModel? maybeFrom(dynamic json) {
    if (json is! Map) return null;
    return MeasurementUnitModel.fromJson(Map<String, dynamic>.from(json));
  }

  String get suffix => (label != null && label!.isNotEmpty) ? ' $label' : '';
}
