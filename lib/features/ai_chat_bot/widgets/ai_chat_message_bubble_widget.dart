import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/ai_chat_bot/domain/models/ai_chat_message_model.dart';
import 'package:sixam_mart/features/ai_chat_bot/widgets/ai_chat_metadata_view_widget.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class AiChatMessageBubbleWidget extends StatelessWidget {
  final AiChatMessage message;
  const AiChatMessageBubbleWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.isUser;
    final Color userBubble = Get.isDarkMode
        ? Theme.of(context).primaryColor.withValues(alpha: 0.25)
        : Theme.of(context).primaryColor.withValues(alpha: 0.12);
    final Color assistantBubble = Get.isDarkMode
        ? Theme.of(context).cardColor.withValues(alpha: 0.6)
        : Theme.of(context).disabledColor.withValues(alpha: 0.08);

    String? timeText;
    if (message.createdAt != null && message.createdAt!.isNotEmpty) {
      try {
        timeText = DateConverter.localDateToIsoStringAMPM(
          DateTime.parse(message.createdAt!).toLocal(),
        );
      } catch (_) {
        timeText = null;
      }
    }

    final BorderRadius bubbleRadius = isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(Dimensions.radiusLarge),
            topRight: Radius.circular(Dimensions.radiusLarge),
            bottomLeft: Radius.circular(Dimensions.radiusLarge),
            bottomRight: Radius.circular(Dimensions.radiusSmall),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(Dimensions.radiusLarge),
            topRight: Radius.circular(Dimensions.radiusLarge),
            bottomRight: Radius.circular(Dimensions.radiusLarge),
            bottomLeft: Radius.circular(Dimensions.radiusSmall),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeExtraSmall,
      ),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [

          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [

              if (!isUser) _AssistantAvatar(),
              if (!isUser) const SizedBox(width: Dimensions.paddingSizeSmall),

              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeDefault,
                    vertical: Dimensions.paddingSizeSmall + 2,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? userBubble : assistantBubble,
                    borderRadius: bubbleRadius,
                  ),
                  child: Text(
                    message.content ?? '',
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      height: 1.4,
                    ),
                  ),
                ),
              ),

              if (message.sending) ...[
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                SizedBox(
                  height: 12, width: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],

            ],
          ),

          if (!isUser && message.metadata != null && !message.metadata!.isEmpty)
            Padding(
              padding: const EdgeInsets.only(
                top: Dimensions.paddingSizeSmall,
                left: 44,
              ),
              child: AiChatMetadataViewWidget(metadata: message.metadata!),
            ),

          if (timeText != null)
            Padding(
              padding: EdgeInsets.only(
                top: Dimensions.paddingSizeExtraSmall,
                left: isUser ? 0 : 44,
                right: isUser ? Dimensions.paddingSizeExtraSmall : 0,
              ),
              child: Text(
                timeText,
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeOverSmall,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),

        ],
      ),
    );
  }
}

class _AssistantAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32, width: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
    );
  }
}

class AiChatTypingBubbleWidget extends StatefulWidget {
  const AiChatTypingBubbleWidget({super.key});

  @override
  State<AiChatTypingBubbleWidget> createState() => _AiChatTypingBubbleWidgetState();
}

class _AiChatTypingBubbleWidgetState extends State<AiChatTypingBubbleWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color assistantBubble = Get.isDarkMode
        ? Theme.of(context).cardColor.withValues(alpha: 0.6)
        : Theme.of(context).disabledColor.withValues(alpha: 0.08);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeExtraSmall,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [

          _AssistantAvatar(),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
              vertical: Dimensions.paddingSizeSmall + 4,
            ),
            decoration: BoxDecoration(
              color: assistantBubble,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(Dimensions.radiusLarge),
                topRight: Radius.circular(Dimensions.radiusLarge),
                bottomRight: Radius.circular(Dimensions.radiusLarge),
                bottomLeft: Radius.circular(Dimensions.radiusSmall),
              ),
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final double t = ((_controller.value + i * 0.18) % 1.0);
                    final double scale = 0.6 + 0.4 * (t < 0.5 ? (t * 2) : (1 - (t - 0.5) * 2));
                    final double opacity = 0.4 + 0.6 * (t < 0.5 ? (t * 2) : (1 - (t - 0.5) * 2));
                    return Padding(
                      padding: EdgeInsets.only(right: i == 2 ? 0 : 4),
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.scale(
                          scale: scale,
                          child: Container(
                            height: 8, width: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),

        ],
      ),
    );
  }
}
