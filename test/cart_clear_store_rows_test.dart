import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/cart/domain/models/online_cart_model.dart' show BogoCartDetails, BundleCartDetails;
import 'package:sixam_mart/features/item/domain/models/item_model.dart';

CartModel regularRow(int id, int? storeId) => CartModel(
  id, 100, 100, <Variation>[], <List<bool?>>[], 0, 1, <AddOn>[], <AddOns>[], false, null, Item(storeId: storeId), null,
);

CartModel bundleRow(String groupId, int storeId) => CartModel.bundle(
  bundleDetails: BundleCartDetails(bundleGroupId: groupId, quantity: 1),
  storeId: storeId,
);

CartModel bogoRow(String groupId, int storeId) => CartModel.bogoBundle(
  bogoDetails: BogoCartDetails(
    bogoGroupId: groupId, quantity: 1, bundlePrice: 100, totalPrice: 100, isAvailable: true,
    itemThumbnails: const <String>[], buyItemThumbnails: const <String>[], freeItemThumbnails: const <String>[],
  ),
  storeId: storeId,
);

List<CartModel> clearedWithNewRule(List<CartModel> rows, int storeId) =>
    List<CartModel>.of(rows)..removeWhere((CartModel c) => c.storeId == storeId);

List<CartModel> clearedWithOldRule(List<CartModel> rows, int storeId) =>
    List<CartModel>.of(rows)..removeWhere((CartModel c) => c.item?.storeId == storeId);

void main() {
  group('regular rows behave exactly as before', () {
    test('storeId is the item store, the value the old rule read', () {
      final CartModel row = regularRow(1, 45);
      expect(row.storeId, 45);
      expect(row.storeId, row.item?.storeId);
    });

    test('an item with no store stays null rather than borrowing one', () {
      final CartModel row = regularRow(1, null);
      expect(row.storeId, isNull);
      expect(row.item?.storeId, isNull);
    });

    test('clearing a regular-only cart matches the old rule row for row', () {
      final List<CartModel> rows = <CartModel>[regularRow(1, 45), regularRow(2, 45), regularRow(3, 99)];

      final List<CartModel> newResult = clearedWithNewRule(rows, 45);
      final List<CartModel> oldResult = clearedWithOldRule(rows, 45);

      expect(newResult.map((CartModel c) => c.id), oldResult.map((CartModel c) => c.id));
      expect(newResult.map((CartModel c) => c.id), <int>[3]);
    });

    test('regular rows of another store are never touched', () {
      final List<CartModel> rows = <CartModel>[regularRow(1, 99), regularRow(2, 99)];
      expect(clearedWithNewRule(rows, 45), hasLength(2));
    });
  });

  group('bundle and BOGO rows now clear with their store', () {
    test('they carry no item, so their store comes from the row', () {
      expect(bundleRow('b-1', 45).item, isNull);
      expect(bundleRow('b-1', 45).storeId, 45);
      expect(bogoRow('g-1', 45).item, isNull);
      expect(bogoRow('g-1', 45).storeId, 45);
    });

    test('a mixed cart clears every row of the store and keeps the rest', () {
      final List<CartModel> rows = <CartModel>[
        regularRow(1, 45), bogoRow('g-1', 45), bundleRow('b-1', 45),
        regularRow(2, 99), bundleRow('b-2', 99),
      ];

      final List<CartModel> remaining = clearedWithNewRule(rows, 45);

      expect(remaining, hasLength(2));
      expect(remaining.every((CartModel c) => c.storeId == 99), isTrue);
    });

    test('the old rule left bundle and BOGO rows behind, which was the bug', () {
      final List<CartModel> rows = <CartModel>[regularRow(1, 45), bogoRow('g-1', 45), bundleRow('b-1', 45)];

      final List<CartModel> remaining = clearedWithOldRule(rows, 45);

      expect(remaining, hasLength(2));
      expect(remaining.every((CartModel c) => c.isAtomicBundle), isTrue);
    });
  });
}

// SUMMARY
// Tests for clearing one store's cart rows. Confirms regular items are removed exactly as
// before, rows of other stores are kept, and BOGO and bundle rows now clear with their store.
