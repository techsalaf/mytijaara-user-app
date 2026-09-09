import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_tool_tip_widget.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/pro/domain/models/pro_active_offer_model.dart';
import 'package:sixam_mart/features/order/model/billing_value.dart';
import 'package:sixam_mart/features/order/widgets/collapsible_header.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class BillingSummarySection extends StatefulWidget {
  final OrderModel order;
  final BillingValues billing;

  const BillingSummarySection({super.key, required this.order, required this.billing});

  @override
  State<BillingSummarySection> createState() => _BillingSummarySectionState();
}

class _BillingSummarySectionState extends State<BillingSummarySection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final billing = widget.billing;
    final addOnEnabled = Get.find<SplashController>().getModuleConfig(order.moduleType).addOn ?? false;
    final additionalChargeName = Get.find<SplashController>().configModel?.additionalChargeName ?? '';
    final hasAdditionalCharge = billing.additionalCharge > 0;
    final hasCouponDiscount = billing.couponDiscount > 0;
    final hasReferrerBonus = billing.referrerBonusAmount > 0;
    final hasDmTips = billing.dmTips > 0;
    final hasExtraPackaging = billing.extraPackagingCharge > 0;
    final showVat = billing.tax > 0 && !billing.taxIncluded;
    final showDeliveryTypeCharge = (order.deliveryType == 'slightly_delay' || order.deliveryType == 'express') && billing.deliveryTypeCharge != 0;
    final isProDiscount = order.benefitType == ProBenefitType.discount && (order.proDiscount ?? 0) > 0;
    final isProCoupon = order.benefitType == ProBenefitType.coupon && (hasCouponDiscount || (order.couponDiscountAmount ?? 0) > 0);
    final isProDeliveryFee = order.benefitType == ProBenefitType.deliveryFee && (order.deliveryFeeReductionAmount ?? 0) > 0;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      CollapsibleSectionHeader(
        title: 'billing_summary'.tr,
        expanded: _expanded,
        onTap: () => setState(() => _expanded = !_expanded),
      ),

      AnimatedCrossFade(
        firstChild: const SizedBox(width: double.infinity),
        secondChild: Padding(
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (billing.parcel) ...[
              // Parcel only offers a delivery-fee discount (no item discount, no coupon).
              _BillingRow(
                label: 'delivery_fee'.tr,
                value: '(+) ${PriceConverter.convertPrice(isProDeliveryFee ? billing.deliveryCharge + (order.deliveryFeeReductionAmount ?? 0) : billing.deliveryCharge)}',
              ),
              if (isProDeliveryFee)
                _BillingRow(
                  label: 'delivery_fee_discount_pro'.tr,
                  value: '(-) ${PriceConverter.convertPrice(order.deliveryFeeReductionAmount)}',
                  tooltipMessage: _deliveryDiscountTooltip(order, billing),
                ),
              _BillingRow(label: 'delivery_man_tips'.tr, value: '(+) ${PriceConverter.convertPrice(billing.dmTips)}'),
              if (showVat) _BillingRow(label: 'vat_tax'.tr, value: '(+) ${PriceConverter.convertPrice(billing.tax)}'),
              if (hasAdditionalCharge)
                _BillingRow(label: additionalChargeName, value: '(+) ${PriceConverter.convertPrice(billing.additionalCharge)}'),
            ] else ...[
              _BillingRow(label: 'item_price'.tr, value: PriceConverter.convertPrice(billing.itemsPrice)),
              if (addOnEnabled) ...[
                _BillingRow(label: 'addons'.tr, value: '(+) ${PriceConverter.convertPrice(billing.addOns)}'),
                Divider(thickness: 1, color: Theme.of(context).hintColor.withValues(alpha: 0.5)),
                _BillingRow(label: 'subtotal'.tr, value: PriceConverter.convertPrice(billing.subTotal), isSubTotal: true),
              ],
              _BillingRow(label: 'discount'.tr, value: '(-) ${PriceConverter.convertPrice(billing.discount)}'),
              if (isProDiscount)
                _BillingRow(label: 'discount_pro'.tr, value: '(-) ${PriceConverter.convertPrice(order.proDiscount)}'),
              if (isProCoupon)
                _BillingRow(label: 'coupon_discount_pro'.tr, value: '(-) ${PriceConverter.convertPrice((order.couponDiscountAmount ?? 0) > 0 ? order.couponDiscountAmount : billing.couponDiscount)}')
              else if (hasCouponDiscount)
                _BillingRow(label: 'coupon_discount'.tr, value: '(-) ${PriceConverter.convertPrice(billing.couponDiscount)}'),
              if (hasReferrerBonus)
                _BillingRow(label: 'referral_discount'.tr, value: '(-) ${PriceConverter.convertPrice(billing.referrerBonusAmount)}'),
              if (hasAdditionalCharge)
                _BillingRow(label: additionalChargeName, value: '(+) ${PriceConverter.convertPrice(billing.additionalCharge)}'),
              if (showVat) _BillingRow(label: 'vat_tax'.tr, value: '(+) ${PriceConverter.convertPrice(billing.tax)}'),
              if (hasDmTips)
                _BillingRow(label: 'delivery_man_tips'.tr, value: '(+) ${PriceConverter.convertPrice(billing.dmTips)}'),
              if (hasExtraPackaging)
                _BillingRow(label: 'extra_packaging'.tr, value: '(+) ${PriceConverter.convertPrice(billing.extraPackagingCharge)}'),
              _BillingRow(
                label: 'delivery_fee'.tr,
                value: billing.deliveryCharge > 0
                    ? '(+) ${PriceConverter.convertPrice(isProDeliveryFee ? billing.deliveryCharge + (order.deliveryFeeReductionAmount ?? 0) : billing.deliveryCharge)}'
                    : 'free'.tr,
                valueColor: billing.deliveryCharge > 0 ? null : Theme.of(context).primaryColor,
              ),
              if (isProDeliveryFee)
                _BillingRow(
                  label: 'delivery_fee_discount_pro'.tr,
                  value: '(-) ${PriceConverter.convertPrice(order.deliveryFeeReductionAmount)}',
                  tooltipMessage: _deliveryDiscountTooltip(order, billing),
                ),
              if (showDeliveryTypeCharge)
                _BillingRow(
                  label: '${order.deliveryType!.replaceAll('_', ' ').capitalize} ${'delivery'.tr}',
                  value: '${billing.deliveryTypeCharge < 0 ? '(-)' : '(+)'} ${PriceConverter.convertPrice(billing.deliveryTypeCharge.abs())}',
                ),
            ],

            Divider(height: Dimensions.paddingSizeLarge, color: Theme.of(context).disabledColor.withValues(alpha: 0.5)),

            if (order.paymentMethod == 'partial_payment')
              _PartialPaymentTotal(order: order, total: billing.total, taxIncluded: billing.taxIncluded)
            else
              _TotalAmountRow(
                total: billing.total,
                taxIncluded: billing.taxIncluded,
                parcel: billing.parcel,
                paymentStatus: order.paymentStatus,
              ),

            if (order.parcelCancellation?.returnFee != null && order.parcelCancellation!.returnFee! > 0) ...[
              const SizedBox(height: Dimensions.paddingSizeSmall),
              _ReturnFeeBlock(order: order, total: billing.total),
            ],
          ]),
        ),
        crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 200),
      ),
    ]);
  }

  String _deliveryDiscountTooltip(OrderModel order, BillingValues billing) {
    final double reduction = order.deliveryFeeReductionAmount ?? 0;
    final double originalDeliveryCharge = billing.deliveryCharge + reduction;
    final double percentage = originalDeliveryCharge > 0 ? (reduction / originalDeliveryCharge) * 100 : 0;
    return '${percentage.toStringAsFixed(0)}% ${'delivery_fee_discount_applied'.tr}';
  }
}

