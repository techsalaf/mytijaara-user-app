import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/brands/controllers/brands_controller.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/flash_sale/controllers/flash_sale_controller.dart';
import 'package:sixam_mart/features/home/controllers/advertisement_controller.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/banner_slider.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/category_section.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/explore_restaurant_section.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/featured_restaurant.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/items_you_will_love_section.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/just_for_you_section.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/last_orders_section_widget.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/last_visited_store_section.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/search_header_widget.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/sliver_gap.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/todays_deals_section.dart';
import 'package:sixam_mart/features/redesign_feature/global_widgets/brand_section_widget.dart';
import 'package:sixam_mart/features/redesign_feature/pharmacy/widget/quick_and_emergency_deliery_widget.dart';
import 'package:sixam_mart/features/redesign_feature/shop/widget/shop_flash_sale_header_widget.dart';
import 'package:sixam_mart/features/redesign_feature/shop/widget/shop_upto_offer.dart';
import 'package:sixam_mart/features/reels/controllers/reels_controller.dart';
import 'package:sixam_mart/features/reels/widgets/reels_section_widget.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sliver_tools/sliver_tools.dart';

class GroceryModuleScreen extends StatefulWidget {
  final Key searchHeaderKey;
  final Key exploreRestaurantKey;
  final ScrollController scrollController;
  final bool isSearchPinned;
  const GroceryModuleScreen({super.key, required this.searchHeaderKey, required this.exploreRestaurantKey, required this.scrollController, this.isSearchPinned = false});

  @override
  State<GroceryModuleScreen> createState() => _GroceryModuleScreenState();
}

class _GroceryModuleScreenState extends State<GroceryModuleScreen> {

