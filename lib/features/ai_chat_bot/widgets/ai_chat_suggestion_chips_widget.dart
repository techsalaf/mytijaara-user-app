import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class AiChatSuggestionChipsWidget extends StatelessWidget {
  final ValueChanged<String> onSuggestionTap;
  const AiChatSuggestionChipsWidget({super.key, required this.onSuggestionTap});

  // Suggestions tailored to the active module so the chips match what the user
  // can actually ask for. Falls back to the food set (the original list) for the
  // food module or any unrecognised/null module type.
  List<String> _suggestionsForModule() {
    final String? moduleType = Get.find<SplashController>().module?.moduleType?.toString();
    switch (moduleType) {
      case AppConstants.grocery:
        return [
          'ai_suggestion_grocery_show'.tr, 'ai_suggestion_grocery_essentials'.tr,
          'ai_suggestion_grocery_breakfast'.tr, 'ai_suggestion_grocery_add'.tr,
        ];
      case AppConstants.ecommerce:
        return [
          'ai_suggestion_shop_show'.tr, 'ai_suggestion_shop_electronics'.tr,
          'ai_suggestion_shop_gift'.tr, 'ai_suggestion_shop_add'.tr,
        ];
      case AppConstants.pharmacy:
        return [
          'ai_suggestion_pharmacy_show'.tr, 'ai_suggestion_pharmacy_essentials'.tr,
          'ai_suggestion_pharmacy_cold'.tr, 'ai_suggestion_pharmacy_add'.tr,
        ];
      default:
        return [
          'ai_suggestion_show_food'.tr, 'ai_suggestion_find_popular'.tr,
          'ai_suggestion_dinner'.tr, 'ai_suggestion_cheese_pizza'.tr,
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> suggestions = _suggestionsForModule();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      Align(
        alignment: Get.find<LocalizationController>().isLtr ? Alignment.centerLeft : Alignment.centerRight,
        child: Text(
          '${'try_asking'.tr}:',
          style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
        ),
      ),
      const SizedBox(height: Dimensions.paddingSizeSmall),

      Wrap(
        spacing: Dimensions.paddingSizeSmall,
        runSpacing: Dimensions.paddingSizeSmall,
        alignment: WrapAlignment.center,
        children: suggestions.map((text) => _SuggestionChip(
          text: text,
          onTap: () => onSuggestionTap(text),
        )).toList(),
      ),

    ]);
  }
}

class _SuggestionChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _SuggestionChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeSmall,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
          border: Border.all(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.25),
            width: 0.8,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.auto_awesome_outlined, size: 14, color: Theme.of(context).primaryColor),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Text(
            text,
            style: robotoMedium.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ]),
      ),
    );
  }
}
