import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/api/api_client.dart';

/// `POST /api/v1/rental/user/trip/trip-booking` — confirm booking in the rental
/// module.
///
/// The controller navigated with `int.parse(response.body.toString())`, which
/// only worked while the endpoint answered with a bare id. Under the envelope
/// the body is whatever `content` holds, and every other rental endpoint wraps
/// that in an object — so `int.parse` threw *after* the trip was created.
///
/// `_tripIdOf` in TaxiCartController is mirrored here so the shapes it must
/// survive are pinned; keep the two in sync.
int? tripIdOf(dynamic body) {
  if (body == null) return null;
  if (body is int) return body;
  if (body is num) return body.toInt();
  if (body is String) return int.tryParse(body.trim());
  if (body is Map) {
    for (final String key in const <String>['trip_id', 'id', 'tripId']) {
      final int? id = tripIdOf(body[key]);
      if (id != null) return id;
    }
    for (final String key in const <String>['trip', 'data']) {
      final dynamic nested = body[key];
      if (nested is Map) {
        final int? id = tripIdOf(nested);
        if (id != null) return id;
      }
    }
  }
  return null;
}

void main() {
  group('booking is a create, so the status guard must accept 201', () {
    test('201 Created counts as success', () {
      expect(ApiClient.isSuccessCode(201), isTrue);
      expect(ApiClient.isSuccessCode(200), isTrue);
    });
  });

  group('trip id extraction', () {
    test('object content — the shape every other rental endpoint uses', () {
      final dynamic body = ApiClient.unwrapEnvelope(jsonDecode(
        '{"identical_code":"default_200","message":"Trip booked successfully",'
        '"content":{"trip_id":12},"errors":[]}',
      ), 200);
      // int.parse("{trip_id: 12}") threw here — this is the reported bug.
      expect(tripIdOf(body), 12);
    });

    test('bare id content — the legacy shape still works', () {
      final dynamic body = ApiClient.unwrapEnvelope(jsonDecode(
        '{"identical_code":"default_200","message":"ok","content":12,"errors":[]}',
      ), 200);
      expect(tripIdOf(body), 12);
    });

    test('a completely flat legacy body still works', () {
      expect(tripIdOf(12), 12);
      expect(tripIdOf('12'), 12);
      expect(tripIdOf(' 12 '), 12);
    });

    test('accepts the other keys the id has been seen under', () {
      expect(tripIdOf(<String, dynamic>{'id': 7}), 7);
      expect(tripIdOf(<String, dynamic>{'tripId': 7}), 7);
      expect(tripIdOf(<String, dynamic>{'trip': <String, dynamic>{'id': 7}}), 7);
      expect(tripIdOf(<String, dynamic>{'data': <String, dynamic>{'trip_id': 7}}), 7);
    });

    test('an id sent as a numeric string is coerced', () {
      expect(tripIdOf(<String, dynamic>{'trip_id': '204'}), 204);
    });

    test('trip_id wins over a sibling id', () {
      expect(tripIdOf(<String, dynamic>{'trip_id': 3, 'id': 99}), 3);
    });

    test('no id yields null rather than throwing', () {
      // content:null leaves the envelope in place — this is what reached
      // int.parse and crashed the booking flow.
      final dynamic envelope = ApiClient.unwrapEnvelope(jsonDecode(
        '{"identical_code":"default_200","message":"ok","content":null,"errors":[]}',
      ), 200);
      expect(tripIdOf(envelope), isNull);
      expect(tripIdOf(<String, dynamic>{'status': 'ok'}), isNull);
      expect(tripIdOf('not a number'), isNull);
      expect(tripIdOf(null), isNull);
      expect(tripIdOf(<dynamic>[]), isNull);
    });
  });
}
