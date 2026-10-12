import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/api/json_reader.dart';

/// Reproduces ParcelController.placeOrder's response handling.
///
/// Two things used to stop the redirect after a successful placement:
///   1. `statusCode == 200` — a 201 create fell to the failure branch, which only
///      shows a snackbar and never calls parcelCallback.
///   2. `int createUserId = response.body['user_id']` — a TypeError when the key is
///      absent, thrown after the order existed but before the redirect.
({bool success, String orderId, int? createUserId, String? message}) handle(
    String rawBody, int statusCode, {String? statusText}) {
  final dynamic decoded = jsonDecode(rawBody);
  final dynamic body = ApiClient.unwrapEnvelope(decoded, statusCode);
  // handleResponse lifts the envelope's own message onto statusText; mirror that
  // rather than inventing one, so the fallback is exercised the way it really works.
  statusText ??= ApiClient.envelopeMessageOf(decoded, statusCode) ?? 'OK';
  if (!ApiClient.isSuccessCode(statusCode)) {
    return (success: false, orderId: '-1', createUserId: null, message: statusText);
  }
  final Map<String, dynamic> placed =
      body is Map<String, dynamic> ? body : const <String, dynamic>{};
  return (
    success: true,
    orderId: placed['order_id']?.toString() ?? '',
    createUserId: JsonReader.toInt(placed['user_id']),
    message: placed['message'] ?? statusText,
  );
}

/// The old handler, for contrast.
({bool success, String orderId}) handleOld(String rawBody, int statusCode) {
  final dynamic body = ApiClient.unwrapEnvelope(jsonDecode(rawBody), statusCode);
  if (statusCode != 200) return (success: false, orderId: '-1');
  // ignore: unused_local_variable
  final int createUserId = body['user_id'] as int; // throws when absent
  return (success: true, orderId: body['order_id'].toString());
}

void main() {
  // A logged-in parcel order: order_id, no user_id (that only appears when the API
  // creates an account for a guest).
  const String loggedIn201 =
      '{"identical_code":"default_store_201","message":"Order placed successfully","content":{"order_id":103012},"errors":[]}';
  // A guest order where an account was created.
  const String guest201 =
      '{"identical_code":"default_store_201","message":"Order placed successfully","content":{"order_id":103013,"user_id":412},"errors":[]}';
  // A legacy flat 200 body.
  const String legacy200 = '{"message":"Order placed successfully","order_id":103014,"user_id":21}';

  test('201 + no user_id now redirects (both old failure modes)', () {
    final r = handle(loggedIn201, 201);
    expect(r.success, isTrue, reason: 'the redirect runs');
    expect(r.orderId, '103012');
    expect(r.createUserId, isNull, reason: 'optional the whole way down');
    expect(r.message, 'Order placed successfully');

    // The old handler failed on the status alone.
    expect(handleOld(loggedIn201, 201).success, isFalse);
  });

  test('200 + no user_id used to throw, now parses', () {
    const String raw = '{"message":"ok","order_id":103015}';
    expect(() => handleOld(raw, 200), throwsA(isA<TypeError>()),
        reason: 'int createUserId = null');
    final r = handle(raw, 200);
    expect(r.success, isTrue);
    expect(r.orderId, '103015');
    expect(r.createUserId, isNull);
  });

  test('a guest order still carries the created user id', () {
    final r = handle(guest201, 201);
    expect(r.createUserId, 412, reason: 'the create-account payment route needs it');
    expect(r.orderId, '103013');
  });

  test('the legacy flat 200 body is unchanged', () {
    final r = handle(legacy200, 200);
    expect(r.success, isTrue);
    expect(r.orderId, '103014');
    expect(r.createUserId, 21);
    expect(r.message, 'Order placed successfully');
    // and the old handler agreed on this one
    expect(handleOld(legacy200, 200).orderId, '103014');
  });

  test('the message falls back to the envelope message on statusText', () {
    // content carries only ids; the human message sits beside content and is lifted
    // onto statusText by handleResponse.
    final r = handle('{"identical_code":"default_store_201","message":"Order placed successfully","content":{"order_id":9},"errors":[]}', 201);
    expect(r.message, 'Order placed successfully');
  });

  test('a genuine failure still reports failure', () {
    final r = handle('{"identical_code":"unprocessable_entity_422","message":"The dm tips must be a number.","content":null,"errors":[]}', 422,
        statusText: 'The dm tips must be a number.');
    expect(r.success, isFalse);
    expect(r.orderId, '-1');
    expect(r.message, 'The dm tips must be a number.');
  });
}
