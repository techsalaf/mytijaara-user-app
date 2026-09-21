import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';
import 'package:sixam_mart/util/dimensions.dart';

class ParcelDeliverToHeaderWidget extends StatelessWidget {
  const ParcelDeliverToHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).cardColor,
      child: Center(
        child: Container(
          width: Dimensions.webMaxWidth,
          padding: const EdgeInsets.fromLTRB(
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeDefault,
            0,
          ),
          child: TitleWidget(title: 'deliver_to'.tr),
        ),
      ),
    );
  }
}
