import 'package:get/get.dart';
import 'package:sixam_mart/features/ai_chat_bot/domain/models/ai_chat_conversation_model.dart';
import 'package:sixam_mart/features/ai_chat_bot/domain/models/ai_chat_message_model.dart';

abstract class AiChatBotServiceInterface {
  Future<AiChatConversationModel?> getConversationList({required int offset, int limit = 20});
  Future<AiChatMessageModel?> getMessages({required int conversationId, required int offset, int limit = 20});
  Future<Response> sendMessage({required String message, int? conversationId});
  Future<bool> deleteConversation({required int conversationId});
}
