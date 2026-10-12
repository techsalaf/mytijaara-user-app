import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/bundle/controllers/bundle_controller.dart';
import 'package:sixam_mart/features/bundle/domain/models/bundle_model.dart';
import 'package:sixam_mart/features/bundle/widgets/bundle_card_widget.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// "Bundle Items" — the home-screen strip, fed by `GET /bundle/home`.
///
/// The section removes itself when the module has no bundles, rather than
/// leaving an empty heading: with the feature switched off the endpoint returns
/// an empty list, so that is the same case as a module with none.
class BundleSectionWidget extends StatelessWidget {
  const BundleSectionWidget({super.key});

  static const double _cardWidth = 168;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BundleController>(builder: (bundleController) {
      final List<Bundle>? bundles = bundleController.homeBundles;

      /// Null while the first fetch is in flight — nothing is drawn until the
      /// answer is known, so the strip never flashes in and out.
      if(bundles == null || bundles.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: Dimensions.paddingSizeLarge),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: Text('bundle_items'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        SizedBox(
          /// Asked of the card rather than guessed: every row inside it is a
          /// fixed height, so this is exact at any text scale.
          height: BundleCardWidget.heightOf(context, width: _cardWidth),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            itemCount: bundles.length,
            separatorBuilder: (context, index) => const SizedBox(width: Dimensions.paddingSizeDefault),
            itemBuilder: (context, index) => BundleCardWidget(bundle: bundles[index], width: _cardWidth),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),

      ]);
    });
  }
}
