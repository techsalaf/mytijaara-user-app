import 'package:get/get_connect/http/src/response/response.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixam_mart/common/models/ongoing_order_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/payment_model.dart';
import 'package:sixam_mart/features/order/domain/models/last_order_model.dart';
import 'package:sixam_mart/features/order/domain/models/monthly_order_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_cancellation_body.dart';
import 'package:sixam_mart/features/order/domain/models/order_details_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/order/domain/models/reorder_response_model.dart';

enum OrderListType { all, running, previous }

extension OrderListTypeQuery on OrderListType {
  String get queryValue => switch(this) {
    OrderListType.all => 'all',
    OrderListType.running => 'running',
    OrderListType.previous => 'previous',
  };
}

abstract class OrderServiceInterface {
  Future<PaginatedOrderModel?> getOrderList(OrderListType type, int offset, {bool fromDashboard, int? moduleId});
  Future<List<LastOrderModel>?> getLastOrders({required bool isHome, int? storeId});
  Future<MonthlyOrderModel?> getMonthlyOrderList({required int offset, String? moduleType});
  Future<bool> removeMonthlyOrder(int id);
  Future<ReorderResponseModel?> reorder(int orderId);
  Future<List<String?>?> getSupportReasonsList();
  Future<List<OrderDetailsModel>?> getOrderDetails(String orderID, String? guestId);
  Future<List<CancellationData>?> getCancelReasons();
  Future<List<String?>?> getRefundReasons();
  Future<void> submitRefundRequest(int selectedReasonIndex, List<String?>? refundReasons, String note, String? orderId, XFile? refundImage);
  Future<Response> trackOrder(String? orderID, String? guestId, {String? contactNumber});
  Future<bool> cancelOrder({required String orderID, String? reason, String? guestId, required bool isParcel, List<String>? reasons, String? comment});
  Future<bool> deleteOrder(int orderId);
  OrderModel? prepareOrderModel(PaginatedOrderModel? runningOrderModel, int? orderID);
  Future<bool> switchToCOD(String? orderID, {String? guestId});
  Future<bool> switchToWalletPayment(String? orderID);
  void paymentRedirect({required String url, required bool canRedirect, required String? contactNumber,
    required Function onClose, required final String? addFundUrl, required final String? subscriptionUrl,
    required final String orderID, int? storeId, required bool createAccount, required String guestId, bool isProSubscription, bool isRenew});
  Future<bool> submitParcelReturn({required int orderId, required String orderStatus, required int returnOtp});
  Future<PaymentModel?> getPaymentFailedDetails(String? orderID);
  Future<OngoingOrderModel?> getDashboardOrders();
}