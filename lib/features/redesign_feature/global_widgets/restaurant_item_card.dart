import 'package:flutter/material.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/search/domain/models/food_item.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class RestaurantItemCard extends StatelessWidget {
  final FoodItem item;
  final VoidCallback? onTap;
  final double width;

  const RestaurantItemCard({super.key, required this.item, this.onTap, this.width = 100});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap,
      child: SizedBox(width: width,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          // Square image derived from the card width (no fixed height literal).
          Container(height: width, width: width,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).cardColor)),
            child: ClipRRect(borderRadius: BorderRadius.circular(12),
              child: CustomImage(image: item.imageUrl, fit: BoxFit.cover, placeholder: Images.placeholder),
            ),
          ),
          const SizedBox(height: 10),
          Text(item.itemName, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
          ),
          const SizedBox(height: 6),
          Text(_formatPrice(item.price),
            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
          ),
          if (item.originalPrice != null) ...<Widget>[
            Text(_formatPrice(item.originalPrice!),
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor, decoration: TextDecoration.lineThrough, decorationColor: Theme.of(context).disabledColor),
            ),
          ],
        ]),
      ),
    );
  }

  String _formatPrice(double value) => '\$${value.toStringAsFixed(2)}';
}
