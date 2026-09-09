import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/common/models/ongoing_order_model.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/common/widgets/confirmation_dialog.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/cart/domain/models/all_carts_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/payment_model.dart';
import 'package:sixam_mart/features/order/domain/models/last_order_model.dart';
import 'package:sixam_mart/features/order/domain/models/monthly_order_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_cancellation_body.dart';
import 'package:sixam_mart/features/order/domain/models/order_details_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/order/domain/models/reorder_response_model.dart';
import 'package:sixam_mart/features/order/domain/services/order_service_interface.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/util/images.dart';

export 'package:sixam_mart/features/order/domain/services/order_service_interface.dart' show OrderListType;

class OrderController extends GetxController implements GetxService {
  final OrderServiceInterface orderServiceInterface;

  OrderController({required this.orderServiceInterface});

  PaginatedOrderModel? _runningOrderModel;
  PaginatedOrderModel? get runningOrderModel => _runningOrderModel;

  PaginatedOrderModel? _historyOrderModel;
  PaginatedOrderModel? get historyOrderModel => _historyOrderModel;

  List<OrderDetailsModel>? _orderDetails;
  List<OrderDetailsModel>? get orderDetails => _orderDetails;

  PaginatedOrderModel? _allOrderModel;
  PaginatedOrderModel? get allOrderModel => _allOrderModel;

  List<LastOrderModel>? _lastOrders;
  List<LastOrderModel>? get lastOrders => _lastOrders;

  List<LastOrderModel>? _lastOrdersHome;
  List<LastOrderModel>? get lastOrdersHome => _lastOrdersHome;

  List<LastOrderModel>? _storeLastOrders;
  List<LastOrderModel>? get storeLastOrders => _storeLastOrders;

  List<MonthlyOrder>? _monthlyOrders;
  List<MonthlyOrder>? get monthlyOrders => _monthlyOrders;

  int? _deletingOrderId;
  int? get deletingOrderId => _deletingOrderId;

  int? _reorderingOrderId;
  int? get reorderingOrderId => _reorderingOrderId;

  OrderModel? _trackModel;
  OrderModel? get trackModel => _trackModel;

  ResponseModel? _responseModel;
  ResponseModel? get responseModel => _responseModel;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isPaymentLoading = false;
  bool get isPaymentLoading => _isPaymentLoading;

  bool _showCancelled = false;
  bool get showCancelled => _showCancelled;

  bool _showBottomSheet = true;
  bool get showBottomSheet => _showBottomSheet;

  bool _showOneOrder = true;
  bool get showOneOrder => _showOneOrder;

  List<String?>? _refundReasons;
  List<String?>? get refundReasons => _refundReasons;

  int _selectedReasonIndex = -1;
  int get selectedReasonIndex => _selectedReasonIndex;

  XFile? _refundImage;
  XFile? get refundImage => _refundImage;

  String? _cancelReason;
  String? get cancelReason => _cancelReason;

  List<CancellationData>? _orderCancelReasons;
  List<CancellationData>? get orderCancelReasons => _orderCancelReasons;

  bool _isExpanded = false;
  bool get isExpanded => _isExpanded;

  List<String?>? _supportReasons;
  List<String?>? get supportReasons => _supportReasons;

  final List<String> _selectedParcelCancelReason = [];
  List<String>? get selectedParcelCancelReason => _selectedParcelCancelReason;

  PaymentModel? _paymentModel;
  PaymentModel? get paymentModel => _paymentModel;

  OngoingOrderModel? _ongoingOrderModel;
  OngoingOrderModel? get ongoingOrderModel => _ongoingOrderModel;

  Future<void> getDashboardOrders() async {
    _ongoingOrderModel = await orderServiceInterface.getDashboardOrders();
    update();
  }

  void removeOrderFromList(int? id) {
    if(id == null) return;
    _allOrderModel?.orders?.removeWhere((order) => order.id == id);
    _runningOrderModel?.orders?.removeWhere((order) => order.id == id);
    _historyOrderModel?.orders?.removeWhere((order) => order.id == id);
    update();
  }

