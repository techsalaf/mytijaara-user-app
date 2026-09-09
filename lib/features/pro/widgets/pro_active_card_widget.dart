import 'package:sixam_mart/features/pro/controllers/pro_controller.dart';
import 'package:sixam_mart/features/pro/domain/models/pro_active_offer_model.dart';
import 'package:sixam_mart/features/pro/widgets/pro_subscription_actions_widget.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/module_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProActiveCardWidget extends StatelessWidget {
  final ProActiveOfferModel? activeOfferModel;
  final VoidCallback? onRenew;
  final List<Map<String, String>>? benefitItemsOverride;
  const ProActiveCardWidget({super.key, required this.activeOfferModel, this.onRenew, this.benefitItemsOverride});

  @override
  Widget build(BuildContext context, ) {
    final ProActivePlanDetails? details = activeOfferModel?.planDetails;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('my_subscription'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge)),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.2)),
          ),
          child: Column(children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              decoration: BoxDecoration(
                color: const Color(0xFFE1D3FF),
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                boxShadow: [BoxShadow(color: const Color(0xFFB794F6).withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 8))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      details?.planName ?? 'monthly_package'.tr,
                      style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Colors.black,),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: 6),
                    decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)),
                    child: Text('active'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.green)),
                  ),
                ]),
                const SizedBox(height: Dimensions.paddingSizeLarge),
                Row(children: [
                  Expanded(child: _buildStatCard(context, 'total_saved'.tr, PriceConverter.convertPrice(details?.totalSaved ?? 0))),
                  const SizedBox(width: Dimensions.paddingSizeDefault),
                  Expanded(child: _buildStatCard(context, 'orders_placed'.tr, '${details?.totalOrders ?? 0}')),
                ]),
              ]),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('plan_details'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
                const SizedBox(height: Dimensions.paddingSizeDefault),
                _buildDetailRow(context, Icons.calendar_today_outlined, 'active_since'.tr, _formatDate(details?.startAt)),
                _buildDetailRow(context, Icons.calendar_today_outlined, 'expires_on'.tr, _formatDate(details?.endAt)),
                _buildDetailRow(context, Icons.credit_card_outlined, 'days_remaining'.tr, '${details?.daysRemaining ?? 0} ${'days'.tr.toLowerCase()}'),
                _buildDetailRow(context, Icons.account_balance_wallet_outlined, 'paid_by'.tr, _formatPaidBy(details?.paidBy), showDivider: false),
              ]),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            _buildBenefitsSection(context, activeOfferModel?.benefit),

            const SizedBox(height: Dimensions.paddingSizeExtraLarge),
            GetBuilder<ProController>(builder: (proController) {
              return ProSubscriptionActionsWidget(plans: proController.planModel?.plans, onRenew: onRenew);
            }),
          ]),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge?.color?.withAlpha(150))),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Text(value, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge?.color)),
      ]),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String title, String value, {bool showDivider = true}) {
    return Column(children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: Theme.of(context).hintColor, size: 22),
        const SizedBox(width: Dimensions.paddingSizeDefault),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Text(value, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color)),
        ])),
      ]),
      if (showDivider) Padding(
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
        child: Divider(color: Theme.of(context).disabledColor.withValues(alpha: 0.2), height: 1),
      ),
    ]);
  }

  Widget _buildBenefitsSection(BuildContext context, ProActiveBenefit? benefit) {
    final List<Map<String, String>> items = benefitItemsOverride ?? _buildBenefitItems(benefit);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('package_benefits'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          if (items.isEmpty)
            _buildNoBenefitsBanner(context)
          else
            ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  width: 8, height: 8,
                  decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['title']!, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
                      if (item['subtitle']!.isNotEmpty)
                        Text(item['subtitle']!, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // Shown when the active plan has no benefit configured for the current module.
  Widget _buildNoBenefitsBanner(BuildContext context) {
    const Color amber = Color(0xFFF0A52E);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(color: amber.withValues(alpha: 0.4)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.info_outline_rounded, color: amber, size: 20),
        const SizedBox(width: Dimensions.paddingSizeSmall),

        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('no_benefits_available_for_this_module'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall)),
          const SizedBox(height: 2),

          Text(
            'your_current_pro_plan_does_not_include_savings_for_this_module'.tr,
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor, height: 1.4),
          ),
        ])),
      ]),
    );
  }

  List<Map<String, String>> _buildBenefitItems(ProActiveBenefit? benefit) {
    if (benefit == null) return [];
    final type = benefit.type;
    final String minLabel = ModuleHelper.proMinSpendLabel(fallbackKey: 'minimum_order_amount');
    if (type == ProBenefitType.discount && (benefit.percentage != null && benefit.percentage! > 0)) {
      final double pct = benefit.percentage ?? 0;
      final double max = benefit.maxAmount ?? 0;
      return [{
        'title': '${'discount_on_all_orders'.tr} (${pct.toStringAsFixed(0)}%)',
        'subtitle': '${'get_up_to'.tr} ${PriceConverter.convertPrice(max)} ${'discount'.tr}${(benefit.minOrderStatus ?? false) ? ', $minLabel ${PriceConverter.convertPrice(benefit.minOrderAmount)}' : ""}',
      }];
    }
    if (type == ProBenefitType.deliveryFee) {
      return [{
        'title': (benefit.offerType == ProOfferType.fullFree) ? 'free_delivery'.tr : 'delivery_fee_discount'.tr,
        'subtitle': (benefit.offerType == ProOfferType.fullFree)
            ? '${'enjoy_unlimited_free_deliveries'.tr}${(benefit.minOrderStatus ?? false) ? ', $minLabel ${PriceConverter.convertPrice(benefit.minOrderAmount)}' : ""}'
            : '${'enjoy'.tr} ${benefit.chargeDiscountPercentage}% ${'discount_on_every_delivery'.tr}${(benefit.minOrderStatus ?? false) ? ', $minLabel ${PriceConverter.convertPrice(benefit.minOrderAmount)}' : ""}',
      }];
    }
    if (type == ProBenefitType.coupon) {
      return [{'title': 'exclusive_coupon_on_order'.tr, 'subtitle': 'unlock_exclusive_coupon_deals'.tr}];
    }
    return [];
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return '';
    return DateConverter.stringToReadableString(date);
  }

  String _formatPaidBy(String? paidBy) {
    if (paidBy == null || paidBy.isEmpty) return '';
    return paidBy.replaceAll('_', ' ').capitalizeFirst ?? paidBy;
  }
}
