import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_parcel_measurement_model.dart';
import 'package:sixam_mart/features/order/widgets/collapsible_header.dart';
import 'package:sixam_mart/helper/image_cache_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class ParcelTypeSection extends StatefulWidget {
  final OrderModel order;
  const ParcelTypeSection({super.key, required this.order});

  @override
  State<ParcelTypeSection> createState() => _ParcelTypeSectionState();
}

class _ParcelTypeSectionState extends State<ParcelTypeSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final category = widget.order.parcelCategory;
    final String description = category?.description ?? '';

    final OrderParcelMeasurement? weight = widget.order.parcelWeight;
    final OrderParcelMeasurement? dimension = widget.order.parcelDimension;
    final bool showWeight = weight?.hasContent ?? false;
    final bool showDimension = dimension?.hasContent ?? false;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      CollapsibleSectionHeader(
        title: 'parcel_type'.tr,
        expanded: _expanded,
        onTap: () => setState(() => _expanded = !_expanded),
      ),

      AnimatedCrossFade(
        firstChild: const SizedBox(width: double.infinity),
        secondChild: Padding(
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                child: CustomImage(
                  image: category?.imageFullUrl ?? '',
                  height: 40, width: 40, fit: BoxFit.cover,
                  cacheWidth: ImageCacheHelper.pixels(context, 40),
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),

              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  category?.name ?? '',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                ),

                if (showWeight || showDimension) ...[
                  const SizedBox(height: 2),
                  RichText(
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                      children: [
                        if (showDimension)
                          TextSpan(text: dimension!.displayText),
                        if (showDimension && showWeight)
                          TextSpan(text: '${showDimension ? ',' : ''} ${weight!.displayText}')
                        else if (showWeight)
                          TextSpan(text: weight!.displayText),
                      ],
                    ),
                  ),
                ] else if (description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                  ),
                ],
              ])),
            ]),

            // if (showWeight || showDimension) ...[
            //   const SizedBox(height: Dimensions.paddingSizeDefault),
            //   Divider(height: 1, thickness: 1, color: Theme.of(context).disabledColor.withValues(alpha: 0.1)),
            //   const SizedBox(height: Dimensions.paddingSizeDefault),
            // ],

            // if (showWeight)
            //   _MeasurementRow(label: 'item_weight'.tr, value: weight!.displayText),
            //
            // if (showWeight && showDimension)
            //   const SizedBox(height: Dimensions.paddingSizeSmall),
            //
            // if (showDimension)
            //   _MeasurementRow(label: 'item_dimension'.tr, value: dimension!.displayText),
          ]),
        ),
        crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 200),
      ),
    ]);
  }
}

class _MeasurementRow extends StatelessWidget {
  final String label;
  final String value;

  const _MeasurementRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        label,
        style: robotoRegular.copyWith(
          fontSize: Dimensions.fontSizeSmall,
          color: Theme.of(context).disabledColor,
        ),
      ),
      const SizedBox(width: Dimensions.paddingSizeSmall),

      Expanded(child: Text(
        value,
        textAlign: TextAlign.end,
        style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
      )),
    ]);
  }
}
