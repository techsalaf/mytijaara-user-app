import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/features/cart/domain/models/all_carts_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';

/// `distance_label` is the API's pre-formatted distance, already in the
/// platform's configured unit. It exists because the app's own `'$km km'`
/// formatting is simply wrong when the platform is set to miles.
void main() {
  Store storeFrom(Map<String, dynamic> extra) =>
      Store.fromJson(<String, dynamic>{'id': 1, 'name': 'Test Store', ...extra});

  group('Store.distanceLabel', () {
    test('parses the live payload, unit and all', () {
      // Verbatim shape from stores/latest on the dev backend.
      final Store store = storeFrom(<String, dynamic>{
        'distance': 5087471.985857802,
        'distance_km': 5087.47,
        'distance_mi': 3161.21,
        'distance_label': '3161.21 mi',
      });
      expect(store.distanceLabel, '3161.21 mi');
      // The numeric fields are untouched, so every fallback still works.
      expect(store.distanceKm, 5087.47);
      expect(store.distance, 5087471.985857802);
    });

    test('accepts the misspelled distance_lavel too', () {
      expect(storeFrom(<String, dynamic>{'distance_lavel': '2.5 km'}).distanceLabel, '2.5 km');
    });

    test('the correctly spelled key wins when both are present', () {
      final Store store = storeFrom(<String, dynamic>{
        'distance_label': '3161.21 mi',
        'distance_lavel': 'wrong',
      });
      expect(store.distanceLabel, '3161.21 mi');
    });

    test('is null when the backend does not send it — every call site falls back', () {
      final Store store = storeFrom(<String, dynamic>{'distance': 16915.07, 'distance_km': 16.92});
      expect(store.distanceLabel, isNull);
      expect(store.distanceKm, 16.92);
    });

    test('a blank or whitespace label normalises to null, not an empty row', () {
      expect(storeFrom(<String, dynamic>{'distance_label': ''}).distanceLabel, isNull);
      expect(storeFrom(<String, dynamic>{'distance_label': '   '}).distanceLabel, isNull);
      expect(storeFrom(<String, dynamic>{'distance_label': null}).distanceLabel, isNull);
    });

    test('a non-string value is coerced rather than throwing', () {
      expect(storeFrom(<String, dynamic>{'distance_label': 12}).distanceLabel, '12');
    });

    test('is trimmed', () {
      expect(storeFrom(<String, dynamic>{'distance_label': '  2.5 km  '}).distanceLabel, '2.5 km');
    });

    test('survives a toJson round trip', () {
      final Store store = storeFrom(<String, dynamic>{'distance_label': '3161.21 mi', 'distance_km': 5087.47});
      final Store again = Store.fromJson(store.toJson());
      expect(again.distanceLabel, '3161.21 mi');
      expect(again.distanceKm, 5087.47);
    });

    test('an unrelated store payload still parses with no distance keys at all', () {
      final Store store = storeFrom(<String, dynamic>{});
      expect(store.distanceLabel, isNull);
      expect(store.distanceKm, isNull);
      // `distance` defaults to 0 exactly as it always has.
      expect(store.distance, 0);
    });
  });

  group('AllCartsStore.distanceLabel', () {
    test('parses both spellings and normalises blanks', () {
      expect(AllCartsStore.fromJson(<String, dynamic>{'distance_label': '2.5 km'}).distanceLabel, '2.5 km');
      expect(AllCartsStore.fromJson(<String, dynamic>{'distance_lavel': '2.5 km'}).distanceLabel, '2.5 km');
      expect(AllCartsStore.fromJson(<String, dynamic>{'distance_label': ''}).distanceLabel, isNull);
      expect(AllCartsStore.fromJson(<String, dynamic>{}).distanceLabel, isNull);
    });

    test('leaves distance_km alone, so the cart row keeps its fallback', () {
      final AllCartsStore store = AllCartsStore.fromJson(<String, dynamic>{'distance_km': 16.92});
      expect(store.distanceLabel, isNull);
      expect(store.distanceKm, 16.92);
    });
  });
}
