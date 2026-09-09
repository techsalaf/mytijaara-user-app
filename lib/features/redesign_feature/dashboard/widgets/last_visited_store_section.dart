import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/store/screens/store_screen.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

// "Last Visited Store" — a horizontally scrolling list of stores the user
// recently ordered from. Self-collapsing: renders nothing when repeat ordering
// is unavailable (guest / config off) or once the list has loaded empty, and a
// shimmer while the list is still loading.
class LastVisitedStoreSection extends StatelessWidget {
  const LastVisitedStoreSection({super.key});

  @override
  Widget build(BuildContext context) {
    final bool canShow = AuthHelper.isLoggedIn()
        && Get.find<SplashController>().configModel?.repeatOrderOption == 1;
    if (!canShow) return const SizedBox.shrink();

    final double textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final double cardWidth = MediaQuery.sizeOf(context).width * 0.78;
    final double cardHeight = math.max(56.0, 40 * textScale) + Dimensions.paddingSizeDefault * 2;

    return GetBuilder<StoreController>(builder: (storeController) {
      final List<Store>? storeList = storeController.visitAgainStoreList;
      if (storeList != null && storeList.isEmpty) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
        color: Theme.of(context).disabledColor.withAlpha(50),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: TitleWidget(title: 'last_visited_store'.tr),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          SizedBox(
            height: cardHeight,
            child: storeList == null
                ? _LastVisitedShimmer(cardWidth: cardWidth)
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                    itemCount: storeList.length > 10 ? 10 : storeList.length,
                    separatorBuilder: (context, index) => const SizedBox(width: Dimensions.paddingSizeDefault),
                    itemBuilder: (context, index) => _LastVisitedStoreCard(store: storeList[index], width: cardWidth),
                  ),
          ),
        ]),
      );
    });
  }
}

class _LastVisitedStoreCard extends StatelessWidget {
  final Store store;
  final double width;
  const _LastVisitedStoreCard({required this.store, required this.width});

  String _deliveryInfo() {
    final double? km = store.distanceKm ?? (store.distance != null ? store.distance! / 1000 : null);
    final String distanceText = km != null ? '(${km.toStringAsFixed(1)} km)' : '';
    return <String>[
      if ((store.deliveryTime ?? '').isNotEmpty) store.deliveryTime!,
      if (distanceText.isNotEmpty) distanceText,
    ].join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final String deliveryInfo = _deliveryInfo();

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      ),
      child: CustomInkWell(
        radius: Dimensions.radiusLarge,
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        onTap: () => Get.toNamed(
          RouteHelper.getStoreRoute(id: store.id, page: 'store_new', slug: store.slug ?? ''),
          arguments: StoreScreen(store: store, fromModule: false),
        ),
        child: Row(children: [
          ClipOval(
            child: CustomImage(image: store.logoFullUrl ?? '', height: 56, width: 56, fit: BoxFit.cover),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(
                store.name ?? '',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
              ),

              if (deliveryInfo.isNotEmpty) ...[
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Row(children: [
                  Icon(Icons.directions_bike_rounded, size: 16, color: Theme.of(context).disabledColor),
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                  Flexible(
                    child: Text(
                      deliveryInfo,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).disabledColor),
                    ),
                  ),
                ]),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

class _LastVisitedShimmer extends StatelessWidget {
  final double cardWidth;
  const _LastVisitedShimmer({required this.cardWidth});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      itemCount: 4,
      separatorBuilder: (context, index) => const SizedBox(width: Dimensions.paddingSizeDefault),
      itemBuilder: (context, index) => Container(
        width: cardWidth,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Shimmer(
          duration: const Duration(seconds: 2),
          child: Row(children: [
            Container(
              height: 56, width: 56,
              decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Container(height: 14, width: cardWidth * 0.45, color: Colors.grey[300]),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Container(height: 12, width: cardWidth * 0.35, color: Colors.grey[300]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