  Future<void> reorder(OrderModel order) async {
    final int? orderId = order.id;
    final int? storeId = order.store?.id;

    if(orderId == null) {
      showCustomSnackBar('reorder_failed'.tr);
      return;
    }

    if(_reorderingOrderId != null) return;

    _reorderingOrderId = orderId;
    update();

    final CartController cartController = Get.find<CartController>();
    if(Get.find<SplashController>().moduleList != null) {
      for(ModuleModel module in Get.find<SplashController>().moduleList!) {
        if(module.id == order.moduleId) {
          Get.find<SplashController>().setModule(module);
          break;
        }
      }
    }
    // if(cartController.allCartsGroups == null && !cartController.isAllCartsLoading) {
      await cartController.getAllCarts(notify: false);
    // }

    final AllCartsModel? existing = storeId != null ? cartController.getCartsForStore(storeId) : null;

    if(existing != null) {
      _reorderingOrderId = null;
      update();
      Get.dialog(ConfirmationDialog(
        icon: Images.warning,
        title: 'are_you_sure_to_reset'.tr,
        description: 'if_you_continue'.tr,
        onYesPressed: () async {
          if(Get.isDialogOpen ?? false) Get.back();
          final bool removed = await cartController.removeStoreCart(storeId!);
          if(removed) {
            await _performReorder(orderId);
          }
        },
      ), barrierDismissible: false);
      return;
    }

    await _performReorder(orderId);
  }

  Future<void> _performReorder(int orderId) async {
    _reorderingOrderId = orderId;
    update();
    final ReorderResponseModel? response = await orderServiceInterface.reorder(orderId);
    _reorderingOrderId = null;
    update();

    if(response != null) {
      String statusMessage = _buildReorderStatusMessage(response);
      showCustomSnackBar(statusMessage, isError: response.unavailableItems?.isNotEmpty ?? false ? true : false);

      final bool hasAdded = response.addedCount != null && response.addedCount! > 0;
      if(hasAdded) {
        await Get.find<CartController>().getAllCarts();
        Get.toNamed(RouteHelper.getGlobalCartRoute(initialModuleId: Get.find<SplashController>().getCacheModule()?.id));
      }
    }
  }

  String _buildReorderStatusMessage(ReorderResponseModel response) {
    final hasAdded = response.addedCount != null && response.addedCount! > 0;
    final hasUnavailable = response.unavailableItems != null && response.unavailableItems!.isNotEmpty;

    if (hasAdded && hasUnavailable) {
      return '${response.addedCount} ${'items_added_to_cart'.tr}, ${response.unavailableItems!.length} ${'items_unavailable'.tr}';
    } else if (hasAdded) {
      return '${response.addedCount} ${'items_added_to_cart'.tr}';
    } else if (hasUnavailable) {
      return 'items_unavailable'.tr;
    }

    return 'reorder_completed'.tr;
  }


  Future<PaymentModel?> getPaymentFailedDetails(String? orderID) async {
    _paymentModel = null;
    _paymentModel = await orderServiceInterface.getPaymentFailedDetails(orderID);
    _isLoading = false;
    update();
    return _paymentModel;
  }

  void expandedUpdate(bool status){
    _isExpanded = status;
    update();
  }

  void setOrderCancelReason(String? reason){
    _cancelReason = reason;
    update();
  }

  void selectReason(int index, {bool isUpdate = true}){
    if(_selectedReasonIndex == index) {
      _selectedReasonIndex = -1;
    }else {
      _selectedReasonIndex = index;
    }

    if(isUpdate) {
      update();
    }
  }

  void showOrders(){
    _showOneOrder = !_showOneOrder;
    update();
  }

  void showRunningOrders({bool canUpdate = true}){
    _showBottomSheet = !_showBottomSheet;
    if(canUpdate) {
      update();
    }
  }

  void pickRefundImage(bool isRemove) async {
    if(isRemove) {
      _refundImage = null;
    }else {
      _refundImage = await ImagePicker().pickImage(source: ImageSource.gallery);
      update();
    }
  }

  Future<void> getOrderCancelReasons()async {
    _orderCancelReasons = null;
    _orderCancelReasons = await orderServiceInterface.getCancelReasons();
    update();
  }

  Future<void> getRefundReasons() async {
    _selectedReasonIndex = -1;
    _refundReasons = null;
    _refundReasons = await orderServiceInterface.getRefundReasons();
    update();
  }

  Future<void> submitRefundRequest(String note, String? orderId)async {
    _isLoading = true;
    update();
    await orderServiceInterface.submitRefundRequest(_selectedReasonIndex, _refundReasons, note, orderId, _refundImage);
    _isLoading = false;
    update();
  }

  Future<void> getSupportReasons() async {
    _supportReasons = await orderServiceInterface.getSupportReasonsList();
    update();
  }

