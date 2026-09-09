import 'dart:convert';

import 'package:get/get_connect.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/cart/domain/models/all_carts_model.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/cart/domain/models/online_cart_model.dart';
import 'package:sixam_mart/features/cart/domain/repositories/cart_repository_interface.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/module_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';

class CartRepository implements CartRepositoryInterface<OnlineCart> {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  CartRepository({required this.apiClient, required this.sharedPreferences});

  @override
  Future<void> addSharedPrefCartList(List<CartModel> cartProductList) async {
    List<String> carts = [];
    if(sharedPreferences.containsKey(AppConstants.cartList)) {
      carts = sharedPreferences.getStringList(AppConstants.cartList) ?? [];
    }
    List<String> cartStringList = [];
    for(String cartString in carts) {
      CartModel cartModel = CartModel.fromJson(jsonDecode(cartString));
      if(cartModel.item!.moduleId != _getModuleId()) {
        cartStringList.add(cartString);
      }
    }
    for(CartModel cartModel in cartProductList) {
      cartStringList.add(jsonEncode(cartModel.toJson()));
    }
    await sharedPreferences.setStringList(AppConstants.cartList, cartStringList);
  }

  int _getModuleId() {
    return ModuleHelper.getModule()?.id ?? ModuleHelper.getCacheModule()?.id ?? 0;
  }

  @override
  Future add(OnlineCart cart, {int? storeId}) async {
    return await _addToCartOnline(cart, storeId: storeId);
  }

  Future<List<OnlineCartModel>?> _addToCartOnline(OnlineCart cart, {int? storeId}) async {
    List<OnlineCartModel>? onlineCartList;
    Response response = await apiClient.postData('${AppConstants.addCartUri}${_buildCartMutationQuery(storeId)}', cart.toJson());
    if(response.statusCode == 200) {
      onlineCartList = [];
      response.body.forEach((cart) => onlineCartList!.add(OnlineCartModel.fromJson(cart)));
    }
    return onlineCartList;
  }

  String _buildCartMutationQuery(int? storeId) {
    final List<String> queryParams = <String>[];
    if(!AuthHelper.isLoggedIn()) {
      queryParams.add('guest_id=${AuthHelper.getGuestId()}');
    }
    if(storeId != null) {
      queryParams.add('store_id=$storeId');
    }
    return queryParams.isEmpty ? '' : '?${queryParams.join('&')}';
  }

  @override
  Future<bool> delete(int? id, {bool isRemoveAll = false, int? storeId}) async {
    if(isRemoveAll) {
      return await _clearCartOnline();
    } else {
      return await _removeCartItemOnline(id!, storeId: storeId);
    }
  }

  Future<bool> _removeCartItemOnline(int cartId, {int? storeId}) async {
    final List<String> queryParams = <String>['cart_id=$cartId'];
    if(!AuthHelper.isLoggedIn()) {
      queryParams.add('guest_id=${AuthHelper.getGuestId()}');
    }
    if(storeId != null) {
      queryParams.add('store_id=$storeId');
    }
    Response response = await apiClient.deleteData('${AppConstants.removeItemCartUri}?${queryParams.join('&')}');
    return (response.statusCode == 200);
  }

  Future<bool> _clearCartOnline() async {
    Response response = await apiClient.deleteData('${AppConstants.removeAllCartUri}${!AuthHelper.isLoggedIn() ? '?guest_id=${AuthHelper.getGuestId()}' : ''}');
    return (response.statusCode == 200);
  }

  @override
  Future get(String? id) {
    throw UnimplementedError();
  }

  @override
  Future getList({int? offset}) async {
    return await _getCartDataOnline();
  }

  @override
  Future<List<OnlineCartModel>?> getCartDataOnline({int? storeId}) async {
    return await _getCartDataOnline(storeId: storeId);
  }

