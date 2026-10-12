import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/lazy_sliver.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/brands/controllers/brands_controller.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/flash_sale/controllers/flash_sale_controller.dart';
import 'package:sixam_mart/features/home/controllers/advertisement_controller.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/item/controllers/campaign_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/reels/controllers/reels_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/features/dashboard/widgets/category_section.dart';
import 'package:sixam_mart/features/dashboard/widgets/explore_restaurant_section.dart';
import 'package:sixam_mart/features/bogo_offer/controllers/bogo_offer_controller.dart';
import 'package:sixam_mart/features/bundle/controllers/bundle_controller.dart';
import 'package:sixam_mart/features/bundle/widgets/bundle_section_widget.dart';
import 'package:sixam_mart/features/dashboard/widgets/bogo_offer_card_widget.dart';
import 'package:sixam_mart/features/dashboard/widgets/banner_slider.dart';
import 'package:sixam_mart/features/dashboard/widgets/featured_restaurant.dart';
import 'package:sixam_mart/features/dashboard/widgets/items_you_will_love_section.dart';
import 'package:sixam_mart/features/dashboard/widgets/just_for_you_section.dart';
import 'package:sixam_mart/features/dashboard/widgets/last_orders_section_widget.dart';
import 'package:sixam_mart/features/dashboard/widgets/last_visited_store_section.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';
import 'package:sixam_mart/features/dashboard/widgets/top_picks_near_you_widget.dart';
import 'package:sixam_mart/features/dashboard/widgets/trending_dishes_section.dart';
import 'package:sixam_mart/features/dashboard/widgets/search_header_widget.dart';
import 'package:sixam_mart/features/dashboard/widgets/sliver_gap.dart';
import 'package:sixam_mart/features/brands/widgets/brand_section_widget.dart';
import 'package:sixam_mart/features/dashboard/modules/shop/widgets/shop_flash_sale_header_widget.dart';
import 'package:sixam_mart/features/dashboard/modules/shop/widgets/shop_upto_offer.dart';
import 'package:sixam_mart/features/reels/widgets/reels_section_widget.dart';
import 'package:sixam_mart/helper/module_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/features/home/widgets/views/promotional_banner_view.dart';
import 'package:sliver_tools/sliver_tools.dart';

class ShopModuleScreen extends StatefulWidget {
  final Key searchHeaderKey;
  final Key exploreRestaurantKey;
  final ScrollController scrollController;
  final bool isSearchPinned;
  const ShopModuleScreen({super.key, required this.searchHeaderKey, required this.exploreRestaurantKey, required this.scrollController, this.isSearchPinned = false});

  @override
  State<ShopModuleScreen> createState() => _ShopModuleScreenState();
}

class _ShopModuleScreenState extends State<ShopModuleScreen> {

  // Every section below the fold fetches from its own LazySliver, when it scrolls
  // into view. Only the banner / categories / top-offer above it are fetched on
  // entry, by HomeScreen.loadCriticalModuleData. Nothing is fetched here.

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

      // banner — leading gap collapses with it
      GetBuilder<BannerController>(builder: (controller) {
        final visible = controller.bannerImageList == null || controller.bannerImageList!.isNotEmpty;
        return _conditionalSection(visible: visible, slivers: [
          sliverGepY(value: Dimensions.paddingSizeDefault),
          const SliverToBoxAdapter(child: BannerSliderWidget()),
        ]);
      }),

      // category (title + grid) — whole block collapses when empty
      GetBuilder<CategoryController>(builder: (controller) {
        final visible = controller.categoryList == null || controller.categoryList!.isNotEmpty;
        return _conditionalSection(visible: visible, slivers: [
          sliverGepY(value: Dimensions.paddingSizeDefault),
          sliverPadX(child: TitleWidget(title: 'find_your_flavor'.tr)),
          sliverGepY(value: Dimensions.paddingSizeExtraLarge),
          const SliverToBoxAdapter(child: CategorySection(asList: true)),
        ]);
      }),

      // top offer promo card — has no loading shimmer, so show only when a valid offer exists
      GetBuilder<HomeController>(builder: (controller) {
        final topOffer = controller.topOffer;
        final visible = topOffer != null && topOffer.discount != null && topOffer.discount! > 0;
        return _conditionalSection(visible: visible, slivers: [
          sliverGepY(value: Dimensions.paddingSizeDefault),
          sliverPadX(child: const ShopUpToOffer(variant: TopOfferVariant.shop)),
        ]);
      }),

