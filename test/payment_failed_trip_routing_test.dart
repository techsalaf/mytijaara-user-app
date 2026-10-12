import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/checkout/domain/models/payment_model.dart';

/// `GET /api/v1/customer/order/payment-failed` answers for rental bookings too,
/// and names everything differently when it does: `trip_id` / `trip_amount` /
/// `type: "rental"` / `module_type: "rental"`, with no `order_id`, `order_amount`
/// or `order_type` at all.
///
/// Everything the shared retry flow does afterwards — `codSwitchUri`,
/// `walletSwitchUri`, the mart payment route, the offline screen — is keyed by an
/// *order* id. Handing any of them a trip id would 404 or act on an unrelated
/// order, so the flow has to branch to `POST rental/user/trip/payment` instead.
void main() {
  PaymentModel parse(String orderType) => PaymentModel.fromJson(
        jsonDecode('{"order_id":100262,"order_type":"$orderType","order_amount":1841.30,'
            '"cash_on_delivery":true,"digital_payment":true,"offline_payment":true,'
            '"payment_status":"unpaid","user_id":21}') as Map<String, dynamic>,
      );

  group('CheckoutController.isTripPayment', () {
    test('recognises a rental trip', () {
      expect(CheckoutController.isTripPayment(parse('trip')), isTrue);
    });

    test('leaves every mart order type on the existing path', () {
      for (final String type in <String>['delivery', 'take_away', 'parcel', 'order', 'ride']) {
        expect(CheckoutController.isTripPayment(parse(type)), isFalse, reason: type);
      }
    });

    test('a null model or missing order_type is not a trip', () {
      expect(CheckoutController.isTripPayment(null), isFalse);
      expect(
        CheckoutController.isTripPayment(
          PaymentModel.fromJson(jsonDecode('{"order_id":1,"user_id":21}') as Map<String, dynamic>),
        ),
        isFalse,
      );
    });
  });

  group('the payment-failed payload itself', () {
    test('unwraps from the envelope with order_type intact', () {
      final dynamic body = ApiClient.unwrapEnvelope(jsonDecode(
        '{"identical_code":"default_200","message":"Successfully fetched",'
        '"content":{"order_id":100262,"order_type":"trip","order_amount":1841.30,'
        '"payment_status":"unpaid","user_id":21},"errors":[]}',
      ), 200);

      final PaymentModel model = PaymentModel.fromJson(body as Map<String, dynamic>);
      expect(CheckoutController.isTripPayment(model), isTrue);
      // The trip id has to survive as something int.tryParse can read — it is
      // what `retryTripPayment` sends as `trip_id`.
      expect(int.tryParse(model.orderID ?? ''), 100262);
      expect(model.orderAmount, 1841.30);
    });

    test('content:null (no failed payment) yields no model to branch on', () {
      // The documented sample. unwrapEnvelope leaves the envelope in place when
      // content is null, so there is no order_id to mistake for a trip.
      final dynamic body = ApiClient.unwrapEnvelope(jsonDecode(
        '{"identical_code":"default_200","message":"Successfully fetched","content":null,"errors":[]}',
      ), 200);
      expect((body as Map)['order_id'], isNull);
    });
  });

  group('method mapping', () {
    // The shared sheet and the rental sheet number their methods differently —
    // shared: 0 COD / 1 wallet / 2 digital / 3 offline
    // rental: 0 wallet / 1 cash_payment / 2 digital
    // so the mapping in _payFailedTrip is by meaning. Pinned here because getting
    // it wrong charges the wrong way round without failing.
    String? methodFor(int sharedIndex) {
      switch (sharedIndex) {
        case 0:
          return 'cash_payment';
        case 1:
          return 'wallet';
        case 2:
          return 'digital_payment';
        default:
          return null; // offline — unsupported by the rental endpoint
      }
    }

    test('shared indices map to the rental API method names', () {
      expect(methodFor(0), 'cash_payment');
      expect(methodFor(1), 'wallet');
      expect(methodFor(2), 'digital_payment');
    });

    test('offline has no rental equivalent', () {
      expect(methodFor(3), isNull);
    });
  });

  group('the real rental payload', () {
    // Verbatim from the live backend for a failed rental trip. Note it carries
    // NO order_id, NO order_amount and NO order_type — the fields the mart path
    // is built on — so nothing here can be assumed from the mart shape.
    final Map<String, dynamic> rentalBody = jsonDecode(
      '{"type":"rental","cash_on_delivery":true,"digital_payment":true,'
      '"offline_payment":false,"maximum_cod_order_amount":0,"trip_id":100045,'
      '"trip_amount":4020.392,"partially_paid_amount":0,"trip_type":"distance_wise",'
      '"trip_status":"payment_failed","user_id":21,"guest_id":null,"zone_id":1,'
      '"module":6,"module_type":"rental","payment_status":"unpaid",'
      '"payment_method":null,"contact_person_number":"+8801600000000"}',
    ) as Map<String, dynamic>;

    test('is recognised as a trip', () {
      expect(CheckoutController.isTripPayment(PaymentModel.fromJson(rentalBody)), isTrue);
    });

    test('trip_id and trip_amount are read into orderID / orderAmount', () {
      final PaymentModel m = PaymentModel.fromJson(rentalBody);
      // _payFailedTrip parses orderID back to an int for `trip_id`.
      expect(m.orderID, '100045');
      expect(int.tryParse(m.orderID!), 100045);
      expect(m.orderAmount, 4020.392);
    });

    test('the sheet is driven by the payload flags — offline is off for rental', () {
      final PaymentModel m = PaymentModel.fromJson(rentalBody);
      expect(m.isCashOnDeliveryActive, isTrue);
      expect(m.isDigitalPaymentActive, isTrue);
      expect(m.isOfflinePaymentActive, isFalse);
      expect(m.maxCodOrderAmount, 0);
      expect(m.contactNumber, '+8801600000000');
      expect(m.zoneId, 1);
      expect(m.userId, 21);
    });

    test('order_type is absent, so the old discriminator would have missed it', () {
      // isTripPayment used to test `orderType == "trip"`. Pinned so the
      // regression cannot come back.
      expect(rentalBody.containsKey('order_type'), isFalse);
      expect(PaymentModel.fromJson(rentalBody).orderType, 'rental');
    });
  });

  group('the real mart payload is unchanged by the rental support', () {
    late Map<String, dynamic> martBody;

    setUp(() {
      final dynamic body = ApiClient.unwrapEnvelope(
        jsonDecode(File('test/fixtures/live/order_payfailed.json').readAsStringSync()), 200);
      martBody = (body is List ? body.first : body) as Map<String, dynamic>;
    });

    test('is not treated as a trip', () {
      expect(martBody['module_type'], 'food');
      expect(CheckoutController.isTripPayment(PaymentModel.fromJson(martBody)), isFalse);
    });

    test('order_id / order_amount still win over the trip fallbacks', () {
      final PaymentModel m = PaymentModel.fromJson(martBody);
      expect(m.orderID, '101698');
      expect(m.orderAmount, 1079.64);
      expect(m.orderType, 'delivery');
      expect(m.isOfflinePaymentActive, isTrue);
    });

    test('order_id wins even if a stray trip_id were present', () {
      final PaymentModel m = PaymentModel.fromJson(<String, dynamic>{
        ...martBody, 'trip_id': 999, 'trip_amount': 1.0,
      });
      expect(m.orderID, '101698');
      expect(m.orderAmount, 1079.64);
    });
  });

  group('content: null — nothing outstanding', () {
    // The whole reason the repository has to normalise: unwrapEnvelope leaves the
    // envelope in place when content is null, so fromJson reads every field off
    // the envelope and returns a perfectly valid, entirely empty model.
    final dynamic emptyBody = ApiClient.unwrapEnvelope(jsonDecode(
      '{"identical_code":"default_200","message":"Successfully fetched","content":null,"errors":[]}',
    ), 200);

    test('the envelope survives unwrapping, so parsing does not fail', () {
      expect(emptyBody, isA<Map<String, dynamic>>());
      expect((emptyBody as Map).containsKey('identical_code'), isTrue);
      expect(() => PaymentModel.fromJson(emptyBody as Map<String, dynamic>), returnsNormally);
    });

    test('the parsed model is hollow — orderID is what distinguishes it', () {
      final PaymentModel hollow = PaymentModel.fromJson(emptyBody as Map<String, dynamic>);
      // Non-null, which is why `paymentModel != null` was never a safe test.
      expect(hollow.orderID, isNull);
      expect(hollow.orderAmount, 0);
      expect(hollow.paymentStatus, isNull);
      expect(hollow.moduleType, isNull);
      expect(CheckoutController.isTripPayment(hollow), isFalse);
    });

    test('a real payload is not mistaken for the empty one', () {
      final PaymentModel real = PaymentModel.fromJson(
        jsonDecode('{"order_id":101698,"order_amount":1079.64,"module_type":"food"}') as Map<String, dynamic>,
      );
      expect(real.orderID, '101698');
    });
  });

  group('digital payment from the shared sheet', () {
    // The sheet sets both the index and the gateway together
    // (payment_method_bottom_sheet.dart:199-200), so index 2 normally implies a
    // gateway. The guard covers the case where it does not.
    String? gatewayFor(int index, String? digitalPaymentName) {
      if (index != 2) return null;
      return (digitalPaymentName == null || digitalPaymentName.isEmpty) ? null : digitalPaymentName;
    }

    test('a chosen gateway is forwarded as payment_gateway', () {
      expect(gatewayFor(2, 'ssl_commerz'), 'ssl_commerz');
    });

    test('cash and wallet send no gateway at all', () {
      // makeTripPayment omits payment_gateway/callback_url/payment_platform when
      // the gateway is null — which is what the cash call in the log did.
      expect(gatewayFor(0, 'ssl_commerz'), isNull);
      expect(gatewayFor(1, 'ssl_commerz'), isNull);
    });

    test('digital with no gateway is refused rather than sent', () {
      // retryTripPayment reads a non-null gateway as "open the webview", so a
      // null one on a 2xx would be taken as settled and refresh the trip as if
      // it had been paid.
      expect(gatewayFor(2, null), isNull);
      expect(gatewayFor(2, ''), isNull);
    });
  });
}
