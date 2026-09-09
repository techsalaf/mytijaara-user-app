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
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/date_converter.dart';
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

  double calculationCart() {
    _addOnsList = [];
    _availableList = [];
    _itemPrice = 0;
    _itemDiscountPrice = 0;
    _addOns = 0;
    _variationPrice = 0;
    bool isFoodVariation = false;
    double variationWithoutDiscountPrice = 0;
    bool haveVariation = false;
    for (var cartModel in cartList) {

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

  List<CartModel> localCartsOfGroup(AllCartsModel group) {
    return cartServiceInterface.formatOnlineCartToLocalCart(onlineCartModel: group.onlineCarts ?? <OnlineCartModel>[]);
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
    _cartList[cartIndex].quantity = await cartServiceInterface.decideItemQuantity(isIncrement, _cartList, cartIndex, stock, quantityLimit, Get.find<SplashController>().configModel!.moduleConfig!.module!.stock!);

    if (oldQuantity == _cartList[cartIndex].quantity) {
      _isLoading = false;
      update();
      return;
    }

    double discountedPrice = await cartServiceInterface.calculateDiscountedPrice(_cartList[cartIndex], _cartList[cartIndex].quantity!, ModuleHelper.getModuleConfig(_cartList[cartIndex].item!.moduleType).newVariation!);
    if(ModuleHelper.getModuleConfig(_cartList[cartIndex].item!.moduleType).newVariation!) {
     await Get.find<ItemController>().setExistInCart(_cartList[cartIndex].item, null, notify: true);
    }

    await updateCartQuantityOnline(_cartList[cartIndex].id!, discountedPrice, _cartList[cartIndex].quantity!,
      storeId: _cartList[cartIndex].item?.storeId);

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

  Future<void> updateCartQuantityOnline(int cartId, double price, int quantity, {int? storeId}) async {
    _isLoading = true;
    update();
    bool success = await cartServiceInterface.updateCartQuantityOnline(cartId, price, quantity, storeId: storeId);
    if(success) {
      await getAllCarts();
      calculationCart();
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
    _isAllCartsLoading = true;
    _isLoading = true;
    if(notify) {
      update();
    }
    final List<AllCartsModel>? result = await cartServiceInterface.getAllCarts();
    // A newer getAllCarts() call was made while this one was in flight — discard
    // this response so it cannot overwrite fresher data with stale results.
    if(generation != _allCartsGeneration) return;
    _allCartsGroups = result;
    if(_allCartsGroups != null) {
      final int? currentModuleId = ModuleHelper.getModule()?.id ?? ModuleHelper.getCacheModule()?.id;
      if(currentModuleId != null) {
        final List<OnlineCartModel> flat = <OnlineCartModel>[];
        for(AllCartsModel group in _allCartsGroups!) {
          for(OnlineCartModel om in (group.onlineCarts ?? <OnlineCartModel>[])) {
            if(om.moduleId == currentModuleId) {
              // Scope to the active cart screen store when one is open; otherwise include all.
              if(_activeCartScreenStoreId == null || group.store?.id == _activeCartScreenStoreId) {
                flat.add(om);
              }
            }
          }
        }
        _cartList = [];
        _cartList = cartServiceInterface.formatOnlineCartToLocalCart(onlineCartModel: flat);
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
    return _allCartsGroups!.where((AllCartsModel group) {
      final List<CartModel> carts = group.carts ?? <CartModel>[];
      return carts.any((CartModel c) => c.item?.moduleId == moduleId);
    }).toList();
  }

  Future<bool> removeStoreCart(int storeId) async {
    bool success = await cartServiceInterface.removeStoreCart(storeId);
    if(success) {
      _allCartsGroups?.removeWhere((AllCartsModel g) => g.store?.id == storeId);
      _cartList.removeWhere((CartModel c) => c.item?.storeId == storeId);
      update();
    }
    return success;
  }

}