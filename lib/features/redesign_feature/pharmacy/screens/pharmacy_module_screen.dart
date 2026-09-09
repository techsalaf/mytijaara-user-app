import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/home/controllers/advertisement_controller.dart';
import 'package:sixam_mart/features/item/controllers/campaign_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/reels/controllers/reels_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/banner_slider.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/category_section.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/explore_restaurant_section.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/featured_restaurant.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/last_orders_section_widget.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/last_visited_store_section.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/search_header_widget.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/sliver_gap.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/top_picks_near_you_widget.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/just_for_you_section.dart';
import 'package:sixam_mart/features/redesign_feature/pharmacy/widget/quick_and_emergency_deliery_widget.dart';
import 'package:sixam_mart/features/redesign_feature/pharmacy/widget/quick_delivery_card.dart';
import 'package:sixam_mart/features/redesign_feature/pharmacy/widget/shop_by_condition.dart';
import 'package:sixam_mart/features/reels/widgets/reels_section_widget.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sliver_tools/sliver_tools.dart';

class PharmacyModuleScreen extends StatefulWidget {
  final Key searchHeaderKey;
  final Key exploreRestaurantKey;
  final ScrollController scrollController;
  final bool isSearchPinned;
  const PharmacyModuleScreen({super.key, required this.searchHeaderKey, required this.exploreRestaurantKey, required this.scrollController, this.isSearchPinned = false});

  @override
  State<PharmacyModuleScreen> createState() => _PharmacyModuleScreenState();
}

class _PharmacyModuleScreenState extends State<PharmacyModuleScreen> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_){
      Get.find<OrderController>().getLastOrders(isHome: false);    
    });
  }

  
  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      // Section: search and quick filters
      SliverToBoxAdapter(
        child: Visibility(
          visible: !widget.isSearchPinned,
          maintainSize: true, maintainState: true, maintainAnimation: true,
          child: SearchAndQuickFilterWidget(key: widget.searchHeaderKey, isPinned: false),
        ),
      ),

      sliverGepY(value: Dimensions.paddingSizeExtraSmall),

      // shop by condition — section + gap collapse when empty
      GetBuilder<ItemController>(builder: (controller) {
        final visible = controller.commonConditions == null || controller.commonConditions!.isNotEmpty;
        return _conditionalSection(visible: visible, slivers: [
          ShopByConditionSection(title: 'shop_by_condition'.tr,),
          sliverGepY(value: Dimensions.paddingSizeExtraOverLarge),
        ]);
      }),

      // category — whole gradient block + gap collapse when empty
      GetBuilder<CategoryController>(builder: (controller) {
        final visible = controller.categoryList == null || controller.categoryList!.isNotEmpty;
        return _conditionalSection(visible: visible, slivers: [
          SliverToBoxAdapter(child: Container(
            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusLarge)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blueAccent.withAlpha(30), Colors.blueAccent.withAlpha(5),],
              )
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                  child: TitleWidget(title: 'shop_by_categories'.tr),
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault,),
                const CategorySection(asList: false),
              ],
            ),
          )),
          sliverGepY(value: Dimensions.paddingSizeExtraSmall),
        ]);
      }),

      GetBuilder<OrderController>(builder: (controller) {
        final visible = controller.lastOrders?.isNotEmpty ?? false;
        return _conditionalSection(visible: visible, slivers: [
          const SliverToBoxAdapter(child: LastOrdersSectionWidget(moduleType: AppConstants.pharmacy)),
          sliverGepY(value: Dimensions.paddingSizeDefault),
        ]);
      }),

      const SliverToBoxAdapter(child: LastVisitedStoreSection()),
      sliverGepY(value: Dimensions.paddingSizeDefault),

      // banner
      GetBuilder<BannerController>(builder: (controller) {
        final visible = controller.bannerImageList == null || controller.bannerImageList!.isNotEmpty;
        return _conditionalSection(visible: visible, slivers: [
          const SliverToBoxAdapter(child: BannerSliderWidget()),
          sliverGepY(value: Dimensions.paddingSizeDefault),
        ]);
      }),

      GetBuilder<StoreController>(builder: (controller) {
        final quickStores = controller.quickDeliveryStoreList?.stores;
        final bool quickVisible = controller.quickDeliveryStoreList == null || (quickStores != null && quickStores.isNotEmpty);
        final bool verifiedVisible = controller.latestStoreList == null || controller.latestStoreList!.isNotEmpty;
        return _conditionalSection(visible: quickVisible || verifiedVisible, slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.blueAccent.withAlpha(30),
                    Colors.blueAccent.withAlpha(5),
                  ],
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  // Section: quick Delivery
                  QuickAndEmergencyDeliveryWidget(isQuick: true, title: "quick_emergency_delivery".tr, subTitle: 'fastest_delivery_pharmacy'.tr,),
                  const SizedBox(height: Dimensions.paddingSizeLarge),

                  // Section: top picks carousel
                  TopPicksNearYouWidget(title: "verified_pharmacies".tr, subTitle: "secure_buying_experience".tr,),
                  // const SizedBox(height: Dimensions.paddingSizeDefault),
                ],
              ),
            ),
          ),
        ]);
      }),

      // Section: featured stores list
      GetBuilder<AdvertisementController>(builder: (controller) {
        final visible = controller.advertisementList == null || controller.advertisementList!.isNotEmpty;
        return _conditionalSection(visible: visible, slivers: [
          sliverPadX(child: const FeaturedRestaurant()),
          sliverGepY(value: Dimensions.paddingSizeDefault),
        ]);
      }),

      // reels
      GetBuilder<ReelsController>(builder: (controller) {
        final visible = (controller.reelsList == null && controller.isLoading)
            || (controller.reelsList != null && controller.reelsList!.isNotEmpty);
        return _conditionalSection(visible: visible, slivers: [
          const SliverToBoxAdapter(child: ReelsSectionWidget()),
        ]);
      }),

      GetBuilder<CampaignController>(builder: (controller) {
        final visible = controller.itemCampaignList == null || controller.itemCampaignList!.isNotEmpty;
        return _conditionalSection(visible: visible, slivers: [
          sliverGepY(value: Dimensions.paddingSizeSmall),
          const SliverToBoxAdapter(child: JustForYouSection()),
        ]);
      }),

      // Section: self care / OTC — leading + trailing gap collapse with it
      GetBuilder<ItemController>(builder: (controller) {
        final products = controller.basicMedicineModel?.products;
        final visible = products == null || products.isNotEmpty;
        return _conditionalSection(visible: visible, slivers: [
          sliverGepY(value: Dimensions.paddingSizeDefault),
          SliverToBoxAdapter(child: QuickDeliveryCardSection(title: 'self_care_otc'.tr, subTitle:'no_prescription_required'.tr)),
          sliverGepY(value: Dimensions.paddingSizeDefault),
        ]);
      }),

      SliverToBoxAdapter(child: Container(
        height: 5, width: double.infinity, color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
      )),
      sliverGepY(value: Dimensions.paddingSizeDefault),
      // Section: explore restaurants
      ExploreRestaurantSection(title: 'explore_pharmacy'.tr ,exploreRestaurantKey: widget.exploreRestaurantKey, scrollController: widget.scrollController),

    ]);
  }
}

// Renders a section together with its trailing/leading spacing, or nothing at
// all — dropping the gap — when the section has loaded but is empty. Always
// returns exactly one sliver so it stays valid inside the parent MultiSliver.
Widget _conditionalSection({required bool visible, required List<Widget> slivers}) {
  return visible
      ? MultiSliver(children: slivers)
      : const SliverToBoxAdapter(child: SizedBox.shrink());
}
