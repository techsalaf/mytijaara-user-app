import 'package:flutter/material.dart';
import 'package:sixam_mart/util/dimensions.dart';
class CustomCardCheckout extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const CustomCardCheckout({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      padding: padding ?? const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
      margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: child,
    );
  }
}
