import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/banner/domain/models/others_banner_model.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/basic_campaign_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/features/store/screens/store_screen.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/image_cache_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:url_launcher/url_launcher_string.dart';

const double _kViewportFraction = 0.8;
const double _kHeightRatio = 0.5;
const double _kSlideBottomMargin = 3;

double _sliderHeight(BuildContext context) =>
    MediaQuery.sizeOf(context).width * _kViewportFraction * _kHeightRatio;

class BannerSliderWidget extends StatefulWidget {
  final List<ParcelBanner>? bannerList;
  final bool isFeatured;
  const BannerSliderWidget({super.key, this.bannerList, this.isFeatured = false});

  @override
  State<BannerSliderWidget> createState() => _BannerSliderWidgetState();
}

class _BannerSliderWidgetState extends State<BannerSliderWidget> {
  final CarouselSliderController _carouselController = CarouselSliderController();
  final ValueNotifier<int> _currentIndex = ValueNotifier<int>(0);

  @override
  void dispose() {
    _currentIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bannerList != null) {
      return _ParcelSlider(
        bannerList: widget.bannerList!,
        carouselController: _carouselController,
        currentIndexNotifier: _currentIndex,
        onPageChanged: (index) => _currentIndex.value = index,
      );
    }

    return GetBuilder<BannerController>(builder: (bannerController) {
      final List<String?>? images = widget.isFeatured ? bannerController.featuredBannerList : bannerController.bannerImageList;
      final List<dynamic>? data = widget.isFeatured ? bannerController.featuredBannerDataList : bannerController.bannerDataList;

      if (images == null) {
        return const BannerSliderShimmer();
      }
      if (images.isEmpty) {
        return const SizedBox();
      }
      return _DynamicSlider(
        images: images, data: data, isFeatured: widget.isFeatured, carouselController: _carouselController,
        currentIndexNotifier: _currentIndex,
        onPageChanged: (index) {
          _currentIndex.value = index;
          // notify: false — nothing in this screen reads BannerController.currentIndex,
          // and an update() here would rebuild the GetBuilder above for nothing.
          bannerController.setCurrentIndex(index, false);
        },
      );
    });
  }
}

class _ParcelSlider extends StatelessWidget {
  final List<ParcelBanner> bannerList;
  final CarouselSliderController carouselController;
  final ValueNotifier<int> currentIndexNotifier;
  final ValueChanged<int> onPageChanged;

  const _ParcelSlider({
    required this.bannerList, required this.carouselController, required this.currentIndexNotifier, required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (bannerList.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CarouselSlider.builder(
          carouselController: carouselController,
          itemCount: bannerList.length,
          itemBuilder: (context, index, realIndex) => Container(
            margin: const EdgeInsets.only(left: Dimensions.paddingSizeDefault),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
              child: SizedBox.expand(child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
                return CustomImage(image: bannerList[index].imageFullUrl ?? '', fit: BoxFit.fill,
                  cacheWidth: ImageCacheHelper.pixels(context, constraints.maxWidth),
                  cacheHeight: ImageCacheHelper.pixels(context, constraints.maxHeight),
                );
              })),
            ),
          ),
          options: CarouselOptions(
            height: _sliderHeight(context),
            viewportFraction: _kViewportFraction,
            initialPage: 0,
            enableInfiniteScroll: bannerList.length > 1,
            enlargeCenterPage: false,
            padEnds: false,
            autoPlay: bannerList.length > 1,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.easeInOut,
            onPageChanged: (index, reason) => onPageChanged(index),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        _DotIndicator(count: bannerList.length, currentIndexNotifier: currentIndexNotifier, carouselController: carouselController),
      ],
    );
  }
}

class _DynamicSlider extends StatelessWidget {
  final List<String?> images;
  final List<dynamic>? data;
  final bool isFeatured;
  final CarouselSliderController carouselController;
  final ValueNotifier<int> currentIndexNotifier;
  final ValueChanged<int> onPageChanged;

  const _DynamicSlider({
    required this.images, required this.data, required this.isFeatured, required this.carouselController,
    required this.currentIndexNotifier, required this.onPageChanged,
  });

