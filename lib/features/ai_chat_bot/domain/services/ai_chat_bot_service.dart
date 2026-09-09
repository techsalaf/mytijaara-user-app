import 'package:get/get.dart';
import 'package:sixam_mart/features/ai_chat_bot/domain/models/ai_chat_conversation_model.dart';
import 'package:sixam_mart/features/ai_chat_bot/domain/models/ai_chat_message_model.dart';
import 'package:sixam_mart/features/ai_chat_bot/domain/repositories/ai_chat_bot_repository_interface.dart';
import 'package:sixam_mart/features/ai_chat_bot/domain/services/ai_chat_bot_service_interface.dart';

class AiChatBotService implements AiChatBotServiceInterface {
  final AiChatBotRepositoryInterface aiChatBotRepositoryInterface;
  AiChatBotService({required this.aiChatBotRepositoryInterface});

  @override
  Future<AiChatConversationModel?> getConversationList({required int offset, int limit = 20}) async {
    return await aiChatBotRepositoryInterface.getConversationList(offset: offset, limit: limit);
  }

  @override
  Future<AiChatMessageModel?> getMessages({required int conversationId, required int offset, int limit = 20}) async {
    return await aiChatBotRepositoryInterface.getMessages(conversationId: conversationId, offset: offset, limit: limit);
  }

  @override
  Future<Response> sendMessage({required String message, int? conversationId}) async {
    return await aiChatBotRepositoryInterface.sendMessage(message: message, conversationId: conversationId);
  }

  @override
  Future<bool> deleteConversation({required int conversationId}) async {
    return await aiChatBotRepositoryInterface.deleteConversation(conversationId: conversationId);
  }

}
