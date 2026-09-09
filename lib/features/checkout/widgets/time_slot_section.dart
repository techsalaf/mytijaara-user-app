import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:sixam_mart/common/models/config_model.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/checkout/widgets/time_slot_bottom_sheet.dart';
import 'package:sixam_mart/features/checkout/widgets_new/custom_card_checkout.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class TimeSlotSection extends StatelessWidget {
  final int? storeId;
  final CheckoutController checkoutController;
  final List<CartModel?>? cartList;
  final JustTheController tooltipController2;
  final bool tomorrowClosed;
  final bool todayClosed;
  final Module? module;
  final Widget? trailingContent;
  const TimeSlotSection({super.key,
    this.storeId, required this.checkoutController, this.cartList, required this.tooltipController2, required this.tomorrowClosed,
    required this.todayClosed, this.module, this.trailingContent,
  });

  static bool shouldRender({
    required int? storeId, required CheckoutController checkoutController, required List<CartModel?>? cartList,
  }) {
    final bool isGuestLoggedIn = AuthHelper.isGuestLoggedIn();
    return !isGuestLoggedIn
        && storeId == null
        && (checkoutController.store?.scheduleOrder ?? false)
        && (cartList?.isNotEmpty ?? false)
        && cartList![0]!.item!.availableDateStarts == null;
  }

  void _openSheet(BuildContext context) {
    final sheet = TimeSlotBottomSheet(
      tomorrowClosed: tomorrowClosed,
      todayClosed: todayClosed,
      module: module,
    );
    if (ResponsiveHelper.isDesktop(context)) {
      showDialog(context: context, builder: (_) => Dialog(child: sheet));
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => sheet,
      );
    }
  }

  bool _isInstant(CheckoutController c) => c.isInstantDelivery;

  bool _selectedDateClosed(CheckoutController c) {
    return (c.selectedDateSlot == 0 && todayClosed)
        || (c.selectedDateSlot == 1 && tomorrowClosed);
  }

  String _scheduledDisplay(CheckoutController c) {
    if (c.timeSlots == null || c.timeSlots!.isEmpty) return c.preferableTime;
    final slot = c.timeSlots![c.selectedTimeSlot];
    if (slot.startTime == null) return c.preferableTime;
    final DateTime base = c.selectedDateSlot == 0
        ? DateTime.now()
        : DateTime.now().add(const Duration(days: 1));
    final DateTime when = DateTime(
      base.year, base.month, base.day,
      slot.startTime!.hour, slot.startTime!.minute,
    );
    return DateConverter.dateMonthTime(when);
  }

  @override
  Widget build(BuildContext context) {
    if (!shouldRender(storeId: storeId, checkoutController: checkoutController, cartList: cartList)) {
      return const SizedBox();
    }

    return GetBuilder<CheckoutController>(builder: (controller) {
      final bool instant = _isInstant(controller);
      final bool dateClosed = _selectedDateClosed(controller);

      return Column(children: [
        CustomCardCheckout(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            InkWell(
              onTap: () => _openSheet(context),
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _TimeSlotHeader(
                  instant: instant,
                  tooltipController: tooltipController2,
                  onEdit: () => _openSheet(context),
                ),

                if (!instant) ...[
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  Text(
                    dateClosed
                        ? (module!.showRestaurantText! ? 'restaurant_is_closed'.tr : 'store_is_closed'.tr)
                        : _scheduledDisplay(controller),
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: dateClosed
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ]),
            ),

            if (trailingContent != null) ...[
              const SizedBox(height: Dimensions.paddingSizeSmall),
              // const Divider(height: 1),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              trailingContent!,
            ],
          ]),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),
      ]);
    });
  }
}

class _TimeSlotHeader extends StatelessWidget {
  final bool instant;
  final JustTheController tooltipController;
  final VoidCallback onEdit;

  const _TimeSlotHeader({
    required this.instant,
    required this.tooltipController,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final String title = instant ? 'instant_delivery'.tr : 'schedule_delivery'.tr;
    final String subtitle = instant ? 'instant_delivery_subtitle'.tr : 'schedule_delivery_subtitle'.tr;

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),

            JustTheTooltip(
              backgroundColor: Colors.black87,
              controller: tooltipController,
              preferredDirection: AxisDirection.right,
              tailLength: 14,
              tailBaseWidth: 20,
              content: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                child: Text(
                  'schedule_time_tool_tip'.tr,
                  style: robotoRegular.copyWith(color: Colors.white),
                ),
              ),
              child: InkWell(
                onTap: () => tooltipController.showTooltip(),
                child: Icon(Icons.info_outline, size: 18, color: Theme.of(context).disabledColor),
              ),
            ),
          ]),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: Theme.of(context).disabledColor,
            ),
          ),
        ]),
      ),
      const SizedBox(width: Dimensions.paddingSizeSmall),

      GestureDetector(
        onTap: onEdit,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          ),
          alignment: Alignment.center,
          child: Icon(Icons.edit_outlined, size: 18, color: Theme.of(context).primaryColor),
        ),
      ),
    ]);
  }
}
