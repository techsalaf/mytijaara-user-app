import 'dart:async';

import 'package:get/get.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/cart/domain/models/all_carts_model.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/cart/domain/models/online_cart_model.dart';
import 'package:sixam_mart/features/cart/domain/services/cart_service_interface.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/features/home/screens/home_screen.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/api/api_checker.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/bundle_amount_helper.dart';
import 'package:sixam_mart/helper/module_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';

class CartController extends GetxController implements GetxService {
  final CartServiceInterface cartServiceInterface;

  CartController({required this.cartServiceInterface});

  List<CartModel> _cartList = [];
  List<CartModel> get cartList => _cartList;

  double _subTotal = 0;
  double get subTotal => _subTotal;

  double _itemPrice = 0;
  double get itemPrice => _itemPrice;

  double _itemDiscountPrice = 0;
  double get itemDiscountPrice => _itemDiscountPrice;

  double _bundleDiscount = 0;

  /// What the bundle rows save against their members' own prices, inside
  /// [itemDiscountPrice] and reported separately.
  ///
  /// The cart's discount row is replaced wholesale by the server's eligibility figure
  /// where there is one, and that figure prices the store's own discount on items — a
  /// bundle's saving is never in it. So the row adds this on top rather than letting
  /// the server's answer swallow it.
  double get bundleDiscount => _bundleDiscount;

  double _addOns = 0;
  double get addOns => _addOns;

  double _variationPrice = 0;
  double get variationPrice => _variationPrice;

  List<List<AddOns>> _addOnsList = [];
  List<List<AddOns>> get addOnsList => _addOnsList;

  List<bool> _availableList = [];
  List<bool> get availableList => _availableList;

  List<String> notAvailableList = ['Remove it from my cart', 'I’ll wait until it’s restocked', 'Please cancel the order', 'Call me ASAP', 'Notify me when it’s back'];
  bool _addCutlery = false;
  bool get addCutlery => _addCutlery;

  int _notAvailableIndex = -1;
  int get notAvailableIndex => _notAvailableIndex;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _needExtraPackage = false;
  bool get needExtraPackage => _needExtraPackage;

  bool _isExpanded = true;
  bool get isExpanded => _isExpanded;

  int? _directAddCartItemIndex = -1;
  int? get directAddCartItemIndex => _directAddCartItemIndex;

  List<AllCartsModel>? _allCartsGroups;
  List<AllCartsModel>? get allCartsGroups => _allCartsGroups;

  // Total number of cart line-items across every module/store (the global cart count).
  int get allCartsItemCount {
    if (_allCartsGroups == null) return 0;
    int count = 0;
    for (final AllCartsModel group in _allCartsGroups!) {
      count += group.carts?.length ?? 0;
    }
    return count;
  }

  bool _isAllCartsLoading = false;
  bool get isAllCartsLoading => _isAllCartsLoading;

  // Incremented on every getAllCarts() call. After the await, any call whose
  // captured token no longer matches is stale (a newer call overtook it) and
  // must be discarded to prevent a slower older response from overwriting the
  // result of a faster newer one.
  int _allCartsGeneration = 0;

  // Set while CartScreen is visible so getAllCarts() never floods _cartList with mixed-store items.
  int? _activeCartScreenStoreId;
  int? get activeCartScreenStoreId => _activeCartScreenStoreId;

  void setActiveCartScreen(int? storeId) => _activeCartScreenStoreId = storeId;

  void clearActiveCartScreen() {
    _activeCartScreenStoreId = null;
    getAllCarts(notify: false);
  }

  void setDirectlyAddToCartIndex(int? index) {
    _directAddCartItemIndex = index;
  }

  void toggleExtraPackage({bool willUpdate = true}) {
    _needExtraPackage = !_needExtraPackage;
    if(willUpdate) {
      update();
    }
  }

  void setAvailableIndex(int index, {bool willUpdate = true}) {
    _notAvailableIndex = cartServiceInterface.availableSelectedIndex(_notAvailableIndex, index);
    if(willUpdate) {
      update();
    }
  }

  void updateCutlery({bool willUpdate = true}){
    _addCutlery = !_addCutlery;
    if(willUpdate) {
      update();
    }
  }

  Future<void> forcefullySetModule(int moduleId) async {
    ModuleModel? module = cartServiceInterface.forcefullySetModule(Get.find<SplashController>().module, Get.find<SplashController>().moduleList, moduleId);
    if(module != null) {
      await Get.find<SplashController>().setModule(module);
      HomeScreen.loadData(true);
    }
  }