  Future<bool> deleteOrder(int? id) async {
    if(id == null) return false;
    _deletingOrderId = id;
    update();
    final bool success = await orderServiceInterface.deleteOrder(id);
    _deletingOrderId = null;
    update();
    return success;
  }

  PaginatedOrderModel? orderModelOf(OrderListType type) => switch(type) {
    OrderListType.all => _allOrderModel,
    OrderListType.running => _runningOrderModel,
    OrderListType.previous => _historyOrderModel,
  };

  Future<void> getOrders(OrderListType type, int offset, {bool isUpdate = false, bool fromDashboard = false, int? moduleId}) async {
    if(offset == 1) {
      _setOrderModel(type, null);
      if(isUpdate) {
        update();
      }
    }
    PaginatedOrderModel? orderModel = await orderServiceInterface.getOrderList(type, offset, fromDashboard: fromDashboard, moduleId: moduleId);
    if (orderModel != null) {
      final PaginatedOrderModel? existing = orderModelOf(type);
      if (offset == 1 || existing == null) {
        _setOrderModel(type, orderModel);
      } else {
        existing.orders!.addAll(orderModel.orders!);
        existing.offset = orderModel.offset;
        existing.totalSize = orderModel.totalSize;
      }
      update();
    }
  }

  Future<void> getLastOrders({bool reload = true, required bool isHome}) async {
    if(isHome){
      if(reload) _lastOrdersHome = null;
      final List<LastOrderModel>? result = await orderServiceInterface.getLastOrders(isHome: isHome);
      if(result != null) {
        _lastOrdersHome = result;
        update();
      }
    }
    else{
      if(reload) _lastOrders = null;
      final List<LastOrderModel>? result = await orderServiceInterface.getLastOrders(isHome: isHome);
      if(result != null) {
        _lastOrders = result;
        update();
      }
    }
  }

  Future<void> getMonthlyOrderList({bool reload = true, String? moduleType, bool notify = true}) async {
    if(reload) {
      _monthlyOrders = null;
      if(notify) update();
    }
    final MonthlyOrderModel? result = await orderServiceInterface.getMonthlyOrderList(offset: 1, moduleType: moduleType);
    if(result != null) {
      _monthlyOrders = result.items;
      update();
    }
  }

  Future<bool> removeMonthlyOrder(int id) async {
    update();
    final bool isSuccess = await orderServiceInterface.removeMonthlyOrder(id);
    if(isSuccess) {
      _monthlyOrders?.removeWhere((MonthlyOrder order) => order.id == id);
    }
    update();
    return isSuccess;
  }

  Future<void> getStoreLastOrders(int? storeId, {bool reload = true}) async {
    if(storeId == null) return;
    if(reload) _storeLastOrders = null;
    final List<LastOrderModel>? result = await orderServiceInterface.getLastOrders(isHome: false, storeId: storeId);
    if(result != null) {
      _storeLastOrders = result;
      update();
    }
  }

  void clearAllOrderModels({bool notify = true}) {
    _allOrderModel = null;
    _runningOrderModel = null;
    _historyOrderModel = null;
    if(notify) update();
  }

  void _setOrderModel(OrderListType type, PaginatedOrderModel? value) {
    switch(type) {
      case OrderListType.all:
        _allOrderModel = value;
      case OrderListType.running:
        _runningOrderModel = value;
      case OrderListType.previous:
        _historyOrderModel = value;
    }
  }

  Future<List<OrderDetailsModel>?> getOrderDetails(String orderID) async {
    _orderDetails = null;
    _isLoading = true;
    _showCancelled = false;
    _trackModel = null;

    if(_trackModel == null || (_trackModel!.orderType != 'parcel' && !(_trackModel!.prescriptionOrder ?? false))) {
      List<OrderDetailsModel>? detailsList = await orderServiceInterface.getOrderDetails(orderID, AuthHelper.isLoggedIn() ? null : AuthHelper.getGuestId());
      _isLoading = false;
      if (detailsList != null) {
        _orderDetails = [];
        _orderDetails!.addAll(detailsList);
      }
    }else {
      _isLoading = false;
      _orderDetails = [];
    }
    update();
    return _orderDetails;
  }

