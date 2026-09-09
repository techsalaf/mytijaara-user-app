import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/pro/domain/models/pro_active_offer_model.dart';
import 'package:sixam_mart/features/pro/domain/models/pro_faq_model.dart';
import 'package:sixam_mart/features/pro/domain/models/pro_plan_model.dart';
import 'package:sixam_mart/features/pro/domain/services/pro_service_interface.dart';
import 'package:sixam_mart/features/pro/widgets/pro_failed_bottom_sheet_widget.dart';
import 'package:sixam_mart/features/pro/widgets/pro_renew_bottom_sheet_widget.dart';
import 'package:sixam_mart/features/pro/widgets/pro_success_bottom_sheet_widget.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/module_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:universal_html/html.dart' as html;

class ProController extends GetxController implements GetxService {
  final ProServiceInterface proServiceInterface;
  ProController({required this.proServiceInterface});

  ProPlanModel? _planModel;
  ProPlanModel? get planModel => _planModel;

  List<ProFaqModel>? _faqList;
  List<ProFaqModel>? get faqList => _faqList;

  ProActiveOfferModel? _activeOfferModel;
  ProActiveOfferModel? get activeOfferModel => _activeOfferModel;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSubscribeLoading = false;
  bool get isSubscribeLoading => _isSubscribeLoading;

  bool _isCancelLoading = false;
  bool get isCancelLoading => _isCancelLoading;

  String? get _moduleType => Get.find<SplashController>().module?.moduleType;

  // Per-module allow-list for pro benefit types. The active-offer API is module-scoped,
  // but a benefit type must also be applicable to the current module before it is shown:
  //   parcel        -> delivery fee only (no item subtotal, so no discount/coupon)
  //   rental / ride -> discount & coupon (trip-based, no delivery fee)
  //   stores        -> all benefit types
  bool isBenefitAllowedForCurrentModule(ProBenefitType? type) {
    if (type == null) return false;
    final String? moduleType = _moduleType ?? ModuleHelper.getCacheModule()?.moduleType;
    switch (moduleType) {
      case AppConstants.parcel:
        return type == ProBenefitType.deliveryFee;
      case AppConstants.taxi:
      case AppConstants.ride:
        return type == ProBenefitType.discount || type == ProBenefitType.coupon;
      default:
        return true;
    }
  }

  Future<void> getProPlans() async {
    _planModel = await proServiceInterface.getProPlans();
    update();
  }

  Future<void> getProFaqs() async {
    _faqList = await proServiceInterface.getProFaqs();
    update();
  }

  Future<void> getProActiveOffer({required String? moduleType}) async {
    if(!AuthHelper.isLoggedIn()) return;
    _activeOfferModel = await proServiceInterface.getProActiveOffer(moduleType: moduleType);
    update();
  }

  Future<void> loadInitialData() async {
    _isLoading = true;
    update();
    await Future.wait([
      getProActiveOffer(moduleType: _moduleType),
      getProFaqs(),
      getProPlans(),
    ]);
    _isLoading = false;
    update();
  }

  Future<void> subscribePlan(PlanItem plan, String paymentType, String paymentMethod, bool isRenew) async {
    if(plan.id == null) {
      showCustomSnackBar('no_data_found'.tr);
      return;
    }

    _isSubscribeLoading = true;
    update();
    String? hostname = html.window.location.hostname;
    String protocol = html.window.location.protocol;
    String paymentPlatform = GetPlatform.isWeb ? 'web' : 'app';
    String? callback = kIsWeb ? '$protocol//$hostname${RouteHelper.subscriptionPlan}${isRenew ? '/renew' : ''}' : null;
    Response response = await proServiceInterface.subscribePlan(planId: plan.id!, paymentType: paymentType, paymentMethod: paymentMethod, callback: callback, paymentPlatform: paymentPlatform);
    _isSubscribeLoading = false;
    update();

    if(response.statusCode == 200) {
      if(response.body['redirect_link'] != null) {
        _proSubscriptionPayment(response.body['redirect_link'], paymentMethod, isRenew);
      } else {
        showPlanSubscribeState(isRenew);
        await Get.find<ProfileController>().getUserInfo();
        await getProPlans();
        await getProActiveOffer(moduleType: _moduleType);
      }
    } else {
      showCustomSnackBar(response.statusText);
    }
  }

  void saveCurrentPath({String? route}) {
    final String currentRoute = route ?? (kIsWeb ? (Uri.base.hasQuery ? '${Uri.base.path}?${Uri.base.query}' : Uri.base.path) : Get.currentRoute);
    proServiceInterface.saveCurrentPath(currentRoute);
  }

  String? getSavedRoute() {
    return proServiceInterface.getSavedRoute();
  }

  void removeSavedRoute() {
    proServiceInterface.removeSavedRoute();
  }

  bool getRenewBottomSheetStatus() {
    return proServiceInterface.getRenewBottomSheetShown();
  }

