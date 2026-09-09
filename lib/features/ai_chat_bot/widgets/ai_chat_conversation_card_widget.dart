import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/features/ai_chat_bot/domain/models/ai_chat_conversation_model.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class AiChatConversationCardWidget extends StatelessWidget {
  final AiChatConversation conversation;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool isDeleting;
  const AiChatConversationCardWidget({
    super.key,
    required this.conversation,
    this.onTap,
    this.onDelete,
    this.isDeleting = false,
  });

  @override
  Widget build(BuildContext context) {
    String? timeText;
    String? rawTime = conversation.updatedAt ?? conversation.createdAt;
    if (rawTime != null && rawTime.isNotEmpty) {
      try {
        timeText = DateConverter.localDateToIsoStringAMPM(
          DateTime.parse(rawTime).toLocal(),
        );
      } catch (_) {
        timeText = null;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        // boxShadow: const [BoxShadow(color: Colors.black12, spreadRadius: 1, blurRadius: 5)],
      ),
      child: CustomInkWell(
        onTap: onTap,
        radius: Dimensions.radiusDefault,
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [

            Container(
              height: 44, width: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor.withValues(alpha: 0.25),
                    Theme.of(context).primaryColor.withValues(alpha: 0.08),
                  ],
                ),
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 22,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeDefault),

            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                Text(
                  conversation.title ?? '',
                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                Row(children: [

                  if (conversation.messagesCount != null) ...[
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 12,
                      color: Theme.of(context).hintColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${conversation.messagesCount} ${'messages'.tr}',
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],

                  if (conversation.messagesCount != null && timeText != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
                      child: Container(
                        height: 3, width: 3,
                        decoration: BoxDecoration(
                          color: Theme.of(context).hintColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),

                  if (timeText != null)
                    Expanded(
                      child: Text(
                        timeText,
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeExtraSmall,
                          color: Theme.of(context).hintColor,
                        ),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ]),

              ]),
            ),

            if (isDeleting)
              SizedBox(
                height: 20, width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).hintColor,
                ),
              )
            else if (onDelete != null)
              PopupMenuButton<String>(
                tooltip: 'options'.tr,
                icon: Icon(Icons.more_vert_rounded, color: Theme.of(context).hintColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
                onSelected: (value) {
                  if (value == 'delete') {
                    onDelete!();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(children: [
                      const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      Text(
                        'delete'.tr,
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Colors.red,
                        ),
                      ),
                    ]),
                  ),
                ],
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).hintColor,
              ),

          ]),
        ),
      ),
    );
  }
}
