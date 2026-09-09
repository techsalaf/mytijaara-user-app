import 'dart:async';
import 'dart:io';

import 'package:expandable_bottom_sheet/expandable_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/models/ongoing_order_model.dart';
import 'package:sixam_mart/common/widgets/custom_dialog.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/login_suggestion_bottomsheet.dart';
import 'package:sixam_mart/features/ai_chat_bot/widgets/ai_chat_bot_floating_button_widget.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/checkout/widgets/congratulation_dialogue.dart';
import 'package:sixam_mart/features/dashboard/widgets/address_bottom_sheet_widget.dart';
import 'package:sixam_mart/features/dashboard/widgets/payment_incomplete_bottomsheet.dart';
import 'package:sixam_mart/features/dashboard/widgets/store_registration_success_bottom_sheet.dart';
import 'package:sixam_mart/features/favourite/screens/favourite_screen.dart';
import 'package:sixam_mart/features/flash_sale/controllers/flash_sale_controller.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/home/widgets/cashback_dialog_widget.dart';
import 'package:sixam_mart/features/home/widgets/cashback_logo_widget.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/screens/main_screen.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/home_status_bar_tint.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/navbar_promo_banner.dart';
import 'package:sixam_mart/features/offer/offer_screen.dart';
import 'package:sixam_mart/features/order/screens/my_order_screen.dart';
import 'package:sixam_mart/features/profile/screens/profile_screen.dart';
import 'package:sixam_mart/features/ride_share_module/ride_home/screens/biding_list_screen.dart';
import 'package:sixam_mart/features/ride_share_module/ride_order/controllers/ride_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

import '../widgets/running_order_view_widget.dart';

class DashboardScreen extends StatefulWidget {
  final int pageIndex;
  final int? rideOfferIndex;
  final bool fromSplash;
  const DashboardScreen({super.key, required this.pageIndex, this.fromSplash = false, this.rideOfferIndex = 0});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  PageController? _pageController;
  int _pageIndex = 0;
  late List<Widget> _screens;
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey();
  bool _canExit = GetPlatform.isWeb ? true : false;

  GlobalKey<ExpandableBottomSheetState> key = GlobalKey();

  late bool _isLogin;
  bool active = false;
  bool _navBarVisible = true;

