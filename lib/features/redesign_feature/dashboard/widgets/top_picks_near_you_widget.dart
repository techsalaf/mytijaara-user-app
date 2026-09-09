import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/common_widget/featured_store_card.dart';
import 'package:sixam_mart/features/store/screens/store_screen.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class TopPicksNearYouWidget extends StatelessWidget {
  final String title;
  final String? subTitle;
  final bool isQuick;
  final bool isNearYou;
  final bool isRecommended;
  final bool? isFeatured;
  final double? height;
  const TopPicksNearYouWidget({super.key, required this.title, this.isQuick = false, this.subTitle, this.isNearYou = false, this.isRecommended = false, this.isFeatured = false, this.height});


  @override
  Widget build(BuildContext context) {
    final double cardWidth = MediaQuery.sizeOf(context).width * 0.80;
    final double imageHeight = cardWidth * 0.46;
    // Content area below the image. Non-featured cards also render a category-tags
    // row, so they need extra room; scale with the text scaler so larger fonts
    // don't clip the card content (which caused the list overflow).
    final double textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final double sectionHeight = imageHeight + ((height ?? 105) + (isFeatured! ? 0 : 22)) * textScale;

    return GetBuilder<StoreController>(builder: (storeController) {
      final List<Store>? storeList = isRecommended ? storeController.recommendedStoreList
          : isNearYou ? storeController.topOfferStoreList
          : isFeatured! ? storeController.featuredStoreList
          : storeController.latestStoreList;

      if (storeList != null && storeList.isEmpty) return const SizedBox();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: Row(children: [
                if(isQuick) ...[
                  Image.asset(Images.quickDelivery, height: 24),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                ],

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TitleWidget(title: title),
                    if(subTitle != null) Text(subTitle!, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),)
                  ],
                ),
            ]),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          SizedBox(
            height: sectionHeight,
            child: storeList == null
                ? _FeaturedShimmer(cardWidth: cardWidth, imageHeight: imageHeight)
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                    itemCount: storeList.length > 10 ? 10 : storeList.length,
                    separatorBuilder: (context, index) => const SizedBox(width: Dimensions.paddingSizeDefault),
                    itemBuilder: (context, index) => FeaturedStoreCard(
                      data: storeList[index],
                      width: cardWidth,
                      imageHeight: imageHeight,
                      isQuick: isQuick,
                      isFeatured: isFeatured,
                      onTap: () {
                        if(Get.find<SplashController>().moduleList != null) {
                          for(ModuleModel module in Get.find<SplashController>().moduleList!) {
                            if(module.id == storeList[index].moduleId) {
                              Get.find<SplashController>().setModule(module);
                              break;
                            }
                          }
                        }
                        Get.toNamed(
                          RouteHelper.getStoreRoute(id: storeList[index].id, page: isFeatured! ? 'module' : 'store_new', slug: storeList[index].slug ?? ''),
                          arguments: StoreScreen(store: storeList[index], fromModule: isFeatured! ? true : false),
                        );
                      },
                    ),
                  ),
          ),
        ],
      );
    });
  }
}

class _FeaturedShimmer extends StatelessWidget {
  final double cardWidth;
  final double imageHeight;
  const _FeaturedShimmer({required this.cardWidth, required this.imageHeight});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(width: Dimensions.paddingSizeDefault),
      itemBuilder: (context, index) => Container(
        width: cardWidth,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        ),
        child: Shimmer(
          duration: const Duration(seconds: 2),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              height: imageHeight,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(height: 14, width: cardWidth * 0.6, color: Colors.grey[300]),
                const SizedBox(height: 8),
                Container(height: 10, width: cardWidth * 0.8, color: Colors.grey[300]),
                const SizedBox(height: 8),
                Container(height: 10, width: cardWidth * 0.5, color: Colors.grey[300]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
