import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/features/bogo_offer/domain/models/bogo_offer_model.dart';
import 'package:sixam_mart/features/cart/domain/models/online_cart_model.dart';
import 'package:sixam_mart/helper/product_image_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';

/// Where a BOGO bundle member's picture comes from, on both screens that show one.
///
/// The two endpoints spell it differently. `bogo/offers/{id}` puts a bare file name on
/// the member's own `image_full_url`, which the offer sheet resolves against the product
/// storage path. `cart/get-all` sends no `image_full_url` anywhere — the file name is
/// `image` on the nested `item` — so the cart row read nothing and every thumbnail fell
/// back to the placeholder while the sheet showed the photo.
void main() {
  const String bareName = '2026-09-14-6aa7d00f791f9.webp';
  const String resolved = '${AppConstants.baseUrl}/storage/app/public/product/$bareName';

  Map<String, dynamic> bogoDetails({required List<dynamic> buyItems, List<dynamic> freeItems = const <dynamic>[]}) =>
      <String, dynamic>{
        'bogo_group_id': 'g-1', 'quantity': 1, 'bundle_price': 100, 'total_price': 100,
        'is_available': true, 'buy_items': buyItems, 'free_items': freeItems,
      };

  group('ProductImageHelper.fullUrl', () {
    test('resolves a bare file name against the product storage path', () {
      expect(ProductImageHelper.fullUrl(bareName), resolved);
    });

    test('leaves an absolute URL alone', () {
      expect(ProductImageHelper.fullUrl(resolved), resolved);
    });

    test('keeps an imageless member empty rather than building a broken URL', () {
      expect(ProductImageHelper.fullUrl(''), '');
      expect(ProductImageHelper.fullUrl(null), isNull);
    });
  });

  group('cart row thumbnails', () {
    // Trimmed from a real cart/get-all row: no image_full_url anywhere, the file name
    // sits on item.image, and `images` is empty for the free member.
    Map<String, dynamic> cartMember(String image) => <String, dynamic>{
      'id': 5680, 'item_id': 280, 'is_free_item': 0, 'price': 2.0, 'quantity': 1,
      'item': <String, dynamic>{'id': 280, 'name': 'Samosa', 'image': image, 'images': <dynamic>[]},
    };

    test('reads item.image, which is all the cart payload carries — the bug', () {
      final BogoCartDetails details = BogoCartDetails.fromJson(bogoDetails(
        buyItems: <dynamic>[cartMember(bareName)],
      ));

      expect(details.buyItemThumbnails, <String>[resolved]);
    });

    test('buy and free members both resolve', () {
      const String freeName = '2026-09-10-6aa27d212209e.webp';
      final BogoCartDetails details = BogoCartDetails.fromJson(bogoDetails(
        buyItems: <dynamic>[cartMember(bareName)],
        freeItems: <dynamic>[cartMember(freeName)],
      ));

      expect(details.buyItemThumbnails, <String>[resolved]);
      expect(details.freeItemThumbnails, <String>['${AppConstants.baseUrl}/storage/app/public/product/$freeName']);
      expect(details.itemThumbnails.length, 2);
    });

    test('image_full_url still wins where a payload carries one', () {
      final BogoCartDetails details = BogoCartDetails.fromJson(bogoDetails(
        buyItems: <dynamic>[<String, dynamic>{'image_full_url': resolved}],
      ));

      expect(details.buyItemThumbnails, <String>[resolved]);
    });

    test('a member with no picture still takes a slot', () {
      final BogoCartDetails details = BogoCartDetails.fromJson(bogoDetails(
        buyItems: <dynamic>[
          cartMember(bareName),
          <String, dynamic>{'item': <String, dynamic>{'name': 'no picture'}},
        ],
      ));

      expect(details.buyItemThumbnails, <String>[resolved, '']);
    });

    test('a member with no item node at all does not throw', () {
      final BogoCartDetails details = BogoCartDetails.fromJson(bogoDetails(
        buyItems: <dynamic>[<String, dynamic>{'item': null}],
      ));

      expect(details.buyItemThumbnails, <String>['']);
    });
  });

  group('offer sheet resolves the same member the same way', () {
    test('the two endpoints spell it differently but land on one URL', () {
      // bogo/offers/{id}: the file name is on the member's own image_full_url.
      final BogoBundleModel bundle = BogoBundleModel.fromJson(<String, dynamic>{
        'bundle_id': 1,
        'buy_items': <dynamic>[<String, dynamic>{'id': 280, 'image_full_url': bareName}],
        'free_items': <dynamic>[],
      });
      // cart/get-all: the file name is on the nested item's image.
      final BogoCartDetails details = BogoCartDetails.fromJson(bogoDetails(
        buyItems: <dynamic>[
          <String, dynamic>{'item': <String, dynamic>{'id': 280, 'image': bareName}},
        ],
      ));

      expect(bundle.buyItems.single.item.imageFullUrl, resolved);
      expect(details.buyItemThumbnails.single, bundle.buyItems.single.item.imageFullUrl);
    });
  });
}

// SUMMARY
// Covers how a BOGO bundle member's picture is resolved: a bare file name becomes a
// full product-storage URL, an absolute one is left alone, an imageless member keeps
// its empty slot, and the cart row and the offer sheet agree on the result.
