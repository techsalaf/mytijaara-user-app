import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_drop_down_button.dart';
import 'package:sixam_mart/features/checkout/domain/models/coverage_list_model.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// The labelled Area / ZIP dropdown, shared by the store checkout and the parcel
/// flow.
///
/// A real dropdown rather than a tap-through to another sheet: the pick is one
/// value from a short list, and stacking a second bottom sheet on top of the one
/// it is opened from buries what the customer came there to check.
///
/// Shared rather than copied because of [_selectionIsValid] below — a guard that
/// is easy to lose in a copy and whose absence is a hard assert, not a cosmetic
/// bug.
///
/// [CustomDropdownButton] is `String`-keyed while coverage options carry int
/// ids, so ids round-trip through `toString()` / `int.tryParse` — lossless, and
/// it keeps the shared widget's styling instead of hand-rolling a second one.
class CoverageDropdownField extends StatelessWidget {
  final CoverageListModel coverage;
  final int? selectedId;

  /// Draws the "please select…" message under the field. The sheets validate on
  /// their own confirm button, so this stays false until the customer has tried.
  final bool showError;
  final ValueChanged<int?> onSelected;

  const CoverageDropdownField({super.key, required this.coverage, required this.selectedId,
    required this.showError, required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    // An option with no id cannot be posted back, and two null values would also
    // break the dropdown's "exactly one item per value" requirement.
    final List<CoverageOption> options =
        coverage.coverage.where((CoverageOption option) => option.id != null).toList();

    // Passing a value the list does not contain makes DropdownButtonFormField2
    // assert. That happens when the coverage list reloads — a new store, or a
    // changed address — while a stale pick is still held.
    final bool selectionIsValid =
        selectedId != null && options.any((CoverageOption option) => option.id == selectedId);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text.rich(TextSpan(children: <InlineSpan>[
        TextSpan(
          text: 'area_zip_code'.tr,
          style: robotoRegular.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        TextSpan(
          text: ' *',
          style: robotoRegular.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ])),
      const SizedBox(height: Dimensions.paddingSizeExtraSmall),

      CustomDropdownButton(
        hintText: 'select_area_zip_code'.tr,
        selectedValue: selectionIsValid ? selectedId.toString() : null,
        backgroundColor: Theme.of(context).cardColor,
        // The sheet validates on Confirm and shows its own message below; the
        // field's built-in validator would otherwise mark it invalid on sight.
        validator: (String? value) => null,
        dropdownMenuItems: options.map((CoverageOption option) => DropdownMenuItem<String>(
          value: option.id.toString(),
          child: Text(
            option.name ?? '',
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
        )).toList(),
        onChanged: (String? value) => onSelected(value == null ? null : int.tryParse(value)),
      ),

      if (showError) ...[
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Text(
          coverage.isZipCode ? 'please_select_zip_code'.tr : 'please_select_area'.tr,
          style: robotoRegular.copyWith(
            fontSize: Dimensions.fontSizeExtraSmall,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    ]);
  }
}