  /// The first cart row that carries an item. A bundle row — BOGO or product —
  /// has none, so it can never stand in for the cart's store, module or pricing
  /// context.
  CartModel? get firstItemCart {
    for(final CartModel cart in _cartList) {
      if(!cart.isAtomicBundle && cart.item != null) {
        return cart;
      }
    }
    return null;
  }

  Item? get firstCartItem => firstItemCart?.item;

  /// The store the cart belongs to, falling back to a bundle row when the cart holds
  /// nothing but bundles.
  int? get cartStoreId {
    final int? id = firstCartItem?.storeId;
    if(id != null) {
      return id;
    }
    for(final CartModel cart in _cartList) {
      if(cart.isAtomicBundle && cart.storeId != null) {
        return cart.storeId;
      }
    }
    return null;
  }

  int? get cartModuleId => firstCartItem?.moduleId ?? ModuleHelper.getModule()?.id ?? ModuleHelper.getCacheModule()?.id;

  String? get cartModuleType => firstCartItem?.moduleType ?? ModuleHelper.getModule()?.moduleType ?? ModuleHelper.getCacheModule()?.moduleType;

  double calculationCart() {
    _addOnsList = [];
    _availableList = [];
    _itemPrice = 0;
    _itemDiscountPrice = 0;
    _bundleDiscount = 0;
    _addOns = 0;
    _variationPrice = 0;
    bool isFoodVariation = false;
    double variationWithoutDiscountPrice = 0;
    bool haveVariation = false;
    for (var cartModel in cartList) {

      if(cartModel.isBogoBundle) {
        _addOnsList.add(<AddOns>[]);
        _availableList.add(cartModel.bogoDetails!.isAvailable);
        _itemPrice = _itemPrice + cartModel.bogoDetails!.totalPrice;
        if(cartModel.bogoDetails!.isHappyHour) {
          _itemDiscountPrice = _itemDiscountPrice + cartModel.bogoDetails!.totalDiscountAmount;
        }
        continue;
      }

      if(cartModel.isBundle) {
        _addOnsList.add(<AddOns>[]);
        final BundleCartDetails bundleDetails = cartModel.bundleDetails!;
        _availableList.add(bundleDetails.isAvailable);
        // Billed at the bundle price, but broken out as the members' own total less what
        // the bundle saves: charging the net against "item price" left the discount row
        // reading zero on a bundle that plainly discounts.
        final double saving = BundleAmountHelper.savingOf(bundleDetails);
        if(saving > 0) {
          _itemPrice = _itemPrice + bundleDetails.totalBasePrice;
          _itemDiscountPrice = _itemDiscountPrice + saving;
          _bundleDiscount = _bundleDiscount + saving;
        } else {
          _itemPrice = _itemPrice + bundleDetails.totalFinalPrice;
        }
        continue;
      }

      isFoodVariation = ModuleHelper.getModuleConfig(cartModel.item!.moduleType).newVariation!;
      double? discount = cartModel.item!.discount;
      String? discountType = cartModel.item!.discountType;

      List<AddOns> addOnList = cartServiceInterface.prepareAddonList(cartModel);

      _addOnsList.add(addOnList);
      _availableList.add(DateConverter.isAvailable(cartModel.item!.availableTimeStarts, cartModel.item!.availableTimeEnds));

      _addOns = cartServiceInterface.calculateAddonPrice(_addOns, addOnList, cartModel);

      _variationPrice = cartServiceInterface.calculateVariationPrice(isFoodVariation, cartModel, discount, discountType, _variationPrice);

      variationWithoutDiscountPrice = cartServiceInterface.calculateVariationWithoutDiscountPrice(isFoodVariation, cartModel, variationWithoutDiscountPrice);
      haveVariation = cartServiceInterface.checkVariation(isFoodVariation, cartModel);

      double price = haveVariation ? variationWithoutDiscountPrice : (cartModel.item!.price! * cartModel.quantity!);
      double discountPrice = haveVariation ? (variationWithoutDiscountPrice - _variationPrice)
          : (price - (PriceConverter.convertWithDiscount(cartModel.item!.price!, discount, discountType)! * cartModel.quantity!));

      _itemPrice = _itemPrice + price;
      _itemDiscountPrice = _itemDiscountPrice + discountPrice;

      haveVariation = false;
    }
    if(isFoodVariation){
      _itemDiscountPrice = _itemDiscountPrice + (variationWithoutDiscountPrice - _variationPrice);
      _variationPrice =  variationWithoutDiscountPrice;
      _subTotal = (_itemPrice - _itemDiscountPrice) + _addOns + _variationPrice;
    } else {
      _subTotal = (_itemPrice - _itemDiscountPrice);
    }

    return _subTotal;
  }

