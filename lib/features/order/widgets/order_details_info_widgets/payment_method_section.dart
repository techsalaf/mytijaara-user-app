import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/order/widgets/collapsible_header.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class PaymentMethodSection extends StatefulWidget {
  final List<Payments> payments;

  const PaymentMethodSection({super.key, required this.payments});

  @override
  State<PaymentMethodSection> createState() => PaymentMethodSectionState();
}

class PaymentMethodSectionState extends State<PaymentMethodSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      CollapsibleSectionHeader(
        title: 'payment_method'.tr,
        expanded: _expanded,
        onTap: () => setState(() => _expanded = !_expanded),
      ),

      AnimatedCrossFade(
        firstChild: const SizedBox(width: double.infinity),
        secondChild: Padding(
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (int i = 0; i < widget.payments.length; i++) ...[
              _PaymentRow(payment: widget.payments[i]),
              if (i != widget.payments.length - 1)
                const SizedBox(height: Dimensions.paddingSizeDefault),
            ],
          ]),
        ),
        crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 200),
      ),
    ]);
  }
}

class _PaymentRow extends StatelessWidget {
  final Payments payment;

  const _PaymentRow({required this.payment});

  IconData get _icon {
    switch (payment.paymentMethod) {
      case 'cash_on_delivery':
        return Icons.payments_outlined;
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'digital_payment':
        return Icons.credit_card;
      case 'offline_payment':
        return Icons.receipt_long_outlined;
      default:
        return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Icon(_icon, size: 24, color: Theme.of(context).textTheme.bodyLarge?.color),
      const SizedBox(width: Dimensions.paddingSizeDefault),

      Expanded(
        child: Text(
          (payment.paymentMethod ?? '').tr,
          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
        ),
      ),

      Text(
        PriceConverter.convertPrice(payment.amount ?? 0),
        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeLarge),
      ),
    ]);
  }
}
