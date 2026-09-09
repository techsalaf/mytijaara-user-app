import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_text_field.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/validate_check.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';


class SignUpNewWidget extends StatefulWidget {
  final String? referCode;
  final GlobalKey<FormState>? formKey;
  final void Function(String countryCode)? onRegister;

  const SignUpNewWidget({super.key, this.referCode, this.formKey, this.onRegister});

  @override
  SignUpNewWidgetState createState() => SignUpNewWidgetState();
}

class SignUpNewWidgetState extends State<SignUpNewWidget> {
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();
  final FocusNode _referCodeFocus = FocusNode();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _referCodeController = TextEditingController();
  String? _countryDialCode;
  GlobalKey<FormState>? _formKeySignUp;

  @override
  void initState() {
    super.initState();
    _formKeySignUp = widget.formKey ?? GlobalKey<FormState>();
    _countryDialCode = CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).dialCode;
    if(widget.referCode != null) {
      _referCodeController.text = widget.referCode!;
    }
  }

  String get countryDialCode => _countryDialCode ?? '';
  TextEditingController get nameController => _nameController;
  TextEditingController get emailController => _emailController;
  TextEditingController get phoneController => _phoneController;
  TextEditingController get passwordController => _passwordController;
  TextEditingController get confirmPasswordController => _confirmPasswordController;
  TextEditingController get referCodeController => _referCodeController;
  GlobalKey<FormState>? get formKey => _formKeySignUp;


  @override
  Widget build(BuildContext context) {
    bool referralEnable = Get.find<SplashController>().configModel!.refEarningStatus == 1;
    return Form(
      key: _formKeySignUp,
      child: GetBuilder<AuthController>(builder: (authController) {
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusLarge)),
              boxShadow: [BoxShadow(color: Colors.grey[Get.isDarkMode ? 400 : 200]!, spreadRadius: 1, blurRadius: 5, offset: const Offset(2, 2))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _fieldTitle(context, 'Name', required: true),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              CustomTextField(
                titleText: 'Ex: Mallory Smith',
                labelText: 'name'.tr,
                showLabelText: false,
                required: true,
                controller: _nameController,
                focusNode: _nameFocus,
                nextFocus: _phoneFocus,
                inputType: TextInputType.name,
                capitalization: TextCapitalization.words,
                validator: (value) => ValidateCheck.validateEmptyText(value, "please_enter_your_name".tr),
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),

              _fieldTitle(context, 'phone_number'.tr, required: true),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              CustomTextField(
                titleText: '+1 (555) 000-0000',
                labelText: 'phone_number'.tr,
                showLabelText: false,
                required: true,
                controller: _phoneController,
                focusNode: _phoneFocus,
                nextFocus: _emailFocus,
                inputType: TextInputType.phone,
                isPhone: true,
                onCountryChanged: (CountryCode countryCode) {
                  _countryDialCode = countryCode.dialCode;
                },
                countryDialCode: _countryDialCode != null ? CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).code
                    : Get.find<LocalizationController>().locale.countryCode,
                validator: (value) => ValidateCheck.validateEmptyText(value, "please_enter_phone_number".tr),
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),

              _fieldTitle(context, 'Email', required: true),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              CustomTextField(
                titleText: 'olivia@untitledui.com',
                labelText: 'email'.tr,
                showLabelText: false,
                required: true,
                controller: _emailController,
                focusNode: _emailFocus,
                nextFocus: _passwordFocus,
                inputType: TextInputType.emailAddress,
                prefixIcon: CupertinoIcons.mail,
                validator: (value) => ValidateCheck.validateEmail(value),
                divider: false,
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),

              _fieldTitle(context, 'Password', required: true),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              CustomTextField(
                titleText: 'password_hint'.tr,
                labelText: 'password'.tr,
                showLabelText: false,
                required: true,
                controller: _passwordController,
                focusNode: _passwordFocus,
                nextFocus: _confirmPasswordFocus,
                inputType: TextInputType.visiblePassword,
                isPassword: true,
                validator: (value) => ValidateCheck.validateEmptyText(value, "please_enter_password".tr),
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),

              _fieldTitle(context, 'Confirm Password', required: true),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              CustomTextField(
                titleText: 'password_hint'.tr,
                labelText: 'confirm_password'.tr,
                showLabelText: false,
                required: true,
                controller: _confirmPasswordController,
                focusNode: _confirmPasswordFocus,
                nextFocus: referralEnable ? _referCodeFocus : null,
                inputAction: referralEnable ? TextInputAction.next : TextInputAction.done,
                inputType: TextInputType.visiblePassword,
                isPassword: true,
                validator: (value) => ValidateCheck.validateConfirmPassword(value, _passwordController.text),
              ),

              referralEnable ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: Dimensions.paddingSizeLarge),
                _fieldTitle(context, 'Use Referral Code (Optional)'),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                CustomTextField(
                  titleText: 'Ex: 4894HUI65',
                  labelText: 'refer_code'.tr,
                  showLabelText: false,
                  controller: _referCodeController,
                  focusNode: _referCodeFocus,
                  inputAction: TextInputAction.done,
                  inputType: TextInputType.text,
                  capitalization: TextCapitalization.words,
                  divider: false,
                ),
              ]) : const SizedBox(),
            ]),
          ),
        ]);
      }),
    );
  }

  Widget _fieldTitle(BuildContext context, String title, {bool required = false}) {
    return Text.rich(TextSpan(children: [
      TextSpan(text: title, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge!.color)),
      required ? TextSpan(text: ' *', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).colorScheme.error)) : const TextSpan(),
    ]));
  }
}
