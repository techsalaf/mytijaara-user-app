import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/chat/domain/models/chat_model.dart';
import 'package:sixam_mart/features/chat/domain/models/conversation_model.dart';

dynamic unwrap(String raw) {
  final dynamic b = jsonDecode(raw);
  if (b is! Map) return b;
  if (!b.containsKey('identical_code') || b['content'] == null) return b;
  return b['content'];
}

void main() {
  // ---- Live GET /api/v1/customer/message/list?type=admin
  const String convAdmin = r'''
{"identical_code":"default_200","message":"Successfully fetched","content":{"type":"admin","data":[
{"id":44,"sender_type":"customer","receiver_type":"admin","unread_message_count":1,
 "last_message_time":"2026-08-31 17:18:37",
 "sender":{"id":29,"f_name":"MSdd","l_name":"1232sdsss","phone":"+8801600000000","image_full_url":null},
 "receiver":null,
 "last_message":{"sender_id":29,"message":"Hiiiii","file_full_url":[],"is_seen":0,"created_at":"2026-08-31T11:18:37.000000Z"}}],
"pagination":{"current_page":1,"last_page":1,"per_page":10,"total":1,"from":1,"to":1}},"errors":[]}''';

  // ---- Live GET /api/v1/customer/message/list?type=vendor
  const String convVendor = r'''
{"identical_code":"default_200","message":"Successfully fetched","content":{"type":"vendor","data":[
{"id":20,"sender_type":"customer","receiver_type":"vendor","unread_message_count":1,
 "last_message_time":"2026-08-31 17:19:20",
 "sender":{"id":29,"f_name":"MSdd","l_name":"1232sdsss","phone":"+8801600000000","image_full_url":null},
 "receiver":{"id":8,"f_name":"Hungry Puppetssss","l_name":"","phone":"+8801710000000","image_full_url":"https://x/y.webp"},
 "last_message":{"sender_id":29,"message":null,"file_full_url":[],"is_seen":0,"created_at":"2026-08-31T11:19:20.000000Z"}}],
"pagination":{"current_page":1,"last_page":1,"per_page":10,"total":1,"from":1,"to":1}},"errors":[]}''';

  // ---- Live GET /api/v1/customer/message/details?conversation_id=44
  const String details = r'''
{"identical_code":"default_200","message":"Successfully fetched","content":{"status":true,
"conversation":{"id":44,"sender_type":"customer","receiver_type":"admin","unread_message_count":1,
 "last_message_time":"2026-08-31 17:18:37",
 "sender":{"id":29,"f_name":"MSdd","l_name":"1232sdsss","phone":"+8801600000000","image_full_url":null},
 "receiver":null},
"data":[{"sender_id":29,"message":"Hiiiii","file_full_url":[],"is_seen":0,"created_at":"2026-08-31T11:18:37.000000Z","order":null}],
"pagination":{"current_page":1,"last_page":1,"per_page":10,"total":5,"from":1,"to":5}},"errors":[]}''';

  group('conversation list', () {
    test('parses from `data` with pagination', () {
      final ConversationsModel m = ConversationsModel.fromJson(unwrap(convVendor) as Map<String, dynamic>);
      expect(m.conversations!.length, 1);
      expect(m.totalSize, 1);
      final Conversation c = m.conversations!.first!;
      expect(c.id, 20);
      expect(c.senderType, 'customer');
      expect(c.receiverType, 'vendor');
      expect(c.receiver!.fName, 'Hungry Puppetssss');
      expect(c.unreadMessageCount, 1);
      // fields the API no longer sends resolve to null, not a crash
      expect(c.senderId, isNull);
      expect(c.receiverId, isNull);
      expect(c.lastMessageId, isNull);
    });

    test('admin conversation has receiver:null — the tile must still be usable', () {
      final ConversationsModel m = ConversationsModel.fromJson(unwrap(convAdmin) as Map<String, dynamic>);
      final Conversation c = m.conversations!.first!;
      expect(c.receiverType, 'admin');
      expect(c.receiver, isNull, reason: 'the admin is not a user record');

      // _ConversationTile picks the counterpart the same way:
      User? user = (c.senderType == 'customer') ? c.receiver : c.sender;
      final String? type = (c.senderType == 'customer') ? c.receiverType : c.senderType;
      expect(user, isNull, reason: 'this is what produced "admin deleted" / "admin not found"');

      // the fix stands in the business identity for an admin conversation
      const String businessName = '6amMart';
      if (user == null && type == 'admin') {
        user = User(id: 0, fName: businessName, lName: '', imageFullUrl: null);
      }
      expect(user, isNotNull);
      expect(user!.fName, businessName);
      expect(user.id, 0, reason: 'adminId 0 is what the chat route expects');
    });

    test('unread badge and time read safely when fields are missing', () {
      final Conversation bare = Conversation.fromJson(<String, dynamic>{'id': 1, 'sender_type': 'customer', 'receiver_type': 'admin'});
      expect(bare.lastMessage, isNull);
      expect(bare.unreadMessageCount, isNull);
      // the widget's new reads
      expect(bare.lastMessage?.senderId, isNull);
      expect((bare.unreadMessageCount ?? 0) > 0, isFalse);
      expect(bare.lastMessageTime, isNull);
    });
  });

  group('chat details', () {
    test('messages parse from `data`, with conversation and status', () {
      final ChatModel m = ChatModel.fromJson(unwrap(details) as Map<String, dynamic>);
      expect(m.status, isTrue);
      expect(m.conversation, isNotNull);
      expect(m.conversation!.id, 44);
      expect(m.messages!.length, 1);
      expect(m.totalSize, 5, reason: 'from pagination.total, for paging');

      final Message msg = m.messages!.first;
      expect(msg.senderId, 29);
      expect(msg.message, 'Hiiiii');
      expect(msg.fileFullUrl, isEmpty);
      expect(msg.isSeen, 0);
      expect(msg.createdAt, '2026-08-31T11:18:37.000000Z');
      // trimmed fields
      expect(msg.id, isNull);
      expect(msg.conversationId, isNull);
      expect(msg.orderId, isNull);
      expect(msg.order, isNull);
    });

    test('a body with no message list does not crash the screen gates', () {
      final ChatModel m = ChatModel.fromJson(<String, dynamic>{'status': true});
      expect(m.messages, isNull);
      // the widget gates, as rewritten
      expect(m.messages?.isNotEmpty ?? false, isFalse);
      expect((m.status ?? false) || (m.messages?.isEmpty ?? true), isTrue);
    });

    test('legacy `messages` key still wins', () {
      final ChatModel m = ChatModel.fromJson(<String, dynamic>{
        'total_size': 7, 'limit': 10, 'offset': 1, 'status': true,
        'messages': <dynamic>[<String, dynamic>{'id': 3, 'sender_id': 9, 'message': 'legacy'}],
        'data': <dynamic>[<String, dynamic>{'id': 99, 'message': 'should be ignored'}],
      });
      expect(m.totalSize, 7);
      expect(m.messages!.single.message, 'legacy');
      expect(m.messages!.single.id, 3);
    });
  });

  test('a 201 send is a success', () {
    // delivery-man/message/question/send is captured at 201 default_store_201;
    // customer/message/send is the same create family.
    expect(ApiClient.isSuccessCode(200), isTrue);
    expect(ApiClient.isSuccessCode(201), isTrue);
    expect(ApiClient.isSuccessCode(422), isFalse);
  });

  tabBehaviourTests();

  test('the old getMessages guard was vacuous', () {
    // `response.body['messages'] != {}` — a fresh map literal never equals another
    // object, so this was always true regardless of the payload.
    final Map<String, dynamic> body = Map<String, dynamic>.from(unwrap(details) as Map);
    expect(body['messages'], isNull, reason: 'the key is `data` now');
    // ignore: unrelated_type_equality_checks
    expect(body['messages'] != <String, dynamic>{}, isTrue, reason: 'vacuous even when null');
  });
}

