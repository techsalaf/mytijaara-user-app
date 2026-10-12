import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/lazy_sliver.dart';
import 'package:sixam_mart/features/address/controllers/address_controller.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/brands/controllers/brands_controller.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/coupon/controllers/coupon_controller.dart';
import 'package:sixam_mart/features/flash_sale/controllers/flash_sale_controller.dart';
import 'package:sixam_mart/features/home/controllers/advertisement_controller.dart';
import 'package:sixam_mart/features/happy_hour/controllers/happy_hour_controller.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/item/controllers/campaign_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/notification/controllers/notification_controller.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/parcel/controllers/parcel_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/reels/controllers/reels_controller.dart';
import 'package:sixam_mart/features/rental_module/home/controllers/taxi_home_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/controllers/taxi_cart_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
class HomeScreen {
  static const Set<String> _lazyModules = {
    AppConstants.food, AppConstants.grocery, AppConstants.ecommerce, AppConstants.pharmacy,
  };

  static bool isLazyModule(String? moduleType) => moduleType != null && _lazyModules.contains(moduleType);

  static void loadCriticalModuleData(String moduleType, bool reload) {
    switch(moduleType) {
      case AppConstants.food:
        Get.find<CategoryController>().getCategoryList(reload);
        Get.find<BannerController>().getBannerList(reload);
        Get.find<HomeController>().getTopOffer(notify: false);

      case AppConstants.grocery:
        Get.find<CategoryController>().getCategoryList(reload);
        Get.find<HomeController>().getTopOffer(notify: false);
        Get.find<BannerController>().getBannerList(reload);

      case AppConstants.ecommerce:
        Get.find<BannerController>().getBannerList(reload);
        Get.find<CategoryController>().getCategoryList(reload);
        Get.find<HomeController>().getTopOffer(notify: false);

      case AppConstants.pharmacy:
        Get.find<ItemController>().getCommonConditions(false);
        Get.find<CategoryController>().getCategoryList(reload);
    }
  }

