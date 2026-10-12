import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/bogo_offer/domain/models/bogo_offer_model.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class BogoOfferItemCard extends StatelessWidget {
  final BogoOfferCardModel offer;
  final int? moduleId;

  const BogoOfferItemCard({super.key, required this.offer, this.moduleId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(RouteHelper.getBogoOfferDetailsRoute(
        (offer.slug != null && offer.slug!.isNotEmpty) ? offer.slug! : '${offer.id}', moduleId: moduleId,
      )),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault+2),
              child: CustomImage(image: offer.imageFullUrl ?? '', height: 120, width: double.infinity, fit: BoxFit.fill),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            Text(offer.title ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),

            if(offer.offerLabel != null && offer.offerLabel!.isNotEmpty) ...[
              Text(offer.offerLabel!.toUpperCase(), style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall, color: Colors.blueAccent)),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            ],

            Text(offer.description ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).disabledColor)),
          ],
        ),
      ),
    );
  }
}
