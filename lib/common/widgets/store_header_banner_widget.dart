import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_banner_model.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:url_launcher/url_launcher_string.dart';

class StoreHeaderBanner extends StatefulWidget {
  final List<StoreBannerModel> banners;
  final double height;

  const StoreHeaderBanner({super.key, required this.banners, required this.height});

  @override
  State<StoreHeaderBanner> createState() => _StoreHeaderBannerState();
}

class _StoreHeaderBannerState extends State<StoreHeaderBanner> {
  final CarouselSliderController _carouselController = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    final List<StoreBannerModel> banners = widget.banners;
    return CarouselSlider.builder(
      carouselController: _carouselController,
      itemCount: banners.length,
      itemBuilder: (context, index, realIndex) => InkWell(
        onTap: () => _handleBannerTap(banners[index]),
        child: SizedBox.expand(
          child: CustomImage(image: banners[index].imageFullUrl ?? '', fit: BoxFit.cover),
        ),
      ),
      options: CarouselOptions(
        height: widget.height,
        viewportFraction: 1.0,
        initialPage: 0,
        enableInfiniteScroll: banners.length > 1,
        enlargeCenterPage: false,
        autoPlay: banners.length > 1,
        autoPlayInterval: const Duration(seconds: 5),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        autoPlayCurve: Curves.easeInOut,
      ),
    );
  }

  void _handleBannerTap(StoreBannerModel banner) {
    switch (banner.type) {
      case 'item':
        final bool isFood = Get.find<SplashController>().module?.moduleType == AppConstants.food;
        Get.toNamed(RouteHelper.getItemDetailsRoute(
          banner.data, isFood, banner.title ?? '',
          slug: 'item_${banner.data}',
        ));
        break;
      case 'store':
        Get.toNamed(RouteHelper.getStoreRoute(
          id: banner.data, page: 'banner',
          slug: 'store_${banner.data}',
        ));
        break;
      default:
        final String? link = banner.defaultLink;
        if (link != null && link.isNotEmpty) {
          launchUrlString(link, mode: LaunchMode.externalApplication);
        }
    }
  }
}
