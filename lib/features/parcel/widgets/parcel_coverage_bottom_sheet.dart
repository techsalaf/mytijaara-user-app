import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/coverage_dropdown_field.dart';
import 'package:sixam_mart/common/widgets/custom_bottom_sheet_widget.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/checkout/domain/models/coverage_list_model.dart';
import 'package:sixam_mart/features/parcel/controllers/parcel_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// The area or ZIP code the sender's zone prices this parcel by.
///
/// Deliberately *not* the combined address + coverage sheet a store checkout
/// uses. A parcel has two addresses, each already edited through its own
/// sender/receiver sheet, so folding an address field in here would give the
/// customer a second way to edit the same thing and no way to tell which of the
/// two ends it meant.
class ParcelCoverageBottomSheet extends StatefulWidget {
  /// Fired after the pick is committed to the controller, so the caller can
  /// requote. Not fired when the customer backs out.
  final Future<void> Function() onConfirm;

  const ParcelCoverageBottomSheet({super.key, required this.onConfirm});

  static void open(BuildContext context, {required Future<void> Function() onConfirm}) {
    final Widget sheet = ParcelCoverageBottomSheet(onConfirm: onConfirm);
    if (ResponsiveHelper.isDesktop(context)) {
      Get.dialog(Dialog(child: SizedBox(width: 480, child: sheet)));
    } else {
      showCustomBottomSheet(child: sheet);
    }
  }

  @override
  State<ParcelCoverageBottomSheet> createState() => _ParcelCoverageBottomSheetState();
}

class _ParcelCoverageBottomSheetState extends State<ParcelCoverageBottomSheet> {
  /// Held locally so backing out of the sheet does not requote the parcel behind
  /// the customer on a half-made pick. Committed to the controller on confirm.
  int? _pendingOptionId;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _pendingOptionId = Get.find<ParcelController>().selectedCoverageOption?.id;
  }

  Future<void> _onConfirm(ParcelController controller) async {
    if (_pendingOptionId == null) {
      setState(() => _submitted = true);
      showCustomSnackBar(controller.isZipCodeWiseDelivery ? 'please_select_zip_code'.tr : 'please_select_area'.tr);
      return;
    }
    controller.setCoverageSelection(_pendingOptionId, notify: false);
    Get.back();
    // The fee moves with the pick, so the caller requotes.
    await widget.onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);

    return Container(
      width: Dimensions.webMaxWidth,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: ResponsiveHelper.isMobile(context)
            ? const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge))
            : const BorderRadius.all(Radius.circular(Dimensions.radiusExtraLarge)),
      ),
      child: GetBuilder<ParcelController>(builder: (ParcelController controller) {
        final CoverageListModel? coverage = controller.coverage;

        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [

          _SheetHeader(showDragHandle: !isDesktop, onClose: () => Get.back()),

          Flexible(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              Dimensions.paddingSizeLarge, 0, Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge,
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [

              Text('area_zip_code'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
              const SizedBox(height: 2),
              Text(
                'select_the_area_your_parcel_will_be_delivered_to'.tr,
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor,
                ),
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
        ]);
      }),
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
              alignment: Alignment.center,
              child: Icon(Icons.close, size: 20, color: Theme.of(context).disabledColor),
            ),
          ),
        ),
      ]),
    );
  }
}
