import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/custom_text_field.dart';
import 'package:sixam_mart/features/auth/widgets/auth_dialog_widget.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/profile/domain/models/userinfo_model.dart';
import 'package:sixam_mart/features/auth/widgets/verification_new/pass_change_successfull_bottom_sheet.dart';
import 'package:sixam_mart/features/verification/controllers/verification_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/helper/validate_check.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class NewPassNewScreen extends StatefulWidget {
  final String? resetToken;
  final String? number;
  final String? email;
  final bool fromPasswordChange;
  final bool fromDialog;
  const NewPassNewScreen({
    super.key,
    required this.resetToken,
    this.number,
    required this.fromPasswordChange,
    this.fromDialog = false,
    this.email,
  });

  @override
  State<NewPassNewScreen> createState() => _NewPassNewScreenState();
}

class _NewPassNewScreenState extends State<NewPassNewScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FocusNode _newPasswordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);
    return Scaffold(
      backgroundColor: isDesktop ? Colors.transparent : Theme.of(context).colorScheme.surface,
      body: SafeArea(child: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: context.width > 700 ? 0 : Dimensions.paddingSizeDefault,
            vertical: Dimensions.paddingSizeLarge,
          ),
          child: Container(
            height: widget.fromDialog ? 516 : null,
            width: widget.fromDialog ? 475 : context.width > 700 ? 500 : context.width,
            padding: context.width > 700 ? const EdgeInsets.all(Dimensions.paddingSizeLarge) : null,
            decoration: context.width > 700 ? BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            ) : null,
            child: Column(children: [
              Row(children: [
                InkWell(
                  onTap: () {
                    Get.back(result: false);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0, top: 8.0, bottom: 8.0),
                    child: Icon(
                      Icons.arrow_back, size: 16,
                      color: Theme.of( context).textTheme.bodyLarge!.color,
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    Get.back(result: false);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0, top: 8.0, bottom: 8.0),
                    child: Icon(
                      Icons.close, size: 16,
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              isDesktop ? Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(onTap: () => Get.back(), child: const Icon(Icons.clear) ),
                ) : const SizedBox(),

              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  'set_your_new_password'.tr,
                  style: robotoMedium.copyWith( fontSize: Dimensions.fontSizeExtraLarge),
                ),
                Text(
                  'enter_your_new_password'.tr,
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),
                Container(
                  padding: const EdgeInsets.all( Dimensions.paddingSizeLarge),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusLarge)),
                    boxShadow: [BoxShadow( color: Colors.grey[Get.isDarkMode ? 400 : 200]!, spreadRadius: 1, blurRadius: 5, offset: const Offset(2, 2)) ],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      CustomTextField(
                        titleText: 'password_hint'.tr, labelText: 'new_password'.tr,
                        controller: _newPasswordController, focusNode: _newPasswordFocus, nextFocus: _confirmPasswordFocus,
                        inputType: TextInputType.visiblePassword, isPassword: true, divider: false,
                        validator: (value) => ValidateCheck.validateEmptyText( value, 'please_enter_new_password'.tr),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeLarge),

                      CustomTextField(
                        titleText: 'password_hint'.tr,
                        controller: _confirmPasswordController,
                        focusNode: _confirmPasswordFocus,
                        inputAction: TextInputAction.done,
                        inputType: TextInputType.visiblePassword,
                        isPassword: true,
                        onSubmit: (text) => GetPlatform.isWeb ? _onPressedPasswordChange() : null,
                        labelText: 'confirm_password'.tr,
                        validator: (value) => ValidateCheck.validateEmptyText(value, 'please_enter_confirm_password'.tr),
                      ),

                      const SizedBox( height: Dimensions.paddingSizeExtraOverLarge),

                      GetBuilder<ProfileController>(
                        builder: (profileController) {
                          return GetBuilder<VerificationController>(
                            builder: (verificationController) {
                              return CustomButton(
                                radius: Dimensions.radiusDefault,
                                buttonText: 'change_password'.tr,
                                isLoading: widget.fromPasswordChange ? profileController.isLoading : verificationController.isLoading,
                                onPressed: () => _onPressedPasswordChange(),
                              );
                            },
                          );
                        },
                      ),
                    ]),
                ),
              ]),
            ]),
          ),
        ),
      )),
    );
  }

  void _onPressedPasswordChange() {
    String password = _newPasswordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();
    if (password.isEmpty) {
      showCustomSnackBar('enter_password'.tr);
    } else if (password.length < 6) {
      showCustomSnackBar('password_should_be'.tr);
    } else if (password != confirmPassword) {
      showCustomSnackBar('confirm_password_does_not_matched'.tr);
    } else {
      if (widget.fromPasswordChange) {
        _changeUserPassword(password);
      } else {
        _resetUserPassword(password, confirmPassword);
      }
    }
  }

  void _changeUserPassword(String password) {
    UserInfoModel user = Get.find<ProfileController>().userInfoModel!;
    user.password = password;
    Get.find<ProfileController>().changePassword(user).then((response) {
      if (response.isSuccess) {
        Get.back();
        showModalBottomSheet(
          context: Get.context!,
          isScrollControlled: true,
          builder: (context) => const PasswordChangedBottomSheet(),
        );
      } else {
        showCustomSnackBar(response.message);
      }
    });
  }

  void _resetUserPassword(String password, String confirmPassword) {
    String? number = '';
    if (widget.number != null && widget.number != 'null' && widget.number!.isNotEmpty) {
      number = widget.number!.startsWith('+') ? widget.number : '+${widget.number!.substring(1, widget.number!.length)}';
    }
    Get.find<VerificationController>().resetPassword(resetToken: widget.resetToken, phone: number, email: widget.email, password: password, confirmPassword: confirmPassword).then((value) {
          if (value.isSuccess) {
            if (!ResponsiveHelper.isDesktop(Get.context)) {
              Get.offAllNamed(RouteHelper.getSignInRoute(RouteHelper.resetPassword));
              showModalBottomSheet(
                context: Get.context!,
                isScrollControlled: true,
                builder: (context) => const PasswordChangedBottomSheet(),
              );
            } else {
              Get.offAllNamed(RouteHelper.getInitialRoute(fromSplash: false))?.then((value) {
                Get.dialog(
                  const Center(child: AuthDialogWidget(exitFromApp: true, backFromThis: false)),
                );
              });
              showCustomSnackBar('password_reset_successfully'.tr, isError: false);
            }
          } else {
            showCustomSnackBar(value.message);
          }
        });
  }
}
