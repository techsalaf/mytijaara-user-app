import 'dart:convert';

import 'package:get/get_connect.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/api/response_parser.dart';
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
    // This endpoint answers `201 Created`; a plain `== 200` check silently
    // dropped every successful add-to-cart.
    if(ApiClient.isSuccessCode(response.statusCode)) {
      onlineCartList = [];
      for (final dynamic cartItem in ResponseParser.listOrEmpty(response.body)) {
        onlineCartList.add(OnlineCartModel.fromJson(cartItem));
      }
    }
    return onlineCartList;
  }

  // The server files a cart row under the module in the request header, so a bundle
  // added from another module's offer list lands in whichever module the app is in
  // rather than the store's. Swapping the header files it correctly without
  // switching the customer out of the module they are browsing.
  Map<String, String>? _headersForModule(int? moduleId) {
    if(moduleId == null) {
      return null;
    }
    final Map<String, String> headers = Map<String, String>.from(apiClient.getHeader());
    headers[AppConstants.moduleId] = '$moduleId';
    return headers;
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
    // `cart/list` now rejects a request that carries no `store_id` with a 422
    // ("The store id field is required."), which used to leave this returning null
    // and the cart screen empty even though the cart had items — it happens whenever
    // the caller has no store in hand yet (cold-opening the cart tab before
    // getAllCarts() has populated its groups, or the interface's `getList`).
    //
    // `cart/get-all` is the unscoped equivalent the API still serves: every store
    // group at once, no `store_id` needed. Flattening its groups reproduces exactly
    // what a store-less `cart/list` used to return, and reuses the same
    // OnlineCartModel parsing, so nothing downstream changes shape.
    if (storeId == null) {
      final List<AllCartsModel>? groups = await getAllCarts();
      if (groups == null) {
        return null;
      }
      return groups
          .expand((AllCartsModel group) => group.onlineCarts ?? const <OnlineCartModel>[])
          .toList();
    }

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
    // Required by the API, and non-null here — the store-less case returned above.
    queryParams.add('store_id=$storeId');
    final String querySuffix = '?${queryParams.join('&')}';

    Response response = await apiClient.getData(
      '${AppConstants.getCartListUri}$querySuffix',
      headers: ModuleHelper.getModule()?.id == null ? header : null,
    );
    if(response.statusCode == 200) {
      onlineCartList = [];
      for (final dynamic cart in ResponseParser.listOrEmpty(response.body)) {
        onlineCartList.add(OnlineCartModel.fromJson(cart));
      }
    }
    return onlineCartList;
  }

  @override
  Future update(Map<String, dynamic> body, int? id, {double? price, int? quantity, bool isUpdateQty = false, int? storeId}) async {
    if(isUpdateQty) {
      return await _updateCartQuantityOnline(body, storeId: storeId);
    } else {
      return await _updateCartOnline(body, storeId: storeId);
    }
  }

  Future<List<OnlineCartModel>?> _updateCartOnline(Map<String, dynamic> body, {int? storeId}) async {
    List<OnlineCartModel>? onlineCartList;
    Response response = await apiClient.postData('${AppConstants.updateCartUri}${_buildCartMutationQuery(storeId)}', body);
    if(ApiClient.isSuccessCode(response.statusCode)) {
      onlineCartList = [];
      for (final dynamic cart in ResponseParser.listOrEmpty(response.body)) {
        onlineCartList.add(OnlineCartModel.fromJson(cart));
      }
    }
    return onlineCartList;
  }

  /// Same endpoint and same body as [_updateCartOnline] — only the return type
  /// differs, because the quantity path re-syncs through `getAllCarts()` rather
  /// than adopting the response.
  ///
  /// It used to post `{cart_id, price, quantity}` alone, which the endpoint
  /// refuses for any item carrying a variation.
  Future<bool> _updateCartQuantityOnline(Map<String, dynamic> body, {int? storeId}) async {
    Response response = await apiClient.postData('${AppConstants.updateCartUri}${_buildCartMutationQuery(storeId)}', body);
    return ApiClient.isSuccessCode(response.statusCode);
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
      for (final dynamic group in ResponseParser.listOrEmpty(response.body)) {
        allCarts.add(AllCartsModel.fromJson(group));
      }
    }
    return allCarts;
  }

  ///Add a BOGO bundle to cart. `quantity` counts whole bundles — every member, paid and
  ///free, is multiplied by it. The id is the store's `bundle_id`, not the offer id.
  @override
  Future<Response> addBogoToCartOnline(int bundleId, int quantity, String? guestId, {String? contactPersonNumber, int? moduleId}) async {
    Map<String, dynamic> body = {
      'bundle_id': bundleId,
      'quantity': quantity,
      'guest_id': ?guestId,
      if(contactPersonNumber != null && contactPersonNumber.isNotEmpty) 'contact_person_number': contactPersonNumber,
    };
    return await apiClient.postData(AppConstants.addBogoCartUri, body, handleError: false, headers: _headersForModule(moduleId));
  }

  ///Change the number of bundles in a BOGO group. The group is rewritten from the store's
  ///enrolment rather than edited line by line.
  /// Returns the raw response (not just success/fail) so the caller can surface the server's
  /// reason when a cap — usage limit, stock, availability — refuses the new quantity.
  @override
  Future<Response> updateBogoBundleQuantityOnline(String bogoGroupId, int quantity, String? guestId, {int? moduleId}) async {
    Map<String, dynamic> data = {
      'bogo_group_id': bogoGroupId,
      'quantity': quantity,
      'guest_id': ?guestId,
    };
    return await apiClient.postData(AppConstants.updateBogoCartUri, data, handleError: false, headers: _headersForModule(moduleId));
  }

  ///Remove a whole BOGO group. Individual members are never removable.
  @override
  Future<bool> removeBogoBundleItemOnline(String bogoGroupId, String? guestId, {required int storeId}) async {
    // The bundle verbs take a JSON body, including on DELETE — `deleteData` supports one.
    Response response = await apiClient.deleteData(
      AppConstants.removeBogoCartUri,
      body: {
        'bogo_group_id': bogoGroupId,
        'guest_id': ?guestId,
      },
      handleError: false,
    );
    return (response.statusCode == 200);
  }

  ///Add a product bundle to cart. `quantity` counts whole bundles — every member is
  ///multiplied by it. Returns the raw response so the caller can surface the server's
  ///own reason: a refusal is 403 with `errors[].code` of `bundle` and the message is
  ///the bundle's `unavailable_reason`.
  @override
  Future<Response> addBundleToCartOnline(int bundleId, int quantity, String? guestId) async {
    Map<String, dynamic> body = {
      'bundle_id': bundleId,
      'quantity': quantity,
      'guest_id': ?guestId,
    };
    return await apiClient.postData(AppConstants.addBundleCartUri, body, handleError: false);
  }

  ///Change how many copies of a bundle the cart holds — the only thing about a bundle
  ///that is editable. The rows are deleted and re-inserted in one transaction, so the
  ///group id survives.
  @override
  Future<Response> updateBundleQuantityOnline(String bundleGroupId, int quantity, String? guestId) async {
    Map<String, dynamic> body = {
      'bundle_group_id': bundleGroupId,
      'quantity': quantity,
      'guest_id': ?guestId,
    };
    return await apiClient.postData(AppConstants.updateBundleCartUri, body, handleError: false);
  }

  ///Remove a whole bundle group. Individual members are never removable.
  @override
  Future<bool> removeBundleItemOnline(String bundleGroupId, String? guestId) async {
    // The bundle verbs take a JSON body, including on DELETE — `deleteData` supports one.
    Response response = await apiClient.deleteData(
      AppConstants.removeBundleCartUri,
      body: {
        'bundle_group_id': bundleGroupId,
        'guest_id': ?guestId,
      },
      handleError: false,
    );
    return (response.statusCode == 200);
  }

  @override
  Future<bool> removeStoreCart(int storeId) async {
    final String guestSuffix = !AuthHelper.isLoggedIn() ? '&guest_id=${AuthHelper.getGuestId()}' : '';
    Response response = await apiClient.deleteData('${AppConstants.removeAllCartUri}?store_id=$storeId$guestSuffix');
    return (response.statusCode == 200);
  }
}