import 'package:sixam_mart/common/models/pagination_model.dart';

class AiChatConversationModel {
  int? totalSize;
  int? limit;
  int? offset;
  List<AiChatConversation>? data;

  AiChatConversationModel({
    this.totalSize,
    this.limit,
    this.offset,
    this.data,
  });

  AiChatConversationModel.fromJson(Map<String, dynamic> json) {
    // Paging arrives flat on the legacy format and nested under `pagination`
    // now. Property names are unchanged, so no caller needs an edit.
    final PaginationModel _pg = PaginationModel.fromJson(json);
    totalSize = _pg.totalSize;
    limit = _pg.limit;
    offset = _pg.offset;
    if (json['data'] != null) {
      data = <AiChatConversation>[];
      json['data'].forEach((v) {
        data!.add(AiChatConversation.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_size'] = totalSize;
    data['limit'] = limit;
    data['offset'] = offset;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class AiChatConversation {
  int? id;
  int? userId;
  int? guestId;
  int? moduleId;
  int? zoneId;
  String? title;
  String? status;
  String? createdAt;
  String? updatedAt;
  int? messagesCount;

  AiChatConversation({
    this.id,
    this.userId,
    this.guestId,
    this.moduleId,
    this.zoneId,
    this.title,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.messagesCount,
  });

  AiChatConversation.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    guestId = int.tryParse(json['guest_id']??'0');
    moduleId = json['module_id'];
    zoneId = json['zone_id'];
    title = json['title'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    messagesCount = json['messages_count'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['user_id'] = userId;
    data['guest_id'] = guestId;
    data['module_id'] = moduleId;
    data['zone_id'] = zoneId;
    data['title'] = title;
    data['status'] = status;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['messages_count'] = messagesCount;
    return data;
  }
}
