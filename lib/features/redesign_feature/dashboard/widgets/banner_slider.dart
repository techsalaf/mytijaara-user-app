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
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:url_launcher/url_launcher_string.dart';

class BannerSliderWidget extends StatefulWidget {
  final List<ParcelBanner>? bannerList;
  final bool isFeatured;
  const BannerSliderWidget({super.key, this.bannerList, this.isFeatured = false});

  @override
  State<BannerSliderWidget> createState() => _BannerSliderWidgetState();
}

class _BannerSliderWidgetState extends State<BannerSliderWidget> {
  final CarouselSliderController _carouselController = CarouselSliderController();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.bannerList != null) {
      return _ParcelSlider(
        bannerList: widget.bannerList!,
        carouselController: _carouselController,
        currentIndex: _currentIndex,
        onPageChanged: (index) => setState(() => _currentIndex = index),
      );
    }

    return GetBuilder<BannerController>(builder: (bannerController) {
      final List<String?>? images = widget.isFeatured ? bannerController.featuredBannerList : bannerController.bannerImageList;
      final List<dynamic>? data = widget.isFeatured ? bannerController.featuredBannerDataList : bannerController.bannerDataList;

      if (images == null) {
        return const _BannerShimmer();
      }
      if (images.isEmpty) {
        return const SizedBox();
      }
      return _DynamicSlider(
        images: images, data: data, isFeatured: widget.isFeatured, carouselController: _carouselController, currentIndex: _currentIndex,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
          bannerController.setCurrentIndex(index, false);
        },
      );
    });
  }
}

class _ParcelSlider extends StatelessWidget {
  final List<ParcelBanner> bannerList;
  final CarouselSliderController carouselController;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  const _ParcelSlider({
    required this.bannerList, required this.carouselController, required this.currentIndex, required this.onPageChanged,
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
              child: SizedBox.expand(child: CustomImage(image: bannerList[index].imageFullUrl ?? '', fit: BoxFit.fill)),
            ),
          ),
          options: CarouselOptions(
            height: MediaQuery.of(context).size.width * 0.8 * 0.5,
            viewportFraction: 0.8,
            initialPage: 0,
            enableInfiniteScroll: true,
            enlargeCenterPage: false,
            padEnds: false,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.easeInOut,
            onPageChanged: (index, reason) => onPageChanged(index),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        _DotIndicator(count: bannerList.length, currentIndex: currentIndex, carouselController: carouselController),
      ],
    );
  }
}

class _DynamicSlider extends StatelessWidget {
  final List<String?> images;
  final List<dynamic>? data;
  final bool isFeatured;
  final CarouselSliderController carouselController;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  const _DynamicSlider({
    required this.images, required this.data, required this.isFeatured, required this.carouselController, required this.currentIndex,
    required this.onPageChanged,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CarouselSlider.builder(
          carouselController: carouselController,
          itemCount: images.length,
          itemBuilder: (context, index, realIndex) => InkWell(
            onTap: () => _handleTap(context, index),
            child: Container(
              margin: const EdgeInsets.only(left: Dimensions.paddingSizeDefault, bottom: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                child: SizedBox.expand(child: CustomImage(image: images[index] ?? '', fit: BoxFit.cover)),
              ),
            ),
          ),
          options: CarouselOptions(
            height: MediaQuery.of(context).size.width * 0.8 * 0.45,
            viewportFraction: 0.8,
            initialPage: 0,
            enableInfiniteScroll: true,
            enlargeCenterPage: false,
            padEnds: false,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.easeInOut,
            onPageChanged: (index, reason) => onPageChanged(index),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        _DotIndicator(count: images.length, currentIndex: currentIndex, carouselController: carouselController),
      ],
    );
  }
}

class _DotIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;
  final CarouselSliderController carouselController;

  const _DotIndicator({required this.count, required this.currentIndex, required this.carouselController});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (index) {
          final bool isActive = index == currentIndex;
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
                color: isActive ? Theme.of(context).textTheme.bodyLarge!.color : Theme.of(context).hintColor.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _BannerShimmer extends StatelessWidget {
  const _BannerShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      duration: const Duration(seconds: 2),
      child: Container(
        margin: const EdgeInsets.only(left: Dimensions.paddingSizeDefault),
        height: MediaQuery.of(context).size.width * 0.8 * 0.5,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          color: Colors.grey[300],
        ),
      ),
    );
  }
}