  // Tracks whether an opaque page has been pushed over the dashboard, so the
  // home status-bar tint overlay only shows while the home tab is actually the
  // visible top page (and not behind another full screen).
  Animation<double>? _secondaryAnimation;
  bool _coveredByOpaque = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Animation<double>? secondary = ModalRoute.of(context)?.secondaryAnimation;
    if (secondary != _secondaryAnimation) {
      _secondaryAnimation?.removeListener(_onCoverChanged);
      _secondaryAnimation = secondary;
      _secondaryAnimation?.addListener(_onCoverChanged);
      _onCoverChanged();
    }
  }

  void _onCoverChanged() {
    final bool covered = (_secondaryAnimation?.value ?? 0) > 0.001;
    if (covered != _coveredByOpaque) {
      _coveredByOpaque = covered;
      _updateHomeStatusBarTint();
    }
  }

  // Home tab (index 0) is MainScreen, the only screen that paints a dynamic
  // status-bar tint. Keep the overlay active only then.
  void _updateHomeStatusBarTint() {
    HomeStatusBarTint.active.value = mounted && !ResponsiveHelper.isWeb() && _pageIndex == 0 && !_coveredByOpaque;
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    // Only react to vertical scrolls — horizontal carousels (e.g. banner/store
    // sliders) also bubble UserScrollNotifications, and should not hide the navbar.
    if (notification is UserScrollNotification && notification.metrics.axis == Axis.vertical) {
      if (notification.direction == ScrollDirection.reverse && _navBarVisible) {
        setState(() => _navBarVisible = false);
      } else if (notification.direction == ScrollDirection.forward && !_navBarVisible) {
        setState(() => _navBarVisible = true);
      }
    }
    // Programmatic scrolls (e.g. back-to-top button) don't emit UserScrollNotification.
    // Show the navbar whenever any scroll settles at the very top of the list.
    if (notification is ScrollEndNotification &&
        notification.metrics.axis == Axis.vertical &&
        notification.metrics.pixels <= 0 &&
        !_navBarVisible) {
      setState(() => _navBarVisible = true);
    }
    return false;
  }

  @override
  void initState() {
    super.initState();

    _isLogin = AuthHelper.isLoggedIn();

    _showRegistrationSuccessBottomSheet();
    if(!_isLogin && Get.find<SplashController>().showLoginSuggestion() && (GetPlatform.isAndroid || GetPlatform.isIOS)) {
      Future.delayed(const Duration(milliseconds: 3000), () {
        _showLoginSuggestionBottomSheet();
      });
    }

    if(_isLogin){
      if(Get.find<SplashController>().configModel!.loyaltyPointStatus == 1 && Get.find<AuthController>().getEarningPint().isNotEmpty
          && !ResponsiveHelper.isDesktop(Get.context)){
        Future.delayed(const Duration(seconds: 1), () => showAnimatedDialog(Get.context!, const CongratulationDialogue()));
      }
      suggestAddressBottomSheet();
      // Get.find<OrderController>().getRunningOrders(1, fromDashboard: true);
      Get.find<OrderController>().getDashboardOrders();

      Get.find<SplashController>().getPaymentIncompleteSheetStatus();
      if((Get.find<SplashController>().showPaymentIncompleteBottomSheet && !GetPlatform.isWeb) || (GetPlatform.isWeb && !Get.find<SplashController>().getPaymentIncompleteSheetStatus())) {
        Get.find<OrderController>().getPaymentFailedDetails(null).then((paymentModel) {
          if (paymentModel != null) {
            if(ResponsiveHelper.isDesktop(Get.context)) {
              Get.dialog(Center(child: PaymentIncompleteBottomSheet(paymentModel: paymentModel, fromHome: true)));
            } else {
              Get.bottomSheet(PaymentIncompleteBottomSheet(paymentModel: paymentModel, fromHome: true), isScrollControlled: true);
            }
          }
        });
      }
    }

    _pageIndex = widget.pageIndex;

    _pageController = PageController(initialPage: widget.pageIndex);

    _screens = [
      const MainScreen(),
      OfferScreen(onBackPressed: () => _setPage(0)),
      MyOrderScreen(onBackPressed: () => _setPage(0)),
      FavouriteScreen(onBackPressed: () => _setPage(0)),
      ProfileScreen(onBackPressed: () => _setPage(0)),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateHomeStatusBarTint();
      }
    });
  }

  @override
  void dispose() {
    _secondaryAnimation?.removeListener(_onCoverChanged);
    HomeStatusBarTint.active.value = false;
    super.dispose();
  }

  void _showRegistrationSuccessBottomSheet() {
    bool canShowBottomSheet = Get.find<HomeController>().getRegistrationSuccessfulSharedPref();
    if(canShowBottomSheet) {
      Future.delayed(const Duration(seconds: 1), () {
        ResponsiveHelper.isDesktop(Get.context) ? Get.dialog(const Dialog(child: StoreRegistrationSuccessBottomSheet())).then((value) {
          Get.find<HomeController>().saveRegistrationSuccessfulSharedPref(false);
          Get.find<HomeController>().saveIsStoreRegistrationSharedPref(false);
          setState(() {});
        }) : showModalBottomSheet(
          context: Get.context!, isScrollControlled: true, backgroundColor: Colors.transparent,
          builder: (con) => const StoreRegistrationSuccessBottomSheet(),
        ).then((value) {
          Get.find<HomeController>().saveRegistrationSuccessfulSharedPref(false);
          Get.find<HomeController>().saveIsStoreRegistrationSharedPref(false);
          setState(() {});
        });
      });
    }
  }

  Future<void> suggestAddressBottomSheet() async {
    active = await Get.find<LocationController>().checkLocationActive();
    if(widget.fromSplash && Get.find<LocationController>().showLocationSuggestion && active) {
      Future.delayed(const Duration(seconds: 1), () {
        showModalBottomSheet(
          context: Get.context!, isScrollControlled: true, backgroundColor: Colors.transparent,
          builder: (con) => const AddressBottomSheetWidget(),
        ).then((value) {
          Get.find<LocationController>().showSuggestedLocation(false);
          setState(() {});
        });
      });
    }
  }

  void _showLoginSuggestionBottomSheet() {
    Get.bottomSheet(
      const LoginSuggestionBottomSheet(),
      isScrollControlled: true,
    ).then((v) {
      Get.find<SplashController>().disableLoginSuggestion();
    });
  }

  @override
  Widget build(BuildContext context) {
    bool keyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;
    return GetBuilder<SplashController>(
      builder: (splashController) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (_pageIndex != 0) {
              _setPage(0);
            } else if (splashController.selectedModuleIndex != 0) {
              splashController.selectHomeModule();
            } else {
              if(!ResponsiveHelper.isDesktop(context) && Get.find<SplashController>().module != null && Get.find<SplashController>().configModel!.module == null && splashController.moduleList != null && splashController.moduleList!.length != 1) {
                splashController.removeModule();
                Get.find<StoreController>().resetStoreData();
              }else {
                if(_canExit) {
                  if (GetPlatform.isAndroid) {
                    SystemNavigator.pop();
                  } else if (GetPlatform.isIOS) {
                    exit(0);
                  }
                }else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('back_press_again_to_exit'.tr, style: const TextStyle(color: Colors.white)),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                    margin: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  ));
                  _canExit = true;
                  Timer(const Duration(seconds: 2), () {
                    _canExit = false;
                  });
                }
              }
            }
          },
          child: GetBuilder<OrderController>(
            builder: (orderController) {
              List<OrderData> runningOrder = orderController.ongoingOrderModel != null ? orderController.ongoingOrderModel!.data! : [];

              return SafeArea(
                top: false, bottom: GetPlatform.isAndroid,
                child: Scaffold(
                  key: _scaffoldKey,
                  floatingActionButton: _pageIndex == 0 ? GetBuilder<FlashSaleController>(builder: (flashSaleController) {
                    // Lift the FAB by the banner's height while the promo is shown so
                    // they never overlap.
                    final double promoOffset = _shouldShowNavbarPromo(flashSaleController, splashController) ? _kPromoBannerReservedHeight : 0;
                    return IgnorePointer(
                      ignoring: !_navBarVisible,
                      child: AnimatedScale(
                        scale: _navBarVisible ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutBack,
                        child: AnimatedOpacity(
                          opacity: _navBarVisible ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          child: _HomeFloatingActionButton(splashController: splashController, extraBottomOffset: promoOffset),
                        ),
                      ),
                    );
                  }) : null,
                  body: ExpandableBottomSheet(
                    background: Stack(children: [
                      NotificationListener<ScrollNotification>(
                        onNotification: _handleScrollNotification,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _screens.length,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            return _screens[index];
                          },
                        ),
                      ),

                      // Card-color → transparent fade behind the floating navbar, so
                      // content scrolling underneath fades out at the bottom. Slides
                      // away together with the navbar when scrolling down.
                      ResponsiveHelper.isDesktop(context) || keyboardVisible ? const SizedBox() : Positioned(
                        bottom: 0, left: 0, right: 0,
                        child: IgnorePointer(
                          child: AnimatedSlide(
                            offset: _navBarVisible ? Offset.zero : const Offset(0, 1),
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Theme.of(context).cardColor,
                                    Theme.of(context).cardColor.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      ResponsiveHelper.isDesktop(context) || keyboardVisible ? const SizedBox() : Positioned(
                        bottom: Dimensions.paddingSizeDefault,
                        left: Dimensions.paddingSizeDefault,
                        right: Dimensions.paddingSizeDefault,
                        child: IgnorePointer(
                          ignoring: !_navBarVisible,
                          child: AnimatedSlide(
                            offset: _navBarVisible ? Offset.zero : const Offset(0, 2),
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            child: Stack(alignment: Alignment.bottomCenter, children: [
                              // Banner tucked behind the pill: a bottom padding equal to
                              // (pill height − overlap) sizes the Stack so the banner is
                              // fully laid out (and tappable), while its empty bottom slides
                              // under the navbar for a no-gap overlap.
                              Padding(
                                padding: const EdgeInsets.only(bottom: _kNavPillHeight - _kPromoOverlap),
                                child: _buildNavbarPromo(context, splashController),
                              ),
                              Container(
                              height: 62,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [BoxShadow(
                              color: Colors.black.withValues(alpha: .15),
                              blurRadius: 5, spreadRadius: 1, offset: const Offset(0,2),
                            )],
                          ),
                          clipBehavior: Clip.antiAlias,
                          // Transparent Material so the InkWell ripples paint ON the
                          // pill (above its opaque cardColor fill) instead of behind it,
                          // clipped to the pill shape by the Container's antiAlias clip.
                          child: Material(
                            type: MaterialType.transparency,
                            child: LayoutBuilder(
                            builder: (context, constraints) {
                              const indicatorWidth = 36.0;
                              const indicatorHeight = 4.0;
                              final itemWidth = constraints.maxWidth / 4;
                              final selectedSlot = _pageIndex >= 1 && _pageIndex <= 4 ? _pageIndex - 1 : -1;
                              final indicatorLeft = selectedSlot == -1
                                  ? -indicatorWidth
                                  : (itemWidth * selectedSlot) + (itemWidth - indicatorWidth) / 2;

                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  AnimatedPositioned(
                                    duration: const Duration(milliseconds: 280),
                                    curve: Curves.easeOutCubic,
                                    top: 0,
                                    left: indicatorLeft,
                                    width: indicatorWidth,
                                    height: indicatorHeight,
                                    child: AnimatedOpacity(
                                      duration: const Duration(milliseconds: 180),
                                      opacity: selectedSlot == -1 ? 0 : 1,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor,
                                          borderRadius: const BorderRadius.vertical(
                                            bottom: Radius.circular(8),
                                          ),
                                          // boxShadow: [BoxShadow(
                                          //   color: Colors.black.withValues(alpha: .15),
                                          //   blurRadius: 8, spreadRadius: 0, offset: const Offset(0, 2),
                                          // )],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        _FoodModuleBottomNavigationItem(
                                          label: 'offers'.tr,
                                          icon: Images.offersIcon,
                                          selectedIcon: Images.offersIconSolid,
                                          isSelected: _pageIndex == 1,
                                          onTap: ()=> _setPage(1),
                                        ),
                                        _FoodModuleBottomNavigationItem(
                                          label: 'orders'.tr,
                                          icon: Images.orderIcon,
                                          selectedIcon: Images.orderIconSolid,
                                          isSelected: _pageIndex == 2,
                                          onTap: () => _setPage(2),
                                        ),
                                        _FoodModuleBottomNavigationItem(
                                          label: 'favourite'.tr,
                                          icon: Images.heartIcon,
                                          selectedIcon: Images.heartIconSolid,
                                          isSelected: _pageIndex == 3,
                                          onTap: () => _setPage(3),
                                        ),
                                        _FoodModuleBottomNavigationItem(
                                          label: 'profile'.tr,
                                          icon: '',
                                          selectedIcon: '',
                                          isProfile: true,
                                          isSelected: _pageIndex == 4,
                                          onTap: () => _setPage(4),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          ),
                        ),
                            ]),
                          ),
                        ),
                      ),
                    ]),

                    persistentContentHeight: (widget.fromSplash && Get.find<LocationController>().showLocationSuggestion && active) ? 0 : GetPlatform.isIOS ? 110 : 100,

                    onIsContractedCallback: () {
                      if(!orderController.showOneOrder) {
                        orderController.showOrders();
                      }
                    },
                    onIsExtendedCallback: () {
                      if(orderController.showOneOrder) {
                        orderController.showOrders();
                      }
                    },

                    enableToggle: true,

                    expandableContent: (widget.fromSplash && Get.find<LocationController>().showLocationSuggestion && active && !ResponsiveHelper.isDesktop(context)) ?  const SizedBox()
                    : (ResponsiveHelper.isDesktop(context) || !_isLogin || orderController.ongoingOrderModel == null
                    || orderController.ongoingOrderModel!.data!.isEmpty || !orderController.showBottomSheet) ? const SizedBox()
                    : Dismissible(
                      key: UniqueKey(),
                      onDismissed: (direction) {
                        if(orderController.showBottomSheet){
                          orderController.showRunningOrders();
                        }
                      },
                      child: RunningOrderViewWidget(reversOrder: runningOrder, onOrderTap: () {
                        _setPage(2);
                        if(orderController.showBottomSheet){
                          orderController.showRunningOrders();
                        }
                      }),
                    ),
                  ),
                ),
              );
            }
          ),
        );
      }
    );
  }

  void _setPage(int pageIndex) {
    setState(() {
      _pageController!.jumpToPage(pageIndex);
      _pageIndex = pageIndex;
    });
    _updateHomeStatusBarTint();
  }

  /// Tab index of the [OfferScreen] within [_screens].
  static const int offersPageIndex = 1;

  /// Public entry point so descendants (e.g. the home quick-filters) can switch
  /// the dashboard tab in place instead of pushing a new route over the navbar.
  void setPage(int pageIndex) => _setPage(pageIndex);

  /// Switches the enclosing dashboard to [pageIndex] from any descendant context.
  /// Returns true when a [DashboardScreen] ancestor was found and switched.
  static bool switchToTab(BuildContext context, int pageIndex) {
    final DashboardScreenState? state = context.findAncestorStateOfType<DashboardScreenState>();
    if (state == null) {
      return false;
    }
    state.setPage(pageIndex);
    return true;
  }

  // Navbar pill height + how far the promo banner's (empty) bottom tucks behind it,
  // so they overlap with no gap (as in the design). The banner adds matching bottom
  // padding so its content stays above the pill. Reserved height lifts the FAB clear.
  static const double _kNavPillHeight = 62;
  static const double _kPromoOverlap = 25;
  static const double _kPromoBannerReservedHeight = 72;

  // True while the active module's flash sale is live (grocery/shop only).
  bool _isFlashOngoing(FlashSaleController flashSaleController) {
    final flashSaleModel = flashSaleController.flashSaleModel;
    return flashSaleModel != null
        && (flashSaleModel.activeProducts?.isNotEmpty ?? false)
        && flashSaleController.duration != null
        && flashSaleController.duration!.inSeconds > 1;
  }

  // Whether the promo banner should currently be visible: on the Home tab, not yet
  // dismissed for this module, and there's something to promote — an ongoing flash
  // sale OR free delivery (so food/pharmacy, which have no flash sale, still show it).
  bool _shouldShowNavbarPromo(FlashSaleController flashSaleController, SplashController splashController) {
    if (_pageIndex != 0 || !Get.find<HomeController>().isFlashPromoVisible(splashController.module?.id)) {
      return false;
    }
    // Rental module has no flash sale / free-delivery promos — never show the banner.
    if (splashController.module?.moduleType == AppConstants.taxi) {
      return false;
    }
    return _isFlashOngoing(flashSaleController) || splashController.module?.freeDelivery == 1;
  }

  // Promo banner shown above the navbar (home tab only, dismissable per module).
  // Rotates a flash-deal item (only while a sale is ongoing) and a free-delivery
  // item (when the module offers it) — so modules without flash sale still show it.
  Widget _buildNavbarPromo(BuildContext context, SplashController splashController) {
    return GetBuilder<FlashSaleController>(builder: (flashSaleController) {
      if (!_shouldShowNavbarPromo(flashSaleController, splashController)) {
        return const SizedBox.shrink();
      }

      final List<PromoBannerItem> promos = [
        if (_isFlashOngoing(flashSaleController))
          PromoBannerItem(
            title: 'hurry_up_flash_deal_ongoing'.tr,
            subtitle: 'grab_best_price_for_your_order'.tr,
            image: Images.flashSaleDashboard,
            accent: const Color(0xFFE2572B),
          ),
        if (splashController.module?.freeDelivery == 1)
          PromoBannerItem(
            title: 'free_delivery_for_all_order'.tr,
            subtitle: 'treat_yourself_we_got_it'.tr,
            image: Images.deliveryDashboard,
            accent: const Color(0xFFE2572B),
          ),
      ];

      return NavbarPromoBanner(
        items: promos,
        bottomTuck: _kPromoOverlap,
        onClose: () {
          Get.find<HomeController>().hideFlashPromoBanner(splashController.module?.id);
          if (mounted) setState(() {});
        },
      );
    });
  }

  Widget trackView(BuildContext context, {required bool status}) {
    return Container(height: 3, decoration: BoxDecoration(color: status ? Theme.of(context).primaryColor
        : Theme.of(context).disabledColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(Dimensions.radiusDefault)));
  }


}

