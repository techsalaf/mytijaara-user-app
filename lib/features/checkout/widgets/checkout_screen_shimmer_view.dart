import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/features/checkout/widgets/saver_delivery_time_widget.dart';
import 'package:sixam_mart/features/checkout/widgets_new/custom_card_checkout.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';

class CheckoutScreenShimmerView extends StatelessWidget {
  const CheckoutScreenShimmerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Center(
            child: SizedBox(
              width: Dimensions.webMaxWidth,
              child: ResponsiveHelper.isMobile(context) ? const CheckoutShimmerView() : const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: CheckoutShimmerView()),
                  SizedBox(width: Dimensions.paddingSizeExtraLarge),
                  Expanded(flex: 4, child: _SummaryPanel()),
                ],
              ),
            ),
          ),
        ),
      ),

      const _OrderBar(),
    ]);
  }
}

class CheckoutShimmerView extends StatelessWidget {
  const CheckoutShimmerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      duration: const Duration(seconds: 2),
      enabled: true,
      child: const Column(children: [
        SizedBox(height: Dimensions.paddingSizeLarge),

        CustomCardCheckout(child: Row(children: [
          Expanded(child: _Box(height: 40, radius: Dimensions.radiusLarge)),
          SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(child: _Box(height: 40, radius: Dimensions.radiusLarge)),
        ])),
        SizedBox(height: Dimensions.paddingSizeLarge),

        // Delivery time — the slot pickers and, under them, the saver tiers.
        // Missing from this skeleton before, so the loaded screen grew a whole
        // card here and pushed everything below it down.
        _TimeSlotAndSaverCard(),
        SizedBox(height: Dimensions.paddingSizeLarge),

        _SectionCard(children: [
          _Box(height: 16, width: 140),
          SizedBox(height: Dimensions.paddingSizeDefault),
          Row(children: [
            _Box(height: 40, width: 40, radius: Dimensions.radiusDefault),
            SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Box(height: 12, width: 110),
              SizedBox(height: Dimensions.paddingSizeExtraSmall),
              _Box(height: 10),
            ])),
          ]),
          SizedBox(height: Dimensions.paddingSizeDefault),
          _Box(height: 44, radius: Dimensions.radiusDefault),
        ]),
        SizedBox(height: Dimensions.paddingSizeLarge),

        _SectionCard(children: [
          Row(children: [
            _Box(height: 24, width: 24, radius: Dimensions.radiusDefault),
            SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(child: _Box(height: 14, width: 120)),
            _Box(height: 14, width: 60),
          ]),
        ]),
        SizedBox(height: Dimensions.paddingSizeLarge),

        _SectionCard(children: [
          _Box(height: 16, width: 160),
          SizedBox(height: Dimensions.paddingSizeDefault),
          Row(children: [
            Expanded(child: _Box(height: 36, radius: Dimensions.radiusDefault)),
            SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(child: _Box(height: 36, radius: Dimensions.radiusDefault)),
            SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(child: _Box(height: 36, radius: Dimensions.radiusDefault)),
            SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(child: _Box(height: 36, radius: Dimensions.radiusDefault)),
          ]),
          SizedBox(height: Dimensions.paddingSizeDefault),
          _Box(height: 44, radius: Dimensions.radiusDefault),
        ]),
        SizedBox(height: Dimensions.paddingSizeLarge),

        _SectionCard(children: [
          _Box(height: 16, width: 140),
          SizedBox(height: Dimensions.paddingSizeDefault),
          _Box(height: 52, radius: Dimensions.radiusDefault),
        ]),
        SizedBox(height: Dimensions.paddingSizeLarge),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: _BillingSummary(),
        ),
        SizedBox(height: Dimensions.paddingSizeLarge),
      ]),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      duration: const Duration(seconds: 2),
      enabled: true,
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
        ),
        child: const Column(children: [
          _BillingSummary(),
          SizedBox(height: Dimensions.paddingSizeLarge),
          _Box(height: 48, radius: Dimensions.radiusDefault),
        ]),
      ),
    );
  }
}

class _BillingSummary extends StatelessWidget {
  const _BillingSummary();

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _Box(height: 16, width: 150),
      const SizedBox(height: Dimensions.paddingSizeDefault),

      ...List<Widget>.generate(4, (int index) => const Padding(
        padding: EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _Box(height: 14, width: 110),
          _Box(height: 14, width: 70),
        ]),
      )),

      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
      const _Box(height: 1),
      const SizedBox(height: Dimensions.paddingSizeDefault),

      const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _Box(height: 16, width: 90),
        _Box(height: 16, width: 90),
      ]),
    ]);
  }
}

class _OrderBar extends StatelessWidget {
  const _OrderBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.1), blurRadius: 10)],
      ),
      padding: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeLarge, Dimensions.paddingSizeDefault, Dimensions.paddingSizeLarge, Dimensions.paddingSizeSmall,
      ),
      child: SafeArea(top: false, child: Shimmer(
        duration: const Duration(seconds: 2),
        enabled: true,
        child: const Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _Box(height: 16, width: 120),
            _Box(height: 16, width: 90),
          ]),
          SizedBox(height: Dimensions.paddingSizeDefault),
          _Box(height: 50, radius: Dimensions.radiusDefault),
        ]),
      )),
    );
  }
}

/// The delivery-time card: a title, the slot pickers, then the saver tiers.
///
/// The tier rows come from [SaverDeliveryOptionsShimmer] — the same placeholder
/// the live section shows while it waits for `checkout-summary` — so the
/// skeleton and the not-yet-quoted screen are the same shape, and the handover
/// between them is invisible.
class _TimeSlotAndSaverCard extends StatelessWidget {
  const _TimeSlotAndSaverCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(children: <Widget>[
      const _Box(height: 16, width: 120),
      const SizedBox(height: Dimensions.paddingSizeDefault),

      const Row(children: <Widget>[
        Expanded(child: _Box(height: 36, radius: Dimensions.radiusDefault)),
        SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(child: _Box(height: 36, radius: Dimensions.radiusDefault)),
      ]),
      const SizedBox(height: Dimensions.paddingSizeDefault),

      Divider(height: 1, thickness: 0.5, color: Theme.of(context).disabledColor.withValues(alpha: 0.2)),

      const SaverDeliveryOptionsShimmer(animate: false),
    ]);
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return CustomCardCheckout(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _Box extends StatelessWidget {
  final double height;
  final double? width;
  final double radius;
  const _Box({required this.height, this.width, this.radius = Dimensions.radiusSmall});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// SUMMARY
// Loading skeleton for the checkout screen. Draws the delivery type switch, address,
// coupon, tips and payment cards, the billing summary and the bottom order bar as
// shimmering placeholders, in the same order and shapes as the loaded screen, with a
// summary panel beside them on desktop.
