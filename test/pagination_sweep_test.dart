import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/api/json_reader.dart';
import 'package:sixam_mart/common/models/pagination_model.dart';
import 'package:sixam_mart/features/chat/domain/models/conversation_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_review_model.dart';
import 'package:sixam_mart/features/order/domain/models/monthly_order_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_cancellation_body.dart';
import 'package:sixam_mart/features/order/domain/models/support_model.dart';
import 'package:sixam_mart/features/parcel/domain/models/parcel_instruction_model.dart';
import 'package:sixam_mart/features/search/domain/models/top_category_model.dart';

/// Covers the paging sweep: every list wrapper now reads `PaginationModel`,
/// which accepts the nested `pagination` object **and** the flat
/// `total_size`/`limit`/`offset` keys.
///
/// Both are asserted for each model, because both are live at once — the core
/// API moved to `pagination` while the service module still sends flat keys, and
/// the app has to run against either.
void main() {
  /// The two payload shapes carrying identical paging values.
  Map<String, dynamic> nested(Map<String, dynamic> extra) => <String, dynamic>{
        ...extra,
        'pagination': <String, dynamic>{
          'current_page': 3, 'last_page': 9, 'per_page': 10, 'total': 87, 'from': 21, 'to': 30,
        },
      };
  Map<String, dynamic> flat(Map<String, dynamic> extra) => <String, dynamic>{
        ...extra,
        'total_size': 87, 'limit': 10, 'offset': 3,
      };

  group('PaginationModel reads both shapes identically', () {
    test('nested and flat agree on every property the app uses', () {
      final PaginationModel a = PaginationModel.fromJson(nested(<String, dynamic>{}));
      final PaginationModel b = PaginationModel.fromJson(flat(<String, dynamic>{}));
      expect(a.totalSize, 87);
      expect(a.limit, 10);
      expect(a.offset, 3, reason: 'current_page maps onto the app\'s 1-based offset');
      expect(a.lastPage, 9);
      expect(<int?>[b.totalSize, b.limit, b.offset], <int?>[a.totalSize, a.limit, a.offset]);
    });

    test('a body with no paging yields nulls rather than throwing', () {
      final PaginationModel p = PaginationModel.fromJson(<String, dynamic>{'data': <dynamic>[]});
      expect(p.totalSize, isNull);
      expect(p.offset, isNull);
    });
  });

  group('swept models read paging from either shape', () {
    test('OrderCancellationBody', () {
      for (final Map<String, dynamic> body in <Map<String, dynamic>>[nested(<String, dynamic>{}), flat(<String, dynamic>{})]) {
        final OrderCancellationBody m = OrderCancellationBody.fromJson(body);
        expect(m.totalSize, 87);
        expect(m.limit, '10', reason: 'declared String? — value is stringified, not dropped');
        expect(m.offset, '3');
      }
    });

    test('SupportModel', () {
      for (final Map<String, dynamic> body in <Map<String, dynamic>>[nested(<String, dynamic>{}), flat(<String, dynamic>{})]) {
        final SupportModel m = SupportModel.fromJson(body);
        expect(m.totalSize, 87);
        expect(m.limit, 10);
        expect(m.offset, 3);
      }
    });

    test('ConversationsModel', () {
      for (final Map<String, dynamic> body in <Map<String, dynamic>>[nested(<String, dynamic>{}), flat(<String, dynamic>{})]) {
        final ConversationsModel m = ConversationsModel.fromJson(body);
        expect(m.totalSize, 87);
        expect(m.offset, 3);
      }
    });

    test('MonthlyOrderModel', () {
      for (final Map<String, dynamic> body in <Map<String, dynamic>>[nested(<String, dynamic>{}), flat(<String, dynamic>{})]) {
        final MonthlyOrderModel m = MonthlyOrderModel.fromJson(body);
        expect(m.totalSize, 87);
        expect(m.limit, '10');
        expect(m.offset, 3);
      }
    });

    test('TopCategoryModel', () {
      for (final Map<String, dynamic> body in <Map<String, dynamic>>[nested(<String, dynamic>{}), flat(<String, dynamic>{})]) {
        final TopCategoryModel m = TopCategoryModel.fromJson(body);
        expect(m.totalSize, 87);
        expect(m.offset, 3);
      }
    });

    test('ItemReviewModel', () {
      for (final Map<String, dynamic> body in <Map<String, dynamic>>[nested(<String, dynamic>{}), flat(<String, dynamic>{})]) {
        final ItemReviewModel m = ItemReviewModel.fromJson(body);
        expect(m.totalSize, 87);
        expect(m.limit, '10');
      }
    });

    test('ParcelInstructionModel', () {
      for (final Map<String, dynamic> body in <Map<String, dynamic>>[nested(<String, dynamic>{}), flat(<String, dynamic>{})]) {
        final ParcelInstructionModel m = ParcelInstructionModel.fromJson(body);
        expect(m.totalSize, 87);
        expect(m.offset, '3');
      }
    });
  });

  group('JsonReader tolerates what force-conversion could not', () {
    test('reads numbers, numeric strings, and absence', () {
      expect(JsonReader.toDouble(12), 12.0);
      expect(JsonReader.toDouble(12.5), 12.5);
      expect(JsonReader.toDouble('12.5'), 12.5);
      expect(JsonReader.toDouble(null), isNull, reason: 'a dropped field must be null, never a crash');
      expect(JsonReader.toDouble('not a number'), isNull);
    });

    test('toInt truncates like num.toInt and parses strings', () {
      expect(JsonReader.toInt(3), 3);
      expect(JsonReader.toInt(3.9), 3);
      expect(JsonReader.toInt('42'), 42);
      expect(JsonReader.toInt(null), isNull);
    });

    test('toStr guards String? fields against an int arriving', () {
      // storage[].data_id changed from string to int and threw a type error
      // that took down the whole rental vehicle list.
      expect(JsonReader.toStr(66), '66');
      expect(JsonReader.toStr('66'), '66');
      expect(JsonReader.toStr(null), isNull);
    });
  });
}
