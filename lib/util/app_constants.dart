import 'package:get/get.dart';
import 'package:sixam_mart/common/models/choose_us_model.dart';
import 'package:sixam_mart/features/language/domain/models/language_model.dart';
import 'package:sixam_mart/util/images.dart';

class AppConstants {
  static const String appName = '6amMart';
  static const double appVersion = 4.0; ///Flutter sdk 3.44.2

  static const String fontFamily = 'DMSans';
  static const bool payInWevView = false;
  static const int balanceInputLen = 10;
  static const String webHostedUrl = 'https://6ammart-react.6amtech.com';
  static const bool stopPolylineAnimation = false;
  static const String googleServerClientId = '491987943015-agln6biv84krpnngdphj87jkko7r9lb8.apps.googleusercontent.com';
  static const String pusherBroadcustUrl = '/api/v1/broadcasting/user-auth';

  static const String baseUrl = 'https://6ammart-admin.6amtech.com';
  static const String categoryUri = '/api/v1/categories';
  static const String topCategoriesUri = '/api/v1/categories/top';
  static const String trendingSearchesUri = '/api/v1/trending-searches';
  static const String bannerUri = '/api/v1/banners';
  static const String smartBannerUri = '/api/v1/smart-banners';
  static const String storeItemUri = '/api/v1/items/latest';
  static const String popularItemUri = '/api/v1/items/popular';
  static const String reviewedItemUri = '/api/v1/items/most-reviewed';
  static const String searchItemUri = '/api/v1/items/details/';
  static const String subCategoryUri = '/api/v1/categories/childes/';
  static const String categoryItemUri = '/api/v1/categories/items/';
  static const String categoryStoreUri = '/api/v1/categories/stores/';
  static const String configUri = '/api/v1/config';
  static const String trackUri = '/api/v1/customer/order/track?order_id=';
  static const String messageUri = '/api/v1/customer/message/get';
  static const String forgetPasswordUri = '/api/v1/auth/forgot-password';
  static const String verifyTokenUri = '/api/v1/auth/verify-token';
  static const String resetPasswordUri = '/api/v1/auth/reset-password';
  static const String verifyPhoneUri = '/api/v1/auth/verify-phone';
  static const String checkEmailUri = '/api/v1/auth/check-email';
  static const String verifyEmailUri = '/api/v1/auth/verify-email';
  static const String registerUri = '/api/v1/auth/sign-up';
  static const String loginUri = '/api/v1/auth/login';
  static const String tokenUri = '/api/v1/customer/cm-firebase-token';
  static const String placeOrderUri = '/api/v1/customer/order/place';
  static const String placePrescriptionOrderUri = '/api/v1/customer/order/prescription/place';
  static const String addressListUri = '/api/v1/customer/address/list';
  static const String zoneUri = '/api/v1/config/get-zone-id';
  static const String checkZoneUri = '/api/v1/zone/check';
  static const String removeAddressUri = '/api/v1/customer/address/delete?address_id=';
  static const String addAddressUri = '/api/v1/customer/address/add';
  static const String updateAddressUri = '/api/v1/customer/address/update/';
  static const String setMenuUri = '/api/v1/items/set-menu';
  static const String customerInfoUri = '/api/v1/customer/info';
  static const String couponUri = '/api/v1/coupon/list';
  static const String couponApplyUri = '/api/v1/coupon/apply?code=';
  static const String allOrderList = '/api/v1/customer/order/list';
  static const String orderCancelUri = '/api/v1/customer/order/cancel';
  static const String orderDeleteUri = '/api/v1/customer/order/delete';
  static const String codSwitchUri = '/api/v1/customer/order/payment-method';
  static const String walletSwitchUri = '/api/v1/customer/order/wallet-payment';
  static const String orderDetailsUri = '/api/v1/customer/order/details?order_id=';
  static const String wishListGetUri = '/api/v1/customer/wish-list';
  static const String addWishListUri = '/api/v1/customer/wish-list/add?';
  static const String removeWishListUri = '/api/v1/customer/wish-list/remove?';
  static const String notificationUri = '/api/v1/customer/notifications';
  static const String updateProfileUri = '/api/v1/customer/update-profile';
  static const String searchUri = '/api/v1/';
  static const String reviewUri = '/api/v1/items/reviews/submit';
  static const String itemDetailsUri = '/api/v1/items/details/';
  static const String lastLocationUri = '/api/v1/delivery-man/last-location?order_id=';
  static const String deliveryManReviewUri = '/api/v1/delivery-man/reviews/submit';
  static const String storeUri = '/api/v1/stores/get-stores';
  static const String exclusiveDealsUri = '/api/v1/stores/exclusive-deals';
  static const String popularStoreUri = '/api/v1/stores/popular';
  static const String latestStoreUri = '/api/v1/stores/latest';
  static const String topOfferStoreUri = '/api/v1/stores/top-offer-near-me';
  static const String storeDetailsUri = '/api/v1/stores/details/';
  static const String basicCampaignUri = '/api/v1/campaigns/basic';
  static const String itemCampaignUri = '/api/v1/campaigns/item';
  static const String basicCampaignDetailsUri = '/api/v1/campaigns/basic-campaign-details?basic_campaign_id=';
  static const String interestUri = '/api/v1/customer/update-interest';
  static const String suggestedItemUri = '/api/v1/customer/suggested-items';
  static const String storeReviewUri = '/api/v1/stores/reviews';
  static const String distanceMatrixUri = '/api/v1/config/distance-api';
  static const String searchLocationUri = '/api/v1/config/place-api-autocomplete';
  static const String placeDetailsUri = '/api/v1/config/place-api-details';
  static const String geocodeUri = '/api/v1/config/geocode-api';
  static const String socialLoginUri = '/api/v1/auth/social-login';
  static const String socialRegisterUri = '/api/v1/auth/social-register';
  static const String updateZoneUri = '/api/v1/customer/update-zone';
  static const String moduleUri = '/api/v1/module';
  static const String topOfferUri = '/api/v1/module/top-offer';
  static const String parcelCategoryUri = '/api/v1/parcel-category';
  static const String aboutUsUri = '/api/v1/about-us';
  static const String privacyPolicyUri = '/api/v1/privacy-policy';
  static const String termsAndConditionUri = '/api/v1/terms-and-conditions';
  static const String cancellationUri = '/api/v1/cancelation';
  static const String refundUri = '/api/v1/refund-policy';
  static const String shippingPolicyUri = '/api/v1/shipping-policy';
  static const String subscriptionUri = '/api/v1/newsletter/subscribe';
  static const String customerRemoveUri = '/api/v1/customer/remove-account';
  static const String walletTransactionUri = '/api/v1/customer/wallet/transactions';
  static const String loyaltyTransactionUri = '/api/v1/customer/loyalty-point/transactions';
  static const String loyaltyPointTransferUri = '/api/v1/customer/loyalty-point/point-transfer';
  static const String zoneListUri = '/api/v1/zone/list';
  static const String storeRegisterUri = '/api/v1/auth/vendor/register';
  static const String dmRegisterUri = '/api/v1/auth/delivery-man/store';
  static const String refundReasonUri = '/api/v1/customer/order/refund-reasons';
  static const String supportReasonUri = '/api/v1/customer/automated-message';
  static const String refundRequestUri = '/api/v1/customer/order/refund-request';
  static const String directionUri = '/api/v1/config/direction-api';
  static const String vehicleListUri = '/api/v1/vehicles/list';
  static const String taxiCouponUri = '/api/v1/coupon/list/taxi';
  static const String taxiBannerUri = '/api/v1/banners/taxi';
  static const String topRatedVehiclesListUri = '/api/v1/vehicles/top-rated/list';
  static const String bandListUri = '/api/v1/vehicles/brand/list';
  static const String tripPlaceUri = '/api/v1/trip/place';
  static const String runningTripUri = '/api/v1/trip/list';
  static const String vehicleChargeUri = '/api/v1/vehicle/extra_charge';
  static const String vehiclesUri = '/api/v1/get-vehicles';
  static const String storeRecommendedItemUri = '/api/v1/items/recommended';
  static const String storeCategoryItemsUri = '/api/v1/store-categories/items';
  static const String orderCancellationUri = '/api/v1/customer/order/cancellation-reasons';
  static const String cartStoreSuggestedItemsUri = '/api/v1/items/suggested';
  static const String mostTipsUri = '/api/v1/most-tips';
  static const String addFundUri = '/api/v1/customer/wallet/add-fund';
  static const String walletBonusUri = '/api/v1/customer/wallet/bonuses';
  static const String guestLoginUri = '/api/v1/auth/guest/request';
  static const String offlineMethodListUri = '/api/v1/offline_payment_method_list';
  static const String offlinePaymentSaveInfoUri = '/api/v1/customer/order/offline-payment';
  static const String offlinePaymentUpdateInfoUri = '/api/v1/customer/order/offline-payment-update';
  static const String storeBannersUri = '/api/v1/banners/';
  static const String recommendedItemsUri = '/api/v1/items/recommended?filter=';
  static const String visitAgainStoreUri = '/api/v1/customer/visit-again';
  static const String discountedItemsUri = '/api/v1/items/discounted';
  static const String parcelOtherBannerUri = '/api/v1/other-banners';
  static const String whyChooseUri = '/api/v1/other-banners/why-choose';
  static const String videoContentUri = '/api/v1/other-banners/video-content';
  static const String promotionalBannerUri = '/api/v1/other-banners';
  static const String basicMedicineUri = '/api/v1/items/basic';
  static const String commonConditionUri = '/api/v1/common-condition';
  static const String conditionWiseItemUri = '/api/v1/common-condition/items/';
  static const String flashSaleUri = '/api/v1/flash-sales';
  static const String flashSaleProductsUri = '/api/v1/flash-sales/items';
  static const String featuredCategoriesItemsUri = '/api/v1/categories/featured/items';
  static const String recommendedStoreUri = '/api/v1/stores/recommended';
  static const String parcelInstructionUri = '/api/v1/customer/order/parcel-instructions';
  static const String cashBackOfferListUri = '/api/v1/cashback/list';
  static const String getCashBackAmountUri = '/api/v1/cashback/getCashback';
  static const String brandListUri = '/api/v1/brand';
  static const String brandItemUri = '/api/v1/brand/items';
  static const String advertisementListUri = '/api/v1/advertisement/list';
  static const String searchSuggestionsUri = '/api/v1/items/item-or-store-search';
  static const String searchPopularCategoriesUri = '/api/v1/categories/popular';
  static const String firebaseAuthVerify = '/api/v1/auth/firebase-verify-token';
  static const String personalInformationUri = '/api/v1/auth/update-info';
  static const String firebaseResetPassword = '/api/v1/auth/firebase-reset-password';
  static const String getOrderTaxUri = '/api/v1/customer/order/get-Tax';
  static const String getSurgePriceUri = '/api/v1/customer/order/get-surge-price';
  static const String customerParcelReturn = '/api/v1/customer/order/parcel-return';
  static const String getMetaData = '/api/v1/get-metadata';
  static const String paymentFailedDetailsUri = '/api/v1/customer/order/payment-failed';
  static const String appDownloadSectionUri = '/api/v1/app-download-section';
  static const String offerItemsUri = '/api/v1/offers/items';
  static const String offerStoresUri = '/api/v1/offers/stores';
  static const String quickDeliveryStoresUri = '/api/v1/stores/quick-delivery';
  static const String distanceStoresUri = '/api/v1/stores/distance';

