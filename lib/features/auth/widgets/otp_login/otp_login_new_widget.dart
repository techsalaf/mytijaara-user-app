import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_text_field.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/auth/widgets/social_login_widget.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/helper/validate_check.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class OtpLoginNewWidget extends StatelessWidget {
  final TextEditingController phoneController;
  final FocusNode phoneFocus;
  final String? countryDialCode;
  final Function(CountryCode countryCode)? onCountryChanged;
  final Function() onClickLoginButton;
  final bool socialEnable;
  final bool backFromThis;
  const OtpLoginNewWidget({super.key, required this.phoneController, required this.phoneFocus, required this.onCountryChanged, required this.countryDialCode,
    required this.onClickLoginButton, this.socialEnable = false, required this.backFromThis});

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);
    return GetBuilder<AuthController>(builder: (authController) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? Dimensions.paddingSizeLarge : 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('login_with_phone'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraLarge)) ,
          Text('use_your_registered_email_phone_number_to_get_otp'.tr, 
          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)) ,
          const SizedBox(height: Dimensions.paddingSizeLarge),

          Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusLarge)),
              boxShadow: [BoxShadow(color: Colors.grey[Get.isDarkMode ? 400 : 200]!, spreadRadius: 1, blurRadius: 5, offset: const Offset(2, 2))],
            ), 
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              CustomTextField(
                titleText: 'xxx-xxx-xxxxx'.tr,
                controller: phoneController,
                focusNode: phoneFocus,
                inputAction: TextInputAction.done,
                inputType: TextInputType.phone,
                isPhone: true,
                onCountryChanged: onCountryChanged,
                countryDialCode: countryDialCode ?? Get.find<LocalizationController>().locale.countryCode,
                labelText: 'phone'.tr,
                required: true,
                validator: (value) => ValidateCheck.validateEmptyText(value, "please_enter_phone_number".tr),
              ),
              const SizedBox(height: Dimensions.paddingSizeExtraLarge),

              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () => authController.toggleRememberMeOtp(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 24, width: 24,
                        child: Checkbox(
                          side: BorderSide(color: Theme.of(context).hintColor),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          activeColor: Theme.of(context).primaryColor,
                          value: authController.isActiveRememberMeOtp,
                          onChanged: (bool? isChecked) => authController.toggleRememberMeOtp(),
                        ),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeSmall),

                      Text('remember_me'.tr, style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color?.withAlpha(130))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),

              // const ConditionCheckBoxWidget(forSignUp: true),
              // const SizedBox(height: Dimensions.paddingSizeLarge),

            CustomButton(
              buttonText: 'get_otp'.tr,
              radius: Dimensions.radiusLarge,
              isBold: isDesktop ? false : true,
              isLoading: authController.isLoading,
              onPressed: onClickLoginButton,
              fontSize: isDesktop ? Dimensions.fontSizeSmall : Dimensions.fontSizeDefault,
            ),
            ]),
          ),
          
          const SizedBox(height: Dimensions.paddingSizeLarge),

          socialEnable ? SocialLoginWidget(onlySocialLogin: false, backFromThis: backFromThis) : const SizedBox(),

          socialEnable && isDesktop ? const SizedBox(height: Dimensions.paddingSizeLarge) : const SizedBox(),

          !socialEnable ? const SizedBox(height: 20) : const SizedBox(),

          if (Get.find<SplashController>().configModel!.centralizeLoginSetup!.manualLoginStatus!)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('new_to_6amMart'.tr, style: robotoRegular.copyWith(color: Theme.of(context).hintColor)),

              InkWell(
                onTap: authController.isLoading ? null : () {
                  Get.toNamed(RouteHelper.getSignUpRoute());
                },
                child: Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                  child: Text('sign_up'.tr, style: robotoMedium.copyWith(color: Colors.blueAccent)),
                ),
              ),
            ]),

        ]),
      );
    });
  }
}
