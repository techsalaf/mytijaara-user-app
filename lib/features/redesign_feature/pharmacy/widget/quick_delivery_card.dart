import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/store_verified_avatar.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/common_widget/food_item_card.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/offer_card_widget.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class QuickDeliveryCardSection extends StatefulWidget {
  final String? title;
  final String? subTitle;
  final bool showStoreName;
  final bool? canScroll;
  const QuickDeliveryCardSection({super.key,
    this.title, this.subTitle, this.showStoreName = true, this.canScroll = true,
  });

  @override
  State<QuickDeliveryCardSection> createState() => _QuickDeliveryCardSectionState();
}

class _QuickDeliveryCardSectionState extends State<QuickDeliveryCardSection> {
  @override
  void initState() {
    super.initState();
    final ItemController itemController = Get.find<ItemController>();
    if (itemController.basicMedicineModel == null) {
      itemController.getBasicMedicine(false, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final double cardWidth = math.max(100, viewportWidth * 0.37);

    return GetBuilder<ItemController>(builder: (itemController) {
      final List<Item>? products = itemController.basicMedicineModel?.products;
      final bool isLoading = products == null;

      if (!isLoading && products.isEmpty) {
        return const SizedBox();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title != null) Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: TitleWidget(title: widget.title!),
          ),
          if (widget.subTitle != null) Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: Text(widget.subTitle!, style: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall)),
          ),

          const SizedBox(height: Dimensions.paddingSizeDefault),
          SizedBox(
            height: 250 + (widget.showStoreName ? 20 : 0),
            child: isLoading
                ? _QuickDeliveryShimmer(cardWidth: cardWidth, showStoreName: widget.showStoreName)
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: widget.canScroll! ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                    itemCount: products.length,
                    separatorBuilder: (context, index) => const SizedBox(width: Dimensions.paddingSizeSmall),
                    itemBuilder: (context, index) {
                      final Item item = products[index];
                      return FoodItemCard(data: item, width: cardWidth, index: index);
                    },
                  ),
          ),
        ],
      );
    });
  }
}

class _QuickDeliveryShimmer extends StatelessWidget {
  final double cardWidth;
  final bool showStoreName;
  const _QuickDeliveryShimmer({required this.cardWidth, required this.showStoreName});

  @override
  Widget build(BuildContext context) {
    final Color shimmerColor = Theme.of(context).disabledColor.withAlpha(60);
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(width: Dimensions.paddingSizeSmall),
      itemBuilder: (context, index) => _QuickDeliveryShimmerCard(
        width: cardWidth, color: shimmerColor, showStoreName: showStoreName,
      ),
    );
  }
}

class _QuickDeliveryShimmerCard extends StatelessWidget {
  final double width;
  final Color color;
  final bool showStoreName;
  const _QuickDeliveryShimmerCard({required this.width, required this.color, required this.showStoreName});

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
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(22)),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            if (showStoreName) Container(
              height: 14, width: width * 0.7,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
            ),
            if (showStoreName) const SizedBox(height: 8),
            Container(
              height: 12, width: width * 0.85,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
            ),
            const SizedBox(height: 6),
            Container(
              height: 10, width: width * 0.5,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
            ),
            const SizedBox(height: 8),
            Container(
              height: 14, width: width * 0.4,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
            ),
          ],
        ),
      ),
    );
  }
}