  ///Subscription
  static const String businessPlanUri = '/api/v1/vendor/business_plan';
  static const String businessPlanPaymentUri = '/api/v1/vendor/subscription/payment/api';
  static const String storePackagesUri = '/api/v1/vendor/package-view';

  ///AI chatting
  static const String aiChatConversationListUri = '/api/v1/customer/ai-chat/conversations';
  static const String aiChatMessagesUri = '/api/v1/customer/ai-chat/messages';
  static const String aiChatSendMessageUri = '/api/v1/customer/ai-chat/send';

  /// MESSAGING
  static const String conversationListUri = '/api/v1/customer/message/list';
  static const String searchConversationListUri = '/api/v1/customer/message/search-list';
  static const String messageListUri = '/api/v1/customer/message/details';
  static const String sendMessageUri = '/api/v1/customer/message/send';

  /// Cart
  static const String getCartListUri = '/api/v1/customer/cart/list';
  static const String getAllCartsUri = '/api/v1/customer/cart/get-all';
  static const String addCartUri = '/api/v1/customer/cart/add';
  static const String updateCartUri = '/api/v1/customer/cart/update';
  static const String removeAllCartUri = '/api/v1/customer/cart/remove';
  static const String removeItemCartUri = '/api/v1/customer/cart/remove-item';

