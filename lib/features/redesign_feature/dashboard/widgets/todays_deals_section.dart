import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/common_widget/food_item_card.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class TodaysDealsSectionWidget extends StatelessWidget {
  const TodaysDealsSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final double cardWidth = math.max(100, viewportWidth * 0.35);
    // FoodItemCard = square image (height == cardWidth) + a fixed info block below
    // it. Derive the list height from the card width (so the image never clips as
    // the card scales) plus the info block, which grows with the text scale.
    final double textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final double cardHeight = cardWidth + Dimensions.paddingSizeDefault + 130 * textScale;

    return GetBuilder<ItemController>(builder: (itemController) {
      final List<Item>? items = itemController.discountedItemList;

      if(items == null) {
        return _TodaysDealsShimmer(cardWidth: cardWidth, cardHeight: cardHeight);
      }
      if(items.isEmpty) {
        return const SizedBox.shrink();
      }

      // Warm "deals" wash that fades to transparent. Light mode keeps the cream
      // tint; dark mode uses a subtle amber glow so it doesn't show as a bright band.
      final bool isDark = Theme.of(context).brightness == Brightness.dark;
      final Color tint = isDark ? const Color(0xFFFFC107) : const Color(0xFFFFFBEB);
      final List<Color> dealsGradient = isDark
          ? [
              tint.withValues(alpha: 0.18),
              tint.withValues(alpha: 0.18),
              tint.withValues(alpha: 0.10),
              tint.withValues(alpha: 0.10),
              tint.withValues(alpha: 0.0),
            ]
          : [
              tint,
              tint,
              tint.withValues(alpha: 0.5),
              tint.withValues(alpha: 0.5),
              tint.withValues(alpha: 0.01),
            ];

      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: dealsGradient, begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              child: TitleWidget(title: 'todays_deals'.tr, fontColor: const Color(0xFFBF6A02)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              child: Text(
                'grab_the_offer_before_end_the_time'.tr,
                style: robotoRegular.copyWith(
                  color: const Color(0xFFBF6A02),
                  fontSize: Dimensions.fontSizeSmall,
                ),
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            SizedBox(
              height: cardHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(width: Dimensions.paddingSizeSmall),
                itemBuilder: (context, index) => FoodItemCard(data: items[index], width: cardWidth, index: index),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _TodaysDealsShimmer extends StatelessWidget {
  final double cardWidth;
  final double cardHeight;
  const _TodaysDealsShimmer({required this.cardWidth, required this.cardHeight});

  @override
  Widget build(BuildContext context) {
    final Color shimmerColor = Theme.of(context).disabledColor.withAlpha(60);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: TitleWidget(title: 'todays_deals'.tr),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: Text(
            'grab_the_offer_before_end_the_time'.tr,
            style: robotoRegular.copyWith(
              color: Theme.of(context).disabledColor,
              fontSize: Dimensions.fontSizeSmall,
            ),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        SizedBox(
          height: cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            itemCount: 5,
            separatorBuilder: (context, index) => const SizedBox(width: Dimensions.paddingSizeSmall),
            itemBuilder: (context, index) => _ShimmerCard(width: cardWidth, color: shimmerColor),
          ),
        ),
      ],
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  final double width;
  final Color color;
  const _ShimmerCard({required this.width, required this.color});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      duration: const Duration(seconds: 2),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: width,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Container(
              height: 12, width: width * 0.6,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 12, width: width * 0.85,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 14, width: width * 0.45,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