      // Section: flash sale
      LazySliver(
        onReveal: () => Get.find<FlashSaleController>().getFlashSale(true, false),
        sliver: GetBuilder<FlashSaleController>(builder: (controller) {
          final visible = controller.flashSaleModel == null || (controller.flashSaleModel!.activeProducts?.isNotEmpty ?? false);
          return _conditionalSection(visible: visible, slivers: [
            sliverGepY(value: Dimensions.paddingSizeLarge),
            const SliverToBoxAdapter(child: ShopFlashSaleHeaderWidget()),
          ]);
        }),
      ),

      // reels
      LazySliver(
        onReveal: () => Get.find<ReelsController>().getReelsList(offset: 1),
        sliver: GetBuilder<ReelsController>(builder: (controller) {
          final visible = (controller.reelsList == null && controller.isLoading)
              || (controller.reelsList != null && controller.reelsList!.isNotEmpty);
          return _conditionalSection(visible: visible, slivers: [
            const SliverToBoxAdapter(child: ReelsSectionWidget()),
          ]);
        }),
      ),

      // Section: BOGO offers — the whole block hides itself when no offer is live
      LazySliver(
        onReveal: () => Get.find<BogoOfferController>().getBogoHomeData(),
        sliver: GetBuilder<BogoOfferController>(builder: (controller) {
          // Unlike the other modules there is no gap above this point, so the card
          // brings its own — inside the block, so it collapses with it.
          return _conditionalSection(visible: controller.showHomeCard, slivers: [
            sliverGepY(value: Dimensions.paddingSizeDefault),
            const SliverToBoxAdapter(child: BogoOfferCardWidget()),
          ]);
        }),
      ),

      // Section: just for you (self-collapses when there are no campaigns)
      sliverGepY(value: Dimensions.paddingSizeDefault),
      LazySliver(
        onReveal: () {
          Get.find<CampaignController>().getBasicCampaignList(true);
          Get.find<CampaignController>().getItemCampaignList(true);
        },
        sliver: const SliverToBoxAdapter(child: JustForYouSection()),
      ),

      // Section: bundle items — the block hides itself when the module has no
      // bundles, which is also what the endpoint returns when the feature is off.
      LazySliver(
        onReveal: () {
          if(ModuleHelper.isBundleEnabled(moduleType: AppConstants.ecommerce)) {
            Get.find<BundleController>().getBundleHome();
          }
        },
        sliver: GetBuilder<BundleController>(builder: (controller) {
          return _conditionalSection(visible: controller.homeBundles?.isNotEmpty ?? false, slivers: [
            const SliverToBoxAdapter(child: BundleSectionWidget()),
          ]);
        }),
      ),

      // Section: last orders — section + leading gap collapse when there are no last orders
      LazySliver(
        // Same guard the section applies before rendering — last orders only exist
        // when repeat ordering is on.
        onReveal: () {
          if(AuthHelper.isLoggedIn() && Get.find<SplashController>().configModel?.repeatOrderOption == 1) {
            Get.find<OrderController>().getLastOrders(isHome: false);
          }
        },
        sliver: GetBuilder<OrderController>(builder: (controller) {
          // null means "not fetched yet" and must keep its height while the section
          // loads; only a loaded-but-empty list collapses.
          final visible = controller.lastOrders == null || controller.lastOrders!.isNotEmpty;
          return _conditionalSection(visible: visible, slivers: [
            sliverGepY(value: Dimensions.paddingSizeDefault),
            const SliverToBoxAdapter(child: LastOrdersSectionWidget(moduleType: AppConstants.grocery)),
          ]);
        }),
      ),

      // Section: last visited store (self-collapses when there is nothing to show)
      sliverGepY(value: Dimensions.paddingSizeDefault),
      LazySliver(
        onReveal: () {
          if(AuthHelper.isLoggedIn() && Get.find<SplashController>().configModel?.repeatOrderOption == 1) {
            Get.find<StoreController>().getVisitAgainStoreList(fromModule: true);
          }
        },
        sliver: const SliverToBoxAdapter(child: LastVisitedStoreSection()),
      ),

