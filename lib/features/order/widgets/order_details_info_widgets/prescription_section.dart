import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/order/widgets/collapsible_header.dart';
import 'package:sixam_mart/helper/image_cache_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';


class PrescriptionSection extends StatefulWidget {
  final OrderModel order;

  const PrescriptionSection({super.key, required this.order});

  static bool hasPrescription(OrderModel order) => _imagesOf(order).isNotEmpty;

  static List<String> _imagesOf(OrderModel order) {
    return (order.orderAttachmentFullUrl ?? const <String?>[])
        .whereType<String>()
        .where((String url) => url.isNotEmpty)
        .toList();
  }

  @override
  State<PrescriptionSection> createState() => _PrescriptionSectionState();
}

class _PrescriptionSectionState extends State<PrescriptionSection> {
  static const double _thumbSize = 88;

  bool _expanded = true;

  void _preview(String url) {
    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusLarge)),
        child: Stack(children: [

          ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            child: GetPlatform.isWeb ? CustomImage(image: url) : PhotoView(
              tightMode: true,
              imageProvider: NetworkImage(url),
              heroAttributes: PhotoViewHeroAttributes(tag: url),
            ),
          ),

          PositionedDirectional(
            top: 0, end: 0,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.cancel, color: Colors.red),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> images = PrescriptionSection._imagesOf(widget.order);
    if(images.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

      CollapsibleSectionHeader(
        title: '${'prescription'.tr} (${images.length})',
        expanded: _expanded,
        onTap: () => setState(() => _expanded = !_expanded),
      ),

      AnimatedCrossFade(
        firstChild: const SizedBox(width: double.infinity),
        secondChild: Padding(
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeLarge),
          child: Wrap(
            spacing: Dimensions.paddingSizeSmall,
            runSpacing: Dimensions.paddingSizeSmall,
            children: [
              for(final String url in images) InkWell(
                onTap: () => _preview(url),
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  child: CustomImage(
                    image: url, height: _thumbSize, width: _thumbSize, fit: BoxFit.cover,
                    cacheWidth: ImageCacheHelper.pixels(context, _thumbSize),
                  ),
                ),
              ),
            ],
          ),
        ),
        crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 200),
      ),
    ]);
  }
}

// SUMMARY
// Collapsible prescription section for order details. Shows the prescription images the customer
// uploaded with the order and opens a zoomable preview when one is tapped.
