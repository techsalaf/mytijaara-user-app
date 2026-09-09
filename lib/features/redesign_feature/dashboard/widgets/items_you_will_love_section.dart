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

class ItemsYouWillLoveSectionWidget extends StatelessWidget {
  final String? title;
  final String? subTitle;
  const ItemsYouWillLoveSectionWidget({super.key, this.title, this.subTitle});


  @override
  Widget build(BuildContext context) {
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final double cardWidth = math.max(100, viewportWidth * 0.37);
    final double textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final double cardHeight = cardWidth + Dimensions.paddingSizeDefault + 130 * textScale;

    return GetBuilder<ItemController>(builder: (itemController) {
      final List<Item>? items = itemController.popularItemList;

      if(items == null) {
        return _ItemsYouWillLoveShimmer(title: title, subTitle: subTitle, cardWidth: cardWidth, cardHeight: cardHeight);
      }
      if(items.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if(title != null) Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: TitleWidget(
              title: title!,
              // onTap: () => Get.toNamed(RouteHelper.getItemViewAllScreen(true, false)),
            ),
          ),
          if(subTitle != null) Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: Text(subTitle!, style: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall)),
          ),

          const SizedBox(height: Dimensions.paddingSizeDefault),
          SizedBox(
            height: cardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(width: Dimensions.paddingSizeDefault),
              itemBuilder: (context, index) => FoodItemCard(data: items[index], width: cardWidth, index: index),
            ),
          ),
        ],
      );
    });
  }
}

class _ItemsYouWillLoveShimmer extends StatelessWidget {
  final String? title;
  final String? subTitle;
  final double cardWidth;
  final double cardHeight;
  const _ItemsYouWillLoveShimmer({required this.title, required this.subTitle, required this.cardWidth, required this.cardHeight});

  @override
  Widget build(BuildContext context) {
    final Color shimmerColor = Theme.of(context).disabledColor.withAlpha(60);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if(title != null) Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: TitleWidget(title: title!),
        ),
        if(subTitle != null) Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: Text(subTitle!, style: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall)),
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


class FoodModuleLovableItemChipData {
  final String label;
  final IconData? icon;
  final bool isDiscount;

  const FoodModuleLovableItemChipData({
    required this.label,
    this.icon,
    this.isDiscount = false,
  });
}