  Future<void> _handleTap(BuildContext context, int index) async {
    if (data == null || index >= data!.length) return;
    final dynamic entry = data![index];
    if (entry is Item) {
      Get.find<ItemController>().navigateToItemPage(entry, context);
    } else if (entry is Store) {
      if (isFeatured) {
        final List<ModuleModel>? moduleList = Get.find<SplashController>().moduleList;
        if (moduleList != null) {
          for (ModuleModel module in moduleList) {
            if (module.id == entry.moduleId) {
              Get.find<SplashController>().setModule(module);
              break;
            }
          }
        }
        final List<ZoneData>? zoneDataList = AddressHelper.getUserAddressFromSharedPref()?.zoneData;
        final ZoneData? zoneData = zoneDataList?.firstWhereOrNull((data) => data.id == entry.zoneId);
        final Modules? module = zoneData?.modules?.firstWhereOrNull((module) => module.id == entry.moduleId);
        if (module != null) {
          Get.find<SplashController>().setModule(ModuleModel(id: module.id, moduleName: module.moduleName, moduleType: module.moduleType, themeId: module.themeId, storesCount: module.storesCount));
        }
      }
      Get.toNamed(
        RouteHelper.getStoreRoute(id: entry.id, page: isFeatured ? 'module' : 'banner', slug: entry.slug ?? 'store_${entry.id}'),
        arguments: StoreScreen(store: entry, fromModule: isFeatured),
      );
    } else if (entry is BasicCampaignModel) {
      Get.toNamed(RouteHelper.getBasicCampaignRoute(entry));
    } else if (entry is String) {
      if (await canLaunchUrlString(entry)) {
        await launchUrlString(entry, mode: LaunchMode.externalApplication);
      } else {
        showCustomSnackBar('unable_to_found_url'.tr);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double sliderHeight = _sliderHeight(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CarouselSlider.builder(
          carouselController: carouselController,
          itemCount: images.length,
          itemBuilder: (context, index, realIndex) => InkWell(
            onTap: () => _handleTap(context, index),
            child: Container(
              margin: const EdgeInsets.only(left: Dimensions.paddingSizeDefault, bottom: _kSlideBottomMargin),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                // SizedBox.expand gives tight constraints, so these are the exact
                // painted box. Both axes suit BoxFit.fill, which stretches to it.
                child: SizedBox.expand(child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
                  return CustomImage(image: images[index] ?? '', fit: BoxFit.fill,
                    cacheWidth: ImageCacheHelper.pixels(context, constraints.maxWidth),
                    cacheHeight: ImageCacheHelper.pixels(context, constraints.maxHeight),
                  );
                })),
              ),
            ),
          ),
          options: CarouselOptions(
            height: sliderHeight,
            viewportFraction: _kViewportFraction,
            initialPage: 0,
            enableInfiniteScroll: images.length > 1,
            enlargeCenterPage: false,
            padEnds: false,
            autoPlay: images.length > 1,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.easeInOut,
            onPageChanged: (index, reason) => onPageChanged(index),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        _DotIndicator(count: images.length, currentIndexNotifier: currentIndexNotifier, carouselController: carouselController),
      ],
    );
  }
}

/// Page dots. Listens to the index itself so a page change repaints this strip
/// instead of the slider above it.
class _DotIndicator extends StatelessWidget {
  final int count;
  final ValueNotifier<int> currentIndexNotifier;
  final CarouselSliderController carouselController;

  const _DotIndicator({required this.count, required this.currentIndexNotifier, required this.carouselController});

  @override
  Widget build(BuildContext context) {
    final Color activeColor = Theme.of(context).textTheme.bodyLarge!.color!;
    final Color inactiveColor = Theme.of(context).hintColor.withValues(alpha: 0.45);

    return SizedBox(
      height: 10,
      child: ValueListenableBuilder<int>(
        valueListenable: currentIndexNotifier,
        builder: (BuildContext context, int currentIndex, Widget? child) {
          final int activeIndex = currentIndex < count ? currentIndex : 0;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(count, (index) {
              final bool isActive = index == activeIndex;
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => carouselController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall / 2),
                  height: isActive ? 8 : 5,
                  width: isActive ? 8 : 5,
                  decoration: BoxDecoration(
                    color: isActive ? activeColor : inactiveColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// Loading state for [BannerSliderWidget], covering the whole section.
///
/// Public so a screen that feeds the slider its own list — the parcel home does —
/// can show it while that list is still in flight, instead of hand-rolling a
/// block. Those hand-rolled ones drifted: the parcel home drew a full-bleed
/// `radiusDefault` rectangle at a hardcoded 150 (395 on desktop) with no dots,
/// against a slider that is [_sliderHeight] tall, inset from the left, and
/// `radiusLarge`.
///
/// Mirrors both sliders exactly: the slide at the carousel's own height with the
/// same left margin and corner radius, then the gap and the dot row they both
/// close with.
class BannerSliderShimmer extends StatelessWidget {
  const BannerSliderShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    // Keyed to the theme rather than a fixed `Colors.grey[300]`, which read as a
    // bright slab in dark mode.
    final Color bar = Theme.of(context).disabledColor.withValues(alpha: 0.15);

    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [

      Shimmer(
        duration: const Duration(seconds: 2),
        child: Container(
          // `viewportFraction: 0.8` with `padEnds: false` leaves the slide flush
          // left and the next one peeking in; the right inset stands in for that.
          margin: const EdgeInsets.only(left: Dimensions.paddingSizeDefault, right: 60),
          height: _sliderHeight(context),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            color: bar,
          ),
        ),
      ),
      const SizedBox(height: Dimensions.paddingSizeSmall),

      // The dot strip both sliders close with — same 10px box, same dot sizes.
      SizedBox(
        height: 10,
        child: Shimmer(
          duration: const Duration(seconds: 2),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            for (int i = 0; i < 3; i++) Container(
              margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall / 2),
              height: i == 0 ? 8 : 5,
              width: i == 0 ? 8 : 5,
              decoration: BoxDecoration(color: bar, borderRadius: BorderRadius.circular(99)),
            ),
          ]),
        ),
      ),
    ]);
  }
}