  double calculateGCartSubTotal(List<CartModel> cartList) {
    double itemPrice = 0;
    double itemDiscountPrice = 0;
    double addOns = 0;
    double subTotal = 0;
    double thisVariationPrice = 0;
    bool isFoodVariation = false;
    double variationWithoutDiscountPrice = 0;
    bool haveVariation = false;
    for (var cartModel in cartList) {

      // See calculationCart(): a BOGO bundle row contributes its own server-sent total.
      if(cartModel.isBundle) {
        itemPrice = itemPrice + cartModel.bundleDetails!.totalFinalPrice;
        continue;
      }
      if(cartModel.isBogoBundle) {
        itemPrice = itemPrice + cartModel.bogoDetails!.totalPrice;
        if(cartModel.bogoDetails!.isHappyHour) {
          itemDiscountPrice = itemDiscountPrice + cartModel.bogoDetails!.totalDiscountAmount;
        }
        continue;
      }

      isFoodVariation = ModuleHelper.getModuleConfig(cartModel.item!.moduleType).newVariation!;
      double? discount = cartModel.item!.discount;
      String? discountType = cartModel.item!.discountType;

      List<AddOns> addOnList = cartServiceInterface.prepareAddonList(cartModel);

      addOns = cartServiceInterface.calculateAddonPrice(addOns, addOnList, cartModel);

      thisVariationPrice = cartServiceInterface.calculateVariationPrice(isFoodVariation, cartModel, discount, discountType, thisVariationPrice);

      variationWithoutDiscountPrice = cartServiceInterface.calculateVariationWithoutDiscountPrice(isFoodVariation, cartModel, variationWithoutDiscountPrice);
      haveVariation = cartServiceInterface.checkVariation(isFoodVariation, cartModel);

      double price = haveVariation ? variationWithoutDiscountPrice : (cartModel.item!.price! * cartModel.quantity!);
      double discountPrice = haveVariation ? (variationWithoutDiscountPrice - thisVariationPrice)
          : (price - (PriceConverter.convertWithDiscount(cartModel.item!.price!, discount, discountType)! * cartModel.quantity!));

      itemPrice = itemPrice + price;
      itemDiscountPrice = itemDiscountPrice + discountPrice;

      haveVariation = false;
    }
    if(isFoodVariation){
      itemDiscountPrice = itemDiscountPrice + (variationWithoutDiscountPrice - thisVariationPrice);
      thisVariationPrice =  variationWithoutDiscountPrice;
      subTotal = (itemPrice - itemDiscountPrice) + addOns + thisVariationPrice;
    } else {
      subTotal = (itemPrice - itemDiscountPrice);
    }

    return subTotal;
  }

  /// Per-store rows read back through `cart/list`, keyed by store id.
  ///
  /// `cart/get-all` returns a bundle's members as separate rows with no `bogo_details`,
  /// while `cart/list?store_id=` folds them into the single bundle row the cart screen
  /// renders from. Without this the global cart shows a bundle as loose items summed at
  /// full price — no offer, no free half.
  final Map<int, List<CartModel>> _foldedCartsByStore = <int, List<CartModel>>{};

  List<CartModel> localCartsOfGroup(AllCartsModel group) {
    final int? storeId = group.store?.id;
    final List<CartModel>? folded = storeId != null ? _foldedCartsByStore[storeId] : null;
    if(folded != null) {
      return folded;
    }
    return cartServiceInterface.formatOnlineCartToLocalCart(onlineCartModel: group.onlineCarts ?? <OnlineCartModel>[]);
  }

  /// Re-reads every group through `cart/list` so bundles arrive folded. One request per
  /// store, issued together, and abandoned if a newer getAllCarts() supersedes it.
  Future<void> _foldGroupBundles(List<AllCartsModel> groups, int generation) async {
    final List<AllCartsModel> storeGroups = groups.where((AllCartsModel g) => g.store?.id != null).toList();
    if(storeGroups.isEmpty) {
      return;
    }

    final List<List<OnlineCartModel>?> results = await Future.wait(
      storeGroups.map((AllCartsModel g) => cartServiceInterface.getCartDataOnline(storeId: g.store!.id)),
    );
    if(generation != _allCartsGeneration) {
      return;
    }

    for(int i = 0; i < storeGroups.length; i++) {
      final List<OnlineCartModel>? rows = results[i];
      if(rows == null) {
        continue;
      }
      _foldedCartsByStore[storeGroups[i].store!.id!] =
          cartServiceInterface.formatOnlineCartToLocalCart(onlineCartModel: rows);
    }
  }

