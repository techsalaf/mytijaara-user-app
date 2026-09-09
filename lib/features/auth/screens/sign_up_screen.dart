import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/auth/domain/enum/centralize_login_enum.dart';
import 'package:sixam_mart/features/auth/domain/models/signup_body_model.dart';
import 'package:sixam_mart/features/auth/widgets/auth_dialog_widget.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/verification/screens/verification_screen.dart';
import 'package:sixam_mart/helper/custom_validator.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

import '../widgets/sign_up_new_widget.dart';

class SignUpScreen extends StatefulWidget {
  final bool exitFromApp;
  final String? referCode;
  const SignUpScreen({super.key, this.exitFromApp = false, this.referCode});

  @override
  SignUpScreenState createState() => SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen> {
  late GlobalKey<SignUpNewWidgetState> _signUpWidgetKey;

  @override
  void initState() {
    super.initState();
    _signUpWidgetKey = GlobalKey<SignUpNewWidgetState>();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (Get.find<SplashController>().deeplinkRoute != null) {
          Get.find<SplashController>().setDeeplink(null);
          Get.offAllNamed(RouteHelper.getInitialRoute());
        } else {
          try {
            Get.back();
          }catch(e) {
            return;
          }
        }
      },
      child: Scaffold(
        backgroundColor: ResponsiveHelper.isDesktop(context) ? Colors.transparent
            : Theme.of(context).colorScheme.surface,
        endDrawer: const MenuDrawer(),
        endDrawerEnableOpenDragGesture: false,
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: context.width > 700 ? 500 : context.width,
              child: Column(children: [
                Expanded(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      !isDesktop ? SliverPersistentHeader(
                        pinned: true,
                        delegate: _SignUpSliverHeaderDelegate(onBackOrClose: _onBackOrClose),
                      ) : const SliverToBoxAdapter(child: SizedBox()),

                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: context.width > 700 ? 0 : Dimensions.paddingSizeDefault,
                            right: context.width > 700 ? 0 : Dimensions.paddingSizeDefault,
                            top: isDesktop ? Dimensions.paddingSizeLarge : 0,
                            bottom: Dimensions.paddingSizeLarge,
                          ),
                          child: Container(
                            padding: context.width > 700 ? const EdgeInsets.all(Dimensions.paddingSizeLarge) : null,
                            margin: context.width > 700 ? const EdgeInsets.all(Dimensions.paddingSizeDefault) : null,
                            decoration: context.width > 700 ? BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                            ) : null,
                            child: Column(children: [
                              isDesktop ? Align(
                                alignment: Alignment.topRight,
                                child: GestureDetector(onTap: () => Get.back(), child: const Icon(Icons.clear)),
                              ) : const SizedBox(),

                              isDesktop ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('sign_up'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
                                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                                RichText(text: TextSpan(children: [
                                  TextSpan(
                                    text: 'To get the all personalised feature sign up ',
                                    style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                                  ),
                                  TextSpan(
                                    text: 'login'.tr,
                                    style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.blueAccent, decoration: TextDecoration.underline),
                                    recognizer: TapGestureRecognizer()..onTap = () {
                                      if(isDesktop){
                                        Get.back();
                                        Get.dialog(const Center(child: AuthDialogWidget(exitFromApp: false, backFromThis: false)));
                                      }else{
                                        if(Get.currentRoute == RouteHelper.signUp) {
                                          Get.back();
                                        } else {
                                          Get.toNamed(RouteHelper.getSignInRoute(RouteHelper.signUp));
                                        }
                                      }
                                    },
                                  ),
                                  TextSpan(
                                    text: ' now.',
                                    style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                                  ),
                                ])),
                                const SizedBox(height: Dimensions.paddingSizeLarge),
                                SignUpNewWidget(key: _signUpWidgetKey, referCode: widget.referCode),
                              ]) : SignUpNewWidget(key: _signUpWidgetKey, referCode: widget.referCode),
                            ]),
                          ),
                        ),
                      ),

                      GetBuilder<AuthController>(builder: (authController) {
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: context.width > 700 ? 0 : Dimensions.paddingSizeDefault,
                              right: context.width > 700 ? 0 : Dimensions.paddingSizeDefault,
                              top: Dimensions.paddingSizeDefault,
                              bottom: Dimensions.paddingSizeLarge,
                            ),
                            child: _termsCard(context, authController),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                GetBuilder<AuthController>(builder: (authController) {
                  return Padding(
                    padding: EdgeInsets.only(
                      left: context.width > 700 ? 0 : Dimensions.paddingSizeDefault,
                      right: context.width > 700 ? 0 : Dimensions.paddingSizeDefault,
                      bottom: Dimensions.paddingSizeLarge,
                    ),
                    child: _signUpButton(context, authController),
                  );
                }),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  void _onBackOrClose() {
    if(Get.find<SplashController>().deeplinkRoute != null) {
      Get.find<SplashController>().setDeeplink(null);
      Get.offAllNamed(RouteHelper.getInitialRoute());
    } else {
      Get.back();
    }
  }

  Widget _termsCard(BuildContext context, AuthController authController) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusLarge)),
        boxShadow: [BoxShadow(color: Colors.grey[Get.isDarkMode ? 400 : 200]!, spreadRadius: 1, blurRadius: 5, offset: const Offset(2, 2))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          height: 24, width: 24,
          child: Checkbox(
            side: BorderSide(color: Theme.of(context).hintColor),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            activeColor: Theme.of(context).primaryColor,
            value: authController.acceptTerms,
            onChanged: (bool? isChecked) => authController.toggleTerms(),
          ),
        ),
        const SizedBox(width: Dimensions.paddingSizeDefault),
        Expanded(
          child: RichText(text: TextSpan(children: [
            TextSpan(text: 'I have read and agree to the ', style: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall)),
            TextSpan(
              text: 'privacy_policy'.tr,
              style: robotoMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color, fontSize: Dimensions.fontSizeSmall),
              recognizer: TapGestureRecognizer()..onTap = () => Get.toNamed(RouteHelper.privacyPolicy),
            ),
            TextSpan(text: ' , ', style: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall)),
            TextSpan(
              text: 'terms_conditions'.tr,
              style: robotoMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color, fontSize: Dimensions.fontSizeSmall),
              recognizer: TapGestureRecognizer()..onTap = () => Get.toNamed(RouteHelper.termsAndCondition),
            ),
            TextSpan(text: ' and ', style: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall)),
            TextSpan(
              text: 'refund_policy'.tr,
              style: robotoMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color, fontSize: Dimensions.fontSizeSmall),
              recognizer: TapGestureRecognizer()..onTap = () => Get.toNamed(RouteHelper.refundPolicy),
            ),
          ])),
        ),
      ]),
    );
  }

  Widget _signUpButton(BuildContext context, AuthController authController) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusLarge)),
        boxShadow: [BoxShadow(color: Colors.grey[Get.isDarkMode ? 400 : 200]!, spreadRadius: 1, blurRadius: 5, offset: const Offset(2, 2))],
      ),
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: TextButton(
          style: TextButton.styleFrom(
            backgroundColor: authController.acceptTerms ? Theme.of(context).primaryColor : const Color(0xFFE0E0E0),
            foregroundColor: authController.acceptTerms ? Theme.of(context).cardColor : Theme.of(context).disabledColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
          ),
          onPressed: (!authController.acceptTerms || authController.isLoading) ? null : () => _register(authController),
          child: authController.isLoading ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
              height: 15, width: 15,
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).cardColor), strokeWidth: 2),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Text('loading'.tr, style: robotoMedium.copyWith(color: Theme.of(context).cardColor)),
          ]) : Text(
            'sign_up'.tr,
            style: robotoBold.copyWith(color: authController.acceptTerms ? Theme.of(context).cardColor : Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeLarge),
          ),
        ),
      ),
    );
  }

  void _register(AuthController authController) async {
    final widgetState = _signUpWidgetKey.currentState;
    if(widgetState == null) return;

    final countryCode = widgetState.countryDialCode;
    final formKey = widgetState.formKey;

    SignUpBodyModel? signUpModel = await _prepareSignUpBody(formKey, countryCode);

    if(signUpModel == null) {
      return;
    } else {
      authController.registration(signUpModel).then((status) async {
        _handleResponse(status, countryCode);
      });
    }
  }

  void _handleResponse(ResponseModel status, String countryCode) {
    final widgetState = _signUpWidgetKey.currentState;
    if(widgetState == null) return;

    String password = widgetState.passwordController.text.trim();
    String numberWithCountryCode = countryCode + widgetState.phoneController.text.trim();
    String email = widgetState.emailController.text.trim();

    if (status.isSuccess) {
      if(ResponsiveHelper.isDesktop(context)) {
        Get.find<CartController>().getAllCarts();
      }
      if(status.authResponseModel != null && !status.authResponseModel!.isPhoneVerified!) {
        List<int> encoded = utf8.encode(password);
        String data = base64Encode(encoded);
        if(Get.find<SplashController>().configModel!.firebaseOtpVerification!) {
          Get.find<AuthController>().firebaseVerifyPhoneNumber(numberWithCountryCode, status.message, CentralizeLoginType.manual.name, fromSignUp: true);
        } else {
          if(ResponsiveHelper.isDesktop(context)) {
            Get.back();
            Get.dialog(VerificationScreen(
              number: numberWithCountryCode, email: null, token: status.message, fromSignUp: true,
              fromForgetPassword: false, loginType: CentralizeLoginType.manual.name, password: password,
            ));
          } else {
            Get.toNamed(RouteHelper.getVerificationRoute(
              numberWithCountryCode, null, status.message, RouteHelper.signUp, data, CentralizeLoginType.manual.name,
            ));
          }
        }
      } else if(status.authResponseModel != null && !status.authResponseModel!.isEmailVerified!) {
        List<int> encoded = utf8.encode(password);
        String data = base64Encode(encoded);
        if(ResponsiveHelper.isDesktop(context)) {
          Get.back();
          Get.dialog(VerificationScreen(
            number: null, email: email, token: status.message, fromSignUp: true,
            fromForgetPassword: false, loginType: CentralizeLoginType.manual.name, password: password,
          ));
        } else {
          Get.toNamed(RouteHelper.getVerificationRoute(
            null, email, status.message, RouteHelper.signUp, data, CentralizeLoginType.manual.name,
          ));
        }
      } else {
        Get.find<ProfileController>().getUserInfo();
        Get.find<LocationController>().navigateToLocationScreen(RouteHelper.signUp);
        if(ResponsiveHelper.isDesktop(context)) {
          Get.back();
        }
      }
    } else {
      showCustomSnackBar(status.message);
    }
  }

  Future<SignUpBodyModel?> _prepareSignUpBody(GlobalKey<FormState>? formKey, String countryCode) async {
    final widgetState = _signUpWidgetKey.currentState;
    if(widgetState == null || formKey == null) return null;

    String name = widgetState.nameController.text.trim();
    String email = widgetState.emailController.text.trim();
    String number = widgetState.phoneController.text.trim();
    String password = widgetState.passwordController.text.trim();
    String confirmPassword = widgetState.confirmPasswordController.text.trim();
    String referCode = widgetState.referCodeController.text.trim();

    String numberWithCountryCode = countryCode + number;
    PhoneValid phoneValid = await CustomValidator.isPhoneValid(numberWithCountryCode);
    numberWithCountryCode = phoneValid.phone;

    if (formKey.currentState!.validate()) {
      if (name.isEmpty) {
        showCustomSnackBar('please_enter_your_name'.tr);
      } else if (email.isEmpty) {
        showCustomSnackBar('enter_email_address'.tr);
      } else if (!GetUtils.isEmail(email)) {
        showCustomSnackBar('enter_a_valid_email_address'.tr);
      } else if (number.isEmpty) {
        showCustomSnackBar('enter_phone_number'.tr);
      } else if (!phoneValid.isValid) {
        showCustomSnackBar('invalid_phone_number'.tr);
      } else if (password.isEmpty) {
        showCustomSnackBar('enter_password'.tr);
      } else if (password.length < 8) {
        showCustomSnackBar('password_should_be_8_characters'.tr);
      } else if (password != confirmPassword) {
        showCustomSnackBar('confirm_password_does_not_matched'.tr);
      } else if (referCode.isNotEmpty && referCode.length != 10) {
        showCustomSnackBar('invalid_refer_code'.tr);
      } else {
        SignUpBodyModel signUpBody = SignUpBodyModel(
          name: name,
          email: email,
          phone: numberWithCountryCode,
          password: password,
          refCode: referCode,
        );
        return signUpBody;
      }
    }
    return null;
  }
}

