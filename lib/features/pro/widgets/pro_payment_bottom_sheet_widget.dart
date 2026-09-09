import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/pro/controllers/pro_controller.dart';
import 'package:sixam_mart/features/pro/domain/models/pro_plan_model.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProPaymentBottomSheetWidget extends StatefulWidget {
  final PlanItem plan;
  final bool isRenew;
  const ProPaymentBottomSheetWidget({super.key, required this.plan, this.isRenew = false});

  @override
  State<ProPaymentBottomSheetWidget> createState() => _ProPaymentBottomSheetWidgetState();
}

class _ProPaymentBottomSheetWidgetState extends State<ProPaymentBottomSheetWidget> {
  int _selectedDigitalIndex = -1;

  @override
  Widget build(BuildContext context) {
    final double totalPrice = widget.plan.price ?? 0;
    final double walletBalance = Get.find<ProfileController>().userInfoModel?.walletBalance ?? 0;
    final bool canPayWallet = walletBalance >= totalPrice;
    final bool hasWallet = Get.find<SplashController>().configModel!.customerWalletStatus == 1;
    final bool hasDigital = Get.find<SplashController>().configModel!.digitalPayment! && Get.find<SplashController>().configModel!.activePaymentMethodList!.isNotEmpty;
    final paymentMethods = Get.find<SplashController>().configModel!.activePaymentMethodList!;

    return SizedBox(
      width: 550,
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.vertical(top: const Radius.circular(Dimensions.radiusLarge), bottom: Radius.circular(ResponsiveHelper.isDesktop(context) ? Dimensions.radiusLarge : 0)),
        ),
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (!ResponsiveHelper.isDesktop(context))
                Container(
                  height: 5, width: 40,
                  decoration: BoxDecoration(color: Theme.of(context).disabledColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(10)),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () => Get.back(),
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    height: 30, width: 30,
                    decoration: BoxDecoration(color: Theme.of(context).disabledColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(50)),
                    child: Icon(Icons.clear, size: 18, color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),

          Text('choose_payment_method'.tr, style: robotoBold),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Text('total_bill'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
          Text(PriceConverter.convertPrice(totalPrice), style: robotoBold.copyWith(fontSize: 24, color: Theme.of(context).primaryColor)),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          Flexible(
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if(!hasWallet && !hasDigital) Text('no_payment_method_is_enabled'.tr, style: robotoRegular.copyWith(color: Theme.of(context).hintColor)),

                if(hasWallet) Container(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('wallet_balance'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
                      Text(PriceConverter.convertPrice(walletBalance), style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
                    ])),
                    OutlinedButton(
                      onPressed: () {
                        if(!canPayWallet) {
                          showCustomSnackBar('you_do_not_have_sufficient_balance_in_wallet'.tr);
                          return;
                        }
                        Get.back();
                        Get.find<ProController>().subscribePlan(widget.plan, 'wallet', 'wallet', widget.isRenew);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Theme.of(context).primaryColor),
                        foregroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
                      ),
                      child: Text('apply'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).primaryColor)),
                    ),
                  ]),
                ),

                if(hasDigital) ...[
                  SizedBox(height: Dimensions.paddingSizeLarge,),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                      border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.2)),
                    ),
                    padding: EdgeInsets.only(left: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeSmall),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: Dimensions.paddingSizeDefault),
                        Text('pay_via_online'.tr, style: robotoSemiBold),
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: paymentMethods.length,
                          itemBuilder: (context, index) {
                            final paymentMethod = paymentMethods[index];
                            final bool isSelected = _selectedDigitalIndex == index;
                            return InkWell(
                              onTap: () => setState(() => _selectedDigitalIndex = index),
                              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                                child: Row(children: [
                                  CustomImage(height: 20, width: 40, fit: BoxFit.contain, image: paymentMethod.getWayImageFullUrl ?? ''),
                                  const SizedBox(width: Dimensions.paddingSizeSmall),
                                  Expanded(child: Text(paymentMethod.getWayTitle ?? '', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault))),
                                  Container(
                                    width: 22, height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                                      border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).disabledColor.withValues(alpha: 0.5), width: 1.5),
                                    ),
                                    child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                                  ),
                                ]),
                              ),
                            );
                          },
                        ),
                      ])
                  )
                ]
              ]),
            ),
          ),

          if(hasDigital) ...[
            const SizedBox(height: Dimensions.paddingSizeDefault),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedDigitalIndex == -1 ? null : () {
                  final paymentMethod = paymentMethods[_selectedDigitalIndex];
                  Get.back();
                  Get.find<ProController>().subscribePlan(widget.plan, 'digital_payment', paymentMethod.getWay ?? '', widget.isRenew);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  disabledBackgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
                  elevation: 0,
                ),
                child: Text('proceed'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Colors.white)),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
