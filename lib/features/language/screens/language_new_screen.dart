import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/language/screens/web_language_screen.dart';
import 'package:sixam_mart/features/onboard/screens/onboarding_new_screen.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';


class ChooseLanguageNewScreen extends StatefulWidget {
  final bool fromMenu;
  const ChooseLanguageNewScreen({super.key, this.fromMenu = false});

  @override
  State<ChooseLanguageNewScreen> createState() => _ChooseLanguageNewScreenState();
}

class _ChooseLanguageNewScreenState extends State<ChooseLanguageNewScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: (widget.fromMenu || ResponsiveHelper.isDesktop(context)) ? CustomAppBar(title: 'language'.tr, backButton: true) : null,
      endDrawer: const MenuDrawer(),
      endDrawerEnableOpenDragGesture: false,
      backgroundColor: Theme.of(context).disabledColor.withValues(alpha: 0.08),
      body: GetBuilder<LocalizationController>(
        builder: (localizationController) {
          return ResponsiveHelper.isDesktop(context) ? const WebLanguageScreen()
          : Column(children: [
              Expanded(flex: 4,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraLarge,),
                    child: SvgPicture.asset(Images.onBoard, height: context.height * 0.3, fit: BoxFit.contain),
                  ),
                ),
              ),

              Expanded(
                flex: 5,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(26), topRight: Radius.circular(26)),
                  ),
                  child: SafeArea(top: false,
                    child: Column(children: [
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      Text(
                        'select_language'.tr,
                        style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                      Text('choose_your_language_to_proceed'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),

                      const SizedBox(height: 24),

                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: localizationController.languages.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final bool isSelected = localizationController.selectedLanguageIndex == index;
                            return _LanguageOptionTile(
                              imageUrl: localizationController.languages[index].imageUrl ?? '',
                              title: _languageDisplayName(
                                localizationController.languages[index].languageName ?? '',
                              ),
                              selected: isSelected,
                              onTap: () => localizationController.setSelectLanguageIndex(index),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 12),
                      CustomButton(
                        buttonText: 'Continue',
                        height: 40,
                        radius: Dimensions.radiusDefault,
                        fontSize: Dimensions.fontSizeLarge,
                        onPressed: () {
                          if (localizationController.languages.isNotEmpty && localizationController.selectedLanguageIndex != -1) {
                            localizationController.setLanguage(
                              Locale(
                                AppConstants.languages[localizationController.selectedLanguageIndex].languageCode!,
                                AppConstants.languages[localizationController.selectedLanguageIndex].countryCode,
                              ),
                            );
                            if (widget.fromMenu) {
                              Navigator.pop(context);
                            } else {
                              Get.to(
                                () =>  const OnBoardingNewScreen(),
                                transition: Transition.downToUp,
                                duration: const Duration(milliseconds: 300)
                              );
                            }
                          } else {
                            showCustomSnackBar('select_a_language'.tr);
                          }
                        },
                      ),
                    ]),
                  ),
                ),
              ),
            ]);
        },
      ),
    );
  }

  String _languageDisplayName(String name) {
    if (name.toLowerCase() == 'english') {
      return 'English - Abc';
    }
    if (name.toLowerCase() == 'bengali') {
      return 'Bengali - বাংলা';
    }
    return name;
  }
}

class _LanguageOptionTile extends StatelessWidget {
  final String imageUrl;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOptionTile({required this.imageUrl, required this.title, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            border: Border.all(color: selected ? Theme.of(context).disabledColor.withValues(alpha: 0.3) : Colors.transparent, width: 1),
          ),
          child: Row(children: [

               Container(
                  height: 30, width: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: ClipRRect(borderRadius: BorderRadius.circular(50),
                  child: Image.asset(imageUrl, height: 30, width: 30, fit: BoxFit.fill)),

              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),

              Expanded(
                child: Text(title,
                  style: (selected ? robotoMedium : robotoRegular).copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: selected ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).disabledColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              _LanguageRadio(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageRadio extends StatelessWidget {
  final bool selected;

  const _LanguageRadio({required this.selected});

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? Theme.of(context).primaryColor : Theme.of(context).disabledColor.withValues(alpha: 0.5);

    return Container(width: 20, height: 20,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color)),
      child: selected ? Center(
        child: Container(width: 11, height: 11, decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),),
      ) : null,
    );
  }
}
