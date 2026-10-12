import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/avg_review_widget.dart';
import 'package:sixam_mart/features/bundle/controllers/bundle_controller.dart';
import 'package:sixam_mart/features/bundle/domain/models/bundle_model.dart';
import 'package:sixam_mart/features/bundle/widgets/bundle_card_widget.dart';
import 'package:sixam_mart/features/bundle/widgets/bundle_details_bottom_sheet.dart';
import 'package:sixam_mart/features/bundle/widgets/bundle_thumbnail_grid_widget.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// The store details screen's "Bundle Item" tab content — this store's own
/// bundles, one full-width row per bundle. Same data as [BundleStoreSectionWidget]
/// (the always-visible desktop section), but styled to match the store's
/// regular item rows rather than that widget's compact layout.
class BundleItemsTabSection extends StatelessWidget {
  final int storeId;
  const BundleItemsTabSection({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BundleController>(builder: (bundleController) {
      final List<Bundle>? bundles = bundleController.storeBundlesOf(storeId);

      if(bundles == null || bundles.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        width: double.infinity,
        color: Theme.of(context).cardColor,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 26),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: Text('bundle_offer'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            itemCount: bundles.length,
            separatorBuilder: (context, index) => Divider(height: Dimensions.paddingSizeExtraLarge, color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
            itemBuilder: (context, index) => _BundleItemListTile(bundle: bundles[index]),
          ),
        ]),
      );
    });
  }
}

class _BundleItemListTile extends StatelessWidget {
  final Bundle bundle;
  const _BundleItemListTile({required this.bundle});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    /// TODO: the store-bundles endpoint sends `items: null` (same gap noted in
    /// BundleCardWidget), so there are no per-member pictures to draw here —
    /// falls back to the bundle's own single thumbnail until the API includes one.
    final List<String> thumbnails = bundle.items != null
        ? bundle.itemThumbnails
        : <String>[if((bundle.imageFullUrl ?? '').isNotEmpty) bundle.imageFullUrl!];

    return InkWell(
      onTap: () => BundleDetailsBottomSheet.show(context, bundleId: bundle.id, storeId: bundle.storeId),
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(
            bundle.name ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

          /// TODO: dummy — `Bundle` carries no rating/review fields at all yet
          /// (verified against bundle_model.dart), so this always renders
          /// nothing (AvgReviewWidget hides itself at avgRating 0). Wire real
          /// values in once the bundle API exposes them.
          const AvgReviewWidget(avgRating: 0, ratingCount: 0),

          Row(children: [
            Text(
              PriceConverter.convertPrice(bundle.finalPrice),
              textDirection: TextDirection.ltr,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
            ),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),

            if(bundle.hasSaving)
              Flexible(child: Text(
                PriceConverter.convertPrice(bundle.basePrice),
                maxLines: 1, overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.ltr,
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeDefault, color: theme.hintColor,
                  decoration: TextDecoration.lineThrough, decorationColor: theme.hintColor,
                ),
              )),
          ]),

          if(bundle.discountPercentage > 0) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall * 0.6),
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
              ),
              child: Text(
                bundle.discountLabel,
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.white),
              ),
            ),
          ],
        ])),
        const SizedBox(width: Dimensions.paddingSizeDefault),

        BundleThumbnailGridWidget(
          thumbnails: thumbnails,
          totalCount: bundle.memberCount,
          size: 132,
          action: BundleAddButton(bundle: bundle, size: 32),
        ),
      ]),
    );
  }
}
