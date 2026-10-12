import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/bundle/controllers/bundle_controller.dart';
import 'package:sixam_mart/features/bundle/domain/models/bundle_model.dart';
import 'package:sixam_mart/features/bundle/widgets/bundle_details_bottom_sheet.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// "Bundle Offer" — one store's own bundles, on its details page.
///
/// Rendered as rows rather than the home strip's cards: the store is already
/// known here, so the card's store line would be noise and the extra width is
/// better spent on the name.
class BundleStoreSectionWidget extends StatelessWidget {
  final int storeId;
  const BundleStoreSectionWidget({super.key, required this.storeId});

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
          const SizedBox(height: Dimensions.paddingSizeLarge),

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
            separatorBuilder: (context, index) => const Divider(height: Dimensions.paddingSizeExtraLarge),
            itemBuilder: (context, index) => _BundleRow(bundle: bundles[index]),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
        ]),
      );
    });
  }
}

class _BundleRow extends StatelessWidget {
  final Bundle bundle;
  const _BundleRow({required this.bundle});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Opacity(
      opacity: bundle.isAvailable ? 1 : 0.5,
      child: InkWell(
        onTap: () => BundleDetailsBottomSheet.show(context, bundleId: bundle.id, storeId: bundle.storeId),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [

            Text(
              bundle.name ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
            ),

            if((bundle.description ?? '').isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                bundle.description!, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: theme.hintColor),
              ),
            ],
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),

            Row(children: [
              Text(
                PriceConverter.convertPrice(bundle.finalPrice),
                textDirection: TextDirection.ltr,
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
              ),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),

              if(bundle.hasSaving)
                Flexible(child: Text(
                  PriceConverter.convertPrice(bundle.basePrice),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.ltr,
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall, color: theme.hintColor,
                    decoration: TextDecoration.lineThrough, decorationColor: theme.hintColor,
                  ),
                )),
            ]),

            if(bundle.discountPercentage > 0) ...[
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                ),
                child: Text(
                  bundle.discountLabel,
                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Colors.white),
                ),
              ),
            ],

            if(!bundle.isAvailable && (bundle.unavailableReason ?? '').isNotEmpty) ...[
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              Text(
                bundle.unavailableReason!, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: theme.colorScheme.error),
              ),
            ],
          ])),
          const SizedBox(width: Dimensions.paddingSizeDefault),

          ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            child: CustomImage(image: bundle.imageFullUrl ?? '', height: 70, width: 90, fit: BoxFit.cover),
          ),
        ]),
      ),
    );
  }
}
