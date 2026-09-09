import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/common/widgets/paginated_list_view.dart';
import 'package:sixam_mart/features/ai_chat_bot/controllers/ai_chat_bot_controller.dart';
import 'package:sixam_mart/features/ai_chat_bot/domain/models/ai_chat_message_model.dart';
import 'package:sixam_mart/features/ai_chat_bot/widgets/ai_chat_message_bubble_widget.dart';
import 'package:sixam_mart/features/ai_chat_bot/widgets/ai_chat_suggestion_chips_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class AiChatDetailsScreen extends StatefulWidget {
  final int? conversationId;
  final String? title;
  final String? initialMessage;
  const AiChatDetailsScreen({
    super.key,
    required this.conversationId,
    this.title,
    this.initialMessage,
  });

  @override
  State<AiChatDetailsScreen> createState() => _AiChatDetailsScreenState();
}

class _AiChatDetailsScreenState extends State<AiChatDetailsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  int? _activeConversationId;
  // Module active when the chat opened. Tapping a metadata card (product/store/
  // category) may silently switch the module for its detail page; restore the
  // entry module on close so taps back on the home/module page don't run against
  // the module left behind by the chat (same pattern as GlobalCartScreen).
  ModuleModel? _entryModule;

  @override
  void initState() {
    super.initState();
    _activeConversationId = widget.conversationId;
    _entryModule = Get.find<SplashController>().module;
    _initCall();
  }

  void _initCall() {
    final controller = Get.find<AiChatBotController>();
    if (_activeConversationId != null) {
      controller.getMessages(_activeConversationId!, 1, firstLoad: true);
    } else {
      controller.clearMessages();
    }
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _inputController.text = widget.initialMessage!;
        controller.toggleSendButtonActivity(true);
        _onSendPressed();
      });
    }
  }

  @override
  void dispose() {
    final SplashController splash = Get.find<SplashController>();
    if (splash.module?.id != _entryModule?.id) {
      splash.setModule(_entryModule, notify: false);
    }
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _onSendPressed() async {
    final String message = _inputController.text.trim();
    if (message.isEmpty) {
      showCustomSnackBar('write_something'.tr);
      return;
    }
    _inputController.clear();
    final controller = Get.find<AiChatBotController>();
    controller.toggleSendButtonActivity(false);

    await controller.sendMessage(
      message: message,
      conversationId: _activeConversationId,
      onConversationIdAssigned: (id) => _activeConversationId = id,
    );

    controller.getConversationList(1, reload: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: widget.title?.isNotEmpty == true ? widget.title! : 'ai_assistant'.tr),
      endDrawer: const MenuDrawer(),
      endDrawerEnableOpenDragGesture: false,
      body: GetBuilder<AiChatBotController>(builder: (controller) {
        return Column(children: [

          Expanded(
            child: Builder(builder: (_) {
              final bool sending = controller.isSendingMessage;
              final List<AiChatMessage> messages = List<AiChatMessage>.from(
                controller.messageModel?.messages ?? const <AiChatMessage>[],
              );
              messages.sort((a, b) {
                final DateTime aTime = DateTime.tryParse(a.createdAt ?? '')?.toUtc() ?? DateTime.fromMillisecondsSinceEpoch(0);
                final DateTime bTime = DateTime.tryParse(b.createdAt ?? '')?.toUtc() ?? DateTime.fromMillisecondsSinceEpoch(0);
                return bTime.compareTo(aTime);
              });
              final bool hasMessages = messages.isNotEmpty;

              if (controller.messageModel == null && _activeConversationId != null && !sending) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!hasMessages && !sending) {
                if (_activeConversationId == null) {
                  return _NewChatWelcomeView(
                    onSuggestionTap: (text) {
                      _inputController.text = text;
                      _onSendPressed();
                    },
                  );
                }
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                    child: Text(
                      'no_message_found'.tr,
                      style: robotoRegular.copyWith(color: Theme.of(context).hintColor),
                    ),
                  ),
                );
              }

              return SingleChildScrollView(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                child: PaginatedListView(
                  scrollController: _scrollController,
                  reverse: true,
                  totalSize: controller.messageModel?.totalSize ?? messages.length,
                  offset: controller.messageModel?.offset ?? 1,
                  onPaginate: (int? offset) async {
                    if (_activeConversationId != null) {
                      await controller.getMessages(_activeConversationId!, offset!);
                    }
                  },
                  itemView: ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    reverse: true,
                    padding: EdgeInsets.zero,
                    itemCount: messages.length + (sending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (sending && index == 0) {
                        return const AiChatTypingBubbleWidget();
                      }
                      final int messageIndex = sending ? index - 1 : index;
                      return AiChatMessageBubbleWidget(
                        message: messages[messageIndex],
                      );
                    },
                  ),
                ),
              );
            }),
          ),

          _AiChatInputBar(
            controller: _inputController,
            isSending: controller.isSendingMessage,
            isActive: controller.isSendButtonActive,
            onChanged: (value) => controller.toggleSendButtonActivity(value.trim().isNotEmpty),
            onSubmit: _onSendPressed,
          ),

        ]);
      }),
    );
  }
}

class _AiChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final bool isActive;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  const _AiChatInputBar({
    required this.controller,
    required this.isSending,
    required this.isActive,
    required this.onChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeSmall,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [

          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                border: Border.all(
                  color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
                  width: 0.6,
                ),
              ),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                textCapitalization: TextCapitalization.sentences,
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                keyboardType: TextInputType.multiline,
                maxLines: 4,
                minLines: 1,
                inputFormatters: [LengthLimitingTextInputFormatter(Dimensions.messageInputLength)],
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'ask_anything'.tr,
                  hintStyle: robotoRegular.copyWith(
                    color: Theme.of(context).hintColor,
                    fontSize: Dimensions.fontSizeSmall,
                  ),
                ),
                onSubmitted: (_) => isSending ? null : onSubmit(),
              ),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          InkWell(
            onTap: isSending ? null : onSubmit,
            customBorder: const CircleBorder(),
            child: Container(
              height: 44, width: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isActive && !isSending)
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).disabledColor.withValues(alpha: 0.4),
              ),
              alignment: Alignment.center,
              child: isSending
                  ? const SizedBox(
                      height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
            ),
          ),

        ]),
      ),
    );
  }
}

class _NewChatWelcomeView extends StatelessWidget {
  final ValueChanged<String> onSuggestionTap;
  const _NewChatWelcomeView({required this.onSuggestionTap});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeLarge,
        vertical: Dimensions.paddingSizeExtraLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          Container(
            height: 110, width: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor.withValues(alpha: 0.2),
                  Theme.of(context).primaryColor.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 56,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          Text(
            'ask_anything'.tr,
            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
            child: Text(
              'start_a_new_conversation_with_ai'.tr,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraLarge),

          AiChatSuggestionChipsWidget(onSuggestionTap: onSuggestionTap),

        ],
      ),
    );
  }
}
