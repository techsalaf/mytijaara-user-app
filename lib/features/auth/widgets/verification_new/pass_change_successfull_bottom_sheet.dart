import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/util/dimensions.dart';

class PasswordChangedBottomSheet extends StatelessWidget {
  const PasswordChangedBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: Dimensions.paddingSizeLarge, left: Dimensions.paddingSizeLarge,
        right: Dimensions.paddingSizeLarge, bottom: Dimensions.paddingSizeLarge + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(width: 36, height: 36,
                decoration: BoxDecoration(shape: BoxShape.circle, color: theme.disabledColor.withAlpha(40)),
                child: Icon(Icons.close, size: 18, color: theme.iconTheme.color),
              ),
            ),
          ),

          const SizedBox(height: Dimensions.paddingSizeLarge),

          Container(padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
            decoration: BoxDecoration(shape: BoxShape.circle, color: theme.disabledColor.withAlpha(80)),
            child: Icon(Icons.check_rounded, size: 48, color: theme.cardColor, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: Dimensions.paddingSizeLarge),

          Text(
            'password_changed_successfully'.tr,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: Dimensions.fontSizeExtraLarge,
            ),
          ),

          const SizedBox(height: Dimensions.paddingSizeSmall),

          Text(
            'password_changed_subtitle'.tr,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.hintColor,
              height: 1.5,
              fontSize: Dimensions.fontSizeDefault,
            ),
          ),

          const SizedBox(height: Dimensions.paddingSizeExtraLarge),

          SizedBox(
            width: 150,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
                elevation: 0,
              ),
              child: Text(
                'okay_got_it'.tr,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: Dimensions.fontSizeDefault,
                ),
              ),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
        ],
      ),
    );
  }
}