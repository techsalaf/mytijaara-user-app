import 'package:get/get_connect.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/cart/domain/models/all_carts_model.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/cart/domain/models/online_cart_model.dart';
import 'package:sixam_mart/features/cart/domain/models/online_cart_model.dart' as online_cart;
import 'package:sixam_mart/features/cart/domain/repositories/cart_repository_interface.dart';
import 'package:sixam_mart/features/cart/domain/services/cart_service_interface.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/helper/module_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart' as item_variation;

class CartService implements CartServiceInterface {
  final CartRepositoryInterface cartRepositoryInterface;
  CartService({required this.cartRepositoryInterface});

  @override
  Future<List<OnlineCartModel>?> addToCartOnline(OnlineCart cart, {int? storeId}) async {
    return await cartRepositoryInterface.add(cart, storeId: storeId);
  }

  @override
  Future<List<OnlineCartModel>?> updateCartOnline(OnlineCart cart, {int? storeId}) async {
    return await cartRepositoryInterface.update(cart.toJson(), null, storeId: storeId);
  }

  /// Changes only the quantity of a row that is already in the cart.
  ///
  /// Posts the **whole** row, not just `cart_id`/`price`/`quantity`.
  /// `customer/cart/update` validates the cart line it is given rather than
  /// patching the stored one, so an item with variations is rejected with
  /// "variation is required" when the variation is left out — the +/- buttons
  /// then failed on exactly the items that had a variation chosen, while plain
  /// items worked. Rebuilding the row from [cart] and overriding the two fields
  /// that actually changed keeps this identical to the body the edit-item flow
  /// already posts successfully to the same endpoint.
  @override
  Future<bool> updateCartQuantityOnline(CartModel cart, double price, int quantity, {int? storeId}) async {
    return await cartRepositoryInterface.update(
      buildOnlineCart(cart, price: price, quantity: quantity).toJson(),
      cart.id, isUpdateQty: true, storeId: storeId,
    );
  }

  /// The cart row as `customer/cart` expects it, optionally with a new [price]
  /// and [quantity].
  ///
  /// The two variation shapes are mutually exclusive and the module decides
  /// which one is live: `newVariation` modules send the selected-option matrix
  /// as `variations`, everything else sends the legacy typed `variation` list.
  /// Sending both, or the wrong one, is what the endpoint rejects.
  @override
  OnlineCart buildOnlineCart(CartModel cart, {double? price, int? quantity}) {
    final Item item = cart.item!;
    final bool newVariation = ModuleHelper.getModuleConfig(item.moduleType).newVariation ?? false;
    final bool isCampaign = cart.isCampaign ?? false;

    final List<int?> addOnIdList = <int?>[];
    final List<int?> addOnQtyList = <int?>[];
    for (final AddOn addOn in cart.addOnIds ?? const <AddOn>[]) {
      addOnIdList.add(addOn.id);
      addOnQtyList.add(addOn.quantity);
    }

    return OnlineCart(
      cart.id,
      isCampaign ? null : item.id,
      isCampaign ? item.id : null,
      (price ?? cart.discountedPrice ?? 0).toString(),
      '',
      newVariation ? null : cart.variation,
      newVariation ? selectedFoodVariations(cart) : null,
      quantity ?? cart.quantity,
      addOnIdList,
      cart.addOns,
      addOnQtyList,
      'Item',
    );
  }

  /// The chosen food-variation options, read out of the `List<List<bool>>`
  /// matrix the cart keeps them in and back into the `{name, values: {label}}`
  /// shape the API speaks.
  ///
  /// The matrix is positional — index `i` of [CartModel.foodVariations] lines up
  /// with index `i` of `item.foodVariations` — so both are walked together and
  /// anything ragged is skipped rather than throwing and taking the cart with it.
  @override
  List<OrderVariation> selectedFoodVariations(CartModel cart) {
    final List<OrderVariation> variations = <OrderVariation>[];
    final List<FoodVariation> itemVariations = cart.item?.foodVariations ?? const <FoodVariation>[];
    final List<List<bool?>> selected = cart.foodVariations ?? const <List<bool?>>[];

    for (int i = 0; i < itemVariations.length && i < selected.length; i++) {
      if (!selected[i].contains(true)) {
        continue;
      }
      final List<VariationValue> values = itemVariations[i].variationValues ?? const <VariationValue>[];
      final List<String?> labels = <String?>[];
      for (int j = 0; j < values.length && j < selected[i].length; j++) {
        if (selected[i][j] ?? false) {
          labels.add(values[j].level);
        }
      }
      if (labels.isNotEmpty) {
        variations.add(OrderVariation(name: itemVariations[i].name, values: OrderVariationValue(label: labels)));
      }
    }
    return variations;
  }

