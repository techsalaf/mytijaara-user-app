import 'package:flutter/material.dart';
import 'package:sixam_mart/common/models/restaurant_offer_chip.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import '../../../util/dimensions.dart';
import '../../../util/gaps.dart';
import '../../../util/images.dart';
import '../../../util/styles.dart';

class RestaurantSummaryRow extends StatelessWidget {
  final String restaurantName;
  final int? verifiedSeller;
  final String restaurantLogoUrl;
  final String deliveryInfoText;
  final String? badgeText;
  final List<RestaurantOfferChipData> offers;
  final VoidCallback? onArrowTap;
  final VoidCallback? onTap;

  const RestaurantSummaryRow({super.key, required this.restaurantName, required this.restaurantLogoUrl, required this.deliveryInfoText, required this.offers,
    this.badgeText, this.onArrowTap, this.onTap, this.verifiedSeller});

  @override
  Widget build(BuildContext context) {
    return CustomInkWell(
      onTap: onTap,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        GestureDetector(onTap: onTap, child: _RestaurantLogo(restaurantLogoUrl: restaurantLogoUrl, badgeText: badgeText)),
        Gaps.horizontalGapOf(Dimensions.paddingSizeSmall),
        Expanded(child: GestureDetector(
          onTap: onTap,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Row(children: [
              Flexible(
                child: Text(restaurantName, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                ),
              ),
              SizedBox(width: verifiedSeller == 1 ? 5 : 0),
              verifiedSeller == 1 ? Image.asset(Images.verifiedBadge2, width: 16, height: 16) : const SizedBox.shrink(),
            ]),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            Row(children: <Widget>[
              Icon(Icons.access_time_filled_rounded, size: 16, color: Theme.of(context).disabledColor),
              const SizedBox(width: 4),
              Expanded(child: Text(deliveryInfoText, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.6)),
              )),
            ]),
            const SizedBox(height: 6),
            Wrap(spacing: 10, runSpacing: 10, children: offers.map((RestaurantOfferChipData offer) => _RestaurantOfferChip(offer: offer)).toList()),
          ]),
        )),
        const SizedBox(width: Dimensions.paddingSizeSmall),

        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            color: Theme.of(context).cardColor,
          ),
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall, bottom: Dimensions.paddingSizeSmall, left: Dimensions.paddingSizeSmall + 2, right: Dimensions.paddingSizeSmall - 2),
          child: const Icon(Icons.arrow_forward_ios, size: 14),
        ),
      ]),
    );
  }
}

class _RestaurantLogo extends StatelessWidget {
  final String restaurantLogoUrl;
  final String? badgeText;

  const _RestaurantLogo({required this.restaurantLogoUrl, this.badgeText});

  @override
  Widget build(BuildContext context) {
    return Stack(clipBehavior: Clip.none, children: <Widget>[
      ClipOval(
        child: CustomImage(image: restaurantLogoUrl, fit: BoxFit.cover, placeholder: Images.placeholder, height: 60, width: 60),
      ),
      if (badgeText != null && badgeText!.isNotEmpty)Positioned(left: 0, bottom: -2, right: 0,
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(999)),
          child: Center(child: Text(badgeText!, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Colors.white))),
        ),
      ),
    ]);
  }
}

class _RestaurantOfferChip extends StatelessWidget {
  final RestaurantOfferChipData offer;

  const _RestaurantOfferChip({required this.offer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
        if (offer.icon != null) ...<Widget>[
          Icon(offer.icon, size: Dimensions.fontSizeSmall, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 8),
        ],
        Text(
          offer.label,
          style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).colorScheme.error),
        ),
      ]),
    );
  }
}

