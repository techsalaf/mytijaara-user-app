import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/location/domain/models/prediction_model.dart';

/// `GET /api/v1/config/place-api-autocomplete` proxies Google Places and answers
/// **HTTP 200 even when Places failed**, so neither the status code nor the
/// envelope distinguishes "no matches" from "the request never worked".
void main() {
  group('Places failure arriving as a 200', () {
    // Verbatim from the live backend: ?search_text=Dha
    final String liveFailure = '{"identical_code":"default_200","message":"Successfully fetched",'
        '"content":{"error":{"code":400,"message":"API key not valid. Please pass a valid API key.",'
        '"status":"INVALID_ARGUMENT","details":[{"@type":"type.googleapis.com/google.rpc.ErrorInfo",'
        '"reason":"API_KEY_INVALID","domain":"googleapis.com",'
        '"metadata":{"service":"places.googleapis.com"}}]}},"errors":[]}';

    test('is a 2xx, so the status code cannot be used to detect it', () {
      expect(ApiClient.isSuccessCode(200), isTrue);
    });

    test('is reported as an error, not as an empty result list', () {
      final dynamic body = ApiClient.unwrapEnvelope(jsonDecode(liveFailure), 200);
      final PlaceAutocompleteResult result = PlaceAutocompleteResult.fromBody(body);

      expect(result.hasError, isTrue);
      expect(result.errorMessage, 'API key not valid. Please pass a valid API key.');
      expect(result.predictions, isEmpty);
    });

    test('an error object with no message still flags the failure', () {
      final PlaceAutocompleteResult result = PlaceAutocompleteResult.fromBody(
        <String, dynamic>{'error': <String, dynamic>{'code': 500}},
      );
      expect(result.hasError, isTrue);
      expect(result.errorMessage, isNull); // caller falls back to a translated string
    });

    test('the legacy flat error_message shape is still understood', () {
      final PlaceAutocompleteResult result = PlaceAutocompleteResult.fromBody(
        <String, dynamic>{'status': 'REQUEST_DENIED', 'error_message': 'The provided API key is invalid.'},
      );
      expect(result.hasError, isTrue);
      expect(result.errorMessage, 'The provided API key is invalid.');
    });
  });

  group('success payload', () {
    final Map<String, dynamic> enveloped = <String, dynamic>{
      'identical_code': 'default_200',
      'message': 'Successfully fetched',
      'content': <String, dynamic>{
        'suggestions': <dynamic>[
          <String, dynamic>{
            'placePrediction': <String, dynamic>{
              'place': 'places/ChIJgUbEo8cfqokR5lP9_Wh_DaM',
              'placeId': 'ChIJgUbEo8cfqokR5lP9_Wh_DaM',
              'text': <String, dynamic>{'text': 'Dhaka, Bangladesh'},
              'types': <String>['locality', 'political'],
              'structuredFormat': <String, dynamic>{
                'mainText': <String, dynamic>{'text': 'Dhaka'},
                'secondaryText': <String, dynamic>{'text': 'Bangladesh'},
              },
            },
          },
        ],
      },
      'errors': <dynamic>[],
    };

    test('predictions parse off the unwrapped body', () {
      final dynamic body = ApiClient.unwrapEnvelope(enveloped, 200);
      final PlaceAutocompleteResult result = PlaceAutocompleteResult.fromBody(body);

      expect(result.hasError, isFalse);
      expect(result.predictions.length, 1);
      final PredictionModel p = result.predictions.first;
      expect(p.description, 'Dhaka, Bangladesh');
      expect(p.placeId, 'ChIJgUbEo8cfqokR5lP9_Wh_DaM');
      expect(p.structuredFormat?.mainText?.text, 'Dhaka');
      expect(p.structuredFormat?.secondaryText?.text, 'Bangladesh');
      expect(p.types, <String>['locality', 'political']);
    });

    test('a queryPrediction entry is skipped without losing the place ones', () {
      // Places (New) mixes both kinds into `suggestions`; the old chained read
      // threw on the queryPrediction and discarded every result with it.
      final PlaceAutocompleteResult result = PlaceAutocompleteResult.fromBody(<String, dynamic>{
        'suggestions': <dynamic>[
          <String, dynamic>{'queryPrediction': <String, dynamic>{'text': <String, dynamic>{'text': 'dhaka restaurants'}}},
          (enveloped['content'] as Map<String, dynamic>)['suggestions']![0],
        ],
      });

      expect(result.predictions.length, 1);
      expect(result.predictions.first.description, 'Dhaka, Bangladesh');
    });

    test('a prediction missing optional fields still parses', () {
      final PlaceAutocompleteResult result = PlaceAutocompleteResult.fromBody(<String, dynamic>{
        'suggestions': <dynamic>[
          <String, dynamic>{'placePrediction': <String, dynamic>{'placeId': 'abc'}},
        ],
      });

      expect(result.predictions.length, 1);
      expect(result.predictions.first.placeId, 'abc');
      expect(result.predictions.first.description, isNull);
      expect(result.predictions.first.types, isEmpty);
      expect(result.predictions.first.structuredFormat, isNull);
    });

    test('no matches is an empty list, not an error', () {
      final PlaceAutocompleteResult result =
          PlaceAutocompleteResult.fromBody(<String, dynamic>{'suggestions': <dynamic>[]});
      expect(result.hasError, isFalse);
      expect(result.predictions, isEmpty);
    });

    test('a body with no suggestions key is empty, not a crash', () {
      expect(PlaceAutocompleteResult.fromBody(<String, dynamic>{}).predictions, isEmpty);
      expect(PlaceAutocompleteResult.fromBody(null).predictions, isEmpty);
      expect(PlaceAutocompleteResult.fromBody('not json').predictions, isEmpty);
      expect(PlaceAutocompleteResult.fromBody(<String, dynamic>{'suggestions': 'nope'}).predictions, isEmpty);
    });
  });
}
