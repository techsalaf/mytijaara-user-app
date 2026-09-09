import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:intl/intl.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/theme/light_theme.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class OrderItemStatusSection extends StatelessWidget {
  final OrderModel order;
  final double total;

  const OrderItemStatusSection({super.key, required this.order, required this.total});

  @override
  Widget build(BuildContext context) {
    final colors = _StatusBadgeColors.resolve(context, order.orderStatus);
    final formatted = order.createdAt == null ? '' : DateFormat('d MMM, y h:mm a').format(DateTime.parse(order.createdAt!).toLocal());
    final type = (order.orderType == 'delivery' ? 'home_delivery'.tr : order.orderType!.tr);
    final payment = order.paymentMethod == 'cash_on_delivery' ? 'cash_on_delivery'.tr
                  : order.paymentMethod == 'wallet' ? 'wallet_payment'.tr
                  : order.paymentMethod == 'partial_payment' ? 'partial_payment'.tr
                  : order.paymentMethod == 'offline_payment' ? 'offline_payment'.tr : 'digital_payment'.tr;
    return Column( mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(children: [
          Text(
            '#ID ${order.id}',
            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
          ),

          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: order.id.toString()));
              showCustomSnackBar('order_id_copied'.tr, isError: false);
            },
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
              child: Image.asset(Images.copyIcon, width: 14, height: 14),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 3),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(Dimensions.radiusMedium),
            ),
            child: Text(
              (order.orderStatus ?? '').tr.capitalizeFirst ?? '',
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.text),
            ),
          )
        ]),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        // Order Placed date time
        Text(
          '${'order_placed'.tr.capitalize}: $formatted',
          style: robotoRegular.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: Theme.of(context).disabledColor,
          ),
        ),
        // Order type and payment method
        Text(
          '${'order_type_is'.tr.capitalize} $type & ${'paid_by'.tr} $payment.',
          style: robotoRegular.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: Theme.of(context).disabledColor,
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall)
      ],
    );
  }
}

class _StatusBadgeColors {
  final Color background;
  final Color text;

  const _StatusBadgeColors(this.background, this.text);

  static _StatusBadgeColors resolve(BuildContext context, String? status) {
    if (status == 'refunded' || status == 'refund_requested' || status == 'refund_request_canceled') {
      return const _StatusBadgeColors(Color(0x1AF44747), Color(0xFFF44747));
    }
    final mappedKey = _mapStatusKey(status);
    final bg = buttonBackgroundColorMap[mappedKey];
    final fg = buttonTextColorMap[mappedKey];
    if (bg != null && fg != null) {
      return _StatusBadgeColors(bg, fg);
    }
    final fallback = Theme.of(context).disabledColor;
    return _StatusBadgeColors(fallback.withValues(alpha: 0.15), fallback);
  }

  static String _mapStatusKey(String? status) {
    switch (status) {
      case 'pending':
        return 'pending';
      case 'accepted':
      case 'confirmed':
      case 'processing':
      case 'handover':
      case 'picked_up':
        return 'accepted';
      case 'delivered':
        return 'completed';
      case 'canceled':
      case 'failed':
        return 'canceled';
      case 'refunded':
      case 'refund_requested':
      case 'refund_request_canceled':
        return 'expired';
      default:
        return 'pending';
    }
  }
}
