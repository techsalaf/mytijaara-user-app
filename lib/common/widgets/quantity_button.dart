import 'package:flutter/material.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';

class QuantityButton extends StatelessWidget {
  final bool isIncrement;
  final Function? onTap;
  final bool fromSheet;
  final bool showRemoveIcon;
  final Color? color;

  /// Bare icon with no filled disc, for steppers that sit inside a tinted pill of their
  /// own — the pill is the surface, so a second one per button muddies it.
  final bool flat;

  const QuantityButton({super.key,
    required this.isIncrement, required this.onTap, this.fromSheet = false, this.showRemoveIcon = false,
    this.color, this.flat = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color iconColor = flat
        ? Theme.of(context).textTheme.bodyLarge!.color!
        : showRemoveIcon ? Theme.of(context).colorScheme.error
            : isIncrement ? Theme.of(context).cardColor : Theme.of(context).disabledColor;

    return InkWell(
      onTap: onTap as void Function()?,
      child: Container(
        height: flat ? 28 : fromSheet ? 30 : 25, width: flat ? 28 : fromSheet ? 30 : 25,
        margin: EdgeInsets.symmetric(horizontal: flat ? Dimensions.paddingSizeExtraSmall : Dimensions.paddingSizeSmall),
        decoration: flat ? null : BoxDecoration(
          shape: BoxShape.circle,
          color: showRemoveIcon ? Theme.of(context).colorScheme.error.withValues(alpha: 0.1) : isIncrement ? color ?? Theme.of(context).primaryColor : Theme.of(context).disabledColor.withValues(alpha: 0.2),
        ),
        alignment: Alignment.center,
        child: showRemoveIcon
            ? Image.asset(Images.delete, height: flat ? 18 : 15, color: iconColor)
            : Icon(isIncrement ? Icons.add : Icons.remove, size: flat ? 20 : 15, color: iconColor),
      ),
    );
  }
}