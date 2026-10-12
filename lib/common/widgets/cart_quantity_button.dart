import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/quantity_decrement_icon.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// The shared cart control for product and bundle cards.
///
/// Three states: a `+` while [quantity] is 0, a count chip once something is in
/// the cart, and a `[- count +]` stepper that collapses back to the chip after
/// a short idle. It owns only the presentation — the caller decides what an
/// add / increment / decrement means and passes `null` to disable one.
class CartQuantityButton extends StatefulWidget {
  final int quantity;
  final Future<void> Function()? onAdd;
  final Future<void> Function()? onIncrement;
  /// Called for every `-`, including the last one — the caller removes the row
  /// when [quantity] is 1.
  final Future<void> Function()? onDecrement;
  final VoidCallback? onBeforeAdd;
  /// A cart request started elsewhere for this card; shows a spinner on the chip.
  final bool isLoading;
  /// Custom look for the `+`; receives whether an add is in flight.
  final Widget Function(BuildContext context, bool isAdding)? addBuilder;

  const CartQuantityButton({
    super.key, required this.quantity, required this.onAdd, required this.onIncrement,
    required this.onDecrement, this.onBeforeAdd, this.isLoading = false, this.addBuilder,
  });

  @override
  State<CartQuantityButton> createState() => _CartQuantityButtonState();
}

class _CartQuantityButtonState extends State<CartQuantityButton> {
  // The expanded [- count +] view auto-collapses to the count chip after this idle delay.
  static const Duration _autoCollapseDelay = Duration(seconds: 3);

  // Shared height for the in-cart states (chip & [- count +]) so switching between
  // them never shifts the control vertically.
  static const double _controlHeight = 32;

  bool _isExpanded = false;
  bool _isAdding = false;
  bool _isBusy = false;
  Timer? _collapseTimer;

  // Show the [- count +] view and (re)start the idle timer that collapses it
  // back to the count chip. Called on add / +/- taps / tapping the count chip.
  void _keepExpanded() {
    _collapseTimer?.cancel();
    if(!_isExpanded) {
      setState(() => _isExpanded = true);
    }
    _collapseTimer = Timer(_autoCollapseDelay, () {
      if(mounted) {
        setState(() => _isExpanded = false);
      }
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _isBusy = true);
    try {
      await action();
    } finally {
      if(mounted) setState(() => _isBusy = false);
    }
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int qty = widget.quantity;

    // Note: _isExpanded is only consulted when qty > 0, so the qty-0 ("+")
    // render ignores it — no need to reset it here (resetting during the brief
    // post-tap window before the async add lands would skip the expanded view).
    final String stateKey = qty == 0 ? 'add' : (_isExpanded ? 'expanded' : 'chip');
    final Widget content = qty == 0
        ? _buildAddButton(context)
        : _isExpanded
            ? _buildExpanded(context, qty)
            : _buildCountChip(context, qty);

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      alignment: Alignment.centerRight,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(animation),
            alignment: Alignment.centerRight,
            child: child,
          ),
        ),
        // Anchor both the outgoing and incoming child to the right so the control
        // grows/shrinks from a fixed right edge instead of drifting horizontally.
        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) => Stack(
          alignment: Alignment.centerRight,
          children: [
            ...previousChildren,
            ?currentChild,
          ],
        ),
        child: KeyedSubtree(key: ValueKey<String>('cart-quantity-$stateKey'), child: content),
      ),
    );
  }

  // State A — only the "+" button (not in cart).
  Widget _buildAddButton(BuildContext context) {
    return InkWell(
      onTap: widget.onAdd == null || _isAdding ? null : () async {
        if(AddressHelper.getUserAddressFromSharedPref() == null) {
          Get.find<LocationController>().navigateToLocationScreen('home', canRoute: true);
          return;
        }
        widget.onBeforeAdd?.call();
        _keepExpanded();
        setState(() => _isAdding = true);
        try {
          await widget.onAdd!();
        } finally {
          if(mounted) setState(() => _isAdding = false);
        }
      },
      child: widget.addBuilder?.call(context, _isAdding) ?? Container(
        height: 25, width: 25,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          color: Theme.of(context).cardColor,
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
        ),
        child: _isAdding
            ? const Padding(
                padding: EdgeInsets.all(4),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.add, size: 20, color: Theme.of(context).primaryColor),
      ),
    );
  }

  // State C — compact chip showing just the count; tapping expands to [- count +].
  Widget _buildCountChip(BuildContext context, int qty) {
    final bool loading = widget.isLoading || _isBusy;
    return InkWell(
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      onTap: _keepExpanded,
      child: Container(
        height: _controlHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall + 2),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 0)],
        ),
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        child: loading
            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : _animatedCount(qty, robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
      ),
    );
  }

  // State B — full [- count +] control.
  Widget _buildExpanded(BuildContext context, int qty) {
    return Container(
      height: _controlHeight,
      width: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        InkWell(
          onTap: widget.onDecrement == null ? null : () {
            if(qty > 1) {
              _keepExpanded();
            } else {
              // Last one removed → returns to the "+" button; no need to stay expanded.
              _collapseTimer?.cancel();
            }
            _run(widget.onDecrement!);
          },
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
            child: QuantityDecrementIcon(quantity: qty, size: 16),
          ),
        ),

        // Keep the number visible and roll it on +/- (no spinner swap) so the
        // control never blinks during quantity changes.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
          child: _animatedCount(qty, robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
        ),

        InkWell(
          onTap: widget.onIncrement == null ? null : () {
            _keepExpanded();
            _run(widget.onIncrement!);
          },
          child: const Padding(
            padding: EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
            child: Icon(Icons.add, size: 16),
          ),
        ),
      ]),
    );
  }

  // Smoothly rolls the count from the old value to the new one (slide + fade),
  // keyed on the value so each +/- change animates instead of snapping.
  Widget _animatedCount(int qty, TextStyle style) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) => ClipRect(
        child: FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero).animate(animation),
            child: child,
          ),
        ),
      ),
      child: Text(qty.toString(), key: ValueKey<int>(qty), style: style),
    );
  }
}
