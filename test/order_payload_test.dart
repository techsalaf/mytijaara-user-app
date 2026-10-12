import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/api/response_parser.dart';
import 'package:sixam_mart/common/models/ongoing_order_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/payment_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_cancellation_body.dart';
import 'package:sixam_mart/features/order/domain/models/order_details_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/order/domain/models/refund_model.dart';
import 'package:sixam_mart/features/order/domain/models/reorder_response_model.dart';

dynamic body(String fixture) {
  final String raw = File('test/fixtures/live/$fixture.json').readAsStringSync();
  return ApiClient.unwrapEnvelope(jsonDecode(raw), 200);
}

void main() {
  group('order list — GET customer/order/list', () {
    test('rows parse from `data` with pagination', () {
      final PaginatedOrderModel m =
          PaginatedOrderModel.fromJson(body('order_order_list') as Map<String, dynamic>);
      expect(m.orders, isNotNull);
      expect(m.orders!.length, 5);
      expect(m.totalSize, 23, reason: 'from pagination.total');
      expect(m.offset, 1, reason: 'current_page maps onto the 1-based offset');
    });

    test('every field the order card renders is present', () {
      final PaginatedOrderModel m =
          PaginatedOrderModel.fromJson(body('order_order_list') as Map<String, dynamic>);
      for (final OrderModel o in m.orders!) {
        expect(o.id, isNotNull);
        expect(o.orderStatus, isNotNull);
        expect(o.createdAt, isNotNull);
        expect(o.orderAmount, isNotNull);
        expect(o.moduleType, isNotNull);
        // my_order_screen.dart:952 does `(orderModel.itemCount)! - 1`
        expect(o.itemCount, isNotNull, reason: 'item_count is force-unwrapped by the card');
        expect(o.itemsPreview, isNotNull);
        expect(o.store?.name, isNotNull);
      }
    });

    test('itemsPreview carries what the thumbnail needs', () {
      final PaginatedOrderModel m =
          PaginatedOrderModel.fromJson(body('order_order_list') as Map<String, dynamic>);
      final ItemsPreview p = m.orders!.first.itemsPreview!.first;
      expect(p.id, isNotNull);
      expect(p.name, isNotNull);
      expect(p.quantity, isNotNull);
      // image_full_url is legitimately null for this item; the key exists.
    });

    test('legacy `orders` key still wins', () {
      final PaginatedOrderModel m = PaginatedOrderModel.fromJson(<String, dynamic>{
        'total_size': 7, 'limit': 10, 'offset': 1,
        'orders': <dynamic>[<String, dynamic>{'id': 5, 'order_status': 'pending'}],
        'data': <dynamic>[<String, dynamic>{'id': 99}],
      });
      expect(m.orders!.single.id, 5);
      expect(m.totalSize, 7);
    });
  });

  group('order details — GET customer/order/details', () {
    test('content is a bare list and every row parses', () {
      final List<dynamic> rows = ResponseParser.listOrEmpty(body('order_details'));
      expect(rows.length, 2);
      final List<OrderDetailsModel> details =
          rows.map((e) => OrderDetailsModel.fromJson(e as Map<String, dynamic>)).toList();
      for (final OrderDetailsModel d in details) {
        expect(d.id, isNotNull);
        expect(d.orderId, isNotNull);
        expect(d.itemId, isNotNull);
        expect(d.quantity, isNotNull);
        expect(d.price, isNotNull);
        expect(d.itemDetails, isNotNull, reason: 'the line item name/image come from here');
      }
    });
  });

  group('order tracking — GET customer/order/track', () {
    test('the tracked order parses', () {
      final OrderModel o = OrderModel.fromJson(body('order_track') as Map<String, dynamic>);
      expect(o.id, isNotNull);
      expect(o.orderStatus, isNotNull);
      expect(o.store?.name, isNotNull);
      expect(o.payments, isEmpty, reason: 'sent as [] on this order');
      expect(o.offlinePayment, isNull, reason: 'sent as null — the UI must not unwrap .data');
    });

    test('track omits list-only fields, and reading them is safe', () {
      final OrderModel o = OrderModel.fromJson(body('order_track') as Map<String, dynamic>);
      // These live on order/list but not on track. Null, never a throw.
      expect(o.itemsPreview, isNull);
      expect(o.itemCount, isNull);
      // `can_reorder` is coerced to a bool, so an absent key reads as false, not null.
      expect(o.canReorder, isFalse);
    });

    test('an offline payment with no nested data does not throw', () {
      // What the hardened widget chain now tolerates.
      final OrderModel o = OrderModel.fromJson(<String, dynamic>{
        'id': 1, 'order_status': 'pending', 'offline_payment': <String, dynamic>{},
      });
      expect(o.offlinePayment, isNotNull);
      expect(() => o.offlinePayment?.data?.status, returnsNormally);
      expect(o.offlinePayment?.data?.status, isNull);
    });
  });

  group('payment failed — GET customer/order/payment-failed', () {
    test('every field the retry sheet reads is present', () {
      final PaymentModel p = PaymentModel.fromJson(body('order_payfailed') as Map<String, dynamic>);
      expect(p.orderID, isNotNull);
      expect(p.orderAmount, isNotNull);
      expect(p.paymentMethod, isNotNull);
      expect(p.orderType, isNotNull);
    });
  });

  group('running + reasons', () {
    test('all-running-orders rows parse', () {
      final OngoingOrderModel m = OngoingOrderModel.fromJson(body('order_allrunning') as Map<String, dynamic>);
      expect(m.data, isNotNull);
      expect(m.data!.length, 25);
      expect(m.data!.first.id, isNotNull);
      expect(m.data!.first.status, isNotNull);
    });

    test('cancellation reasons parse, and an empty body yields no reasons instead of throwing', () {
      final OrderCancellationBody c =
          OrderCancellationBody.fromJson(body('order_cancelreasons') as Map<String, dynamic>);
      expect(c.reasons!.length, 6);
      expect(c.reasons!.first.reason, isNotNull);

      final OrderCancellationBody empty = OrderCancellationBody.fromJson(<String, dynamic>{});
      expect(empty.reasons, isNull);
      // The repository now iterates `reasons ?? []`.
      expect(() => (empty.reasons ?? <CancellationData>[]).toList(), returnsNormally);
    });

    test('refund reasons parse from `data`, legacy key still wins', () {
      final RefundModel r = RefundModel.fromJson(body('order_refundreasons') as Map<String, dynamic>);
      expect(r.refundReasons!.length, greaterThan(0));
      expect(r.refundReasons!.first.reason, isNotNull);

      final RefundModel legacy = RefundModel.fromJson(<String, dynamic>{
        'refund_reasons': <dynamic>[<String, dynamic>{'id': 1, 'reason': 'legacy'}],
        'data': <dynamic>[<String, dynamic>{'id': 2, 'reason': 'ignored'}],
      });
      expect(legacy.refundReasons!.single.reason, 'legacy');
    });
  });

  group('reorder — POST customer/order-again/reorder', () {
    // A 403 is never unwrapped centrally, so the repository strips the envelope itself.
    final Map<String, dynamic> refusal = <String, dynamic>{
      'identical_code': 'forbidden_403',
      'message': 'Permission denied',
      'content': <String, dynamic>{
        'cart_count': 0, 'added_count': 0, 'skipped_count': 0,
        'unavailable_items': <dynamic>[
          <String, dynamic>{'id': 10, 'name': 'Desi Cow Ghee', 'code': 'out_of_stock', 'message': 'Item is out of stock'},
        ],
        'skipped_items': <dynamic>[],
      },
      'errors': <dynamic>[<String, dynamic>{'code': 'no_item_added', 'message': 'No item could be added to cart'}],
    };

    test('a refused reorder still names every unavailable item', () {
      final ReorderResponseModel m =
          ReorderResponseModel.fromJson(ResponseParser.payloadOf(refusal) as Map<String, dynamic>);
      expect(m.addedCount, 0);
      expect(m.unavailableItems!.single.name, 'Desi Cow Ghee');
      expect(m.unavailableItems!.single.message, 'Item is out of stock');
    });

    test('the envelope itself carries no counts — reading it as the payload loses them', () {
      final ReorderResponseModel m = ReorderResponseModel.fromJson(refusal);
      expect(m.addedCount, isNull);
      expect(m.unavailableItems, isNull, reason: 'what the screen used to be handed');
    });

    test('a success is already unwrapped, so the same call leaves it alone', () {
      final dynamic unwrapped = ApiClient.unwrapEnvelope(<String, dynamic>{
        'identical_code': 'default_200',
        'message': 'Added',
        'content': <String, dynamic>{'cart_count': 2, 'added_count': 2, 'unavailable_items': <dynamic>[]},
        'errors': <dynamic>[],
      }, 200);
      final ReorderResponseModel m =
          ReorderResponseModel.fromJson(ResponseParser.payloadOf(unwrapped) as Map<String, dynamic>);
      expect(m.addedCount, 2);
      expect(m.unavailableItems, isEmpty);
    });
  });
}