class _BillingRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final String? tooltipMessage;
  final bool isSubTotal;

  const _BillingRow({required this.label, required this.value, this.valueColor, this.tooltipMessage, this.isSubTotal = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Flexible(
              child: Text(
                label,
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            if (tooltipMessage != null) ...[
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              CustomToolTip(
                message: tooltipMessage,
                size: Dimensions.fontSizeLarge,
                preferredDirection: AxisDirection.up,
              ),
            ],
          ]),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Text(
          value,
          style: isSubTotal ? robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: valueColor) : robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: valueColor),
          textDirection: TextDirection.ltr,
        ),
      ]),
    );
  }
}

class _TotalAmountRow extends StatelessWidget {
  final double total;
  final bool taxIncluded;
  final bool parcel;
  final String? paymentStatus;

  const _TotalAmountRow({
    required this.total,
    required this.taxIncluded,
    required this.parcel,
    required this.paymentStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text('total_amount'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
      if (taxIncluded)
        Text(
          ' ${'vat_tax_inc'.tr}',
          style: robotoMedium.copyWith(
            fontSize: Dimensions.fontSizeExtraSmall,
            color: Theme.of(context).disabledColor,
          ),
        ),
      const SizedBox(width: Dimensions.paddingSizeExtraSmall),

      if (parcel)
        Container(
          decoration: BoxDecoration(
            color: paymentStatus == 'paid'
                ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                : Theme.of(context).colorScheme.error.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          ),
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall, vertical: 2),
          child: Text(
            paymentStatus == 'paid' ? 'paid'.tr : 'due'.tr,
            style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: paymentStatus == 'paid'
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      const Expanded(child: SizedBox()),

      Text(
        PriceConverter.convertPrice(total),
        style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
        textDirection: TextDirection.ltr,
      ),
    ]);
  }
}

class _PartialPaymentTotal extends StatelessWidget {
  final OrderModel order;
  final double total;
  final bool taxIncluded;

