import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/checkout/domain/models/checkout_summary_model.dart';
import 'package:sixam_mart/features/coupon/controllers/coupon_controller.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class SaverDeliveryTimeWidget extends StatelessWidget {
  final CheckoutController checkoutController;
  final double deliveryCharge;
  final double originalDeliveryCharge;
  // True when the Pro membership fully covers the delivery fee (full-free or 100% off);
  // the saver charge options become meaningless, so they are disabled just like a free-delivery coupon.
  final bool proFreeDelivery;

  const SaverDeliveryTimeWidget({super.key,
    required this.checkoutController, required this.deliveryCharge, required this.originalDeliveryCharge, this.proFreeDelivery = false,
  });

  static bool _disableSaverOptions({
    required CheckoutController controller, required double deliveryCharge, required double originalDeliveryCharge, bool proFreeDelivery = false,
  }) {
    final Modules? saverModule = controller.saverModule;
    final double? minimumDeliveryCharge = saverModule?.pivot?.minimumDeliveryCharge;
    final bool isFreeDeliveryCouponApplied = Get.find<CouponController>().freeDelivery;
    final bool belowOriginalDeliveryCharge = minimumDeliveryCharge != null
        && originalDeliveryCharge >= 0
        && originalDeliveryCharge < minimumDeliveryCharge;
    final bool hadEligibleOriginalDeliveryCharge = originalDeliveryCharge > 0 && !belowOriginalDeliveryCharge;
    // A settled quote pricing delivery at nothing is free delivery, whoever granted it.
    final bool quotedFreeDelivery = controller.checkoutSummary?.delivery != null && deliveryCharge == 0;
    return proFreeDelivery || quotedFreeDelivery
        || (isFreeDeliveryCouponApplied && deliveryCharge == 0 && hadEligibleOriginalDeliveryCharge);
  }

  /// Whether the current fee is one the saver tiers can actually be priced against.
  ///
  /// Kept free of [CheckoutController] so it is unit-testable — the widgets here
  /// cannot be mounted in a bare test, because `Dimensions` reads `Get.context!`
  /// in its static initialisers.
  ///
  /// A fee of `0` (free delivery) or `-1` (still calculating) is not eligible, and
  /// neither is one below the module's own minimum: an area- or ZIP-priced zone
  /// quotes the rule's bare minimum until the customer picks their area, and that
  /// figure can sit under `pivot.minimum_delivery_charge`.
  static bool isDeliveryChargeEligible({required double deliveryCharge, required double? minimumDeliveryCharge}) {
    final bool belowMinimum = minimumDeliveryCharge != null
        && deliveryCharge >= 0
        && deliveryCharge < minimumDeliveryCharge;
    return deliveryCharge > 0 && !belowMinimum;
  }

  /// Whether the section renders at all.
  ///
  /// Gated on the zone/module **configuration** only. The delivery fee is
  /// deliberately not consulted here: it legitimately moves — `-1` while a quote
  /// is in flight, the rule's minimum before an area is picked, the real rate
  /// after — and letting it decide visibility made the whole section appear and
  /// disappear as the customer worked through checkout. The fee instead decides
  /// whether the options are *selectable*; see [isDeliveryChargeEligible] and the
  /// `AbsorbPointer` in [build].
  static bool canShow({required CheckoutController controller}) {
    // Saver delivery tiers (express / slightly-delay) are platform-fleet options;
    // when the store delivers with its own fleet they don't apply, so hide them.
    final bool isSelfDeliveryStore = controller.store?.selfDeliverySystem == 1;
    return controller.orderType == 'delivery'
        && !isSelfDeliveryStore
        && (_quoteOffersOptions(controller) || _zoneConfigOffersOptions(controller));
  }

  /// `checkout-summary` priced tiers for this order. That is the platform saying
  /// the feature is on for this zone and module, so it stands on its own — the
  /// zone config it would otherwise be checked against is read from the *stored*
  /// address and can lag behind.
  static bool _quoteOffersOptions(CheckoutController controller) =>
      controller.quotedDeliveryOptions.any((CheckoutSummaryDeliveryOption o) => o.isUsable);

  /// The pre-existing source: the zone/module block hanging off the saved
  /// address. Still honoured so a build talking to a platform that does not yet
  /// send `delivery_options` behaves exactly as before.
  static bool _zoneConfigOffersOptions(CheckoutController controller) {
    final ZoneData? saverZoneData = controller.saverZoneData;
    final Modules? saverModule = controller.saverModule;
    return saverZoneData != null
        && saverModule?.deliveryOptions != null
        && saverZoneData.status == 1
        && (saverModule?.additionalDeliveryOptionStatus ?? false);
  }

  @override
  Widget build(BuildContext context) {
    // Free delivery makes the saver charges meaningless, so the tier is reset to standard.
    final bool freeDeliveryDisabled = _disableSaverOptions(
      controller: checkoutController, deliveryCharge: deliveryCharge, originalDeliveryCharge: originalDeliveryCharge, proFreeDelivery: proFreeDelivery,
    );
    // The fee simply is not known yet — a quote in flight, or an area-priced zone
    // before the customer has picked. Temporary, so the options are dimmed rather
    // than removed, and the existing choice is deliberately left alone.
    final bool feeNotReady = !freeDeliveryDisabled && !isDeliveryChargeEligible(
      deliveryCharge: deliveryCharge,
      minimumDeliveryCharge: checkoutController.saverModule?.pivot?.minimumDeliveryCharge,
    );
    final bool disableSaverOptions = freeDeliveryDisabled || feeNotReady;

    // Only the free-delivery case resets the selection. Resetting on [feeNotReady]
    // would wipe the customer's tier every time a requote was in flight.
    if(freeDeliveryDisabled && checkoutController.saverDeliveryType != 'standard') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if(checkoutController.saverDeliveryType != 'standard') {
          checkoutController.setSaverDeliveryType('standard');
        }
      });
    }

    final List<_SaverOption> options = _resolveOptions();

    // Until the first quote answers, the only source is the zone config, whose
    // ranges the client reconstructs from the store's free-text delivery time.
    // Drawing those would show one set of times and then change them under the
    // customer the moment `delivery_options` arrives. The config's *count* is
    // still useful — it sizes the skeleton so the section does not jump either.
    //
    // Gated on never having had a quote, not on `summaryLoading`: a requote
    // keeps the tiers it already showed rather than flashing a skeleton over
    // every coupon, tip or address change.
    if(checkoutController.checkoutSummary == null) {
      return SaverDeliveryOptionsShimmer(
        count: options.isNotEmpty ? options.length : 3,
        isDesktop: ResponsiveHelper.isDesktop(context),
      );
    }

    if(options.isEmpty) return const SizedBox.shrink();

    return Column(children: [
      AbsorbPointer(
        absorbing: disableSaverOptions,
        child: Opacity(
          opacity: disableSaverOptions ? 0.55 : 1,
          child: RadioGroup<String>(
            groupValue: checkoutController.saverDeliveryType,
            onChanged: (String? value) {
              if(value != null && !disableSaverOptions) {
                checkoutController.setSaverDeliveryType(value);
              }
            },
            child: ResponsiveHelper.isDesktop(context) ? SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                    child: SizedBox(
                      width: 270,
                      child: _saverCard(context, options[index], isDesktop: true),
                    ),
                  );
                },
              ),
            ) : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: options.length,
              separatorBuilder: (_, _) => Divider(
                height: 1, thickness: 0.5,
                color: Theme.of(context).disabledColor.withValues(alpha: 1),
              ),
              itemBuilder: (context, index) {
                return _saverCard(context, options[index]);
              },
            ),
          ),
        ),
      ),

      // The two reasons read very differently to a customer: one is a permanent
      // consequence of their order, the other is "wait a moment".
      if(disableSaverOptions) ...[
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 18),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Expanded(child: Text(
            freeDeliveryDisabled
                ? 'free_delivery_applies_to_this_order_amount_so_delivery_type_charge_options_are_disabled'.tr
                : 'saver_options_available_once_delivery_fee_is_calculated'.tr,
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
          )),
        ]),
      ],
    ]);
  }

  /// The rows to draw, quote first.
  ///
  /// `checkout-summary.delivery_options` is priced against this basket and
  /// carries the platform's own label and time range, so where it answers it is
  /// rendered as sent — nothing here reconstructs a range any more. The
  /// zone/module config stays as the fallback, so a build talking to a platform
  /// that does not send the block yet behaves exactly as it did.
  List<_SaverOption> _resolveOptions() {
    final List<CheckoutSummaryDeliveryOption> quoted = checkoutController.quotedDeliveryOptions
        .where((CheckoutSummaryDeliveryOption option) => option.isUsable).toList();

    if(quoted.isNotEmpty) {
      return quoted.map((CheckoutSummaryDeliveryOption option) => _SaverOption(
        deliveryType: option.deliveryType!,
        // Already localised by the platform, so it is not run through `.tr`.
        label: (option.deliveryTypeText ?? '').isNotEmpty
            ? option.deliveryTypeText! : '${option.deliveryType!.tr} ${'delivery'.tr}',
        timeText: option.timeRange ?? '',
      )).toList();
    }

    return (checkoutController.saverModule?.deliveryOptions ?? const <DeliveryOptions>[])
        .where((DeliveryOptions option) => (option.deliveryType ?? '').isNotEmpty)
        .map((DeliveryOptions option) => _SaverOption(
          deliveryType: option.deliveryType!,
          label: '${option.deliveryType!.tr} ${'delivery'.tr}',
          timeText: _finalizeDeliveryTime(checkoutController.store?.deliveryTime ?? '', option),
          configOption: option,
        )).toList();
  }

  Widget _saverCard(BuildContext context, _SaverOption option, {bool isDesktop = false}) {
    final bool select = checkoutController.saverDeliveryType == option.deliveryType;
    // The tier's own figure, uncapped. `deliveryType` is what resolves a quoted
    // row; `configOption` is null for those and carries the fallback.
    final double adjustment = checkoutController.rawSaverDeliveryAdjustment(
      deliveryOption: option.configOption, deliveryType: option.deliveryType,
    );

    // Driven by the adjustment rather than by which key was present: this payload
    // sends both and zeroes the unused one, so `standard` would otherwise wear a
    // "+ 0" badge.
    final Widget chargeBadge = adjustment == 0
        ? const SizedBox.shrink()
        : Container(
            decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            ),
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 3),
            child: Text(
              '${adjustment > 0 ? '+' : '-'} ${PriceConverter.convertPrice(adjustment.abs())}',
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
            ),
          );

    final Widget radio = Radio<String>(
      value: option.deliveryType,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      activeColor: Theme.of(context).primaryColor,
      visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
    );

    final Widget content = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(
        option.label,
        maxLines: 1, overflow: TextOverflow.ellipsis,
        style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
      ),
      // Absent when the platform sent no range and the store's own delivery time
      // could not be parsed — an empty line reads as a missing value.
      if(option.timeText.isNotEmpty) ...[
        const SizedBox(height: 4),
        Text(
          option.timeText,
          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
        ),
      ],
    ]);

    return InkWell(
      onTap: () => checkoutController.setSaverDeliveryType(option.deliveryType),
      child: Container(
        decoration: isDesktop ? BoxDecoration(
          color: select ? Theme.of(context).primaryColor.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          border: Border.all(color: select ? Theme.of(context).primaryColor : Theme.of(context).disabledColor, width: 0.5),
        ) : null,
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? Dimensions.paddingSizeSmall : 0,
          vertical: Dimensions.paddingSizeSmall,
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(child: content),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          chargeBadge,
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          radio,
        ]),
      ),
    );
  }

  String _finalizeDeliveryTime(String storeDeliveryTime, DeliveryOptions deliveryOption) {
    String time = '';
    if(storeDeliveryTime.isNotEmpty) {
      int minTime = 0;
      int maxTime = 0;
      try {
        // Accepts: "20-30 min", "15-20", "20-30-min", "15 - 25 hour"
        final match = RegExp(r'(\d+(?:\.\d+)?)\s*-\s*(\d+(?:\.\d+)?)\s*(\w+)?', caseSensitive: false).firstMatch(storeDeliveryTime);
        if(match == null) {
          throw const FormatException('Invalid delivery time format');
        }
        minTime = int.parse(match.group(1)!);
        maxTime = int.parse(match.group(2)!);
        final String timeUnit = match.group(3) ?? 'min';

        minTime = _convertToMinutes(minTime, timeUnit);
        maxTime = _convertToMinutes(maxTime, timeUnit);

        int saverMinTime = checkoutController.saverModule?.pivot?.minimumDeliveryTime?.value ?? 0;
        final String saverMinTimeType = checkoutController.saverModule?.pivot?.minimumDeliveryTime?.unit ?? 'min';
        saverMinTime = _convertToMinutes(saverMinTime, saverMinTimeType);

        if(minTime > saverMinTime) {
          minTime = saverMinTime;
        }

        if(maxTime < saverMinTime) {
          maxTime = saverMinTime;
        }

        if(deliveryOption.deliveryType == 'standard') {
          time = _formatDeliveryTime(minTime, maxTime);
        } else if(deliveryOption.deliveryType == 'express') {
          int reduceTime = deliveryOption.reduceDeliveryTime?.value ?? 0;
          final String reduceTimeType = deliveryOption.reduceDeliveryTime?.unit ?? timeUnit;
          reduceTime = _convertToMinutes(reduceTime, reduceTimeType);
          time = _formatDeliveryTime(minTime, (maxTime - reduceTime).clamp(minTime, 9999999));
        } else if(deliveryOption.deliveryType == 'slightly_delay') {
          int addTime = deliveryOption.addDeliveryTime?.value ?? 0;
          final String addTimeType = deliveryOption.addDeliveryTime?.unit ?? timeUnit;
          addTime = _convertToMinutes(addTime, addTimeType);
          time = _formatDeliveryTime(minTime, maxTime + addTime);
        }
      } catch(_) {}
    }
    return time;
  }

  int _convertToMinutes(int value, String? unit) {
    final normalizedUnit = unit?.toLowerCase() ?? 'min';
    if (normalizedUnit.contains('day')) {
      return value * 24 * 60;
    }
    if (normalizedUnit.contains('hour') ||
        normalizedUnit.contains('hr')) {
      return value * 60;
    }
    return value;
  }

  String _formatDeliveryTime(int minTime, int maxTime) {
    String left = _getSlidTime(minTime);
    String right = _getSlidTime(maxTime);

    final bool isLeftContainMin = left.contains('min');
    final bool isRightContainMin = right.contains('min');
    final bool isLeftContainHour = left.contains('hr');
    final bool isRightContainHour = right.contains('hr');

    if(isLeftContainMin && isRightContainMin && !isLeftContainHour && !isRightContainHour) {
      left = left.replaceAll(' min', '');
      right = right.replaceAll(' min', '');
      if(left == right) {
        return '(${'upto'.tr} $left min)';
      }
      return '($left - $right) min';
    }
    if(!isLeftContainMin && !isRightContainMin && isLeftContainHour && isRightContainHour) {
      left = left.replaceAll(' hr', '');
      right = right.replaceAll(' hr', '');
      if(left == right) {
        return '(${'upto'.tr} $left hr)';
      }
      return '($left - $right) hr';
    }
    if(left == right) {
      return '(${'upto'.tr} $left)';
    }
    return '($left - $right)';
  }

  String _getSlidTime(int value) {
    if(value >= 60) {
      final int h = value ~/ 60;
      final int m = value % 60;
      if(m == 0) {
        return '$h hr';
      }
      return '$h hr $m min';
    }
    return '$value min';
  }
}

