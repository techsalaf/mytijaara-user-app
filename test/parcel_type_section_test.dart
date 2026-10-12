import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_parcel_measurement_model.dart';
import 'package:sixam_mart/features/parcel/domain/models/parcel_category_model.dart';
import 'package:sixam_mart/features/order/widgets/order_details_info_widgets/parcel_type_section.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  const Map<String, dynamic> weightData = <String, dynamic>{
    'id': 2,
    'name': 'medium weight',
    'label': '10 - 20 kg',
  };

  const Map<String, dynamic> dimensionData = <String, dynamic>{
    'id': 1,
    'name': 'box size',
    'label': '50 × 20 × 10 in',
  };

  testWidgets('renders both dimension and weight in RichText', (WidgetTester tester) async {
    final order = OrderModel(
      parcelCategory: ParcelCategoryModel(id: 1, name: 'Documents', description: 'desc'),
      parcelWeight: OrderParcelMeasurement.weightFrom(weightData),
      parcelDimension: OrderParcelMeasurement.dimensionFrom(dimensionData),
    );

    await tester.pumpWidget(GetMaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ParcelTypeSection(order: order),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final richTextFinder = find.byType(RichText);
    expect(richTextFinder, findsWidgets);

    final richTexts = tester.widgetList<RichText>(richTextFinder);
    final measurementRichText = richTexts.firstWhere(
      (r) => r.text.toPlainText().contains('box size · 50 × 20 × 10 in'),
    );

    expect(measurementRichText.text.toPlainText(), 'box size · 50 × 20 × 10 in (medium weight · 10 - 20 kg)');
  });

  testWidgets('renders only dimension when weight is absent', (WidgetTester tester) async {
    final order = OrderModel(
      parcelCategory: ParcelCategoryModel(id: 1, name: 'Documents', description: 'desc'),
      parcelDimension: OrderParcelMeasurement.dimensionFrom(dimensionData),
    );

    await tester.pumpWidget(GetMaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ParcelTypeSection(order: order),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final richTextFinder = find.byType(RichText);
    expect(richTextFinder, findsWidgets);

    final richTexts = tester.widgetList<RichText>(richTextFinder);
    final measurementRichText = richTexts.firstWhere(
      (r) => r.text.toPlainText().contains('box size · 50 × 20 × 10 in'),
    );

    expect(measurementRichText.text.toPlainText(), 'box size · 50 × 20 × 10 in');
  });

  testWidgets('renders only weight when dimension is absent', (WidgetTester tester) async {
    final order = OrderModel(
      parcelCategory: ParcelCategoryModel(id: 1, name: 'Documents', description: 'desc'),
      parcelWeight: OrderParcelMeasurement.weightFrom(weightData),
    );

    await tester.pumpWidget(GetMaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ParcelTypeSection(order: order),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final richTextFinder = find.byType(RichText);
    expect(richTextFinder, findsWidgets);

    final richTexts = tester.widgetList<RichText>(richTextFinder);
    final measurementRichText = richTexts.firstWhere(
      (r) => r.text.toPlainText().contains('medium weight · 10 - 20 kg'),
    );

    expect(measurementRichText.text.toPlainText(), 'medium weight · 10 - 20 kg');
  });

  testWidgets('renders description when weight and dimension are absent', (WidgetTester tester) async {
    final order = OrderModel(
      parcelCategory: ParcelCategoryModel(id: 1, name: 'Documents', description: 'Important docs'),
    );

    await tester.pumpWidget(GetMaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ParcelTypeSection(order: order),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Important docs'), findsOneWidget);
  });
}
