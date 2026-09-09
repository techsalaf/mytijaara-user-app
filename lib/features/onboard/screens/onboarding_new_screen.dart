import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_asset_image_widget.dart';
import 'package:sixam_mart/common/widgets/web_menu_bar.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/onboard/controllers/onboard_controller.dart';
import 'package:sixam_mart/features/onboard/domain/repository/onboard_repository.dart';
import 'package:sixam_mart/features/onboard/domain/service/onboard_service.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class OnBoardingNewScreen extends StatefulWidget {
  const OnBoardingNewScreen({super.key});

  @override
  State<OnBoardingNewScreen> createState() => _OnBoardingNewScreenState();
}

class _OnBoardingNewScreenState extends State<OnBoardingNewScreen> {
  final PageController _pageController = PageController();
  late final OnBoardingController _onBoardingController =
      OnBoardingController(onboardServiceInterface: OnboardService(onboardRepositoryInterface: OnboardRepository()));
  static const List<_OnBoardingNewText> _onBoardingText = [
    _OnBoardingNewText(
      image: Images.onBoard,
      title: 'on_boarding_1_title',
      description: 'on_boarding_1_description',
    ),
    _OnBoardingNewText(
      image: Images.onboard_3,
      title: 'on_boarding_2_title',
      description: 'on_boarding_2_description',
    ),
    _OnBoardingNewText(
      image: Images.onboard_2,
      title: 'on_boarding_3_title',
      description: 'on_boarding_3_description',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _onBoardingController.getOnBoardingList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: ResponsiveHelper.isDesktop(context) ? const WebMenuBar() : null,
      body: SafeArea(
        child: GetBuilder<OnBoardingController>(
          init: _onBoardingController,
          global: false,
          builder: (onBoardingController) {
            bool showIndicatorAndButton = onBoardingController.selectedIndex < onBoardingController.onBoardingList.length - 1;
            bool isLastOnBoardingPage = onBoardingController.selectedIndex >= onBoardingController.onBoardingList.length - 2;
            int displayIndex = onBoardingController.selectedIndex;
            if (displayIndex >= _onBoardingText.length) {
              displayIndex = _onBoardingText.length - 1;
            }
            return onBoardingController.onBoardingList.isNotEmpty
              ? Center(child: SizedBox(width: Dimensions.webMaxWidth,
                  child: Column(children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(25), bottomRight: Radius.circular(25)),
                        ),
                        child: Stack(children: [
                          PageView.builder(
                            itemCount: onBoardingController.onBoardingList.length,
                            controller: _pageController,
                            itemBuilder: (context, index) {
                              if (index >= _onBoardingText.length) {
                                return const SizedBox.expand();
                              }
                              return _OnBoardingImage(image: _onBoardingText[index].image);
                            },
                            onPageChanged: (index) {
                              onBoardingController.changeSelectIndex(index);
                              if (onBoardingController.selectedIndex == 3) {
                                _configureToRouteInitialPage();
                              }
                            },
                          ),

                          if (showIndicatorAndButton && !isLastOnBoardingPage)
                            Positioned(
                              top: Dimensions.paddingSizeLarge,
                              right: Dimensions.paddingSizeExtremeLarge,
                              child: _SkipButton(onTap: _configureToRouteInitialPage),
                            ),
                        ]),
                      ),
                    ),

                    if (showIndicatorAndButton)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 42, 24, 28),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(
                            _onBoardingText[displayIndex].title.tr,
                            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge,
                            ),
                            textAlign: TextAlign.center, maxLines: 2,
                          ),
                          const SizedBox(height: 12),

                          Text(_onBoardingText[displayIndex].description.tr,
                            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 34),

                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            _CircleArrowButton(
                              icon: Icons.arrow_back,
                              backgroundColor: Theme.of(context).cardColor,
                              iconColor: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.6),
                              onTap: () {
                                if (onBoardingController.selectedIndex == 0) {
                                  Get.back();
                                }
                                if (onBoardingController.selectedIndex > 0) {
                                  _pageController.previousPage(
                                    duration: const Duration(milliseconds: 450),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              },
                            ),
                            const SizedBox(width: 22),
                            _NextArrowButton(
                              progress: (displayIndex + 1) / _onBoardingText.length,
                              onTap: () {
                                if (onBoardingController.selectedIndex != 2) {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 450),
                                    curve: Curves.easeInOut,
                                  );
                                } else {
                                  _configureToRouteInitialPage();
                                }
                              },
                            ),
                          ]),
                        ]),
                      )
                    else const SizedBox(height: 250),
                  ]),
                )) : const SizedBox();
          },
        ),
      ),
    );
  }

  void _configureToRouteInitialPage() async {
    Get.find<SplashController>().disableIntro();
    await Get.find<AuthController>().guestLogin();
    if (AddressHelper.getUserAddressFromSharedPref() != null) {
      Get.offNamed(RouteHelper.getInitialRoute(fromSplash: true));
    } else {
      Get.find<LocationController>().navigateToLocationScreen(RouteHelper.onBoarding, offNamed: true)
          .then((v) {_pageController.jumpToPage(_onBoardingController.onBoardingList.length - 2);});
    }
  }
}

class _OnBoardingNewText {
  final String image;
  final String title;
  final String description;

  const _OnBoardingNewText({required this.image, required this.title, required this.description});
}

class _OnBoardingImage extends StatelessWidget {
  final String image;

  const _OnBoardingImage({required this.image});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, 0.24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: CustomAssetImageWidget(image, height: context.height * 0.26, fit: BoxFit.contain),
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SkipButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 30,
          decoration: BoxDecoration(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall + 2, vertical: Dimensions.paddingSizeExtraSmall - 2),
          child: Center(
            child: Text(
              'skip'.tr,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleArrowButton extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _CircleArrowButton({required this.icon, required this.backgroundColor, required this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      child: InkWell(onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(width: 36, height: 36,
          child: Icon(icon, color: iconColor, size: 14),
        ),
      ),
    );
  }
}

class _NextArrowButton extends StatelessWidget {
  final double progress;
  final VoidCallback onTap;

  const _NextArrowButton({required this.progress, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;

    return SizedBox(width: 56, height: 48,
      child: Stack(alignment: Alignment.center, children: [
        SizedBox(width: 42, height: 42,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOut,
            builder: (context, value, child) => CircularProgressIndicator(
              value: value,
              strokeWidth: 2,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          ),
        ),
        _CircleArrowButton(
          icon: Icons.arrow_forward,
          backgroundColor: primaryColor,
          iconColor: Theme.of(context).cardColor,
          onTap: onTap,
        ),
      ]),
    );
  }
}
