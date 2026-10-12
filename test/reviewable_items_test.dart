import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/features/order/domain/models/order_details_model.dart';
import 'package:sixam_mart/features/order/helper/reviewable_items_helper.dart';

/// Which of an order's items reach the rate-and-review screen.
///
/// A bundle or BOGO line carries no `item_details` of its own, and the review button
/// used to skip exactly those lines — so every item delivered inside one went
/// unreviewable. Each member is an ordinary item and is rated on its own.

OrderDetailsModel _detail(Map<String, dynamic> json) =>
    OrderDetailsModel.fromJson(jsonDecode(jsonEncode(json)) as Map<String, dynamic>);

Map<String, dynamic> _plainItem(int id, String name) => <String, dynamic>{
  'id': id * 10, 'item_id': id, 'order_id': 500, 'quantity': 1, 'price': 100,
  'item_details': <String, dynamic>{'id': id, 'name': name, 'price': 100},
};

Map<String, dynamic> _member(int id, String name) => <String, dynamic>{
  'item_id': id, 'name': name, 'unit_price': 520.0, 'quantity': 1,
  'image_full_url': 'https://cdn.test/$id.png',
};

Map<String, dynamic> _bundleLine(List<Map<String, dynamic>> members, {int id = 99}) => <String, dynamic>{
  'id': id, 'order_id': 500, 'quantity': 1,
  'bundle_details': <String, dynamic>{
    'bundle_group_id': 'g-$id', 'bundle_id': 18, 'name': 'Breakfast combo', 'quantity': 1,
    'items': members,
  },
};