  Future<void> addToCart(CartModel cartModel, int? index) async {
    if(index != null && index != -1) {
      _cartList.replaceRange(index, index+1, [cartModel]);
    }else {
      _cartList.add(cartModel);
    }
    Get.find<ItemController>().setExistInCart(cartModel.item, null, notify: true);
    await cartServiceInterface.addSharedPrefCartList(_cartList);

    calculationCart();
    update();
  }

  int? getCartId(int cartIndex) {
    return cartServiceInterface.getCartId(cartIndex, _cartList);
  }

  Future<void> setQuantity(bool isIncrement, int cartIndex, int? stock, int ? quantityLimit) async {
    if (_isLoading) return;

    _isLoading = true;
    update();

    int oldQuantity = _cartList[cartIndex].quantity!;
    _cartList[cartIndex].quantity = cartServiceInterface.decideItemQuantity(isIncrement, _cartList, cartIndex, stock, quantityLimit, Get.find<SplashController>().configModel!.moduleConfig!.module!.stock!);

    if (oldQuantity == _cartList[cartIndex].quantity) {
      _isLoading = false;
      update();
      return;
    }

    double discountedPrice = await cartServiceInterface.calculateDiscountedPrice(_cartList[cartIndex], _cartList[cartIndex].quantity!, ModuleHelper.getModuleConfig(_cartList[cartIndex].item!.moduleType).newVariation!);
    if(ModuleHelper.getModuleConfig(_cartList[cartIndex].item!.moduleType).newVariation!) {
     await Get.find<ItemController>().setExistInCart(_cartList[cartIndex].item, null, notify: true);
    }

    await updateCartQuantityOnline(_cartList[cartIndex], discountedPrice, _cartList[cartIndex].quantity!,
      storeId: _cartList[cartIndex].item?.storeId);

  }

  // ── Debounced cart-quantity sync ───────────────────────────────────────────
  // Tapping +/- updates the quantity (and totals) in-memory immediately so the
  // UI stays responsive, then schedules a single backend sync that fires only
  // after the user has stopped tapping for [_quantitySyncDelay]. Rapid taps
  // collapse into one API call instead of one-per-tap, and the buttons are never
  // blocked while a previous request is in flight. Keyed by cart id so several
  // items can be adjusted independently.
  static const Duration _quantitySyncDelay = Duration(seconds: 2);
  final Map<int, Timer> _quantitySyncTimers = {};

  void changeQuantity(bool isIncrement, int cartIndex, int? stock, int? quantityLimit) {
    final int oldQuantity = _cartList[cartIndex].quantity!;
    final int newQuantity = cartServiceInterface.decideItemQuantity(
      isIncrement, _cartList, cartIndex, stock, quantityLimit,
      Get.find<SplashController>().configModel!.moduleConfig!.module!.stock!,
    );
    // Hit a stock / limit boundary — nothing changed (a snackbar was shown).
    if (oldQuantity == newQuantity) return;

    _cartList[cartIndex].quantity = newQuantity;
    calculationCart();
    update();

    final int cartId = _cartList[cartIndex].id!;
    _quantitySyncTimers[cartId]?.cancel();
    _quantitySyncTimers[cartId] = Timer(_quantitySyncDelay, () => _syncQuantityToServer(cartId));
  }

  Future<void> _syncQuantityToServer(int cartId) async {
    _quantitySyncTimers.remove(cartId);
    final int index = _cartList.indexWhere((CartModel c) => c.id == cartId);
    if (index == -1) return;

    final CartModel cart = _cartList[index];
    final bool newVariation = ModuleHelper.getModuleConfig(cart.item!.moduleType).newVariation!;
    final double discountedPrice = await cartServiceInterface.calculateDiscountedPrice(cart, cart.quantity!, newVariation);
    if (newVariation) {
      await Get.find<ItemController>().setExistInCart(cart.item, null, notify: true);
    }
    await updateCartQuantityOnline(cart, discountedPrice, cart.quantity!, storeId: cart.item?.storeId);
  }

  Future<void> removeFromCart(int index, {Item? item}) async {
    int cartId = _cartList[index].id!;
    int? storeId = _cartList[index].item?.storeId;
    _cartList.removeAt(index);
    update();
    Get.find<ItemController>().cartIndexSet();
    await removeCartItemOnline(cartId, item: item, storeId: storeId);
    if(Get.find<ItemController>().item != null) {
      Get.find<ItemController>().cartIndexSet();
    }

  }