  Future<List<OnlineCartModel>?> _getCartDataOnline({int? storeId}) async {
    List<OnlineCartModel>? onlineCartList;
    Map<String, String>? header ={
      'Content-Type': 'application/json; charset=UTF-8',
      AppConstants.localizationKey: AppConstants.languages[0].languageCode!,
      AppConstants.moduleId: '${ModuleHelper.getCacheModule()?.id}',
      'Authorization': 'Bearer ${sharedPreferences.getString(AppConstants.token)}'
    };

    final List<String> queryParams = <String>[];
    if(!AuthHelper.isLoggedIn()) {
      queryParams.add('guest_id=${AuthHelper.getGuestId()}');
    }
    if(storeId != null) {
      queryParams.add('store_id=$storeId');
    }
    final String querySuffix = queryParams.isEmpty ? '' : '?${queryParams.join('&')}';

    Response response = await apiClient.getData(
      '${AppConstants.getCartListUri}$querySuffix',
      headers: ModuleHelper.getModule()?.id == null ? header : null,
    );
    if(response.statusCode == 200) {
      onlineCartList = [];
      response.body.forEach((cart) => onlineCartList!.add(OnlineCartModel.fromJson(cart)));
    }
    return onlineCartList;
  }

  @override
  Future update(Map<String, dynamic> body, int? id, {double? price, int? quantity, bool isUpdateQty = false, int? storeId}) async {
    if(isUpdateQty) {
      return await _updateCartQuantityOnline(id!, price!, quantity!, storeId: storeId);
    } else {
      return await _updateCartOnline(body, storeId: storeId);
    }
  }

  Future<List<OnlineCartModel>?> _updateCartOnline(Map<String, dynamic> body, {int? storeId}) async {
    List<OnlineCartModel>? onlineCartList;
    Response response = await apiClient.postData('${AppConstants.updateCartUri}${_buildCartMutationQuery(storeId)}', body);
    if(response.statusCode == 200) {
      onlineCartList = [];
      response.body.forEach((cart) => onlineCartList!.add(OnlineCartModel.fromJson(cart)));
    }
    return onlineCartList;
  }

  Future<bool> _updateCartQuantityOnline(int cartId, double price, int quantity, {int? storeId}) async {
    Map<String, dynamic> data = {
      "cart_id": cartId,
      "price": price,
      "quantity": quantity,
    };
    Response response = await apiClient.postData('${AppConstants.updateCartUri}${_buildCartMutationQuery(storeId)}', data);
    return (response.statusCode == 200);
  }

  @override
  Future<List<AllCartsModel>?> getAllCarts() async {
    List<AllCartsModel>? allCarts;
    Map<String, String>? header = {
      'Content-Type': 'application/json; charset=UTF-8',
      AppConstants.localizationKey: AppConstants.languages[0].languageCode!,
      AppConstants.moduleId: '${ModuleHelper.getCacheModule()?.id}',
      'Authorization': 'Bearer ${sharedPreferences.getString(AppConstants.token)}',
    };
    if(ModuleHelper.getCacheModule()?.id == null) {
      return [];
    }

    Response response = await apiClient.getData(
      '${AppConstants.getAllCartsUri}${!AuthHelper.isLoggedIn() ? '?guest_id=${AuthHelper.getGuestId()}' : ''}',
      headers: ModuleHelper.getModule()?.id == null ? header : null,
    );
    if(response.statusCode == 200) {
      allCarts = [];
      response.body.forEach((group) => allCarts!.add(AllCartsModel.fromJson(group)));
    }
    return allCarts;
  }

  @override
  Future<bool> removeStoreCart(int storeId) async {
    final String guestSuffix = !AuthHelper.isLoggedIn() ? '&guest_id=${AuthHelper.getGuestId()}' : '';
    Response response = await apiClient.deleteData('${AppConstants.removeAllCartUri}?store_id=$storeId$guestSuffix');
    return (response.statusCode == 200);
  }
}