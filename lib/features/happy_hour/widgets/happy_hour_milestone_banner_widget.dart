import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/happy_hour/controllers/happy_hour_controller.dart';
import 'package:sixam_mart/features/happy_hour/domain/models/discount_eligibility_model.dart';
import 'package:sixam_mart/features/happy_hour/screens/happy_hour_screen.dart';
import 'package:sixam_mart/features/happy_hour/widgets/happy_hour_banner_widget.dart';
import 'package:sixam_mart/features/happy_hour/widgets/happy_hour_palette.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class HappyHourMilestoneBannerWidget extends StatefulWidget {
  final double subtotal;

  final bool? isHappyHourRunning;
  final double bottomInset;

  final double bottomSpacing;

  final bool roundedBottom;
  final double? borderRadius;
  final VoidCallback? onTap;

  final int? storeId;
  final bool tappable;
  final bool showCountdown;

  const HappyHourMilestoneBannerWidget({super.key,
    required this.subtotal, this.isHappyHourRunning, this.bottomInset = 0, this.bottomSpacing = 0, this.roundedBottom = false,
    this.borderRadius, this.onTap, this.storeId, this.tappable = true, this.showCountdown = true,
  });

  @override
  State<HappyHourMilestoneBannerWidget> createState() => _HappyHourMilestoneBannerWidgetState();
}

class _HappyHourMilestoneBannerWidgetState extends State<HappyHourMilestoneBannerWidget> {
  static const double _iconSize = 18;
  static const double _progressHeight = 3;

  @override
  void initState() {
    super.initState();
    _refreshEligibility();
  }

  @override
  void didUpdateWidget(HappyHourMilestoneBannerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if(oldWidget.storeId != widget.storeId || oldWidget.subtotal != widget.subtotal) {
      _refreshEligibility();
    }
  }

  void _refreshEligibility() {
    if(widget.storeId == null || widget.subtotal <= 0) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(mounted) {
        Get.find<HappyHourController>().getDiscountEligibility(widget.storeId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HappyHourController>(builder: (happyHourController) {
      if(!happyHourController.showStoreBanner(widget.isHappyHourRunning)) {
        return const SizedBox.shrink();
      }
      final DiscountEligibilityModel? eligibility = happyHourController.eligibilityFor(widget.storeId);
      final double remaining = eligibility?.shortfall ?? happyHourController.remainingForDiscount(widget.subtotal);
      final bool qualified = eligibility?.isQualified ?? !happyHourController.hasMinOrderRequirement;
      final bool showProgress = !qualified && remaining > 0;


      final bool hasCartItems = widget.subtotal > 0;

      final double? minPurchase = eligibility?.minPurchase ?? happyHourController.minOrderAmount;
      final double progress = (minPurchase != null && minPurchase > 0)
          ? ((minPurchase - remaining) / minPurchase).clamp(0.0, 1.0)
          : 1;

      final String percentValue = eligibility?.percentage?.toStringAsFixed(0) ?? happyHourController.discountLabel;
      final String percentLabel = '$percentValue%';

      final Radius corner = Radius.circular(widget.borderRadius ?? Dimensions.radiusDefault);
      final BorderRadius radius = widget.roundedBottom ? BorderRadius.all(corner) : BorderRadius.vertical(top: corner);
      final Color textColor = Theme.of(context).textTheme.bodyLarge!.color!;
      final TextStyle regular = robotoRegular.copyWith(color: textColor, fontSize: Dimensions.fontSizeDefault);
      final TextStyle strong = robotoBold.copyWith(color: textColor, fontSize: Dimensions.fontSizeDefault);

      return Container(
        margin: EdgeInsets.only(bottom: widget.bottomSpacing),
        decoration: BoxDecoration(color: HappyHourPalette.milestoneCard(context), borderRadius: radius),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.tappable ? (widget.onTap ?? () => HappyHourScreen.show(context)) : null,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                Dimensions.paddingSizeLarge, Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeLarge, Dimensions.paddingSizeDefault + widget.bottomInset,
              ),
              child: Row(children: [

                Expanded(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [

                  Row(children: [
                    Image.asset(Images.percentTag, height: _iconSize, width: _iconSize, color: HappyHourPalette.milestoneAccent),
                    const SizedBox(width: Dimensions.paddingSizeSmall),

                    Expanded(child: RichText(
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      text: !hasCartItems ? TextSpan(
                        text: 'get_percentage_off'.tr.replaceAll('{percentage}', percentValue), style: regular,
                      ) : showProgress ? TextSpan(children: [
                        TextSpan(text: '${'add'.tr} ', style: regular),
                        // Compacts a large amount to 1M rather than letting the figure
                        // push the single line it shares out of shape.
                        TextSpan(text: PriceConverter.convertPrice(remaining, forTaxi: true), style: strong),
                        TextSpan(text: ' ${'more_to_get'.tr} ', style: regular),
                        TextSpan(text: percentLabel, style: strong),
                        TextSpan(text: ' ${'discount'.tr}', style: regular),
                      ]) : TextSpan(children: [
                        TextSpan(text: '${'order_now_and_get'.tr} ', style: regular),
                        TextSpan(text: percentLabel, style: strong),
                        TextSpan(text: ' ${'discount'.tr}', style: regular),
                      ]),
                    )),
                  ]),

                  if(hasCartItems) ...[
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                      child: LinearProgressIndicator(
                        minHeight: _progressHeight,
                        value: showProgress ? progress : 1,
                        backgroundColor: HappyHourPalette.milestoneTrack(context),
                        valueColor: const AlwaysStoppedAnimation<Color>(HappyHourPalette.milestoneAccent),
                      ),
                    ),
                  ],
                ])),

                if(widget.showCountdown) ...[
                  const SizedBox(width: Dimensions.paddingSizeLarge),
                  const HappyHourCountdownChip(background: HappyHourPalette.timer),
                ],
              ]),
            ),
          ),
        ),
      );
    });
  }
}
