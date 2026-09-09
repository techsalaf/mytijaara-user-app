import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/order/screens/my_items_screen.dart';
import 'package:sixam_mart/features/profile/domain/constant.dart';
import 'package:sixam_mart/features/profile/widgets/profile_header_card_widget.dart';
import 'package:sixam_mart/features/profile/widgets/profile_logout_button_widget.dart';
import 'package:sixam_mart/features/profile/widgets/profile_menu_section_widget.dart';
import 'package:sixam_mart/features/profile/widgets/profile_stat_cards_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';

class ProfileScreen extends StatefulWidget {
  final Function()? onBackPressed;
  const ProfileScreen({super.key, this.onBackPressed});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    if (AuthHelper.isLoggedIn() && Get.find<ProfileController>().userInfoModel == null) {
      Get.find<ProfileController>().getUserInfo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).disabledColor.withAlpha(20),
      appBar: CustomAppBar(title: 'my_profile'.tr, backButton: widget.onBackPressed != null, onBackPressed: widget.onBackPressed),
      body: SafeArea(
        child: Column(
          children: [
            const Divider(height: 0.2),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
                child: Column(
                  children: [
                    const ProfileHeaderCardWidget(),
                    const SizedBox(height: Dimensions.paddingSizeDefault),
                    const ProfileStatCardsWidget(),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                    ProfileMenuSectionWidget(
                      titleKey: 'general',
                      items: _buildGeneralItems(),
                    ),
                    ProfileMenuSectionWidget(
                      titleKey: 'promotional_activity',
                      items: _buildPromotionalItems(),
                    ),
                    ProfileMenuSectionWidget(
                      titleKey: 'earnings',
                      items: _buildEarningsItems(context),
                    ),
                    ProfileMenuSectionWidget(
                      titleKey: 'help_and_support',
                      items: _buildHelpAndSupportItems(),
                    ),

                    const ProfileLogoutButtonWidget(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<ProfileMenuItem> _buildGeneralItems() {
    return [
      ProfileMenuItem(
        titleKey: 'edit_profile',
        iconAsset: Images.user,
        route: RouteHelper.getUpdateProfileRoute(),
      ),
      ProfileMenuItem(
        titleKey: 'my_address',
        iconAsset: Images.mapIcon,
        route: RouteHelper.getAddressRoute(),
      ),
      if(Get.find<SplashController>().proStaus)
        ProfileMenuItem(
          titleKey: 'my_subscription',
          iconAsset: Images.proPlanCrown,
          route: RouteHelper.getSubscriptionPlanRoute(),
        ),
      if(AuthHelper.isLoggedIn() && Get.find<SplashController>().configModel?.monthlyOrderRemainder == 1)
        ProfileMenuItem(
          titleKey: 'monthly_cart_list',
          iconAsset: Images.monthlyCart,
          onTap: () => Get.to(() => const MyItemsScreen()),
        ),
      ProfileMenuItem(
        titleKey: 'settings',
        iconAsset: Images.settings,
        route: RouteHelper.getSettingScreen(),
      ),
    ];
  }

  List<ProfileMenuItem> _buildPromotionalItems() {
    final config = Get.find<SplashController>().configModel!;
    final List<ProfileMenuItem> items = [
      ProfileMenuItem(
        titleKey: 'coupon',
        iconAsset: Images.couponIcon,
        route: RouteHelper.getCouponRoute(),
      ),
    ];

    if (config.loyaltyPointStatus == 1) {
      items.add(ProfileMenuItem(
        titleKey: 'loyalty_points',
        iconAsset: Images.taxiStarIcon,
        route: RouteHelper.getLoyaltyRoute(),
      ));
    }

    if (config.customerWalletStatus == 1) {
      items.add(ProfileMenuItem(
        titleKey: 'my_wallet',
        iconAsset: Images.walletIcon,
        route: RouteHelper.getWalletRoute(),
      ));
    }

    return items;
  }

  List<ProfileMenuItem> _buildEarningsItems(BuildContext context) {
    final config = Get.find<SplashController>().configModel!;
    final bool isDesktop = ResponsiveHelper.isDesktop(context);
    final List<ProfileMenuItem> items = [];

    if (config.refEarningStatus == 1) {
      items.add(ProfileMenuItem(
        titleKey: 'refer_and_earn',
        iconAsset: Images.referIcon,
        route: RouteHelper.getReferAndEarnRoute(),
      ));
    }

    if ((config.toggleDmRegistration ?? false) && !isDesktop) {
      items.add(ProfileMenuItem(
        titleKey: 'join_as_a_delivery_man',
        iconAsset: Images.deliveryManIcon,
        route: RouteHelper.getDeliverymanRegistrationRoute(),
      ));
    }

    if ((config.toggleRiderRegistration ?? false) && !isDesktop) {
      items.add(ProfileMenuItem(
        titleKey: 'join_as_a_rider',
        iconAsset: Images.deliveryManIcon,
        route: RouteHelper.getRiderRegistrationRoute(),
      ));
    }

    if ((config.toggleStoreRegistration ?? false) && !isDesktop) {
      items.add(ProfileMenuItem(
        titleKey: 'open_vendor',
        iconAsset: Images.storeIcon,
        route: RouteHelper.getRestaurantRegistrationRoute(),
      ));
    }

    return items;
  }

  List<ProfileMenuItem> _buildHelpAndSupportItems() {
    final config = Get.find<SplashController>().configModel!;
    final bool isRideShare = Get.find<SplashController>().module?.moduleType == 'ride-share';
    final List<ProfileMenuItem> items = [
      ProfileMenuItem(
        titleKey: 'live_chat',
        iconAsset: Images.message,
        route: RouteHelper.getConversationRoute(),
      ),
      ProfileMenuItem(
        titleKey: 'help_and_support',
        iconAsset: Images.helpAndSupportIcon,
        route: RouteHelper.getSupportRoute(),
      ),
      const ProfileMenuItem(
        titleKey: 'terms_conditions',
        iconAsset: Images.termsIcon,
        route: RouteHelper.termsAndCondition,
      ),
      ProfileMenuItem(
        titleKey: 'privacy_policy',
        iconAsset: Images.termsIcon,
        route: RouteHelper.privacyPolicy,
      ),
    ];

    if (isRideShare) {
      items.add(ProfileMenuItem(
        titleKey: 'safety_policy',
        iconAsset: Images.termsIcon,
        route: RouteHelper.safety,
      ));
    }

    if (config.refundPolicyStatus == 1) {
      items.add(ProfileMenuItem(
        titleKey: 'refund_policy',
        iconAsset: Images.termsIcon,
        route: RouteHelper.refundPolicy,
      ));
    }

    if (config.cancellationPolicyStatus == 1) {
      items.add(ProfileMenuItem(
        titleKey: 'cancellation_policy',
        iconAsset: Images.termsIcon,
        route: RouteHelper.cancellationPolicy,
      ));
    }

    if (config.shippingPolicyStatus == 1) {
      items.add(ProfileMenuItem(
        titleKey: 'shipping_policy',
        iconAsset: Images.termsIcon,
        route: RouteHelper.shippingPolicy,
      ));
    }

    return items;
  }
}
