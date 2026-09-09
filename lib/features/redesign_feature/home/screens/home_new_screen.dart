import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/smart_banner/controllers/smart_banner_controller.dart';
import 'package:sixam_mart/features/pro/controllers/pro_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/banner_slider.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/last_orders_section_widget.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/search_header_widget.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/top_picks_near_you_widget.dart';
import 'package:sixam_mart/features/redesign_feature/home/screens/preference_screen.dart';
import 'package:sixam_mart/features/redesign_feature/home/widgets/home_new_module_section_widget.dart';
import 'package:sixam_mart/features/redesign_feature/home/widgets/home_smart_banner_widget.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sliver_tools/sliver_tools.dart';

class HomeNewScreen extends StatefulWidget {
  final Key searchHeaderKey;
  final bool isSearchPinned;
  const HomeNewScreen({super.key, required this.searchHeaderKey, this.isSearchPinned = false});

  @override
  State<HomeNewScreen> createState() => _HomeNewScreenState();
}

class _HomeNewScreenState extends State<HomeNewScreen> {
  final ScrollController _scrollController = ScrollController();
  Timer? _preferenceScreenTimer;
  bool _preferenceScreenShown = false;

  bool _moduleSectionExpanded = false;
  bool _dimOverlayVisible = false;
  ScrollPosition? _parentScrollPosition;

  void _schedulePreferenceScreen() {
    final int delayInSeconds = 3 + Random().nextInt(5);
    _preferenceScreenTimer = Timer(Duration(seconds: delayInSeconds), () {
      if(!mounted || _preferenceScreenShown || !(ModalRoute.of(context)?.isCurrent ?? false)) {
        return;
      }
      _preferenceScreenShown = true;
      Get.to(() => const PreferenceScreen(), transition: Transition.rightToLeft);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_){
      Get.find<OrderController>().getLastOrders(isHome: false);
      // Reload the global (home) featured stores. A module screen may have
      // overwritten the shared featured list with module-scoped data, so always
      // refresh it on Home entry with the home/global header.
      Get.find<StoreController>().getFeaturedStoreList(fromHome: true);
      if(Get.find<ProfileController>().userInfoModel?.proStatus ?? false) {
        Get.find<ProController>().getProActiveOffer(moduleType: 'grocery');
      }
    });
    Get.find<SmartBannerController>().getSmartBanners(notify: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ScrollableState? scrollable = Scrollable.maybeOf(context);
    final ScrollPosition? newPosition = scrollable?.position;
    if (newPosition != _parentScrollPosition) {
      _parentScrollPosition?.removeListener(_handleParentScroll);
      _parentScrollPosition = newPosition;
      _parentScrollPosition?.addListener(_handleParentScroll);
    }
  }

  void _handleParentScroll() {
    if (_dimOverlayVisible) {
      _hideDimOverlay();
    }
  }

  void _setModuleExpanded(bool expanded) {
    if (_moduleSectionExpanded == expanded) {
      return;
    }
    setState(() {
      _moduleSectionExpanded = expanded;
      _dimOverlayVisible = expanded;
    });
  }

  void _hideDimOverlay() {
    if (!_dimOverlayVisible) {
      return;
    }
    setState(() {
      _dimOverlayVisible = false;
    });
  }

  @override
  void dispose() {
    _parentScrollPosition?.removeListener(_handleParentScroll);
    _parentScrollPosition = null;
    _preferenceScreenTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiSliver(
        children: [

          /// Main Content
          SliverToBoxAdapter(
            child: Center(
              child: Container(
                width: Dimensions.webMaxWidth,
                color: Theme.of(context).disabledColor.withAlpha(30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Visibility(
                      visible: !widget.isSearchPinned,
                      maintainSize: true, maintainState: true, maintainAnimation: true,
                      child: SearchAndQuickFilterWidget(key: widget.searchHeaderKey, isPinned: false, showQuickFilters: false, isHomeModule: true),
                    ),

                    HomeNewModuleSectionWidget(
                      isExpanded: _moduleSectionExpanded,
                      onExpandedChanged: _setModuleExpanded,
                    ),

                    _DimmableSection(
                      isDimmed: _dimOverlayVisible,
                      onDismiss: _hideDimOverlay,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          const HomeSmartBannerWidget(),

                          const SizedBox(height: Dimensions.paddingSizeSmall),
                          const LastOrdersSectionWidget(),

                          const SizedBox(height: Dimensions.paddingSizeSmall),

                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusLarge)),
                            ),
                            child: Column(children: [

                              const SizedBox(height: Dimensions.paddingSizeLarge),

                              const BannerSliderWidget(isFeatured: true),
                              // const Divider(height: Dimensions.paddingSizeLarge),
                              const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                              TopPicksNearYouWidget(title: "featured_stores_restaurants".tr, isFeatured: true),
                            ]),
                          ),
                        ],
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),
        ],
    );
  }

}

class _DimmableSection extends StatelessWidget {
  final bool isDimmed;
  final VoidCallback onDismiss;
  final Widget child;

  const _DimmableSection({required this.isDimmed, required this.onDismiss, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -Dimensions.radiusExtraLarge,
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            ignoring: !isDimmed,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onDismiss,
              child: AnimatedOpacity(
                opacity: isDimmed ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: const ClipPath(
                  clipper: _DimYokeClipper(cornerRadius: Dimensions.radiusExtraLarge),
                  child: ColoredBox(color: Color(0x66000000)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DimYokeClipper extends CustomClipper<Path> {
  final double cornerRadius;

  const _DimYokeClipper({required this.cornerRadius});

  @override
  Path getClip(Size size) {
    final double r = cornerRadius;
    return Path()
      ..moveTo(0, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, 0)
      ..arcToPoint(
        Offset(size.width - r, r),
        radius: Radius.circular(r),
        clockwise: true,
      )
      ..lineTo(r, r)
      ..arcToPoint(
        const Offset(0, 0),
        radius: Radius.circular(r),
        clockwise: true,
      )
      ..close();
  }

  @override
  bool shouldReclip(covariant _DimYokeClipper oldClipper) => cornerRadius != oldClipper.cornerRadius;
}

class _TabItem {
  final String label;
  final IconData icon;

  const _TabItem({required this.label, required this.icon});
}
