import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/happy_hour/controllers/happy_hour_controller.dart';
import 'package:sixam_mart/features/happy_hour/domain/models/happy_hour_model.dart';
import 'package:sixam_mart/features/happy_hour/widgets/happy_hour_palette.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class HappyHourPromoBannerCardWidget extends StatelessWidget {
  const HappyHourPromoBannerCardWidget({super.key});

  static const double _badgeSize = 56;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HappyHourController>(builder: (happyHourController) {
      final HappyHourModel? happyHour = happyHourController.happyHour;
      if(happyHour == null) {
        return const SizedBox.shrink();
      }

      final String title =  'happy_hours_offer_title'.tr.replaceAll('{percentage}', happyHourController.discountLabel);
      final String description = (happyHour.shortDescription?.isNotEmpty ?? false)
          ? happyHour.shortDescription!
          : 'grab_best_price_for_your_order'.tr;
      final String? iconUrl = happyHour.iconFullUrl;

      // Bottom-aligned so the badge sits beside the countdown however many lines the
      // server's blurb runs to.
      return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [

        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          Text(title, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeOverLarge)),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

          Text(
            description,
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),

          const HappyHourCountdownRow(),
        ])),
        const SizedBox(width: Dimensions.paddingSizeDefault),

        ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          child: (iconUrl != null && iconUrl.isNotEmpty)
            ? CustomImage(image: iconUrl, height: _badgeSize, width: _badgeSize, fit: BoxFit.cover)
            : Image.asset(Images.happyHours, height: _badgeSize, width: _badgeSize, fit: BoxFit.cover),
        ),
      ]);
    });
  }
}

/// `22 min : 18 sec` — the expanded countdown, split so each unit carries its own
/// label. Bound to the controller's tick id so only this row rebuilds each second.
class HappyHourCountdownRow extends StatelessWidget {
  const HappyHourCountdownRow({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HappyHourController>(id: HappyHourController.timerBuilderId, builder: (happyHourController) {
      final Duration remaining = happyHourController.remaining;

      // Flexible so a long translated unit costs the boxes width rather than overflowing
      // the card they sit in.
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Flexible(child: _TimeBox(value: remaining.inMinutes, label: 'min'.tr)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
          child: Text(':', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).disabledColor)),
        ),
        Flexible(child: _TimeBox(value: remaining.inSeconds % 60, label: 'sec'.tr)),
      ]);
    });
  }
}

class _TimeBox extends StatelessWidget {
  final int value;
  final String label;

  static const double _minWidth = 58;

  const _TimeBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _minWidth,
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
      decoration: BoxDecoration(color: HappyHourPalette.timer, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
      child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(value.toString().padLeft(2, '0'), style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Colors.white)),
        const SizedBox(width: 3),
        Flexible(child: Text(
          label, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Colors.white),
        )),
      ]),
    );
  }
}

// SUMMARY
// The happy hour card that heads the happy hour screen. Shows the offer's title, the
// server's blurb and its icon, with a live minutes-and-seconds countdown beside them that
// reticks every second without rebuilding the rest of the card.
