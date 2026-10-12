import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/common/widgets/not_logged_in_screen.dart';
import 'package:sixam_mart/common/widgets/paginated_list_view.dart';
import 'package:sixam_mart/features/chat/controllers/chat_controller.dart';
import 'package:sixam_mart/features/chat/domain/models/conversation_model.dart';
import 'package:sixam_mart/features/chat/enums/user_type_enum.dart';
import 'package:sixam_mart/features/chat/widgets/chat_avatar_widget.dart';
import 'package:sixam_mart/features/chat/widgets/chat_serach_field_widget.dart';
import 'package:sixam_mart/features/chat/widgets/web_chat_view_widget.dart';
import 'package:sixam_mart/features/chat/widgets/web_conversation_list_view_widget.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class ConversationScreen extends StatefulWidget {
  final bool fromNavBar;
  const ConversationScreen({super.key, this.fromNavBar = false});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late final TabController _tabController;
  bool _isTabLoading = false;

  static final List<String> _tabTypes = [UserType.vendor.name, UserType.delivery_man.name];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: _tabTypes.length, vsync: this);
    initCall();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void initCall(){
    if(AuthHelper.isLoggedIn()) {
      Get.find<ProfileController>().getUserInfo();
      Get.find<ChatController>().getConversationList(1, type: _tabTypes[_tabController.index]);
      if(!ResponsiveHelper.isDesktop(Get.context)) {
        Get.find<ChatController>().getAdminConversation();
      }
    }
  }

  Future<void> _onTabTap(int index) async {
    _searchController.text = '';
    Get.find<ChatController>().removeSearchMode();
    setState(() => _isTabLoading = true);
    await Get.find<ChatController>().getConversationList(1, type: _tabTypes[index]);
    if(mounted) setState(() => _isTabLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatController>(builder: (chatController) {
      ConversationsModel? conversation;
      if(chatController.searchConversationModel != null) {
        conversation = chatController.searchConversationModel;
      }else {
        conversation = chatController.conversationModel;
      }

      final String activeType = _tabTypes[_tabController.index];
      final List<Conversation?> visibleConversations = Get.find<ChatController>()
          .conversationsOfType(conversation?.conversations, activeType);

      return Scaffold(
        appBar: CustomAppBar(title: 'conversation_list'.tr, backButton: !widget.fromNavBar),
        endDrawer: const MenuDrawer(), endDrawerEnableOpenDragGesture: false,
        floatingActionButton: (chatController.conversationModel != null && !chatController.hasAdmin) && !ResponsiveHelper.isDesktop(context) ? FloatingActionButton.extended(
          label: SizedBox(
            width: context.width * 0.75,
            child: Text(
              '${'chat_with'.tr} ${Get.find<SplashController>().configModel!.businessName}',
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Colors.white),
            ),
          ),
          icon: const Icon(Icons.chat, color: Colors.white),
          backgroundColor: Theme.of(context).primaryColor,
          onPressed: () => Get.toNamed(RouteHelper.getChatRoute(notificationBody: NotificationBodyModel(
            notificationType: NotificationType.message, adminId: 0,
          ))),
        ) : null,
        body: ResponsiveHelper.isDesktop(context) ? WebChatViewWidget(
          scrollController: _scrollController,
          conversation: conversation,
          chatController: chatController,
          searchController: _searchController,
          initCall: initCall,
        ) : Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          child: Column(children: [

            (AuthHelper.isLoggedIn() && conversation != null && conversation.conversations != null
            && chatController.conversationModel!.conversations!.isNotEmpty) ? Center(child: SizedBox(width: Dimensions.webMaxWidth, child: ChatSearchFieldWidget(
              controller: _searchController,
              hint: '${'search'.tr}...',
              suffixIcon: chatController.searchConversationModel != null ? Icons.close : Icons.search,
              onSubmit: (String text) {
                if(_searchController.text.trim().isNotEmpty) {
                  chatController.searchConversation(_searchController.text.trim());
                }else {
                  showCustomSnackBar('write_something'.tr);
                }
              },
              iconPressed: () {
                if(chatController.searchConversationModel != null) {
                  _searchController.text = '';
                  chatController.removeSearchMode();
                }else {
                  if(_searchController.text.trim().isNotEmpty) {
                    chatController.searchConversation(_searchController.text.trim());
                  }else {
                    showCustomSnackBar('write_something'.tr);
                  }
                }
              },
            ))) : const SizedBox(),
            SizedBox(height: (AuthHelper.isLoggedIn() && conversation != null && conversation.conversations != null
                && chatController.conversationModel!.conversations!.isNotEmpty) ? Dimensions.paddingSizeSmall : 0),

            (AuthHelper.isLoggedIn() && chatController.adminConversationModel != null
            && chatController.adminConversationModel!.conversations != null
            && chatController.adminConversationModel!.conversations!.isNotEmpty) ? Padding(
              padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
              child: Center(child: SizedBox(width: Dimensions.webMaxWidth, child: _ConversationTile(
                conversationItem: chatController.adminConversationModel!.conversations!.first!,
              ))),
            ) : const SizedBox(),

            AuthHelper.isLoggedIn() ? Center(child: SizedBox(width: Dimensions.webMaxWidth, child: TabBar(
              controller: _tabController,
              indicatorColor: Theme.of(context).primaryColor,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Theme.of(context).disabledColor,
              labelStyle: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
              unselectedLabelStyle: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
              tabs: [Tab(text: 'vendor'.tr), Tab(text: 'delivery_man'.tr)],
              onTap: _onTabTap,
            ))) : const SizedBox(),
            SizedBox(height: AuthHelper.isLoggedIn() ? Dimensions.paddingSizeSmall : 0),

            Expanded(child: AuthHelper.isLoggedIn() ? (_isTabLoading ? const ConversationShimmer() : (conversation != null && conversation.conversations != null)
            ? visibleConversations.isNotEmpty ? RefreshIndicator(
              onRefresh: () async {
                await Get.find<ChatController>().getConversationList(1, type: _tabTypes[_tabController.index]);
              },
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverList.separated(
                    itemCount: visibleConversations.length,
                    itemBuilder: (context, index) => Center(
                      child: SizedBox(width: Dimensions.webMaxWidth, child: _ConversationTile(
                        conversationItem: visibleConversations[index]!,
                        index: index,
                      )),
                    ),
                    separatorBuilder: (context, index) => const SizedBox(height: Dimensions.paddingSizeSmall),
                  ),
                  SliverToBoxAdapter(child: Center(child: SizedBox(width: Dimensions.webMaxWidth, child: PaginatedListView(
                    scrollController: _scrollController,
                    onPaginate: (int? offset) => chatController.getConversationList(offset!, type: _tabTypes[_tabController.index]),
                    totalSize: conversation.totalSize,
                    offset: conversation.offset,
                    enabledPagination: chatController.searchConversationModel == null,
                    itemView: const SizedBox.shrink(),
                  )))),
                ],
              ),
            ) : Center(child: Text('no_conversation_found'.tr)) : const Center(child: CircularProgressIndicator())) :  NotLoggedInScreen(callBack: (value){
              initCall();
              setState(() {});
            })),

          ]),
        ),
      );
    });
  }
}

