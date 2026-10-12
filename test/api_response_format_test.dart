import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/api/response_parser.dart';
import 'package:sixam_mart/common/models/pagination_model.dart';

/// Proves the splash → home path reads both API response formats.
///
/// Sample payloads are trimmed from `docs/New-api-responses.md`. Every case is
/// asserted twice — once against the new format, once against the legacy one —
/// because the app has to keep working against the current backend until the
/// cutover lands.
void main() {
  group('ApiClient.isSuccessCode', () {
    test('accepts 2xx, including the 201 the API returns on create', () {
      expect(ApiClient.isSuccessCode(200), isTrue);
      expect(ApiClient.isSuccessCode(201), isTrue);
      expect(ApiClient.isSuccessCode(204), isTrue);
    });

    test('rejects non-2xx and null', () {
      expect(ApiClient.isSuccessCode(301), isFalse);
      expect(ApiClient.isSuccessCode(403), isFalse);
      expect(ApiClient.isSuccessCode(422), isFalse);
      expect(ApiClient.isSuccessCode(500), isFalse);
      expect(ApiClient.isSuccessCode(null), isFalse);
    });
  });

  group('ApiClient.unwrapEnvelope', () {
    test('unwraps content on a 2xx enveloped response', () {
      final dynamic body = ApiClient.unwrapEnvelope(<String, dynamic>{
        'identical_code': 'default_200',
        'message': 'Successfully fetched',
        'content': <String, dynamic>{'guest_id': 6778},
        'errors': <dynamic>[],
      }, 200);
      expect(body, <String, dynamic>{'guest_id': 6778});
    });

    test('unwraps on 201 too — guest login and cart add return Created', () {
      final dynamic body = ApiClient.unwrapEnvelope(<String, dynamic>{
        'identical_code': 'default_store_201',
        'message': 'Successfully created',
        'content': <String, dynamic>{'guest_id': 6778},
        'errors': <dynamic>[],
      }, 201);
      expect((body as Map)['guest_id'], 6778);
    });

    test('leaves a legacy response untouched — no identical_code', () {
      final Map<String, dynamic> legacy = <String, dynamic>{'guest_id': 6778};
      expect(ApiClient.unwrapEnvelope(legacy, 200), same(legacy));
    });

    test('leaves a legacy bare list untouched', () {
      final List<dynamic> legacy = <dynamic>[
        <String, dynamic>{'id': 1},
      ];
      expect(ApiClient.unwrapEnvelope(legacy, 200), same(legacy));
    });

    test('keeps the envelope on an error so ApiChecker still sees errors', () {
      final Map<String, dynamic> error = <String, dynamic>{
        'identical_code': 'default_403',
        'message': 'Forbidden',
        'content': null,
        'errors': <dynamic>[
          <String, dynamic>{'code': 'coupon', 'message': 'Coupon not found'},
        ],
      };
      expect(ApiClient.unwrapEnvelope(error, 403), same(error));
    });

    test('keeps the envelope when content is null, so body[message] still reads', () {
      // `content: null` is the shape for endpoints like customer/cm-firebase-token.
      // Leaving the envelope in place means the top-level `message` sits exactly
      // where the old flat {"message": …} body had it.
      final Map<String, dynamic> body = <String, dynamic>{
        'identical_code': 'default_200',
        'message': 'Token updated successfully',
        'content': null,
        'errors': <dynamic>[],
      };
      expect(ApiClient.unwrapEnvelope(body, 200), same(body));
      expect((ApiClient.unwrapEnvelope(body, 200) as Map)['message'], 'Token updated successfully');
    });

    test('leaves a non-JSON (binary) body alone', () {
      expect(ApiClient.unwrapEnvelope('%PDF-1.4', 200), '%PDF-1.4');
      expect(ApiClient.unwrapEnvelope(null, 200), isNull);
    });
  });

  group('ApiClient.envelopeMessageOf', () {
    test('lifts the envelope message, which sits beside content and not inside it', () {
      // POST /customer/address/add answers
      // {"message":"Successfully created","content":{"zone_ids":[1,3]}} — so the
      // message is lost unless it is carried over to statusText.
      final Map<String, dynamic> body = <String, dynamic>{
        'identical_code': 'default_store_201',
        'message': 'Successfully created',
        'content': <String, dynamic>{'zone_ids': <int>[1, 3]},
        'errors': <dynamic>[],
      };
      expect(ApiClient.envelopeMessageOf(body, 201), 'Successfully created');
    });

    test('is null for a legacy body, which keeps its message in-band', () {
      expect(
        ApiClient.envelopeMessageOf(<String, dynamic>{'message': 'Saved', 'zone_ids': <int>[1]}, 200),
        isNull,
      );
    });

    test('is null on an error, leaving error messaging to ApiChecker', () {
      final Map<String, dynamic> error = <String, dynamic>{
        'identical_code': 'default_403',
        'message': 'Out of coverage!',
        'content': null,
        'errors': <dynamic>[],
      };
      expect(ApiClient.envelopeMessageOf(error, 403), isNull);
    });
  });

  group('ResponseParser.listOf — both formats produce the same list', () {
    test('reads the new content.data shape', () {
      final List<dynamic>? list = ResponseParser.listOf(<String, dynamic>{
        'data': <dynamic>[
          <String, dynamic>{'id': 1},
          <String, dynamic>{'id': 2},
        ],
        'pagination': <String, dynamic>{'current_page': 1, 'last_page': 1, 'per_page': 25, 'total': 2},
      });
      expect(list, hasLength(2));
      expect(list!.first['id'], 1);
    });

    test('reads a legacy bare list — /categories, /module', () {
      final List<dynamic>? list = ResponseParser.listOf(<dynamic>[
        <String, dynamic>{'id': 1},
      ]);
      expect(list, hasLength(1));
    });

    test('reads a legacy named key — stores, addresses, smart_banners', () {
      expect(
        ResponseParser.listOf(<String, dynamic>{
          'stores': <dynamic>[<String, dynamic>{'id': 9}],
        }, legacyKey: 'stores'),
        hasLength(1),
      );
      expect(
        ResponseParser.listOf(<String, dynamic>{
          'addresses': <dynamic>[<String, dynamic>{'id': 3}],
        }, legacyKey: 'addresses'),
        hasLength(1),
      );
    });

    test('an explicitly named key wins over the generic data key', () {
      // The caller naming a key is the stronger signal, and checking it first
      // stops a transitional body carrying both from picking the wrong list.
      final List<dynamic>? list = ResponseParser.listOf(<String, dynamic>{
        'data': <dynamic>[<String, dynamic>{'id': 'generic'}],
        'stores': <dynamic>[<String, dynamic>{'id': 'named'}],
      }, legacyKey: 'stores');
      expect(list!.single['id'], 'named');
    });

    test('falls back to data when the named key is absent — the migrated case', () {
      final List<dynamic>? list = ResponseParser.listOf(<String, dynamic>{
        'data': <dynamic>[<String, dynamic>{'id': 7}],
        'pagination': <String, dynamic>{'total': 1},
      }, legacyKey: 'stores');
      expect(list!.single['id'], 7);
    });
  });

  group('ResponseParser.namedListOf — bodies holding more than one list', () {
    // A wish list returns vehicles and providers side by side. listOf would fall
    // back to `data` for whichever key is missing and hand back the wrong list;
    // namedListOf never does.
    final Map<String, dynamic> twoLists = <String, dynamic>{
      'vehicles': <dynamic>[<String, dynamic>{'id': 1}],
      'providers': <dynamic>[<String, dynamic>{'id': 2}, <String, dynamic>{'id': 3}],
    };

    test('reads each list independently', () {
      expect(ResponseParser.namedListOf(twoLists, 'vehicles'), hasLength(1));
      expect(ResponseParser.namedListOf(twoLists, 'providers'), hasLength(2));
    });

    test('never falls back to data, so a missing key stays empty', () {
      final Map<String, dynamic> withData = <String, dynamic>{
        'data': <dynamic>[<String, dynamic>{'id': 99}],
        'vehicles': <dynamic>[<String, dynamic>{'id': 1}],
      };
      expect(ResponseParser.namedListOf(withData, 'vehicles'), hasLength(1));
      expect(ResponseParser.namedListOf(withData, 'providers'), isEmpty);
    });

    test('a missing or non-list value yields an empty list, never throws', () {
      expect(ResponseParser.namedListOf(<String, dynamic>{'providers': null}, 'providers'), isEmpty);
      expect(ResponseParser.namedListOf(<String, dynamic>{'providers': 'oops'}, 'providers'), isEmpty);
      expect(ResponseParser.namedListOf(null, 'providers'), isEmpty);
    });

    test('returns null when nothing list-shaped is present', () {
      expect(ResponseParser.listOf(<String, dynamic>{'message': 'ok'}), isNull);
      expect(ResponseParser.listOf(null), isNull);
      expect(ResponseParser.listOf('some string'), isNull);
      expect(ResponseParser.listOrEmpty(<String, dynamic>{'message': 'ok'}), isEmpty);
    });

    test('an empty list stays an empty list, not null', () {
      expect(ResponseParser.listOf(<String, dynamic>{'data': <dynamic>[]}), isEmpty);
      expect(ResponseParser.listOf(<dynamic>[]), isEmpty);
    });
  });

  group('PaginationModel', () {
    test('reads the new pagination object', () {
      final PaginationModel p = PaginationModel.fromJson(<String, dynamic>{
        'data': <dynamic>[],
        'pagination': <String, dynamic>{
          'current_page': 2, 'last_page': 4, 'per_page': 25, 'total': 87, 'from': 26, 'to': 50,
        },
      });
      expect(p.totalSize, 87);
      expect(p.limit, 25);
      expect(p.offset, 2);
      expect(p.lastPage, 4);
    });

    test('reads the legacy flat keys the service module still returns', () {
      final PaginationModel p = PaginationModel.fromJson(<String, dynamic>{
        'total_size': 87, 'limit': 25, 'offset': 2,
      });
      expect(p.totalSize, 87);
      expect(p.limit, 25);
      expect(p.offset, 2);
      expect(p.lastPage, isNull);
    });

    test('both formats agree on the values the app actually reads', () {
      final PaginationModel newFormat = PaginationModel.fromJson(<String, dynamic>{
        'pagination': <String, dynamic>{'current_page': 3, 'per_page': 10, 'total': 42},
      });
      final PaginationModel legacy = PaginationModel.fromJson(<String, dynamic>{
        'total_size': 42, 'limit': 10, 'offset': 3,
      });
      expect(newFormat.totalSize, legacy.totalSize);
      expect(newFormat.limit, legacy.limit);
      expect(newFormat.offset, legacy.offset);
    });

    test('coerces string numbers, which both formats have been seen sending', () {
      final PaginationModel p = PaginationModel.fromJson(<String, dynamic>{
        'total_size': '87', 'limit': '25', 'offset': '2',
      });
      expect(p.totalSize, 87);
      expect(p.limit, 25);
      expect(p.offset, 2);
    });

    test('missing paging metadata yields nulls rather than throwing', () {
      final PaginationModel p = PaginationModel.fromJson(<String, dynamic>{'data': <dynamic>[]});
      expect(p.totalSize, isNull);
      expect(p.offset, isNull);
    });
  });
}
