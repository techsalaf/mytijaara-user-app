import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/banner/domain/models/promotional_banner_model.dart';
import 'package:sixam_mart/helper/image_cache_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';

/// Promotional (bottom-section) banner shown on the module home pages.
///
/// The artwork is authored at a 4:1 ratio, so the banner sizes itself from the
/// available width instead of a fixed height — it stays correct on any screen
/// size. [PromotionalBannerSliver] is the variant to use inside the module
/// screens, which build their content from slivers.
class PromotionalBannerView extends StatelessWidget {
  const PromotionalBannerView({super.key});

  /// width : height of the banner artwork.
  static const double bannerAspectRatio = 4 / 1;

  /// Whether this widget will draw anything for the banner the controller
  /// currently holds — true while it is still loading (the shimmer occupies the
  /// same box), false once the response came back without artwork.
  ///
  /// Screens that own spacing around the banner check this so their gap
  /// collapses with it instead of leaving a stray band behind.
  static bool hasContent(BannerController bannerController) {
    final PromotionalBanner? promotionalBanner = bannerController.promotionalBanner;
    if (promotionalBanner == null) {
      return true;
    }
    final String? imageUrl = promotionalBanner.bottomSectionBannerFullUrl;
    return imageUrl != null && imageUrl.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BannerController>(builder: (bannerController) {
      final promotionalBanner = bannerController.promotionalBanner;
      if (promotionalBanner == null) {
        return const PromotionalBannerShimmerView();
      }

      final String? imageUrl = promotionalBanner.bottomSectionBannerFullUrl;
      if (imageUrl == null || imageUrl.isEmpty) {
        return const SizedBox();
      }

      final double bannerWidth = MediaQuery.sizeOf(context).width - (Dimensions.paddingSizeDefault * 2);
      final int? decodeWidth = ImageCacheHelper.pixels(context, bannerWidth);
      final int? decodeHeight = ImageCacheHelper.pixels(context, bannerWidth / bannerAspectRatio);

      return Container(
        width: double.infinity,
        color: Theme.of(context).cardColor,
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault, horizontal: Dimensions.paddingSizeDefault),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
          child: AspectRatio(
            aspectRatio: bannerAspectRatio,
            child: CustomImage(image: imageUrl, fit: BoxFit.cover, width: double.infinity,
              cacheWidth: decodeWidth, cacheHeight: decodeHeight,
            ),
          ),
        ),
      );
    });
  }
}

/// Sliver form of [PromotionalBannerView]. The module home pages compose their
/// content out of slivers, so the banner has to be adapted before it can be
/// placed in those lists.
class PromotionalBannerSliver extends StatelessWidget {
  const PromotionalBannerSliver({super.key});

  @override
  Widget build(BuildContext context) {
    return const SliverToBoxAdapter(child: PromotionalBannerView());
  }
}

class PromotionalBannerShimmerView extends StatelessWidget {
  const PromotionalBannerShimmerView({super.key});

  @override
  Widget build(BuildContext context) {
    // Mirrors the loaded banner's padding + ratio so nothing shifts on load.
    return Container(
      width: double.infinity,
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault, horizontal: Dimensions.paddingSizeDefault),
      child: Shimmer(
        duration: const Duration(seconds: 2),
        enabled: true,
        child: AspectRatio(
          aspectRatio: PromotionalBannerView.bannerAspectRatio,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
            ),
          ),
        ),
      ),
    );
  }
}