/// One saver tier as the card needs it, from whichever source supplied it.
///
/// Exists so the quote's rows and the zone-config rows draw through one code
/// path: they carry different shapes — the quote sends a written-out
/// `time_range` and zeroes the charge key that does not apply, the config sends
/// `{value, unit}` deltas and leaves the unused key null — and reconciling that
/// inside the card was how `standard` ended up wearing a "+ 0" badge.
class _SaverOption {
  /// The key posted as `saver_delivery_type` and matched against the selection.
  final String deliveryType;

  final String label;

  /// Empty when neither source could supply one; the card then omits the line.
  final String timeText;

  /// The zone-config row this came from, or null for a quoted one. Carried so
  /// the charge adjustment can still be resolved per option on the fallback
  /// path — without it every card would price against the *selected* tier.
  final DeliveryOptions? configOption;

  const _SaverOption({required this.deliveryType, required this.label, required this.timeText, this.configOption});
}

/// Placeholder rows for the saver tiers, shown until the first quote answers.
///
/// The tiers' times come from `checkout-summary.delivery_options`. Before that
/// response lands the only source is the zone config, whose ranges the client
/// reconstructs from the store's free-text delivery time — a different set of
/// numbers that would visibly change under the customer the moment the quote
/// arrives. A skeleton says "not yet" instead of saying something wrong.
///
/// [count] is taken from the config where it knows how many tiers this zone has,
/// so the section does not resize when the real rows replace these.
class SaverDeliveryOptionsShimmer extends StatelessWidget {
  final int count;
  final bool isDesktop;

