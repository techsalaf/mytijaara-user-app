import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/common_widget/dish_card.dart';
import 'package:sixam_mart/util/dimensions.dart';

class TrendingDishesSectionWidget extends StatelessWidget {
  final String title;
  const TrendingDishesSectionWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final double cardWidth = math.max(300, math.min(viewportWidth * 0.82, 360));

    return GetBuilder<ItemController>(builder: (itemController) {
      final List<Item>? items = itemController.discountedItemList;

      if (items == null) {
        return _TrendingDishesShimmer(title: title, cardWidth: cardWidth);
      }
      if (items.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        color: Theme.of(context).disabledColor.withAlpha(50),
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault),
              child: TitleWidget(title: title),
            ),

            const SizedBox(height: Dimensions.paddingSizeDefault),
            SizedBox(
              height: 130,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(width: Dimensions.paddingSizeDefault),
                itemBuilder: (context, index) {
                  final Item item = items[index];
                  return CustomInkWell(
                    onTap: () => itemController.navigateToItemPage(item, context),
                    child: DishCard(item: item, width: cardWidth, index: index),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _TrendingDishesShimmer extends StatelessWidget {
  final String title;
  final double cardWidth;
  const _TrendingDishesShimmer({required this.title, required this.cardWidth});

  @override
  Widget build(BuildContext context) {
    final Color shimmerColor = Theme.of(context).disabledColor.withAlpha(60);

    return Container(
      color: Theme.of(context).disabledColor.withAlpha(50),
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault),
            child: TitleWidget(title: title),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              itemCount: 4,
              separatorBuilder: (context, index) => const SizedBox(width: Dimensions.paddingSizeDefault),
              itemBuilder: (context, index) => _DishCardShimmer(width: cardWidth, color: shimmerColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _DishCardShimmer extends StatelessWidget {
  final double width;
  final Color color;
  const _DishCardShimmer({required this.width, required this.color});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      duration: const Duration(seconds: 2),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(color: Theme.of(context).disabledColor.withAlpha(50)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall, vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(height: 16, width: 16, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Expanded(child: Container(height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)))),
                    ]),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    Container(height: 12, width: double.infinity, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(Dimensions.radiusSmall))),
                    const Spacer(),
                    Row(children: [
                      Container(height: 14, width: 50, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(Dimensions.radiusSmall))),
                      const SizedBox(width: 8),
                      Container(height: 12, width: 36, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(Dimensions.radiusSmall))),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Container(
              width: 126,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
            ),
          ],
        ),
      ),
    );
  }
}
