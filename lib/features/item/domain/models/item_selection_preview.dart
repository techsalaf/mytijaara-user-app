import 'package:sixam_mart/api/json_reader.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';

class ItemSelectionPreview {
  final List<OrderVariation> variations;
  final List<int> addOnIds;
  final List<int> addOnQtys;
  const ItemSelectionPreview({this.variations = const <OrderVariation>[], this.addOnIds = const <int>[], this.addOnQtys = const <int>[]});

  Map<String, dynamic> toJson() => {
    'variations': variations.map((v) => v.toJson()).toList(),
    'add_on_ids': addOnIds,
    'add_on_qtys': addOnQtys,
  };

  factory ItemSelectionPreview.fromJson(Map<String, dynamic> json) {
    final dynamic rawVariations = json['variations'];
    return ItemSelectionPreview(
      variations: rawVariations is List
          ? rawVariations.whereType<Map>().map((row) => OrderVariation.fromJson(Map<String, dynamic>.from(row))).toList()
          : const <OrderVariation>[],
      addOnIds: JsonReader.toIntList(json['add_on_ids']),
      addOnQtys: JsonReader.toIntList(json['add_on_qtys']),
    );
  }
}
