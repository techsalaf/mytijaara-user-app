import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class ParcelQuoteErrorWidget extends StatelessWidget {
  const ParcelQuoteErrorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Listens on its own rather than reading the controller inline: the parcel
    // screens hold this widget as a const child, which Flutter skips rebuilding
    // when the screen around it repaints, so an inline read would stay frozen on
    // whatever the quote had answered when the screen was first painted.
    return GetBuilder<CheckoutController>(builder: (checkoutController) {
      final String message = checkoutController.summaryError ?? '';
      if (message.isEmpty) return const SizedBox();

      return Container(
        margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeSmall,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3), width: 0.7),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.error_outline, size: 18, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Text(
              message,
              style: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ]),
      );
    });
  }
}

// SUMMARY
// Error banner for the parcel screens. Shows the reason the server refused the parcel
// quote — an out-of-coverage receiver, for instance — and draws nothing while the last
// quote succeeded or failed for no stated reason.
