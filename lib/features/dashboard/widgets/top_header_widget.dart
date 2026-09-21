import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/widgets/cart_widget.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/notification/controllers/notification_controller.dart';
import 'package:sixam_mart/features/cart/screens/global_cart_screen.dart';
import 'package:sixam_mart/features/rental_module/common/widgets/rant_cart_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/module_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class TopHeaderWidget extends StatelessWidget {
  final bool isHomeModule;
  final bool isParcelModule;
  final String? title;
  final VoidCallback? onBackTap;
  final bool showModuleTabs;

  const TopHeaderWidget({
    super.key,
    required this.isHomeModule,
    this.isParcelModule = false,
    this.title,
    this.onBackTap,
    this.showModuleTabs = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).disabledColor.withAlpha(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DashboardAppBar(isHomeModule: isHomeModule, isParcelModule: isParcelModule, title: title, onBackTap: onBackTap),
          if(showModuleTabs) const ModuleTabs(),
        ],
      ),
    );
  }
}

class DashboardAppBar extends StatelessWidget {
  final bool isHomeModule;
  final bool isParcelModule;
  final String? title;
  final VoidCallback? onBackTap;

  const DashboardAppBar({
    super.key,
    required this.isHomeModule,
    this.isParcelModule = false,
    this.title,
    this.onBackTap,
  });

  @override
  Widget build(BuildContext context) {
    // final bool showBackButton = onBackTap != null || !isHomeModule;
    final String? moduleType = Get.find<SplashController>().module?.moduleType?.toString();
    final bool isRentalModule = moduleType == AppConstants.taxi;
    // Rental uses its own cart (RantCartWidget) instead of the global CartWidget.
    final bool showCart = !isParcelModule && moduleType != AppConstants.ride && !isRentalModule;
    return Center(
      child: SizedBox(
        width: Dimensions.webMaxWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeSmall,
            vertical: Dimensions.paddingSizeDefault,
          ),
          child: Row(
            children: [
              // if(showBackButton) ...[
              //   _BackButtonWidget(onTap: onBackTap ?? () => Get.find<SplashController>().selectModuleIndex(0)),
              //   const SizedBox(width: Dimensions.paddingSizeDefault),
              // ],

              Expanded(
                child: title != null
                    ? Text(
                        title!,
                        style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeLarge,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      )
                    : GetBuilder<LocationController>(builder: (locationController) {
                  final String addressText = AddressHelper.getUserAddressFromSharedPref()?.address?.trim().isNotEmpty ?? false
                      ? AddressHelper.getUserAddressFromSharedPref()!.address!
                      : 'select_your_location'.tr;

                  return InkWell(
                    // borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusDefault)),
                    onTap: () => locationController.navigateToLocationScreen('home'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                        Padding(
                          padding: const EdgeInsets.only(left: 2.0),
                          child: Text(
                            isParcelModule || moduleType == AppConstants.ride ? 'pickup_at'.tr : 'deliver_to'.tr,
                            style: robotoBold.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                              height: 110 * 0.01,
                            ),),
                        ),
                        const SizedBox(height: 2),

                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.placemark,
                              size: Dimensions.fontSizeLarge,
                              color: Theme.of(context).disabledColor,
                            ),
                            const SizedBox(width: 2),

                            Flexible(
                              child: Text(
                                addressText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: robotoRegular.copyWith(
                                  fontSize: Dimensions.fontSizeSmall,
                                  color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.5),
                                  height: 130 * 0.01,
                                ),
                              ),
                            ),

                            Icon(
                              Icons.keyboard_arrow_down_outlined,
                              size:  Dimensions.fontSizeLarge,
                            ),
                            const SizedBox(width: 64,)
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ),

              const SizedBox(width: Dimensions.paddingSizeSmall),

              _HeaderActionButton(
                onTap: () => Get.toNamed(RouteHelper.getNotificationRoute()),
                child: GetBuilder<NotificationController>(builder: (notificationController) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Image.asset(Images.bellOn, height: 24, width: 24, color: Theme.of(context).textTheme.bodyLarge!.color),

                      if(notificationController.hasNotification)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          height: 9,
                          width: 9,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(width: 1, color: Theme.of(context).cardColor),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),

              if(showCart)
                _HeaderActionButton(
                  onTap: () => Get.to(() => const GlobalCartScreen(fromNav: false)),
                  child: const CartWidget(size: 20),
                ),

              if(isRentalModule)
                RantCartWidget(callback: (_) {}),
            ],
          ),
        ),
      ),
    );
  }
}

// class _BackButtonWidget extends StatelessWidget {
//   final VoidCallback onTap;
//   const _BackButtonWidget({required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
//         decoration: BoxDecoration(
//           shape: BoxShape.circle,
//           color: Theme.of(context).cardColor,
//           boxShadow: lightShadow,
//         ),
//         alignment: Alignment.center,
//         child: Icon(
//           Icons.arrow_back_ios_new_rounded,
//           size: 20, color: Theme.of(context).textTheme.bodyLarge?.color,
//         ),
//       ),
//     );
//   }
// }

class _HeaderActionButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _HeaderActionButton({
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
        child: child,
      ),
    );
  }
}