  @override
  Future<List<OnlineCartModel>?> getCartDataOnline({int? storeId}) async {
    return await cartRepositoryInterface.getCartDataOnline(storeId: storeId);
  }

  @override
  Future<bool> removeCartItemOnline(int cartId, {int? storeId}) async {
    return await cartRepositoryInterface.delete(cartId, storeId: storeId);
  }

  @override
  Future<bool> clearCartOnline() async {
    return await cartRepositoryInterface.delete(null, isRemoveAll: true);
  }

  @override
  int availableSelectedIndex(int selectedIndex, int index) {
    int notAvailableIndex = selectedIndex;
    if(notAvailableIndex == index){
      notAvailableIndex = -1;
    }else {
      notAvailableIndex = index;
    }
    return notAvailableIndex;
  }

  @override
  ModuleModel? forcefullySetModule(ModuleModel? selectedModule, List<ModuleModel>? moduleList, int moduleId) {
    ModuleModel? module;
    if(selectedModule == null && moduleList != null){
      for(ModuleModel m in moduleList) {
        if(m.id == moduleId) {
          module = m;
          break;
        }
      }
    }
    return module;
  }

  @override
  List<AddOns> prepareAddonList(CartModel cartModel) {
    List<AddOns> addOnList = [];
    for (var addOnId in cartModel.addOnIds!) {
      for(AddOns addOns in cartModel.item!.addOns!) {
        if(addOns.id == addOnId.id) {
          addOnList.add(addOns);
          break;
        }
      }
    }
    return addOnList;
  }

  @override
  double calculateAddonPrice(double addOns, List<AddOns> addOnList, CartModel cartModel) {
    double addonPrice = addOns;
    for(int index=0; index<addOnList.length; index++) {
      addonPrice = addonPrice + (addOnList[index].price! * cartModel.addOnIds![index].quantity!);
    }
    return addonPrice;
  }

  @override
  double calculateVariationPrice(bool isFoodVariation, CartModel cartModel, double? discount, String? discountType, double variationPrice) {
    double price = variationPrice;
    if(isFoodVariation) {
      for(int index = 0; index< cartModel.item!.foodVariations!.length; index++) {
        for(int i=0; i<cartModel.item!.foodVariations![index].variationValues!.length; i++) {
          if(cartModel.foodVariations![index][i]!) {
            price += (PriceConverter.convertWithDiscount(cartModel.item!.foodVariations![index].variationValues![i].optionPrice!, discount, discountType, isFoodVariation: true)! * cartModel.quantity!);
          }
        }
      }
    } else {

      String variationType = '';
      for(int i=0; i<cartModel.variation!.length; i++) {
        variationType = cartModel.variation![i].type!;
      }

      for (item_variation.Variation variation in cartModel.item!.variations!) {
        if (variation.type == variationType) {
          price = (PriceConverter.convertWithDiscount(variation.price!, discount, discountType)! * cartModel.quantity!);
          break;
        }
      }
    }
    return price;
  }

  @override
  double calculateVariationWithoutDiscountPrice(bool isFoodVariation, CartModel cartModel, double variationWithoutDiscount) {
    double variationWithoutDiscountPrice = variationWithoutDiscount;
    if(!isFoodVariation) {
      String variationType = '';
      for(int i=0; i<cartModel.variation!.length; i++) {
        variationType = cartModel.variation![i].type!;
      }
      for (item_variation.Variation variation in cartModel.item!.variations!) {
        if (variation.type == variationType) {
          variationWithoutDiscountPrice = (variation.price! * cartModel.quantity!);
          break;
        }
      }
    } else {
      for(int index = 0; index< cartModel.item!.foodVariations!.length; index++) {
        for(int i=0; i<cartModel.item!.foodVariations![index].variationValues!.length; i++) {
          if(cartModel.foodVariations![index][i]!) {
            variationWithoutDiscountPrice += (cartModel.item!.foodVariations![index].variationValues![i].optionPrice! * cartModel.quantity!);
          }
        }
      }
    }
    return variationWithoutDiscountPrice;
  }

