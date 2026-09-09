import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';

// Loading placeholder for the item bottom sheet. Mirrors the real layout:
// a full-width header image, the product summary (store row, name, rating, price,
// offer badges), a few description lines, and the pinned add-to-cart bottom bar.
class ItemBottomSheetShimmer extends StatelessWidget {
  const ItemBottomSheetShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final double headerHeight = (context.height * 0.30).clamp(240.0, 320.0).toDouble();
    final double topInset = MediaQuery.of(context).padding.top + Dimensions.paddingSizeDefault;
    final Color base = Theme.of(context).disabledColor.withValues(alpha: 0.15);

    Widget box(double width, double height, {double radius = Dimensions.radiusSmall}) => Container(
      width: width, height: height,
      decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(radius)),
    );

    Widget circle(double size, {Color? color}) => Container(
      width: size, height: size,
      decoration: BoxDecoration(color: color ?? base, shape: BoxShape.circle),
    );

    return ClipRRect(
      borderRadius: ResponsiveHelper.isDesktop(context)
          ? const BorderRadius.all(Radius.circular(Dimensions.radiusDefault))
          : const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge)),
      child: Shimmer(
        duration: const Duration(seconds: 2),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Header media (full width) with the close / favourite buttons ──
          Stack(children: [
            Container(width: double.infinity, height: headerHeight, color: base),
            Positioned(top: topInset, left: Dimensions.paddingSizeDefault, child: circle(40, color: Theme.of(context).cardColor)),
            Positioned(top: topInset, right: Dimensions.paddingSizeDefault, child: circle(40, color: Theme.of(context).cardColor)),
          ]),

          // ── Product summary + details ──
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Store row: avatar + name
              Row(children: [
                circle(18),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                box(120, 12),
              ]),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              // Item name (two lines)
              box(context.width * 0.7, 18),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              box(context.width * 0.45, 18),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              // Rating
              box(150, 12),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              // Price + struck original price
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                box(110, 22),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                box(60, 14),
              ]),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              // Offer badges
              Row(children: [
                box(72, 24, radius: 30),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                box(96, 24, radius: 30),
              ]),
              const SizedBox(height: Dimensions.paddingSizeLarge),

              box(double.infinity, 1),
              const SizedBox(height: Dimensions.paddingSizeLarge),

              // Description heading + lines
              box(120, 14),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              box(double.infinity, 11),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              box(double.infinity, 11),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              box(context.width * 0.6, 11),
            ]),
          ),

          // ── Pinned add-to-cart bar (quantity stepper + button) ──
          Container(
            padding: EdgeInsets.fromLTRB(
              Dimensions.paddingSizeLarge, Dimensions.paddingSizeDefault,
              Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(top: BorderSide(color: Theme.of(context).disabledColor.withValues(alpha: 0.12))),
            ),
            child: Row(children: [
              box(110, 46, radius: Dimensions.radiusDefault),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              Expanded(child: box(double.infinity, 50, radius: Dimensions.radiusDefault)),
            ]),
          ),
        ]),
      ),
    );
  }
}