  Future<void> clearCartList() async {
    final int? storeId = _cartList.isNotEmpty ? _cartList[0].item?.storeId : null;
    _cartList = [];
    if(storeId != null) {
      _allCartsGroups?.removeWhere((AllCartsModel g) => g.store?.id == storeId);
    }
    update();
    if((AuthHelper.isLoggedIn() || AuthHelper.isGuestLoggedIn()) && (ModuleHelper.getModule() != null || ModuleHelper.getCacheModule() != null)) {
      if(storeId != null){
        removeStoreCart(storeId);
      }
    }
  }

  int isExistInCart(int? itemID, String variationType, bool isUpdate, int? cartIndex) {
    return cartServiceInterface.isExistInCart(_cartList, itemID, variationType, isUpdate, cartIndex);
  }

  bool existAnotherStoreItem(int? storeID, int? moduleId) {
    if (cartServiceInterface.existAnotherStoreItem(storeID, moduleId, _cartList)) {
      return true;
    }
    // Also check the global carts list — _cartList may be empty or stale
    if (_allCartsGroups != null) {
      for (final AllCartsModel group in _allCartsGroups!) {
        if (group.store?.id != storeID && (group.carts?.isNotEmpty ?? false)) {
          return true;
        }
      }
    }
    return false;
  }

  void setCurrentIndex(int index, bool notify) {
    _currentIndex = index;
    if(notify) {
      update();
    }
  }

  Future<bool> addToCartOnline(OnlineCart cart, {int? storeId}) async {
    _isLoading = true;
    bool success = false;
    update();
    List<OnlineCartModel>? onlineCartList = await cartServiceInterface.addToCartOnline(cart, storeId: storeId);
    if(onlineCartList != null) {
      _cartList = [];
      _cartList.addAll(cartServiceInterface.formatOnlineCartToLocalCart(onlineCartModel: onlineCartList));
      calculationCart();
      success = true;
      await getAllCarts(notify: false);
    }
    _isLoading = false;
    update();

    return success;
  }

  Future<bool> updateCartOnline(OnlineCart cart, {int? storeId}) async {
    _isLoading = true;
    bool success = false;
    update();
    List<OnlineCartModel>? onlineCartList = await cartServiceInterface.updateCartOnline(cart, storeId: storeId);
    if(onlineCartList != null) {
      _cartList = [];
      _cartList.addAll(cartServiceInterface.formatOnlineCartToLocalCart(onlineCartModel: onlineCartList));
      calculationCart();
      success = true;
      await getAllCarts(notify: false);
    }
    _isLoading = false;
    update();

    return success;
  }

  Future<void> updateCartQuantityOnline(CartModel cart, double price, int quantity, {int? storeId}) async {
    _isLoading = true;
    update();
    bool success = await cartServiceInterface.updateCartQuantityOnline(cart, price, quantity, storeId: storeId);
    // Resync with the server whether the update succeeded or not: on success to
    // reflect the saved state, on failure (e.g. out of stock, or any other
    // rejection) to roll the optimistic local quantity back to the real cart
    // value. The error message itself is surfaced by the API layer.
    await getAllCarts();
    calculationCart();
    if(success) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
    _isLoading = false;
    update();
  }

  Future<void> getCartDataOnline({int? storeId}) async {
    if(ModuleHelper.getModule() != null || ModuleHelper.getCacheModule() != null) {
      _isLoading = true;
      // Schedule update after build phase completes to avoid "setState during build" error
      Future.microtask(() => update());
      List<OnlineCartModel>? onlineCartList = await cartServiceInterface.getCartDataOnline(storeId: storeId);
      // Assign atomically after the await so no concurrent getAllCarts() call can
      // write into _cartList between the clear and the fill (race that caused duplicates).
      if(onlineCartList != null) {
        _cartList = cartServiceInterface.formatOnlineCartToLocalCart(onlineCartModel: onlineCartList);
        calculationCart();
      } else {
        _cartList = [];
      }
      _isLoading = false;
      update();
    }
  }

  Future<bool> removeCartItemOnline(int cartId, {Item? item, int? storeId}) async {
    _isLoading = true;
    update();
    bool success = await cartServiceInterface.removeCartItemOnline(cartId, storeId: storeId);
    if(success) {
      await getCartDataOnline(storeId: storeId);
      // If removing the last item emptied this store's cart, drop it from the global list too
      if(_cartList.isEmpty && storeId != null) {
        _allCartsGroups?.removeWhere((AllCartsModel g) => g.store?.id == storeId);
      }
      if(item != null) {
        Get.find<ItemController>().setExistInCart(item, null, notify: true);
      }
    }
    _isLoading = false;
    update();
    return success;
  }

