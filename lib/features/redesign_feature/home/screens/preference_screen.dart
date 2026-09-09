import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class PreferenceScreen extends StatefulWidget {
  const PreferenceScreen({super.key});

  @override
  State<PreferenceScreen> createState() => _PreferenceScreenState();
}

class _PreferenceScreenState extends State<PreferenceScreen> {
  @override
  void initState() {
    super.initState();
    Get.find<CategoryController>().getCategoryList(true, allCategory: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      body: SafeArea(
        child: GetBuilder<CategoryController>(builder: (categoryController) {
          return categoryController.categoryList != null ? categoryController.categoryList!.isNotEmpty ? Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                _topIconButton(context, Icons.arrow_back, () => Get.back()),
                const Spacer(),
                _skipButton(context),
              ]),
              const SizedBox(height: Dimensions.paddingSizeExtraLarge),

              Text('choose_what_you_love'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Text(
                'personalize_home_with_your_choice'.tr,
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor, height: 1.45),
              ),
              const SizedBox(height: Dimensions.paddingSizeExtraLarge),

              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: categoryController.categoryList!.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: Dimensions.paddingSizeLarge,
                    crossAxisSpacing: Dimensions.paddingSizeSmall,
                    childAspectRatio: 0.7,
                  ),
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () => categoryController.addInterestSelection(index),
                      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                      child: Column(children: [
                        Stack(clipBehavior: Clip.none, children: [
                          Container(
                            height: 58, width: 58,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).disabledColor.withValues(alpha: 0.06),
                              border: categoryController.interestSelectedList![index] ? Border.all(color: Theme.of(context).primaryColor, width: 1) : null,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: CustomImage(image: categoryController.categoryList![index].imageFullUrl??'', fit: BoxFit.cover),
                            ),
                          ),
                          categoryController.interestSelectedList![index] ? Positioned(
                            top: 0, right: -2,
                            child: Container(
                              height: 18, width: 18,
                              decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
                              child: Icon(Icons.check, color: Theme.of(context).cardColor, size: 14),
                            ),
                          ) : const SizedBox(),
                        ]),
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        Text(
                          categoryController.categoryList![index].name!,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: robotoRegular.copyWith(
                            color: categoryController.interestSelectedList![index] ? Theme.of(context).textTheme.bodyLarge!.color : Theme.of(context).hintColor,
                            fontSize: Dimensions.fontSizeSmall,
                          ),
                        ),
                      ]),
                    );
                  },
                ),
              ),

              CustomButton(
                buttonText: 'continue'.tr,
                height: 58,
                width: double.infinity,
                radius: Dimensions.radiusDefault,
                fontSize: Dimensions.fontSizeLarge,
                isLoading: categoryController.isLoading,
                onPressed: () {
                  List<int?> interests = [];
                  for(int index=0; index<categoryController.categoryList!.length; index++) {
                    if(categoryController.interestSelectedList![index]) {
                      interests.add(categoryController.categoryList![index].id);
                    }
                  }
                  categoryController.saveInterest(interests).then((isSuccess) {
                    if(isSuccess) {
                      if(ResponsiveHelper.isDesktop(Get.context)) {
                        Get.offAllNamed(RouteHelper.getInitialRoute());
                      } else {
                        Get.back();
                      }
                    }
                  });
                },
              ),
            ]),
          ) : Center(child: Text('no_category_found'.tr)) : const Center(child: CircularProgressIndicator());
        }),
      ),
    );
  }

  Widget _topIconButton(BuildContext context, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        height: 36, width: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).disabledColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        child: Icon(icon, color: Theme.of(context).textTheme.bodyLarge!.color, size: 16),
      ),
    );
  }

  Widget _skipButton(BuildContext context) {
    return InkWell(
      onTap: () => Get.back(),
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
        decoration: BoxDecoration(
          color: Theme.of(context).disabledColor.withValues(alpha: 0.06),
          borderRadius:  BorderRadius.circular(Dimensions.radiusDefault),
        ),
        child: Text('Skip', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge!.color)),
      ),
    );
  }
}