  @override
  bool checkVariation(bool isFoodVariation, CartModel cartModel) {
    bool haveVariation = false;
    if(!isFoodVariation) {
      String variationType = '';
      for(int i=0; i<cartModel.variation!.length; i++) {
        variationType = cartModel.variation![i].type!;
      }
      for (item_variation.Variation variation in cartModel.item!.variations!) {
        if (variation.type == variationType) {
          haveVariation = true;
          break;
        }
      }
    }
    return haveVariation;
  }

  @override
  Future<void> addSharedPrefCartList(List<CartModel> cartProductList) async {
    await cartRepositoryInterface.addSharedPrefCartList(cartProductList);
  }

  @override
  int? getCartId(int cartIndex, List<CartModel> cartList) {
    if(cartIndex != -1) {
      return cartList.isNotEmpty ? cartList[cartIndex].id : null;
    } else {
      return null;
    }
  }

  @override
  int decideItemQuantity(bool isIncrement, List<CartModel> cartList, int cartIndex, int? stock, int ? quantityLimit, bool moduleStock){
    int quantity = cartList[cartIndex].quantity!;
    if (isIncrement) {
      if(moduleStock && cartList[cartIndex].quantity! >= stock!) {
        showCustomSnackBar('out_of_stock'.tr);
      }else if(quantityLimit != null){
        if(quantity >= quantityLimit && quantityLimit != 0) {
          showCustomSnackBar('${'maximum_quantity_limit'.tr} $quantityLimit');
        } else {
          quantity = quantity + 1;
        }
      } else {
        quantity = quantity + 1;
      }
    } else {
      quantity = quantity - 1;
    }
    return quantity;
  }

  @override
  Future<double> calculateDiscountedPrice(CartModel cartModel, int quantity, bool isFoodVariation) async{
    double? discount = cartModel.item!.discount;
    String? discountType = cartModel.item!.discountType;
    double variationPrice = 0;
    double addonPrice = 0;

    if(isFoodVariation) {
      for(int index = 0; index< cartModel.item!.foodVariations!.length; index++) {
        for(int i=0; i<cartModel.item!.foodVariations![index].variationValues!.length; i++) {
          if(cartModel.foodVariations![index][i]!) {
            variationPrice += (PriceConverter.convertWithDiscount(cartModel.item!.foodVariations![index].variationValues![i].optionPrice!, discount, discountType, isFoodVariation: true)! * cartModel.quantity!);
          }
        }
      }

      List<AddOns> addOnList = [];
      for (var addOnId in cartModel.addOnIds!) {
        for(AddOns addOns in cartModel.item!.addOns!) {
          if(addOns.id == addOnId.id) {
            addOnList.add(addOns);
            break;
          }
        }
      }
      for(int index=0; index<addOnList.length; index++) {
        addonPrice = addonPrice + (addOnList[index].price! * cartModel.addOnIds![index].quantity!);
      }
    }
    double discountedPrice = addonPrice + variationPrice + (cartModel.item!.price! * quantity) - PriceConverter.calculation(cartModel.item!.price!, discount, discountType!, quantity);
    return discountedPrice;
  }

