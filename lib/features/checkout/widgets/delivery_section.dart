import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart/common/widgets/custom_dropdown.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/checkout/widgets/delivery_instraction_bottom_sheet_widget.dart';
import 'package:sixam_mart/features/checkout/widgets_new/address_info_bottom_sheet.dart';
import 'package:sixam_mart/features/checkout/widgets_new/custom_card_checkout.dart';
import 'package:sixam_mart/features/location/screens/pick_location_screen.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class DeliverySection extends StatelessWidget {
  final CheckoutController checkoutController;
  final List<AddressModel> address;
  final List<DropdownItem<int>> addressList;
  final TextEditingController guestNameTextEditingController;
  final TextEditingController guestNumberTextEditingController;
  final TextEditingController guestEmailController;
  final FocusNode guestNumberNode;
  final FocusNode guestEmailNode;
  final bool isServiceAddress;
  final int? zoneId;

  const DeliverySection({
    super.key,
    required this.checkoutController,
    required this.address,
    required this.addressList,
    required this.guestNameTextEditingController,
    required this.guestNumberTextEditingController,
    required this.guestNumberNode,
    required this.guestEmailController,
    required this.guestEmailNode,
    this.isServiceAddress = false,
    this.zoneId,
  });

  @override
  Widget build(BuildContext context) {
    final bool isGuest = AuthHelper.isGuestLoggedIn();
    final bool takeAway = checkoutController.orderType == 'take_away';

    if (!isGuest && takeAway) {
      return const SizedBox();
    }

    return GetBuilder<CheckoutController>(builder: (controller) {
      return CustomCardCheckout(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          Text(takeAway ? 'contact_information'.tr : 'delivery_address'.tr, style: robotoBold),
          const SizedBox(height: Dimensions.paddingSizeDefault),

          if (!takeAway) ...[
            _LocationRow(
              addressText: _resolveAddressText(controller, isGuest),
              onEdit: () => _openPickLocationScreen(isGuest),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
          ],

          _ContactBlock(
            name: _resolveName(controller, isGuest),
            dialCode: controller.countryDialCode,
            phone: _resolvePhone(controller, isGuest),
            onEdit: () => _openSheet(context, isGuest),
            onAdd: () => _openSheet(context, isGuest),
          ),

          if (!takeAway) ...[
            const SizedBox(height: Dimensions.paddingSizeDefault),
            const _DeliveryNoteField(),
          ],
        ]),
      );
    });
  }

  void _openSheet(BuildContext context, bool isGuest) {
    AddressInfoBottomSheet.open(
      context,
      checkoutController: checkoutController,
      isGuest: isGuest,
      guestNameController: isGuest ? guestNameTextEditingController : null,
      guestNumberController: isGuest ? guestNumberTextEditingController : null,
      guestEmailController: isGuest ? guestEmailController : null,
      guestNumberNode: isGuest ? guestNumberNode : null,
      guestEmailNode: isGuest ? guestEmailNode : null,
    );
  }

  void _openPickLocationScreen(bool isGuest) {
    Get.to(
      () => PickLocationScreen(
        mode: PickLocationMode.checkout,
        initialSearchText: _resolveAddressText(checkoutController, isGuest),
        onAddressPicked: (address) async {
          if (isGuest) {
            checkoutController.setGuestAddress(address);
          } else {
            await checkoutController.insertAddresses(address, notify: true);
          }
          // Recalculate distance for the newly picked address.
          // Without this call the distance stays stale (calculated on init with
          // the SharedPref address), so delivery charge and the order body are wrong.
          final store = checkoutController.store;
          if (store != null &&
              address.latitude != null && address.latitude!.isNotEmpty &&
              address.longitude != null && address.longitude!.isNotEmpty &&
              store.latitude != null && store.longitude != null) {
            checkoutController.getDistanceInKM(
              LatLng(double.parse(address.latitude!), double.parse(address.longitude!)),
              LatLng(double.parse(store.latitude!), double.parse(store.longitude!)),
            );
          }
        },
      ),
      preventDuplicates: false,
    );
  }

  String _resolveAddressText(CheckoutController controller, bool isGuest) {
    if (isGuest) {
      return controller.guestAddress?.address ?? controller.contactPersonAddressController.text;
    }
    final String? current = controller.address?.address;
    if (current != null && current.isNotEmpty) {
      return current;
    }
    if (address.isNotEmpty && controller.addressIndex != null && controller.addressIndex! < address.length) {
      return address[controller.addressIndex!].address ?? '';
    }
    return controller.contactPersonAddressController.text;
  }

  String _resolveName(CheckoutController controller, bool isGuest) {
    return isGuest ? guestNameTextEditingController.text : controller.contactPersonNameController.text;
  }

  String _resolvePhone(CheckoutController controller, bool isGuest) {
    return isGuest ? guestNumberTextEditingController.text : controller.contactPersonNumberController.text;
  }
}