  const _PartialPaymentTotal({required this.order, required this.total, required this.taxIncluded});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Container(
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          color: primary,
          strokeWidth: 1,
          strokeCap: StrokeCap.butt,
          dashPattern: const [8, 5],
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          radius: const Radius.circular(Dimensions.radiusDefault),
        ),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('total_amount'.tr,
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: primary)),
            Text(
              PriceConverter.convertPrice(total),
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: primary),
              textDirection: TextDirection.ltr,
            ),
          ]),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('paid_by_wallet'.tr,
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
            Text(
              PriceConverter.convertPrice(order.payments?[0].amount ?? 0),
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
            ),
          ]),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(
              '${order.payments?[1].paymentStatus == 'paid' ? 'paid_by'.tr : 'due_amount'.tr} (${order.payments?[1].paymentMethod?.tr ?? ''})',
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
            ),
            Text(
              PriceConverter.convertPrice(order.payments?[1].amount ?? 0),
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _ReturnFeeBlock extends StatelessWidget {
  final OrderModel order;
  final double total;

  const _ReturnFeeBlock({required this.order, required this.total});

  @override
  Widget build(BuildContext context) {
    final cancellation = order.parcelCancellation!;
    final isPaid = cancellation.returnFeePaymentStatus == 'paid';
    final pillColor = isPaid
        ? Theme.of(context).primaryColor
        : Theme.of(context).colorScheme.error;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Text('return_fee'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),

          Container(
            decoration: BoxDecoration(
              color: pillColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            ),
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall, vertical: 2),
            child: Text(
              isPaid ? 'paid'.tr : 'due'.tr,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: pillColor),
            ),
          ),
        ]),

        Text(
          '(+) ${PriceConverter.convertPrice(cancellation.returnFee)}',
          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
          textDirection: TextDirection.ltr,
        ),
      ]),

      Padding(
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
        child: Divider(thickness: 1, color: Theme.of(context).hintColor.withValues(alpha: 0.2)),
      ),

      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('total'.tr, style: robotoBold),
        Text(
          PriceConverter.convertPrice(total + cancellation.returnFee!),
          style: robotoBold,
          textDirection: TextDirection.ltr,
        ),
      ]),
    ]);
  }
}