  bool get shouldShowRenewBottomSheet {
    final sub = Get.find<ProfileController>().userInfoModel?.proSubscription;
    return sub?.isExpired == true && Get.find<AuthController>().isLoggedIn() && !getRenewBottomSheetStatus();
  }

  void saveRenewBottomSheetStatus(bool shown) {
    proServiceInterface.saveRenewBottomSheetShown(shown);
  }

  // Routes that are part of the login/onboarding flow itself. While the user is on any of
  // these, login is not "complete", so the renew sheet must not appear yet.
  static const List<String> _renewSkipRoutes = [
    RouteHelper.splash, RouteHelper.language, RouteHelper.onBoarding,
    RouteHelper.signIn, RouteHelper.signUp, RouteHelper.verification,
    RouteHelper.accessLocation, RouteHelper.pickMap, RouteHelper.newUserSetupScreen,
    RouteHelper.interest,
  ];

  // Called from the global routingCallback on every settled route (Android, iOS, web alike).
  // Shows the expired-pro renew sheet on whatever page the user lands on once login is fully
  // complete, instead of relying on a specific screen. Self-guarding + once-per-session, so it
  // is safe to call on every navigation.
  Future<void> maybeShowRenewOnRoute(String? route) async {
    if(!AuthHelper.isLoggedIn() || getRenewBottomSheetStatus()) return;

    final String current = (route ?? '').split('?').first;
    if(current.isEmpty) return;
    final bool isFlowRoute = _renewSkipRoutes.any((r) => current == r || current.startsWith('$r/'));
    if(isFlowRoute) return;

    await Get.find<ProfileController>().getUserInfo();
    Future.delayed(const Duration(milliseconds: 600), () => showRenewProBottomSheet());
  }

  Future<void> showRenewProBottomSheet() async {
    final bool showRenew = shouldShowRenewBottomSheet;
    if(!showRenew) return;
    saveRenewBottomSheetStatus(true);
    ResponsiveHelper.isDesktop(Get.context) ? Get.dialog(Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge)),
      insetPadding: const EdgeInsets.all(22),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: const ProRenewBottomSheetWidget(),
    ), useSafeArea: false) : showModalBottomSheet(
      isScrollControlled: true, useRootNavigator: true, context: Get.context!,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(Dimensions.radiusExtraLarge), topRight: Radius.circular(Dimensions.radiusExtraLarge)),),
      builder: (context) => const ProRenewBottomSheetWidget(),
    );
  }

  void showPlanSubscribeState(bool isRenew, {bool redirect = false, bool paymentStatus = true, bool isOffAll = false}) async {
    if(Get.isOverlaysOpen) {
      Get.back();
    }
    if(redirect) {
      if(isOffAll) {
        Get.offAllNamed(RouteHelper.getSubscriptionPlanRoute(flag: paymentStatus, isRenew: isRenew));
      } else {
        Get.offNamed(RouteHelper.getSubscriptionPlanRoute(flag: paymentStatus, isRenew: isRenew), preventDuplicates: false);
      }
    } else {
      String? route = getSavedRoute();
      if(route != null && route.isNotEmpty) {
        removeSavedRoute();
        Get.offNamed(route);
      }
      if(paymentStatus) {
        saveRenewBottomSheetStatus(false);
        ResponsiveHelper.isDesktop(Get.context) ? Get.dialog(
          Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge)),
            insetPadding: const EdgeInsets.all(22),
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: ProSuccessBottomSheetWidget(isRenewalMode: isRenew),
          ),
          useSafeArea: false,
        ) : Get.bottomSheet(
          ProSuccessBottomSheetWidget(isRenewalMode: isRenew),
          isScrollControlled: true,
          backgroundColor: Get.theme.cardColor,
        );
      } else {
        Get.dialog(
          Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge)),
            insetPadding: const EdgeInsets.all(22),
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: const ProFailedBottomSheetWidget(),
          ),
          useSafeArea: false,
        );
      }
    }
  }

  Future<void> cancelSubscription() async {
    _isCancelLoading = true;
    update();
    Response response = await proServiceInterface.cancelSubscription();
    _isCancelLoading = false;
    update();

    if(response.statusCode == 200) {
      showCustomSnackBar(response.body['message'] ?? 'subscription_cancelled_successfully'.tr, isError: true);
      await Get.find<ProfileController>().getUserInfo();
      await getProPlans();
      await getProActiveOffer(moduleType: _moduleType);
    } else {
      showCustomSnackBar(response.statusText);
    }
  }

  Future<void> _proSubscriptionPayment(String redirectUrl, String paymentMethod, bool isRenew) async {
    if(GetPlatform.isWeb) {
      html.window.open(redirectUrl, '_self');
    } else {
      Get.toNamed(RouteHelper.getPaymentRoute(
        '0', 0, '', 0, false, paymentMethod,
        subscriptionUrl: redirectUrl,
        guestId: Get.find<AuthController>().getGuestId(),
        isProSubscription: true,
        isRenew: isRenew,
      ));
    }
  }
}