      // top brands
      LazySliver(
        onReveal: () => Get.find<BrandsController>().getBrandList(),
        sliver: GetBuilder<BrandsController>(builder: (controller) {
          final visible = controller.brandList == null || controller.brandList!.isNotEmpty;
          return _conditionalSection(visible: visible, slivers: [
            sliverGepY(value: Dimensions.paddingSizeSmall),
            SliverToBoxAdapter(child: BrandSectionWidget(title: "top_brands".tr, showLabel: true, showItemCount: true)),
            sliverGepY(value: Dimensions.paddingSizeLarge),
          ]);
        }),
      ),

      // Section: featured stores list — the gap collapses with the list, and the
      // list itself follows below (it is not inside the GetBuilder).
      GetBuilder<AdvertisementController>(builder: (controller) {
        final visible = controller.advertisementList == null || controller.advertisementList!.isNotEmpty;
        return _conditionalSection(visible: visible, slivers: [
          sliverGepY(value: Dimensions.paddingSizeExtraSmall),
        ]);
      }),

      LazySliver(
        onReveal: () => Get.find<AdvertisementController>().getAdvertisementList(),
        sliver: sliverPadX(child: const FeaturedRestaurant(isShop: true)),
      ),
      // SliverToBoxAdapter(child: Container(
      //   height: 5, width: double.infinity, color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
      // )),

      // Section: Recommended For You
      LazySliver(
        onReveal: () => Get.find<StoreController>().getRecommendedStoreList(),
        sliver: GetBuilder<StoreController>(builder: (controller) {
          final visible = controller.recommendedStoreList == null || controller.recommendedStoreList!.isNotEmpty;
          return _conditionalSection(visible: visible, slivers: [
            sliverGepY(value: Dimensions.paddingSizeLarge),
            SliverToBoxAdapter(
              child: TopPicksNearYouWidget(title: "recommended_for_you".tr, isRecommended: true,),
            ),
          ]);
        }),
      ),

      // Section: trending dishes
      LazySliver(
        onReveal: () => Get.find<ItemController>().getDiscountedItemList(offset: '1', firstTimeCategoryLoad: true),
        sliver: GetBuilder<ItemController>(builder: (controller) {
          final visible = controller.discountedItemList == null || controller.discountedItemList!.isNotEmpty;
          return _conditionalSection(visible: visible, slivers: [
            SliverToBoxAdapter(child: TrendingDishesSectionWidget(title: "trending_item".tr)),
          ]);
        }),
      ),

      // Section: items you will love
      LazySliver(
        onReveal: () => Get.find<ItemController>().getPopularItemList(offset: '1', firstTimeCategoryLoad: true),
        sliver: GetBuilder<ItemController>(builder: (controller) {
          final visible = controller.popularItemList == null || controller.popularItemList!.isNotEmpty;
          return _conditionalSection(visible: visible, slivers: [
            sliverGepY(value: Dimensions.paddingSizeDefault),
            SliverToBoxAdapter(child: ItemsYouWillLoveSectionWidget(title: 'items_you_will_love'.tr,)),
          ]);
        }),
      ),

      LazySliver(
        onReveal: () => Get.find<BannerController>().getPromotionalBannerList(true),
        sliver: const PromotionalBannerSliver(),
      ),
      sliverGepY(value: Dimensions.paddingSizeDefault),

      SliverToBoxAdapter(child: Container(
        height: 5, width: double.infinity, color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
      )),
      sliverGepY(value: Dimensions.paddingSizeDefault),

      LazySliver(
        onReveal: () => Get.find<StoreController>().getStoreList(1, true),
        sliver: ExploreRestaurantSection(title: 'explore_shop'.tr, exploreRestaurantKey: widget.exploreRestaurantKey, scrollController: widget.scrollController),
      ),

    ]
    );
  }
}

// Renders a section together with its leading/trailing spacing, or nothing at
// all — dropping the gap — when the section has loaded but is empty. Always
// returns exactly one sliver so it stays valid inside the parent MultiSliver.
Widget _conditionalSection({required bool visible, required List<Widget> slivers}) {
  return visible
      ? MultiSliver(children: slivers)
      : const SliverToBoxAdapter(child: SizedBox.shrink());
}
