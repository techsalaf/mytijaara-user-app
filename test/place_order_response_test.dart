import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/api/api_client.dart';

/// Covers what the checkout screen reads back from `POST customer/order/place`.
///
/// The place-order response moved in three ways at once, and each one fails
/// silently rather than loudly: the status code can be 201, the success message
/// left the body for the envelope, and the failure reason stopped reaching
/// `statusText` — so the user saw "Unprocessable Content" instead of the reason
/// the order was rejected.
void main() {
  group('success payload', () {
    // The envelope shape every 2xx now uses: message beside `content`, payload inside.
    final Map<String, dynamic> enveloped = <String, dynamic>{
      'identical_code': 'default_200',
      'message': 'Order placed successfully',
      'content': <String, dynamic>{'order_id': 103013, 'user_id': 6778},
      'errors': <dynamic>[],
    };

    // What the previous backend returned, flat.
    final Map<String, dynamic> legacy = <String, dynamic>{
      'message': 'Order placed successfully',
      'order_id': 103013,
      'user_id': 6778,
    };

    test('order_id and user_id are read off the unwrapped body', () {
      final dynamic body = ApiClient.unwrapEnvelope(enveloped, 200);
      expect(body['order_id'].toString(), '103013');
      expect(body['user_id'].toString(), '6778');
    });

    test('a 201 Created unwraps the same way — placing an order creates one', () {
      expect(ApiClient.isSuccessCode(201), isTrue);
      final dynamic body = ApiClient.unwrapEnvelope(enveloped, 201);
      expect(body['order_id'].toString(), '103013');
    });

    test('the success message is on the envelope, not in the unwrapped body', () {
      // This is what broke the confirmation message: `body['message']` is gone.
      final dynamic body = ApiClient.unwrapEnvelope(enveloped, 200);
      expect(body['message'], isNull);
      expect(ApiClient.envelopeMessageOf(enveloped, 200), 'Order placed successfully');
    });

    test('a legacy flat body still carries both in the body', () {
      final dynamic body = ApiClient.unwrapEnvelope(legacy, 200);
      expect(body['order_id'].toString(), '103013');
      expect(body['message'], 'Order placed successfully');
      // No envelope, so nothing is lifted onto statusText — the body fallback is
      // what keeps the legacy backend showing a message.
      expect(ApiClient.envelopeMessageOf(legacy, 200), isNull);
    });
  });

  group('failure payload', () {
    // Verbatim from docs/New-api-responses.md — POST api/v1/customer/order/place.
    // Note `errors` is a map keyed by field here, not the legacy [{code, message}].
    final dynamic validationFailure = jsonDecode(
      '{"identical_code":"unprocessable_entity_422",'
      '"message":"The dm tips must be a number.",'
      '"content":null,'
      '"errors":{"dm_tips":["The dm tips must be a number."]}}',
    );

    test('the reason reaches statusText instead of the HTTP phrase', () {
      expect(ApiClient.envelopeErrorMessageOf(validationFailure), 'The dm tips must be a number.');
    });

    test('an error body is never unwrapped, so the shape stays inspectable', () {
      expect(ApiClient.unwrapEnvelope(validationFailure, 422), same(validationFailure));
    });

    test('falls back to the field map when the envelope has no top-level message', () {
      expect(
        ApiClient.envelopeErrorMessageOf(<String, dynamic>{
          'identical_code': 'unprocessable_entity_422',
          'message': '',
          'errors': <String, dynamic>{
            'contact_person_number': <String>['The contact person number field is required.'],
          },
        }),
        'The contact person number field is required.',
      );
    });

    test('still reads the legacy [{code, message}] list shape', () {
      expect(
        ApiClient.envelopeErrorMessageOf(<String, dynamic>{
          'identical_code': 'default_403',
          'errors': <dynamic>[
            <String, dynamic>{'code': 'order_time', 'message': 'Store is closed now'},
          ],
        }),
        'Store is closed now',
      );
    });

    test('leaves every non-envelope body to the existing handling', () {
      // No identical_code — a legacy error body must fall through untouched.
      expect(
        ApiClient.envelopeErrorMessageOf(<String, dynamic>{
          'errors': <dynamic>[
            <String, dynamic>{'code': 'coupon', 'message': 'Coupon expired'},
          ],
        }),
        isNull,
      );
      expect(ApiClient.envelopeErrorMessageOf('plain string body'), isNull);
      expect(ApiClient.envelopeErrorMessageOf(null), isNull);
    });

    test('an envelope with nothing readable yields null rather than a bad message', () {
      expect(
        ApiClient.envelopeErrorMessageOf(<String, dynamic>{
          'identical_code': 'default_500',
          'errors': <dynamic>[],
        }),
        isNull,
      );
      expect(
        ApiClient.envelopeErrorMessageOf(<String, dynamic>{
          'identical_code': 'default_500',
          'errors': <String, dynamic>{'field': <dynamic>[]},
        }),
        isNull,
      );
    });

    // POST api/v1/customer/order/checkout-summary, refusing a parcel whose receiver
    // sits outside the service area.
    final dynamic receiverZoneRefusal = jsonDecode(
      '{"identical_code":"forbidden_403",'
      '"message":"Permission denied",'
      '"content":null,'
      '"errors":[{"code":"receiverZone",'
      '"message":"This service is not available in the desired location."}]}',
    );

    test('a refused quote is read out by its error, not the envelope message', () {
      expect(
        ApiClient.envelopeErrorMessageOf(receiverZoneRefusal),
        'This service is not available in the desired location.',
        reason: '`message` alone says only "Permission denied"',
      );
      expect(
        (receiverZoneRefusal as Map)['errors'][0]['code'],
        'receiverZone',
        reason: 'the code the controller matches to decide the refusal is worth a snackbar',
      );
    });
  });
}
