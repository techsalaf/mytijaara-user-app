import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/ai_chat_bot/domain/models/ai_chat_conversation_model.dart';
import 'package:sixam_mart/features/ai_chat_bot/domain/models/ai_chat_message_model.dart';
import 'package:sixam_mart/features/ai_chat_bot/domain/services/ai_chat_bot_service_interface.dart';

class AiChatBotController extends GetxController implements GetxService {
  final AiChatBotServiceInterface aiChatBotServiceInterface;
  AiChatBotController({required this.aiChatBotServiceInterface});

  AiChatConversationModel? _conversationModel;
  AiChatConversationModel? get conversationModel => _conversationModel;

  AiChatMessageModel? _messageModel;
  AiChatMessageModel? get messageModel => _messageModel;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSendingMessage = false;
  bool get isSendingMessage => _isSendingMessage;

  bool _isSendButtonActive = false;
  bool get isSendButtonActive => _isSendButtonActive;

  final Set<int> _deletingIds = <int>{};
  bool isDeleting(int conversationId) => _deletingIds.contains(conversationId);

  Future<void> getConversationList(int offset, {bool reload = false}) async {
    if(reload || offset == 1) {
      _conversationModel = null;
    }

    AiChatConversationModel? conversationModel = await aiChatBotServiceInterface.getConversationList(offset: offset);

    if(conversationModel != null) {
      if(offset == 1) {
        _conversationModel = conversationModel;
      } else {
        _conversationModel!.totalSize = conversationModel.totalSize;
        _conversationModel!.offset = conversationModel.offset;
        _conversationModel!.data!.addAll(conversationModel.data ?? []);
      }
    }
    update();
  }

  Future<void> getMessages(int conversationId, int offset, {bool firstLoad = false, bool silent = false}) async {
    if((firstLoad || offset == 1) && !silent) {
      _messageModel = null;
      // update();
    }

    AiChatMessageModel? messageModel = await aiChatBotServiceInterface.getMessages(
      conversationId: conversationId, offset: offset,
    );

    if(messageModel != null) {
      if(offset == 1) {
        _messageModel = messageModel;
      } else {
        _messageModel!.totalSize = messageModel.totalSize;
        _messageModel!.offset = messageModel.offset;
        _messageModel!.messages!.addAll(messageModel.messages ?? []);
      }
    }
    update();
  }

  Future<Response?> sendMessage({
    required String message,
    int? conversationId,
    ValueChanged<int>? onConversationIdAssigned,
  }) async {
    if(message.trim().isEmpty || _isSendingMessage) {
      return null;
    }

    _isSendingMessage = true;

    _messageModel ??= AiChatMessageModel(messages: [], totalSize: 0, offset: 1, limit: 20);
    _messageModel!.messages ??= [];

    final AiChatMessage userMessage = AiChatMessage(
      conversationId: conversationId,
      role: 'user',
      content: message,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
    _messageModel!.messages!.insert(0, userMessage);
    _messageModel!.totalSize = (_messageModel!.totalSize ?? 0) + 1;
    update();

    Response? response;
    try {
      response = await aiChatBotServiceInterface.sendMessage(
        message: message, conversationId: conversationId,
      );
    } catch (_) {
      response = null;
    }

    if (response != null && response.statusCode == 200 && response.body is Map<String, dynamic>) {
      final Map<String, dynamic> body = response.body as Map<String, dynamic>;

      final dynamic newId = body['conversation_id'];
      if (newId is int) {
        userMessage.conversationId = newId;
        if (conversationId == null) {
          onConversationIdAssigned?.call(newId);
        }
      }

      if (body['role'] != null) {
        try {
          final AiChatMessage assistantMessage = AiChatMessage.fromJson(body);
          assistantMessage.createdAt ??= DateTime.now().toUtc().toIso8601String();
          _messageModel!.messages!.insert(0, assistantMessage);
          _messageModel!.totalSize = (_messageModel!.totalSize ?? 0) + 1;
        } catch (_) {}
      }
    } else {
      _messageModel!.messages!.remove(userMessage);
      final int currentTotal = _messageModel!.totalSize ?? 0;
      _messageModel!.totalSize = currentTotal > 0 ? currentTotal - 1 : 0;
    }

    _isSendingMessage = false;
    update();
    return response;
  }

  Future<bool> deleteConversation(int conversationId) async {
    if (_deletingIds.contains(conversationId)) {
      return false;
    }
    _deletingIds.add(conversationId);
    update();

    final bool success = await aiChatBotServiceInterface.deleteConversation(conversationId: conversationId);

    if (success && _conversationModel?.data != null) {
      _conversationModel!.data!.removeWhere((c) => c.id == conversationId);
      final int currentTotal = _conversationModel!.totalSize ?? 0;
      _conversationModel!.totalSize = currentTotal > 0 ? currentTotal - 1 : 0;
    }

    _deletingIds.remove(conversationId);
    update();
    return success;
  }

  void toggleSendButtonActivity(bool active) {
    if (_isSendButtonActive != active) {
      _isSendButtonActive = active;
      update();
    }
  }

  void clearMessages() {
    _messageModel = null;
    _isSendButtonActive = false;
    _isSendingMessage = false;
  }

  void showBottomLoader() {
    _isLoading = true;
    update();
  }

}
