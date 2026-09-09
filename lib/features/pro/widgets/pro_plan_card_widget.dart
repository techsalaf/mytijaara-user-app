import 'package:sixam_mart/features/pro/domain/models/pro_plan_model.dart';
import 'package:sixam_mart/features/pro/widgets/pro_benefit_items.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProPlanCardWidget extends StatelessWidget {
  final ProPlanModel? model;
  const ProPlanCardWidget({super.key, required this.model,});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> benefitItems = ProBenefitItems.fromPlanBenefits(model?.benefits);
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        
        Container(
          decoration: const BoxDecoration(
            color: Color(0xffDFDFFF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(Dimensions.radiusLarge)),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(100),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular( Dimensions.radiusExtraLarge), top: Radius.circular(Dimensions.radiusLarge)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: Dimensions.paddingSizeDefault),
                    Container(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                      decoration: const BoxDecoration(color: Colors.yellow, shape: BoxShape.circle),
                      child: Image.asset(Images.proPlanCrown, width: 36, height: 36),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    Text(
                      model?.proBrand ?? 'sixammart_pro'.tr,
                      style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                    Text(
                      'save_more_on_every_order'.tr,
                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeDefault),
                  ],
                ),
              ),

              if (benefitItems.isNotEmpty) Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: Column(
                  children: [
                    const SizedBox(height: Dimensions.paddingSizeLarge),
                    ...benefitItems.map((item) => _buildBenefitsRow(context, item['title']!, item['subtitle']!)),
                  ],
                ),
              )
            ],
          ),
        )

      ],
    );

    return column;
  }

  Widget _buildBenefitsRow(BuildContext context, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(color: Colors.white , shape: BoxShape.circle),
            child: const Icon(Icons.check, color: Color(0xFF4CAF50), size: 12,),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Colors.black)),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.black)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
