import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/common/widgets/paginated_list_view.dart';
import 'package:sixam_mart/features/ai_chat_bot/controllers/ai_chat_bot_controller.dart';
import 'package:sixam_mart/features/ai_chat_bot/domain/models/ai_chat_conversation_model.dart';
import 'package:sixam_mart/features/ai_chat_bot/widgets/ai_chat_conversation_card_widget.dart';
import 'package:sixam_mart/features/ai_chat_bot/widgets/ai_chat_conversation_shimmer_widget.dart';
import 'package:sixam_mart/features/ai_chat_bot/widgets/ai_chat_empty_state_widget.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class AiChatBotScreen extends StatefulWidget {
  const AiChatBotScreen({super.key});

  @override
  State<AiChatBotScreen> createState() => _AiChatBotScreenState();
}

class _AiChatBotScreenState extends State<AiChatBotScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initCall();
  }

  void _initCall() {
    Get.find<AiChatBotController>().getConversationList(1, reload: true);
  }

  Future<void> _confirmDelete(AiChatConversation conversation) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('delete_conversation'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
        content: Text(
          'delete_conversation_confirm'.tr,
          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'cancel'.tr,
              style: robotoMedium.copyWith(color: Theme.of(context).hintColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'delete'.tr,
              style: robotoMedium.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || conversation.id == null) {
      return;
    }

    final bool ok = await Get.find<AiChatBotController>().deleteConversation(conversation.id!);
    showCustomSnackBar(
      ok ? 'conversation_deleted'.tr : 'sorry_something_went_wrong'.tr,
      isError: !ok,
    );
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'ai_chat_bot'.tr),
      endDrawer: const MenuDrawer(),
      endDrawerEnableOpenDragGesture: false,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(RouteHelper.getAiChatDetailsScreen(conversationId: null)),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'new_chat'.tr,
          style: robotoMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: GetBuilder<AiChatBotController>(builder: (aiChatBotController) {
        if (aiChatBotController.conversationModel == null) {
          return const AiChatConversationShimmerWidget();
        }
        if (aiChatBotController.conversationModel!.data == null
            || aiChatBotController.conversationModel!.data!.isEmpty) {
          return const AiChatEmptyStateWidget();
        }
        return RefreshIndicator(
          onRefresh: () async {
            await Get.find<AiChatBotController>().getConversationList(1, reload: true);
          },
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeSmall,
              vertical: Dimensions.paddingSizeSmall,
            ),
            child: FooterView(
              child: SizedBox(
                width: Dimensions.webMaxWidth,
                child: PaginatedListView(
                  scrollController: _scrollController,
                  totalSize: aiChatBotController.conversationModel!.totalSize,
                  offset: aiChatBotController.conversationModel!.offset,
                  onPaginate: (int? offset) async {
                    await aiChatBotController.getConversationList(offset!);
                  },
                  itemView: ListView.builder(
                    itemCount: aiChatBotController.conversationModel!.data!.length,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      final conversation = aiChatBotController.conversationModel!.data![index];
                      final bool deleting = conversation.id != null
                          && aiChatBotController.isDeleting(conversation.id!);
                      return AiChatConversationCardWidget(
                        conversation: conversation,
                        isDeleting: deleting,
                        onTap: deleting ? null : () => Get.toNamed(RouteHelper.getAiChatDetailsScreen(
                          conversationId: conversation.id,
                          title: conversation.title,
                        )),
                        onDelete: conversation.id == null ? null : () => _confirmDelete(conversation),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
