import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/auth/domain/enum/centralize_login_enum.dart';
import 'package:sixam_mart/features/auth/screens/new_user_setup_screen.dart';
import 'package:sixam_mart/features/auth/widgets/sign_in/existing_user_bottom_sheet.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/profile/domain/models/update_user_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/verification/controllers/verification_controller.dart';
import 'package:sixam_mart/features/verification/domein/enum/verification_type_enum.dart';
import 'package:sixam_mart/features/verification/domein/models/verification_data_model.dart';
import 'package:sixam_mart/features/verification/screens/new_pass_screen.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class VerificationNewScreen extends StatefulWidget {
  final String? number;
  final String? email;
  final bool fromSignUp;
  final String? token;
  final String? password;
  final String loginType;
  final String? firebaseSession;
  final bool fromForgetPassword;
  final UpdateUserModel? userModel;
  final bool backFromThis;
  const VerificationNewScreen({super.key, required this.number, required this.password, required this.fromSignUp,
    required this.token, this.email, required this.loginType, this.firebaseSession, required this.fromForgetPassword,
    this.userModel, this.backFromThis = false});

  @override
  VerificationNewScreenState createState() => VerificationNewScreenState();
}

class VerificationNewScreenState extends State<VerificationNewScreen> {
  String? _number;
  String? _email;
  Timer? _timer;
  int _seconds = 0;
  final ScrollController _scrollController = ScrollController();
  late StreamController<ErrorAnimationType> errorController;

  bool hasError = false;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();

    Get.find<VerificationController>().updateVerificationCode('', canUpdate: false);
    if(widget.number != null && widget.number!.isNotEmpty) {
      _number = widget.number!.startsWith('+') ? widget.number : '+${widget.number!.substring(1, widget.number!.length)}';
    }
    _email = widget.email;
    _startTimer();

