import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/single_deal_widget.dart';
import 'package:sixam_mart/features/redesign_feature/parcel/widget/easiest_way_to_get_services_bottom_sheet.dart';
import 'package:sixam_mart/util/images.dart';

class NeedHelpToGettingStartWidget extends StatelessWidget {
  const NeedHelpToGettingStartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleDealWidget(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          builder: (_) => const EasiestWayToGetServicesBottomSheet(),
        );
      },
      beginColor: Colors.blueAccent.withAlpha(50),
      endColor: Colors.blueAccent.withAlpha(20),
      title: 'need_help_to_getting_started'.tr,
      subTitle: 'take_a_quick_tour_to_see_how_it_works'.tr,
      image: Images.bookIcon,
    );
  }
}
