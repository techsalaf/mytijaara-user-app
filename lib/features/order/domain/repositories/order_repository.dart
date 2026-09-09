import 'dart:developer';

import 'package:get/get_connect/connect.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/models/ongoing_order_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/payment_model.dart';
import 'package:sixam_mart/features/order/domain/models/last_order_model.dart';
import 'package:sixam_mart/features/order/domain/models/monthly_order_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_cancellation_body.dart';
import 'package:sixam_mart/features/order/domain/models/order_details_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/order/domain/models/refund_model.dart';
import 'package:sixam_mart/features/order/domain/models/reorder_response_model.dart';
import 'package:sixam_mart/features/order/domain/models/support_model.dart';
import 'package:sixam_mart/features/order/domain/repositories/order_repository_interface.dart';
import 'package:sixam_mart/features/order/domain/services/order_service_interface.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';

class OrderRepository implements OrderRepositoryInterface {
  final ApiClient apiClient;
  OrderRepository({required this.apiClient});

  @override
  Future<Response> submitRefundRequest(Map<String, String> body, XFile? data) async {
    return apiClient.postMultipartData(AppConstants.refundRequestUri, body,  [MultipartBody('image[]', data)]);
  }

  @override
  Future<Response> trackOrder(String? orderID, String? guestId, {String? contactNumber}) async {
    return await apiClient.getData(
      '${AppConstants.trackUri}$orderID${guestId != null ? '&guest_id=$guestId' : ''}'
          '${contactNumber != null ? '&contact_number=$contactNumber' : ''}',
    );
  }

  @override
  Future<PaymentModel?> getPaymentFailedDetails(String? orderID) async {
    PaymentModel? paymentModel;
    Response response = await apiClient.getData('${AppConstants.paymentFailedDetailsUri}${orderID != null ? '?order_id=$orderID' : ''}${AuthHelper.isGuestLoggedIn() ? '&guest_id=${AuthHelper.getGuestId()}' : ''}');
    if (response.statusCode == 200) {
      try {
        paymentModel = PaymentModel.fromJson(response.body);
      } catch(_) {}
    }
    return paymentModel;
  }

  @override
  Future<Response> switchToCOD(String? orderID, {String? guestId}) async {
    Map<String, String> data = {'_method': 'put', 'order_id': orderID!};
    if(AuthHelper.isGuestLoggedIn() || guestId != null) {
      data.addAll({'guest_id': guestId ?? AuthHelper.getGuestId()});
    }
    return await apiClient.postData(AppConstants.codSwitchUri, data);
  }

  @override
  Future<Response> switchToWalletPayment(String? orderID) async {
    Map<String, String> data = {'order_id': orderID!};
    return await apiClient.postData(AppConstants.walletSwitchUri, data);
  }

  @override
  Future<bool> cancelOrder({required String orderID, String? reason, String? guestId, required bool isParcel, List<String>? reasons, String? comment}) async {
    bool success = false;

    Map<String, dynamic> data;

    if (isParcel) {
      data = {'_method': 'put', 'order_id': orderID, 'reason': reasons ?? [], 'note': comment ?? ''};
    } else {
      data = {'_method': 'put', 'order_id': orderID, 'reason': reason ?? '', 'note': comment ?? ''};
    }

    if(AuthHelper.isGuestLoggedIn() || guestId != null){
      data.addAll({'guest_id': guestId ?? AuthHelper.getGuestId()});
    }
    Response response = await apiClient.postData(AppConstants.orderCancelUri, data, );
    if (response.statusCode == 200) {
      success = true;
    }
    return success;
  }

  @override
  Future<bool> deleteOrder(int orderId) async {
    final Response response = await apiClient.deleteData('${AppConstants.orderDeleteUri}?order_id=$orderId');
    return response.statusCode == 200;
  }

  @override
  Future get(String? id, {String? guestId}) async {
    return await _getOrderDetails(id!, guestId);
  }

  Future<List<OrderDetailsModel>?> _getOrderDetails(String orderID, String? guestId) async {
    List<OrderDetailsModel>? orderDetails;
    Response response = await apiClient.getData('${AppConstants.orderDetailsUri}$orderID${guestId != null ? '&guest_id=$guestId' : ''}');
    if (response.statusCode == 200) {
      orderDetails = [];
      if(response.body is List){
        response.body.forEach((orderDetail) => orderDetails!.add(OrderDetailsModel.fromJson(orderDetail)));
      }
    }
    return orderDetails;
  }

  @override
  Future getList({int? offset, bool isCancelReasons = false, bool isRefundReasons = false, bool fromDashboard = false, bool isSupportReasons = false}) async {
    if(isCancelReasons) {
      return await _getCancelReasons();
    } else if(isRefundReasons) {
      return await _getRefundReasons();
    } else if(isSupportReasons) {
      return await _getSupportReasons();
    }
  }