  // Review
  static const String getReviewListUri = '/api/v1/items/reviews';

  ///taxi
  static const String getTopRatedCarsUri = '/api/v1/rental/vehicle/top-rated';
  static const String getTaxiBannerUri = '/api/v1/rental/banners';
  static const String getTaxiCouponUri = '/api/v1/rental/coupon/list';
  static const String taxiCouponApplyUri = '/api/v1/rental/coupon/apply';
  static const String getVehicleDetailsUri = '/api/v1/rental/vehicle/get-vehicle-details';
  static const String getVehicleCategoriesUri = '/api/v1/rental/vehicle/category-list';
  static const String getSelectVehiclesUri = '/api/v1/rental/vehicle/search/';
  static const String getSearchVehicleSuggestionUri = '/api/v1/rental/vehicle/search/suggestion';
  static const String addToCarCartUri = '/api/v1/rental/user/cart/add-to-cart';
  static const String updateCarCartUri = '/api/v1/rental/user/cart/update-cart';
  static const String removeCarCartUri = '/api/v1/rental/user/cart/remove-vehicle';
  static const String getCarCartListUri = '/api/v1/rental/user/cart/get-cart';
  static const String tripBookingUri = '/api/v1/rental/user/trip/trip-booking';
  static const String tripUpdateUserDataUri = '/api/v1/rental/user/cart/update-user-data';
  static const String removeAllCarCartUri = '/api/v1/rental/user/cart/remove-cart';
  static const String removeMultipleCarCartUri = '/api/v1/rental/user/cart/remove-multiple-cart';
  static const String tripListUri = '/api/v1/rental/user/trip/get-trip-list';
  static const String tripDetailsUri = '/api/v1/rental/user/trip/get-trip-details';
  static const String tripCancelUri = '/api/v1/rental/user/trip/cancel-trip';
  static const String tripDeleteUri = '/api/v1/rental/user/trip/delete-trip';
  static const String getProviderDetailsUri = '/api/v1/rental/provider/get-provider-details';
  static const String getProviderVehicleListUri = '/api/v1/rental/vehicle/get-provider-vehicles';
  static const String getProviderVehicleCategoryListUri = '/api/v1/rental/vehicle/category-list';
  static const String tripPaymentUri = '/api/v1/rental/user/trip/payment';
  static const String addTaxiWishListUri = '/api/v1/rental/user/wish-list/add';
  static const String removeTaxiWishListUri = '/api/v1/rental/user/wish-list/remove';
  static const String getTaxiWishListUri = '/api/v1/rental/user/wish-list';
  static const String getTaxiBrandListUri = '/api/v1/rental/vehicle/brand-list';
  static const String getTaxiProviderReviewUri = '/api/v1/rental/provider/get-provider-reviews';
  static const String addTaxiReviewUri = '/api/v1/rental/user/review/add';
  static const String getPopularTaxiSuggestionUri = '/api/v1/rental/vehicle/popular-suggestion/';
  static const String getProviderBannerUri = '/api/v1/rental/banners';
  static const String getTripTaxUri = '/api/v1/rental/user/trip/get-tax';
  static const String getVerifiedProvidersUri = '/api/v1/rental/provider/verified';
  static const String getParcelCancellationReasons = '/api/v1/get-parcel-cancellation-reasons';
  static const String rentalLastTrips = '/api/v1/rental/customer/trip/last';
  static const String rentalReOrder = '/api/v1/rental/user/trip/reorder';



