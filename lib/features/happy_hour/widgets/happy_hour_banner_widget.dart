import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/happy_hour/controllers/happy_hour_controller.dart';
import 'package:sixam_mart/features/happy_hour/screens/happy_hour_screen.dart';
import 'package:sixam_mart/features/happy_hour/widgets/happy_hour_palette.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class HappyHourBannerWidget extends StatefulWidget {
  final double bottomTuck;

  const HappyHourBannerWidget({super.key, this.bottomTuck = 0});

  @override
  State<HappyHourBannerWidget> createState() => _HappyHourBannerWidgetState();
}

class _HappyHourBannerWidgetState extends State<HappyHourBannerWidget> {
  final GlobalKey _bannerKey = GlobalKey();

  void _reportHeight(bool visible) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(!mounted) {
        return;
      }
      final HappyHourController happyHourController = Get.find<HappyHourController>();
      if(!visible) {
        happyHourController.reportHeight(0);
        return;
      }
      final double? height = (_bannerKey.currentContext?.findRenderObject() as RenderBox?)?.size.height;
      if(height != null) {
        happyHourController.reportHeight(height);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HappyHourController>(builder: (happyHourController) {
      final bool visible = happyHourController.showHomeBanner;
      _reportHeight(visible);

      if(!visible) {
        return const SizedBox.shrink();
      }

      final String offLabel = 'percentage_off'.tr.replaceAll('{percentage}', happyHourController.discountLabel);
      final String? iconUrl = happyHourController.happyHour?.iconFullUrl;

      return Container(
        key: _bannerKey,
        decoration: BoxDecoration(
          color: HappyHourPalette.card(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusLarge)),
          boxShadow: [BoxShadow(
            color: Theme.of(context).hintColor.withValues(alpha: 0.20),
            blurRadius: 8, spreadRadius: 1, offset: const Offset(0, 3),
          )],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [

          InkWell(
            onTap: () => HappyHourScreen.show(context),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall,
                Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault + widget.bottomTuck,
              ),
              child: Row(children: [

                ClipRRect(
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  child: (iconUrl != null && iconUrl.isNotEmpty)
                    ? CustomImage(image: iconUrl, height: 40, width: 40, fit: BoxFit.cover)
                    : Image.asset(Images.happyHours, height: 40, width: 40, fit: BoxFit.cover),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),

                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    '$offLabel ${'happy_hour'.tr}', maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: robotoBold.copyWith(color: HappyHourPalette.accent, fontSize: Dimensions.fontSizeLarge),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'grab_best_price_for_your_order'.tr, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: robotoRegular.copyWith(color: HappyHourPalette.accent, fontSize: Dimensions.fontSizeSmall),
                  ),
                ])),
                const SizedBox(width: Dimensions.paddingSizeSmall),

                HappyHourCountdownChip(fontSize: Dimensions.fontSizeDefault),
                const SizedBox(width: Dimensions.paddingSizeExtremeLarge),
              ]),
            ),
          ),
          PositionedDirectional(
            top: 0, end: 0,
            child: InkWell(
              onTap: happyHourController.dismiss,
              borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                child: Icon(Icons.close, size: 22, color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.5)),
              ),
            ),
          ),
        ]),
      );
    });
  }
}

class HappyHourCountdownChip extends StatelessWidget {
  final Color? background;
  final Color? textColor;

  final double? fontSize;

  const HappyHourCountdownChip({super.key, this.background, this.textColor, this.fontSize});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HappyHourController>(id: HappyHourController.timerBuilderId, builder: (happyHourController) {
      return Container(
        width: 60,
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall, vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background ?? HappyHourPalette.accent,
          borderRadius: BorderRadius.circular(Dimensions.radiusMedium),
        ),
        child: Center(
          child: Text(
            happyHourController.formattedRemaining.split(':').join(' : '), textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            style: robotoBold.copyWith(color: textColor ?? Colors.white, fontSize: fontSize ?? Dimensions.fontSizeDefault),
          ),
        ),
      );
    });
  }
}
