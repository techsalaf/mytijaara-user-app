import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/cart/domain/models/online_cart_model.dart';
import 'package:sixam_mart/helper/bundle_amount_helper.dart';

/// What a product bundle contributes to the bill's discount line.
///
/// A bundle row is billed at its bundle price, so charging that net figure against
/// "item price" left the discount line reading zero on a bundle that plainly discounts.
/// The cart and the checkout now both split the row into the members' own total and the
/// saving, and this is the single definition of that saving.

BundleCartDetails _details({required double basePrice, required double finalPrice, int quantity = 1}) =>
    BundleCartDetails.fromJson(jsonDecode(jsonEncode(<String, dynamic>{
      'bundle_group_id': 'g-1', 'bundle_id': 18, 'name': 'test', 'quantity': quantity,
      'base_price': basePrice, 'bundle_price': finalPrice, 'final_price': finalPrice,
      'total_final_price': finalPrice * quantity, 'is_available': true,
    })) as Map<String, dynamic>);

BogoCartDetails _bogo({required double totalPrice, required double totalDiscount}) =>
    BogoCartDetails.fromJson(jsonDecode(jsonEncode(<String, dynamic>{
      'bogo_group_id': '77', 'bundle_id': 5, 'quantity': 1, 'bundle_price': totalPrice,
      'total_price': totalPrice, 'total_final_price': totalPrice - totalDiscount,
      'total_discount_amount': totalDiscount, 'is_happy_hour': true, 'is_available': true,
    })) as Map<String, dynamic>);

void main() {
  group('what one bundle row saves', () {
    test('the reported row: 1790 of members billed at 1611', () {
      expect(BundleAmountHelper.savingOf(_details(basePrice: 1790, finalPrice: 1611)), 179);
    });

    test('it counts every copy, not just the first', () {
      expect(BundleAmountHelper.savingOf(_details(basePrice: 1790, finalPrice: 1611, quantity: 2)), 358);
    });

    test('a bundle priced at its members total saves nothing', () {
      expect(BundleAmountHelper.savingOf(_details(basePrice: 3498, finalPrice: 3498)), 0);
    });

    test('a base the payload never sent cannot read as a negative saving', () {
      // Without the clamp this returns -1611, which would inflate the bill.
      expect(BundleAmountHelper.savingOf(_details(basePrice: 0, finalPrice: 1611)), 0);
    });
  });

  group('what the basket saves', () {
    test('every product bundle is counted', () {
      final List<CartModel?> cart = <CartModel?>[
        CartModel.bundle(bundleDetails: _details(basePrice: 1790, finalPrice: 1611)),
        CartModel.bundle(bundleDetails: _details(basePrice: 780, finalPrice: 390)),
      ];
      expect(BundleAmountHelper.bundleSaving(cart), 569);
    });

    test('a BOGO row is left out — its Happy Hour is already a discount of its own', () {
      // Counting it here would take the same saving off the bill twice.
      final List<CartModel?> cart = <CartModel?>[
        CartModel.bogoBundle(bogoDetails: _bogo(totalPrice: 900, totalDiscount: 90)),
      ];
      expect(BundleAmountHelper.bundleSaving(cart), 0);
    });

    test('an empty or null basket saves nothing', () {
      expect(BundleAmountHelper.bundleSaving(const <CartModel?>[]), 0);
      expect(BundleAmountHelper.bundleSaving(null), 0);
    });
  });
}
