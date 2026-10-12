import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/cart/domain/models/online_cart_model.dart';

class BundleAmountHelper {
  /// What the bundles in [cartList] contribute to the basket, after the Happy Hour that
  /// may be stacking on them.
  ///
  /// A bundle is already the promotion. Only a Happy Hour and the Pro benefit stack on
  /// top of one, so every other discount — coupon, referral, the store's own rate — is
  /// worked out from a base with this amount taken out.
  ///
  /// Both kinds count. A BOGO offer and a product bundle are the same thing to this
  /// rule — `CartModel.isAtomicBundle` is the class they share — and only the figure
  /// carrying the Happy Hour differs: it stacks on a BOGO's price, so the discount is
  /// taken off there, and it replaces a product bundle's own rate, so `total_final_price`
  /// already holds it.
  /// What one product-bundle row saves against its members' own prices, and 0 when it
  /// saves nothing or the payload carries no base to compare against.
  ///
  /// The single definition of that figure: the cart breaks a row into base price and
  /// saving with it, and the checkout totals it over the basket with [bundleSaving].
  static double savingOf(BundleCartDetails details) {
    final double saving = details.totalBasePrice - details.totalFinalPrice;
    return saving > 0 ? saving : 0;
  }

  /// What every product bundle in [cartList] saves, for the bill's discount line.
  ///
  /// BOGO rows are not counted: their own saving is a Happy Hour stacking on the
  /// bundle, and it is already carried as a discount of its own.
  static double bundleSaving(List<CartModel?>? cartList) {
    double amount = 0;
    for(final CartModel? cart in cartList ?? const <CartModel?>[]) {
      if(cart != null && cart.isBundle) {
        amount += savingOf(cart.bundleDetails!);
      }
    }
    return amount;
  }

  static double netAmount(List<CartModel?>? cartList) {
    double amount = 0;
    for(final CartModel? cart in cartList ?? const <CartModel?>[]) {
      if(cart == null) {
        continue;
      }
      if(cart.isBogoBundle) {
        final BogoCartDetails details = cart.bogoDetails!;
        amount += details.totalFinalPrice ?? (details.totalPrice - details.totalDiscountAmount);
      } else if(cart.isBundle) {
        amount += cart.bundleDetails!.totalFinalPrice;
      }
    }
    return amount;
  }
}

// SUMMARY
// Works out what the bundle rows in a cart — BOGO offers and product bundles alike —
// contribute to the basket once their Happy Hour is accounted for, so the discounts that
// may not stack on a bundle are worked out from a base without that amount in it, and
// what a product bundle saves against its members' own prices for the bill to show.