  /// Ride Share
  static const String getRideShareBannerUri = '/api/v1/rideshare/customer/banner/list';
  static const String getRideShareCategoryUri = '/api/v1/rideshare/customer/vehicle/category';
  static const String getRideShareCouponUri = '/api/v1/rideshare/customer/coupon/list';
  static const String getRideShareCouponApplyUri = '/api/v1/rideshare/customer/coupon/apply';
  static const String estimatedFare = '/api/v1/rideshare/customer/ride/get-estimated-fare';
  static const String tripDetails = '/api/v1/rideshare/customer/ride/details/';
  static const String updateTripStatus = '/api/v1/rideshare/customer/ride/update-status/';
  static const String remainDistance = '/api/v1/rideshare/customer/config/get-routes';
  static const String biddingList = '/api/v1/rideshare/customer/ride/bidding-list/';
  static const String nearestDriverList = '/api/v1/rideshare/customer/drivers-near-me';
  static const String ignoreBidding = '/api/v1/rideshare/customer/ride/ignore-bidding';
  static const String tripAcceptOrReject = '/api/v1/rideshare/customer/ride/trip-action';
  static const String currentRideStatus = '/api/v1/rideshare/customer/ride/ride-resume-status';
  static const String finalFare = '/api/v1/rideshare/customer/ride/final-fare';
  static const String arrivalPickupPoint = '/api/v1/rideshare/customer/ride/arrival-time';
  static const String getRunningRideList = '/api/v1/rideshare/customer/ride/pending-ride-list';
  static const String parcelReceived = '/api/v1/rideshare/customer/ride/received-returning-parcel/';
  static const String rideRequest = '/api/v1/rideshare/customer/ride/create';
  static const String bestOfferList = '/api/v1/rideshare/customer/discount/list?limit=10&offset=';
  static const String tripList = '/api/v1/rideshare/customer/ride/list';
  static const String rideCancellationReasonList = '/api/v1/rideshare/customer/config/cancellation-reason-list';
  static const String getOtherEmergencyNumberList = '/api/v1/rideshare/customer/config/other-emergency-contact-list';
  static const String getSafetyAlertReasonList = '/api/v1/rideshare/customer/config/safety-alert-reason-list';
  static const String getPrecautionList = '/api/v1/rideshare/customer/config/safety-precaution-list';
  static const String storeSafetyAlert = '/api/v1/rideshare/customer/safety-alert/store';
  static const String markAsSolvedSafetyAlert = '/api/v1/rideshare/customer/safety-alert/mark-as-solved/';
  static const String resendSafetyAlert = '/api/v1/rideshare/customer/safety-alert/resend/';
  static const String undoSafetyAlert = '/api/v1/rideshare/customer/safety-alert/undo/';
  static const String customerAlertDetails = '/api/v1/rideshare/customer/safety-alert/show/';
  static const String submitReview = '/api/v1/rideshare/customer/review/store';
  static const String paymentUri = '/api/v1/rideshare/customer/ride/payment';
  static const String getPaymentMethods = '/api/v1/rideshare/customer/config/get-payment-methods';
  static const String getZoneIdUri = '/api/v1/rideshare/customer/config/get-zone-id';
  static const String getRunningRideListUri = '/api/v1/rideshare/customer/ride/list-running';
  static const String getHistoryRideListUri = '/api/v1/rideshare/customer/ride/list-history';
  static const String rideDeleteUri = '/api/v1/rideshare/customer/ride/delete';
  static const String digitalPayment = '/api/v1/rideshare/customer/ride/digital-payment';
  static const String bannerCountUpdate = '/api/v1/rideshare/customer/banner/update-redirection-count';
  static const String updateLiveLocation = '/api/v1/rideshare/user/store-live-location';