class _LocationRow extends StatelessWidget {
  final String addressText;
  final VoidCallback onEdit;

  const _LocationRow({required this.addressText, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = addressText.trim().isEmpty;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _IconBadge(icon: Icons.location_on_outlined),
      const SizedBox(width: Dimensions.paddingSizeSmall),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('current_location'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
          const SizedBox(height: 2),
          Text(
            isEmpty ? 'set_your_delivery_location'.tr : addressText,
            style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: Theme.of(context).disabledColor,
              height: 1.4,
            ),
          ),
        ]),
      ),
      const SizedBox(width: Dimensions.paddingSizeSmall),
      _EditIconButton(onTap: onEdit),
    ]);
  }
}

class _ContactBlock extends StatelessWidget {
  final String name;
  final String? dialCode;
  final String phone;
  final VoidCallback onEdit;
  final VoidCallback onAdd;

  const _ContactBlock({
    required this.name,
    required this.dialCode,
    required this.phone,
    required this.onEdit,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasContact = name.trim().isNotEmpty && phone.trim().isNotEmpty;
    if (!hasContact) {
      return _AddContactInfoButton(onTap: onAdd);
    }
    final String formattedPhone = (dialCode != null && dialCode!.isNotEmpty) ? '$dialCode $phone' : phone;
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      const _IconBadge(icon: Icons.person_outline),
      const SizedBox(width: Dimensions.paddingSizeSmall),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
          const SizedBox(height: 2),
          Text(
            formattedPhone,
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
          ),
        ]),
      ),
      const SizedBox(width: Dimensions.paddingSizeSmall),
      _EditIconButton(onTap: onEdit),
    ]);
  }
}

class _AddContactInfoButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddContactInfoButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.add_circle_outline, size: 20, color: Theme.of(context).textTheme.bodyLarge!.color),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Text(
            'add_contact_info'.tr,
            style: robotoBold.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: Theme.of(context).textTheme.bodyLarge!.color,
            ),
          ),
        ]),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;

  const _IconBadge({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
      ),
      child: Icon(icon, size: 18, color: Theme.of(context).disabledColor),
    );
  }
}

class _EditIconButton extends StatelessWidget {
  final VoidCallback onTap;

  const _EditIconButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
        child: Icon(Icons.edit_outlined, size: 18, color: Theme.of(context).primaryColor),
      ),
    );
  }
}

class _DeliveryNoteField extends StatelessWidget {
  const _DeliveryNoteField();

  void _openPicker(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) {
      Get.dialog(const Dialog(child: DeliveryInstractionBottomSheetWidget()));
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const DeliveryInstractionBottomSheetWidget(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CheckoutController>(builder: (controller) {
      final bool hasInstruction = controller.selectedInstruction != -1;
      final String? selectedText = hasInstruction
          ? AppConstants.deliveryInstructionList[controller.selectedInstruction].tr
          : null;

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text.rich(
          TextSpan(children: [
            TextSpan(
              text: 'delivery_note'.tr,
              style: robotoBold.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            TextSpan(
              text: ' (${'optional'.tr})',
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).disabledColor,
              ),
            ),
          ]),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        InkWell(
          onTap: () => _openPicker(context),
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
              vertical: Dimensions.paddingSizeDefault,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              border: Border.all(
                color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
                width: 0.7,
              ),
            ),
            child: Row(children: [
              Expanded(
                child: Text(
                  hasInstruction ? selectedText! : 'select_your_instruction'.tr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: hasInstruction
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : Theme.of(context).hintColor,
                  ),
                ),
              ),
              if (hasInstruction)
                GestureDetector(
                  onTap: () => controller.setInstruction(-1),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
                    child: Icon(Icons.clear, size: 18, color: Theme.of(context).disabledColor),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
                  child: Icon(
                    Icons.keyboard_arrow_right,
                    size: 20,
                    color: Theme.of(context).disabledColor,
                  ),
                ),
            ]),
          ),
        ),
      ]);
    });
  }
}
