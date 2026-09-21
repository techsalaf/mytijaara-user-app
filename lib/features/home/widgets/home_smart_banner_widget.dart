import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/smart_banner/controllers/smart_banner_controller.dart';
import 'package:sixam_mart/features/smart_banner/domain/models/smart_banner_model.dart';
import 'package:sixam_mart/features/smart_banner/helper/smart_banner_redirect_handler.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class HomeSmartBannerWidget extends StatelessWidget {
  const HomeSmartBannerWidget({super.key});

  static int _positionOrder(String? position) => position == 'top' ? 0 : 1;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SmartBannerController>(builder: (controller) {
      final List<SmartBanner>? allBanners = controller.smartBanners;

      if (allBanners == null) {
        return const Padding(
          padding: EdgeInsets.only(
            left: Dimensions.paddingSizeSmall,
            right: Dimensions.paddingSizeSmall,
            top: Dimensions.paddingSizeLarge,
          ),
          child: _PromoBannerShimmer(),
        );
      }

      if (allBanners.isEmpty) {
        return const SizedBox.shrink();
      }

      final List<SmartBanner> banners = List<SmartBanner>.from(allBanners)
        ..sort((a, b) => _positionOrder(a.position).compareTo(_positionOrder(b.position)));

      return Padding(
        padding: const EdgeInsets.only(
          left: Dimensions.paddingSizeDefault,
          right: Dimensions.paddingSizeDefault,
          top: Dimensions.paddingSizeExtraLarge,
        ),
        child: Column(
          children: [
            for (int i = 0; i < banners.length; i++) ...[
              _PromoBannerCard(
                banner: banners[i],
                onTap: () => SmartBannerRedirectHandler.handle(banners[i]),
              ),
              if (i < banners.length - 1) const SizedBox(height: Dimensions.paddingSizeDefault),
            ],
          ],
        ),
      );
    });
  }
}

class _PromoBannerCard extends StatelessWidget {
  final SmartBanner banner;
  final VoidCallback onTap;

  const _PromoBannerCard({required this.banner, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final String title = (banner.title ?? '').trim();
    final String subtitle = (banner.subtitle ?? '').trim();
    final String imageUrl = banner.imageFullUrl ?? '';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeDefault,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          // boxShadow: customBoxShadow,
        ),
        child: _buildTextRow(context, title, subtitle, imageUrl),
      ),
    );
  }

  Widget _buildTextRow(BuildContext context, String title, String subtitle, String imageUrl) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: robotoBold.copyWith(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: Dimensions.fontSizeDefault,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              Text(
                subtitle,
                style: robotoRegular.copyWith(
                  color: Theme.of(context).disabledColor,
                  fontSize: Dimensions.fontSizeSmall,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),

        ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          child: CustomImage(image: imageUrl, height: 32, width: 32, fit: BoxFit.cover),
        ),
      ],
    );
  }
}

class _PromoBannerShimmer extends StatelessWidget {
  const _PromoBannerShimmer();

  @override
  Widget build(BuildContext context) {
    final Color baseColor = Theme.of(context).disabledColor.withValues(alpha: 0.15);
    return Shimmer(
      duration: const Duration(seconds: 2),
      child: Column(
        children: [
          _shimmerCard(context, baseColor),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          _shimmerCard(context, baseColor),
        ],
      ),
    );
  }

  Widget _shimmerCard(BuildContext context, Color color) {
    return Container(
      width: double.infinity,
      height: 70,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
    );
  }
}
