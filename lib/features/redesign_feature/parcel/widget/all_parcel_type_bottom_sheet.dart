import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/parcel/controllers/parcel_controller.dart';
import 'package:sixam_mart/features/redesign_feature/global_widgets/bottom_sheet_header_widget.dart';
import 'package:sixam_mart/features/redesign_feature/parcel/widget/parcel_category_card_widget.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';

class AllParcelTypeBottomSheet extends StatelessWidget {
  const AllParcelTypeBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);
    return Container(
      width: 550,
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge)),
      ),
      child: GetBuilder<ParcelController>(builder: (parcelController) {
        final categories = parcelController.parcelCategoryList ?? [];
        return Column(mainAxisSize: MainAxisSize.min, children: [

          BottomSheetHeaderWidget(title: 'all_parcel_type'.tr),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isDesktop ? 3 : 2,
                  crossAxisSpacing: Dimensions.paddingSizeSmall,
                  mainAxisSpacing: Dimensions.paddingSizeSmall,
                  mainAxisExtent: 90,
                ),
                itemCount: categories.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  return ParcelCategoryCardWidget(
                    image: '${categories[index].imageFullUrl}',
                    itemName: categories[index].name ?? '',
                    description: categories[index].description ?? '',
                    colorIndex: index,
                    onTap: () {
                      Get.back();
                      if (AddressHelper.getUserAddressFromSharedPref() == null) {
                        Get.find<LocationController>().navigateToLocationScreen('home', canRoute: true);
                        return;
                      }
                      Get.toNamed(RouteHelper.getParcelLocationRoute(categories[index]));
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
        ]);
      }),
    );
  }
}