class _FoodModuleBottomNavigationItem extends StatefulWidget {
  final String label;
  final String icon;
  final String selectedIcon;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool? isProfile;

  const _FoodModuleBottomNavigationItem({
    required this.label,
    required this.icon,
    this.onTap,
    required this.isSelected, this.isProfile = false, required this.selectedIcon,
  });

  @override
  State<_FoodModuleBottomNavigationItem> createState() => _FoodModuleBottomNavigationItemState();
}

class _FoodModuleBottomNavigationItemState extends State<_FoodModuleBottomNavigationItem> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glow;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    // Soft glow: expands outward from the icon and dissolves as it grows.
    _glow = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    // Icon pop: quick scale up, then settle back with a soft overshoot.
    _scale = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.22).chain(CurveTween(curve: Curves.easeOut)), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.22, end: 1.0).chain(CurveTween(curve: Curves.easeOutBack)), weight: 65),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    return Expanded(
      child: InkWell(
        onTap: widget.onTap == null ? null : _handleTap,
        borderRadius: BorderRadius.circular(40),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: widget.isProfile! ? 25 : 20, child: Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => CustomPaint(
                  painter: _NavGlowPainter(value: _glow.value, color: primary),
                  child: Transform.scale(scale: _scale.value, child: child),
                ),
                child: widget.isProfile!
                  ? _FoodModuleBottomNavigationProfileIcon(isSelected: widget.isSelected)
                  : Image.asset(widget.isSelected ? widget.selectedIcon : widget.icon, color: widget.isSelected ? primary : null),
              ),
            )),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: widget.isSelected ? robotoBold.copyWith(
                color: primary,
                fontSize: Dimensions.fontSizeSmall,
              ) : robotoRegular.copyWith(
                color: Theme.of(context).textTheme.bodyLarge!.color,
                fontSize: Dimensions.fontSizeSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Soft glow halo that blooms behind the icon on tap and then vanishes, giving
// the bottom-nav tap an eye-catchy ambient spotlight in the module color.
// [value] (0 -> 1 -> 0) drives the bloom-in then fade-out over a single tap.
class _NavGlowPainter extends CustomPainter {
  final double value;
  final Color color;

  const _NavGlowPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (value <= 0 || value >= 1) {
      return;
    }
    final Offset center = size.center(Offset.zero);
    // Grows outward from the icon (small -> large) while fading to nothing, so
    // the glow expands and dissolves rather than collapsing back in.
    const double minRadius = 14;
    const double maxRadius = 70;
    final double radius = minRadius + (maxRadius - minRadius) * value;
    // Brighter, more focused core that fades as it expands.
    final double opacity = (1 - value) * 0.55;
    final Paint paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..shader = RadialGradient(
        colors: <Color>[
          color.withValues(alpha: opacity),
          color.withValues(alpha: opacity * 0.5),
          color.withValues(alpha: 0),
        ],
        stops: const <double>[0.0, 0.35, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_NavGlowPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color;
}

class _FoodModuleBottomNavigationProfileIcon extends StatelessWidget {
  final bool isSelected;
  const _FoodModuleBottomNavigationProfileIcon({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    if(!Get.isRegistered<ProfileController>()) {
      return const _FoodModuleBottomNavigationGuestIcon();
    }

    return GetBuilder<ProfileController>(builder: (profileController) {
      final String image = profileController.userInfoModel != null && AuthHelper.isLoggedIn() ? profileController.userInfoModel!.imageFullUrl ?? '' : '';

      return Container(
        height: 24,
        width: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Theme.of(context).primaryColor, width: 1) : null,
          // border: image.isNotEmpty ? Border.all(color: Theme.of(context).disabledColor): null,
        ) ,
        child: ClipRRect(borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge), child: CustomImage(image: image, placeholder: Images.guestIcon, fit: BoxFit.cover,)),
      );
    });
  }
}

class _FoodModuleBottomNavigationGuestIcon extends StatelessWidget {
  const _FoodModuleBottomNavigationGuestIcon();

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        Images.guestIcon,
        height: 24,
        width: 24,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _HomeFloatingActionButton extends StatelessWidget {
  final SplashController splashController;
  final double extraBottomOffset;

  const _HomeFloatingActionButton({required this.splashController, this.extraBottomOffset = 0});

  @override
  Widget build(BuildContext context) {
    final bool isRide = splashController.module != null
        && splashController.module!.moduleType.toString() == AppConstants.ride;

    return GetBuilder<HomeController>(builder: (homeController) {
      if(isRide) {
        return GetBuilder<RideController>(builder: (rideController) {
          if(rideController.biddingList.isEmpty || !homeController.showFavButton) {
            return const SizedBox();
          }
          return Padding(
            padding: EdgeInsets.only(bottom: Get.height * 0.08),
            child: InkWell(
              onTap: () => Get.to(() => BidingListScreen(tripId: rideController.rideDetails!.id!)),
              child: Image.asset(Images.biddingIcon, height: 60, width: 60),
            ),
          );
        });
      }

      final bool showCashBack = AuthHelper.isLoggedIn()
          && homeController.cashBackOfferList != null
          && homeController.cashBackOfferList!.isNotEmpty
          && homeController.showFavButton;

      // AI chat is only available for the shopping modules (food, grocery, shop,
      // pharmacy). Hidden on Home (no module), parcel, rental and rideshare.
      const Set<String> aiChatModules = {
        AppConstants.food, AppConstants.grocery, AppConstants.ecommerce, AppConstants.pharmacy,
      };
      // Gate on the selected dashboard tab, not the active module: navbar screens
      // (e.g. My Orders) call setModule() as a side effect, so `module` can be a real
      // module even while the Home landing is shown. selectedModuleIndex == 0 is the
      // reliable "Home landing" signal.
      final String? moduleType = splashController.module?.moduleType?.toString();
      final bool showAiChat = (splashController.configModel?.aiChatStatus ?? false)
          && splashController.selectedModuleIndex != 0
          && moduleType != null && aiChatModules.contains(moduleType);

      return AnimatedPadding(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: 50.0 + extraBottomOffset, right: ResponsiveHelper.isDesktop(context) ? 50 : 0),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [

          showAiChat ? const AiChatBotFloatingButtonWidget() : const SizedBox(),
          showAiChat ? const SizedBox(height: Dimensions.paddingSizeSmall) : const SizedBox(),

          showCashBack ? Padding(
            padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
            child: InkWell(
              onTap: () => Get.dialog(const CashBackDialogWidget()),
              child: const CashBackLogoWidget(),
            ),
          ) : const SizedBox(),


        ]),
      );
    });
  }
}