  /// False when the caller already sits inside a [Shimmer] — the whole-screen
  /// skeleton does — so the rows are not swept twice at two different phases.
  final bool animate;

  const SaverDeliveryOptionsShimmer({super.key, this.count = 3, this.isDesktop = false, this.animate = true});

  @override
  Widget build(BuildContext context) {
    final Color base = Theme.of(context).disabledColor.withValues(alpha: 0.2);

    Widget box(double height, double width, {double radius = Dimensions.radiusSmall}) => Container(
      height: height, width: width,
      decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(radius)),
    );

    // Mirrors `_saverCard`: label and time range stacked on the left, the charge
    // badge and the radio on the right.
    Widget row() => Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          box(14, 120),
          const SizedBox(height: 6),
          box(11, 90),
        ])),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        box(20, 54, radius: Dimensions.radiusLarge),
        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
        box(18, 18, radius: 9),
      ]),
    );

    final Widget rows = isDesktop
          ? SizedBox(height: 110, child: Row(children: <Widget>[
              for(int i = 0; i < count; i++) ...<Widget>[
                if(i > 0) const SizedBox(width: Dimensions.paddingSizeSmall),
                SizedBox(width: 270, child: row()),
              ],
            ]))
          : Column(children: <Widget>[
              for(int i = 0; i < count; i++) ...<Widget>[
                if(i > 0) Divider(height: 1, thickness: 0.5, color: Theme.of(context).disabledColor.withValues(alpha: 1)),
                row(),
              ],
            ]);

    return animate ? Shimmer(duration: const Duration(seconds: 2), child: rows) : rows;
  }
}

// SUMMARY
// Saver delivery tier picker for checkout — standard, express and slightly-delay rows with
// their time range and the tier's own extra or reduce charge as the platform configured it,
// taken from the checkout quote where it prices them and from the zone/module config
// otherwise. Decides on its own whether the section renders, shows a skeleton until the
// first quote answers, and dims the rows with a reason when the fee is free or not yet
// known. Also holds the matching shimmer used by the checkout skeleton.
