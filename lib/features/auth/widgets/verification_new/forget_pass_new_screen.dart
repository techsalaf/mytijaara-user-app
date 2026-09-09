import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/custom_text_field.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/verification/controllers/verification_controller.dart';
import 'package:sixam_mart/features/verification/screens/verification_screen.dart';
import 'package:sixam_mart/helper/custom_validator.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/helper/validate_check.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class ForgetPassNewScreen extends StatefulWidget {
  final bool fromDialog;
  const ForgetPassNewScreen({super.key, this.fromDialog = false});

  @override
  State<ForgetPassNewScreen> createState() => _ForgetPassNewScreenState();
}

class _ForgetPassNewScreenState extends State<ForgetPassNewScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _numberFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  String? _countryDialCode = CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).dialCode;
  GlobalKey<FormState>? _formKeyLogin;
  bool isEmail = false;
  bool isPhone = false;

  @override
  void initState() {
    super.initState();

    isPhone = (Get.find<SplashController>().configModel!.isSmsActive! || Get.find<SplashController>().configModel!.firebaseOtpVerification!);
    isEmail = Get.find<SplashController>().configModel!.isMailActive!;

    _formKeyLogin = GlobalKey<FormState>();
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 800), () {
          FocusScope.of(Get.context!).requestFocus(_numberFocusNode);
        });
      });
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _numberFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);
    return Scaffold(
      backgroundColor: isDesktop ? Colors.transparent : Theme.of(context).colorScheme.surface,
      body: SafeArea(child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          height: widget.fromDialog ? 600 : null,
          width: widget.fromDialog ? 475 : context.width > 700 ? 500 : context.width,
          padding: context.width > 700 ? const EdgeInsets.all(50) : const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          margin: context.width > 700 && !widget.fromDialog ? const EdgeInsets.all(50) : EdgeInsets.zero,
          decoration: context.width > 700 ? BoxDecoration(
            color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            boxShadow: isDesktop ? null : const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
          ) : null,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const SizedBox(height: Dimensions.paddingSizeLarge),
              isDesktop || widget.fromDialog ? Align(
                alignment: Alignment.topRight,
                child: IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.clear)),
              ) : Row(children: [
                InkWell(
                  onTap: () => Get.back(),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0, top: 8.0, bottom: 8.0),
                    child: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.bodyLarge!.color, size: 16),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => Get.back(),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0, top: 8.0, bottom: 8.0),
                    child: Icon(Icons.close, color: Theme.of(context).textTheme.bodyLarge!.color, size: 16),
                  ),
                ),
              ]),
              const SizedBox(height: Dimensions.paddingSizeLarge),

              (isPhone || isEmail) ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isPhone ? 'use_mail_phone_for_recovery'.tr : 'use_mail_mail_for_recovery'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
                Text(
                  isPhone ? 'please_enter_registered_phone'.tr : 'please_enter_registered_email'.tr,
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),

                Container(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusLarge)),
                    boxShadow: [BoxShadow(color: Colors.grey[Get.isDarkMode ? 400 : 200]!, spreadRadius: 1, blurRadius: 5, offset: const Offset(2, 2))],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Form(
                      key: _formKeyLogin,
                      child: isPhone ? CustomTextField(
                        titleText: 'type_your_number'.tr,
                        controller: _numberController,
                        focusNode: _numberFocusNode,
                        inputType: TextInputType.phone,
                        inputAction: TextInputAction.done,
                        isPhone: true,
                        onCountryChanged: (CountryCode countryCode) {
                          _countryDialCode = countryCode.dialCode;
                        },
                        countryDialCode: CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).code ?? Get.find<LocalizationController>().locale.countryCode,
                        onSubmit: (text) => GetPlatform.isWeb ? _onPressedForgetPass(_countryDialCode!) : null,
                        labelText: 'phone'.tr,
                        validator: (value) => ValidateCheck.validateEmptyText(value, null),
                      ) : CustomTextField(
                        titleText: 'type_your_mail'.tr,
                        labelText: 'email'.tr,
                        showLabelText: true,
                        required: true,
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        inputType: TextInputType.emailAddress,
                        inputAction: TextInputAction.done,
                        prefixIcon: CupertinoIcons.mail_solid,
                        validator: (value) => ValidateCheck.validateEmail(value),
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                    GetBuilder<VerificationController>(builder: (verificationController) {
                      return GetBuilder<AuthController>(builder: (authController) {
                        return CustomButton(
                          radius: Dimensions.radiusDefault,
                          buttonText: 'get_otp'.tr,
                          isLoading: verificationController.isLoading || authController.isLoading,
                          onPressed: () => _onPressedForgetPass(_countryDialCode!),
                        );
                      });
                    }),

                    const SizedBox(height: Dimensions.paddingSizeLarge),
                  ]),
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),

                // Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                //   Text('new_to_6amMart'.tr, style: robotoRegular.copyWith(color: Theme.of(context).hintColor)),
                //   InkWell(
                //     onTap: () => Get.toNamed(RouteHelper.getSignUpRoute()),
                //     child: Padding(
                //       padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                //       child: Text('sign_up'.tr, style: robotoMedium.copyWith(color: Theme.of(context).primaryColor)),
                //     ),
                //   ),
                // ]),

              ]) : Padding(
                padding: widget.fromDialog ? const EdgeInsets.all(Dimensions.paddingSizeExtremeLarge) : context.width > 700 ? const EdgeInsets.all(Dimensions.paddingSizeDefault) : const EdgeInsets.all(Dimensions.paddingSizeLarge),
                child: Column(children: [

                  Image.asset(Images.forgot, height:  widget.fromDialog ? 160 : 220),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
                    child: Text('sorry_something_went_wrong'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge), textAlign: TextAlign.center),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                    child: Text(
                      'please_try_again_after_some_time_or_contact_with_our_support_team'.tr,
                      style: robotoRegular.copyWith(fontSize: widget.fromDialog ? Dimensions.fontSizeSmall : null, color: Theme.of(context).hintColor), textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeExtremeLarge),

                  CustomButton(
                    buttonText: 'help_and_support'.tr,
                    onPressed: () {
                      Get.toNamed(RouteHelper.getSupportRoute());
                    }
                  ),
                  const SizedBox(height: Dimensions.paddingSizeLarge),

                  RichText(text: TextSpan(children: [
                    TextSpan(
                      text: '${'continue_as'.tr} ',
                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor),
                    ),
                    TextSpan(
                      text: 'guest'.tr, style: robotoMedium.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeDefault, decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => Get.offAllNamed(RouteHelper.getInitialRoute()),
                    ),
                  ]), textAlign: TextAlign.center, maxLines: 3),

                ]),
              ),
              RichText(text: TextSpan(children: [
                TextSpan(
                  text: '${'back_to'.tr} ',
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge!.color),
                ),
                TextSpan(
                  text: 'login_in'.tr, style: robotoMedium.copyWith(color: Colors.blueAccent, fontSize: Dimensions.fontSizeDefault, decoration: TextDecoration.underline),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => Get.back(),
                ),
              ]), textAlign: TextAlign.center, maxLines: 3),
            ]),
          ),
        ),
      )),
    );
  }

  void _onPressedForgetPass(String countryCode) async {
    String phone = _numberController.text.trim();
    String email = _emailController.text.trim();

    String numberWithCountryCode = countryCode+phone;
    PhoneValid phoneValid = await CustomValidator.isPhoneValid(numberWithCountryCode);
    numberWithCountryCode = phoneValid.phone;

    if(_formKeyLogin!.currentState!.validate()) {
      if (!phoneValid.isValid && !isEmail) {
        showCustomSnackBar('invalid_phone_number'.tr);
      } else {
        Get.find<VerificationController>().forgetPassword(email: email, phone: numberWithCountryCode).then((status) async {
          if (status.isSuccess) {
            if(Get.find<SplashController>().configModel!.centralizeLoginSetup!.phoneVerificationStatus! && Get.find<SplashController>().configModel!.firebaseOtpVerification!) {
              Get.find<AuthController>().firebaseVerifyPhoneNumber(numberWithCountryCode, status.message, '', fromSignUp: false);
            } else {
              if(ResponsiveHelper.isDesktop(Get.context)) {
                Get.back();
                Get.dialog(VerificationScreen(
                  number: numberWithCountryCode, email: email, token: '', fromSignUp: false,
                  fromForgetPassword: true, loginType: '', password: '',
                ));
              } else {
                Get.toNamed(RouteHelper.getVerificationRoute(numberWithCountryCode, email, '', RouteHelper.forgotPassword, '', ''));
              }
            }
          }else {
            showCustomSnackBar(status.message);
          }
        });
      }
    }
  }
}
