import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/common/models/config_model.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/features/checkout/widgets/slot_widget.dart';

class TimeSlotBottomSheet extends StatefulWidget {
  final bool tomorrowClosed;
  final bool todayClosed;
  final Module? module;
  const TimeSlotBottomSheet({super.key, required this.tomorrowClosed, required this.todayClosed, required this.module});

  @override
  State<TimeSlotBottomSheet> createState() => _TimeSlotBottomSheetState();
}

class _TimeSlotBottomSheetState extends State<TimeSlotBottomSheet> {

  int selectedTimeSlotIndex = 0;
  String selectedTimeSlot = '';

  @override
  void initState() {
    super.initState();
    selectedTimeSlotIndex = Get.find<CheckoutController>().selectedTimeSlot;
    selectedTimeSlot = Get.find<CheckoutController>().preferableTime;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CheckoutController>(builder: (checkoutController) {
      return GetBuilder<StoreController>(builder: (storeController) {
        return Container(
          width: ResponsiveHelper.isDesktop(context) ? 550 : context.width,
          constraints: BoxConstraints(maxHeight: context.height * 0.8, minHeight: 0),
          margin: EdgeInsets.only(top: GetPlatform.isWeb ? 0 : 30),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: ResponsiveHelper.isMobile(context) ?
              const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge))
              : const BorderRadius.all(Radius.circular(Dimensions.radiusDefault)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // !ResponsiveHelper.isDesktop(context) ? Container(
                //   height: 4, width: 35,
                //   margin: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                //   decoration: BoxDecoration(color: Theme.of(context).disabledColor.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(10)),
                // ) : const SizedBox(),

                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10.0, right: 10),
                    child: InkWell(
                      onTap: () => Get.back(),
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                        decoration: BoxDecoration(color: Theme.of(context).disabledColor.withValues(alpha: 0.12), shape: BoxShape.circle),
                        child: Icon(Icons.close, size: 18, color: Theme.of(context).disabledColor),
                      ),
                    ),
                  ),
                ),

                /// Header — title, subtitle & close button
                Padding(
                  padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, 0, Dimensions.paddingSizeLarge, 0),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('select_your_time_slot'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                        const SizedBox(height: 2),
                        Text(
                          'choose_preferable_time_when_you_want_delivery'.tr,
                          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                        ),
                      ]),
                    ),

                  ]),
                ),

                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, Dimensions.paddingSizeDefault, Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [

                      Row(children: [
                        Expanded(
                          child: tabView(context:context, title: 'today'.tr, isSelected: checkoutController.selectedDateSlot == 0, onTap: (){
                            checkoutController.updateDateSlot(0, Get.find<StoreController>().store!.orderPlaceToScheduleInterval);
                          }),
                        ),

                        Expanded(
                          child: tabView(context:context, title: 'tomorrow'.tr, isSelected: checkoutController.selectedDateSlot == 1, onTap: (){
                            checkoutController.updateDateSlot(1, Get.find<StoreController>().store!.orderPlaceToScheduleInterval);
                          }),
                        ),
                      ]),
                      // const SizedBox(height: Dimensions.paddingSizeSmall),

                      Flexible(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                          decoration: BoxDecoration(
                            color: Theme.of(context).disabledColor.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          ),
                          child: ((checkoutController.selectedDateSlot == 0 && widget.todayClosed) || (checkoutController.selectedDateSlot == 1 && widget.tomorrowClosed))
                            ? Center(child: Text(widget.module!.showRestaurantText! ? 'restaurant_is_closed'.tr : 'store_is_closed'.tr))
                            : checkoutController.timeSlots != null
                            ? checkoutController.timeSlots!.isNotEmpty ? GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: ResponsiveHelper.isDesktop(context) ? 3 : 2,
                              mainAxisSpacing: Dimensions.paddingSizeSmall,
                              crossAxisSpacing: Dimensions.paddingSizeSmall,
                              // childAspectRatio: ResponsiveHelper.isDesktop(context) ? 4 : ResponsiveHelper.isMobile(context) ? 2.2 : 3,
                              mainAxisExtent: 40,
                            ),
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: checkoutController.timeSlots!.length,
                            itemBuilder: (context, index){
                              String time = (index == 0 && checkoutController.selectedDateSlot == 0
                                  && storeController.isStoreOpenNow(storeController.store!.active!, storeController.store!.schedules)
                                  && (Get.find<SplashController>().configModel!.moduleConfig!.module!.orderPlaceToScheduleInterval! ? storeController.store!.orderPlaceToScheduleInterval == 0 : true))
                                  ? 'instance'.tr : '${DateConverter.dateToTimeOnly(checkoutController.timeSlots![index].startTime!)} '
                                  '- ${DateConverter.dateToTimeOnly(checkoutController.timeSlots![index].endTime!)}';
                              return SlotWidget(
                                title: time,
                                isSelected: selectedTimeSlotIndex == index,
                                onTap: () {
                                  setState(() {
                                    selectedTimeSlotIndex = index;
                                    selectedTimeSlot = time;
                                  });
                                },
                              );
                            }) : Center(child: Text('no_slot_available'.tr)) : const Center(child: CircularProgressIndicator()),
                        ),
                      ),

                    ]),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraLarge, vertical: Dimensions.paddingSizeSmall),
                child: Row(children: [
                  Expanded(
                    child: CustomButton(
                      radius: ResponsiveHelper.isDesktop(context) ?  Dimensions.radiusSmall : Dimensions.radiusDefault,
                      height: ResponsiveHelper.isDesktop(context) ? 50 : null,
                      isBold:  ResponsiveHelper.isDesktop(context) ? false : true,
                      buttonText: 'cancel'.tr,
                      color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
                      textColor: Theme.of(context).textTheme.bodyLarge!.color,
                      onPressed: () => Get.back(),
                    ),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),

                  Expanded(
                    child: CustomButton(
                      radius: ResponsiveHelper.isDesktop(context) ?  Dimensions.radiusSmall : Dimensions.radiusDefault,
                      height: ResponsiveHelper.isDesktop(context) ? 50 : null,
                      isBold:  ResponsiveHelper.isDesktop(context) ? false : true,
                      buttonText: 'confirm_schedule'.tr,
                      onPressed: () {
                        checkoutController.updateTimeSlot(selectedTimeSlotIndex);
                        checkoutController.setPreferenceTimeForView(selectedTimeSlot);

                        DateTime scheduleEndDate = DateTime.now();

                        DateTime date = checkoutController.selectedDateSlot == 0 ? DateTime.now() : DateTime.now().add(const Duration(days: 1));
                        DateTime endTime = checkoutController.timeSlots![checkoutController.selectedTimeSlot].endTime!;
                        scheduleEndDate = DateTime(date.year, date.month, date.day, endTime.hour, endTime.minute+1);

                        checkoutController.getSurgePrice(
                          zoneId: checkoutController.store!.zoneId.toString(),
                          moduleId: checkoutController.store!.moduleId.toString(),
                          dateTime: DateConverter.dateToDateAndTime(scheduleEndDate),
                          guestId: AuthHelper.getGuestId(),
                        );
                        Get.back();
                      },
                    ),
                  ),
                ]),
              )],
            ),
          ),
        );
      });
    });
  }

  Widget tabView({required BuildContext context, required String title, required bool isSelected, required Function() onTap}){
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(title, style: robotoBold.copyWith(color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.5))),
          ResponsiveHelper.isDesktop(context) ? const SizedBox(height: Dimensions.paddingSizeSmall) : const SizedBox(height: Dimensions.paddingSizeSmall),
          Divider(color: isSelected ? Theme.of(context).primaryColor : Colors.transparent, thickness: isSelected ? 2 : 1, height: 0,),
        ],
      ),
    );
  }

}
