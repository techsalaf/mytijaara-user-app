import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/cart/domain/models/online_cart_model.dart';
import 'package:sixam_mart/features/cart/domain/repositories/cart_repository_interface.dart';
import 'package:sixam_mart/features/cart/domain/services/cart_service.dart';
import 'package:sixam_mart/api/response_parser.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';

class _FakeCartRepo implements CartRepositoryInterface<OnlineCart> {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

const String liveCartResponse = r'''
{"identical_code":"default_200","message":"Successfully fetched","content":{"data":[
{"id":4666,"module_id":4,"store_id":46,"price":40.5,"quantity":3,"variation":[],"add_on_ids":[],"add_on_qtys":[],
 "item":{"id":412,"name":"adfg","slug":"adfg","image_full_url":null,"images_full_url":[null],"price":45,"discount":10,
 "discount_type":"percent","store_discount":0,"flash_sale":0,"stock":0,"unit_type":null,"maximum_cart_quantity":12,
 "veg":0,"organic":0,"is_halal":0,"avg_rating":0,"rating_count":0,"available_time_starts":"12:00:00",
 "available_time_ends":"22:00:00","brand_name":null,"category_ids":[{"id":"82","position":1}],"module_id":4,
 "module_type":"food","store_id":46,"store_name":"Hungry Puppetssss","store_slug":"hungry-puppets46",
 "store_image_full_url":"https://x/y.webp","verified_seller":1,"halal_tag_status":0,"zone_id":1,
 "schedule_order":true,"free_delivery":false,"variations":[],"food_variations":[],"choice_options":[],"addons":[]}},
{"id":4668,"module_id":4,"store_id":46,"price":345,"quantity":1,
 "variation":[{"name":"Protein","values":{"label":["Chicken"]}},{"name":"Spice Level","values":{"label":["Medium"]}}],
 "add_on_ids":[],"add_on_qtys":[],
 "item":{"id":396,"name":"Aromatic Biryani Rice","slug":"aromatic-biryani-rice","image_full_url":null,
 "images_full_url":[],"price":350,"discount":10,"discount_type":"amount","store_discount":0,"flash_sale":0,"stock":0,
 "unit_type":null,"maximum_cart_quantity":3,"veg":0,"organic":0,"is_halal":1,"avg_rating":0,"rating_count":0,
 "available_time_starts":"10:00:00","available_time_ends":"22:00:00","brand_name":null,
 "category_ids":[{"id":"71","position":1}],"module_id":4,"module_type":"food","store_id":46,
 "store_name":"Hungry Puppetssss","store_slug":"hungry-puppets46","store_image_full_url":"https://x/y.webp",
 "verified_seller":1,"halal_tag_status":0,"zone_id":1,"schedule_order":true,"free_delivery":false,"variations":[],
 "food_variations":[
  {"name":"Protein","type":"multi","min":"1","max":"2","required":"on","values":[
    {"label":"Chicken","optionPrice":"5.0"},{"label":"Lamb","optionPrice":"8.0"},{"label":"Paneer","optionPrice":"6.0"}]},
  {"name":"Spice Level","type":"single","min":"","max":"","required":"on","values":[
    {"label":"Mild","optionPrice":"0.0"},{"label":"Medium","optionPrice":"0.0"},{"label":"Hot","optionPrice":"0.0"}]},
  {"name":"Herbs","type":"multi","min":"1","max":"3","required":"off","values":[
    {"label":"Cilantro","optionPrice":"1.0"},{"label":"Mint","optionPrice":"1.0"},{"label":"Basil","optionPrice":"1.5"}]}],
 "choice_options":[],"addons":[]}}
],"pagination":{"current_page":1,"last_page":1,"per_page":25,"total":2,"from":1,"to":2}},"errors":[]}
''';

dynamic unwrap(String raw) {
  final dynamic b = jsonDecode(raw);
  if (b is! Map) return b;
  if (!b.containsKey('identical_code') || b['content'] == null) return b;
  return b['content'];
}

void main() {
  test('formatOnlineCartToLocalCart on the live cart/list payload', () {
    final dynamic body = unwrap(liveCartResponse);
    final List<OnlineCartModel> online = ResponseParser.listOrEmpty(body)
        .map((e) => OnlineCartModel.fromJson(e as Map<String, dynamic>))
        .toList();
    print('parsed OnlineCartModel count: ${online.length}');
    for (final OnlineCartModel c in online) {
      print('  cart ${c.id}: qty=${c.quantity} apiPrice=${c.price} '
          'foodVariation=${c.foodVariation?.length} productVariation=${c.productVariation?.length} '
          'item.foodVariations=${c.item?.foodVariations?.length} item.variations=${c.item?.variations?.length} '
          'item.addOns=${c.item?.addOns?.length} addOnIds=${c.addOnIds}');
    }

    final CartService service = CartService(cartRepositoryInterface: _FakeCartRepo());
    final List<CartModel> local = service.formatOnlineCartToLocalCart(onlineCartModel: online);

    print('');
    print('formatted CartModel count: ${local.length}');
    for (final CartModel m in local) {
      print('  id=${m.id} item=${m.item?.name} qty=${m.quantity} '
          'price=${m.price} discountedPrice=${m.discountedPrice} discountAmount=${m.discountAmount} '
          'stock=${m.stock} quantityLimit=${m.quantityLimit}');
      print('     foodVariations matrix = ${m.foodVariations}');
      print('     variation (product)   = ${m.variation?.length}');
    }
    expect(local.length, online.length, reason: 'every online cart row must produce a local row');
  });

  test('a single unusable row no longer destroys the whole cart', () {
    // Each entry below broke the loop with a null-check error before, which threw
    // out of formatOnlineCartToLocalCart entirely and left the cart screen empty.
    final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[
      // good food row
      {'id': 1, 'quantity': 1, 'variation': [{'name': 'Size', 'values': {'label': ['M']}}],
       'add_on_ids': [], 'add_on_qtys': [],
       'item': {'id': 10, 'name': 'Good', 'module_type': 'food', 'price': 100, 'discount': 0,
                'discount_type': 'percent', 'variations': [], 'food_variations': [
                  {'name': 'Size', 'type': 'single', 'min': '', 'max': '', 'required': 'on',
                   'values': [{'label': 'S', 'optionPrice': '0'}, {'label': 'M', 'optionPrice': '2'}]}],
                'choice_options': [], 'addons': []}},
      // item price absent  -> used to throw on item.price!
      {'id': 2, 'quantity': 1, 'variation': [], 'add_on_ids': [], 'add_on_qtys': [],
       'item': {'id': 11, 'name': 'No price', 'module_type': 'food', 'variations': [],
                'food_variations': [], 'choice_options': [], 'addons': []}},
      // item entirely absent -> used to throw on cart.item!
      {'id': 3, 'quantity': 1, 'variation': [], 'add_on_ids': [], 'add_on_qtys': []},
      // non-food module row, product variation
      {'id': 4, 'quantity': 2, 'variation': [{'type': 'Large'}], 'add_on_ids': [], 'add_on_qtys': [],
       'item': {'id': 12, 'name': 'Grocery', 'module_type': 'grocery', 'price': 50, 'discount': 0,
                'discount_type': 'percent',
                'variations': [{'type': 'Large', 'price': 60, 'stock': 5}],
                'food_variations': [], 'choice_options': [], 'addons': []}},
      // legacy: isSelected carried on the item, no cart variation
      {'id': 5, 'quantity': 1, 'variation': [], 'add_on_ids': [], 'add_on_qtys': [],
       'item': {'id': 13, 'name': 'Legacy', 'module_type': 'food', 'price': 20, 'discount': 0,
                'discount_type': 'percent', 'variations': [], 'food_variations': [
                  {'name': 'Size', 'type': 'single', 'min': '', 'max': '', 'required': 'on',
                   'values': [{'label': 'S', 'optionPrice': '0', 'isSelected': true},
                              {'label': 'M', 'optionPrice': '2'}]}],
                'choice_options': [], 'addons': []}},
      // add-ons present on the item and referenced by the row
      {'id': 6, 'quantity': 1, 'variation': [], 'add_on_ids': [7], 'add_on_qtys': [2],
       'item': {'id': 14, 'name': 'With addons', 'module_type': 'food', 'price': 30, 'discount': 0,
                'discount_type': 'percent', 'variations': [], 'food_variations': [],
                'choice_options': [], 'addons': [{'id': 7, 'name': 'Cheese', 'price': 3}]}},
    ];

    final List<OnlineCartModel> online =
        rows.map((e) => OnlineCartModel.fromJson(e)).toList();
    final CartService service = CartService(cartRepositoryInterface: _FakeCartRepo());
    final List<CartModel> local = service.formatOnlineCartToLocalCart(onlineCartModel: online);

    for (final CartModel m in local) {
      print('  id=${m.id} item=${m.item?.name} price=${m.price} discounted=${m.discountedPrice} '
          'stock=${m.stock} matrix=${m.foodVariations} addOns=${m.addOns?.map((a) => "${a.name} x${m.addOnIds?.first.quantity}")}');
    }

    // 6 rows in, the item-less one dropped, the other five survive.
    expect(local.length, 5);
    expect(local.map((m) => m.id).toList(), <int?>[1, 2, 4, 5, 6]);
    // cart-reported selection is honoured
    expect(local[0].foodVariations, <List<bool?>>[<bool?>[false, true]]);
    // missing price degrades to 0 instead of throwing
    expect(local[1].price, 0);
    // non-food branch still resolves the variation price and stock
    expect(local[2].discountedPrice, 120.0);
    expect(local[2].stock, 5);
    // legacy isSelected still honoured
    expect(local[3].foodVariations, <List<bool?>>[<bool?>[true, false]]);
    // add-ons resolved
    expect(local[4].addOns!.single.name, 'Cheese');
    expect(local[4].addOnIds!.single.quantity, 2);
  });
}