void main() {
  group('an ordinary order', () {
    test('every item with details is reviewable, once each', () {
      final List<OrderDetailsModel> out = ReviewableItemsHelper.from(<OrderDetailsModel>[
        _detail(_plainItem(1, 'Burger')), _detail(_plainItem(2, 'Fries')),
      ]);
      expect(out.map((d) => d.itemDetails!.name), <String>['Burger', 'Fries']);
    });

    test('the same item twice is one thing to rate', () {
      final List<OrderDetailsModel> out = ReviewableItemsHelper.from(<OrderDetailsModel>[
        _detail(_plainItem(1, 'Burger')), _detail(_plainItem(1, 'Burger')),
      ]);
      expect(out.length, 1);
    });
  });

  group('a bundle of several items', () {
    final List<OrderDetailsModel> out = ReviewableItemsHelper.from(<OrderDetailsModel>[
      _detail(_bundleLine(<Map<String, dynamic>>[_member(322, 'Thai Fried Rice'), _member(327, 'Chicken Salad')])),
    ]);

    test('every member is rated on its own, where the line itself never was', () {
      expect(out.length, 2);
      expect(out.map((d) => d.itemDetails!.name), <String>['Thai Fried Rice', 'Chicken Salad']);
    });

    test('each member posts its own item id', () {
      expect(out.map((d) => d.itemDetails!.id), <int>[322, 327]);
      expect(out.map((d) => d.itemId), <int>[322, 327]);
    });

    test('each member carries the order id the review is posted against', () {
      // The submission body pairs `item_id` with the row's `orderId`.
      expect(out.map((d) => d.orderId), <int>[500, 500]);
    });

    test('each member carries the name, price and picture the row draws', () {
      expect(out.first.itemDetails!.price, 520.0);
      expect(out.first.imageFullUrl, 'https://cdn.test/322.png');
    });
  });

  group('a BOGO of several items', () {
    final List<OrderDetailsModel> out = ReviewableItemsHelper.from(<OrderDetailsModel>[
      _detail(<String, dynamic>{
        'id': 98, 'order_id': 500, 'quantity': 1,
        'bogo_details': <String, dynamic>{
          'bogo_group_id': '77', 'offer_title': 'Buy one get one', 'quantity': 1,
          'buy_items': <Map<String, dynamic>>[_member(401, 'Large Pizza')],
          'free_items': <Map<String, dynamic>>[_member(402, 'Garlic Bread')],
        },
      }),
    ]);

    test('the bought and the free item are each rated separately', () {
      expect(out.length, 2);
      expect(out.map((d) => d.itemDetails!.name), <String>['Large Pizza', 'Garlic Bread']);
    });
  });

  group('the quantity the card prints', () {
    test('a plain row keeps its own', () {
      expect(ReviewableItemsHelper.from(<OrderDetailsModel>[_detail(_plainItem(1, 'Burger'))]).single.quantity, 1);
    });

    test('a member gets one, never null', () {
      final List<OrderDetailsModel> out = ReviewableItemsHelper.from(<OrderDetailsModel>[
        _detail(_bundleLine(<Map<String, dynamic>>[_member(322, 'Thai Fried Rice')])),
        _detail(<String, dynamic>{
          'id': 98, 'order_id': 500, 'quantity': 1,
          'bogo_details': <String, dynamic>{
            'quantity': 1, 'buy_items': <Map<String, dynamic>>[_member(401, 'Large Pizza')],
          },
        }),
      ]);
      expect(out.map((d) => d.quantity), <int>[1, 1]);
    });

    test('several bundles multiply what each one held', () {
      final OrderDetailsModel entry = ReviewableItemsHelper.from(<OrderDetailsModel>[
        _detail(<String, dynamic>{
          'id': 95, 'order_id': 500, 'quantity': 3,
          'bundle_details': <String, dynamic>{
            'bundle_id': 18, 'quantity': 3,
            'items': <Map<String, dynamic>>[<String, dynamic>{'item_id': 322, 'name': 'Thai Fried Rice', 'quantity': 2}],
          },
        }),
      ]).single;
      expect(entry.quantity, 6);
    });

    test('a member sent without a quantity counts as one per bundle', () {
      final OrderDetailsModel entry = ReviewableItemsHelper.from(<OrderDetailsModel>[
        _detail(<String, dynamic>{
          'id': 94, 'order_id': 500, 'quantity': 2,
          'bogo_details': <String, dynamic>{
            'quantity': 2,
            'buy_items': <Map<String, dynamic>>[<String, dynamic>{'item_id': 401, 'name': 'Large Pizza'}],
          },
        }),
      ]).single;
      expect(entry.quantity, 2);
    });
  });

  group('the shapes a bundle member arrives in', () {
    test('a nested item_details still wins where it is sent', () {
      final OrderDetailsModel entry = ReviewableItemsHelper.from(<OrderDetailsModel>[
        _detail(_bundleLine(<Map<String, dynamic>>[<String, dynamic>{
          'item_id': 322, 'name': 'bare name', 'price': 10,
          'item_details': <String, dynamic>{'name': 'detailed name', 'image_full_url': 'https://cdn.test/d.png'},
        }])),
      ]).single;
      expect(entry.itemDetails!.name, 'detailed name');
      expect(entry.imageFullUrl, 'https://cdn.test/d.png');
    });
  });

  group('rows with nothing to rate', () {
    test('a member with no item id or no name is dropped, not rendered blank', () {
      // `item_review_widget` reads `itemDetails!.name!` and posts `itemDetails!.id`.
      final List<OrderDetailsModel> out = ReviewableItemsHelper.from(<OrderDetailsModel>[
        _detail(_bundleLine(<Map<String, dynamic>>[
          <String, dynamic>{'item_id': null, 'name': 'No id'},
          <String, dynamic>{'item_id': 5, 'name': ''},
          _member(6, 'Good one'),
        ], id: 97)),
      ]);
      expect(out.map((d) => d.itemDetails!.name), <String>['Good one']);
    });

    test('an item bought alone and inside a bundle appears once', () {
      final List<OrderDetailsModel> out = ReviewableItemsHelper.from(<OrderDetailsModel>[
        _detail(_plainItem(322, 'Thai Fried Rice')),
        _detail(_bundleLine(<Map<String, dynamic>>[_member(322, 'Thai Fried Rice')], id: 96)),
      ]);
      expect(out.length, 1);
    });

    test('an empty or null order yields nothing', () {
      expect(ReviewableItemsHelper.from(const <OrderDetailsModel>[]), isEmpty);
      expect(ReviewableItemsHelper.from(null), isEmpty);
    });
  });
}