class _SignUpSliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final VoidCallback onBackOrClose;
  const _SignUpSliverHeaderDelegate({required this.onBackOrClose});

  static const double _minHeaderExtent = 72;
  static const double _maxHeaderExtent = 140;

  @override
  double get minExtent => _minHeaderExtent;

  @override
  double get maxExtent => _maxHeaderExtent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    double progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0).toDouble();
    bool isCollapsed = progress >= 0.5;
    double collapsedAnimProgress = ((progress - 0.5) / 0.5).clamp(0.0, 1.0);

    return Stack(fit: StackFit.expand, children: [
      Opacity(
        opacity: isCollapsed ? 1.0 : 0.0,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(bottom: BorderSide(color: Theme.of(context).disabledColor.withValues(alpha: 0.12))),
          ),
        ),
      ),

      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        child: isCollapsed ? _buildCollapsedHeader(context, collapsedAnimProgress) : _buildExpandedHeader(context),
      ),
    ]);
  }

  Widget _buildExpandedHeader(BuildContext context) {
    return Stack(children: [
      Positioned(
        top: 0, left: 0, right: 0, height: _minHeaderExtent,
        child: Row(children: [
          _expandedIconButton(context, Icons.arrow_back, onBackOrClose),
          const Spacer(),
          _expandedIconButton(context, Icons.close, onBackOrClose),
        ]),
      ),

      Positioned(
        left: 0, right: 0, bottom: Dimensions.paddingSizeLarge,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('sign_up'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          RichText(text: TextSpan(children: [
            TextSpan(
              text: 'To get the all personalised feature sign up ',
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
            ),
            TextSpan(
              text: 'login'.tr,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.blueAccent, decoration: TextDecoration.underline),
              recognizer: TapGestureRecognizer()..onTap = () {
                if(Get.currentRoute == RouteHelper.signUp) {
                  Get.back();
                } else {
                  Get.toNamed(RouteHelper.getSignInRoute(RouteHelper.signUp));
                }
              },
            ),
            TextSpan(
              text: ' now.',
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
            ),
          ])),
        ]),
      ),
    ]);
  }

  Widget _buildCollapsedHeader(BuildContext context, double animProgress) {
    return Transform.translate(
      offset: Offset(0, -30 * (1 - animProgress)),
      child: Opacity(
        opacity: animProgress,
        child: Align(
          alignment: Alignment.center,
          child: Row(children: [
            _circleButton(context, Icons.arrow_back, onBackOrClose),
            const SizedBox(width: Dimensions.paddingSizeDefault),
            Expanded(
              child: Text('sign_up'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
            ),
            _circleButton(context, Icons.close, onBackOrClose),
          ]),
        ),
      ),
    );
  }

  Widget _expandedIconButton(BuildContext context, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Icon(icon, color: Theme.of(context).textTheme.bodyLarge!.color, size: 16),
      ),
    );
  }

  Widget _circleButton(BuildContext context, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 28, width: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).disabledColor.withValues(alpha: 0.08),
        ),
        child: Icon(icon, color: Theme.of(context).hintColor, size: 16),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SignUpSliverHeaderDelegate oldDelegate) {
    return oldDelegate.onBackOrClose != onBackOrClose;
  }
}
