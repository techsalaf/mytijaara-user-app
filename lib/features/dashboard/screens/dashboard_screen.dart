import 'dart:async';
import 'dart:io';

import 'package:expandable_bottom_sheet/expandable_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/common/models/ongoing_order_model.dart';
import 'package:sixam_mart/common/widgets/custom_dialog.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/login_suggestion_bottomsheet.dart';
import 'package:sixam_mart/features/ai_chat_bot/widgets/ai_chat_bot_floating_button_widget.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/checkout/widgets/congratulation_dialogue.dart';
import 'package:sixam_mart/features/dashboard/screens/main_screen.dart';
import 'package:sixam_mart/features/dashboard/widgets/address_bottom_sheet_widget.dart';
import 'package:sixam_mart/features/dashboard/widgets/home_status_bar_tint.dart';
import 'package:sixam_mart/features/dashboard/widgets/ios_edge_swipe_back_detector.dart';
import 'package:sixam_mart/features/dashboard/widgets/navbar_promo_banner.dart';
import 'package:sixam_mart/features/dashboard/widgets/payment_incomplete_bottomsheet.dart';
import 'package:sixam_mart/features/dashboard/widgets/store_registration_success_bottom_sheet.dart';
import 'package:sixam_mart/features/favourite/screens/favourite_screen.dart';
import 'package:sixam_mart/features/flash_sale/controllers/flash_sale_controller.dart';
import 'package:sixam_mart/features/happy_hour/controllers/happy_hour_controller.dart';
import 'package:sixam_mart/features/happy_hour/widgets/happy_hour_banner_widget.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/home/widgets/cashback_dialog_widget.dart';
import 'package:sixam_mart/features/home/widgets/cashback_logo_widget.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/offer/offer_screen.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/screens/my_order_screen.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/profile/screens/profile_screen.dart';
import 'package:sixam_mart/features/ride_share_module/ride_home/screens/biding_list_screen.dart';
import 'package:sixam_mart/features/ride_share_module/ride_order/controllers/ride_controller.dart';
import 'package:sixam_mart/features/service_module/booking_details/controllers/booking_controller.dart';
import 'package:sixam_mart/features/service_module/booking_details/widgets/service_running_booking_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/image_cache_helper.dart';
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
  ModuleModel? _moduleBeforeOffers;
  ModuleModel? _moduleBeforeMyOrders;
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey();
  bool _canExit = GetPlatform.isWeb ? true : false;

  GlobalKey<ExpandableBottomSheetState> key = GlobalKey();

  late bool _isLogin;
  bool active = false;
  bool _navBarVisible = true;

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

  void _updateHomeStatusBarTint() {
    HomeStatusBarTint.active.value = mounted && !ResponsiveHelper.isWeb() && _pageIndex == 0 && !_coveredByOpaque;
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is UserScrollNotification && notification.metrics.axis == Axis.vertical) {
      if (notification.direction == ScrollDirection.reverse && _navBarVisible) {
        setState(() => _navBarVisible = false);
      } else if (notification.direction == ScrollDirection.forward && !_navBarVisible) {
        setState(() => _navBarVisible = true);
      }
    }
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

    if((AuthHelper.isLoggedIn() || AuthHelper.isGuestLoggedIn())
        && Get.find<SplashController>().module?.moduleType == AppConstants.service) {
      Get.find<BookingController>().getDashboardRunningBookings();
    }

    _pageIndex = widget.pageIndex;
    _moduleBeforeOffers = Get.find<SplashController>().module;
    _moduleBeforeMyOrders = Get.find<SplashController>().module;

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
    _pageController?.dispose();
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
          onPopInvokedWithResult: (didPop, result) => _handleBackPress(),
          child: IosEdgeSwipeBackDetector(
            enabled: !GetPlatform.isWeb && GetPlatform.isIOS,
            onBack: _handleBackPress,
            child: GetBuilder<OrderController>(
              builder: (orderController) {
                List<OrderData> runningOrder = orderController.ongoingOrderModel != null ? orderController.ongoingOrderModel!.data! : [];
            
                return GetBuilder<BookingController>(builder: (bookingController) {
                final bool hasRunningSheet = _hasRunningSheet(context, orderController, bookingController, splashController);
                final double promoBottomInset = _promoBottomInset(hasRunningSheet);
                return SafeArea(
                  top: false, bottom: GetPlatform.isAndroid,
                  child: Scaffold(
                    key: _scaffoldKey,
                    floatingActionButton: _pageIndex == 0 ? GetBuilder<FlashSaleController>(builder: (flashSaleController) {
                      return GetBuilder<HappyHourController>(builder: (happyHourController) {
                        final double promoOffset = _shouldShowHappyHourBanner(happyHourController, splashController)
                            ? (happyHourController.bannerHeight > 0 ? happyHourController.bannerHeight : _kPromoBannerReservedHeight) + promoBottomInset
                            : _shouldShowNavbarPromo(flashSaleController, splashController) ? _kPromoBannerReservedHeight + promoBottomInset : 0;
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
                      });
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
                              child: Stack(alignment: Alignment.bottomCenter, clipBehavior: Clip.none, children: [
                                
                                Padding(
                                  padding: EdgeInsets.only(bottom: _kNavPillHeight - _kPromoOverlap + promoBottomInset),
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
                            child: Material(
                              type: MaterialType.transparency,
                              child: LayoutBuilder(
                              builder: (context, constraints) {
                                const indicatorWidth = 36.0;
                                const indicatorHeight = 4.0;
                                final itemWidth = constraints.maxWidth / 4;
                                final selectedSlot = _pageIndex >= 1 && _pageIndex <= 4 ? _pageIndex - 1 : -1;
                               
                                final bool isLtr = Get.find<LocalizationController>().isLtr;
                                final double indicatorOffset = selectedSlot == -1
                                    ? -indicatorWidth
                                    : (itemWidth * selectedSlot) + (itemWidth - indicatorWidth) / 2;
            
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    AnimatedPositioned(
                                      duration: const Duration(milliseconds: 280),
                                      curve: Curves.easeOutCubic,
                                      top: 0,
                                      left: isLtr ? indicatorOffset : null,
                                      right: isLtr ? null : indicatorOffset,
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
            
                      persistentContentHeight: (widget.fromSplash && Get.find<LocationController>().showLocationSuggestion && active) ? 0 : _runningSheetHeight,
            
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
                      
                      : (splashController.module?.moduleType == AppConstants.service)
                      ? ((ResponsiveHelper.isDesktop(context) || (bookingController.dashboardRunningBookings ?? []).isEmpty || !orderController.showBottomSheet) ? const SizedBox()
                      : Dismissible(
                        key: UniqueKey(),
                        onDismissed: (direction) {
                          if(orderController.showBottomSheet){
                            orderController.showRunningOrders();
                          }
                        },
                        child: ServiceRunningBookingWidget(bookings: bookingController.dashboardRunningBookings!, onTap: () {
                          _setPage(2);
                          if(orderController.showBottomSheet){
                            orderController.showRunningOrders();
                          }
                        }),
                      ))
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
                });
              }
            ),
          ),
        );
      }
    );
  }

  void _handleBackPress() {
    final SplashController splashController = Get.find<SplashController>();
    final bool hasModuleLanding = !ResponsiveHelper.isDesktop(context)
        && splashController.module != null && splashController.configModel!.module == null
        && splashController.moduleList != null && splashController.moduleList!.length != 1;

    if (_pageIndex != 0) {
      _setPage(0);
    } else if (splashController.selectedModuleIndex != 0 && hasModuleLanding) {
      splashController.selectHomeModule();
    } else {
      if(hasModuleLanding) {
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
  }


  void _setPage(int pageIndex) {
    final int previousIndex = _pageIndex;
    if (pageIndex == offersPageIndex && previousIndex != offersPageIndex) {
      _moduleBeforeOffers = Get.find<SplashController>().module;
    }
    if (pageIndex == myOrdersPageIndex && previousIndex != myOrdersPageIndex) {
      _moduleBeforeMyOrders = Get.find<SplashController>().module;
    }
    setState(() {
      _pageController!.jumpToPage(pageIndex);
      _pageIndex = pageIndex;
    });

    if (previousIndex == offersPageIndex && pageIndex != offersPageIndex) {
      final SplashController splash = Get.find<SplashController>();
      if (splash.module?.id != _moduleBeforeOffers?.id) {
        splash.setModule(_moduleBeforeOffers, notify: false);
      }
    }
    if (previousIndex == myOrdersPageIndex && pageIndex != myOrdersPageIndex) {
      final SplashController splash = Get.find<SplashController>();
      if (splash.module?.id != _moduleBeforeMyOrders?.id) {
        splash.setModule(_moduleBeforeMyOrders, notify: false);
      }
    }
    _updateHomeStatusBarTint();
  }

  static const int offersPageIndex = 1;

  static const int myOrdersPageIndex = 2;

  void setPage(int pageIndex) => _setPage(pageIndex);

  static bool switchToTab(BuildContext context, int pageIndex) {
    final DashboardScreenState? state = context.findAncestorStateOfType<DashboardScreenState>();
    if (state == null) {
      return false;
    }
    state.setPage(pageIndex);
    return true;
  }

  static const double _kNavPillHeight = 62;
  static const double _kPromoOverlap = 25;
  static const double _kPromoBannerReservedHeight = 72;

  static double get _runningSheetHeight => GetPlatform.isIOS ? 110 : 100;

  bool _hasRunningSheet(BuildContext context, OrderController orderController, BookingController bookingController, SplashController splashController) {
    if(ResponsiveHelper.isDesktop(context) || !orderController.showBottomSheet) {
      return false;
    }
    if(widget.fromSplash && Get.find<LocationController>().showLocationSuggestion && active) {
      return false;
    }
    if(splashController.module?.moduleType == AppConstants.service) {
      return (bookingController.dashboardRunningBookings ?? []).isNotEmpty;
    }
    return _isLogin && (orderController.ongoingOrderModel?.data?.isNotEmpty ?? false);
  }

  double _promoBottomInset(bool hasRunningSheet) {
    if(!hasRunningSheet) {
      return 0;
    }
    final double covered = _runningSheetHeight - (_kNavPillHeight + Dimensions.paddingSizeDefault);
    return covered > 0 ? covered + Dimensions.paddingSizeSmall : 0;
  }

  bool _isFlashOngoing(FlashSaleController flashSaleController) {
    final flashSaleModel = flashSaleController.flashSaleModel;
    return flashSaleModel != null
        && (flashSaleModel.activeProducts?.isNotEmpty ?? false)
        && flashSaleController.duration != null
        && flashSaleController.duration!.inSeconds > 1;
  }

  // would bury the pill itself.
  bool _shouldShowHappyHourBanner(HappyHourController happyHourController, SplashController splashController) {
    // The offer belongs to the module it was fetched for, so Home (no module) and other modules never show it.
    return _pageIndex == 0 && happyHourController.showBannerForModule(splashController.module?.id);
  }

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


  Widget _buildNavbarPromo(BuildContext context, SplashController splashController) {
    return GetBuilder<HappyHourController>(builder: (happyHourController) {
      if (_shouldShowHappyHourBanner(happyHourController, splashController)) {
        return const _JumpingPromo(child: HappyHourBannerWidget(bottomTuck: _kPromoOverlap));
      }
      return _buildFlashPromo(context, splashController);
    });
  }

  Widget _buildFlashPromo(BuildContext context, SplashController splashController) {
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

class _JumpingPromo extends StatefulWidget {
  final Widget child;

  const _JumpingPromo({required this.child});

  @override
  State<_JumpingPromo> createState() => _JumpingPromoState();
}

class _JumpingPromoState extends State<_JumpingPromo> with SingleTickerProviderStateMixin {
  static const double _hopHeight = 10;

  late final AnimationController _controller;
  late final Animation<double> _hop;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();
    _hop = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: -1).chain(CurveTween(curve: Curves.easeOut)), weight: 10),
      TweenSequenceItem(tween: Tween<double>(begin: -1, end: 0).chain(CurveTween(curve: Curves.bounceOut)), weight: 17),
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 73),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _hop,
      builder: (context, child) => Transform.translate(offset: Offset(0, _hop.value * _hopHeight), child: child),
      child: widget.child,
    );
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
    _glow = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
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
    const double minRadius = 14;
    const double maxRadius = 70;
    final double radius = minRadius + (maxRadius - minRadius) * value;
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
        child: ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
            child: CustomImage(
              image: image, placeholder: Images.guestIcon, fit: BoxFit.cover,
              cacheHeight: ImageCacheHelper.pixels(context, 24), cacheWidth: ImageCacheHelper.pixels(context, 24),
            ),
        ),
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

      const Set<String> aiChatModules = {
        AppConstants.food, AppConstants.grocery, AppConstants.ecommerce, AppConstants.pharmacy, AppConstants.service,
      };
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
            padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
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

// SUMMARY
// Dashboard shell: hosts the home, offers, orders, favourite and profile tabs behind a
// floating nav pill, the promo and Happy Hour banner tucked above it, the home floating
// buttons, and the running order or booking sheet that slides up from the bottom —
// keeping the banner and buttons clear of whatever the sheet covers.
