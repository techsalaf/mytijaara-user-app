import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_bottom_sheet_widget.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_text_field.dart';
import 'package:sixam_mart/features/location/screens/pick_location_screen.dart';
import 'package:sixam_mart/features/parcel/controllers/parcel_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class ParcelInfoBottomSheet extends StatefulWidget {
  final bool isSender;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController streetController;
  final TextEditingController houseController;
  final TextEditingController floorController;
  final TextEditingController guestEmailController;
  final TextEditingController addressController;
  final Future<bool> Function() onConfirm;

  const ParcelInfoBottomSheet({
    super.key,
    required this.isSender,
    required this.nameController,
    required this.phoneController,
    required this.streetController,
    required this.houseController,
    required this.floorController,
    required this.guestEmailController,
    required this.addressController,
    required this.onConfirm,
  });

  static void open(
    BuildContext context, {
    required bool isSender,
    required TextEditingController nameController,
    required TextEditingController phoneController,
    required TextEditingController streetController,
    required TextEditingController houseController,
    required TextEditingController floorController,
    required TextEditingController guestEmailController,
    required TextEditingController addressController,
    required Future<bool> Function() onConfirm,
  }) {
    final sheet = ParcelInfoBottomSheet(
      isSender: isSender,
      nameController: nameController,
      phoneController: phoneController,
      streetController: streetController,
      houseController: houseController,
      floorController: floorController,
      guestEmailController: guestEmailController,
      addressController: addressController,
      onConfirm: onConfirm,
    );

    Get.find<ParcelController>().setIsPickedUp(isSender, false);
    Get.find<ParcelController>().setIsSender(isSender, false);

    if (ResponsiveHelper.isDesktop(context)) {
      Get.dialog(Dialog(child: SizedBox(width: 480, child: sheet)));
    } else {
      final double screenHeight = MediaQuery.of(context).size.height;
      final double sheetHeight = screenHeight * (AuthHelper.isGuestLoggedIn() ? 0.92 : 0.8);
      showCustomBottomSheet(child: sheet, height: sheetHeight);
    }
  }

  @override
  State<ParcelInfoBottomSheet> createState() => _ParcelInfoBottomSheetState();
}

class _ParcelInfoBottomSheetState extends State<ParcelInfoBottomSheet> {
  Future<void> _openMapPicker() async {
    Get.find<ParcelController>().setIsPickedUp(widget.isSender, false);

    await Get.to(
      () => PickLocationScreen(
        mode: widget.isSender ? PickLocationMode.parcelSender : PickLocationMode.parcelReceiver,
      ),
      preventDuplicates: false,
    );

    if (!mounted) return;
    final parcelController = Get.find<ParcelController>();
    final picked = widget.isSender
        ? parcelController.pickupAddress
        : parcelController.destinationAddress;
    if (picked != null) {
      widget.addressController.text = picked.address ?? '';
    }
    setState(() {});
  }

  Future<void> _onConfirmTap() async {
    final ok = await widget.onConfirm();
    if (ok) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);
    final bool isGuest = AuthHelper.isGuestLoggedIn();