    errorController = StreamController<ErrorAnimationType>();
  }

  void _startTimer() {
    _seconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _seconds = _seconds - 1;
      if(_seconds == 0) {
        timer.cancel();
        _timer?.cancel();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();

    _timer?.cancel();
    errorController.close();
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);
    double borderWidth = 0.7;
    return Scaffold(
      backgroundColor: isDesktop ? Colors.transparent : Theme.of(context).colorScheme.surface,
      body: SafeArea(child: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: context.width > 700 ? 0 : Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeLarge),
          child: Container(
            width: context.width > 700 ? 500 : context.width,
            padding: context.width > 700 ? const EdgeInsets.all(Dimensions.paddingSizeLarge) : null,
            decoration: context.width > 700 ? BoxDecoration(
              color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            ) : null,
            child: GetBuilder<VerificationController>(builder: (verificationController) {
              final String contact = (_email != null && _email!.isNotEmpty) ? _email! : (_number ?? '');
              final bool canVerify = verificationController.verificationCode.length >= 6;

              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    ResponsiveHelper.isDesktop(context) ? const SizedBox.shrink() : 
                    Row(children: [ 
                      InkWell(
                        onTap: () {
                          Get.back(result: false);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0, top: 8.0, bottom: 8.0),
                          child: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.bodyLarge!.color, size: 16),
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () {
                          Get.back(result: false);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 8.0, bottom: 8.0),
                          child: Icon(Icons.close, color: Theme.of(context).textTheme.bodyLarge!.color, size: 16),
                        ),
                      ),
                    ]),
                    const SizedBox(height: Dimensions.paddingSizeLarge),

                Text(
                  (_email != null && _email!.isNotEmpty) ? 'check_mail_to_verification'.tr : 'check_phone_to_verification'.tr,
                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                Get.find<SplashController>().configModel!.demo! ? Text(
                  'for_demo_purpose'.tr,
                  style: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeDefault),
                ) : RichText(text: TextSpan(children: [
                  TextSpan(text: "${'we_have_sent_a_verification_code_to'.tr} ", style: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeDefault)),
                  TextSpan(text: contact, style: robotoMedium.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeDefault)),
                  // TextSpan(text: '\n${'your_otp_will_be_expired_within'.tr} ', style: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeDefault)),
                  // TextSpan(text: '2_minutes'.tr, style: robotoMedium.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeDefault)),
                ])),
                const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                Container(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusExtraLarge)),
                  ),
                  child: Column(children: [
                    PinCodeTextField(
                      length: 6,
                      appContext: context,
                      autoFocus: true,
                      keyboardType: TextInputType.number,
                      animationType: AnimationType.slide,
                      cursorColor: Theme.of(context).textTheme.bodyLarge!.color,
                      textStyle: robotoMedium.copyWith(fontSize: 20),
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        fieldHeight: 52,
                        fieldWidth: context.width > 390 ? 52 : 44,
                        borderWidth: borderWidth,
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        selectedColor: Theme.of(context).disabledColor.withValues(alpha: 0.35),
                        selectedFillColor: Theme.of(context).cardColor,
                        inactiveFillColor: Theme.of(context).cardColor,
                        inactiveColor: Theme.of(context).disabledColor.withValues(alpha: 0.35),
                        activeColor: hasError ? Colors.orange : Theme.of(context).disabledColor.withValues(alpha: 0.35),
                        activeFillColor: Theme.of(context).cardColor,
                        inactiveBorderWidth: borderWidth,
                        selectedBorderWidth: borderWidth,
                        disabledBorderWidth: borderWidth,
                        errorBorderWidth: borderWidth,
                        activeBorderWidth: borderWidth,
                      ),
                      animationDuration: const Duration(milliseconds: 300),
                      backgroundColor: Colors.transparent,
                      enableActiveFill: true,
                      onChanged: verificationController.updateVerificationCode,
                      beforeTextPaste: (text) => true,
                      errorAnimationController: errorController, // Optional: Custom error animation
                      errorTextSpace: 20, // Space for error text
                      errorTextMargin: const EdgeInsets.only(top: 10),
                    ),
                    hasError ? Text(
                      hasError ? errorMessage : "",
                      style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w400),
                    ) : const SizedBox(),
                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    GetBuilder<ProfileController>(builder: (profileController) {
                      return SizedBox(
                        height: 52, width: double.infinity,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: canVerify ? Theme.of(context).primaryColor : const Color(0xFFE0E0E0),
                            foregroundColor: canVerify ? Theme.of(context).cardColor : Theme.of(context).disabledColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
                          ),
                          onPressed: (!canVerify || verificationController.isLoading || profileController.isLoading) ? null : () {
                            if(widget.firebaseSession != null && widget.userModel == null) {
                              verificationController.verifyFirebaseOtp(
                                phoneNumber: _number!, session: widget.firebaseSession!, loginType: widget.loginType,
                                otp: verificationController.verificationCode, token: widget.token, isForgetPassPage: widget.fromForgetPassword,
                                isSignUpPage: widget.loginType == CentralizeLoginType.otp.name ? false : true,
                              ).then((value) {
                                if(value.isSuccess) {
                                  _handleVerifyResponse(value, _number, _email);
                                }else {
                                  showCustomSnackBar(value.message);
                                }
                              });
                            } else if(widget.userModel != null) {
                              widget.userModel!.otp = verificationController.verificationCode;
                              Get.find<ProfileController>().updateUserInfo(widget.userModel!, Get.find<AuthController>().getUserToken(), fromButton: true);
                            }
                            else if(widget.fromSignUp) {
                              verificationController.verifyPhone(data: VerificationDataModel(
                                phone: _number, email: _email, verificationType: _number != null
                                  ? VerificationTypeEnum.phone.name : VerificationTypeEnum.email.name,
                                otp: verificationController.verificationCode, loginType: widget.loginType,
                                guestId: AuthHelper.getGuestId(),
                              )).then((value) {
                                if(value.isSuccess) {
                                  _handleVerifyResponse(value, _number, _email);
                                } else {
                                  showCustomSnackBar(value.message);
                                }
                              });
                            } else {
                              verificationController.verifyToken(phone: _number, email: _email).then((value) {
                                if(value.isSuccess) {
                                  if(ResponsiveHelper.isDesktop(Get.context!)){
                                    Get.back();
                                    Get.dialog(Center(child: NewPassScreen(resetToken: verificationController.verificationCode, number : _number, email: _email, fromPasswordChange: false, fromDialog: true )));
                                  }else{
                                    Get.toNamed(RouteHelper.getResetPasswordRoute(phone: _number, email: _email, token: verificationController.verificationCode, page: 'reset-password'));
                                  }
                                }else {
                                  errorController.add(ErrorAnimationType.shake);
                                  errorMessage = value.message??'';
                                  setState(() {
                                    hasError = true;
                                  });
                                  showCustomSnackBar(value.message);
                                }
                              });
                            }
                          },
                          child: verificationController.isLoading || profileController.isLoading ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            SizedBox(
                              height: 15, width: 15,
                              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).cardColor), strokeWidth: 2),
                            ),
                            const SizedBox(width: Dimensions.paddingSizeSmall),
                            Text('loading'.tr, style: robotoMedium.copyWith(color: Theme.of(context).cardColor)),
                          ]) : Text(
                            'verify_and_continue'.tr,
                            style: robotoBold.copyWith(color: canVerify ? Theme.of(context).cardColor : Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeLarge),
                          ),
                        ),
                      );
                    }),
                   
                  ]),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),

                // Padding(
                //   padding: EdgeInsets.symmetric(horizontal: isDesktop ? 29 : 0),
                //   child: 
                // ),
                const SizedBox(height: Dimensions.paddingSizeLarge),

                _seconds < 1 ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Padding(
                        padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall,),
                        child: Text('did_not_receive_the_code'.tr, style: robotoRegular.copyWith(color: Theme.of(context).hintColor)),
                      ),
                      InkWell(
                        onTap: _seconds < 1 ? () async {
                          if(widget.firebaseSession != null) {
                            await Get.find<AuthController>().firebaseVerifyPhoneNumber(_number!, widget.token, widget.loginType, fromSignUp: widget.fromSignUp, canRoute: false);
                            _startTimer();
                          } else {
                            _resendOtp();
                          }
                        } : null,
                        child: Padding(
                          padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall, top: Dimensions.paddingSizeSmall, bottom: Dimensions.paddingSizeExtraSmall),
                          child: Text('${'resent_it'.tr}${_seconds > 0 ? ' (${_seconds}s)' : ''}', style: const TextStyle(color: Colors.blueAccent)),
                        ),
                      ),
                    ]) : InkWell(
                  onTap: _seconds < 1 ? () async {
                    if(widget.firebaseSession != null) {
                      await Get.find<AuthController>().firebaseVerifyPhoneNumber(_number!, widget.token, widget.loginType, fromSignUp: widget.fromSignUp, canRoute: false);
                      _startTimer();
                    } else {
                      _resendOtp();
                    }
                  } : null,
                  child: Padding(
                    padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall, top: Dimensions.paddingSizeSmall, bottom: Dimensions.paddingSizeExtraSmall),
                    child: RichText(textAlign: TextAlign.center, text: TextSpan(children: [
                      TextSpan(text: "${'resend_code_in'.tr} ", style: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeDefault)),
                      TextSpan(text: '0.$_seconds min', style: robotoMedium.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeDefault)),
                    ])),
                  ),
                ),

                const SizedBox(height: Dimensions.paddingSizeExtraLarge),

              ]);
            }),
          ),
        ),
      )),
    );
  }

  void _handleVerifyResponse(ResponseModel response, String? number, String? email) {
    if(response.authResponseModel != null && response.authResponseModel!.isExistUser != null) {
      if(ResponsiveHelper.isDesktop(context)) {
        Get.back();
        Get.dialog(Center(
          child: ExistingUserBottomSheet(
            userModel: response.authResponseModel!.isExistUser!, number: _number, email: _email,
            loginType: widget.loginType, otp: Get.find<VerificationController>().verificationCode,
            backFromThis: widget.backFromThis,
          ),
        ));
      } else {
        Get.bottomSheet(ExistingUserBottomSheet(
          userModel: response.authResponseModel!.isExistUser!, number: _number, email: _email,
          loginType: widget.loginType, otp: Get.find<VerificationController>().verificationCode,
          backFromThis: widget.backFromThis,
        ));
      }
    } else if(response.authResponseModel != null && !response.authResponseModel!.isPersonalInfo!) {
      if(ResponsiveHelper.isDesktop(context)) {
        Get.back();
        Get.dialog(NewUserSetupScreen(name: '', loginType: widget.loginType, phone: number, email: email, backFromThis: widget.backFromThis));
      } else {
        Get.toNamed(RouteHelper.getNewUserSetupScreen(name: '', loginType: widget.loginType, phone: number, email: email, backFromThis: widget.backFromThis));
      }
    } else {

      if(widget.fromForgetPassword) {
        Get.toNamed(RouteHelper.getResetPasswordRoute(phone: _number, email: _email, token: Get.find<VerificationController>().verificationCode, page: 'reset-password'));
      } else {
        if(widget.backFromThis) {
          Get.find<LocationController>().syncZoneData();
          Get.back();
          Get.back();
        } else {
          Get.find<LocationController>().navigateToLocationScreen('verification', offNamed: true);
        }
      }
    }
  }

  void _resendOtp() {
    if(widget.userModel != null) {
      Get.find<ProfileController>().updateUserInfo(widget.userModel!, Get.find<AuthController>().getUserToken(), fromVerification: true);
    } else if(widget.fromSignUp) {
      if(widget.loginType == CentralizeLoginType.otp.name) {
        Get.find<AuthController>().otpLogin(phone: _number!, otp: '', loginType: widget.loginType, verified: '').then((response) {
          if (response.isSuccess) {
            _startTimer();
            showCustomSnackBar('resend_code_successful'.tr, isError: false);
          } else {
            showCustomSnackBar(response.message);
          }
        });
      } else {
        Get.find<AuthController>().login(
          emailOrPhone: _number != null ? _number! : _email ?? '', password: widget.password!, loginType: widget.loginType,
          fieldType: _number != null ? VerificationTypeEnum.phone.name : VerificationTypeEnum.email.name,
        ).then((value) {
          if (value.isSuccess) {
            _startTimer();
            showCustomSnackBar('resend_code_successful'.tr, isError: false);
          } else {
            showCustomSnackBar(value.message);
          }
        });
      }
    } else {
      Get.find<VerificationController>().forgetPassword(phone: _number, email: _email).then((value) {
        if (value.isSuccess) {
          _startTimer();
          showCustomSnackBar('resend_code_successful'.tr, isError: false);
        } else {
          showCustomSnackBar(value.message);
        }
      });
    }
  }
}