  /// service module — categories & sub-categories
  static const String serviceCategoriesUri = '/api/v1/categories';
  static const String serviceCategoryChildesUri = '/api/v1/categories/childes'; // /{category_id}
  static const String serviceCategoryServicesUri = '/api/v1/categories/services'; // /{category_id}  (+ /all)
  static const String serviceCategoryProvidersUri = '/api/v1/service/categories/providers'; // /{category_id}


  /// service module — banners
  static const String serviceBannersUri = '/api/v1/banners'; // /{provider_id} for provider banners

  /// service module — services
  static const String serviceLatestUri = '/api/v1/service/latest';
  static const String servicePopularUri = '/api/v1/service/popular';
  static const String serviceTopRatedUri = '/api/v1/service/top-rated';
  static const String serviceRecommendedUri = '/api/v1/service/recommended';
  static const String serviceSearchUri = '/api/v1/service/search';
  static const String serviceSearchSuggestionUri = '/api/v1/service/search-suggestion';
  static const String serviceDetailsUri = '/api/v1/service/details'; // /{id}  (numeric id or slug)
  static const String serviceRelatedUri = '/api/v1/service/related'; // /{service_id}
  static const String serviceRelatedProviderServicesUri = '/api/v1/service/related-provider-services'; // /{service_id}
  static const String serviceExploreUri = '/api/v1/service/explore'; // category tabs + paginated service grid
  static const String serviceQuickEmergencyExpertsUri = '/api/v1/service/quick-emergency-experts'; // providers + preview services
  static const String serviceModuleStatusUri = '/api/v1/service/service-module/status'; // health check (unused by app)