  Future<bool> clearCartOnline() async {
    _isLoading = true;
    update();
    bool success = await cartServiceInterface.clearCartOnline();
    if(success) {
      await getAllCarts();
    }
    _isLoading = false;
    update();
    return success;
  }

  int cartQuantity(int itemId) {
    return cartServiceInterface.cartQuantity(itemId, _cartList);
  }

  String cartVariant(int itemId) {
    return cartServiceInterface.cartVariant(itemId, _cartList);
  }

  void setExpanded(bool setExpand) {
    _isExpanded = setExpand;
    update();
  }

  void setAllCartsLoading({bool notify = true}) {
    _isAllCartsLoading = true;
    _isLoading = true;
    if(notify) {
      update();
    }
  }

  Future<void> getAllCarts({bool notify = true}) async {
    final int generation = ++_allCartsGeneration;
    _foldedCartsByStore.clear();
    _isAllCartsLoading = true;
    _isLoading = true;
    if(notify) {
      update();
    }
    final List<AllCartsModel>? result = await cartServiceInterface.getAllCarts();
    // A newer getAllCarts() call was made while this one was in flight — discard
    // this response so it cannot overwrite fresher data with stale results.
    //
    // The loading flags are deliberately left alone on this path: the newer call
    // set them and owns clearing them. Clearing here would drop the spinner while
    // that call is still running.
    if(generation != _allCartsGeneration) return;
    _allCartsGroups = result;

    // Folded before _cartList is built: get-all returns a bundle as its member rows, so
    // building from those turns a bundle back into loose items on every refresh.
    if(_allCartsGroups != null) {
      await _foldGroupBundles(_allCartsGroups!, generation);
      if(generation != _allCartsGeneration) {
        return;
      }
    }

    if(_allCartsGroups != null) {
      final int? currentModuleId = ModuleHelper.getModule()?.id ?? ModuleHelper.getCacheModule()?.id;
      if(currentModuleId != null) {
        // Snapshot optimistic quantities of carts still awaiting a debounced
        // sync so this refresh doesn't snap their numbers back to the (older)
        // server value while the user is still tapping.
        final Map<int, int> pendingQuantities = {};
        for (final CartModel c in _cartList) {
          if (c.id != null && c.quantity != null && _quantitySyncTimers.containsKey(c.id)) {
            pendingQuantities[c.id!] = c.quantity!;
          }
        }

        final List<CartModel> rebuilt = <CartModel>[];
        for(AllCartsModel group in _allCartsGroups!) {
          final int? groupStoreId = group.store?.id;
          // Scope to the active cart screen store when one is open; otherwise include all.
          if(_activeCartScreenStoreId != null && groupStoreId != _activeCartScreenStoreId) {
            continue;
          }
          final List<OnlineCartModel> rows = (group.onlineCarts ?? <OnlineCartModel>[])
              .where((OnlineCartModel om) => om.moduleId == currentModuleId).toList();
          if(rows.isEmpty) {
            continue;
          }
          final List<CartModel>? folded = groupStoreId != null ? _foldedCartsByStore[groupStoreId] : null;
          rebuilt.addAll(folded ?? cartServiceInterface.formatOnlineCartToLocalCart(onlineCartModel: rows));
        }

        _cartList = rebuilt;
        if (pendingQuantities.isNotEmpty) {
          for (final CartModel c in _cartList) {
            final int? pendingQty = c.id != null ? pendingQuantities[c.id] : null;
            if (pendingQty != null) c.quantity = pendingQty;
          }
        }
        calculationCart();
      }
    }

    _isAllCartsLoading = false;
    _isLoading = false;
    update();
  }

  AllCartsModel? getCartsForStore(int storeId) {
    if (_allCartsGroups == null) return null;
    try {
      return _allCartsGroups!.firstWhere(
        (AllCartsModel g) => g.store?.id == storeId && (g.carts?.isNotEmpty ?? false),
      );
    } catch (_) {
      return null;
    }
  }

  List<AllCartsModel> getCartsForModule(int? moduleId) {
    if(moduleId == null || _allCartsGroups == null) {
      return <AllCartsModel>[];
    }
    // Filter on onlineCarts' moduleId (parsed straight from the row's top-level
    // module_id), not carts' item.moduleId: a bundle row has no item, so that
    // field is always null for it and would wrongly drop the whole group.
    return _allCartsGroups!.where((AllCartsModel group) {
      final List<OnlineCartModel> onlineCarts = group.onlineCarts ?? <OnlineCartModel>[];
      return onlineCarts.any((OnlineCartModel om) => om.moduleId == moduleId);
    }).toList();
  }

