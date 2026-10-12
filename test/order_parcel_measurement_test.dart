import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_parcel_measurement_model.dart';

/// The `weight` / `dimension` blocks on `GET customer/order/track`, which are
/// optional: a zone that does not price by that tier records nothing.
void main() {
  Map<String, dynamic> trackContent({dynamic weight, dynamic dimension}) => <String, dynamic>{
    'id': 102705,
    'order_type': 'parcel',
    'module_type': 'parcel',
    'parcel_category': <String, dynamic>{
      'id': 8, 'name': 'test', 'description': '432', 'charge': 45.0,
      'parcel_per_km_shipping_charge': 0.0, 'parcel_minimum_shipping_charge': 0.0,
    },
    if (weight != null) 'weight': weight,
    if (dimension != null) 'dimension': dimension,
  };

  const Map<String, dynamic> liveWeight = <String, dynamic>{
    'id': 2, 'name': 'medium weight', 'label': '10 - 20 kg',
    'from_weight': 10.0, 'to_weight': 20.0, 'unit': 'kg',
  };

  const Map<String, dynamic> liveDimension = <String, dynamic>{
    'id': 1, 'name': 'Mehedi dimention', 'label': '50 × 20 × 10 in',
    'max_length': 50.0, 'max_width': 20.0, 'max_height': 10.0, 'unit': 'in',
  };

  test('parses the live payload and renders the server label verbatim', () {
    final OrderModel order = OrderModel.fromJson(trackContent(weight: liveWeight, dimension: liveDimension));

    expect(order.parcelWeight, isNotNull);
    expect(order.parcelWeight!.hasContent, isTrue);
    expect(order.parcelWeight!.displayText, 'medium weight · 10 - 20 kg');

    expect(order.parcelDimension, isNotNull);
    expect(order.parcelDimension!.displayText, 'Mehedi dimention · 50 × 20 × 10 in');
  });

  test('a missing block leaves the field null rather than an empty row', () {
    final OrderModel order = OrderModel.fromJson(trackContent());
    expect(order.parcelWeight, isNull);
    expect(order.parcelDimension, isNull);
    // The rest of the order still parses — the tiers are not load-bearing.
    expect(order.parcelCategory?.name, 'test');
  });

  test('an explicit null block is the same as an absent one', () {
    final OrderModel order = OrderModel.fromJson(<String, dynamic>{
      'id': 1, 'order_type': 'parcel', 'weight': null, 'dimension': null,
    });
    expect(order.parcelWeight, isNull);
    expect(order.parcelDimension, isNull);
  });

  test('only one tier configured renders only that row', () {
    final OrderModel order = OrderModel.fromJson(trackContent(weight: liveWeight));
    expect(order.parcelWeight!.displayText, 'medium weight · 10 - 20 kg');
    expect(order.parcelDimension, isNull);
  });

  test('a block carrying only an id says nothing and is treated as empty', () {
    final OrderParcelMeasurement? weight =
        OrderParcelMeasurement.weightFrom(<String, dynamic>{'id': 9});
    expect(weight, isNotNull);
    expect(weight!.hasContent, isFalse);
  });

  test('no label falls back to the bounds, trimmed and unit-suffixed', () {
    final OrderParcelMeasurement weight = OrderParcelMeasurement.weightFrom(
      <String, dynamic>{'id': 2, 'name': 'medium', 'from_weight': 10.0, 'to_weight': 20.5, 'unit': 'kg'},
    )!;
    expect(weight.displayText, 'medium · 10 - 20.5 kg');

    final OrderParcelMeasurement dimension = OrderParcelMeasurement.dimensionFrom(
      <String, dynamic>{'id': 1, 'max_length': 50.0, 'max_width': 20.0, 'max_height': 10.0, 'unit': 'in'},
    )!;
    expect(dimension.displayText, '50 × 20 × 10 in');
  });

  test('numeric strings and a missing unit do not break the fallback', () {
    final OrderParcelMeasurement weight = OrderParcelMeasurement.weightFrom(
      <String, dynamic>{'id': 2, 'from_weight': '10', 'to_weight': '20'},
    )!;
    expect(weight.displayText, '10 - 20');
  });

  test('a name with no bounds still renders', () {
    final OrderParcelMeasurement weight =
        OrderParcelMeasurement.weightFrom(<String, dynamic>{'id': 2, 'name': 'heavy'})!;
    expect(weight.hasContent, isTrue);
    expect(weight.displayText, 'heavy');
  });

  test('a non-map block is rejected instead of throwing', () {
    expect(OrderParcelMeasurement.weightFrom('10 - 20 kg'), isNull);
    expect(OrderParcelMeasurement.dimensionFrom(<dynamic>[]), isNull);
  });

  test('toJson round-trips the tiers back through fromJson', () {
    final OrderModel order = OrderModel.fromJson(trackContent(weight: liveWeight, dimension: liveDimension));
    final OrderModel again = OrderModel.fromJson(order.toJson());
    expect(again.parcelWeight!.displayText, 'medium weight · 10 - 20 kg');
    expect(again.parcelDimension!.displayText, 'Mehedi dimention · 50 × 20 × 10 in');
  });
}
