import 'package:get/get.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/ai_chat_bot/domain/models/ai_chat_conversation_model.dart';
import 'package:sixam_mart/features/ai_chat_bot/domain/models/ai_chat_message_model.dart';
import 'package:sixam_mart/features/ai_chat_bot/domain/repositories/ai_chat_bot_repository_interface.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';

class AiChatBotRepository implements AiChatBotRepositoryInterface {
  final ApiClient apiClient;
  AiChatBotRepository({required this.apiClient});

  String get _guestIdQuerySuffix => !AuthHelper.isLoggedIn() ? '&guest_id=${AuthHelper.getGuestId()}' : '';

  @override
  Future<AiChatConversationModel?> getConversationList({required int offset, int limit = 20}) async {
    AiChatConversationModel? conversationModel;
    Response response = await apiClient.getData(
      '${AppConstants.aiChatConversationListUri}?limit=$limit&offset=$offset$_guestIdQuerySuffix',
    );
    if (response.statusCode == 200) {
      conversationModel = AiChatConversationModel.fromJson(response.body);
    }
    return conversationModel;
  }

  @override
  Future<AiChatMessageModel?> getMessages({required int conversationId, required int offset, int limit = 20}) async {
    AiChatMessageModel? messageModel;
    Response response = await apiClient.getData(
      '${AppConstants.aiChatMessagesUri}?conversation_id=$conversationId&limit=$limit&offset=$offset$_guestIdQuerySuffix',
    );
    if (response.statusCode == 200) {
      messageModel = AiChatMessageModel.fromJson(response.body);
    }
    return messageModel;
  }

  @override
  Future<Response> sendMessage({required String message, int? conversationId}) async {
    final Map<String, dynamic> body = {'message': message};
    if (conversationId != null) {
      body['conversation_id'] = conversationId;
    }
    if (!AuthHelper.isLoggedIn()) {
      body['guest_id'] = AuthHelper.getGuestId();
    }
    return await apiClient.postData(AppConstants.aiChatSendMessageUri, body);
  }

  @override
  Future<bool> deleteConversation({required int conversationId}) async {
    final String guestSuffix = !AuthHelper.isLoggedIn() ? '?guest_id=${AuthHelper.getGuestId()}' : '';
    Response response = await apiClient.deleteData(
      '${AppConstants.aiChatConversationListUri}/$conversationId$guestSuffix',
    );
    return response.statusCode == 200;
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    throw UnimplementedError();
  }

  @override
  Future get(String? id) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }

  @override
  Future getList({int? offset}) {
    throw UnimplementedError();
  }

}
