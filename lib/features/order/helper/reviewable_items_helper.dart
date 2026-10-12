import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_details_model.dart';

class ReviewableItemsHelper {
  /// The items of [orderDetails] a customer can rate, one entry per distinct item.
  ///
  /// A bundle or BOGO line carries no item of its own — `item_details` is null on it —
  /// so it used to be skipped outright and everything inside it went unreviewable. Its
  /// members are ordinary items the customer received, and each is rated on its own, so
  /// every one becomes an entry here.
  ///
  /// Deduplicated by item id across the whole order: an item bought both on its own and
  /// inside a bundle is one thing to rate, and the review posts one id.
  static List<OrderDetailsModel> from(List<OrderDetailsModel>? orderDetails) {
    final List<OrderDetailsModel> reviewable = <OrderDetailsModel>[];
    final Set<int> seen = <int>{};

    void add(OrderDetailsModel entry) {
      final int? id = entry.itemDetails?.id;
      if(id == null || !seen.add(id)) {
        return;
      }
      reviewable.add(entry);
    }

    for(final OrderDetailsModel detail in orderDetails ?? const <OrderDetailsModel>[]) {
      if(detail.isBogoBundle) {
        final OrderBogoDetailsModel? bogo = detail.bogoDetails;
        // The line's quantity counts bundles and a member's counts per bundle, so what the
        // customer received — and the card shows — is the two multiplied.
        final int bundles = detail.quantity ?? bogo?.quantity ?? 1;
        for(final OrderBogoItemModel member in <OrderBogoItemModel>[...?bogo?.buyItems, ...?bogo?.freeItems]) {
          // A free item was still delivered, so it is rated like any other.
          final OrderDetailsModel? entry = _entry(
            detail: detail, itemId: member.itemId, name: member.name,
            imageFullUrl: member.imageFullUrl, price: member.price,
            quantity: (member.quantity ?? 1) * bundles,
          );
          if(entry != null) add(entry);
        }
        continue;
      }

      if(detail.isBundle) {
        final OrderBundleDetailsModel? bundle = detail.bundleDetails;
        final int bundles = detail.quantity ?? bundle?.quantity ?? 1;
        for(final OrderBundleItemModel member in bundle?.items ?? const <OrderBundleItemModel>[]) {
          final OrderDetailsModel? entry = _entry(
            detail: detail, itemId: member.itemId, name: member.name,
            imageFullUrl: member.imageFullUrl, price: member.price,
            quantity: (member.quantity ?? 1) * bundles,
          );
          if(entry != null) add(entry);
        }
        continue;
      }

      if(detail.itemDetails != null) {
        add(detail);
      }
    }

    return reviewable;
  }

  /// A member written out as the row the review screen reads: it takes the name and price
  /// off `itemDetails` and posts that id, so a member carrying neither cannot be rated.
  ///
  /// [detail] is the line the member came from, and supplies the order id the review is
  /// posted against — the same one an ordinary row submits.
  static OrderDetailsModel? _entry({required OrderDetailsModel detail, int? itemId, String? name,
    String? imageFullUrl, double? price, int? quantity,
  }) {
    if(itemId == null || (name ?? '').isEmpty) {
      return null;
    }
    return OrderDetailsModel(
      itemId: itemId,
      orderId: detail.orderId,
      imageFullUrl: imageFullUrl,
      quantity: quantity,
      itemDetails: Item(id: itemId, name: name, price: price ?? 0, imageFullUrl: imageFullUrl),
    );
  }
}

// SUMMARY
// Works out which of an order's items the customer can rate, unfolding a bundle or BOGO
// line into the member items it delivered so each is reviewed on its own, and dropping
// duplicates, so every item the order delivered appears once on the rate-and-review screen.
