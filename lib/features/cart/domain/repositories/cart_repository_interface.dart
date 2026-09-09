import 'package:sixam_mart/features/cart/domain/models/all_carts_model.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/cart/domain/models/online_cart_model.dart';
import 'package:sixam_mart/interfaces/repository_interface.dart';

abstract class CartRepositoryInterface<OnlineCart> extends RepositoryInterface<OnlineCart> {
  Future<void> addSharedPrefCartList(List<CartModel> cartProductList);
  @override
  Future<dynamic> add(OnlineCart value, {int? storeId});
  @override
  Future<dynamic> update(Map<String, dynamic> body, int? id, {double price, int quantity, bool isUpdateQty = false, int? storeId});
  @override
  Future<bool> delete(int? id, {bool isRemoveAll = false, int? storeId});
  Future<List<AllCartsModel>?> getAllCarts();
  Future<bool> removeStoreCart(int storeId);
  Future<List<OnlineCartModel>?> getCartDataOnline({int? storeId});
}