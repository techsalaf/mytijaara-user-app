import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

/// Flash-sale background graphic (with a dark scrim in dark mode) used behind the
/// flash sale header. Shared between the shop home header and the flash sale details screen.
class FlashSaleHeaderBackground extends StatelessWidget {
  final Widget child;
  const FlashSaleHeaderBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(children: [
      Positioned.fill(child: Image.asset(Images.flashSellBg, fit: BoxFit.cover)),
      // The asset is a bright/light graphic. In dark mode lay a dark scrim over it
      // so it blends with the dark UI instead of glaring; content stays on top.
      if(isDark)
        Positioned.fill(child: Container(color: Theme.of(context).cardColor.withValues(alpha: 0.75))),
      child,
    ]);
  }
}

/// Flash-sale header row: icon + title/subtitle + countdown boxes.
/// Pass [onTap] to make the row tappable (e.g. "see all" on the home header);
/// leave it null on screens that are already the flash sale destination.
class FlashSaleHeaderBanner extends StatelessWidget {
  final Duration? duration;
  final VoidCallback? onTap;
  const FlashSaleHeaderBanner({super.key, this.duration, this.onTap});

  @override
  Widget build(BuildContext context) {
    final Duration d = duration ?? Duration.zero;
    final int days = d.inDays;
    final int hours = d.inHours - days * 24;
    final int minutes = d.inMinutes - (24 * days * 60) - (hours * 60);
    final int seconds = d.inSeconds - (24 * days * 60 * 60) - (hours * 60 * 60) - (minutes * 60);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: CustomInkWell(
        onTap: onTap,
        radius: Dimensions.radiusSmall,
        child: SizedBox(
          height: 50,
          child: Row(children: [
            Image.asset(Images.flashSellIcon, height: 42, width: 42),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'flash_sale'.tr,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: robotoBold.copyWith(color: Colors.blueAccent, fontSize: Dimensions.fontSizeLarge),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'grab_the_offer_before_end_the_time'.tr,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: robotoRegular.copyWith(color: Colors.blueAccent, fontSize: Dimensions.fontSizeSmall),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Row(children: [
              _FlashSaleTimeBox(timeCount: days, timeUnit: 'days'.tr),
              const SizedBox(width: 6),
              _FlashSaleTimeBox(timeCount: hours, timeUnit: 'hours'.tr),
              const SizedBox(width: 6),
              _FlashSaleTimeBox(timeCount: minutes, timeUnit: 'mins'.tr),
              const SizedBox(width: 6),
              _FlashSaleTimeBox(timeCount: seconds, timeUnit: 'sec'.tr),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _FlashSaleTimeBox extends StatelessWidget {
  final int timeCount;
  final String timeUnit;
  const _FlashSaleTimeBox({required this.timeCount, required this.timeUnit});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40, width: 38,
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(
          timeCount > 9 ? timeCount.toString() : '0${timeCount.toString()}',
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeDefault),
        ),
        Text(
          timeUnit,
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: robotoRegular.copyWith(color: Colors.white, fontSize: 8),
        ),
      ]),
    );
  }
}
