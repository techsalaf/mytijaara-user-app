import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/models/measurement_unit_model.dart';
import 'package:sixam_mart/common/widgets/custom_bottom_sheet_widget.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_loader.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/parcel/controllers/parcel_controller.dart';
import 'package:sixam_mart/features/parcel/domain/models/parcel_category_model.dart';
import 'package:sixam_mart/features/parcel/domain/models/parcel_tier_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/helper/zone_module_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// The three answers a parcel fee is priced from — category, weight band, size
/// class — in one sheet.
///
/// They sit together because they answer the same question: each adds a flat
/// amount on top of whatever the zone's delivery rule priced, and a customer
/// changing one usually wants to check the others.
///
/// A tier section is drawn only while its switch is on **and** it offers bands.
/// The two switches are independent, so a zone pricing by weight and not by size
/// shows two sections rather than three, and a zone charging a flat parcel fee
/// shows only the category.
class SetParcelInformationBottomSheet extends StatefulWidget {
  final ParcelCategoryModel selectedCategory;
  final void Function(ParcelCategoryModel category) onConfirm;

  const SetParcelInformationBottomSheet({super.key, required this.selectedCategory, required this.onConfirm});

  static void open(BuildContext context, {required ParcelCategoryModel selectedCategory,
    required void Function(ParcelCategoryModel category) onConfirm,
  }) {
    final Widget sheet = SetParcelInformationBottomSheet(selectedCategory: selectedCategory, onConfirm: onConfirm);
    if (ResponsiveHelper.isDesktop(context)) {
      Get.dialog(Dialog(child: SizedBox(width: 480, child: sheet)));
    } else {
      showCustomBottomSheet(child: sheet, height: MediaQuery.of(context).size.height * 0.85);
    }
  }

  static Future<void> startFromCategory(ParcelCategoryModel category) async {
    final AddressModel? address = AddressHelper.getUserAddressFromSharedPref();
    if (address == null) {
      Get.find<LocationController>().navigateToLocationScreen('home', canRoute: true);
      return;
    }

    final ParcelController controller = Get.find<ParcelController>();
    controller.clearTierSelections(notify: false);
    final int? moduleId = Get.find<SplashController>().module?.id;
    final int? zoneId = ZoneModuleHelper.resolveZoneId(address, moduleId: moduleId);
    if (zoneId != null) {
      // Bands are priced per zone, so they are loaded against the saved address.
      Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);
      await controller.loadParcelTiers(zoneId: zoneId, moduleId: moduleId);
      if (Get.isDialogOpen ?? false) Get.back();
    }

    // A zone charging a flat parcel fee leaves the sheet nothing to ask.
    if (!controller.needsWeightSelection && !controller.needsDimensionSelection) {
      Get.toNamed(RouteHelper.getParcelLocationRoute(category));
      return;
    }

    _openForCategory(category, controller);
  }

  static void _openForCategory(ParcelCategoryModel category, ParcelController controller) {
    final BuildContext? context = Get.context;
    if (context == null) return;
    open(context, selectedCategory: category, onConfirm: (ParcelCategoryModel selected) {
      controller.holdTierSelectionForNextEntry();
      Get.toNamed(RouteHelper.getParcelLocationRoute(selected));
    });
  }

  @override
  State<SetParcelInformationBottomSheet> createState() => _SetParcelInformationBottomSheetState();
}

class _SetParcelInformationBottomSheetState extends State<SetParcelInformationBottomSheet> {
  /// Held locally so backing out of the sheet does not requote the order behind
  /// the customer on a half-made pick. Committed to the controller on confirm.
  late ParcelCategoryModel _category;
  int? _weightId;
  int? _dimensionId;

  @override
  void initState() {
    super.initState();
    final ParcelController controller = Get.find<ParcelController>();
    _category = widget.selectedCategory;
    _weightId = controller.selectedWeightId;
    _dimensionId = controller.selectedDimensionId;
  }

  bool _isAnswered(ParcelController controller) =>
      (!controller.needsWeightSelection || _weightId != null)
      && (!controller.needsDimensionSelection || _dimensionId != null);