  @override
  void initState() {

    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_){
      Get.find<OrderController>().getLastOrders(isHome: false);
      Get.find<HomeController>().getTopOffer(notify: false);
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

      // Find Your Food section
      sliverGepY(value: Dimensions.paddingSizeExtraSmall),
      sliverPadX(child: TitleWidget(title: 'shop_by_categories'.tr)),
      sliverGepY(value: Dimensions.paddingSizeDefault),

      // category — collapses (with its gap) when empty
      GetBuilder<CategoryController>(builder: (controller) {
        final visible = controller.categoryList == null || controller.categoryList!.isNotEmpty;
        return _conditionalSection(visible: visible, slivers: [
          const SliverToBoxAdapter(child: CategorySection(asList: false)),
          sliverGepY(value: Dimensions.paddingSizeLarge),
        ]);
      }),

      // top offer promo card — has no loading shimmer, so show only when a valid offer exists
      GetBuilder<HomeController>(builder: (controller) {
        final topOffer = controller.topOffer;
        final visible = topOffer != null && topOffer.discount != null && topOffer.discount! > 0;
        return _conditionalSection(visible: visible, slivers: [
          sliverPadX(child: const ShopUpToOffer(variant: TopOfferVariant.grocery)),
          sliverGepY(value: Dimensions.paddingSizeLarge),
        ]);
      }),

      // banner
      GetBuilder<BannerController>(builder: (controller) {
        final visible = controller.bannerImageList == null || controller.bannerImageList!.isNotEmpty;
        return _conditionalSection(visible: visible, slivers: [
          const SliverToBoxAdapter(child: BannerSliderWidget()),
          sliverGepY(value: Dimensions.paddingSizeDefault),
        ]);
      }),

      // Section: flash sale
      GetBuilder<FlashSaleController>(builder: (controller) {
        final visible = controller.flashSaleModel == null || (controller.flashSaleModel!.activeProducts?.isNotEmpty ?? false);
        return _conditionalSection(visible: visible, slivers: [
          sliverGepY(value: Dimensions.paddingSizeLarge),
          const SliverToBoxAdapter(child: ShopFlashSaleHeaderWidget()),
        ]);
      }),

      // Section: today's deals
      GetBuilder<ItemController>(builder: (controller) {
        final visible = controller.discountedItemList == null || controller.discountedItemList!.isNotEmpty;
        return _conditionalSection(visible: visible, slivers: [
          const SliverToBoxAdapter(child: TodaysDealsSectionWidget()),
          sliverGepY(value: Dimensions.paddingSizeSmall),
        ]);
      }),

      // reels
      GetBuilder<ReelsController>(builder: (controller) {
        final visible = (controller.reelsList == null && controller.isLoading)
            || (controller.reelsList != null && controller.reelsList!.isNotEmpty);
        return _conditionalSection(visible: visible, slivers: [
          const SliverToBoxAdapter(child: ReelsSectionWidget()),
          sliverGepY(value: Dimensions.paddingSizeDefault),
        ]);
      }),

      // Section: just for you (self-collapses when there are no campaigns)
      const SliverToBoxAdapter(child: JustForYouSection()),
      sliverGepY(value: Dimensions.paddingSizeDefault),

      // Section: last orders — section + gap collapse when there are no last orders
      GetBuilder<OrderController>(builder: (controller) {
        final visible = controller.lastOrders?.isNotEmpty ?? false;
        return _conditionalSection(visible: visible, slivers: [
          const SliverToBoxAdapter(child: LastOrdersSectionWidget(moduleType: AppConstants.grocery)),
          sliverGepY(value: Dimensions.paddingSizeDefault),
        ]);
      }),

      // Section: last visited store (self-collapses when there is nothing to show)
      const SliverToBoxAdapter(child: LastVisitedStoreSection()),
      sliverGepY(value: Dimensions.paddingSizeDefault),

      // top brands
      GetBuilder<BrandsController>(builder: (controller) {
        final visible = controller.brandList == null || controller.brandList!.isNotEmpty;
        return _conditionalSection(visible: visible, slivers: [
          const SliverToBoxAdapter(child: BrandSectionWidget(showLabel: true, showItemCount: true)),
          sliverGepY(value: Dimensions.paddingSizeLarge),
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

      // Section: quick & emergency delivery — collapse the whole gradient block + gap when empty
      GetBuilder<StoreController>(builder: (controller) {
        final stores = controller.quickDeliveryStoreList?.stores;
        final visible = controller.quickDeliveryStoreList == null || (stores != null && stores.isNotEmpty);
        // Warm "express delivery" wash. Light mode keeps the cream tint; dark mode
        // uses a subtle amber glow fading to transparent so it isn't a bright band.
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        final Color tint = isDark ? const Color(0xFFFFC107) : const Color(0xFFFFF1C2);
        final List<Color> expressGradient = isDark
            ? [
                tint.withValues(alpha: 0.18),
                tint.withValues(alpha: 0.18),
                tint.withValues(alpha: 0.10),
                tint.withValues(alpha: 0.10),
                tint.withValues(alpha: 0.0),
              ]
            : [
                const Color(0xFFFFF1C2),
                const Color(0xFFFFF1C2),
                const Color(0xFFFFF1C2).withValues(alpha: 0.5),
                const Color(0xFFFFF1C2).withValues(alpha: 0.5),
                const Color(0xFFFFFBEB).withValues(alpha: 0.01),
              ];
        return _conditionalSection(visible: visible, slivers: [
          SliverToBoxAdapter(child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: expressGradient, begin: Alignment.bottomCenter, end: Alignment.topCenter),
            ),
            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
            child: QuickAndEmergencyDeliveryWidget(isQuick: true, title: "express_delivery".tr, subTitle: 'fastest_delivery_store'.tr,),
          )),
          sliverGepY(value: Dimensions.paddingSizeDefault),
        ]);
      }),

      // Section: items you will love (self-collapses; no trailing gap)
      SliverToBoxAdapter(child: ItemsYouWillLoveSectionWidget(title: 'top_picks'.tr, subTitle: 'based_on_your_recent_activity'.tr)),

      SliverToBoxAdapter(child: Container(
        height: 5, width: double.infinity, color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
      )),
      sliverGepY(value: Dimensions.paddingSizeDefault),
      // Section: explore restaurants
      ExploreRestaurantSection(exploreRestaurantKey: widget.exploreRestaurantKey, scrollController: widget.scrollController, title: 'explore_stores'.tr,),
    ]
    );
  }
}

// Renders a section together with its trailing spacing (gap / divider), or
// nothing at all — dropping the gap — when the section has loaded but is empty.
// Always returns exactly one sliver so it stays valid inside the parent MultiSliver.
Widget _conditionalSection({required bool visible, required List<Widget> slivers}) {
  return visible
      ? MultiSliver(children: slivers)
      : const SliverToBoxAdapter(child: SizedBox.shrink());
}
