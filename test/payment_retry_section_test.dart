import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/order/widgets/order_details_info_widgets/payment_retry_section.dart';

/// The failed-payment retry block restored on the order details page, ported from
/// the pre-4.2 `order_info_widget.dart:805-921`.
///
/// These pin the three-way branch, because every rule here is a money decision:
/// showing the buttons on an offline deposit charges the customer twice, and
/// missing the unpaid case leaves them with no way to pay at all.
void main() {
  OrderModel order({
    String? paymentMethod,
    String? paymentStatus,
    String? orderStatus,
    List<Payments>? payments,
    bool withOfflineRecord = false,
  }) {
    return OrderModel.fromJson(<String, dynamic>{
      'id': 101698,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'order_status': orderStatus,
      'order_amount': 1079.64,
      if (payments != null) 'payments': payments.map((Payments p) => p.toJson()).toList(),
      if (withOfflineRecord) 'offline_payment': <String, dynamic>{
        'data': <String, dynamic>{'status': 'pending', 'method_name': 'Bank'},
      },
    });
  }

  Payments leg(String method, String status) =>
      Payments(paymentMethod: method, paymentStatus: status, amount: 500);

  /// The section renders `SizedBox` when no branch applies; `offersRetry` is the
  /// predicate `build` gates on.
  bool offersRetry(OrderModel o) => PaymentRetrySection(order: o).offersRetry;

  group('branch 3 — the general failed/unpaid case', () {
    test('an unpaid digital payment offers retry, at pending and at failed', () {
      expect(offersRetry(order(paymentMethod: 'digital_payment', paymentStatus: 'unpaid', orderStatus: 'pending')), isTrue);
      expect(offersRetry(order(paymentMethod: 'digital_payment', paymentStatus: 'unpaid', orderStatus: 'failed')), isTrue);
    });

    test('a paid order never offers retry', () {
      expect(offersRetry(order(paymentMethod: 'digital_payment', paymentStatus: 'paid', orderStatus: 'confirmed')), isFalse);
    });

    test('a cancelled order never offers retry', () {
      expect(offersRetry(order(paymentMethod: 'digital_payment', paymentStatus: 'unpaid', orderStatus: 'canceled')), isFalse);
    });

    test('cash on delivery and wallet settle elsewhere — nothing to retry', () {
      expect(offersRetry(order(paymentMethod: 'cash_on_delivery', paymentStatus: 'unpaid', orderStatus: 'pending')), isFalse);
      expect(offersRetry(order(paymentMethod: 'wallet', paymentStatus: 'unpaid', orderStatus: 'pending')), isFalse);
    });
  });

  group('branch 2 — offline payments must never be retryable', () {
    test('an offline payment awaiting verification is excluded', () {
      // Sits at `unpaid` until the store verifies the deposit; paying again
      // would charge a customer who has already handed over cash.
      expect(offersRetry(order(paymentMethod: 'offline_payment', paymentStatus: 'unpaid', orderStatus: 'failed')), isFalse);
    });

    test('the live fixture (order 101698) takes the offline branch', () {
      final String raw = File('test/fixtures/live/order_track.json').readAsStringSync();
      final dynamic body = ApiClient.unwrapEnvelope(jsonDecode(raw), 200);
      final OrderModel live = OrderModel.fromJson(
        (body is List ? body.first : body) as Map<String, dynamic>,
      );

      expect(live.paymentMethod, 'offline_payment');
      expect(live.paymentStatus, 'unpaid');
      expect(live.payments, isEmpty, reason: 'the RangeError the original would have thrown');
      expect(offersRetry(live), isFalse);
    });

    test('a partial payment whose due leg is an offline deposit is excluded', () {
      // The one rule not carried over verbatim. The partial branch runs before
      // the offline branch, so without this a bank deposit under verification
      // would reach the retry buttons.
      expect(
        offersRetry(order(
          paymentMethod: 'partial_payment', paymentStatus: 'unpaid', orderStatus: 'failed',
          payments: <Payments>[leg('wallet', 'paid'), leg('offline_payment', 'unpaid')],
        )),
        isFalse,
      );
    });

    test('a partial payment with an unpaid DIGITAL leg still offers retry', () {
      // Faithful to the original branch order: the partial branch wins even when
      // an offline record is attached, because a digital leg is genuinely
      // retryable online.
      expect(
        offersRetry(order(
          paymentMethod: 'partial_payment', paymentStatus: 'unpaid', orderStatus: 'failed',
          payments: <Payments>[leg('wallet', 'paid'), leg('digital_payment', 'unpaid')],
          withOfflineRecord: true,
        )),
        isTrue,
      );
    });
  });

  group('branch 1 — partial payments', () {
    test('an unpaid second leg offers retry', () {
      expect(
        offersRetry(order(
          paymentMethod: 'partial_payment', paymentStatus: 'partial_paid', orderStatus: 'pending',
          payments: <Payments>[leg('wallet', 'paid'), leg('digital_payment', 'unpaid')],
        )),
        isTrue,
      );
    });

    test('a second leg due on delivery has nothing to pay online', () {
      expect(
        offersRetry(order(
          paymentMethod: 'partial_payment', paymentStatus: 'partial_paid', orderStatus: 'pending',
          payments: <Payments>[leg('wallet', 'paid'), leg('cash_on_delivery', 'unpaid')],
        )),
        isFalse,
      );
    });

    test('a fully paid partial payment offers nothing', () {
      expect(
        offersRetry(order(
          paymentMethod: 'partial_payment', paymentStatus: 'paid', orderStatus: 'confirmed',
          payments: <Payments>[leg('wallet', 'paid'), leg('digital_payment', 'paid')],
        )),
        isFalse,
      );
    });

    test('a missing second leg is a missed branch, not a RangeError', () {
      // The original indexed payments[1] unconditionally in five places.
      expect(
        () => offersRetry(order(
          paymentMethod: 'partial_payment', paymentStatus: 'unpaid', orderStatus: 'failed',
          payments: <Payments>[leg('wallet', 'paid')],
        )),
        returnsNormally,
      );
      expect(
        offersRetry(order(
          paymentMethod: 'partial_payment', paymentStatus: 'unpaid', orderStatus: 'failed',
          payments: <Payments>[],
        )),
        isFalse,
      );
    });
  });
}