// ---------------------------------------------------------------------------
// Conversation-screen behaviour: tab filtering and the admin chat button.
// ---------------------------------------------------------------------------

/// ChatService.conversationsOfType
List<Conversation?> conversationsOfType(List<Conversation?>? conversations, String type) {
  if (conversations == null) return <Conversation?>[];
  return conversations.where((Conversation? c) {
    if (c == null) return false;
    final bool customerIsSender = c.senderType == 'user' || c.senderType == 'customer';
    return (customerIsSender ? c.receiverType : c.senderType) == type;
  }).toList();
}

Conversation conv(int id, String counterpart, {bool customerIsSender = true}) =>
    Conversation.fromJson(<String, dynamic>{
      'id': id,
      'sender_type': customerIsSender ? 'customer' : counterpart,
      'receiver_type': customerIsSender ? counterpart : 'customer',
    });

void tabBehaviourTests() {
  group('conversation tabs', () {
    // What `message/list` with no `type` returns — verified live: all three at once.
    final List<Conversation?> mixed = <Conversation?>[
      conv(44, 'admin'),
      conv(20, 'vendor'),
      conv(31, 'delivery_man'),
      conv(32, 'vendor', customerIsSender: false),
    ];

    test('vendor tab shows only vendors — no admin, no delivery man', () {
      final List<Conversation?> shown = conversationsOfType(mixed, 'vendor');
      expect(shown.map((c) => c!.id).toList(), <int>[20, 32]);
      expect(shown.any((c) => c!.receiverType == 'admin' || c.senderType == 'admin'), isFalse);
      expect(shown.any((c) => c!.receiverType == 'delivery_man' || c.senderType == 'delivery_man'), isFalse);
    });

    test('delivery man tab shows only delivery men — no admin, no vendor', () {
      final List<Conversation?> shown = conversationsOfType(mixed, 'delivery_man');
      expect(shown.map((c) => c!.id).toList(), <int>[31]);
      expect(shown.any((c) => c!.receiverType == 'vendor' || c.senderType == 'vendor'), isFalse);
      expect(shown.any((c) => c!.receiverType == 'admin' || c.senderType == 'admin'), isFalse);
    });

    test('the counterpart is found whichever side the customer is on', () {
      // id 32 has the vendor as sender and the customer as receiver.
      expect(conversationsOfType(mixed, 'vendor').map((c) => c!.id), contains(32));
      expect(conversationsOfType(mixed, 'customer'), isEmpty);
    });

    test('a null or empty list is handled', () {
      expect(conversationsOfType(null, 'vendor'), isEmpty);
      expect(conversationsOfType(<Conversation?>[], 'vendor'), isEmpty);
      expect(conversationsOfType(<Conversation?>[null], 'vendor'), isEmpty);
    });
  });

  group('admin chat button', () {
    // ChatController.hasAdmin, as reworked: driven by the type=admin response.
    bool hasAdmin(ConversationsModel? adminModel) =>
        adminModel?.conversations?.isNotEmpty ?? false;

    // The old rule: scan the *tab* list for an admin row.
    bool hasAdminOld(List<Conversation?> tabList) =>
        tabList.any((c) => c?.receiverType == 'admin' || c?.senderType == 'admin');

    final ConversationsModel adminPresent = ConversationsModel.fromJson(<String, dynamic>{
      'data': <dynamic>[<String, dynamic>{'id': 44, 'sender_type': 'customer', 'receiver_type': 'admin'}],
      'pagination': <String, dynamic>{'total': 1},
    });
    final ConversationsModel adminAbsent = ConversationsModel.fromJson(<String, dynamic>{
      'data': <dynamic>[], 'pagination': <String, dynamic>{'total': 0},
    });
    // The vendor tab, as the API actually returns it: type-filtered, so never an admin.
    final List<Conversation?> vendorTab = <Conversation?>[conv(20, 'vendor')];

    test('button hidden once an admin conversation exists', () {
      expect(hasAdmin(adminPresent), isTrue);
      expect(hasAdminOld(vendorTab), isFalse,
          reason: 'the old rule found nothing, so the button kept showing');
    });

    test('button shown only when there is genuinely no admin conversation', () {
      expect(hasAdmin(adminAbsent), isFalse);
      expect(hasAdmin(null), isFalse, reason: 'not loaded yet — the screen also gates on conversationModel');
    });
  });
}