class ModuleTabs extends StatelessWidget {
  const ModuleTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashController>(builder: (splashController) {
      if(splashController.moduleList == null) {
        return const _ModuleTabsShimmer();
      }

      final List<_FoodModuleModuleTabData> tabs = _buildTabs(splashController);
      final int selectedIndex = splashController.selectedModuleIndex >= tabs.length ? 0 : splashController.selectedModuleIndex;

      return DefaultTabController(
        key: ValueKey('food-module-module-tab-$selectedIndex-${tabs.length}'),
        length: tabs.length,
        initialIndex: selectedIndex,
        child: Center(
          child: SizedBox(
            height: 34,
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
              labelPadding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              indicator: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusDefault)),
                boxShadow: lightShadow,
              ),
              labelStyle: robotoBold.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).textTheme.bodyLarge!.color,
              ),
              unselectedLabelStyle: robotoBold.copyWith(
                fontSize: Dimensions.fontSizeDefault,
              ),
              labelColor: Theme.of(context).textTheme.bodyLarge?.color,
              unselectedLabelColor: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.5),
              onTap: (index) => tabs[index].onTap?.call(),
              tabs: tabs.map((tab) {
                return Tab(text: tab.label);
              }).toList(),
            ),
          ),
        ),
      );
    });
  }

  List<_FoodModuleModuleTabData> _buildTabs(SplashController splashController) {
    final List<_FoodModuleModuleTabData> tabs = [
      _FoodModuleModuleTabData(
        label: 'home'.tr,
        isSelected: splashController.selectedModuleIndex == 0,
        onTap: () => splashController.selectHomeModule(),
      ),
    ];

    int selectedIndex = 1;
    if(splashController.moduleList != null && splashController.moduleList!.isNotEmpty) {
      for(int index = 0; index < splashController.moduleList!.length; index++) {
        final module = splashController.moduleList![index];
        final String moduleType = module.moduleType?.toString() ?? '';
        final int currentTabIndex = selectedIndex;

        tabs.add(
          _FoodModuleModuleTabData(
            label: ModuleHelper.moduleDisplayName(moduleType, moduleName: module.moduleName),
            isSelected: splashController.selectedModuleIndex == currentTabIndex,
            onTap: () => splashController.selectModuleByTabIndex(currentTabIndex),
          ),
        );
        selectedIndex++;
      }
    }

    if(tabs.length == 1) {
      tabs.addAll([
        _FoodModuleModuleTabData(
          label: 'Food',
          isSelected: splashController.selectedModuleIndex == 1,
          onTap: () => splashController.selectModuleIndex(1),
        ),
        _FoodModuleModuleTabData(
          label: 'Grocery',
          isSelected: splashController.selectedModuleIndex == 2,
          onTap: () => splashController.selectModuleIndex(2),
        ),
        _FoodModuleModuleTabData(
          label: 'Shop',
          isSelected: splashController.selectedModuleIndex == 3,
          onTap: () => splashController.selectModuleIndex(3),
        ),
        _FoodModuleModuleTabData(
          label: 'Pharmacy',
          isSelected: splashController.selectedModuleIndex == 4,
          onTap: () => splashController.selectModuleIndex(4),
        ),
      ]);
    }

    return tabs;
  }
}

class _FoodModuleModuleTabData {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _FoodModuleModuleTabData({
    required this.label,
    this.isSelected = false,
    this.onTap,
  });
}

class _ModuleTabsShimmer extends StatelessWidget {
  const _ModuleTabsShimmer();

  static const List<double> _tabLabelWidths = [55, 70, 50, 75];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 34,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
          children: [
            const _HomeTabPlaceholder(),
            Shimmer(
              duration: const Duration(seconds: 2),
              child: Row(
                children: _tabLabelWidths.map((width) => _ModuleTabPlaceholder(width: width)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The "Home" tab is always available (it never depends on `SplashController.moduleList`
/// loading), so it renders as real, static content — mirroring the selected-tab indicator
/// card (`indicatorSize: TabBarIndicatorSize.tab`) — instead of shimmering.
class _HomeTabPlaceholder extends StatelessWidget {
  const _HomeTabPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusDefault)),
        boxShadow: lightShadow,
      ),
      child: Text(
        'home'.tr,
        style: robotoBold.copyWith(
          fontSize: Dimensions.fontSizeDefault,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }
}

/// Mirrors a single unselected [Tab] inside the real [TabBar]: `labelPadding` inset on both sides.
class _ModuleTabPlaceholder extends StatelessWidget {
  final double width;

  const _ModuleTabPlaceholder({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      alignment: Alignment.center,
      child: _Bar(width: width, height: 14),
    );
  }
}

/// Pill-shaped placeholder for a single tab label.
class _Bar extends StatelessWidget {
  final double width;
  final double height;

  const _Bar({required this.width, this.height = 12});

  @override
  Widget build(BuildContext context) {
    return Container(height: height, width: width,
      decoration: BoxDecoration(color: _shimmerColor(context), borderRadius: BorderRadius.circular(99)),
    );
  }
}

Color _shimmerColor(BuildContext context) {
  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? Colors.white.withValues(alpha: 0.18) : const Color(0xFFE9E9E9);
}
