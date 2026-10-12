import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/api/api_client.dart';

/// What `POST /customer/order/refund-request` actually answers, and what the success
/// branch reading it has to accept.
///
/// The endpoint CREATES a refund request, so it answers `201 Created` with a null
/// `content`. The branch tested for `statusCode == 200`, so a request the server had
/// already filed fell through it — and because the failure path is handled upstream by
/// ApiChecker there was nothing left to show. The button submitted and then looked dead.
void main() {
  // The response body as captured from the live endpoint.
  Map<String, dynamic> refundCreatedBody() => <String, dynamic>{
    'identical_code': 'default_store_201',
    'message': 'Successfully created',
    'content': null,
    'errors': <dynamic>[],
  };

  test('201 counts as success — the bug', () {
    expect(ApiClient.isSuccessCode(201), isTrue);
    expect(201 == 200, isFalse, reason: 'the test the branch used to make');
  });

  test('a null content leaves the envelope intact, so message stays readable', () {
    final dynamic body = ApiClient.unwrapEnvelope(refundCreatedBody(), 201);

    expect(body, isA<Map<dynamic, dynamic>>());
    expect(body['message'], 'Successfully created');
  });

  test('the confirmation shown is the server\'s own wording', () {
    final dynamic body = ApiClient.unwrapEnvelope(refundCreatedBody(), 201);
    // Mirrors the read in OrderService.submitRefundRequest.
    final dynamic message = body is Map ? body['message'] : null;

    expect(message is String ? message : null, 'Successfully created');
  });

  test('a filled content unwraps, and the message rides on statusText instead', () {
    final Map<String, dynamic> filled = refundCreatedBody()
      ..['content'] = <String, dynamic>{'refund_id': 12};

    expect(ApiClient.unwrapEnvelope(filled, 201), <String, dynamic>{'refund_id': 12});
    expect(ApiClient.envelopeMessageOf(filled, 201), 'Successfully created');
  });

  test('a refusal is not mistaken for success', () {
    expect(ApiClient.isSuccessCode(403), isFalse);
    expect(
      ApiClient.envelopeErrorMessageOf(<String, dynamic>{
        'identical_code': 'default_403',
        'message': 'Permission denied',
        'content': null,
        'errors': <dynamic>[<String, dynamic>{'code': 'order', 'message': 'This order is not refundable.'}],
      }),
      'This order is not refundable.',
    );
  });
}

// SUMMARY
// Covers the refund-request response: 201 Created counts as success, its null content
// leaves the envelope's message where the success branch reads it, a filled content
// moves that message to statusText, and a refusal still reports the server's reason.
