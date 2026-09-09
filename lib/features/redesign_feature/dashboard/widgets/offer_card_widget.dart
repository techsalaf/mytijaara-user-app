import 'package:flutter/material.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class OfferCardWidget extends StatelessWidget {
  final bool isHilight;
  final IconData? iconData;
  final String label;
  const OfferCardWidget({super.key, this.iconData, required this.label, this.isHilight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall, vertical: 2),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.error.withAlpha(isHilight ? 255 : 25), borderRadius: BorderRadius.circular(Dimensions.radiusLarge),),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconData != null) ...[
            Icon(iconData, size: Dimensions.fontSizeSmall, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 5),
          ],

          Text(label, style: robotoSemiBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: isHilight ? Colors.white : Theme.of(context).colorScheme.error),),
        ],
      ),
    );
  }
}
