import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class ScheduledOrderBanner extends StatelessWidget {
  final OrderModel order;

  const ScheduledOrderBanner({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    final String scheduledTime = order.scheduleAt != null ? DateConverter.dateTimeStringToDateTime(order.scheduleAt!) : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary.withValues(alpha: 0.12), primary.withValues(alpha: 0.04)],
        ),
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        border: Border.all(color: primary.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Container(
          height: 30, width: 30,
          decoration: BoxDecoration(color: primary.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: Icon(Icons.event_available_rounded, color: primary, size: 16),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),

        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(
            'scheduled_order'.tr,
            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: primary),
          ),
          const SizedBox(height: 1),

          Row(children: [
            Icon(Icons.access_time_rounded, size: 12, color: Theme.of(context).disabledColor),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
            Flexible(child: Text(
              scheduledTime,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor),
            )),
          ]),
        ])),
      ]),
    );
  }
}
