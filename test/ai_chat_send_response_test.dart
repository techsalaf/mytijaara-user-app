import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/ai_chat_bot/domain/models/ai_chat_message_model.dart';

/// What `POST customer/ai-chat/send` answers with, and how the reply is read.
///
/// The endpoint answers `201 Created`, not `200`. The controller used to gate its
/// success branch on `statusCode == 200`, so every reply fell through to the failure
/// path: the assistant's message was never appended and the customer's own message was
/// rolled back off the list, leaving the chat looking as though nothing had been sent.

/// The live 201 body, shape intact.
const String _sendBody = '''
{"id":64,"conversation_id":9,"role":"assistant",
 "content":"I'm sorry, I couldn't process that right now. Please try again.",
 "tool_name":null,
 "metadata":{"products":[],"stores":[],"categories":[],"cart_items":[],"bogo_offers":[],
   "bundles":[],"cart_updated":false,"cart":{"stores":[],"grand_total":0,"total_items":0}},
 "created_at":"2026-09-22T05:06:03.000000Z"}''';

void main() {
  group('the status the send endpoint answers with', () {
    test('201 counts as success', () {
      expect(ApiClient.isSuccessCode(201), isTrue);
    });

    test('the whole 2xx range counts, and nothing outside it', () {
      expect(ApiClient.isSuccessCode(200), isTrue);
      expect(ApiClient.isSuccessCode(204), isTrue);
      expect(ApiClient.isSuccessCode(299), isTrue);
      expect(ApiClient.isSuccessCode(400), isFalse);
      expect(ApiClient.isSuccessCode(500), isFalse);
      expect(ApiClient.isSuccessCode(null), isFalse);
    });
  });

  group('the reply the send endpoint returns', () {
    final AiChatMessage message =
        AiChatMessage.fromJson(jsonDecode(_sendBody) as Map<String, dynamic>);

    test('reads as the assistant, not the customer', () {
      expect(message.isAssistant, isTrue);
      expect(message.isUser, isFalse);
    });

    test('carries the text the bubble renders', () {
      expect(message.content, "I'm sorry, I couldn't process that right now. Please try again.");
    });

    test('carries the conversation it belongs to, so a new chat can adopt the id', () {
      expect(message.conversationId, 9);
    });

    test('a metadata block of empty lists parses without throwing', () {
      // The append sits inside a bare `catch (_)`, so anything thrown here would be
      // indistinguishable from the bug this file guards.
      expect(message.metadata, isNotNull);
      expect(message.metadata!.cartUpdated, isFalse);
      expect(message.metadata!.products, isEmpty);
      expect(message.metadata!.stores, isEmpty);
    });

    test('a null tool_name is carried as null rather than refused', () {
      expect(message.toolName, isNull);
    });
  });
}
