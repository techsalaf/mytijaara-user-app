import 'package:flutter/material.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/order/domain/models/monthly_order_model.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class MonthlyItemTile extends StatelessWidget {
  final MonthlyOrderItemPreview item;
  final double imageHeight;
  const MonthlyItemTile({super.key, required this.item, this.imageHeight = 100});

  @override
  Widget build(BuildContext context) {
    final bool hasOldPrice = (item.oldPrice ?? 0) > (item.price ?? 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: imageHeight,
          decoration: BoxDecoration(
            color: Theme.of(context).disabledColor.withAlpha(20),
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            child: CustomImage(image: item.imageFullUrl ?? '', fit: BoxFit.cover, width: double.infinity),
          ),
        ),
        const SizedBox(height: 4),

        Text(
          item.name ?? '',
          maxLines: 2, overflow: TextOverflow.ellipsis,
          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
        ),

        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            PriceConverter.convertPrice(item.price ?? 0),
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
          ),

          hasOldPrice ? Text(
            PriceConverter.convertPrice(item.oldPrice ?? 0),
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor,
              decoration: TextDecoration.lineThrough,
            ),
          ) : const SizedBox.shrink(),
        ]),
      ],
    );
  }
}
