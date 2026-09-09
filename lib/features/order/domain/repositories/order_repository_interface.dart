import 'package:get/get_connect/http/src/response/response.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixam_mart/common/models/ongoing_order_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/payment_model.dart';
import 'package:sixam_mart/features/order/domain/models/last_order_model.dart';
import 'package:sixam_mart/features/order/domain/models/monthly_order_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/order/domain/models/reorder_response_model.dart';
import 'package:sixam_mart/features/order/domain/services/order_service_interface.dart';
import 'package:sixam_mart/interfaces/repository_interface.dart';

abstract class OrderRepositoryInterface extends RepositoryInterface {
  @override
  Future get(String? id, {String? guestId});
  @override
  Future getList({int? offset, bool isCancelReasons = false, bool isRefundReasons = false, bool fromDashboard, bool isSupportReasons = false});
  Future<PaginatedOrderModel?> getOrderList(OrderListType type, int offset, {bool fromDashboard = false, int? moduleId});
  Future<List<LastOrderModel>?> getLastOrders({required bool isHome, int? storeId});
  Future<MonthlyOrderModel?> getMonthlyOrderList({required int offset, String? moduleType});
  Future<Response> removeMonthlyOrder(int id);
  Future<ReorderResponseModel?> reorder(int orderId);
  Future<Response> submitRefundRequest(Map<String, String> body, XFile? data);
  Future<Response> trackOrder(String? orderID, String? guestId, {String? contactNumber});
  Future<bool> cancelOrder({required String orderID, String? reason, String? guestId, required bool isParcel, List<String>? reasons, String? comment});
  Future<bool> deleteOrder(int orderId);
  Future<Response> switchToCOD(String? orderID, {String? guestId});
  Future<Response> switchToWalletPayment(String? orderID);
  Future<bool> submitParcelReturn({required int orderId, required String orderStatus, required int returnOtp});
  Future<PaymentModel?> getPaymentFailedDetails(String? orderID);
  Future<OngoingOrderModel?> getDashboardOrders();
}