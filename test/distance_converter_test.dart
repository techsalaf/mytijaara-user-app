import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/helper/distance_converter.dart';

/// Rendering a distance the *client* measured in the platform's configured unit.
///
/// `CheckoutController.getDistanceInKM` returns kilometres whatever
/// `distance_unit` is set to — the setting governs the unit rates are quoted in,
/// not the unit this value arrives in. So a screen showing it has to convert as
/// well as suffix; a `mi` label on an unconverted value overstates the distance
/// by about 60%.
///
/// Distances the API sends (`Store.distanceLabel`, the rental trip distance) are
/// a different case entirely — those already carry the configured unit and are
/// rendered as sent.
void main() {
  group('convert', () {
    test('kilometres are left alone', () {
      expect(DistanceConverter.convert(12.5, 'km'), 12.5);
    });

    test('miles are converted, not just relabelled', () {
      // 10 km is about 6.21 miles. Rendering "10.00 mi" would be the bug.
      expect(DistanceConverter.convert(10, 'mi'), closeTo(6.2137, 0.0001));
    });

    test('uses the exact international mile', () {
      expect(DistanceConverter.convert(1.609344, 'mi'), closeTo(1, 1e-12));
    });

    test('matching is case- and whitespace-insensitive', () {
      for (final String unit in <String>['mi', 'MI', ' Mi ', 'mile', 'Miles']) {
        expect(DistanceConverter.convert(10, unit), closeTo(6.2137, 0.0001), reason: unit);
      }
    });

    test('an absent or unrecognised unit leaves the value in kilometres', () {
      // Degrading to the value the app actually holds beats silently scaling it
      // by a factor nobody chose.
      for (final String? unit in <String?>[null, '', '   ', 'furlong', 'nmi']) {
        expect(DistanceConverter.convert(10, unit), 10, reason: unit ?? 'null');
      }
    });

    test('zero converts to zero', () {
      expect(DistanceConverter.convert(0, 'mi'), 0);
    });
  });

  group('format', () {
    test('suffixes and rounds to two decimals by default', () {
      expect(DistanceConverter.format(12.3456, 'km', suffix: 'km'), '12.35 km');
    });

    test('converts before rounding, so the rounding is of the right number', () {
      expect(DistanceConverter.format(10, 'mi', suffix: 'mi'), '6.21 mi');
    });

    test('honours a requested precision', () {
      expect(DistanceConverter.format(10, 'mi', suffix: 'mi', decimals: 3), '6.214 mi');
      expect(DistanceConverter.format(10, 'km', suffix: 'km', decimals: 0), '10 km');
    });

    test('the suffix is independent of the unit matched on', () {
      // `distance_unit_label` is what the customer reads; `unit` is what decides
      // the arithmetic. A platform labelling miles "Miles" still converts.
      expect(DistanceConverter.format(10, 'mi', suffix: 'Miles'), '6.21 Miles');
    });
  });

  group('labelFromKilometres, with no SplashController registered', () {
    test('returns null for a distance that is not resolved yet', () {
      // `getDistanceInKM` parks -1 while the call is in flight; the summary shows
      // "calculating" for it rather than a zero, which reads as "next door".
      expect(DistanceConverter.labelFromKilometres(null), isNull);
      expect(DistanceConverter.labelFromKilometres(-1), isNull);
    });

    test('falls back to unconverted kilometres rather than throwing', () {
      // No container in a unit test, and none during early startup either — the
      // fallback unit and the unit of the raw value are both km, so they agree.
      expect(DistanceConverter.labelFromKilometres(12.345), '12.35 km');
      expect(DistanceConverter.unitSuffix, 'km');
    });

    test('zero is a real distance and renders as one', () {
      expect(DistanceConverter.labelFromKilometres(0), '0.00 km');
    });
  });
}
