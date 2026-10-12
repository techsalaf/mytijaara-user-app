import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/features/ai_chat_bot/domain/models/ai_chat_message_model.dart';

/// The BOGO and bundle blocks the chat's `metadata` carries.
///
/// The live payload only ever showed these as empty arrays, so the rows here are the
/// shape the app's own `bogo/list` and `bundle/list` endpoints answer with — which is
/// what the chat is expected to embed. If the backend sends something else, these are
/// the assertions that will say so.

AiChatMetadata _metadata(String raw) =>
    AiChatMetadata.fromJson(jsonDecode(raw) as Map<String, dynamic>);

/// The reported body's metadata: every block present, every block empty.
const String _emptyBlocks = '''
{"products":[],"stores":[],"categories":[],"cart_items":[],"bogo_offers":[],"bundles":[],
 "happy_hours":[],"cart_updated":false,"cart":{"stores":[],"grand_total":0,"total_items":0}}''';

/// The `GetHappyHourTool` reply, shape intact.
const String _happyHours = '''
{"products":[],"stores":[],"categories":[],"cart_items":[],"bogo_offers":[],"bundles":[],
 "happy_hours":[{"id":6,"slug":"asd-asf-asdf","title":"asd asf asdf",
   "short_description":"asd asf asdf","cover_image_full_url":"https://cdn.test/hh/cover.webp",
   "icon_full_url":"https://cdn.test/hh/icon.webp","module_id":4,"discount":10,
   "min_order_amount":100,"duration_type":"daily","is_permanent":false,"weekly_days":[],
   "start_time":"12:30:00","end_time":"13:30:00","start_date":"2026-09-17","end_date":"2026-09-30",
   "is_running_now":true,"started_at":"2026-09-22 12:30:00","ends_at":"2026-09-22 13:30:00",
   "remaining_seconds":1072,"store_count":1}],
 "cart_updated":false,"cart":{"stores":[],"grand_total":0,"total_items":0}}''';

const String _populated = '''
{"products":[],"stores":[],"categories":[],"cart_updated":false,
 "bogo_offers":[
   {"id":7,"slug":"buy-one-get-one-pizza","title":"Buy one get one pizza",
    "description":"On every large pizza","image_full_url":"https://cdn.test/bogo/7.png",
    "buy_qty":1,"get_qty":1,"offer_label":"BUY 1 GET 1","module_id":3}],
 "bundles":[
   {"id":12,"name":"Breakfast combo","slug":"breakfast-combo",
    "image_full_url":"https://cdn.test/bundle/12.png","store_id":4,"store_name":"Cafe Rio",
    "module_id":3,"item_count":3,"base_price":600,"bundle_price":450,"final_price":450,
    "discount_percentage":25,"discount_amount":150,"is_happy_hour":false,"is_available":true}]}''';

void main() {
  group('a metadata block with nothing in it', () {
    final AiChatMetadata metadata = _metadata(_emptyBlocks);

    test('offers and bundles read as absent, so no strip is drawn', () {
      expect(metadata.hasBogoOffers, isFalse);
      expect(metadata.hasBundles, isFalse);
      expect(metadata.hasHappyHours, isFalse);
    });

    test('the whole block still counts as empty, so the bubble draws nothing', () {
      // `isEmpty` is what `AiChatMessageBubbleWidget` gates the metadata view on.
      expect(metadata.isEmpty, isTrue);
    });
  });

  group('a metadata block carrying offers and bundles', () {
    final AiChatMetadata metadata = _metadata(_populated);

    test('the bubble draws the view even when products and stores are empty', () {
      expect(metadata.isEmpty, isFalse);
    });

    test('a BOGO offer keeps what the card renders', () {
      expect(metadata.hasBogoOffers, isTrue);
      final AiChatBogoOffer row = metadata.bogoOffers!.single;
      expect(row.offer.title, 'Buy one get one pizza');
      expect(row.offer.slug, 'buy-one-get-one-pizza');
      expect(row.offer.offerLabel, 'BUY 1 GET 1');
      expect(row.offer.imageFullUrl, 'https://cdn.test/bogo/7.png');
    });

    test('a BOGO offer carries its module, which the card has no slot for', () {
      // Without it the offer opens under whichever module is active, and a
      // cross-module recommendation answers empty.
      expect(metadata.bogoOffers!.single.moduleId, 3);
    });

    test('a bundle keeps what the card renders and what its sheet is opened with', () {
      expect(metadata.hasBundles, isTrue);
      final bundle = metadata.bundles!.single;
      expect(bundle.id, 12);
      expect(bundle.name, 'Breakfast combo');
      expect(bundle.storeId, 4);
      expect(bundle.finalPrice, 450);
      expect(bundle.basePrice, 600);
    });
  });

  group('a metadata block carrying happy hours', () {
    final AiChatMetadata metadata = _metadata(_happyHours);

    test('the bubble draws the view on a happy-hour-only reply', () {
      expect(metadata.isEmpty, isFalse);
      expect(metadata.hasHappyHours, isTrue);
    });

    test('the row keeps what the card renders', () {
      final happyHour = metadata.happyHours!.single;
      expect(happyHour.title, 'asd asf asdf');
      expect(happyHour.discount, 10);
      expect(happyHour.storeCount, 1);
      expect(happyHour.coverImageFullUrl, 'https://cdn.test/hh/cover.webp');
      expect(happyHour.isRunningNow, isTrue);
    });

    test('the row carries its module, which the tap switches to', () {
      expect(metadata.happyHours!.single.moduleId, 4);
    });
  });

  group('rows the chat sends malformed', () {
    test('a bad row is dropped without taking the rest of the strip with it', () {
      // `BogoOfferCardModel.fromJson` assigns `id` straight to an `int?`, so a string
      // id throws — the per-row catch is what keeps the good row renderable.
      final AiChatMetadata metadata = _metadata(
        '{"bogo_offers":[{"id":"seven","title":"Bad row"},{"id":8,"title":"Good row"}]}',
      );
      expect(metadata.bogoOffers!.length, 1);
      expect(metadata.bogoOffers!.single.offer.title, 'Good row');
    });

    test('a block that is not a list is ignored rather than throwing', () {
      final AiChatMetadata metadata = _metadata('{"bogo_offers":null,"bundles":"none"}');
      expect(metadata.hasBogoOffers, isFalse);
      expect(metadata.hasBundles, isFalse);
    });
  });
}