  void _onConfirm(ParcelController controller) {
    controller.setWeightSelection(_weightId, notify: false);
    controller.setDimensionSelection(_dimensionId, notify: false);
    Get.back();
    widget.onConfirm(_category);
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
      child: GetBuilder<ParcelController>(builder: (parcelController) {
        final List<ParcelCategoryModel> categories = parcelController.parcelCategoryList ?? <ParcelCategoryModel>[];
        final ParcelTierListModel<ParcelWeightModel>? weightTier = parcelController.weightTier;
        final ParcelTierListModel<ParcelDimensionModel>? dimensionTier = parcelController.dimensionTier;

        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [

          _SheetHeader(showDragHandle: !isDesktop),

          Flexible(
            // The horizontal inset lives on the individual sections rather than
            // here, so the chip rows can run the full width of the sheet and
            // scroll off both edges. A scroller stopping short of the padding
            // reads as a clipped row rather than a scrollable one.
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [

                if (categories.isNotEmpty) ...[
                  _Inset(child: _SectionLabel(label: 'parcel_type'.tr)),
                  _ChipRow(
                    chips: categories.map((ParcelCategoryModel category) => _ChoiceChip(
                      label: category.name ?? '',
                      selected: category.id == _category.id,
                      onTap: () => setState(() => _category = category),
                    )).toList(),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeLarge),
                ],

                // Absent whenever the tier is off, or on with nothing configured.
                // An empty list is the answer, not a failure — so no empty picker.
                if (parcelController.needsWeightSelection) ...[
                  _Inset(child: _SectionLabel(label: 'item_weight'.tr)),
                  _ChipRow(
                    chips: weightTier!.data.map((ParcelWeightModel weight) => _ChoiceChip(
                      label: _weightLabel(weight, weightTier.unit),
                      selected: weight.id == _weightId,
                      onTap: () => setState(() => _weightId = weight.id),
                    )).toList(),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeLarge),
                ],

                // Stays a vertical list: the bounds make these rows far too wide
                // to read side by side, and only one can be picked.
                if (parcelController.needsDimensionSelection) ...[
                  _Inset(child: _SectionLabel(label: 'item_dimension'.tr)),
                  ...dimensionTier!.data.map((ParcelDimensionModel dimension) => _Inset(
                    child: _DimensionRow(
                      name: dimension.name ?? '',
                      bounds: dimension.bounds(dimensionTier.unit),
                      selected: dimension.id == _dimensionId,
                      onTap: () => setState(() => _dimensionId = dimension.id),
                    ),
                  )),
                  const SizedBox(height: Dimensions.paddingSizeLarge),
                ],

                const SizedBox(height: Dimensions.paddingSizeSmall),
                _Inset(
                  child: CustomButton(
                    buttonText: 'confirm_information'.tr,
                    onPressed: _isAnswered(parcelController) ? () => _onConfirm(parcelController) : null,
                  ),
                ),
              ]),
            ),
          ),
        ]);
      }),
    );
  }

  /// `Light (2~4 kg)` — the band's own name carries the meaning, the range makes
  /// it checkable. Falls back to whichever half the API actually sent.
  String _weightLabel(ParcelWeightModel weight, MeasurementUnitModel? unit) {
    final String name = weight.name ?? '';
    final String range = weight.range(unit);
    if (name.isEmpty) return range;
    if (range.isEmpty) return name;
    return '$name ($range)';
  }
}

class _SheetHeader extends StatelessWidget {
  final bool showDragHandle;

  const _SheetHeader({required this.showDragHandle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeLarge, Dimensions.paddingSizeSmall,
        Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault,
      ),
      child: Stack(alignment: Alignment.topCenter, children: [
        if (showDragHandle)
          Container(
            height: 4,
            width: 36,
            decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        // Align(
        //   alignment: AlignmentDirectional.centerStart,
        //   child: Padding(
        //     padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
        //     child: Text(title, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
        //   ),
        // ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: GestureDetector(
            onTap: () => Get.back(),
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

/// The sheet's standard horizontal inset.
///
/// Applied per section rather than once on the scroll view, so the chip rows can
/// opt out of it and span the full width.
class _Inset extends StatelessWidget {
  final Widget child;

  const _Inset({required this.child});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
    child: child,
  );
}

/// One row of choice chips, scrolled horizontally.
///
/// A [Wrap] would reflow a long list onto a second and third line and push the
/// rest of the sheet — including the confirm button — off the bottom. Scrolling
/// keeps every section at a fixed height however many bands a zone configures.
///
/// The inset is the scroll view's own padding, not a wrapper, so the first and
/// last chip line up with the section labels while the row still scrolls past
/// both edges.
class _ChipRow extends StatelessWidget {
  final List<Widget> chips;

  const _ChipRow({required this.chips});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
      // Trackpads and mice on web/desktop, where there is no touch drag.
      physics: const BouncingScrollPhysics(),
      child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
        for (int i = 0; i < chips.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: Dimensions.paddingSizeSmall),
          chips[i],
        ],
      ]),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: Text(label, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall + 2,
        ),
        decoration: BoxDecoration(
          color: selected ? primary : Theme.of(context).disabledColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
          border: Border.all(
            color: selected ? primary : Theme.of(context).disabledColor.withValues(alpha: 0.4),
            width: 0.7,
          ),
        ),
        child: Text(
          label,
          style: selected ? robotoSemiBold.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: Theme.of(context).cardColor,
          ) : robotoMedium.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }
}

class _DimensionRow extends StatelessWidget {
  final String name;
  final String bounds;
  final bool selected;
  final VoidCallback onTap;

  const _DimensionRow({required this.name, required this.bounds, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeDefault,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(
            color: selected ? primary : Theme.of(context).disabledColor.withValues(alpha: 0.3),
            width: selected ? 1 : 0.7,
          ),
        ),
        child: Row(children: [
          Expanded(
            child: Text(
              name, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          if (bounds.isNotEmpty)
            Text(
              bounds,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor,
              ),
            ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            size: 20,
            color: selected ? primary : Theme.of(context).disabledColor,
          ),
        ]),
      ),
    );
  }
}

// SUMMARY
// Sheet that collects what a parcel's fee is priced from — its category, and the
// weight band and size class the sender's zone prices by. Opened from a category card
// before the parcel has a route, and from the set-location screen to edit any of them;
// confirming commits the picks to the parcel controller.
