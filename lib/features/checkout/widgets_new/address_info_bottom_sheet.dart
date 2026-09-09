import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_bottom_sheet_widget.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/custom_text_field.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class AddressInfoBottomSheet extends StatefulWidget {
  final CheckoutController checkoutController;
  final bool isGuest;
  final TextEditingController? guestNameController;
  final TextEditingController? guestNumberController;
  final TextEditingController? guestEmailController;
  final FocusNode? guestNumberNode;
  final FocusNode? guestEmailNode;

  const AddressInfoBottomSheet({
    super.key,
    required this.checkoutController,
    required this.isGuest,
    this.guestNameController,
    this.guestNumberController,
    this.guestEmailController,
    this.guestNumberNode,
    this.guestEmailNode,
  });

  static void open(
    BuildContext context, {
    required CheckoutController checkoutController,
    required bool isGuest,
    TextEditingController? guestNameController,
    TextEditingController? guestNumberController,
    TextEditingController? guestEmailController,
    FocusNode? guestNumberNode,
    FocusNode? guestEmailNode,
  }) {
    final sheet = AddressInfoBottomSheet(
      checkoutController: checkoutController,
      isGuest: isGuest,
      guestNameController: guestNameController,
      guestNumberController: guestNumberController,
      guestEmailController: guestEmailController,
      guestNumberNode: guestNumberNode,
      guestEmailNode: guestEmailNode,
    );
    if (ResponsiveHelper.isDesktop(context)) {
      Get.dialog(Dialog(child: sheet));
    } else {
      showCustomBottomSheet(child: sheet);
    }
  }

  @override
  State<AddressInfoBottomSheet> createState() => _AddressInfoBottomSheetState();
}

class _AddressInfoBottomSheetState extends State<AddressInfoBottomSheet> {
  TextEditingController get _nameController =>
      widget.isGuest ? widget.guestNameController! : widget.checkoutController.contactPersonNameController;

  TextEditingController get _numberController =>
      widget.isGuest ? widget.guestNumberController! : widget.checkoutController.contactPersonNumberController;

  FocusNode? get _numberFocusNode => widget.isGuest ? widget.guestNumberNode : widget.checkoutController.phoneNode;

  bool _takeAway() => widget.checkoutController.orderType == 'take_away';

  void _onConfirm() {
    if (_nameController.text.trim().isEmpty) {
      showCustomSnackBar('please_enter_your_name'.tr);
      return;
    }
    if (_numberController.text.trim().isEmpty) {
      showCustomSnackBar('please_enter_phone_number'.tr);
      return;
    }
    if (widget.isGuest && (widget.guestEmailController?.text.trim().isEmpty ?? true)) {
      showCustomSnackBar('enter_email'.tr);
      return;
    }
    widget.checkoutController.update();
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);
    final bool takeAway = _takeAway();

    return Container(
      width: Dimensions.webMaxWidth,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: ResponsiveHelper.isMobile(context)
            ? const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge))
            : const BorderRadius.all(Radius.circular(Dimensions.radiusExtraLarge)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [

        _SheetHeader(showDragHandle: !isDesktop, onClose: () => Get.back()),

        Flexible(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Dimensions.paddingSizeLarge,
            0,
            Dimensions.paddingSizeLarge,
            Dimensions.paddingSizeLarge,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [

            Text('contact_information'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            if (!takeAway) ...[
              _LabeledField(
                label: 'street_number'.tr,
                child: CustomTextField(
                  titleText: 'write_street_number'.tr,
                  showLabelText: false,
                  inputType: TextInputType.streetAddress,
                  focusNode: widget.checkoutController.streetNode,
                  nextFocus: widget.checkoutController.houseNode,
                  controller: widget.checkoutController.streetNumberController,
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),

              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: _LabeledField(
                    label: 'house'.tr,
                    child: CustomTextField(
                      titleText: 'write_house_number'.tr,
                      showLabelText: false,
                      inputType: TextInputType.text,
                      focusNode: widget.checkoutController.houseNode,
                      nextFocus: widget.checkoutController.floorNode,
                      controller: widget.checkoutController.houseController,
                    ),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Expanded(
                  child: _LabeledField(
                    label: 'floor'.tr,
                    child: CustomTextField(
                      titleText: 'write_floor_number'.tr,
                      showLabelText: false,
                      inputType: TextInputType.text,
                      focusNode: widget.checkoutController.floorNode,
                      inputAction: TextInputAction.next,
                      controller: widget.checkoutController.floorController,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: Dimensions.paddingSizeLarge),
            ],

            _LabeledField(
              label: 'sender_name'.tr,
              required: true,
              child: CustomTextField(
                titleText: 'write_name'.tr,
                showLabelText: false,
                inputType: TextInputType.name,
                controller: _nameController,
                focusNode: widget.isGuest ? null : widget.checkoutController.nameNode,
                nextFocus: _numberFocusNode,
                capitalization: TextCapitalization.words,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),

            _LabeledField(
              label: 'phone_number'.tr,
              required: true,
              child: CustomTextField(
                titleText: 'write_number'.tr,
                showLabelText: false,
                controller: _numberController,
                focusNode: _numberFocusNode,
                nextFocus: widget.isGuest ? widget.guestEmailNode : null,
                inputType: TextInputType.phone,
                isPhone: true,
                onCountryChanged: (CountryCode countryCode) {
                  widget.checkoutController.countryDialCode = countryCode.dialCode;
                },
                countryDialCode:
                    widget.checkoutController.countryDialCode ?? Get.find<LocalizationController>().locale.countryCode,
              ),
            ),

            if (widget.isGuest) ...[
              const SizedBox(height: Dimensions.paddingSizeLarge),
              _LabeledField(
                label: 'email'.tr,
                required: true,
                child: CustomTextField(
                  titleText: 'enter_email'.tr,
                  showLabelText: false,
                  controller: widget.guestEmailController,
                  focusNode: widget.guestEmailNode,
                  inputAction: TextInputAction.done,
                  inputType: TextInputType.emailAddress,
                ),
              ),
            ],
            const SizedBox(height: Dimensions.paddingSizeExtraLarge),

            CustomButton(
              buttonText: 'confirm_information'.tr,
              onPressed: _onConfirm,
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
          ]),
        )),
      ]),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final bool required;
  final Widget child;

  const _LabeledField({required this.label, this.required = false, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text.rich(
        TextSpan(children: [
          TextSpan(
            text: label,
            style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          if (required)
            TextSpan(
              text: ' *',
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
        ]),
      ),
      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
      child,
    ]);
  }
}

class _SheetHeader extends StatelessWidget {
  final bool showDragHandle;
  final VoidCallback onClose;

  const _SheetHeader({required this.showDragHandle, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeLarge,
        Dimensions.paddingSizeSmall,
        Dimensions.paddingSizeSmall,
        Dimensions.paddingSizeSmall,
      ),
      child: Stack(alignment: Alignment.center, children: [
        if (showDragHandle)
          Container(
            height: 4, width: 36,
            decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, size: 16, color: Theme.of(context).disabledColor),
            ),
          ),
        ),
      ]),
    );
  }
}