  @override
  List<CartModel> formatOnlineCartToLocalCart({required List<OnlineCartModel> onlineCartModel}) {
    List<CartModel> cartList = [];
    for (OnlineCartModel cart in onlineCartModel) {
      // Anything thrown in this loop loses the *whole* cart, not the one bad row, so
      // the two values that can legitimately be absent are read without `!`:
      // `item` (a row whose item the API no longer returns) and `item.price`
      // (JsonReader.toDouble yields null for a missing or unparseable price).
      // A BOGO bundle row carries no item of its own; `bogo_details` is all it has.
      if (cart.bogoDetails != null) {
        cartList.add(CartModel.bogoBundle(bogoDetails: cart.bogoDetails!, storeId: cart.storeId ?? cart.item?.storeId));
        continue;
      }
      // A product bundle row is the same shape: no item of its own, everything
      // under `bundle_details`.
      if (cart.bundleDetails != null) {
        cartList.add(CartModel.bundle(bundleDetails: cart.bundleDetails!, storeId: cart.storeId ?? cart.item?.storeId));
        continue;
      }
      final Item? item = cart.item;
      if (item == null) {
        continue;
      }
      double price = item.price ?? 0;
      double? discount = item.discount;
      String? discountType = item.discountType;
      double discountedPrice = PriceConverter.convertWithDiscount(price, discount, discountType)!;

      double? discountAmount = price - discountedPrice;
      int? quantity = cart.quantity;
      int? stock = item.stock ?? 0;

      List<List<bool?>> selectedFoodVariations = [];
      List<bool> collapsVariation = [];

      if(item.moduleType == 'food') {
        // The API reports the *chosen* options separately from the item's option
        // list, and the option list carries no `isSelected`:
        //
        //   variation:            [{name: "Protein", values: {label: ["Chicken"]}}]
        //   item.food_variations: [{name: "Protein", values: [{label: "Chicken", optionPrice: "5.0"}, …]}]
        //
        // Reading only `isSelected` therefore built an all-false matrix, so the cart
        // row rendered no variation text and reopening the item preselected nothing
        // (ItemController seeds `_selectedVariations` from this same matrix).
        //
        // Index the cart's own `variation` by name -> chosen labels and treat that as
        // the source of truth, keeping `isSelected` as a fallback so locally built
        // carts and any payload that still sends it behave exactly as before.
        //
        // The loop variable is explicitly typed: `cart.foodVariation ?? []` infers a
        // `List<dynamic>`, and mapping over a dynamic receiver yields a
        // `MappedListIterable<String, dynamic>` that `Set<String>.addAll` rejects at
        // *runtime* — the analyzer cannot see it through the dynamic.
        final Map<String, Set<String>> selectedLabelsByName = <String, Set<String>>{};
        final List<online_cart.Variation> cartVariations = cart.foodVariation ?? const <online_cart.Variation>[];
        for (final online_cart.Variation cartVariation in cartVariations) {
          final String? variationName = cartVariation.name;
          if (variationName == null) {
            continue;
          }
          final Set<String> labels = selectedLabelsByName.putIfAbsent(variationName, () => <String>{});
          final List<String> chosenLabels = cartVariation.values?.label ?? const <String>[];
          for (final String label in chosenLabels) {
            labels.add(label.trim());
          }
        }

        final List<FoodVariation> itemFoodVariations = item.foodVariations ?? const <FoodVariation>[];
        for(int index=0; index<itemFoodVariations.length; index++) {
          selectedFoodVariations.add([]);
          collapsVariation.add(true);
          final FoodVariation foodVariation = itemFoodVariations[index];
          final Set<String> selectedLabels = selectedLabelsByName[foodVariation.name] ?? const <String>{};
          final List<VariationValue> values = foodVariation.variationValues ?? const <VariationValue>[];
          for(int i=0; i < values.length; i++) {
            final VariationValue variationValue = values[i];
            final bool isSelected = (variationValue.isSelected ?? false)
                || selectedLabels.contains(variationValue.level?.trim());
            selectedFoodVariations[index].add(isSelected);
          }
        }
      } else {
        String variationType = cart.productVariation != null && cart.productVariation!.isNotEmpty ? (cart.productVariation![0].type ?? '') : '';
        for (item_variation.Variation variation in item.variations ?? const <item_variation.Variation>[]) {
          if (variation.type == variationType) {
            discountedPrice = (PriceConverter.convertWithDiscount(variation.price!, discount, discountType)! * cart.quantity!);
            stock = variation.stock ?? 0;
            break;
          }
        }
      }

      List<AddOn> addOnIdList = [];
      List<AddOns> addOnsList = [];
      // All three lists are optional on their models — the API omits add-on keys on
      // some item payloads — so read them defensively rather than with `!`, which
      // threw a null-check error and took the cart screen down.
      final List<int> cartAddOnIds = cart.addOnIds ?? const <int>[];
      final List<int> cartAddOnQtys = cart.addOnQtys ?? const <int>[];
      final List<AddOns> itemAddOns = item.addOns ?? const <AddOns>[];
      for (int index = 0; index < cartAddOnIds.length; index++) {
        addOnIdList.add(AddOn(id: cartAddOnIds[index], quantity: index < cartAddOnQtys.length ? cartAddOnQtys[index] : 1));
        for (int i = 0; i < itemAddOns.length; i++) {
          if(cartAddOnIds[index] == itemAddOns[i].id) {
            addOnsList.add(AddOns(id: itemAddOns[i].id, name: itemAddOns[i].name, price: itemAddOns[i].price));
          }
        }
      }

      int? quantityLimit = item.quantityLimit;

      cartList.add(
        CartModel(
          cart.id, price, discountedPrice, cart.productVariation?? [], selectedFoodVariations, discountAmount, quantity,
          addOnIdList, addOnsList, false, stock, item, quantityLimit,
        ),
      );
    }

    return cartList;
  }

