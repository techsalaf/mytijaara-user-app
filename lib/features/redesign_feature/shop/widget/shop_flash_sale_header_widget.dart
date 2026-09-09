import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/features/flash_sale/controllers/flash_sale_controller.dart';
import 'package:sixam_mart/features/flash_sale/domain/models/flash_sale_model.dart';
import 'package:sixam_mart/features/flash_sale/widgets/flash_sale_header_banner.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/common_widget/food_item_card.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class ShopFlashSaleHeaderWidget extends StatefulWidget {
  const ShopFlashSaleHeaderWidget({super.key});

  @override
  State<ShopFlashSaleHeaderWidget> createState() => _ShopFlashSaleHeaderWidgetState();
}

class _ShopFlashSaleHeaderWidgetState extends State<ShopFlashSaleHeaderWidget> {
  @override
  Widget build(BuildContext context) {
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final double cardWidth = math.max(100, viewportWidth * 0.35);
    // FoodItemCard = square image (height == cardWidth) + a fixed info block below it.
    // Derive the list height so the image never clips as the card scales, with the
    // info block growing with the text scale.
    final double textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final double cardHeight = cardWidth + Dimensions.paddingSizeDefault + 130 * textScale;

    return GetBuilder<FlashSaleController>(builder: (flashSaleController) {
      if (flashSaleController.flashSaleModel == null) {
        return FlashSaleHeaderBackground(child: _ShopFlashSaleShimmer(cardWidth: cardWidth, cardHeight: cardHeight));
      }

      final List<ActiveProducts>? activeProducts = flashSaleController.flashSaleModel!.activeProducts;
      final Duration? duration = flashSaleController.duration;

      if (activeProducts == null || activeProducts.isEmpty || duration == null || duration.inSeconds <= 1) {
        return const SizedBox.shrink();
      }

      final List<Item> items = activeProducts
          .where((ap) => ap.item != null)
          .map((ap) => ap.item!)
          .toList();

      if (items.isEmpty) {
        return const SizedBox.shrink();
      }

      final int flashSaleId = activeProducts[0].flashSaleId!;

      return FlashSaleHeaderBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: Dimensions.paddingSizeDefault),
            FlashSaleHeaderBanner(
              duration: duration,
              onTap: () => Get.toNamed(RouteHelper.getFlashSaleDetailsScreen(flashSaleId)),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),

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

class _ShopFlashSaleBackground extends StatelessWidget {
  final Widget child;
  const _ShopFlashSaleBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(child: Image.asset(Images.flashSellBg, fit: BoxFit.cover)),
        // The asset is a bright/light graphic. In dark mode lay a dark scrim over it
        // so it blends with the dark UI instead of glaring; content stays on top.
        if(isDark)
          Positioned.fill(
            child: Container(color: Theme.of(context).cardColor.withValues(alpha: 0.75)),
          ),
        child,
      ],
    );
  }
}

class _FlashSaleHeaderRow extends StatelessWidget {
  final Duration duration;
  final VoidCallback onSeeAll;

  const _FlashSaleHeaderRow({required this.duration, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final int days = duration.inDays;
    final int hours = duration.inHours - days * 24;
    final int minutes = duration.inMinutes - (24 * days * 60) - (hours * 60);
    final int seconds = duration.inSeconds - (24 * days * 60 * 60) - (hours * 60 * 60) - (minutes * 60);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: CustomInkWell(
        onTap: onSeeAll,
        radius: Dimensions.radiusSmall,
        child: SizedBox(
          height: 50,
          child: Row(
            children: [
              Image.asset(Images.flashSellIcon, height: 42, width: 42),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'flash_sale'.tr,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: robotoBold.copyWith(color: Colors.blueAccent, fontSize: Dimensions.fontSizeLarge),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'grab_the_offer_before_end_the_time'.tr,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: robotoRegular.copyWith(color: Colors.blueAccent, fontSize: Dimensions.fontSizeSmall),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Row(
                children: [
                  _ShopFlashSaleTimeBox(timeCount: days, timeUnit: 'days'.tr),
                  const SizedBox(width: 6),
                  _ShopFlashSaleTimeBox(timeCount: hours, timeUnit: 'hours'.tr),
                  const SizedBox(width: 6),
                  _ShopFlashSaleTimeBox(timeCount: minutes, timeUnit: 'mins'.tr),
                  const SizedBox(width: 6),
                  _ShopFlashSaleTimeBox(timeCount: seconds, timeUnit: 'sec'.tr),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopFlashSaleTimeBox extends StatelessWidget {
  final int timeCount;
  final String timeUnit;
  const _ShopFlashSaleTimeBox({required this.timeCount, required this.timeUnit});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 38,
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            timeCount > 9 ? timeCount.toString() : '0${timeCount.toString()}',
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeDefault),
          ),
          Text(
            timeUnit,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: robotoRegular.copyWith(color: Colors.white, fontSize: 8),
          ),
        ],
      ),
    );
  }
}

class _ShopFlashSaleShimmer extends StatelessWidget {
  final double cardWidth;
  final double cardHeight;
  const _ShopFlashSaleShimmer({required this.cardWidth, required this.cardHeight});

  @override
  Widget build(BuildContext context) {
    final Color shimmerColor = Theme.of(context).disabledColor.withAlpha(60);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: Dimensions.paddingSizeSmall),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: Shimmer(
            duration: const Duration(seconds: 2),
            child: SizedBox(
              height: 50,
              child: Row(
                children: [
                  Container(
                    height: 42, width: 42,
                    decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 12, width: 100,
                          decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 10, width: 160,
                          decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Row(children: List.generate(4, (i) => Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Container(
                      height: 40, width: 38,
                      decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
                    ),
                  ))),
                ],
              ),
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
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(22)),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Container(
              height: 12, width: width * 0.6,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
            ),
            const SizedBox(height: 8),
            Container(
              height: 12, width: width * 0.85,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
            ),
            const SizedBox(height: 8),
            Container(
              height: 14, width: width * 0.45,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
            ),
          ],
        ),
      ),
    );
  }
}
