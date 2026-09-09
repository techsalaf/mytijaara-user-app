import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/parcel/controllers/parcel_controller.dart';
import 'package:sixam_mart/features/parcel/widgets/get_service_video_widget.dart';
import 'package:sixam_mart/features/redesign_feature/global_widgets/bottom_sheet_header_widget.dart';
import 'package:sixam_mart/features/redesign_feature/parcel/screens/parcel_category_screen.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class EasiestWayToGetServicesBottomSheet extends StatelessWidget {
  const EasiestWayToGetServicesBottomSheet({super.key});

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
        final hasMedia = parcelController.videoContentDetails != null
            && (parcelController.videoContentDetails!.bannerVideo != null
                || parcelController.videoContentDetails!.bannerImageFullUrl != null);

        return Column(mainAxisSize: MainAxisSize.min, children: [

          BottomSheetHeaderWidget(title: 'easiest_way_to_get_services'.tr),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
              child: parcelController.videoContentDetails != null ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                if(hasMedia) _MediaContentWidget(parcelController: parcelController, isDesktop: isDesktop),
                if(hasMedia) const SizedBox(height: Dimensions.paddingSizeLarge),

                _NumberedServiceInfoListWidget(parcelController: parcelController),

                const SizedBox(height: Dimensions.paddingSizeDefault),
              ]) : const VideoContentDetailsShimmer(),
            ),
          ),
        ]);
      }),
    );
  }
}

class _MediaContentWidget extends StatelessWidget {
  final ParcelController parcelController;
  final bool isDesktop;
  const _MediaContentWidget({required this.parcelController, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final details = parcelController.videoContentDetails!;

    if (details.bannerType == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        child: CustomImage(image: '${details.bannerImageFullUrl}'),
      );
    }
    if (details.bannerType == 'video') {
      return GetServiceVideoWidget(youtubeVideoUrl: details.bannerVideo ?? '', fileVideoUrl: '');
    }
    return GetServiceVideoWidget(
      youtubeVideoUrl: '',
      fileVideoUrl: '${details.bannerVideoContentFullUrl}',
    );
  }
}

class _NumberedServiceInfoListWidget extends StatelessWidget {
  final ParcelController parcelController;
  const _NumberedServiceInfoListWidget({required this.parcelController});

  @override
  Widget build(BuildContext context) {
    final List<String> titles = [];
    final List<String> subTitles = [];
    final contents = parcelController.videoContentDetails?.bannerContents ?? [];
    for (int i = 0; i < contents.length; i++) {
      if (i % 2 == 0) {
        titles.add(contents[i].value ?? '');
      } else {
        subTitles.add(contents[i].value ?? '');
      }
    }

    if (titles.isEmpty) return const SizedBox();

    final bool isLtr = Get.find<LocalizationController>().isLtr;

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: titles.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final bool isLast = index == titles.length - 1;
        final String? subTitle = index < subTitles.length ? subTitles[index] : null;
        return IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

            Column(children: [
              Container(
                height: 28, width: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                ),
                child: Text(
                  '${index + 1}',
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                ),
              ),

              if(!isLast) Expanded(
                child: Container(
                  width: 1,
                  height: 40,
                  color: Theme.of(context).disabledColor.withValues(alpha: 0.4),
                ),
              ),
            ]),
            const SizedBox(width: Dimensions.paddingSizeDefault),

            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : Dimensions.paddingSizeDefault),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    titles[index],
                    style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                    textAlign: isLtr ? TextAlign.left : TextAlign.right,
                  ),
                  if(subTitle != null && subTitle.isNotEmpty) ...[
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                    Text(
                      subTitle,
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                  ],
                ]),
              ),
            ),
          ]),
        );
      },
    );
  }
}