  /// service module — providers
  static const String serviceProvidersUri = '/api/v1/service/providers/get-providers'; // /{filter_data}
  static const String serviceProvidersLatestUri = '/api/v1/service/providers/latest';
  static const String serviceProvidersPopularUri = '/api/v1/service/providers/popular';
  static const String serviceProvidersTopRatedUri = '/api/v1/service/providers/top-rated';
  static const String serviceProvidersRecommendedUri = '/api/v1/service/providers/recommended';
  static const String serviceVerifiedProvidersUri = '/api/v1/stores/verified'; // verified providers (paginated)
  static const String serviceProvidersSearchUri = '/api/v1/service/providers/search';
  static const String serviceProviderPopularServicesUri = '/api/v1/service/providers/popular-services'; // /{id}
  static const String serviceProviderDetailsUri = '/api/v1/service/providers/details'; // /{id}

  static const String getServiceZoneId = '/api/v1/service/customer/get-zone-id';
  static const String dashboardOrderUri = '/api/v1/customer/order/all-running-orders';
  static const String savedFilesUri = '/api/v1/customer/saved-files';
  static const String deleteSavedFilesUri = '/api/v1/customer/saved-files/delete-all';
  static const String storeSavedFilesUri = '/api/v1/customer/saved-files/store';

  /// orders
  static const String reorderUri = '/api/v1/customer/order-again/reorder';
  static const String lastOrdersUri = '/api/v1/customer/order/last';
  static const String monthlyOrderListUri = '/api/v1/customer/monthly-order/list';
  static const String monthlyOrderRemoveUri = '/api/v1/customer/monthly-order/remove';

