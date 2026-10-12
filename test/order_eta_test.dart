import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';

/// ETA on `customer/order/track` — `content.eta`.
///
/// The platform only produces an estimate where an admin configured one for the
/// order's (zone, module) pair, and only for an unfinished `delivery` order. So
/// `null` is a normal answer and the UI must render nothing at all — every
/// assertion about absence below is a real requirement, not defensiveness.
void main() {
  OrderModel parseTracked(String content) {
    final dynamic body = ApiClient.unwrapEnvelope(jsonDecode(
      '{"identical_code":"default_200","message":"Successfully fetched",'
      '"content":$content,"errors":[]}',
    ), 200);
    return OrderModel.fromJson(body as Map<String, dynamic>);
  }

  group('the live track payload', () {
    // Trimmed from the guide's captured response for order 100183.
    const String tracked = '''
    {"id":100183,"user_id":46,"order_status":"pending","order_amount":774.1,
     "min_delivery_time":120,"max_delivery_time":180,
     "eta":{"min":0,"max":5,"unit":"min","text":"Any minute now","overdue":true,
       "from":"04:02 PM","to":"04:07 PM","window":"04:02 PM - 04:07 PM",
       "from_at":"2026-09-05T16:02:32+06:00","to_at":"2026-09-05T16:07:32+06:00",
       "timezone":"Asia/Dhaka","stage":"before_processing"}}
    ''';

    test('every field of the eta object is read', () {
      final OrderEta eta = parseTracked(tracked).eta!;
      expect(eta.min, 0);
      expect(eta.max, 5);
      expect(eta.unit, 'min');
      expect(eta.text, 'Any minute now');
      expect(eta.overdue, isTrue);
      expect(eta.from, '04:02 PM');
      expect(eta.to, '04:07 PM');
      expect(eta.window, '04:02 PM - 04:07 PM');
      expect(eta.fromAt, '2026-09-05T16:02:32+06:00');
      expect(eta.toAt, '2026-09-05T16:07:32+06:00');
      expect(eta.timezone, 'Asia/Dhaka');
      expect(eta.stage, 'before_processing');
    });

    test('the store window is not mistaken for the eta', () {
      // min_delivery_time / max_delivery_time are the store's own advertised
      // window (120-180 here) and sit right next to the eta; they are unrelated,
      // and the eta must come only from the `eta` object.
      final OrderEta eta = parseTracked(tracked).eta!;
      expect(eta.min, 0);
      expect(eta.max, 5);
      expect(eta.max, isNot(180));
    });
  });

  group('null is a real answer', () {
    test('no eta key at all', () {
      expect(parseTracked('{"id":1,"order_status":"pending"}').eta, isNull);
    });

    test('an explicit null eta', () {
      // The guide's example: same zone, different module, no configuration.
      expect(parseTracked('{"id":100065,"order_status":"picked_up","eta":null}').eta, isNull);
    });

    test('a non-object eta does not throw', () {
      expect(parseTracked('{"id":1,"eta":"soon"}').eta, isNull);
      expect(parseTracked('{"id":1,"eta":[]}').eta, isNull);
    });
  });

  group('hasWindow decides whether anything renders', () {
    test('true when there is a label or a clock range', () {
      expect(parseTracked('{"id":1,"eta":{"text":"25 - 40 min"}}').eta!.hasWindow, isTrue);
      expect(parseTracked('{"id":1,"eta":{"window":"04:30 PM - 04:45 PM"}}').eta!.hasWindow, isTrue);
    });

    test('false for an empty or blank object — an empty row is worse than none', () {
      expect(parseTracked('{"id":1,"eta":{}}').eta!.hasWindow, isFalse);
      expect(parseTracked('{"id":1,"eta":{"text":"","window":"  "}}').eta!.hasWindow, isFalse);
      expect(parseTracked('{"id":1,"eta":{"min":25,"max":40}}').eta!.hasWindow, isFalse,
          reason: 'numbers alone are not printable — text is the scaled label');
    });
  });

  group('the states from the guide', () {
    test('A — store fallback, scaled to hours', () {
      final OrderEta eta = parseTracked(
        '{"id":1,"eta":{"min":135,"max":195,"unit":"min","text":"2 - 3 hr","overdue":false,'
        '"window":"06:20 PM - 07:20 PM","stage":"before_processing"}}',
      ).eta!;
      // min/max stay minutes even when text reads hours — display text, not them.
      expect(eta.min, 135);
      expect(eta.max, 195);
      expect(eta.text, '2 - 3 hr');
      expect(eta.overdue, isFalse);
    });

    test('C — the store reported its own prep time, so stage flips', () {
      final OrderEta eta = parseTracked(
        '{"id":1,"eta":{"min":40,"max":55,"text":"40 - 55 min","overdue":false,"stage":"processing"}}',
      ).eta!;
      expect(eta.stage, 'processing');
      expect(eta.overdue, isFalse);
    });

    test('D — overdue carries the wording, not numbers', () {
      final OrderEta eta = parseTracked(
        '{"id":1,"eta":{"min":0,"max":5,"text":"Any minute now","overdue":true}}',
      ).eta!;
      expect(eta.overdue, isTrue);
      expect(eta.text, 'Any minute now');
    });

    test('a missing overdue flag is treated as not overdue', () {
      expect(parseTracked('{"id":1,"eta":{"text":"25 - 40 min"}}').eta!.overdue, isFalse);
    });
  });

  test('round-trips through toJson', () {
    final OrderEta eta = parseTracked(
      '{"id":1,"eta":{"min":25,"max":40,"unit":"min","text":"25 - 40 min","overdue":false,'
      '"window":"04:30 PM - 04:45 PM","from_at":"2026-09-05T16:30:00+06:00","stage":"processing"}}',
    ).eta!;
    final Map<String, dynamic> json = eta.toJson();
    expect(json['text'], '25 - 40 min');
    expect(json['from_at'], '2026-09-05T16:30:00+06:00');
    expect(OrderEta.fromJson(json).window, '04:30 PM - 04:45 PM');
  });

  group('which value the status card shows', () {
    // Mirrors _OrderEtaLine: the clock range answers "when will it arrive"
    // directly; a duration makes the customer do the arithmetic. `text` takes
    // over only when there is no window, or when the window has already passed.
    String labelFor(OrderEta eta) {
      final String window = eta.window?.trim() ?? '';
      final String text = eta.text?.trim() ?? '';
      return (window.isNotEmpty && !(eta.overdue ?? false)) ? window : text;
    }

    test('the window is preferred over the duration', () {
      final OrderEta eta = parseTracked(
        '{"id":1,"eta":{"min":25,"max":40,"text":"25 - 40 min","overdue":false,'
        '"window":"04:30 PM - 04:45 PM"}}',
      ).eta!;
      expect(labelFor(eta), '04:30 PM - 04:45 PM');
      expect(labelFor(eta), isNot('25 - 40 min'));
    });

    test('an overdue estimate uses the wording, not the stale window', () {
      // The guide's state D: the window has passed, so showing "04:02 PM -
      // 04:07 PM" would be worse than useless.
      final OrderEta eta = parseTracked(
        '{"id":1,"eta":{"min":0,"max":5,"text":"Any minute now","overdue":true,'
        '"window":"04:02 PM - 04:07 PM"}}',
      ).eta!;
      expect(labelFor(eta), 'Any minute now');
    });

    test('falls back to the duration when there is no window', () {
      expect(labelFor(parseTracked('{"id":1,"eta":{"text":"2 - 3 hr"}}').eta!), '2 - 3 hr');
    });

    test('a window with no duration is still shown', () {
      expect(
        labelFor(parseTracked('{"id":1,"eta":{"window":"06:20 PM - 07:20 PM"}}').eta!),
        '06:20 PM - 07:20 PM',
      );
    });

    test('a collapsed window — both ends the same — is shown as sent', () {
      expect(labelFor(parseTracked('{"id":1,"eta":{"window":"04:37 PM"}}').eta!), '04:37 PM');
    });
  });
}
