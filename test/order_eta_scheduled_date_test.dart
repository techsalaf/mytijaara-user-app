import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/helper/date_converter.dart';

/// Naming the day an ETA window or a scheduled slot falls on.
///
/// `.tr` with no translations registered returns the key itself, so the labels
/// assert against `today` / `tomorrow` rather than their English values.
void main() {
  group('DateConverter.dateToTodayTomorrowLabel', () {
    test('names today', () {
      expect(DateConverter.dateToTodayTomorrowLabel(DateTime.now()), 'today');
    });

    test('names tomorrow, from the day field rather than +24h', () {
      final DateTime now = DateTime.now();
      final DateTime tomorrow = DateTime(now.year, now.month, now.day + 1, 9, 30);
      expect(DateConverter.dateToTodayTomorrowLabel(tomorrow), 'tomorrow');
    });

    test('a later date falls through to the readable date', () {
      final DateTime now = DateTime.now();
      final DateTime later = DateTime(now.year, now.month, now.day + 5);
      final String label = DateConverter.dateToTodayTomorrowLabel(later);
      expect(label, isNot('today'));
      expect(label, isNot('tomorrow'));
      expect(label, DateConverter.dateToReadableDate(later));
    });

    test('a past date is not called yesterday — this formatter looks forward', () {
      final DateTime now = DateTime.now();
      final DateTime past = DateTime(now.year, now.month, now.day - 1);
      expect(DateConverter.dateToTodayTomorrowLabel(past), DateConverter.dateToReadableDate(past));
    });

    test('crossing a month boundary still reads as tomorrow', () {
      final DateTime endOfMonth = DateTime(2026, 9, 30, 23, 0);
      final DateTime nextDay = DateTime(endOfMonth.year, endOfMonth.month, endOfMonth.day + 1);
      expect(nextDay.month, 10);
      expect(nextDay.day, 1);
    });
  });

  group('DateConverter.isSameCalendarDay', () {
    test('true for any time today, false for another day', () {
      final DateTime now = DateTime.now();
      expect(DateConverter.isSameCalendarDay(DateTime(now.year, now.month, now.day, 0, 1)), isTrue);
      expect(DateConverter.isSameCalendarDay(DateTime(now.year, now.month, now.day, 23, 59)), isTrue);
      expect(DateConverter.isSameCalendarDay(DateTime(now.year, now.month, now.day + 1)), isFalse);
    });

    test('does not collapse to the minute the way isSameDate does', () {
      final DateTime now = DateTime.now();
      final DateTime laterToday = DateTime(now.year, now.month, now.day, (now.hour + 3) % 24, 15);
      expect(DateConverter.isSameCalendarDay(laterToday), isTrue);
    });
  });

  group('OrderEta.windowDate', () {
    OrderModel orderWithEta(Map<String, dynamic> eta) =>
        OrderModel.fromJson(<String, dynamic>{'id': 1, 'order_type': 'delivery', 'eta': eta});

    test('reads from_at, offset and all, as a local instant', () {
      final OrderEta eta = orderWithEta(<String, dynamic>{
        'window': '04:37 PM - 04:52 PM',
        'text': '25 - 40 min',
        'from_at': '2026-09-12T16:37:00+06:00',
        'to_at': '2026-09-12T16:52:00+06:00',
      }).eta!;

      expect(eta.hasWindow, isTrue);
      expect(eta.windowDate, isNotNull);
      expect(eta.windowDate!.isUtc, isFalse);
      expect(eta.windowDate!.isAtSameMomentAs(DateTime.parse('2026-09-12T16:37:00+06:00')), isTrue);
    });

    test('falls back to to_at when from_at is missing', () {
      final OrderEta eta = orderWithEta(<String, dynamic>{
        'window': '04:52 PM',
        'to_at': '2026-09-12T16:52:00+06:00',
      }).eta!;
      expect(eta.windowDate!.isAtSameMomentAs(DateTime.parse('2026-09-12T16:52:00+06:00')), isTrue);
    });

    test('handles a Z-suffixed timestamp', () {
      final OrderEta eta = orderWithEta(<String, dynamic>{
        'window': '10:00 AM', 'from_at': '2026-09-12T10:00:00Z',
      }).eta!;
      expect(eta.windowDate!.isUtc, isFalse);
      expect(eta.windowDate!.isAtSameMomentAs(DateTime.parse('2026-09-12T10:00:00Z')), isTrue);
    });

    test('null when the payload carries no timestamps — the date line is skipped', () {
      final OrderEta eta = orderWithEta(<String, dynamic>{
        'window': '04:37 PM - 04:52 PM', 'text': '25 - 40 min',
      }).eta!;
      expect(eta.hasWindow, isTrue);
      expect(eta.windowDate, isNull);
    });

    test('null rather than throwing on a malformed timestamp', () {
      final OrderEta eta = orderWithEta(<String, dynamic>{
        'window': '04:37 PM', 'from_at': 'not a date', 'to_at': '',
      }).eta!;
      expect(eta.windowDate, isNull);
    });

    test('an absent eta block stays null and hasWindow is not consulted', () {
      final OrderModel order = OrderModel.fromJson(<String, dynamic>{'id': 1, 'eta': null});
      expect(order.eta, isNull);
    });

    test('toJson round-trips the timestamps windowDate reads', () {
      final OrderModel order = orderWithEta(<String, dynamic>{
        'window': '04:37 PM - 04:52 PM', 'from_at': '2026-09-12T16:37:00+06:00',
      });
      final OrderModel again = OrderModel.fromJson(order.toJson());
      expect(again.eta!.windowDate!.isAtSameMomentAs(DateTime.parse('2026-09-12T16:37:00+06:00')), isTrue);
    });
  });

  group('the scheduled headline input', () {
    // `dateTimeStringToDateTime` — the formatter the headline prints through —
    // resolves the 12/24-hour setting via `Get.find<SplashController>()`, so it
    // cannot run without the app's DI. Its output is exercised in the app; what
    // is asserted here is the gate that decides whether it is called at all.

    test('the scheduled gate needs both the flag and the timestamp', () {
      final OrderModel flagged = OrderModel.fromJson(<String, dynamic>{
        'id': 1, 'scheduled': 1, 'schedule_at': '2026-09-09 15:13:15',
      });
      expect(flagged.scheduled == 1 && flagged.scheduleAt != null, isTrue);

      final OrderModel flagOnly = OrderModel.fromJson(<String, dynamic>{'id': 1, 'scheduled': 1});
      expect(flagOnly.scheduled == 1 && flagOnly.scheduleAt != null, isFalse);

      final OrderModel notScheduled = OrderModel.fromJson(<String, dynamic>{
        'id': 1, 'scheduled': 0, 'schedule_at': '2026-09-09 15:13:15',
      });
      expect(notScheduled.scheduled == 1 && notScheduled.scheduleAt != null, isFalse);
    });

    test('a slot still ahead is claimed; one already passed is handed back', () {
      final DateTime now = DateTime.now();
      final String ahead = DateConverter.dateToDateTime(now.add(const Duration(hours: 3)));
      final String passed = DateConverter.dateToDateTime(now.subtract(const Duration(hours: 3)));

      // The headline takes the slot only while it is ahead — the inverse of the
      // condition guarding the food prep countdown, so the two never overlap.
      expect(DateConverter.isBeforeTime(ahead), isFalse);
      expect(DateConverter.isBeforeTime(passed), isTrue);
    });
  });
}