  ///Reels
  static const String reelListUri = '/api/v1/customer/reels/list';
  static const String reelDetailsUri = '/api/v1/customer/reels/details';
  static const String reelStatsUri = '/api/v1/customer/reels/stats';
  static const String reelLikeUri = '/api/v1/customer/reels/like';
  static const String reelVisitUri = '/api/v1/customer/reels/visit';

  // pro
  static const String proPlansUri = '/api/v1/pro-customer/plans';
  static const String proFaqsUri = '/api/v1/pro-customer/faqs';
  static const String proCustomerSubscribeUri = '/api/v1/customer/pro-customer/subscribe';
  static const String proCancelSubscriptionsUri = '/api/v1/customer/pro-customer/cancel';
  static const String proActiveOfferUri = '/api/v1/customer/pro-customer/active-offer';
  static const String proTermsAndConditionUri = '/api/v1/pro-customer/terms-and-conditions';

  /// Shared Key
  static const String savedRoute = 'savedRoute';
  static const String renewBottomSheetShown = 'sixam_mart_renew_bottomsheet_shown';
  static const String theme = '6ammart_theme';
  static const String token = '6ammart_token';
  static const String countryCode = '6ammart_country_code';
  static const String languageCode = '6ammart_language_code';
  static const String cacheCountryCode = 'cache_country_code';
  static const String cacheLanguageCode = 'cache_language_code';
  static const String cartList = '6ammart_cart_list';
  static const String userPassword = '6ammart_user_password';
  static const String userAddress = '6ammart_user_address';
  static const String userNumber = '6ammart_user_number';
  static const String userCountryCode = '6ammart_user_country_code';
  static const String otpUserNumber = '6ammart_otp_user_number';
  static const String otpUserCountryCode = '6ammart_otp_user_country_code';
  static const String notification = '6ammart_notification';
  static const String notificationIdList = 'notification_id_list';
  static const String searchHistory = '6ammart_search_history';
  static const String intro = '6ammart_intro';
  static const String notificationCount = '6ammart_notification_count';
  static const String dmTipIndex = '6ammart_dm_tip_index';
  static const String earnPoint = '6ammart_earn_point';
  static const String acceptCookies = '6ammart_accept_cookies';
  static const String suggestedLocation = '6ammart_suggested_location';
  static const String walletAccessToken = '6ammart_wallet_access_token';
  static const String guestId = '6ammart_guest_id';
  static const String guestNumber = '6ammart_guest_number';
  static const String referBottomSheet = '6ammart_reffer_bottomsheet_show';
  static const String paymentIncompleteBottomSheet = '6ammart_payment_incomplete_bottomsheet';
  static const String dmRegisterSuccess = '6ammart_dm_registration_success';
  static const String isRestaurantRegister = '6ammart_store_registration';
  static const String suggestLogin = '6ammart_login_suggestion';

  ///taxi
  static const String taxiSearchHistory = '6ammart_taxi_search_history';
  static const String taxiSearchAddressHistory = '6ammart_taxi_search_address_history';

  ///parcel
  static const String parcelRecentAddresses = '6ammart_parcel_recent_addresses';
  static const int parcelRecentAddressesMax = 10;

  ///recent delivery addresses (saved on successful checkout order)
  static const String recentDeliveryAddresses = '6ammart_recent_delivery_addresses';
  static const int recentDeliveryAddressesMax = 10;

  static const String prescriptionMediaLibrary = 'prescription_media_library';

  static const String topic = 'all_zone_customer';
  static const String zoneId = 'zoneId';
  static const String operationAreaId = 'operationAreaId';
  static const String moduleId = 'moduleId';
  static const String cacheModuleId = 'cacheModuleId';
  static const String localizationKey = 'X-localization';
  static const String latitude = 'latitude';
  static const String longitude = 'longitude';
  static const String cookiesManagement = 'cookies_management';
  static const String maintenanceModeTopic = 'maintenance_mode_user_app';