  Future<bool> removeStoreCart(int storeId) async {
    bool success = await cartServiceInterface.removeStoreCart(storeId);
    if(success) {
      _allCartsGroups?.removeWhere((AllCartsModel g) => g.store?.id == storeId);
      // Bundle and BOGO rows carry no item, so their store lives on the row itself.
      _cartList.removeWhere((CartModel c) => c.storeId == storeId);
      update();
    }
    return success;
  }


  /// `POST /customer/cart/bogo/add`. Unlike an ordinary item add the response wraps
  /// the cart array under `data` rather than returning it directly.
  Future<bool> addBogoToCartOnline(int bogoId, int quantity, {String? contactPersonNumber, int? moduleId}) async {
    _isLoading = true;
    update();
    try {
      Response response = await cartServiceInterface.addBogoToCartOnline(
        bogoId, quantity, AuthHelper.isLoggedIn() ? null : AuthHelper.getGuestId(), contactPersonNumber: contactPersonNumber,
        moduleId: moduleId,
      );

      final bool isSuccess = ApiClient.isSuccessCode(response.statusCode);
      if(isSuccess) {
        await getAllCarts(notify: false);
      } else {
        ApiChecker.checkApi(response);
      }
      return isSuccess;
    } finally {
      _isLoading = false;
      update();
    }
  }

  /// `POST /customer/cart/bogo/update` — the group is rewritten
  /// atomically from the enrolment, so no `cart_id`/price is sent, just the new bundle count.
  /// The server is the source of truth for how many bundles are allowed — a whole-offer cap,
  /// a per-customer cap, or stock on the enrolled items — so `+` always asks it rather than
  /// guessing a limit client-side; a refusal surfaces the server's own reason.
  Future<void> updateBogoBundleQuantity(bool isIncrement, CartModel cart, {required int storeId}) async {
    if(!cart.isBogoBundle) return;
    await setBogoBundleQuantity(cart, (cart.quantity ?? 1) + (isIncrement ? 1 : -1), storeId: storeId);
  }

  /// The row a bundle already sits on, so a details sheet can tell an add from an update.
  /// Bundles are grouped per store, and the offer's own store narrows the search
  /// when the caller knows it.
  CartModel? findBogoBundleInCart(int? bundleId, {int? storeId}) {
    if(bundleId == null) {
      return null;
    }
    for(final AllCartsModel group in _allCartsGroups ?? const <AllCartsModel>[]) {
      final int? groupStoreId = group.store?.id;
      if(storeId != null && groupStoreId != storeId) {
        continue;
      }
      // The folded rows, not group.carts: get-all returns a bundle as its member rows
      // with no bogo_details, so searching those never matched and the offer sheet
      // offered "Add to cart" for a bundle already in the cart — adding a second group.
      final List<CartModel> rows = (groupStoreId != null ? _foldedCartsByStore[groupStoreId] : null)
          ?? group.carts ?? const <CartModel>[];
      for(final CartModel cart in rows) {
        if(cart.isBogoBundle && cart.bogoDetails?.bundleId == bundleId) {
          return cart;
        }
      }
    }
    return null;
  }

  /// The endpoint takes the new bundle count outright, so a quantity picked in one go —
  /// the details sheet — costs one call rather than one per step.
  Future<bool> setBogoBundleQuantity(CartModel cart, int quantity, {required int storeId, int? moduleId}) async {
    if(_isLoading || !cart.isBogoBundle || quantity < 1) return false;

    _isLoading = true;
    update();
    try {
      Response response = await cartServiceInterface.updateBogoBundleQuantityOnline(
        cart.bogoDetails!.bogoGroupId, quantity, AuthHelper.isLoggedIn() ? null : AuthHelper.getGuestId(),
        moduleId: moduleId,
      );
      final bool isSuccess = ApiClient.isSuccessCode(response.statusCode);
      if(isSuccess) {
        await getAllCarts(notify: false);
      } else {
        ApiChecker.checkApi(response);
      }
      return isSuccess;
    } finally {
      _isLoading = false;
      update();
    }
  }

