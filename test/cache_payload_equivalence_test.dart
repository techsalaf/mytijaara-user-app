import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/api/response_parser.dart';

/// Proves the offline-cache change is shape-neutral.
///
/// Repositories used to write `jsonEncode(response.body)` to the local cache —
/// re-encoding a body `ApiClient.handleResponse` had *just* decoded. They now
/// write `response.bodyString`, the raw wire string that was already in hand,
/// and the read side runs the decoded row through [ResponseParser.payloadOf].
///
/// That is only safe if, for every response shape the app can see, this holds:
///
///     payloadOf(jsonDecode(bodyString))  ==  jsonDecode(jsonEncode(response.body))
///                    (new read path)                    (old read path)
///
/// where `response.body` is `unwrapEnvelope(jsonDecode(bodyString))`. These tests
/// assert exactly that, plus the backward compatibility that matters in the
/// field: rows written by a **previous build** (already-unwrapped payloads) must
/// still read correctly after the upgrade, because the cache is not cleared.
void main() {
  /// What `handleResponse` puts on `response.body` for a 2xx.
  dynamic decodedBodyFor(String wire) => ApiClient.unwrapEnvelope(jsonDecode(wire), 200);

  /// What a repository's local branch used to reconstruct from the cache.
  dynamic oldCacheRoundTrip(String wire) => jsonDecode(jsonEncode(decodedBodyFor(wire)));

  /// What it reconstructs now: the raw wire string in, `payloadOf` on the way out.
  dynamic newCacheRoundTrip(String wire) => ResponseParser.payloadOf(jsonDecode(wire));

  group('cached payload is identical before and after the change', () {
    test('new enveloped response — content is unwrapped by both paths', () {
      const String wire = '{"identical_code":"default_200","message":"Successfully fetched",'
          '"content":{"total_size":2,"data":[{"id":1},{"id":2}]},"errors":[]}';

      expect(newCacheRoundTrip(wire), oldCacheRoundTrip(wire));
      expect(newCacheRoundTrip(wire), <String, dynamic>{
        'total_size': 2,
        'data': <dynamic>[
          <String, dynamic>{'id': 1},
          <String, dynamic>{'id': 2},
        ],
      });
    });

    test('legacy flat response — passes through untouched on both paths', () {
      const String wire = '{"total_size":2,"stores":[{"id":1},{"id":2}]}';

      expect(newCacheRoundTrip(wire), oldCacheRoundTrip(wire));
      expect(newCacheRoundTrip(wire)['stores'], hasLength(2));
    });

    test('legacy bare-list response — still a List on both paths', () {
      const String wire = '[{"id":1},{"id":2}]';

      expect(newCacheRoundTrip(wire), oldCacheRoundTrip(wire));
      expect(newCacheRoundTrip(wire), isA<List<dynamic>>());
    });

    test('envelope with null content — neither path unwraps it', () {
      // `unwrapEnvelope` deliberately leaves the envelope in place when `content`
      // is null, so callers reading `body['message']` keep working. `payloadOf`
      // has to make the same call or the cached row would lose the message.
      const String wire = '{"identical_code":"default_200","message":"Nothing outstanding",'
          '"content":null,"errors":[]}';

      expect(newCacheRoundTrip(wire), oldCacheRoundTrip(wire));
      expect(newCacheRoundTrip(wire)['message'], 'Nothing outstanding');
    });
  });

  group('rows written by an older build still read correctly', () {
    test('an already-unwrapped cached map is passed through, not unwrapped twice', () {
      // What the previous build stored: the body *after* unwrapEnvelope.
      const String oldRow = '{"total_size":2,"data":[{"id":1},{"id":2}]}';

      expect(ResponseParser.payloadOf(jsonDecode(oldRow)), <String, dynamic>{
        'total_size': 2,
        'data': <dynamic>[
          <String, dynamic>{'id': 1},
          <String, dynamic>{'id': 2},
        ],
      });
    });

    test('payloadOf is idempotent, so a double application cannot corrupt a row', () {
      const String wire = '{"identical_code":"default_200","message":"ok",'
          '"content":{"data":[{"id":1}]},"errors":[]}';

      final dynamic once = ResponseParser.payloadOf(jsonDecode(wire));
      expect(ResponseParser.payloadOf(once), once);
    });

    test('a payload that happens to carry a content key is not mistaken for an envelope', () {
      // `payloadOf` only unwraps when `identical_code` is present, so a legitimate
      // domain field named `content` survives.
      const String row = '{"content":"some article body","title":"Terms"}';

      expect(ResponseParser.payloadOf(jsonDecode(row)), <String, dynamic>{
        'content': 'some article body',
        'title': 'Terms',
      });
    });
  });

  group('list reads survive both cache-row shapes', () {
    test('listOrEmpty finds the list inside an enveloped row', () {
      const String wire = '{"identical_code":"default_200","message":"ok",'
          '"content":{"data":[{"id":1},{"id":2}]},"errors":[]}';

      expect(ResponseParser.listOrEmpty(newCacheRoundTrip(wire)), hasLength(2));
    });

    test('listOrEmpty still finds a legacy named list through payloadOf', () {
      const String wire = '{"stores":[{"id":1},{"id":2},{"id":3}]}';

      expect(
        ResponseParser.listOrEmpty(newCacheRoundTrip(wire), legacyKey: 'stores'),
        hasLength(3),
      );
    });
  });
}
