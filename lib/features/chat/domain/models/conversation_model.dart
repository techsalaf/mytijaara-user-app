import 'package:sixam_mart/api/response_parser.dart';
import 'package:sixam_mart/common/models/pagination_model.dart';
import 'package:sixam_mart/features/chat/domain/models/chat_model.dart';

class ConversationsModel {
  int? totalSize;
  int? limit;
  int? offset;
  List<Conversation?>? conversations;

  ConversationsModel({this.totalSize, this.limit, this.offset, this.conversations});

  ConversationsModel.fromJson(Map<String, dynamic> json) {
    // Paging arrives flat (`total_size`/`limit`/`offset`) on the legacy format
    // and nested under `pagination` now. Property names are unchanged, so no
    // caller needs an edit.
    final PaginationModel _pg = PaginationModel.fromJson(json);
    totalSize = _pg.totalSize;
    limit = _pg.limit;
    offset = _pg.offset;
    // The list moved to `data` in the new API format. `listOf` checks the legacy
    // key first, so a backend still answering with `conversations` parses exactly as before
    // and only the new shape is newly understood.
    final List<dynamic>? conversationEntries = ResponseParser.listOf(json, legacyKey: 'conversations');
    if (conversationEntries != null) {
      conversations = <Conversation?>[];
      for (final dynamic v in conversationEntries) {
        conversations!.add(Conversation.fromJson(v));
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_size'] = totalSize;
    data['limit'] = limit;
    data['offset'] = offset;
    if (conversations != null) {
      data['conversations'] = conversations!.map((v) => v!.toJson()).toList();
    }
    return data;
  }
}

class Conversation {
  int? id;
  int? senderId;
  String? senderType;
  int? receiverId;
  String? receiverType;
  int? unreadMessageCount;
  int? lastMessageId;
  String? lastMessageTime;
  String? createdAt;
  String? updatedAt;
  User? sender;
  User? receiver;
  Message? lastMessage;

  Conversation({
    this.id,
    this.senderId,
    this.senderType,
    this.receiverId,
    this.receiverType,
    this.unreadMessageCount,
    this.lastMessageId,
    this.lastMessageTime,
    this.createdAt,
    this.updatedAt,
    this.sender,
    this.receiver,
    this.lastMessage,
  });

  Conversation.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    senderId = json['sender_id'];
    senderType = json['sender_type'];
    receiverId = json['receiver_id'];
    receiverType = json['receiver_type'];
    unreadMessageCount = json['unread_message_count'];
    lastMessageId = json['last_message_id'];
    lastMessageTime = json['last_message_time'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    sender = json['sender'] != null ? User.fromJson(json['sender']) : null;
    receiver = json['receiver'] != null ? User.fromJson(json['receiver']) : null;
    lastMessage = json['last_message'] != null ? Message.fromJson(json['last_message']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['sender_id'] = senderId;
    data['sender_type'] = senderType;
    data['receiver_id'] = receiverId;
    data['receiver_type'] = receiverType;
    data['unread_message_count'] = unreadMessageCount;
    data['last_message_id'] = lastMessageId;
    data['last_message_time'] = lastMessageTime;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (sender != null) {
      data['sender'] = sender!.toJson();
    }
    if (receiver != null) {
      data['receiver'] = receiver!.toJson();
    }
    if (lastMessage != null) {
      data['last_message'] = lastMessage!.toJson();
    }
    return data;
  }
}

class User {
  int? id;
  String? fName;
  String? lName;
  String? phone;
  String? email;
  String? imageFullUrl;
  String? createdAt;
  String? updatedAt;

  User({this.id, this.fName, this.lName, this.phone, this.email, this.imageFullUrl, this.createdAt, this.updatedAt});

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    fName = json['f_name'];
    lName = json['l_name'];
    phone = json['phone'];
    email = json['email'];
    imageFullUrl = json['image_full_url'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['f_name'] = fName;
    data['l_name'] = lName;
    data['phone'] = phone;
    data['email'] = email;
    data['image_full_url'] = imageFullUrl;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
