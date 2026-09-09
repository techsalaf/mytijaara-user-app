import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/html/controllers/html_controller.dart';
import 'package:sixam_mart/util/html_type.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ProTermsBottomSheetWidget extends StatefulWidget {
  const ProTermsBottomSheetWidget({super.key});

  @override
  State<ProTermsBottomSheetWidget> createState() => _ProTermsBottomSheetWidgetState();
}

class _ProTermsBottomSheetWidgetState extends State<ProTermsBottomSheetWidget> {
  @override
  void initState() {
    super.initState();
    Get.find<HtmlController>().resetHtmlText();
    Get.find<HtmlController>().getHtmlText(HtmlType.proTermsAndCondition);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge)),
      ),
      child: Column(
        children: [
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Row(
            children: [
              const SizedBox(width: 48),
              Expanded(
                child: Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).disabledColor.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Get.back(),
                icon: Icon(Icons.close, color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
            ],
          ),
          GetBuilder<HtmlController>(builder: (htmlController) {
            return Padding(
              padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
              child: Text(
                (htmlController.pageTitle?.isNotEmpty ?? false) ? htmlController.pageTitle! : 'terms_and_condition'.tr,
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
              ),
            );
          }),
          Divider(color: Theme.of(context).disabledColor.withValues(alpha: 0.3), height: 1),
          Expanded(
            child: GetBuilder<HtmlController>(builder: (htmlController) {
              if (htmlController.htmlText == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (htmlController.htmlText!.isEmpty) {
                return Center(
                  child: Text(
                    'no_terms_and_condition_found'.tr,
                    style: robotoRegular.copyWith(color: Theme.of(context).hintColor),
                  ),
                );
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if(htmlController.pageImage?.isNotEmpty ?? false) Padding(
                      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        child: CustomImage(
                          image: htmlController.pageImage!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    HtmlWidget(
                      htmlController.htmlText!,
                      textStyle: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.6)),
                      onTapUrl: (String url) => launchUrlString(url),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