  @override
  int isExistInCart(List<CartModel> cartList, int? itemID, String variationType, bool isUpdate, int? cartIndex) {
    for(int index=0; index<cartList.length; index++) {
      // Skips any row with no item of its own — item! is dereferenced below.
      if(cartList[index].isAtomicBundle) {
        continue;
      }
      if(cartList[index].item!.id == itemID && (cartList[index].variation!.isNotEmpty
          ? cartList[index].variation![0].type == variationType : true)) {
        if((isUpdate && index == cartIndex)) {
          return -1;
        }else {
          return index;
        }
      }
    }
    return -1;
  }

  @override
  bool existAnotherStoreItem(int? storeID, int? moduleId, List<CartModel> cartList) {
    for(CartModel cartModel in cartList) {
      if(cartModel.isAtomicBundle) {
        continue;
      }
      if(cartModel.item!.storeId != storeID && cartModel.item!.moduleId == moduleId) {
        return true;
      }
    }
    return false;
  }

  @override
  int cartQuantity(int itemId, List<CartModel> cartList) {
    int quantity = 0;
    for(CartModel cart in cartList) {
      if(cart.isAtomicBundle) {
        continue;
      }
      if(cart.item!.id == itemId) {
        quantity += cart.quantity!;
      }

    }
    return quantity;
  }

  @override
  String cartVariant(int itemId, List<CartModel> cartList) {
    String variant = '';
    for(CartModel cart in cartList) {
      if(cart.isAtomicBundle) {
        continue;
      }
      if(cart.item!.id == itemId) {
        if(!ModuleHelper.getModuleConfig(cart.item!.moduleType).newVariation!) {
          variant = (cart.variation != null && cart.variation!.isNotEmpty) ? cart.variation![0].type! : '';
        }
      }
    }
    return variant;
  }

  @override
  Future<List<AllCartsModel>?> getAllCarts() async {
    return await cartRepositoryInterface.getAllCarts();
  }

  @override
  Future<bool> removeStoreCart(int storeId) async {
    return await cartRepositoryInterface.removeStoreCart(storeId);
  }


  @override
  Future<Response> addBogoToCartOnline(int bogoId, int quantity, String? guestId, {String? contactPersonNumber, int? moduleId}) async {
    return await cartRepositoryInterface.addBogoToCartOnline(bogoId, quantity, guestId, contactPersonNumber: contactPersonNumber, moduleId: moduleId);
  }

  @override
  Future<Response> updateBogoBundleQuantityOnline(String bogoGroupId, int quantity, String? guestId, {int? moduleId}) async {
    return await cartRepositoryInterface.updateBogoBundleQuantityOnline(bogoGroupId, quantity, guestId, moduleId: moduleId);
  }

  @override
  Future<bool> removeBogoBundleItemOnline(String bogoGroupId, String? guestId, {required int storeId}) async {
    return await cartRepositoryInterface.removeBogoBundleItemOnline(bogoGroupId, guestId, storeId: storeId);
  }

  @override
  Future<Response> addBundleToCartOnline(int bundleId, int quantity, String? guestId) async {
    return await cartRepositoryInterface.addBundleToCartOnline(bundleId, quantity, guestId);
  }

  @override
  Future<Response> updateBundleQuantityOnline(String bundleGroupId, int quantity, String? guestId) async {
    return await cartRepositoryInterface.updateBundleQuantityOnline(bundleGroupId, quantity, guestId);
  }

  @override
  Future<bool> removeBundleItemOnline(String bundleGroupId, String? guestId) async {
    return await cartRepositoryInterface.removeBundleItemOnline(bundleGroupId, guestId);
  }
}