  static Future<void> loadData(bool reload, {bool fromModule = false}) async {
    print('===== Home Screen Load Data =====');
    Get.find<LocationController>().syncZoneData();
    Get.find<FlashSaleController>().setEmptyFlashSale(fromModule: fromModule);

    final String moduleType = Get.find<SplashController>().module?.moduleType.toString() ?? '';
    final bool isStoreModule = Get.find<SplashController>().module != null
        && moduleType != AppConstants.ride
        && !Get.find<SplashController>().configModel!.moduleConfig!.module!.isParcel!
        && !Get.find<SplashController>().configModel!.moduleConfig!.module!.isTaxi!;


    if(reload && !fromModule) {
      LazyRefreshNotifier.bump();
    }

    // Driven from here rather than the controller's onInit so it also re-runs when the
    // user switches module — a Happy Hour belongs to the module it was configured for.
    if(isStoreModule) {
      Get.find<HappyHourController>().getRunningHappyHour();
    }

    if(isStoreModule && isLazyModule(moduleType)) {
      // Converted module: only the above-the-fold fetches. Every other section is
      // wrapped in a LazySliver in the module screen and fetches when scrolled to.
      loadCriticalModuleData(moduleType, reload);
    }
    else if(isStoreModule) {

      if(AuthHelper.isLoggedIn() && Get.find<SplashController>().configModel!.repeatOrderOption == 1) {
        Get.find<StoreController>().getVisitAgainStoreList(fromModule: fromModule);
      }

      Get.find<BannerController>().getBannerList(reload);
      Get.find<StoreController>().getRecommendedStoreList();
      if(Get.find<SplashController>().module!.moduleType.toString() == AppConstants.grocery) {
        Get.find<FlashSaleController>().getFlashSale(reload, false);
      }
      if(Get.find<SplashController>().module!.moduleType.toString() == AppConstants.ecommerce) {
        Get.find<ItemController>().getFeaturedCategoriesItemList(false, false);
        Get.find<FlashSaleController>().getFlashSale(reload, false);
        Get.find<BrandsController>().getBrandList();
      }
      if(Get.find<SplashController>().module!.moduleType.toString() == AppConstants.grocery) {
        Get.find<BrandsController>().getBrandList();
      }
      Get.find<BannerController>().getPromotionalBannerList(reload);
      Get.find<ReelsController>().getReelsList(offset: 1);
      Get.find<ItemController>().getDiscountedItemList(offset: '1', firstTimeCategoryLoad: true);
      Get.find<ItemController>().getPopularItemList(offset: '1', firstTimeCategoryLoad: true);
      Get.find<ItemController>().getReviewedItemList(offset: '1', firstTimeCategoryLoad: true);
      Get.find<CategoryController>().getCategoryList(reload);
      Get.find<StoreController>().getPopularStoreList(reload, 'all', false);
      Get.find<CampaignController>().getBasicCampaignList(reload);
      Get.find<CampaignController>().getItemCampaignList(reload);
      Get.find<StoreController>().getLatestStoreList(reload, 'all', false);
      Get.find<StoreController>().getTopOfferStoreList(reload, false);
      Get.find<ItemController>().getRecommendedItemList(reload, 'all', false);
      Get.find<StoreController>().getStoreList(1, reload);
      Get.find<AdvertisementController>().getAdvertisementList();

      if(moduleType == AppConstants.food || moduleType == AppConstants.grocery || moduleType == AppConstants.pharmacy) {
        Get.find<StoreController>().getQuickDeliveryStoreList(reload: reload);
      }
    }
    if(AuthHelper.isLoggedIn()) {
      await Get.find<ProfileController>().getUserInfo();
      Get.find<NotificationController>().getNotificationList(reload);
      if(Get.find<SplashController>().configModel!.repeatOrderOption == 1) {
        Get.find<OrderController>().getLastOrders(reload: reload, isHome: true);
        if(!isLazyModule(moduleType)) {
          Get.find<OrderController>().getLastOrders(reload: reload, isHome: false);
        }
      }
      if(!Get.find<SplashController>().configModel!.moduleConfig!.module!.isRide!) {
        Get.find<CouponController>().getCouponList();
      }
    }
    Get.find<SplashController>().getModules();
    if(Get.find<SplashController>().module == null && Get.find<SplashController>().configModel!.module == null) {
      Get.find<BannerController>().getFeaturedBanner();
      Get.find<StoreController>().getFeaturedStoreList();
      if(AuthHelper.isLoggedIn()) {
        Get.find<AddressController>().getAddressList();
      }
    }
    if(Get.find<SplashController>().module != null && Get.find<SplashController>().configModel!.moduleConfig!.module!.isParcel!) {
      Get.find<ParcelController>().getParcelCategoryList();

      Get.find<BannerController>().getPromotionalBannerList(reload);
    }
    if(!isLazyModule(moduleType)
        && Get.find<SplashController>().module != null
        && Get.find<SplashController>().module!.moduleType.toString() == AppConstants.pharmacy) {
      Get.find<ItemController>().getBasicMedicine(reload, false);
      Get.find<StoreController>().getFeaturedStoreList();
      Get.find<StoreController>().getVerifiedStoreList(reload: reload, notify: false);
      Get.find<ItemController>().getCommonConditions(false);
    }
  }

  static Future<void> loadTaxiApis() async {
    await Get.find<TaxiHomeController>().getTaxiBannerList(true);
    await Get.find<TaxiHomeController>().getTopRatedCarList(1, true);
    if (AuthHelper.isLoggedIn()) {
      await Get.find<AddressController>().getAddressList();
      await Get.find<TaxiHomeController>().getTaxiCouponList(true);
      await Get.find<TaxiCartController>().getCarCartList();
    }
  }
}