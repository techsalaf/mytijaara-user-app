import 'package:country_code_picker/country_code_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:sixam_mart/api/api_checker.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/checkout/domain/models/payment_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/saved_prescription_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/checkout_summary_body_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/checkout_summary_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/coverage_list_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/surge_price_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/features/coupon/controllers/coupon_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_order/controllers/taxi_order_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_order/screens/taxi_order_details_screen.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/payment/domain/models/offline_method_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/timeslote_model.dart';
import 'package:sixam_mart/features/checkout/domain/services/checkout_service_interface.dart';
import 'package:sixam_mart/features/checkout/widgets/order_successfull_dialog.dart';
import 'package:sixam_mart/features/checkout/widgets/partial_pay_dialog_widget.dart';
import 'package:sixam_mart/features/home/screens/home_screen.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/file_validation_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:universal_html/html.dart' as html;

class CheckoutController extends GetxController implements GetxService {
  final CheckoutServiceInterface checkoutServiceInterface;
  CheckoutController({required this.checkoutServiceInterface});

  static const int maxPrescriptionFileCount = 5;
  static const int maxPrescriptionSaveBatchCount = 5;
  final int fileSize = Get.find<SplashController>().configModel?.validationConfig?.maxFileSize??2;
  late int maxPrescriptionFileSizeInBytes = (fileSize * 1024 * 1024);

  final TextEditingController couponController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController streetNumberController = TextEditingController();
  final TextEditingController houseController = TextEditingController();
  final TextEditingController floorController = TextEditingController();
  final TextEditingController tipController = TextEditingController();
  final TextEditingController contactPersonNameController = TextEditingController();
  final TextEditingController contactPersonNumberController = TextEditingController();
  final TextEditingController contactPersonAddressController = TextEditingController();
  final FocusNode nameNode = FocusNode();
  final FocusNode phoneNode = FocusNode();
  final FocusNode streetNode = FocusNode();
  final FocusNode houseNode = FocusNode();
  final FocusNode floorNode = FocusNode();