  @override
  Future<List<LastOrderModel>?> getLastOrders({required bool isHome, int? storeId}) async {
    Map<String, String>? header;
    if(isHome){
      header = Map.from(apiClient.getHeader());
      header.remove(AppConstants.moduleId);
    }

    final String uri = storeId != null ? '${AppConstants.lastOrdersUri}?store_id=$storeId' : AppConstants.lastOrdersUri;
    final Response response = await apiClient.getData(uri, headers: header);
    if(response.statusCode == 200 && response.body is List) {
      log("---------+> ${header} ${response.body.map((e)=>e['module_id'])}");
      return (response.body as List).whereType<Map<String, dynamic>>().map(LastOrderModel.fromJson).toList();
    }
    return null;
  }

  @override
  Future<MonthlyOrderModel?> getMonthlyOrderList({required int offset, String? moduleType}) async {
    MonthlyOrderModel? monthlyOrderModel;
    final String moduleParam = (moduleType != null && moduleType.isNotEmpty) ? '&module_type=$moduleType' : '';
    final Response response = await apiClient.getData('${AppConstants.monthlyOrderListUri}?limit=10&offset=$offset$moduleParam');
    if(response.statusCode == 200) {
      monthlyOrderModel = MonthlyOrderModel.fromJson(response.body);
    }
    return monthlyOrderModel;
  }

  @override
  Future<Response> removeMonthlyOrder(int id) async {
    return await apiClient.deleteData('${AppConstants.monthlyOrderRemoveUri}?id=$id');
  }

  @override
  Future<ReorderResponseModel?> reorder(int orderId) async {
    ReorderResponseModel? reorderResponse;
    Response response = await apiClient.postData(AppConstants.reorderUri, {'order_id': orderId}, handleError: false);
    // if (response.statusCode == 200) {
      reorderResponse = ReorderResponseModel.fromJson(response.body);
    // }
    return reorderResponse;
  }

  @override
  Future<PaginatedOrderModel?> getOrderList(OrderListType type, int offset, {bool fromDashboard = false, int? moduleId}) async {
    PaginatedOrderModel? orderModel;
    final String moduleParam = moduleId != null ? '&module_id=$moduleId' : '';
    Response response = await apiClient.getData(
      '${AppConstants.allOrderList}?type=${type.queryValue}&offset=$offset&limit=${fromDashboard ? 50 : 10}$moduleParam',
    );
    if (response.statusCode == 200) {
      orderModel = PaginatedOrderModel.fromJson(response.body);
    }
    return orderModel;
  }

  Future<List<CancellationData>?> _getCancelReasons() async {
    List<CancellationData>? orderCancelReasons;
    Response response = await apiClient.getData('${AppConstants.orderCancellationUri}?offset=1&limit=30&type=customer');
    if (response.statusCode == 200) {
      OrderCancellationBody orderCancellationBody = OrderCancellationBody.fromJson(response.body);
      orderCancelReasons = [];
      for (var element in orderCancellationBody.reasons!) {
        orderCancelReasons.add(element);
      }
    }
    return orderCancelReasons;
  }

  Future<List<String?>?> _getRefundReasons() async {
    List<String?>? refundReasons;
    Response response = await apiClient.getData(AppConstants.refundReasonUri);
    if (response.statusCode == 200) {
      RefundModel refundModel = RefundModel.fromJson(response.body);
      refundReasons = [];
      for (var element in refundModel.refundReasons!) {
        refundReasons.add(element.reason);
      }
    }
    return refundReasons;
  }

  Future<List<String?>?> _getSupportReasons() async {
    List<String?>? supportReasons;
    Response response = await apiClient.getData(AppConstants.supportReasonUri);
    if (response.statusCode == 200) {
      SupportModel supportModel = SupportModel.fromJson(response.body);
      supportReasons = [];
      for (var element in supportModel.data!) {
        supportReasons.add(element.message);
      }
    }
    return supportReasons;
  }

  @override
  Future<bool> submitParcelReturn({required int orderId, required String orderStatus, required int returnOtp}) async {
    Map<String, dynamic> data = {
      'order_id': orderId,
      'order_status': orderStatus,
      'return_otp': returnOtp,
    };
    Response response = await apiClient.postData(AppConstants.customerParcelReturn, data);
    return response.statusCode == 200;
  }

  @override
  Future<OngoingOrderModel?> getDashboardOrders() async {
    OngoingOrderModel? ongoingOrderModel;
    Response response = await apiClient.getData(AppConstants.dashboardOrderUri);
    if (response.statusCode == 200) {
      ongoingOrderModel = OngoingOrderModel.fromJson(response.body);
    }
    return ongoingOrderModel;
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }
  
}