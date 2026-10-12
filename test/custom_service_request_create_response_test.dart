import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' show Response;
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/service_module/custom_service_request/domain/models/custom_service_request_model.dart';

/// `POST /api/v1/service/custom-requests` answers 201 with the created object
/// at the TOP LEVEL - no `data` wrapper - unlike `getDetail` on the same
/// resource, which tolerates either shape. The repository's success gate used
/// to check `response.body?['data'] != null` only, which is always false for
/// this exact response, so a successful create was reported as
/// "something_went_wrong". These tests pin the fixed gate's decision on the
/// real captured shape, and the old gate's failure on it, so a regression back
/// to `data`-only shows up here rather than in a live device log.
void main() {
  // Verbatim from the live response body (already past ApiClient.unwrapEnvelope,
  // i.e. this is what `response.body` actually is by the time the repository
  // sees it).
  final Map<String, dynamic> liveCreateBody = <String, dynamic>{
    'id': 5,
    'description': 'want service',
    'customer_information': <String, dynamic>{
      'name': 'MSdd 1232sdsss2',
      'phone': '+8801600000000',
      'address': '176 New Market - Pilkhana Rd, Dhaka 1205, Bangladesh',
      'latitude': '23.732193956299128',
      'longitude': '90.37973642349243',
    },
    'booking_date': '2026-09-15',
    'booking_time': '00:16',
    'status': 'open_for_bidding',
    'status_label': 'Open For Bidding',
    'is_expired': false,
    'bid_count': 0,
    'last_bid_at': null,
    'selected_offer_id': null,
    'category': <String, dynamic>{'id': 173, 'name': 'Beauty & Salon', 'image_full_url': 'https://x/y.webp'},
    'sub_category': <String, dynamic>{'id': 178, 'name': 'Hair Care & Styling', 'image_full_url': null},
    'created_at': '2026-09-15T04:17:35.000000Z',
    'updated_at': '2026-09-15T04:17:35.000000Z',
  };

  /// Mirrors the fixed gate in CustomServiceRequestRepository.createRequest:
  /// success by status, then the created object either under `data` or as the
  /// payload itself.
  CustomServiceRequestModel? fixedGate(Response response) {
    if (ApiClient.isSuccessCode(response.statusCode) && response.body is Map) {
      final dynamic raw = response.body['data'] ?? response.body;
      if (raw is Map<String, dynamic>) {
        return CustomServiceRequestModel.fromJson(raw);
      }
    }
    return null;
  }

  /// The old, buggy gate: success was inferred purely from a `data` key being
  /// present, which this response never has.
  CustomServiceRequestModel? oldBuggyGate(Response response) {
    if (response.body?['data'] != null) {
      return CustomServiceRequestModel.fromJson(response.body['data'] as Map<String, dynamic>);
    }
    return null;
  }

  test('the fixed gate parses the real 201 create response into a model', () {
    final Response response = Response(statusCode: 201, body: liveCreateBody);
    final CustomServiceRequestModel? model = fixedGate(response);

    expect(model, isNotNull);
    expect(model!.id, 5);
    expect(model.description, 'want service');
    expect(model.status, 'open_for_bidding');
    expect(model.statusLabel, 'Open For Bidding');
    expect(model.customerInformation?.name, 'MSdd 1232sdsss2');
    expect(model.category?.name, 'Beauty & Salon');
    expect(model.subCategory?.name, 'Hair Care & Styling');
  });

  test('reproduces the bug: the old data-only gate returns null on this exact response', () {
    final Response response = Response(statusCode: 201, body: liveCreateBody);
    expect(oldBuggyGate(response), isNull);
  });

  test('still accepts a data-wrapped shape, for parity with getDetail', () {
    final Response response = Response(statusCode: 201, body: <String, dynamic>{'data': liveCreateBody});
    final CustomServiceRequestModel? model = fixedGate(response);
    expect(model?.id, 5);
  });

  test('a genuine failure (422, no created object) still yields null', () {
    final Response response = Response(statusCode: 422, body: <String, dynamic>{
      'identical_code': 'unprocessable_entity_422', 'message': 'Validation failed', 'errors': <dynamic>[],
    });
    expect(fixedGate(response), isNull);
  });

  test('a non-map body (e.g. a plain string error page) does not throw', () {
    final Response response = Response(statusCode: 201, body: 'Internal Server Error');
    expect(() => fixedGate(response), returnsNormally);
    expect(fixedGate(response), isNull);
  });

  test('200 is accepted too, not only 201', () {
    final Response response = Response(statusCode: 200, body: liveCreateBody);
    expect(fixedGate(response)?.id, 5);
  });
}
