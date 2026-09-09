import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';
import 'package:sixam_mart/features/brands/controllers/brands_controller.dart';
import 'package:sixam_mart/features/brands/domain/models/brands_model.dart';
import 'package:sixam_mart/features/redesign_feature/global_widgets/brand_item_widget.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';

class BrandSectionWidget extends StatelessWidget {
  final String? title;
  final bool showLabel;
  final bool showItemCount;

  const BrandSectionWidget({super.key, this.title, this.showLabel = false, this.showItemCount = false});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BrandsController>(builder: (brandsController) {
      final List<BrandModel>? brands = brandsController.brandList;

      if (brands == null) {
        return _BrandSectionShimmer(title: title, showLabel: showLabel, showItemCount: showItemCount);
      }
      if (brands.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: TitleWidget(title: title ?? 'top_brands'.tr),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          SizedBox(
            height: 80 + (showLabel ? 18 : 0) + (showItemCount ? 18 : 0),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: brands.length,
              separatorBuilder: (BuildContext context, int index) => const SizedBox(width: Dimensions.paddingSizeDefault),
              itemBuilder: (BuildContext context, int index) {
                final BrandModel brand = brands[index];
                return Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? Dimensions.paddingSizeDefault : 0,
                    right: index == brands.length - 1 ? Dimensions.paddingSizeDefault : 0,
                  ),
                  child: InkWell(
                    onTap: brand.id != null && brand.name != null
                        ? () => Get.toNamed(RouteHelper.getBrandsItemScreen(brand.id!, brand.name!, slug: brand.slug ?? brand.name??'brand'))
                        : null,
                    child: BrandItemWidget(
                      image: brand.imageFullUrl,
                      label: brand.name,
                      subTitle: brand.itemsCount! > 0 ? '${'in'.tr} ${brand.itemsCount ?? 0} ${'stores'.tr}' : null,
                      showLabel: showLabel,
                      showSubTitle: showItemCount,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }
}

class _BrandSectionShimmer extends StatelessWidget {
  final String? title;
  final bool showLabel;
  final bool showItemCount;

  const _BrandSectionShimmer({required this.title, required this.showLabel, required this.showItemCount});

  @override
  Widget build(BuildContext context) {
    final Color shimmerColor = Theme.of(context).disabledColor.withAlpha(60);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: TitleWidget(title: title ?? 'top_brands'.tr),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        SizedBox(
          height: 72 + (showLabel ? 18 : 0) + (showItemCount ? 18 : 0),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            separatorBuilder: (context, index) => const SizedBox(width: Dimensions.paddingSizeDefault),
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? Dimensions.paddingSizeDefault : 0,
                right: index == 5 ? Dimensions.paddingSizeDefault : 0,
              ),
              child: Shimmer(
                duration: const Duration(seconds: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 72, width: 72,
                      decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
                    ),
                    if (showLabel) ...[
                      const SizedBox(height: 4),
                      Container(
                        height: 10, width: 50,
                        decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
                      ),
                    ],
                    if (showItemCount) ...[
                      const SizedBox(height: 4),
                      Container(
                        height: 10, width: 40,
                        decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
