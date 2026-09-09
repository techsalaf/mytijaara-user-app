import 'package:flutter/material.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class ParcelCategoryCardWidget extends StatelessWidget {
  final String image;
  final String itemName;
  final String description;
  final int colorIndex;
  final Function? onTap;
  const ParcelCategoryCardWidget({
    super.key,
    required this.image,
    required this.itemName,
    required this.description,
    required this.colorIndex,
    this.onTap,
  });

  static const List<Color> _categoryColors = [
    Color(0xFFFCEFC9),
    Color(0xFFE5E9F5),
    Color(0xFFD9EAD8),
    Color(0xFFFAD9DD),
  ];

  static const Color _extraColor = Color(0xFFEEEEEE);

  Color _backgroundFor(int index) {
    if (index < _categoryColors.length) {
      return _categoryColors[index];
    }
    return _extraColor;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _backgroundFor(colorIndex),
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      ),
      child: CustomInkWell(
        onTap: onTap,
        radius: Dimensions.radiusLarge,
        padding: const EdgeInsets.symmetric(
          vertical: Dimensions.paddingSizeSmall,
          horizontal: Dimensions.paddingSizeSmall,
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  itemName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),

                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),

          ClipRRect(borderRadius: BorderRadius.circular(Dimensions.radiusSmall), child: CustomImage(image: image, width: 40, height: 40,)),

        ]),
      ),
    );
  }
}
