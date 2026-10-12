import 'package:get/get_connect.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/cart/domain/models/all_carts_model.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/cart/domain/models/online_cart_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';

abstract class CartServiceInterface {
  int availableSelectedIndex(int selectedIndex, int index);
  ModuleModel? forcefullySetModule(ModuleModel? module, List<ModuleModel>? moduleList, int moduleId);
  List<AddOns> prepareAddonList(CartModel cartModel);
  double calculateAddonPrice(double addOns, List<AddOns> addOnList, CartModel cartModel);
  double calculateVariationPrice(bool isFoodVariation, CartModel cartModel, double? discount, String? discountType, double variationPrice);
  double calculateVariationWithoutDiscountPrice(bool isFoodVariation, CartModel cartModel, double variationWithoutDiscount);
  bool checkVariation(bool isFoodVariation, CartModel cartModel);
  Future<void> addSharedPrefCartList(List<CartModel> cartProductList);
  int? getCartId(int cartIndex, List<CartModel> cartList);
  int decideItemQuantity(bool isIncrement, List<CartModel> cartList, int cartIndex, int? stock, int ? quantityLimit, bool moduleStock);
  Future<double> calculateDiscountedPrice(CartModel cartModel, int quantity, bool isFoodVariation);
  /// Takes the whole row, not just its id: `customer/cart/update` validates the
  /// cart line it is posted, so a quantity change has to carry the variation and
  /// add-ons with it or the endpoint rejects it.
  Future<bool> updateCartQuantityOnline(CartModel cart, double price, int quantity, {int? storeId});
  OnlineCart buildOnlineCart(CartModel cart, {double? price, int? quantity});
  List<OrderVariation> selectedFoodVariations(CartModel cart);
  Future<List<OnlineCartModel>?> getCartDataOnline({int? storeId});
  List<CartModel> formatOnlineCartToLocalCart({required List<OnlineCartModel> onlineCartModel});
  Future<List<OnlineCartModel>?> updateCartOnline(OnlineCart cart, {int? storeId});
  Future<List<OnlineCartModel>?> addToCartOnline(OnlineCart cart, {int? storeId});
  Future<bool> removeCartItemOnline(int cartId, {int? storeId});
  Future<bool> clearCartOnline();
  int isExistInCart(List<CartModel> cartList, int? itemID, String variationType, bool isUpdate, int? cartIndex);
  bool existAnotherStoreItem(int? storeID, int? moduleId, List<CartModel> cartList);
  int cartQuantity(int itemId, List<CartModel> cartList);
  String cartVariant(int itemId, List<CartModel> cartList);
  Future<List<AllCartsModel>?> getAllCarts();
  Future<bool> removeStoreCart(int storeId);
  Future<Response> addBogoToCartOnline(int bogoId, int quantity, String? guestId, {String? contactPersonNumber, int? moduleId});
  Future<Response> updateBogoBundleQuantityOnline(String bogoGroupId, int quantity, String? guestId, {int? moduleId});
  Future<bool> removeBogoBundleItemOnline(String bogoGroupId, String? guestId, {required int storeId});
  Future<Response> addBundleToCartOnline(int bundleId, int quantity, String? guestId);
  Future<Response> updateBundleQuantityOnline(String bundleGroupId, int quantity, String? guestId);
  Future<bool> removeBundleItemOnline(String bundleGroupId, String? guestId);
}