  Future<ResponseModel?> trackOrder(String? orderID, OrderModel? orderModel, bool fromTracking, {String? contactNumber, bool? fromGuestInput = false}) async {
    _trackModel = null;
    _responseModel = null;
    if(!fromTracking) {
      _orderDetails = null;
    }
    _showCancelled = false;
    if(orderModel == null) {
      _isLoading = true;
      Response response = await orderServiceInterface.trackOrder(
        orderID, AuthHelper.isLoggedIn() ? null : AuthHelper.getGuestId(),
        contactNumber: contactNumber,
      );
      if (response.statusCode == 200) {
        _trackModel = OrderModel.fromJson(response.body);
        _responseModel = ResponseModel(true, response.body.toString(), statusCode: response.statusCode);
      } else {
        _responseModel = ResponseModel(false, response.statusText, statusCode: response.statusCode);
      }
      _isLoading = false;
      update();
    } else {
      _trackModel = orderModel;
      _responseModel = ResponseModel(true, 'Successful');
    }
    return _responseModel;
  }

  Future<ResponseModel?> timerTrackOrder(String orderID, {String? contactNumber}) async {
    _showCancelled = false;

    Response response = await orderServiceInterface.trackOrder(
      orderID, AuthHelper.isLoggedIn() ? null : AuthHelper.getGuestId(),
      contactNumber: contactNumber,
    );
    if (response.statusCode == 200) {
      _trackModel = OrderModel.fromJson(response.body);
      _responseModel = ResponseModel(true, response.body.toString());
    } else {
      _responseModel = ResponseModel(false, response.statusText);
    }
    update();

    return _responseModel;
  }

  Future<bool> cancelOrder({required int orderID, String? reason, String? guestId, required bool isParcel, List<String>? reasons, String? comment}) async {
    _isLoading = true;
    update();
    bool success = await orderServiceInterface.cancelOrder(orderID: orderID.toString(), reason: reason, guestId: guestId, isParcel: isParcel, reasons: reasons, comment: comment);
    _isLoading = false;
    Get.back();
    if (success) {
      OrderModel? orderModel = orderServiceInterface.prepareOrderModel(_runningOrderModel, orderID);
      if(_runningOrderModel != null) {
        _runningOrderModel!.orders!.remove(orderModel);
      }
      _showCancelled = true;
    }
    update();
    return success;
  }

  Future<bool> switchToCOD(String? orderID, {String? guestId, bool fromOrderDetails = false}) async {
    if(fromOrderDetails) {
      _isPaymentLoading = true;
    } else {
      _isLoading = true;
    }
    update();
    bool isSuccess = await orderServiceInterface.switchToCOD(orderID, guestId: guestId);
    _isLoading = false;
    _isPaymentLoading = false;
    update();
    return isSuccess;
  }

  Future<bool> switchToWalletPayment(String? orderID) async {
    _isLoading = true;
    update();
    bool isSuccess = await orderServiceInterface.switchToWalletPayment(orderID);
    _isLoading = false;
    _isPaymentLoading = false;
    update();
    return isSuccess;
  }

  void paymentRedirect({required String url, required bool canRedirect, required String? contactNumber,
    required Function onClose, required final String? addFundUrl, required final String? subscriptionUrl,
    required final String orderID, int? storeId, required bool createAccount, required String guestId, bool isProSubscription = false, bool isRenew = false}) {

    orderServiceInterface.paymentRedirect(
      url: url, canRedirect: canRedirect, contactNumber: contactNumber, onClose: onClose,
      addFundUrl: addFundUrl, subscriptionUrl: subscriptionUrl, orderID: orderID, storeId: storeId,
      createAccount: createAccount, guestId: guestId, isProSubscription: isProSubscription, isRenew: isRenew,
    );
  }

  void toggleParcelCancelReason(String reason, bool isSelected) {
    if (isSelected) {
      if (!_selectedParcelCancelReason.contains(reason)) {
        _selectedParcelCancelReason.add(reason);
      }
    } else {
      _selectedParcelCancelReason.remove(reason);
    }
    update();
  }

  bool isReasonSelected(String reason) {
    return _selectedParcelCancelReason.contains(reason);
  }

  void clearSelectedParcelCancelReason() {
    _selectedParcelCancelReason.clear();
  }

  Future<bool> submitParcelReturn({required int orderId, required int returnOtp, String? contactNumber}) async {
    bool isSuccess = await orderServiceInterface.submitParcelReturn(orderId: orderId, orderStatus: 'returned', returnOtp: returnOtp);
    if(isSuccess) {
      trackOrder(orderId.toString(), null, true, contactNumber: contactNumber);
    }
    return isSuccess;
  }

}