  String? countryDialCode = Get.find<AuthController>().getUserCountryCode().isNotEmpty ? Get.find<AuthController>().getUserCountryCode()
      : CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).dialCode ?? Get.find<LocalizationController>().locale.countryCode;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AddressModel? _address;
  AddressModel? get address => _address;

  AddressModel? _guestAddress;
  AddressModel? get guestAddress => _guestAddress;

  int? _mostDmTipAmount;
  int? get mostDmTipAmount => _mostDmTipAmount;

  String _preferableTime = '';
  String get preferableTime => _preferableTime;

  /// True when "Instant delivery" is selected (no schedule slot picked).
  /// Saver delivery options are only meaningful for instant delivery.
  bool get isInstantDelivery {
    final String t = _preferableTime.trim();
    if (t.isEmpty) return true;
    final String lower = t.toLowerCase();
    return lower == 'instance' || lower == 'instant'.tr.toLowerCase() || lower == 'instance'.tr.toLowerCase();
  }

  List<OfflineMethodModel>? _offlineMethodList;
  List<OfflineMethodModel>? get offlineMethodList => _offlineMethodList;

  bool _isPartialPay = false;
  bool get isPartialPay => _isPartialPay;

  // True once wallet is applied as a partial payment but the remainder method
  // (cash_after_service / digital_payment) hasn't been chosen yet — index 1 is
  // wallet's own slot, reused during partial pay to mean "pending remainder choice".
  bool get hasIncompletePartialSelection => isPartialPay && _paymentMethodIndex == 1;

  double _tips = 0.0;
  double get tips => _tips;

  int _selectedTips = 0;
  int get selectedTips => _selectedTips;

  Store? _store;
  Store? get store => _store;

  int? _addressIndex = 0;
  int? get addressIndex => _addressIndex;

  XFile? _orderAttachment;
  XFile? get orderAttachment => _orderAttachment;

  Uint8List? _rawAttachment;
  Uint8List? get rawAttachment => _rawAttachment;

  bool _acceptTerms = true;
  bool get acceptTerms => _acceptTerms;

  int _paymentMethodIndex = -1;
  int get paymentMethodIndex => _paymentMethodIndex;

  int _selectedDateSlot = 0;
  int get selectedDateSlot => _selectedDateSlot;

  int _selectedTimeSlot = 0;
  int get selectedTimeSlot => _selectedTimeSlot;

  double? _distance;
  double? get distance => _distance;

  /// Seconds `config/distance-api` estimated for the route, alongside the
  /// distance it was measured with. Null whenever the routing call did not
  /// answer — the Geolocator fallback measures a straight line between two
  /// points and has no duration to give, and a guessed one must not be posted
  /// as if it were routed.
  double? _deliveryDuration;
  double? get deliveryDuration => _deliveryDuration;

  List<TimeSlotModel>? _timeSlots;
  List<TimeSlotModel>? get timeSlots => _timeSlots;

  List<TimeSlotModel>? _allTimeSlots;
  List<TimeSlotModel>? get allTimeSlots => _allTimeSlots;

  List<XFile> _pickedPrescriptions = [];
  List<XFile> get pickedPrescriptions => _pickedPrescriptions;

  List<String?> _pickedPrescriptionSavedImageNames = [];
  List<String?> get pickedPrescriptionSavedImageNames =>
      _pickedPrescriptionSavedImageNames;

  List<bool> _pickedPrescriptionFromMediaLibrary = [];
  List<bool> get pickedPrescriptionFromMediaLibrary => _pickedPrescriptionFromMediaLibrary;

  double? _extraCharge;
  double? get extraCharge => _extraCharge;

  String? _orderType = 'delivery';
  String? get orderType => _orderType;

  double _viewTotalPrice = 0;
  double? get viewTotalPrice => _viewTotalPrice;

  int _selectedOfflineBankIndex = 0;
  int get selectedOfflineBankIndex => _selectedOfflineBankIndex;

  int _selectedInstruction = -1;
  int get selectedInstruction => _selectedInstruction;

  bool _isDmTipSave = false;
  bool get isDmTipSave => _isDmTipSave;

  String? _digitalPaymentName;
  String? get digitalPaymentName => _digitalPaymentName;

  List<SavedPrescriptionModel>? _savedPrescriptions;
  List<SavedPrescriptionModel>? get savedPrescriptions => _savedPrescriptions;

  bool _isSavedPrescriptionLoading = false;
  bool get isSavedPrescriptionLoading => _isSavedPrescriptionLoading;

  bool _isSavedPrescriptionDeleting = false;
  bool get isSavedPrescriptionDeleting => _isSavedPrescriptionDeleting;

  String? _savedPrescriptionErrorMessage;
  String? get savedPrescriptionErrorMessage => _savedPrescriptionErrorMessage;

  bool _isPrescriptionUploading = false;
  bool get isPrescriptionUploading => _isPrescriptionUploading;

  int _prescriptionUploadingCount = 0;
  int get prescriptionUploadingCount => _prescriptionUploadingCount;

  bool _canShowTipsField = false;
  bool get canShowTipsField => _canShowTipsField;

  bool _isExpanded = false;
  bool get isExpanded => _isExpanded;

  bool _isExpand = false;
  bool get isExpand => _isExpand;

  double _exchangeAmount = 0;
  double get exchangeAmount => _exchangeAmount;

  bool _isCreateAccount = false;
  bool get isCreateAccount => _isCreateAccount;

  bool _monthlySubscribe = false;
  bool get monthlySubscribe => _monthlySubscribe;

  void toggleMonthlySubscribe() {
    _monthlySubscribe = !_monthlySubscribe;
    print('[DEBUG] Monthly Subscribe toggled: $_monthlySubscribe');
    update();
  }

  List<String> getMonthlyReorderPolicy() => checkoutServiceInterface.getMonthlyReorderPolicy();

  bool _isFirstTime = true;
  bool get isFirstTime => _isFirstTime;

  double? _orderTax = 0.0;
  double? get orderTax => _orderTax;

  // Guards against stale tax responses: when a coupon is added/removed quickly,
  // an older in-flight request must not overwrite the result of a newer one.
  int _taxRequestId = 0;

  int? _taxIncluded;
  int? get taxIncluded => _taxIncluded;

  SurgePriceModel? _surgePrice;
  SurgePriceModel? get surgePrice => _surgePrice;

  /// The server's quote for the current basket, or null before the first
  /// response. Every figure it carries is priced by the same methods
  /// `place_order` calls, so where it is present it is authoritative and the
  /// client-side arithmetic in `CheckoutScreen` is only a fallback.
  CheckoutSummaryModel? _checkoutSummary;
  CheckoutSummaryModel? get checkoutSummary => _checkoutSummary;

  /// Guards against stale quotes exactly as [_taxRequestId] does: the summary
  /// refires on every coupon, tip, address and coverage change, and an older
  /// in-flight response must not overwrite a newer one.
  int _summaryRequestId = 0;

  /// Inputs the last quote was fetched for, so an unchanged basket does not
  /// refetch on every rebuild.
  String? _lastSummarySignature;

  /// The last basket quoted, kept so a coverage pick made from the address sheet
  /// can requote on its own — the widget that owns the picker sits well below the
  /// screen that knows the cart totals.
  CheckoutSummaryBodyModel? _lastSummaryBody;

  bool _summaryLoading = false;
  bool get summaryLoading => _summaryLoading;

  String? _summaryError;
  String? get summaryError => _summaryError;

  /// True once a quote has come back saying the address falls outside the
  /// store's zone (`delivery: null`). Render nothing for the fee rather than a
  /// zero, which reads as "free".
  bool get isOutsideDeliveryZone => _checkoutSummary != null && _checkoutSummary!.delivery == null;

  CoverageListModel? _coverageList;
  CoverageListModel? get coverageList => _coverageList;

  /// The customer's coverage pick. Only one can be set — which one depends on
  /// [CoverageListModel.isZipCode] — and it is posted to both the quote and
  /// `place_order`, because the fee moves with it.
  int? _selectedAreaId;
  int? get selectedAreaId => _selectedAreaId;

  int? _selectedZipCodeId;
  int? get selectedZipCodeId => _selectedZipCodeId;

  /// The picked option, for rendering the picker's current value.
  CoverageOption? get selectedCoverageOption {
    final int? id = _coverageList?.isZipCode == true ? _selectedZipCodeId : _selectedAreaId;
    if (id == null || _coverageList == null) return null;
    for (final CoverageOption option in _coverageList!.coverage) {
      if (option.id == id) return option;
    }
    return null;
  }

  /// Whether the zone's rule prices by ZIP code rather than by area — decides
  /// which key the pick is posted under and which wording the customer sees.
  bool get isZipCodeWiseDelivery => _coverageList?.isZipCode ?? false;

  /// Whether this zone prices by area or ZIP at all. False for `distance_wise`,
  /// `fixed_amount`, and a rule with no options configured.
  bool get isCoverageBasedDelivery => _coverageList?.requiresSelection ?? false;

  /// Whether the customer must pick before the order can be placed.
  ///
  /// Gated on delivery: a take-away order has no fee to price, so asking for an
  /// area would block an order that never needed one.
  bool get needCoverageAreaSelection => isCoverageBasedDelivery && _orderType == 'delivery';

  /// The pick is required here and has not been made. Checked by the place-order
  /// button, which warns and opens the picker rather than letting the order go
  /// through priced at the rule's minimum.
  bool get isCoverageSelectionMissing => needCoverageAreaSelection && selectedCoverageOption == null;

  bool  _isFirstTimeCodActive = true;
  bool get isFirstTimeCodActive => _isFirstTimeCodActive;

  String? _saverDeliveryType = 'standard';
  String? get saverDeliveryType => _saverDeliveryType;

  ZoneData? _saverZoneData;
  ZoneData? get saverZoneData => _saverZoneData;

  Modules? _saverModule;
  Modules? get saverModule => _saverModule;

  DeliveryOptions? get selectedSaverDeliveryOption {
    if(_saverModule?.deliveryOptions == null) {
      return null;
    }
    for(final deliveryOption in _saverModule!.deliveryOptions!) {
      if(deliveryOption.deliveryType == _saverDeliveryType) {
        return deliveryOption;
      }
    }
    return null;
  }

  /// The saver tiers the quote priced for this order, empty when it sent none.
  ///
  /// Authoritative over the zone/module config wherever present: these are
  /// priced against this basket, and carry a `time_range` the client used to
  /// have to reconstruct from the store's free-text delivery time.
  List<CheckoutSummaryDeliveryOption> get quotedDeliveryOptions =>
      _checkoutSummary?.deliveryOptions ?? const <CheckoutSummaryDeliveryOption>[];

  /// The quote's row for a tier, or null when it did not price that tier.
  CheckoutSummaryDeliveryOption? quotedDeliveryOptionFor(String? deliveryType) {
    if(deliveryType == null || deliveryType.isEmpty) return null;
    for(final CheckoutSummaryDeliveryOption option in quotedDeliveryOptions) {
      if(option.deliveryType == deliveryType) return option;
    }
    return null;
  }

  double getSaverDeliveryChargeAdjustment({DeliveryOptions? deliveryOption}) {
    if(deliveryOption == null) {
      return 0;
    }
    if(deliveryOption.extraCharge != null) {
      return deliveryOption.extraCharge!;
    }
    if(deliveryOption.reduceCharge != null) {
      return -deliveryOption.reduceCharge!;
    }
    return 0;
  }

  /// The zone rule's floor for the delivery fee, null when this zone sets none.
  ///
  /// A saver reduction is measured against it, so the row explaining a reduction
  /// that did not land needs the same figure the cap was taken from.
  ///
  /// The quote answers first. It is priced for this order and carries the floor
  /// whenever it carries the tiers, while the zone-config copy hangs off the saved
  /// address and is simply absent wherever that address was resolved before the zone
  /// had the rule — and an absent floor let the whole reduce charge come off a fee
  /// that could never give it up.
  double? get saverMinimumDeliveryCharge =>
      _checkoutSummary?.delivery?.minDeliveryCharge ?? _saverModule?.pivot?.minimumDeliveryCharge;

  /// The tier's own adjustment, before the minimum delivery charge caps it.
  ///
  /// [deliveryType] names the tier directly, for callers rendering the quote's
  /// own options — those have no matching zone-config [DeliveryOptions] object
  /// to pass. Falls back to the passed option, then to the current selection.
  ///
  /// This is what the saver tier rows show: the platform's configured `+` or `-`
  /// for the tier, as sent. The cap belongs to the bill, which has to stay
  /// payable; on the rows it would quietly print a smaller number than the one
  /// the admin set against the tier.
  double rawSaverDeliveryAdjustment({DeliveryOptions? deliveryOption, String? deliveryType}) {
    final DeliveryOptions? resolvedOption = deliveryOption ?? selectedSaverDeliveryOption;
    final CheckoutSummaryDeliveryOption? quoted =
        quotedDeliveryOptionFor(deliveryType ?? resolvedOption?.deliveryType ?? _saverDeliveryType);
    // The quote wins: it priced this tier against this basket, where the config
    // only describes the zone's rule in the abstract.
    return quoted?.chargeAdjustment ?? getSaverDeliveryChargeAdjustment(deliveryOption: resolvedOption);
  }

  /// Saver delivery fee adjustment as actually applied to the bill, clamped so a
  /// slightly-delay reduction can never drop the delivery fee below the saver
  /// minimum delivery charge. Without this a reduce charge larger than the fee
  /// would drive the delivery portion (and the order total) negative; capping it
  /// keeps the net delivery charge at the configured minimum (0 when no minimum).
  double getEffectiveSaverDeliveryAdjustment({required double deliveryCharge, DeliveryOptions? deliveryOption,
    String? deliveryType,
  }) {
    final double adjustment = rawSaverDeliveryAdjustment(deliveryOption: deliveryOption, deliveryType: deliveryType);
    // Only reductions can overshoot; cap them when the fee is a valid positive
    // amount (skip -1 "calculating"/0 "free" states).
    if(adjustment >= 0 || deliveryCharge <= 0) {
      return adjustment;
    }
    // The customer must still pay at least the minimum delivery charge, so the
    // reduction can only bring the fee down to that minimum — not to zero.
    final double minimumDeliveryCharge = saverMinimumDeliveryCharge ?? 0;
    final double maxReduction = (deliveryCharge - minimumDeliveryCharge).clamp(0, deliveryCharge).toDouble();
    return adjustment < -maxReduction ? -maxReduction : adjustment;
  }

  /// How much of the selected tier's reduce charge the minimum delivery charge held
  /// back, and 0 when the whole reduction landed.
  ///
  /// A tier whose reduction is capped away leaves the fee sitting where it was, with
  /// the card and the bill both saying nothing about why — this is what the delivery
  /// fee row explains.
  double getBlockedSaverDeliveryReduction({required double deliveryCharge, DeliveryOptions? deliveryOption,
    String? deliveryType,
  }) {
    final double adjustment = rawSaverDeliveryAdjustment(deliveryOption: deliveryOption, deliveryType: deliveryType);
    if(adjustment >= 0) {
      return 0;
    }
    final double effective = getEffectiveSaverDeliveryAdjustment(
      deliveryCharge: deliveryCharge, deliveryOption: deliveryOption, deliveryType: deliveryType,
    );
    return effective - adjustment;
  }

  void setSaverDeliveryType(String type) {
    _saverDeliveryType = type;
    update();
  }

  /// Resolves the saver delivery config for the current address and store.
  ///
  /// The zone comes from the **stored** address, so this has to re-run whenever
  /// that address changes: a customer who switches to an address in another zone
  /// would otherwise keep the previous zone's saver options and pivot minimum.
  /// It used to run only once, from [initCheckoutData], and never again.
  ///
  /// [notify] follows the project convention — pass `false` when calling from a
  /// widget's `initState` or from an init path that repaints on its own.
  void refreshSaverDeliveryData({bool notify = true}) {
    final int? previousModuleId = _saverModule?.id;

    try {
      _saverZoneData = AddressHelper.getUserAddressFromSharedPref()?.zoneData?.firstWhere((zone) => zone.id == _store?.zoneId);
    } catch (_) {
      _saverZoneData = null;
    }
    try {
      _saverModule = _saverZoneData?.modules?.firstWhere((module) => module.id == _store?.moduleId);
    } catch (_) {
      _saverModule = null;
    }

    if(_saverModule != null && (_saverModule!.additionalDeliveryOptionStatus ?? false)) {
      final List<DeliveryOptions> options = _saverModule!.deliveryOptions ?? <DeliveryOptions>[];
      // Keep the customer's tier when the same module resolved again and still
      // offers it; only fall back to the default when the module actually changed
      // or the option is gone.
      final bool selectionStillValid = previousModuleId == _saverModule!.id
          && options.any((DeliveryOptions option) => option.deliveryType == _saverDeliveryType);
      if(!selectionStillValid) {
        _saverDeliveryType = options.isNotEmpty ? options.first.deliveryType ?? 'standard' : 'standard';
      }
    } else {
      _saverDeliveryType = 'standard';
    }

    if(notify) update();
  }

  void updateFirstTimeCodActive({bool isActive = true}) {
    _isFirstTimeCodActive = isActive;
    update();
  }

  void updateFirstTime() {
    _isFirstTime = true;
    update();
  }

  void resetOrderTax() {
    _orderTax = 0.0;
    _taxIncluded = null;
    resetCheckoutSummary();
  }

  void setExchangeAmount(double value) {
    _exchangeAmount = value;
  }

  void initAdditionData(){
    noteController.clear();
    _selectedInstruction = -1;
  }

  Future<void> initCheckoutData(int? storeId) async {
    Get.find<CouponController>().removeCouponData(false);

    _store = await Get.find<StoreController>().getStoreDetails(Store(id: storeId), false);

    // The quote fired by CheckoutScreen repaints, so this need not.
    refreshSaverDeliveryData(notify: false);

    resetCheckoutSummary();

    if (_store != null) {
      // Whether the customer has an area or ZIP to pick before the fee means
      // anything. Not awaited because it only gates a picker, never the quote: a
      // missing pick is charged the rule's own minimum rather than refused.
      if(_store!.zoneId != null) {
        getCoverageList(zoneId: _store!.zoneId!, moduleId: _store!.moduleId, notify: false);
      }

      if(Get.find<SplashController>().module == null) {
        // Same unguarded index as the cart's checkout button used to have: when the
        // store's module was not in the list this walked one past the end and threw
        // a RangeError, which stopped the rest of `initCheckoutData` — including the
        // time slots — without any visible error.
        await Get.find<SplashController>().activateModuleById(_store!.moduleId);
      }

      initializeTimeSlot(_store!);
    }
  }

  void showTipsField(){
    _canShowTipsField = !_canShowTipsField;
    update();
  }

  Future<void> addTips(double tips)async {
    _tips = tips;
    update();
  }

  void expandedUpdate(bool status){
    _isExpanded = status;
    update();
  }

  void setPaymentMethod(int index, {bool isUpdate = true}) {
    _paymentMethodIndex = index;
    if(_isFirstTimeCodActive) updateFirstTimeCodActive(isActive: false);
    if(isUpdate){
      update();
    }
  }

  void changeDigitalPaymentName(String name, {bool willUpdate = true}){
    _digitalPaymentName = name;
    if(willUpdate) {
      update();
    }
  }

  void setOrderType(String? type, {bool notify = true}) {
    _orderType = type;
    if(notify) {
      update();
    }
  }

  void changePartialPayment({bool isUpdate = true}){
    _isPartialPay = !_isPartialPay;
    if(isUpdate) {
      update();
    }
  }

  void setAddressIndex(int? index) {
    _addressIndex = index;
    update();
  }

  void setGuestAddress(AddressModel? address, {bool isUpdate = true}){
    _guestAddress = address;
    contactPersonAddressController.text = address?.address ?? '';
    // A new address can land in a different zone, which changes (or removes) the
    // saver delivery options.
    refreshSaverDeliveryData(notify: false);
    if(isUpdate) {
      update();
    }
  }

  Future<void> getDmTipMostTapped()async {
    _mostDmTipAmount = await checkoutServiceInterface.getDmTipMostTapped();
    update();
  }

  void setPreferenceTimeForView(String time, {bool isUpdate = true}){
    _preferableTime = time;
    // Saver delivery options apply only to instant delivery — clear the selection when scheduling.
    if(!isInstantDelivery) {
      _saverDeliveryType = 'standard';
    }
    if(isUpdate) {
      update();
    }
  }

  Future<List<OfflineMethodModel>?> getOfflineMethodList()async {
    _offlineMethodList = null;
    _offlineMethodList = await checkoutServiceInterface.getOfflineMethodList();
    update();
    return _offlineMethodList;
  }

  void updateTips(int index, {bool notify = true}) {
    _selectedTips = index;
    final String tipValue = AppConstants.tips[index];
    if(tipValue == '0' || tipValue == 'custom') {
      _tips = 0;
    }else {
      _tips = double.parse(tipValue);
    }
    if(notify) {
      update();
    }
  }

  void saveSharedPrefDmTipIndex(String i){
    checkoutServiceInterface.saveSharedPrefDmTipIndex(i);
  }

  String getSharedPrefDmTipIndex() {
    return checkoutServiceInterface.getSharedPrefDmTipIndex();
  }

  void setTotalAmount(double amount){
    _viewTotalPrice = amount;
  }

  void clearPrevData() {
    _distance = null;
    _addressIndex = 0;
    _acceptTerms = true;
    _paymentMethodIndex = -1;
    _selectedDateSlot = 0;
    _selectedTimeSlot = 0;
    _orderAttachment = null;
    _rawAttachment = null;
    _saverZoneData = null;
    _saverModule = null;
    _saverDeliveryType = 'standard';
    // The coverage pick belongs to one checkout visit, not to the app session.
    // This controller is a singleton, so without clearing here the previous
    // visit's area/ZIP came back pre-selected — and was posted to the quote and
    // to `place_order` — for a customer who never picked it this time.
    //
    // The list itself is deliberately left alone: `getCoverageList` clears and
    // refetches it on its own, and this method also runs from flows that never
    // refetch it (a global address change), where blanking the list would take
    // the picker off screen with nothing to put it back.
    _selectedAreaId = null;
    _selectedZipCodeId = null;
  }

  Future<void> initializeTimeSlot(Store store) async {
    _timeSlots = await checkoutServiceInterface.initializeTimeSlot(store, Get.find<SplashController>().configModel!.scheduleOrderSlotDuration!);
    _allTimeSlots = await checkoutServiceInterface.initializeTimeSlot(store, Get.find<SplashController>().configModel!.scheduleOrderSlotDuration!);

    _validateSlot(_allTimeSlots!, 0, store.orderPlaceToScheduleInterval, notify: false);
  }

  void _validateSlot(List<TimeSlotModel> slots, int dateIndex, int? interval, {bool notify = true}) {
    _timeSlots = checkoutServiceInterface.validateTimeSlot(slots, dateIndex, interval, Get.find<SplashController>().configModel!.moduleConfig!.module!.orderPlaceToScheduleInterval!);

    if(notify) {
      update();
    }
  }

  void pickPrescriptionImage({required bool isRemove, required bool isCamera}) async {
    if(isRemove) {
      _pickedPrescriptions = [];
      _pickedPrescriptionSavedImageNames = [];
      _pickedPrescriptionFromMediaLibrary = [];
    }else {
      final fileValidator = FileValidationHelper();
      XFile? xFile = await ImagePicker().pickImage(source: isCamera ? ImageSource.camera : ImageSource.gallery, imageQuality: 50);
      if(xFile != null) {

        final bool isValid = await fileValidator.isFileUnder2MB(xFile);

        if(isValid == false) {
          showCustomSnackBar('please_upload_lower_size_file'.tr);
          update();
          return;
        }
        if(_pickedPrescriptions.length >= maxPrescriptionFileCount) {
          showCustomSnackBar('you_have_reached_your_maximum_limit'.tr);
          update();
          return;
        }

        final String signature = await _getPrescriptionSignature(xFile);
        final Set<String> existingSignatures = await _getPrescriptionSignatureSet(_pickedPrescriptions, _pickedPrescriptionSavedImageNames);

        if(existingSignatures.contains(signature)) {
          showCustomSnackBar('This prescription image is already added.');
        } else {
          _pickedPrescriptions.add(xFile);
          _pickedPrescriptionSavedImageNames.add(null);
          _pickedPrescriptionFromMediaLibrary.add(false);
        }
      }
      update();
    }
  }

  Future<List<XFile>?> pickMultiplePrescriptionImages({int? maxSelectable}) async {
    final int effectiveLimit = (maxSelectable ?? maxPrescriptionSaveBatchCount) <= maxPrescriptionSaveBatchCount
        ? (maxSelectable ?? maxPrescriptionSaveBatchCount)
        : maxPrescriptionSaveBatchCount;

    if(effectiveLimit <= 0) {
      showCustomSnackBar('you_have_reached_your_maximum_limit'.tr);
      return [];
    }

    List<XFile> xFiles;
    if(effectiveLimit == 1) {
      final XFile? file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 100);
      xFiles = file != null ? [file] : [];
    } else {
      xFiles = await ImagePicker().pickMultiImage(imageQuality: 100, limit: effectiveLimit);
    }

    if(xFiles.isEmpty) return xFiles;

    final fileValidator = FileValidationHelper();

    final List<XFile> validFiles = [];
    bool hasOversizeFile = false;
    for(final XFile file in xFiles) {
      final bool isValid = await fileValidator.isFileUnder2MB(file);
      if (isValid) {
        validFiles.add(file);
      } else {
        hasOversizeFile = true;
      }
    }


    print("hasOversizeFile: $hasOversizeFile");

    if(hasOversizeFile) {
      showCustomSnackBar('max_file_size_2mb'.tr);
    }
    return validFiles;
  }

  Future<void> addPrescriptionImages(List<XFile> xFiles, {bool isAutoSaved = false, List<String?>? savedImageNames, List<bool>? mediaLibraryFlags}) async {
    if(xFiles.isEmpty) {
      return;
    }

    final List<String?> incomingSavedNames = savedImageNames != null && savedImageNames.length == xFiles.length
        ? List<String?>.from(savedImageNames) : List<String?>.filled(xFiles.length, null);
    final List<bool> incomingMediaLibraryFlags = mediaLibraryFlags != null && mediaLibraryFlags.length == xFiles.length
        ? List<bool>.from(mediaLibraryFlags) : List<bool>.filled(xFiles.length, false);

    final Set<String> existingSignatures = await _getPrescriptionSignatureSet(_pickedPrescriptions, _pickedPrescriptionSavedImageNames);

    final ({List<XFile> files, List<String?> savedNames, List<bool> mediaLibraryFlags, int skippedCount}) uniquePayload = await _getUniquePrescriptionPayload(
      xFiles, incomingSavedNames, incomingMediaLibraryFlags, existingSignatures: existingSignatures,
    );

    if(uniquePayload.files.isEmpty) {
      showCustomSnackBar('This prescription image is already added.');
      return;
    }

    // Apply global count limits
    final ({List<XFile> files, List<String?> savedNames, List<bool> mediaLibraryFlags, int trimmedCount}) limitedPayload = _limitPrescriptionPayload(
        uniquePayload.files, uniquePayload.savedNames, uniquePayload.mediaLibraryFlags, availableSlots: maxPrescriptionFileCount - _pickedPrescriptions.length);

    if(limitedPayload.files.isEmpty) {
      showCustomSnackBar('you_have_reached_your_maximum_limit'.tr);
      return;
    }

    if(uniquePayload.skippedCount > 0) {
      showCustomSnackBar('Duplicate prescription image skipped.', isError: false);
    }
    if(limitedPayload.trimmedCount > 0) {
      showCustomSnackBar('you_have_reached_your_maximum_limit'.tr);
    }

    // Identify which files need to be uploaded to the server
    final List<XFile> filesToSave = await _getFilesNeedingMediaSave(limitedPayload.files, limitedPayload.savedNames);

    List<String> newlySavedNames = [];
    if(isAutoSaved && filesToSave.isNotEmpty) {
      _isPrescriptionUploading = true;
      _prescriptionUploadingCount = filesToSave.length;
      update();

      newlySavedNames = await _saveToMediaLibrary(filesToSave);

      _isPrescriptionUploading = false;
      _prescriptionUploadingCount = 0;
    }

    _pickedPrescriptions.addAll(limitedPayload.files);
    _pickedPrescriptionSavedImageNames.addAll(
      _mergeSavedImageNames(limitedPayload.savedNames, newlySavedNames),
    );
    _pickedPrescriptionFromMediaLibrary.addAll(limitedPayload.mediaLibraryFlags);
    update();
  }

  Future<void> updatePrescriptionImages(List<XFile> xFiles, {bool isAutoSaved = false, List<String?>? savedImageNames, List<bool>? mediaLibraryFlags}) async {
    final List<String?> incomingSavedNames = savedImageNames != null && savedImageNames.length == xFiles.length
        ? List<String?>.from(savedImageNames) : List<String?>.filled(xFiles.length, null);
    final List<bool> incomingMediaLibraryFlags = mediaLibraryFlags != null && mediaLibraryFlags.length == xFiles.length
        ? List<bool>.from(mediaLibraryFlags) : List<bool>.filled(xFiles.length, false);

    final ({List<XFile> files, List<String?> savedNames, List<bool> mediaLibraryFlags, int skippedCount}) uniquePayload = await _getUniquePrescriptionPayload(
      xFiles, incomingSavedNames, incomingMediaLibraryFlags,
    );

    if(uniquePayload.files.isEmpty) {
      showCustomSnackBar('At least one prescription image is required.');
      return;
    }

    final ({List<XFile> files, List<String?> savedNames, List<bool> mediaLibraryFlags, int trimmedCount}) limitedPayload = _limitPrescriptionPayload(
        uniquePayload.files, uniquePayload.savedNames, uniquePayload.mediaLibraryFlags);

    if(uniquePayload.skippedCount > 0) {
      showCustomSnackBar('Duplicate prescription image skipped.', isError: false);
    }
    if(limitedPayload.trimmedCount > 0) {
      showCustomSnackBar('you_have_reached_your_maximum_limit'.tr);
    }

    final List<XFile> filesToSave = await _getFilesNeedingMediaSave(limitedPayload.files, limitedPayload.savedNames);

    List<String> newlySavedNames = [];
    if(isAutoSaved && filesToSave.isNotEmpty) {
      _isPrescriptionUploading = true;
      _prescriptionUploadingCount = filesToSave.length;
      update();

      newlySavedNames = await _saveToMediaLibrary(filesToSave);

      _isPrescriptionUploading = false;
      _prescriptionUploadingCount = 0;
    }

    _pickedPrescriptions.clear();
    _pickedPrescriptionSavedImageNames.clear();
    _pickedPrescriptionFromMediaLibrary.clear();
    _pickedPrescriptions.addAll(limitedPayload.files);
    _pickedPrescriptionSavedImageNames.addAll(
      _mergeSavedImageNames(limitedPayload.savedNames, newlySavedNames),
    );
    _pickedPrescriptionFromMediaLibrary.addAll(limitedPayload.mediaLibraryFlags);
    update();
  }

  ({List<XFile> files, List<String?> savedNames, List<bool> mediaLibraryFlags, int trimmedCount}) _limitPrescriptionPayload(
      List<XFile> files, List<String?> savedImageNames, List<bool> mediaLibraryFlags, {int availableSlots = maxPrescriptionFileCount}) {
    final int sanitizedAvailableSlots = availableSlots < 0 ? 0 : availableSlots;
    if(files.length <= sanitizedAvailableSlots) {
      return (files: files, savedNames: savedImageNames, mediaLibraryFlags: mediaLibraryFlags, trimmedCount: 0);
    }

    return (
    files: files.take(sanitizedAvailableSlots).toList(),
    savedNames: savedImageNames.take(sanitizedAvailableSlots).toList(),
    mediaLibraryFlags: mediaLibraryFlags.take(sanitizedAvailableSlots).toList(),
    trimmedCount: files.length - sanitizedAvailableSlots,
    );
  }

  Future<({List<XFile> files, List<String?> savedNames, List<bool> mediaLibraryFlags, int skippedCount})> _getUniquePrescriptionPayload(
      List<XFile> xFiles,
      List<String?> savedImageNames,
      List<bool> mediaLibraryFlags, {
        Set<String>? existingSignatures,
      }) async {
    final Set<String> signatures = existingSignatures != null ? <String>{...existingSignatures} : <String>{};
    final List<XFile> uniqueFiles = [];
    final List<String?> uniqueSavedNames = [];
    final List<bool> uniqueMediaLibraryFlags = [];
    int skippedCount = 0;

    for(int index = 0; index < xFiles.length; index++) {
      final XFile file = xFiles[index];
      final String? savedName = savedImageNames[index];
      final bool isFromMediaLibrary = mediaLibraryFlags[index];

      final String localSignature = await _getPrescriptionSignature(file);
      final String? savedSignature = (savedName?.trim().isNotEmpty ?? false) ? await _getPrescriptionSignature(file, savedImageName: savedName) : null;

      if (signatures.contains(localSignature) || (savedSignature != null && signatures.contains(savedSignature))) {
        skippedCount++;
      } else {
        signatures.add(localSignature);
        if(savedSignature != null) {
          signatures.add(savedSignature);
        }
        uniqueFiles.add(file);
        uniqueSavedNames.add(savedName);
        uniqueMediaLibraryFlags.add(isFromMediaLibrary);
      }
    }

    return (files: uniqueFiles, savedNames: uniqueSavedNames, mediaLibraryFlags: uniqueMediaLibraryFlags, skippedCount: skippedCount);
  }

  Future<Set<String>> _getPrescriptionSignatureSet(List<XFile> files, List<String?> savedImageNames) async {
    final Set<String> signatures = <String>{};
    for(int index = 0; index < files.length; index++) {
      signatures.add(await _getPrescriptionSignature(files[index]));

      if(index < savedImageNames.length && (savedImageNames[index]?.trim().isNotEmpty ?? false)) {
        signatures.add(await _getPrescriptionSignature(
          files[index],
          savedImageName: savedImageNames[index],
        ));
      }
    }
    return signatures;
  }

  Future<String> _getPrescriptionSignature(XFile file, {String? savedImageName}) async {
    final String normalizedSavedImageName = savedImageName?.trim() ?? '';
    if(normalizedSavedImageName.isNotEmpty) {
      return 'saved:${normalizedSavedImageName.toLowerCase()}';
    }

    final String fileName = file.name.isNotEmpty ? file.name : path.basename(file.path);
    final int fileLength = await file.length();
    final String extension = path.extension(fileName).toLowerCase();

    if (fileName.contains('image_picker') || fileName.contains('scaled_') || fileName.length > 40) {
      return 'local-size:$fileLength$extension';
    }

    return 'local:${fileName.toLowerCase()}:$fileLength';
  }

  Future<List<XFile>> _getFilesNeedingMediaSave(List<XFile> files, List<String?> savedImageNames) async {
    final List<XFile> filesToSave = [];
    for(int index = 0; index < files.length; index++) {
      final String savedImageName = index < savedImageNames.length ? savedImageNames[index]?.trim() ?? '' : '';
      if(savedImageName.isNotEmpty) {
        continue;
      }
      filesToSave.add(files[index]);
    }
    return filesToSave;
  }

  Future<List<String>> _saveToMediaLibrary(List<XFile> xFiles) async {
    if(xFiles.isEmpty) {
      return [];
    }

    final Map<String, int> previousSavedNameCounts = _getSavedFileNameCounts(_savedPrescriptions);
    List<MultipartBody> savedImages = [];
    for(XFile file in xFiles) {
      savedImages.add(MultipartBody('saved_images[]', file));
    }

    Response response = await checkoutServiceInterface.storeSavedPrescriptionImages(savedImages);

    if(response.statusCode == 200){
      await getSavedPrescriptionImages(reload: true);
      return _getNewlySavedFileNames(previousSavedNameCounts, _savedPrescriptions);
    }else{
      // A failed body is not always the `{message: …}` map this assumed — some
      // endpoints answer with a bare list of errors, and naming a key on a List
      // throws. _bodyValue() returns null rather than blowing up on the error path.
      showCustomSnackBar(_bodyValue(response, 'message')?.toString() ?? response.statusText);
      return [];
    }
  }

  List<String?> _mergeSavedImageNames(List<String?> savedNames, List<String> newlySavedNames) {
    if(newlySavedNames.isEmpty) {
      return List<String?>.from(savedNames);
    }

    final List<String?> mergedNames = List<String?>.from(savedNames);
    int newSavedIndex = 0;
    for(int index = 0; index < mergedNames.length && newSavedIndex < newlySavedNames.length; index++) {
      if(mergedNames[index]?.trim().isEmpty ?? true) {
        mergedNames[index] = newlySavedNames[newSavedIndex];
        newSavedIndex++;
      }
    }
    return mergedNames;
  }

  Map<String, int> _getSavedFileNameCounts(List<SavedPrescriptionModel>? savedPrescriptions) {
    final Map<String, int> counts = <String, int>{};
    if(savedPrescriptions == null) {
      return counts;
    }

    for(final SavedPrescriptionModel savedPrescription in savedPrescriptions) {
      final String fileName = savedPrescription.fileName?.trim() ?? '';
      if(fileName.isNotEmpty) {
        counts[fileName] = (counts[fileName] ?? 0) + 1;
      }
    }
    return counts;
  }

  List<String> _getNewlySavedFileNames(Map<String, int> previousCounts, List<SavedPrescriptionModel>? currentSavedPrescriptions) {
    final Map<String, int> remainingCounts = <String, int>{...previousCounts};
    final List<String> newFileNames = [];

    if(currentSavedPrescriptions == null) {
      return newFileNames;
    }

    for(final SavedPrescriptionModel savedPrescription in currentSavedPrescriptions) {
      final String fileName = savedPrescription.fileName?.trim() ?? '';
      if(fileName.isEmpty) {
        continue;
      }

      final int existingCount = remainingCounts[fileName] ?? 0;
      if(existingCount > 0) {
        remainingCounts[fileName] = existingCount - 1;
      } else {
        newFileNames.add(fileName);
      }
    }

    return newFileNames;
  }

  Future<void> getSavedPrescriptionImages({bool reload = false})async {
    if(_isSavedPrescriptionLoading) {
      return;
    }

    if(!reload && _savedPrescriptions != null) {
      return;
    }

    _isSavedPrescriptionLoading = true;
    _savedPrescriptionErrorMessage = null;
    if(reload){
      _savedPrescriptions = null;
    }
    update();

    final List<SavedPrescriptionModel>? savedFiles = await checkoutServiceInterface.getSavedPrescriptionImages();
    if(savedFiles != null) {
      _savedPrescriptions = savedFiles;
    }else {
      _savedPrescriptions ??= [];
      _savedPrescriptionErrorMessage = 'unable_to_load_data'.tr;
    }
    _isSavedPrescriptionLoading = false;
    update();
  }

  Future<bool> clearAllSavedPrescriptionImages() async {
    if (_isSavedPrescriptionDeleting || _savedPrescriptions == null || _savedPrescriptions!.isEmpty) {
      return false;
    }

    _isSavedPrescriptionDeleting = true;
    update();

    final Response response = await checkoutServiceInterface.deleteSavedPrescriptionImages();
    _isSavedPrescriptionDeleting = false;

    if (response.statusCode == 200) {
      _savedPrescriptions!.clear();
      update();
      return true;
    } else {
      // A failed body is not always the `{message: …}` map this assumed — some
      // endpoints answer with a bare list of errors, and naming a key on a List
      // throws. _bodyValue() returns null rather than blowing up on the error path.
      showCustomSnackBar(_bodyValue(response, 'message')?.toString() ?? response.statusText);
      update();
      return false;
    }
  }

  Future<List<XFile>> getSelectedSavedPrescriptionFiles(List<int> indexes) async {
    if (_savedPrescriptions == null || _savedPrescriptions!.isEmpty || indexes.isEmpty) {
      return [];
    }

    final List<XFile> files = [];
    for (final int index in indexes) {
      if (index < 0 || index >= _savedPrescriptions!.length) {continue;}

      final XFile? file = await _downloadSavedPrescriptionFile(_savedPrescriptions![index]);
      if (file != null) {files.add(file);}
    }

    return files;
  }

  List<String> getSelectedSavedPrescriptionNames(List<int> indexes) {
    if (_savedPrescriptions == null || _savedPrescriptions!.isEmpty || indexes.isEmpty) {
      return [];
    }

    return indexes.where((index) => index >= 0 && index < _savedPrescriptions!.length).map((index)
    => _savedPrescriptions![index].fileName ?? '').where((fileName) => fileName.isNotEmpty).toList();
  }

  Future<XFile?> _downloadSavedPrescriptionFile(SavedPrescriptionModel savedPrescription) async {
    final String imageUrl = savedPrescription.imageFullUrl ?? '';
    if (imageUrl.isEmpty) {
      return null;
    }

    final String fileName =
    savedPrescription.fileName?.trim().isNotEmpty == true ? savedPrescription.fileName!.trim()
        : 'saved_prescription_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageUrl)}';
    final String requestUrl = kIsWeb && imageUrl.startsWith('http')
        ? '${AppConstants.baseUrl}/image-proxy?url=${Uri.encodeComponent(imageUrl)}'
        : imageUrl;

    try {
      final http.Response response = await http.get(Uri.parse(requestUrl));
      if (response.statusCode != 200) {
        return null;
      }

      if (kIsWeb) {
        final Uint8List bytes = response.bodyBytes;
        final String extension = path.extension(fileName).toLowerCase();

        String mimeType = 'image/jpeg';
        if (extension == '.png') {
          mimeType = 'image/png';
        } else if (extension == '.webp') {
          mimeType = 'image/webp';
        } else if (extension == '.gif') {
          mimeType = 'image/gif';
        }

        return XFile.fromData(
          bytes,
          name: fileName,
          mimeType: mimeType,
        );
      }

      final Directory directory = await getTemporaryDirectory();
      final String filePath = path.join( directory.path, '${DateTime.now().millisecondsSinceEpoch}_$fileName');
      final File file = File(filePath);
      await file.writeAsBytes(response.bodyBytes, flush: true);
      return XFile(file.path);
    } catch (_) {
      return null;
    }
  }

  void removePrescriptionImage(int index) {
    _pickedPrescriptions.removeAt(index);
    if (_pickedPrescriptionSavedImageNames.length > index) {
      _pickedPrescriptionSavedImageNames.removeAt(index);
    }
    if (_pickedPrescriptionFromMediaLibrary.length > index) {
      _pickedPrescriptionFromMediaLibrary.removeAt(index);
    }
    update();
  }

  bool isStoreClosed(bool today, bool active, List<Schedules>? schedules) {
    return Get.find<StoreController>().isStoreClosed(today, active, schedules);
  }

  bool isStoreOpenNow(bool active, List<Schedules>? schedules) {
    return Get.find<StoreController>().isStoreOpenNow(active, schedules);
  }

  Future<double?> getDistanceInKM(LatLng originLatLng, LatLng destinationLatLng) async {
    _distance = -1;
    _deliveryDuration = null;
    Response response = await checkoutServiceInterface.getDistanceInMeter(originLatLng, destinationLatLng);
    try {
      if (response.statusCode == 200) {
        final double distanceMater = response.body['distanceMeters']?.toDouble();
        _distance = distanceMater / 1000;
        // Read from the same response as the distance — `distance-api` returns
        // both, and the route is measured once. Parsed defensively rather than
        // inside the `.toDouble()` style above: a throw here lands in the catch
        // below and would discard a distance that had already parsed correctly,
        // silently replacing it with the straight-line estimate.
        _deliveryDuration = parseDurationSeconds(response.body['duration']);
      } else {
        _distance = Geolocator.distanceBetween(originLatLng.latitude, originLatLng.longitude, destinationLatLng.latitude, destinationLatLng.longitude) / 1000;
      }
    } catch (e) {
      _distance = Geolocator.distanceBetween(originLatLng.latitude, originLatLng.longitude, destinationLatLng.latitude, destinationLatLng.longitude) / 1000;
    }

    await _getExtraCharge(_distance);

    update();
    return _distance;
  }

  double parseDuration(String duration) {
    return double.tryParse(duration.replaceAll('s', '')) ?? 0.0;
  }

  /// `"11508s"` → `11508`, the seconds `config/distance-api` estimates for the
  /// leg. Posted as `delivery_duration` at placement.
  ///
  /// Total by design — every unusable shape answers null rather than throwing.
  /// Its one caller sits inside the `try` that owns the distance, so an
  /// exception raised here would cost a distance that had already parsed.
  static double? parseDurationSeconds(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    final String text = raw.toString().trim().toLowerCase();
    if (text.isEmpty) return null;
    // `replaceAll` would turn a stray "secs" into "ec"; only a trailing unit is
    // stripped, and anything else is left for `tryParse` to reject.
    return double.tryParse(text.endsWith('s') ? text.substring(0, text.length - 1) : text);
  }

  Future<double?> _getExtraCharge(double? distance) async {
    _extraCharge = null;
    _extraCharge = await checkoutServiceInterface.getExtraCharge(distance);
    return _extraCharge;
  }

  Future<bool> checkBalanceStatus(double totalPrice, double discount) async {
    totalPrice = (totalPrice - discount);
    if(isPartialPay){
      changePartialPayment();
    }
    setPaymentMethod(-1);
    if((Get.find<ProfileController>().userInfoModel!.walletBalance! < totalPrice) && (Get.find<ProfileController>().userInfoModel!.walletBalance! != 0.0)){
      Get.dialog(PartialPayDialogWidget(isPartialPay: true, totalPrice: totalPrice), useSafeArea: false,);
    }else{
      Get.dialog(PartialPayDialogWidget(isPartialPay: false, totalPrice: totalPrice), useSafeArea: false,);
    }
    update();
    return true;
  }

  void selectOfflineBank(int index, {bool canUpdate = true}){
    _selectedOfflineBankIndex = index;
    if(canUpdate) {
      update();
    }
  }

  void setInstruction(int index){
    if(_selectedInstruction == index){
      _selectedInstruction = -1;
    }else {
      _selectedInstruction = index;
    }
    update();
  }

  void toggleDmTipSave() {
    _isDmTipSave = !_isDmTipSave;
    update();
  }

  void stopLoader({bool canUpdate = true}) {
    _isLoading = false;
    if(canUpdate) {
      update();
    }
  }

  /// Caches the delivery address locally (max 10, newest first) so it appears in
  /// the pick-location "Recent" tab. Only delivery orders with a real location are saved.
  void _saveRecentDeliveryAddress({
    required String? orderType, required String? address, required String? latitude, required String? longitude,
    String? addressType, String? contactPersonName, String? contactPersonNumber, String? streetNumber, String? house, String? floor,
  }) {
    if (orderType != 'delivery' || address == null || address.isEmpty || latitude == null || longitude == null) {
      return;
    }
    Get.find<LocationController>().addRecentAddress(AddressModel(
      addressType: addressType, address: address, latitude: latitude, longitude: longitude, contactPersonName: contactPersonName,
      contactPersonNumber: contactPersonNumber, streetNumber: streetNumber, house: house, floor: floor,
    ));
  }

  /// One field off a place-order body, whatever envelope it arrived in.
  ///
  /// `ApiClient.unwrapEnvelope` already strips `content`, so the field is read
  /// straight off the body — this only guards the body being a non-Map (a raw
  /// string on a malformed response) rather than throwing mid-checkout.
  dynamic _bodyValue(Response response, String key) {
    final dynamic body = response.body;
    return body is Map ? body[key] : null;
  }

  /// The order id as a string, or '' when the response didn't carry one.
  ///
  /// The old code did `response.body['order_id'].toString()`, which on a missing
  /// id produced the literal string `"null"` — that then went into the
  /// order-success route and the web payment callback URL as if it were real.
  String _orderIdOf(Response response) => _bodyValue(response, 'order_id')?.toString() ?? '';

  /// The success message the user is shown.
  ///
  /// The envelope carries `message` at the top level, beside `content`, so
  /// `ApiClient` lifts it onto `statusText`; `body['message']` only exists on a
  /// legacy flat body, and is kept as the fallback so both backends work.
  String? _successMessageOf(Response response) {
    final String? statusText = response.statusText;
    if (statusText != null && statusText.isNotEmpty) return statusText;
    final dynamic message = _bodyValue(response, 'message');
    return message?.toString();
  }

  Future<String> placeOrder(PlaceOrderBodyModel placeOrderBody, int? zoneID, double amount, double? maximumCodOrderAmount, bool fromCart,
      bool isCashOnDeliveryActive, List<XFile>? orderAttachment, {bool isOfflinePay = false}) async {
    List<MultipartBody>? multiParts = [];
    final List<XFile> attachments = orderAttachment ?? [];
    // Every prescription goes up the same way. A media-library pick is already a real
    // local file by this point — getSelectedSavedPrescriptionFiles() downloads it — so
    // it uploads as order_attachment[] like a gallery pick. Passing only its stored
    // filename instead left the server with no prescription attached at all.
    for(final XFile file in attachments) {
      multiParts.add(MultipartBody('order_attachment[]', file));
    }
    _isLoading = true;
    update();
    String orderID = '';
    String userID = '';
    Response response = await checkoutServiceInterface.placeOrder(placeOrderBody, multiParts, const <String>[]);
    _isLoading = false;
    // Placing an order CREATES something, so it can answer 201 as well as 200 —
    // `== 200` would have reported a successfully placed order as a failure.
    if (ApiClient.isSuccessCode(response.statusCode)) {
      String? message = _successMessageOf(response);
      orderID = _orderIdOf(response);
      final dynamic userId = _bodyValue(response, 'user_id');
      if(userId != null) {
        userID = userId.toString();
      }
      Get.find<ItemController>().cartIndexSet();

      _saveRecentDeliveryAddress(
        orderType: placeOrderBody.orderType, address: placeOrderBody.address,
        latitude: placeOrderBody.latitude, longitude: placeOrderBody.longitude,
        contactPersonName: placeOrderBody.contactPersonName, contactPersonNumber: placeOrderBody.contactPersonNumber,
        streetNumber: placeOrderBody.streetNumber, house: placeOrderBody.house, floor: placeOrderBody.floor,
      );

      if(!isOfflinePay) {
        callback(true, message, orderID, zoneID, amount, maximumCodOrderAmount, fromCart, isCashOnDeliveryActive, placeOrderBody.contactPersonNumber!, userID);
      } else {
        showCustomSnackBar('order_placed_successfully'.tr, isError: false);
        Get.find<CartController>().getAllCarts();
        Get.offNamed(RouteHelper.getOfflinePaymentScreen(
          zoneId: zoneID, total: amount, orderId: orderID, contactNumber: placeOrderBody.contactPersonNumber??'',
          maxCodOrderAmount: maximumCodOrderAmount, fromCart: fromCart, isCodActive: isCashOnDeliveryActive, forParcel: false,
        ));
      }
      _orderAttachment = null;
      _rawAttachment = null;
      if (kDebugMode) {
        print('-------- Order placed successfully $orderID ----------');
      }
    } else {
      if(!isOfflinePay) {
        callback(false, response.statusText, '-1', zoneID, amount, maximumCodOrderAmount, fromCart, isCashOnDeliveryActive, placeOrderBody.contactPersonNumber, userID);
      } else {
        showCustomSnackBar(response.statusText);
      }
    }
    update();

    return orderID;
  }

  Future<void> placePrescriptionOrder({required int? storeId, required int? zoneID, required double? distance, required String address, required String longitude,
    required String latitude, required String note, required List<XFile> orderAttachment, required List<String> savedImages, required String dmTips,
    required String deliveryInstruction, required double orderAmount, required double maxCodAmount, required bool fromCart, required bool isCashOnDeliveryActive,
  }) async {
    List<MultipartBody> multiParts = [];
    List<String> resolvedSavedImages = [];
    for(int index = 0; index < orderAttachment.length; index++) {
      final bool fromMediaLibrary = index < _pickedPrescriptionFromMediaLibrary.length && _pickedPrescriptionFromMediaLibrary[index];
      final String savedImageName = index < _pickedPrescriptionSavedImageNames.length ? _pickedPrescriptionSavedImageNames[index]?.trim() ?? '' : '';
      if (fromMediaLibrary && savedImageName.isNotEmpty) {
        resolvedSavedImages.add(savedImageName);
        continue;
      }
      XFile file = orderAttachment[index];
      multiParts.add(MultipartBody('order_attachment[]', file));
    }
    _isLoading = true;
    update();
    Response response = await checkoutServiceInterface.placePrescriptionOrder(storeId, distance, address,longitude, latitude, note, multiParts, resolvedSavedImages, dmTips, deliveryInstruction);
    _isLoading = false;
    // Same as placeOrder: a creating endpoint may answer 201, and the envelope's
    // message/order_id no longer sit where a flat body put them.
    if (ApiClient.isSuccessCode(response.statusCode)) {
      String? message = _successMessageOf(response);
      String orderID = _orderIdOf(response);
      _saveRecentDeliveryAddress(orderType: 'delivery', address: address, latitude: latitude, longitude: longitude);
      callback(true, message, orderID, zoneID, orderAmount, maxCodAmount, fromCart, isCashOnDeliveryActive, null, '');
      _orderAttachment = null;
      _rawAttachment = null;
      if (kDebugMode) {
        print('-------- Order placed successfully $orderID ----------');
      }
    } else {
      callback(false, response.statusText, '-1', zoneID, orderAmount, maxCodAmount, fromCart, isCashOnDeliveryActive, null, '');
    }
    update();
  }

  void callback(
      bool isSuccess, String? message, String orderID, int? zoneID, double amount,
      double? maximumCodOrderAmount, bool fromCart, bool isCashOnDeliveryActive, String? contactNumber,
      String userID) async {

    if(isSuccess) {
      if(fromCart) {
        Get.find<CartController>().clearCartList();
      }
      setGuestAddress(null);
      if(!Get.find<OrderController>().showBottomSheet){
        Get.find<OrderController>().showRunningOrders(canUpdate: false);
      }
      if(isDmTipSave){
        saveSharedPrefDmTipIndex(PriceConverter.tipToSave(selectedTips));
      }
      stopLoader(canUpdate: false);
      HomeScreen.loadData(true);
      if(paymentMethodIndex == 2) {
        if(GetPlatform.isWeb) {
          // Get.back();
          await Get.find<AuthController>().saveGuestNumber(contactNumber ?? '');
          String? hostname = html.window.location.hostname;
          String protocol = html.window.location.protocol;
          String selectedUrl;
          selectedUrl = '${AppConstants.baseUrl}/payment-mobile?order_id=$orderID&&customer_id=${Get.find<ProfileController>().userInfoModel?.id ?? (userID.isNotEmpty ? userID : AuthHelper.getGuestId())}'
              '&payment_method=$digitalPaymentName&payment_platform=web&&callback=$protocol//$hostname${RouteHelper.orderSuccess}?id=$orderID&status=';

          html.window.open(selectedUrl,"_self");
        } else{
          Get.offNamed(RouteHelper.getPaymentRoute(
            orderID, Get.find<ProfileController>().userInfoModel?.id ?? (userID.isNotEmpty ? int.parse(userID) : 0), orderType, amount,
            isCashOnDeliveryActive, digitalPaymentName, guestId: userID.isNotEmpty ? userID : AuthHelper.getGuestId(),
            contactNumber: contactNumber, createAccount: _isCreateAccount,
          ));
        }
      } else {
        double total = ((amount / 100) * Get.find<SplashController>().configModel!.loyaltyPointItemPurchasePoint!);
        if(AuthHelper.isLoggedIn()) {
          Get.find<AuthController>().saveEarningPoint(total.toStringAsFixed(0));
        }
        if (ResponsiveHelper.isDesktop(Get.context) && AuthHelper.isLoggedIn()){
          Get.offNamed(RouteHelper.getInitialRoute());
          Future.delayed(const Duration(seconds: 2) , () => Get.dialog(Center(child: SizedBox(height: 350, width : 500, child: OrderSuccessfulDialog(orderID: orderID)))));
        } else {
          Get.offNamed(RouteHelper.getOrderSuccessRoute(orderID, contactNumber, createAccount: _isCreateAccount));
        }
      }
      clearPrevData();
      _monthlySubscribe = false;
      Get.find<CouponController>().removeCouponData(false);
      updateTips(
        PriceConverter.tipIndexFromSaved(getSharedPrefDmTipIndex()),
        notify: false,
      );
    }else {
      showCustomSnackBar(message);
    }
  }

  /// True when this failed payment is a rental trip rather than a mart order.
  ///
  /// `customer/order/payment-failed` marks a trip with `module_type: "rental"`
  /// (and `type: "rental"`), alongside `trip_id` / `trip_amount` in place of
  /// `order_id` / `order_amount`. `module_type` is the discriminator because it
  /// is present on both shapes — `food`, `grocery`, … for a storefront order.
  ///
  /// `orderType == 'trip'` is still accepted so a backend that labels it that
  /// way keeps working; it is not what the current API sends.
  static bool isTripPayment(PaymentModel? paymentData) =>
      paymentData?.moduleType == 'rental'
      || paymentData?.orderType == 'rental'
      || paymentData?.orderType == 'trip';

  Future<void> paymentAfterDigitalCancel(PaymentModel paymentData, bool fromHome) async {
    Get.find<SplashController>().togglePaymentIncompleteBottomSheet(false);
    // A trip is a different resource with its own payment endpoint. The mart
    // switch endpoints below are all keyed by *order* id, so handing them a trip
    // id would either 404 or act on an unrelated order.
    if(isTripPayment(paymentData)) {
      await _payFailedTrip(paymentData);
      clearPrevData();
      Get.find<CouponController>().removeCouponData(false);
      return;
    }
    if(paymentMethodIndex == 0) {
      bool isSuccess = await Get.find<OrderController>().switchToCOD(paymentData.orderID, guestId: paymentData.guestId);
      if(isSuccess) {
        _closePaymentSheet();
        _redirection(paymentData, fromHome);
      }
    } else if(paymentMethodIndex == 1) {
      debugPrint('------wallet selected');
      bool isSuccess = await Get.find<OrderController>().switchToWalletPayment(paymentData.orderID);
      if(isSuccess) {
        _closePaymentSheet();
        _redirection(paymentData, fromHome);
      }
    } else if(paymentMethodIndex == 2) {
      _closePaymentSheet();
      if(GetPlatform.isWeb) {
        String? hostname = html.window.location.hostname;
        String protocol = html.window.location.protocol;
        String selectedUrl;
        selectedUrl = '${AppConstants.baseUrl}/payment-mobile?order_id=${paymentData.orderID}&&customer_id=${paymentData.userId ?? AuthHelper.getGuestId()}'
            '&payment_method=$digitalPaymentName&payment_platform=web&&callback=$protocol//$hostname${RouteHelper.orderSuccess}?id=${paymentData.orderID}&status=';

        html.window.open(selectedUrl,"_self");
      } else{
        Get.offNamed(RouteHelper.getPaymentRoute(
          paymentData.orderID!, Get.find<ProfileController>().userInfoModel?.id ?? 0, paymentData.orderType, paymentData.orderAmount!,
          paymentData.isCashOnDeliveryActive, digitalPaymentName, guestId: AuthHelper.getGuestId(),
          contactNumber: paymentData.contactNumber,
        ));
      }
    } else if(paymentMethodIndex == 3) {
      debugPrint('------offline selected');
      _closePaymentSheet();
      Get.toNamed(RouteHelper.getOfflinePaymentScreen(
        zoneId: paymentData.zoneId, total: paymentData.orderAmount!, orderId: paymentData.orderID!, contactNumber: paymentData.contactNumber??'',
        maxCodOrderAmount: paymentData.maxCodOrderAmount, fromCart: false, isCodActive: paymentData.isCashOnDeliveryActive, forParcel: paymentData.orderType == 'parcel',
      ));
    }
    clearPrevData();
    Get.find<CouponController>().removeCouponData(false);
  }

  /// Retries a failed rental payment through `POST rental/user/trip/payment`.
  ///
  /// The shared sheet's method indices don't line up with rental's — it uses
  /// 0 wallet / 1 cash / 2 digital while this flow uses 0 COD / 1 wallet /
  /// 2 digital / 3 offline — so the mapping is by meaning, never by index.
  /// Offline has no rental equivalent (the endpoint accepts only cash, wallet,
  /// digital and partial), which is why the sheet hides it for a trip.
  Future<void> _payFailedTrip(PaymentModel paymentData) async {
    final int? tripId = int.tryParse(paymentData.orderID ?? '');
    if(tripId == null) return;

    final String method;
    String? gateway;
    switch(paymentMethodIndex) {
      case 0:
        method = 'cash_payment';
        break;
      case 1:
        method = 'wallet';
        break;
      case 2:
        method = 'digital_payment';
        gateway = digitalPaymentName;
        // The endpoint requires `payment_gateway` for a digital payment, and
        // `retryTripPayment` reads a non-null gateway as "open the webview" —
        // so a null one would both fail the request and, on any 2xx, be taken
        // as settled and refresh the trip as though it had been paid.
        if(gateway == null || gateway.isEmpty) {
          showCustomSnackBar('select_payment_method'.tr);
          return;
        }
        break;
      default:
        showCustomSnackBar('payment_method_not_available_for_trip'.tr);
        return;
    }

    final TaxiOrderController taxiOrderController = Get.find<TaxiOrderController>();
    // Captured before the call: the sheet is usually opened from this trip's own
    // details screen, and re-pushing that screen over itself would rebuild it
    // from scratch — losing scroll position and flashing a loader — when all it
    // needs is fresh data.
    final bool alreadyShowingThisTrip = taxiOrderController.tripDetailsModel?.id == tripId;

    final bool settled = await taxiOrderController.retryTripPayment(
      tripId: tripId, paymentMethod: method, gatewayName: gateway,
    );
    if(!settled) return;

    Get.find<SplashController>().savePaymentIncompleteSheetStatus(false);
    _closePaymentSheet();
    // The trip is also listed in the dashboard's running-orders sheet, which is
    // fed by a different endpoint and would otherwise keep showing it as unpaid.
    taxiOrderController.refreshRunningOrders();
    if(alreadyShowingThisTrip) {
      // Stay put and re-read the trip, so `Pay Now` disappears and the status
      // updates in place — the same shape as the mart order-details flow.
      taxiOrderController.getTripDetails(tripId, willUpdate: false);
    } else {
      // Reached from somewhere else (the payment-incomplete sheet, a
      // notification): trips have their own detail screen, and the mart
      // order-success route would look this id up as an order and find nothing.
      //
      // `Get.to`, not `Get.off`. By this point the sheet has been dismissed, so
      // the current route is the page the user was on — usually the dashboard —
      // and `Get.off` replaced it. Back from the trip screen then popped into an
      // empty stack, because `TaxiOrderDetailsScreen` pops plainly unless it was
      // told `fromCheckout`. Every other route into this screen uses `Get.to`.
      Get.to(() => TaxiOrderDetailsScreen(tripId: tripId));
    }
  }

  /// Dismisses the payment sheet (or, on desktop, the dialog wrapping it) that
  /// this retry was started from.
  ///
  /// Only the offline branch used to do this. The cash and wallet branches
  /// relied on [_redirection] popping for them, and that pop is gated on
  /// `Get.currentRoute` still reading as the order-details route — which it
  /// often doesn't by the time the switch returns, because `switchToCOD` shows a
  /// snackbar and GetX's observer rewrites `current` from `previous` when a
  /// non-`PageRoute` is popped above a non-`PageRoute`. The payment then
  /// succeeded with the sheet still sitting on top of the result.
  ///
  /// Closing it here makes the outcome independent of whatever the route stack
  /// happens to read as.
  void _closePaymentSheet() {
    // The route on top, not the flags — those stay true under a pushed page.
    if(Get.rawRoute is PopupRoute) {
      Get.back();
    }
  }

  void _redirection(PaymentModel paymentData, bool fromHome) {
    Get.find<SplashController>().savePaymentIncompleteSheetStatus(false);
    // Loyalty is optional; `loyalty_point_item_purchase_point` is absent when it
    // is switched off, and force-unwrapping it threw right here — after the
    // payment had already gone through.
    final double? purchasePoint = Get.find<SplashController>().configModel?.loyaltyPointItemPurchasePoint;
    if(AuthHelper.isLoggedIn() && purchasePoint != null && paymentData.orderAmount != null) {
      final double total = (paymentData.orderAmount! / 100) * purchasePoint;
      Get.find<AuthController>().saveEarningPoint(total.toStringAsFixed(0));
    }
    // The sheet is already closed by the caller. On order details there is
    // nowhere else to go — the order refreshes in place, which is what the
    // pre-4.2 flow did.
    if(Get.currentRoute.contains(RouteHelper.orderDetails)) {
      return;
    } else if (ResponsiveHelper.isDesktop(Get.context) && AuthHelper.isLoggedIn()){
      if(fromHome) {
        return;
      } else {
        Get.offNamed(RouteHelper.getInitialRoute());
        Future.delayed(const Duration(seconds: 2) , () => Get.dialog(Center(child: SizedBox(height: 350, width : 500, child: OrderSuccessfulDialog(orderID: paymentData.orderID)))));
      }
    } else {
      Get.offNamed(RouteHelper.getOrderSuccessRoute(paymentData.orderID!, paymentData.contactNumber, createAccount: _isCreateAccount));
    }
  }

  void toggleExpand() {
    _isExpand = !_isExpand;
    update();
  }

  void updateTimeSlot(int index) {
    _selectedTimeSlot = index;
    update();
  }

  void updateDateSlot(int index, int? interval) {
    _selectedDateSlot = index;
    if(_allTimeSlots != null) {
      validateSlot(_allTimeSlots!, index, interval);
    }
    update();
  }

  void validateSlot(List<TimeSlotModel> slots, int dateIndex, int? interval, {bool notify = true}) {
    _timeSlots = [];
    DateTime now = DateTime.now();
    if(Get.find<SplashController>().configModel!.moduleConfig!.module!.orderPlaceToScheduleInterval!) {
      now = now.add(Duration(minutes: interval!));
    }
    int day = 0;
    if(dateIndex == 0) {
      day = DateTime.now().weekday;
    }else {
      day = DateTime.now().add(const Duration(days: 1)).weekday;
    }
    if(day == 7) {
      day = 0;
    }
    for (var slot in slots) {
      if (day == slot.day && (dateIndex == 0 ? slot.endTime!.isAfter(now) : true)) {
        _timeSlots!.add(slot);
      }
    }
    if(notify) {
      update();
    }
  }

  void toggleCreateAccount({bool willUpdate = true}){
    _isCreateAccount = !_isCreateAccount;
    if(willUpdate) {
      update();
    }
  }

  Future<void> getOrderTax(PlaceOrderBodyModel placeOrderBody) async {
    final int requestId = ++_taxRequestId;
    Response response = await checkoutServiceInterface.getOrderTax(placeOrderBody);
    // A newer tax request was fired while this one was in flight; discard this stale response.
    if(requestId != _taxRequestId) return;
    if(response.statusCode == 200) {
      _isFirstTime = false;
      _orderTax = double.tryParse(response.body['tax_amount'].toString()) ?? 0.0;
      _taxIncluded = response.body['tax_included'];
    } else if(response.statusCode == 403 && response.body is Map && response.body['errors'] is List && response.body['errors'].isNotEmpty) {
      final error = response.body['errors'][0];
      if(error is Map && error['code'] == 'not_found') {
        _isFirstTime = false;
        showCustomSnackBar('product_currently_unavailable'.tr);
      } else {
        _isFirstTime = false;
        ApiChecker.checkApi(response);
      }
    } else {
      _isFirstTime = false;
      ApiChecker.checkApi(response);
    }
    update();
  }

  /// Error codes worth interrupting the customer for. Everything else — a
  /// dropped connection, a 500 — leaves the previous quote in place and lets the
  /// screen fall back to its own arithmetic, because this call refires on every
  /// coupon, tip and address change and must not become a snackbar machine.
  static const List<String> _actionableSummaryCodes = <String>[
    'coupon', 'area_id', 'zip_code_id', 'order_time', 'schedule_at', 'store',
    // Only a parcel quote posts receiver details, so this one cannot reach a
    // store checkout — and it is the one refusal that stops the order outright.
    'receiverZone',
  ];

  /// Fetches the whole checkout quote — tax, delivery, surge, pro and cashback —
  /// in one call.
  ///
  /// Skips the request when [body] matches the last one fetched, unless [force]
  /// is set, so a rebuild does not requote an unchanged basket.
  Future<void> getCheckoutSummary(CheckoutSummaryBodyModel body, {bool notify = true, bool force = false}) async {
    final String signature = body.signature;
    if(!force && signature == _lastSummarySignature) return;
    _lastSummarySignature = signature;
    _lastSummaryBody = body;

    final int requestId = ++_summaryRequestId;
    _summaryLoading = true;
    if(notify) update();

    final Response response = await checkoutServiceInterface.getCheckoutSummary(body);
    // A newer quote was fired while this one was in flight; discard this one.
    if(requestId != _summaryRequestId) return;
    _summaryLoading = false;

    if(response.statusCode == 200 && response.body is Map) {
      _checkoutSummary = CheckoutSummaryModel.fromJson(Map<String, dynamic>.from(response.body as Map));
      _summaryError = null;
      _isFirstTime = false;
      // Keep the legacy fields in step so any widget still reading them, and the
      // tax posted with the order, agree with the quote on screen.
      final CheckoutSummaryTax? tax = _checkoutSummary!.tax;
      if(tax != null) {
        _orderTax = tax.taxAmount ?? 0.0;
        _taxIncluded = tax.taxIncluded;
      }
      // Assigned unconditionally: `checkout-summary` is the only source of the
      // surge, so a quote that comes back without one has to clear the previous
      // zone's rather than leave it standing.
      _surgePrice = _checkoutSummary!.surge;
    } else {
      // Allow a retry for the same basket — this signature never produced a quote.
      _lastSummarySignature = null;
      final String? code = _summaryErrorCode(response);
      // Only a named code is the server refusing this basket. A dropped
      // connection or a 500 carries none, and must not be read out as a reason
      // the order cannot be placed.
      _summaryError = code != null ? response.statusText : null;
      if(code != null && _actionableSummaryCodes.contains(code)) {
        showCustomSnackBar(response.statusText ?? 'something_went_wrong'.tr);
      }
    }
    update();
  }

  /// The first error `code` in the envelope, or null for any other failure shape.
  String? _summaryErrorCode(Response response) {
    final dynamic body = response.body;
    if(body is! Map) return null;
    final dynamic errors = body['errors'];
    if(errors is List && errors.isNotEmpty) {
      final dynamic first = errors.first;
      if(first is Map && first['code'] != null) return first['code'].toString();
    } else if(errors is Map && errors.isNotEmpty) {
      return errors.keys.first.toString();
    }
    return null;
  }

  /// Loads what the customer must pick from for this `(zone, module)`.
  ///
  /// `coverage` comes back empty for `distance_wise` and `fixed_amount` — that
  /// is the answer, not a missing one, and the picker simply is not drawn.
  /// The customer's pick survives a reload and is re-validated against the new
  /// list, rather than being cleared up front. `initCheckoutData` fires this
  /// un-awaited, so clearing eagerly silently discarded a pick the customer had
  /// already made — and the quote would then be priced at the rule's minimum.
  Future<void> getCoverageList({required int zoneId, int? moduleId, bool notify = true}) async {
    final int? previousAreaId = _selectedAreaId;
    final int? previousZipCodeId = _selectedZipCodeId;

    _coverageList = null;
    if(notify) update();

    _coverageList = await checkoutServiceInterface.getCoverageList(zoneId: zoneId, moduleId: moduleId);

    // Keep the pick only if the new list still offers it — a different zone or
    // module means the old id refers to somewhere else entirely.
    final List<CoverageOption> options = _coverageList?.coverage ?? const <CoverageOption>[];
    final bool isZip = _coverageList?.isZipCode ?? false;
    final int? previousId = isZip ? previousZipCodeId : previousAreaId;
    final bool stillOffered = previousId != null
        && options.any((CoverageOption option) => option.id == previousId);

    _selectedAreaId = (stillOffered && !isZip) ? previousId : null;
    _selectedZipCodeId = (stillOffered && isZip) ? previousId : null;
    // The pick feeds the quote, so a dropped pick must let the next quote refire.
    if(!stillOffered) _lastSummarySignature = null;

    update();
  }

  /// Records the customer's coverage pick and requotes with it, because the fee
  /// moves with the pick and the figure on screen has to move with it too.
  Future<void> setCoverageSelection(int? optionId) async {
    if(_coverageList?.isZipCode ?? false) {
      _selectedZipCodeId = optionId;
      _selectedAreaId = null;
    } else {
      _selectedAreaId = optionId;
      _selectedZipCodeId = null;
    }
    _lastSummarySignature = null;
    update();

    // Nothing has been quoted yet (the screen fires the first one itself), so
    // there is no basket to requote — the pick will be carried by that first call.
    final CheckoutSummaryBodyModel? last = _lastSummaryBody;
    if(last == null) return;
    await getCheckoutSummary(
      last.copyWithCoverage(areaId: _selectedAreaId, zipCodeId: _selectedZipCodeId),
      force: true,
    );
  }

  /// Clears the quote so a new store or basket cannot render the previous one.
  void resetCheckoutSummary() {
    _checkoutSummary = null;
    _summaryError = null;
    // The surge rides on the quote, so it is only as valid as the quote is.
    _surgePrice = null;
    _lastSummarySignature = null;
    _lastSummaryBody = null;
    _summaryLoading = false;
    _summaryRequestId++;
  }

  Future<void> insertAddresses(AddressModel? addressModel, {bool notify = false})async {
    _address = addressModel;

    String phone = '';
    String name = '';

    if(AuthHelper.isLoggedIn()) {
      if(Get.find<ProfileController>().userInfoModel == null) {
        await Get.find<ProfileController>().getUserInfo();
      }
      phone = Get.find<ProfileController>().userInfoModel!.phone ?? '';
      name ='${Get.find<ProfileController>().userInfoModel!.fName ?? ''} ${Get.find<ProfileController>().userInfoModel!.lName ?? ''}';
    }

    try {

      String processPhone = (addressModel != null && addressModel.contactPersonNumber != null && addressModel.contactPersonNumber != 'null') ? addressModel.contactPersonNumber??'' : phone;

      PhoneNumber phoneNumber = PhoneNumber.parse(processPhone);
      countryDialCode = '+${phoneNumber.countryCode}';
      contactPersonNumberController.text = phoneNumber.international.substring(
        countryDialCode!.length,
      );
    } catch (e) {
      debugPrint('number can\'t parse : $e');
    }
    contactPersonAddressController.text = _address?.address ?? '';
    contactPersonNameController.text = _address?.contactPersonName ?? name;
    streetNumberController.text = _address?.streetNumber ?? '';
    houseController.text = _address?.house ?? '';
    floorController.text = _address?.floor ?? '';
    // A new address can land in a different zone, which changes (or removes) the
    // saver delivery options. Silent here — the `notify` below owns the repaint.
    refreshSaverDeliveryData(notify: false);
    if (notify) update();
  }
}

// SUMMARY
// Checkout state for store orders and parcels alike. Holds the address, order type,
// schedule, coupon, tips, coverage pick and payment choice, fetches the server quote —
// delivery, tax, surge, Pro and cashback — along with the reason it was refused, and
// places the order.