    return Container(
      width: Dimensions.webMaxWidth,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: ResponsiveHelper.isMobile(context)
            ? const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge))
            : const BorderRadius.all(Radius.circular(Dimensions.radiusExtraLarge)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [

        _SheetHeader(
          showDragHandle: !isDesktop,
          title: widget.isSender ? 'sender_info'.tr : 'receiver_info'.tr,
          onClose: () => Get.back(),
        ),

        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              Dimensions.paddingSizeLarge,
              0,
              Dimensions.paddingSizeLarge,
              Dimensions.paddingSizeLarge + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [

              _AddressRow(
                isSender: widget.isSender,
                addressController: widget.addressController,
                onEdit: _openMapPicker,
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),

              _LabeledField(
                label: 'street_number'.tr,
                child: CustomTextField(
                  titleText: 'enter_street_number'.tr,
                  showLabelText: false,
                  inputType: TextInputType.streetAddress,
                  controller: widget.streetController,
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),

              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: _LabeledField(
                    label: 'house'.tr,
                    child: CustomTextField(
                      titleText: 'house_number'.tr,
                      showLabelText: false,
                      inputType: TextInputType.text,
                      controller: widget.houseController,
                    ),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Expanded(
                  child: _LabeledField(
                    label: 'floor'.tr,
                    child: CustomTextField(
                      titleText: 'floor'.tr,
                      showLabelText: false,
                      inputType: TextInputType.text,
                      controller: widget.floorController,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: Dimensions.paddingSizeLarge),

              _LabeledField(
                label: widget.isSender ? 'sender_name'.tr : 'receiver_name'.tr,
                required: true,
                child: CustomTextField(
                  titleText: 'write_name'.tr,
                  showLabelText: false,
                  inputType: TextInputType.name,
                  capitalization: TextCapitalization.words,
                  controller: widget.nameController,
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),

              _LabeledField(
                label: 'phone_number'.tr,
                required: true,
                child: GetBuilder<ParcelController>(builder: (parcelController) {
                  final String? code = widget.isSender
                      ? parcelController.senderCountryCode
                      : parcelController.receiverCountryCode;
                  return CustomTextField(
                    titleText: 'write_number'.tr,
                    showLabelText: false,
                    isPhone: true,
                    inputType: TextInputType.phone,
                    controller: widget.phoneController,
                    countryDialCode: code,
                    onCountryChanged: (CountryCode countryCode) {
                      Get.find<ParcelController>().setCountryCode(countryCode.dialCode ?? '', widget.isSender);
                    },
                  );
                }),
              ),

              if (isGuest) ...[
                const SizedBox(height: Dimensions.paddingSizeLarge),
                _LabeledField(
                  label: 'email'.tr,
                  required: true,
                  child: CustomTextField(
                    titleText: 'enter_email'.tr,
                    showLabelText: false,
                    inputType: TextInputType.emailAddress,
                    inputAction: TextInputAction.done,
                    controller: widget.guestEmailController,
                  ),
                ),
              ],

              const SizedBox(height: Dimensions.paddingSizeExtraLarge),

              CustomButton(
                buttonText: 'confirm_information'.tr,
                onPressed: _onConfirmTap,
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final bool showDragHandle;
  final String title;
  final VoidCallback onClose;

  const _SheetHeader({required this.showDragHandle, required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeLarge,
        Dimensions.paddingSizeSmall,
        Dimensions.paddingSizeSmall,
        Dimensions.paddingSizeDefault,
      ),
      child: Stack(alignment: Alignment.center, children: [
        if (showDragHandle)
          Container(
            height: 4,
            width: 36,
            decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Padding(
            padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
            child: Text(title, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 28,
              height: 28,
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

class _AddressRow extends StatelessWidget {
  final bool isSender;
  final TextEditingController addressController;
  final VoidCallback onEdit;

  const _AddressRow({required this.isSender, required this.addressController, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeSmall,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.4), width: 0.7),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Icon(Icons.location_on_outlined, size: 18, color: Theme.of(context).disabledColor),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: GetBuilder<ParcelController>(builder: (parcelController) {
              final String addressText = isSender
                  ? (parcelController.pickupAddress?.address ?? addressController.text)
                  : (parcelController.destinationAddress?.address ?? addressController.text);
              final bool empty = addressText.trim().isEmpty;
              return Text(
                empty ? 'select_from_map'.tr : addressText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: empty
                      ? Theme.of(context).hintColor
                      : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              );
            }),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
            child: Icon(Icons.edit_outlined, size: 18, color: Theme.of(context).primaryColor),
          ),
        ]),
      ),
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
      Text.rich(TextSpan(children: [
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
      ])),
      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
      child,
    ]);
  }
}