  ///Ride Share
  static const String rideSearchAddressHistory = '6ammart_ride_search_address_history';
  static const String paymentType = 'paymentType';
  static const String paymentMethod = 'payment_method';

  ///service
  static const String lastIncompleteOfflineBookingId = 'last_incomplete_offline_booking_id';


  ///Refer & Earn work flow list..
  static final dataList = [
    'invite_your_friends_and_business'.tr,
    '${'they_register'.tr} ${AppConstants.appName} ${'with_special_offer'.tr}',
    'you_made_your_earning'.tr,
  ];

  /// Delivery Tips
  static List<String> tips = ['custom', '15', '10', '20', '40', '0'];
  static List<String> deliveryInstructionList = [
    'deliver_to_front_door',
    'deliver_the_reception_desk',
    'avoid_calling_phone',
    'come_with_no_sound',
  ];

  static List<ChooseUsModel> whyChooseUsList = [
    ChooseUsModel(icon: Images.landingTrusted, title: 'trusted_by_customers_and_store_owners'),
    ChooseUsModel(icon: Images.landingStores, title: 'thousands_of_stores'),
    ChooseUsModel(icon: Images.landingExcellent, title: 'excellent_shopping_experience'),
    ChooseUsModel(icon: Images.landingCheckout, title: 'easy_checkout_and_payment_system'),
  ];

  /// order status..
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String processing = 'processing';
  static const String confirmed = 'confirmed';
  static const String handover = 'handover';
  static const String pickedUp = 'picked_up';
  static const String delivered = 'delivered';
  static const String canceled = 'canceled';
  static const String failed = 'failed';
  static const String refunded = 'refunded';
  static const String returned = 'returned';

  /// Rider_module.
  static const String ongoing = 'ongoing';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';

  ///modules..
  static const String pharmacy = 'pharmacy';
  static const String food = 'food';
  static const String parcel = 'parcel';
  static const String ecommerce = 'ecommerce';
  static const String grocery = 'grocery';
  static const String taxi = 'rental';
  static const String ride = 'ride-share';
  static const String service = 'service';

  ///ride share map zoom
  static const double mapZoom = 20;

  ///
  static const int idleDebounceDuration = 800;

  static List<LanguageModel> languages = [
    LanguageModel(imageUrl: Images.english, languageName: 'English', countryCode: 'US', languageCode: 'en'),
    LanguageModel(imageUrl: Images.arabic, languageName: 'عربى', countryCode: 'SA', languageCode: 'ar'),
    LanguageModel(imageUrl: Images.spanish, languageName: 'Spanish', countryCode: 'ES', languageCode: 'es'),
    LanguageModel(imageUrl: Images.bengali, languageName: 'Bengali', countryCode: 'BN', languageCode: 'bn'),
  ];

  static List<String> joinDropdown = [
    'join_us',
    'become_a_seller',
    'become_a_delivery_man',
    'join_as_a_rider',
  ];

  static final List<Map<String, String>> walletTransactionSortingList = [
    {
      'title' : 'all_transactions',
      'value' : 'all'
    },
    {
      'title' : 'order_transactions',
      'value' : 'order'
    },
    {
      'title' : 'converted_from_loyalty_point',
      'value' : 'loyalty_point'
    },
    {
      'title' : 'added_via_payment_method',
      'value' : 'add_fund'
    },
    {
      'title' : 'earned_by_referral',
      'value' : 'referrer'
    },
    {
      'title' : 'cash_back_transactions',
      'value' : 'CashBack'
    },
  ];

  //taxi seats..
  static List<String> seats = ['1-4', '5-8', '9-13', '14+'];

  ///Rental Type
  static const String hourly = 'hourly';
  static const String distanceWise = 'distance_wise';
  static const String dayWise = 'day_wise';

}