  /// `POST /customer/cart/bundle/add`. The response wraps the cart array under
  /// `data`, the same way the BOGO add does.
  ///
  /// A refusal is **403** with `errors[].code` of `bundle`, and the message is the
  /// bundle's own `unavailable_reason` — it names the member at fault, so it is
  /// shown rather than a generic failure.
  Future<bool> addBundleToCart(int bundleId, int quantity) async {
    _isLoading = true;
    update();
    try {
      Response response = await cartServiceInterface.addBundleToCartOnline(
        bundleId, quantity, AuthHelper.isLoggedIn() ? null : AuthHelper.getGuestId(),
      );

      final bool isSuccess = ApiClient.isSuccessCode(response.statusCode);
      if(isSuccess) {
        await getAllCarts(notify: false);
      } else {
        ApiChecker.checkApi(response);
      }
      return isSuccess;
    } finally {
      _isLoading = false;
      update();
    }
  }

  /// The entry a bundle already sits on, so a details sheet can tell an add from
  /// an update. A second add of the same bundle would create a *second* group
  /// with its own id, which is what this exists to avoid.
  CartModel? findBundleInCart(int? bundleId, {int? storeId}) {
    if(bundleId == null) {
      return null;
    }
    for(final AllCartsModel group in _allCartsGroups ?? const <AllCartsModel>[]) {
      final int? groupStoreId = group.store?.id;
      if(storeId != null && groupStoreId != storeId) {
        continue;
      }
      // The folded rows, not group.carts: get-all returns a bundle as its member
      // rows with no bundle_details, so searching those never matches.
      final List<CartModel> rows = (groupStoreId != null ? _foldedCartsByStore[groupStoreId] : null)
          ?? group.carts ?? const <CartModel>[];
      for(final CartModel cart in rows) {
        if(cart.isBundle && cart.bundleDetails?.bundleId == bundleId) {
          return cart;
        }
      }
    }
    return null;
  }

  /// `POST /customer/cart/bundle/update` — changes how many copies the cart
  /// holds, the only thing about a bundle that is editable.
  Future<void> updateBundleQuantity(bool isIncrement, CartModel cart) async {
    if(!cart.isBundle) return;
    await setBundleQuantity(cart, (cart.quantity ?? 1) + (isIncrement ? 1 : -1));
  }

  /// The endpoint takes the new copy count outright, so a quantity picked in one
  /// go — the details sheet — costs one call rather than one per step.
  ///
  /// The server decides what is allowed: a member out of stock or outside its
  /// serving hours can refuse a higher quantity even when the bundle lists as
  /// available, so `+` always asks rather than guessing a cap client-side.
  Future<bool> setBundleQuantity(CartModel cart, int quantity) async {
    if(_isLoading || !cart.isBundle || quantity < 1) return false;

    _isLoading = true;
    update();
    try {
      Response response = await cartServiceInterface.updateBundleQuantityOnline(
        cart.bundleDetails!.bundleGroupId, quantity, AuthHelper.isLoggedIn() ? null : AuthHelper.getGuestId(),
      );
      final bool isSuccess = ApiClient.isSuccessCode(response.statusCode);
      if(isSuccess) {
        await getAllCarts(notify: false);
      } else {
        ApiChecker.checkApi(response);
      }
      return isSuccess;
    } finally {
      _isLoading = false;
      update();
    }
  }

  /// `DELETE /customer/cart/bundle/remove` — removes every row in the group.
  /// Individual members are never removable.
  Future<void> removeBundle(CartModel cart) async {
    if(_isLoading || !cart.isBundle) return;

    _isLoading = true;
    update();
    try {
      await cartServiceInterface.removeBundleItemOnline(
        cart.bundleDetails!.bundleGroupId, AuthHelper.isLoggedIn() ? null : AuthHelper.getGuestId(),
      );
      await getAllCarts(notify: false);
    } finally {
      _isLoading = false;
      update();
    }
  }

  /// Bundle mode of `/customer/cart/remove-item` — removes every row in the group at once.
  Future<void> removeBogoBundle(CartModel cart, {required int storeId}) async {
    if(_isLoading || !cart.isBogoBundle) return;

    _isLoading = true;
    update();
    try {
      await cartServiceInterface.removeBogoBundleItemOnline(
        cart.bogoDetails!.bogoGroupId, AuthHelper.isLoggedIn() ? null : AuthHelper.getGuestId(), storeId: storeId,
      );
      await getAllCarts(notify: false);
    } finally {
      _isLoading = false;
      update();
    }
  }
}

// SUMMARY
// Holds the customer's cart for the active store: regular items, BOGO bundles and product
// bundles, their prices and totals, and the add, update, remove and clear calls that keep them
// in step with the server.
