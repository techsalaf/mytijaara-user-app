import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart/common/widgets/custom_bottom_sheet_widget.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/coverage_dropdown_field.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/checkout/domain/models/coverage_list_model.dart';
import 'package:sixam_mart/features/location/screens/pick_location_screen.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Opens the delivery address + area/ZIP sheet.
///
/// Self-contained on purpose: it is opened from two places that know very
/// different things — the address row's edit button, and the place-order button
/// when it finds the pick missing — so it resolves everything it needs from
/// [CheckoutController] rather than being handed it.
void showDeliveryAddressCoverageSheet() {
  const Widget sheet = DeliveryAddressCoverageSheet();
  if (ResponsiveHelper.isDesktop(Get.context!)) {
    Get.dialog(const Dialog(child: SizedBox(width: Dimensions.webMaxWidth, child: sheet)));
  } else {
    showCustomBottomSheet(child: sheet);
  }
}

/// Opens the map picker, applies the picked address and refreshes the distance.
///
/// Shared by this sheet and `DeliverySection` so the distance recalculation
/// cannot drift between them: without it the distance stays as calculated on
/// init, and the delivery fee and order body are both priced for the old address.
Future<void> openCheckoutLocationPicker(CheckoutController controller, {required String initialSearchText}) async {
  final bool isGuest = AuthHelper.isGuestLoggedIn();
  await Get.to(
    () => PickLocationScreen(
      mode: PickLocationMode.checkout,
      initialSearchText: initialSearchText,
      onAddressPicked: (address) async {
        if (isGuest) {
          controller.setGuestAddress(address);
        } else {
          await controller.insertAddresses(address, notify: true);
        }
        final store = controller.store;
        if (store != null &&
            address.latitude != null && address.latitude!.isNotEmpty &&
            address.longitude != null && address.longitude!.isNotEmpty &&
            store.latitude != null && store.longitude != null) {
          controller.getDistanceInKM(
            LatLng(double.parse(address.latitude!), double.parse(address.longitude!)),
            LatLng(double.parse(store.latitude!), double.parse(store.longitude!)),
          );
        }
      },
    ),
    preventDuplicates: false,
  );
}

/// The delivery address plus the area / ZIP pick, in one sheet.
///
/// The two sit together because they answer the same question: the fee is priced
/// from the address *and* the pick, and a customer who changes one usually needs
/// to check the other.
class DeliveryAddressCoverageSheet extends StatefulWidget {
  const DeliveryAddressCoverageSheet({super.key});

  @override
  State<DeliveryAddressCoverageSheet> createState() => _DeliveryAddressCoverageSheetState();
}

class _DeliveryAddressCoverageSheetState extends State<DeliveryAddressCoverageSheet> {
  /// Held locally so the customer can back out of the sheet without their
  /// half-made pick requoting the order behind them. Committed on confirm.
  int? _pendingOptionId;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _pendingOptionId = Get.find<CheckoutController>().selectedCoverageOption?.id;
  }

  String _addressText(CheckoutController controller) {
    if (AuthHelper.isGuestLoggedIn()) {
      return controller.guestAddress?.address ?? controller.contactPersonAddressController.text;
    }
    final String? current = controller.address?.address;
    if (current != null && current.isNotEmpty) return current;
    return controller.contactPersonAddressController.text;
  }

  Future<void> _changeAddress(CheckoutController controller) async {
    // The sheet stays open across the picker, the way the address row behaves
    // elsewhere — the customer came here to finish both fields.
    await openCheckoutLocationPicker(controller, initialSearchText: _addressText(controller));
    if (mounted) setState(() {});
  }

  Future<void> _onConfirm(CheckoutController controller) async {
    if (_pendingOptionId == null) {
      setState(() => _submitted = true);
      showCustomSnackBar(controller.isZipCodeWiseDelivery ? 'please_select_zip_code'.tr : 'please_select_area'.tr);
      return;
    }
    Get.back();
    // Requotes on its own — the fee moves with the pick.
    await controller.setCoverageSelection(_pendingOptionId);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);

    return GetBuilder<CheckoutController>(builder: (CheckoutController controller) {
      final CoverageListModel? coverage = controller.coverageList;

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
              Dimensions.paddingSizeLarge, 0, Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge,
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [

              Text('delivery_address'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              _AddressField(
                addressText: _addressText(controller),
                onEdit: () => _changeAddress(controller),
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),

              if (coverage != null && coverage.requiresSelection)
                CoverageDropdownField(
                  coverage: coverage,
                  selectedId: _pendingOptionId,
                  showError: _submitted && _pendingOptionId == null,
                  onSelected: (int? id) => setState(() {
                    _pendingOptionId = id;
                    _submitted = false;
                  }),
                ),
              const SizedBox(height: Dimensions.paddingSizeExtraLarge),

              CustomButton(buttonText: 'confirm_information'.tr, onPressed: () => _onConfirm(controller)),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + Dimensions.paddingSizeSmall),
            ]),
          )),
        ]),
      );
    });
  }
}

class _AddressField extends StatelessWidget {
  final String addressText;
  final VoidCallback onEdit;

  const _AddressField({required this.addressText, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = addressText.trim().isEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeSmall,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        Icon(Icons.location_on_outlined, size: 18, color: Theme.of(context).disabledColor),
        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
        Expanded(
          child: Text(
            isEmpty ? 'set_your_delivery_location'.tr : addressText,
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
        GestureDetector(
          onTap: onEdit,
          behavior: HitTestBehavior.opaque,
          child: Icon(Icons.edit_outlined, size: 18, color: Theme.of(context).primaryColor),
        ),
      ]),
    );
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
        Dimensions.paddingSizeLarge, Dimensions.paddingSizeSmall,
        Dimensions.paddingSizeSmall, Dimensions.paddingSizeSmall,
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
