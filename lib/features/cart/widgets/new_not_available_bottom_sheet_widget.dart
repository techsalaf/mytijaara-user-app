import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class NewNotAvailableBottomSheetWidget extends StatefulWidget {
  const NewNotAvailableBottomSheetWidget({super.key});

  @override
  State<NewNotAvailableBottomSheetWidget> createState() => _NewNotAvailableBottomSheetWidgetState();
}

class _NewNotAvailableBottomSheetWidgetState extends State<NewNotAvailableBottomSheetWidget> {
  int selectIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 550,
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: Align(alignment: Alignment.topRight,
            child: InkWell(
              onTap: () => Get.back(),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 18),
              ),
            ),
          ),
        ),


        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
          child: Align(alignment: Alignment.topLeft, child: Text('if_any_product_is_not_available'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge))),
        ),
        const SizedBox(height: Dimensions.paddingSizeLarge),

        GetBuilder< CartController>(
          builder: (cartController) {
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cartController.notAvailableList.length,
              itemBuilder: (context, index){
                bool isSelected = selectIndex == index;
                return InkWell(
                onTap: () {
                  setState(() {
                    selectIndex = index;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeExtraSmall),
                  child: Row(children: [
                    Expanded(
                      child: Text(
                        cartController.notAvailableList[index].tr,
                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyMedium!.color),
                      ),
                    ),
                    Radio(
                      value: index,
                      groupValue: selectIndex,
                      activeColor: Theme.of(context).primaryColor,
                      onChanged: (int? value) {
                        setState(() {
                          selectIndex = value!;
                        });
                      },
                    ),
                  ]),
                ),
              );
              }
            );
          }
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
          child: SafeArea(
            child: CustomButton(
              buttonText: 'apply'.tr,
              onPressed: selectIndex == -1 ? null : () {
                Get.find< CartController>().setAvailableIndex(selectIndex);
                Get.back();
              },
            ),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault)
      ]),
    );
  }
}
