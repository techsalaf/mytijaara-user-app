import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/features/review/widgets/rating_widget.dart';

/// `RatingWidget` derived its five progress rows from `ratings`, which **no** store
/// payload sends — `stores/details`, `stores/search` and `stores/get-stores` all omit
/// it (verified live). `percentages` was therefore null and `percentages![0]` threw
/// while building, which is the crash reported from the review screen. On top of that
/// `calculateProgressForEach(null)` returned `[]`, so even a non-null-but-empty list
/// would have RangeError'd on `progressForEach[0]`.
///
/// The widget itself cannot be mounted in a bare test — `Dimensions` reads
/// `Get.context!` in its static initialisers — so this exercises the real computation
/// directly.
void main() {
  test('ratings absent (what the live store payload gives) -> five zeros, no throw', () {
    final List<double> p = RatingWidget.percentagesOf(null);
    expect(p.length, 5, reason: 'the five progress rows index this list directly');
    expect(p, everyElement(0.0));
  });

  test('empty list -> five zeros', () {
    expect(RatingWidget.percentagesOf(<int>[]), <double>[0, 0, 0, 0, 0]);
  });

  test('all zeros -> five zeros, not NaN', () {
    // total == 0 used to make the division 0/0.
    final List<double> p = RatingWidget.percentagesOf(<int>[0, 0, 0, 0, 0]);
    expect(p, <double>[0, 0, 0, 0, 0]);
    expect(p.any((double e) => e.isNaN), isFalse);
  });

  test('a short list is padded to five instead of overflowing', () {
    final List<double> p = RatingWidget.percentagesOf(<int>[3, 1]);
    expect(p.length, 5);
    expect(p[0], 75.0);
    expect(p[1], 25.0);
    expect(p.sublist(2), everyElement(0.0));
  });

  test('a longer list is truncated to five', () {
    expect(RatingWidget.percentagesOf(<int>[1, 1, 1, 1, 1, 1, 1]).length, 5);
  });

  test('a real distribution sums to 100', () {
    // The shape the rental provider endpoint sends: [3,2,1,0,0] over 6 ratings.
    final List<double> p = RatingWidget.percentagesOf(<int>[3, 2, 1, 0, 0]);
    expect(p[0], closeTo(50, 0.01));
    expect(p[1], closeTo(33.33, 0.01));
    expect(p[2], closeTo(16.67, 0.01));
    expect(p[3], 0);
    expect(p[4], 0);
    expect(p.reduce((double a, double b) => a + b), closeTo(100, 0.01));
  });

  test('every element is a usable progress fraction', () {
    for (final List<int>? input in <List<int>?>[null, <int>[], <int>[0,0,0,0,0], <int>[3,2,1,0,0], <int>[9]]) {
      for (final double pct in RatingWidget.percentagesOf(input)) {
        expect(pct.isNaN, isFalse);
        expect(pct, inInclusiveRange(0, 100));
        expect(pct / 100, inInclusiveRange(0, 1), reason: 'LinearProgressIndicator needs 0..1');
      }
    }
  });
}