class _ConversationTile extends StatelessWidget {
  static String _formatLastMessageTime(String? lastMessageTime) {
    final DateTime? date = DateConverter.apiStringToDateOrNull(lastMessageTime);
    return date != null ? DateConverter.localDateToIsoStringAMPM(date) : '';
  }

  final Conversation conversationItem;
  final int? index;

  const _ConversationTile({required this.conversationItem, this.index});

  @override
  Widget build(BuildContext context) {
    User? user;
    String? type;
    if(conversationItem.senderType == UserType.user.name || conversationItem.senderType == UserType.customer.name) {
      user = conversationItem.receiver;
      type = conversationItem.receiverType;
    }else {
      user = conversationItem.sender;
      type = conversationItem.senderType;
    }

    final bool isAdminConversation = type == UserType.admin.name;
    if(user == null && isAdminConversation) {
      user = User(
        id: 0,
        fName: Get.find<SplashController>().configModel?.businessName ?? 'admin'.tr,
        lName: '',
        imageFullUrl: Get.find<SplashController>().configModel?.logoFullUrl,
      );
    }

    final String? lastMessageText = conversationItem.lastMessage?.message;
    final bool hasLastMessageAttachment = conversationItem.lastMessage?.fileFullUrl?.isNotEmpty ?? false;
    final String lastMessagePreview = (lastMessageText != null && lastMessageText.isNotEmpty)
        ? lastMessageText
        : hasLastMessageAttachment ? 'sent_a_photo'.tr : type!.tr;

    final bool isDeleted = user == null;
    final String title = isDeleted ? '${type!.tr} ${'deleted'.tr}' : '${user.fName} ${user.lName}';

    return GetBuilder<ProfileController>(builder: (profileController) {
      final int? myId = profileController.userInfoModel?.userInfo?.id;
      // Unread only counts when the newest message came from the other party.
      final bool isUnread = myId != null
          && conversationItem.lastMessage?.senderId != myId
          && (conversationItem.unreadMessageCount ?? 0) > 0;

      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          // Shadow carries the unread state, the same way the notification list does.
          boxShadow: isUnread ? [const BoxShadow(color: Colors.black12, spreadRadius: 1, blurRadius: 5)] : [],
        ),
        child: CustomInkWell(
          onTap: () {
            if(user != null) {
              Get.toNamed(RouteHelper.getChatRoute(
                notificationBody: NotificationBodyModel(
                  type: conversationItem.senderType,
                  notificationType: NotificationType.message,
                  adminId: type == UserType.admin.name ? 0 : null,
                  restaurantId: type == UserType.vendor.name ? user.id : null,
                  deliverymanId: type == UserType.delivery_man.name ? user.id : null,
                ),
                conversationID: conversationItem.id,
                index: index,
              ));
            }else {
              showCustomSnackBar('${type!.tr} ${'not_found'.tr}');
            }
          },
          highlightColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
          radius: Dimensions.radiusDefault,
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Row(children: [

              ChatAvatarWidget(isAdmin: isAdminConversation, imageUrl: user?.imageFullUrl, size: 50),
              const SizedBox(width: Dimensions.paddingSizeSmall),

              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                Row(children: [
                  Expanded(child: Text(
                    title,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: isUnread ? robotoBold : robotoMedium,
                  )),
                  Padding(
                    padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
                    child: Text(
                      _formatLastMessageTime(conversationItem.lastMessageTime),
                      style: robotoRegular.copyWith(
                        color: isUnread ? Theme.of(context).primaryColor : Theme.of(context).hintColor,
                        fontSize: Dimensions.fontSizeExtraSmall,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                Row(children: [
                  Expanded(child: isDeleted ? const SizedBox() : Text(
                    lastMessagePreview,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: isUnread
                          ? Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.7)
                          : Theme.of(context).disabledColor,
                    ),
                  )),

                  if(isUnread) Padding(
                    padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
                      decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
                      child: Text(
                        '${conversationItem.unreadMessageCount}',
                        style: robotoMedium.copyWith(color: Theme.of(context).cardColor, fontSize: Dimensions.fontSizeExtraSmall),
                      ),
                    ),
                  ),
                ]),

              ])),
            ]),
          ),
        ),
      );
    });
  }
}
