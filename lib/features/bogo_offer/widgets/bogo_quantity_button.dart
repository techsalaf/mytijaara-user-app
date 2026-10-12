import 'package:flutter/material.dart';
import 'package:sixam_mart/util/dimensions.dart';

/// Square step control used beside a bundle count, in the offer sheet and the cart's
/// bundle sheet alike.
class BogoQuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const BogoQuantityButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        height: 36, width: 36,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        child: Icon(
          icon, size: 18,
          color: onTap == null ? Theme.of(context).disabledColor : Theme.of(context).textTheme.bodyLarge!.color,
        ),
      ),
    );
  }
}
