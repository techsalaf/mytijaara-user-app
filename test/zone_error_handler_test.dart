import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/helper/zone_error_handler.dart';

/// `ZoneErrorHandler.isZoneUnavailable` is the gate that decides whether a failed
/// request hijacks the customer's navigation. It must fire on exactly one error
/// and stay out of the way of every other failure the app already handles.
void main() {
  Response envelope({
    required int status,
    dynamic errors,
    String message = 'Validation failed',
    String code = 'unprocessable_entity_422',
  }) =>
      Response(
        statusCode: status,
        statusText: message,
        body: <String, dynamic>{
          'identical_code': code,
          'message': message,
          'content': null,
          'errors': errors,
        },
      );

  group('fires on the zone failure', () {
    test('the exact payload the API sends', () {
      // Verbatim from the live response.
      final Response response = envelope(
        status: 422,
        errors: <dynamic>[
          <String, dynamic>{
            'code': 'zone_module_not_found',
            'message': 'Zone is not available right now',
          },
        ],
      );
      expect(ZoneErrorHandler.isZoneUnavailable(response), isTrue);
    });

    test('when the zone error is not the first in the list', () {
      final Response response = envelope(status: 422, errors: <dynamic>[
        <String, dynamic>{'code': 'coupon', 'message': 'Coupon expired'},
        <String, dynamic>{'code': 'zone_module_not_found', 'message': 'Zone is not available right now'},
      ]);
      expect(ZoneErrorHandler.isZoneUnavailable(response), isTrue);
    });

    test('on any non-2xx status, not only 422', () {
      for (final int status in <int>[400, 403, 404, 422, 500]) {
        final Response response = envelope(status: status, errors: <dynamic>[
          <String, dynamic>{'code': 'zone_module_not_found', 'message': 'Zone is not available right now'},
        ]);
        expect(ZoneErrorHandler.isZoneUnavailable(response), isTrue, reason: 'status $status');
      }
    });
  });

  group('stays out of the way of everything else', () {
    test('a different 422 validation error is left to the existing snackbar', () {
      final Response response = envelope(status: 422, errors: <dynamic>[
        <String, dynamic>{'code': 'dm_tips', 'message': 'The dm tips must be a number.'},
      ]);
      expect(ZoneErrorHandler.isZoneUnavailable(response), isFalse);
    });

    test('the field-keyed map error shape does not match', () {
      final Response response = envelope(status: 422, errors: <String, dynamic>{
        'dm_tips': <String>['The dm tips must be a number.'],
      });
      expect(ZoneErrorHandler.isZoneUnavailable(response), isFalse);
    });

    test('a 401 is left to the sign-out branch', () {
      final Response response = envelope(status: 401, errors: <dynamic>[
        <String, dynamic>{'code': 'zone_module_not_found', 'message': 'x'},
      ]);
      // Still true here — ApiChecker checks 401 first, so this never reaches the
      // zone branch. Asserted so the ordering in ApiChecker stays deliberate.
      expect(ZoneErrorHandler.isZoneUnavailable(response), isTrue);
    });

    test('a SUCCESS response is never treated as the zone failure', () {
      for (final int status in <int>[200, 201, 204]) {
        final Response ok = Response(statusCode: status, body: <String, dynamic>{
          'errors': <dynamic>[
            <String, dynamic>{'code': 'zone_module_not_found', 'message': 'x'},
          ],
        });
        expect(ZoneErrorHandler.isZoneUnavailable(ok), isFalse, reason: 'status $status');
      }
    });

    test('an empty errors list does not match', () {
      expect(ZoneErrorHandler.isZoneUnavailable(envelope(status: 422, errors: <dynamic>[])), isFalse);
    });

    test('a null errors field does not match', () {
      expect(ZoneErrorHandler.isZoneUnavailable(envelope(status: 422, errors: null)), isFalse);
    });

    test('the legacy zone_404 shape is left to its existing handling', () {
      const Response response = Response(statusCode: 403, body: <String, dynamic>{
        'response_code': 'zone_404',
        'message': 'Zone not found',
      });
      expect(ZoneErrorHandler.isZoneUnavailable(response), isFalse);
    });
  });

  group('never throws on a malformed body', () {
    test('a plain string body', () {
      expect(ZoneErrorHandler.isZoneUnavailable(
        const Response(statusCode: 500, body: 'Internal Server Error'),
      ), isFalse);
    });

    test('a null body — the offline/no-internet shape', () {
      expect(ZoneErrorHandler.isZoneUnavailable(const Response(statusCode: 0)), isFalse);
      expect(ZoneErrorHandler.isZoneUnavailable(const Response(statusCode: 1)), isFalse);
    });

    test('a null status code', () {
      expect(ZoneErrorHandler.isZoneUnavailable(const Response()), isFalse);
    });

    test('errors entries that are not maps', () {
      expect(ZoneErrorHandler.isZoneUnavailable(
        envelope(status: 422, errors: <dynamic>['zone_module_not_found', 42, null]),
      ), isFalse);
    });

    test('an error entry with no code key', () {
      expect(ZoneErrorHandler.isZoneUnavailable(
        envelope(status: 422, errors: <dynamic>[<String, dynamic>{'message': 'Zone is not available right now'}]),
      ), isFalse);
    });

    test('matching is on the code, not the human message', () {
      // The message is localized and the backend can reword it; the code cannot.
      expect(ZoneErrorHandler.isZoneUnavailable(
        envelope(status: 422, errors: <dynamic>[
          <String, dynamic>{'code': 'something_else', 'message': 'Zone is not available right now'},
        ]),
      ), isFalse);
    });
  });
}
