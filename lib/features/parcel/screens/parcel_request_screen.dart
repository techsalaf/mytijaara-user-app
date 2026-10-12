import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_map_custom_windows/google_map_custom_windows.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:sixam_mart/common/controllers/theme_controller.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/custom_tool_tip_widget.dart';
import 'package:sixam_mart/common/widgets/not_logged_in_screen.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/features/checkout/widgets/condition_check_box.dart';
import 'package:sixam_mart/features/checkout/widgets/guest_create_account.dart';
import 'package:sixam_mart/features/parcel/controllers/parcel_controller.dart';
import 'package:sixam_mart/features/parcel/domain/models/parcel_category_model.dart';
import 'package:sixam_mart/helper/delivery_fee_tooltip.dart';
import 'package:sixam_mart/features/parcel/widgets/parcel_coverage_bottom_sheet.dart';
import 'package:sixam_mart/features/parcel/widgets/parcel_quote_error_widget.dart';
import 'package:sixam_mart/features/parcel/widgets/parcel_info_bottom_sheet.dart';
import 'package:sixam_mart/features/parcel/widgets/parcel_payment_method_bottom_sheet.dart';
import 'package:sixam_mart/features/parcel/widgets/parcel_payment_method_picker.dart';
import 'package:sixam_mart/features/pro/controllers/pro_controller.dart';
import 'package:sixam_mart/features/pro/domain/models/pro_active_offer_model.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/custom_validator.dart';
import 'package:sixam_mart/helper/distance_converter.dart';
import 'package:sixam_mart/helper/marker_helper.dart';
import 'package:sixam_mart/helper/module_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/zone_module_helper.dart';
import 'package:sixam_mart/helper/zone_payment_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class ParcelRequestScreen extends StatefulWidget {
  final ParcelCategoryModel parcelCategory;
  final AddressModel pickedUpAddress;
  final AddressModel destinationAddress;
  const ParcelRequestScreen({super.key,
    required this.parcelCategory, required this.pickedUpAddress, required this.destinationAddress,
  });

  @override
  State<ParcelRequestScreen> createState() => _ParcelRequestScreenState();
}

class _ParcelRequestScreenState extends State<ParcelRequestScreen> {
  final TextEditingController _guestPasswordController = TextEditingController();
  final TextEditingController _guestConfirmPasswordController = TextEditingController();
  final FocusNode _guestPasswordNode = FocusNode();
  final FocusNode _guestConfirmPasswordNode = FocusNode();
  bool _isLoggedIn = AuthHelper.isLoggedIn();
  bool _isCashOnDeliveryActive = false;
  bool _isDigitalPaymentActive = false;

  final DraggableScrollableController _sheetController = DraggableScrollableController();
  final GlobalKey _peekKey = GlobalKey();
  final GlobalKey _footerKey = GlobalKey();
  final GlobalKey _contentKey = GlobalKey();
  double _peekFraction = 0.4;
  double _footerHeight = 120;
  double _maxFraction = _maxSheetFraction;

  static const double _maxSheetFraction = 1.0;
  static const double _maxSlack = 0.02;
  GoogleMapController? _mapController;
  final Set<Marker> _markers = HashSet<Marker>();
  GoogleMapCustomWindowController _customInfoWindowController = GoogleMapCustomWindowController();

  final TextEditingController _senderNameController = TextEditingController();
  final TextEditingController _senderPhoneController = TextEditingController();
  final TextEditingController _senderStreetController = TextEditingController();
  final TextEditingController _senderHouseController = TextEditingController();
  final TextEditingController _senderFloorController = TextEditingController();
  final TextEditingController _senderEmailController = TextEditingController();
  final TextEditingController _senderAddressController = TextEditingController();
  final TextEditingController _receiverNameController = TextEditingController();
  final TextEditingController _receiverPhoneController = TextEditingController();
  final TextEditingController _receiverStreetController = TextEditingController();
  final TextEditingController _receiverHouseController = TextEditingController();
  final TextEditingController _receiverFloorController = TextEditingController();
  final TextEditingController _receiverEmailController = TextEditingController();
  final TextEditingController _receiverAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initCall();
    _primeEditControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measurePeek());
  }

  Future<void> _quoteParcel() async {
    final ParcelController parcelController = Get.find<ParcelController>();
    _loadTiers();
    _loadCoverage();
    await parcelController.getDistance(widget.pickedUpAddress, widget.destinationAddress);
    if (!mounted) return;
    await parcelController.fetchParcelSummary(widget.parcelCategory, force: true);
  }

  void _measurePeek() {
    if (!mounted) return;
    final RenderBox? peekBox = _peekKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? footerBox = _footerKey.currentContext?.findRenderObject() as RenderBox?;
    final double screenHeight = MediaQuery.of(context).size.height;
    if (peekBox == null || !peekBox.hasSize || screenHeight <= 0) return;

    final double newFooterHeight = (footerBox != null && footerBox.hasSize) ? footerBox.size.height : _footerHeight;
    final double newFraction = ((peekBox.size.height + newFooterHeight + 36) / screenHeight).clamp(0.22, 0.9);

    final RenderBox? contentBox = _contentKey.currentContext?.findRenderObject() as RenderBox?;
    final double contentHeight = (contentBox != null && contentBox.hasSize)
        ? contentBox.size.height + newFooterHeight + Dimensions.paddingSizeDefault
        : screenHeight;
    final double newMax = (contentHeight / screenHeight + _maxSlack).clamp(newFraction, _maxSheetFraction);

    final bool atPeek = !_sheetController.isAttached || (_sheetController.size - _peekFraction).abs() < 0.02;

    if ((newFraction - _peekFraction).abs() < 0.005
        && (newFooterHeight - _footerHeight).abs() < 1
        && (newMax - _maxFraction).abs() < 0.005) {
      return;
    }

    setState(() {
      _peekFraction = newFraction;
      _footerHeight = newFooterHeight;
      _maxFraction = newMax;
    });

    if (_sheetController.isAttached && atPeek) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _sheetController.isAttached) _sheetController.jumpTo(newFraction);
      });
    }
  }

  void initCall(){

    Get.find<CheckoutController>().resetOrderTax();
    Get.find<CheckoutController>().resetCheckoutSummary();
    if (Get.find<ParcelController>().parcelCategoryList == null) {
      Get.find<ParcelController>().getParcelCategoryList();
    }

    _quoteParcel();
    Get.find<ParcelController>().getOfflineMethodList();
    Get.find<ParcelController>().startLoader(false, canUpdate: false);
      _resolvePaymentFlags();
      if (Get.find<ProfileController>().userInfoModel == null && _isLoggedIn) {
        Get.find<ProfileController>().getUserInfo();
      }
      if (_isLoggedIn) {
        Get.find<ProController>().getProActiveOffer(
          moduleType: ModuleHelper.getModule()?.moduleType ?? ModuleHelper.getCacheModule()?.moduleType,
        );
      }
  }

  void _resolvePaymentFlags() {
    _isCashOnDeliveryActive = ZonePaymentHelper.isCashOnDeliveryActive(_currentPickup());
    _isDigitalPaymentActive = ZonePaymentHelper.isDigitalPaymentActive(_currentPickup());
  }

  void _primeEditControllers() {
    final pickup = _currentPickup();
    final destination = _currentDestination();
    _senderNameController.text = pickup.contactPersonName ?? '';
    _senderStreetController.text = pickup.streetNumber ?? '';
    _senderHouseController.text = pickup.house ?? '';
    _senderFloorController.text = pickup.floor ?? '';
    _senderEmailController.text = pickup.email ?? '';
    _senderAddressController.text = pickup.address ?? '';
    final senderSplit = _splitPhoneNumber(pickup.contactPersonNumber ?? '');
    _senderPhoneController.text = senderSplit.number;
    if (senderSplit.code.isNotEmpty) {
      Get.find<ParcelController>().setCountryCode(senderSplit.code, true);
    }

    _receiverNameController.text = destination.contactPersonName ?? '';
    _receiverStreetController.text = destination.streetNumber ?? '';
    _receiverHouseController.text = destination.house ?? '';
    _receiverFloorController.text = destination.floor ?? '';
    _receiverEmailController.text = destination.email ?? '';
    _receiverAddressController.text = destination.address ?? '';
    final receiverSplit = _splitPhoneNumber(destination.contactPersonNumber ?? '');
    _receiverPhoneController.text = receiverSplit.number;
    if (receiverSplit.code.isNotEmpty) {
      Get.find<ParcelController>().setCountryCode(receiverSplit.code, false);
    }
  }

  _PhoneParts _splitPhoneNumber(String number) {
    try {
      final PhoneNumber phoneNumber = PhoneNumber.parse(number);
      final code = '+${phoneNumber.countryCode}';
      final pNumber = phoneNumber.international.substring(code.length);
      return _PhoneParts(code: code, number: pNumber);
    } catch (_) {
      return _PhoneParts(code: '', number: number);
    }
  }

  AddressModel _currentPickup() => Get.find<ParcelController>().pickupAddress ?? widget.pickedUpAddress;
  AddressModel _currentDestination() => Get.find<ParcelController>().destinationAddress ?? widget.destinationAddress;

  @override
  void dispose() {
    _sheetController.dispose();
    _mapController?.dispose();
    _customInfoWindowController.dispose();
    _guestPasswordController.dispose();
    _guestConfirmPasswordController.dispose();
    _guestPasswordNode.dispose();
    _guestConfirmPasswordNode.dispose();
    _senderNameController.dispose();
    _senderPhoneController.dispose();
    _senderStreetController.dispose();
    _senderHouseController.dispose();
    _senderFloorController.dispose();
    _senderEmailController.dispose();
    _senderAddressController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _receiverStreetController.dispose();
    _receiverHouseController.dispose();
    _receiverFloorController.dispose();
    _receiverEmailController.dispose();
    _receiverAddressController.dispose();
    super.dispose();
  }

  Future<void> _setupMap() async {
    if (_mapController == null) return;
    final pickup = _latLngOf(_currentPickup());
    final dest = _latLngOf(_currentDestination());
    if (pickup == null || dest == null) return;

    _customInfoWindowController.googleMapController = _mapController;

    BitmapDescriptor pickupIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    BitmapDescriptor destIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    try {
      pickupIcon = await MarkerHelper.convertAssetToBitmapDescriptor(
        imagePath: Images.riderPickup, height: 40,
      );
      destIcon = await MarkerHelper.convertAssetToBitmapDescriptor(
        imagePath: Images.riderDestination, height: 40,
      );
    } catch (_) {}
    if (!mounted) return;

    _markers
      ..clear()
      ..add(Marker(
        markerId: const MarkerId('pickup'),
        position: pickup,
        anchor: const Offset(0.4, 0.7),
        icon: pickupIcon,
      ))
      ..add(Marker(
        markerId: const MarkerId('destination'),
        position: dest,
        anchor: const Offset(0.4, 0.8),
        icon: destIcon,
      ));

    if (_customInfoWindowController.addInfoWindow == null) {
      _customInfoWindowController = GoogleMapCustomWindowController()
        ..googleMapController = _mapController;
    }
    try {
      _customInfoWindowController.addInfoWindow!(
        [const _ParcelMarkerLabel(title: 'pickup'), const _ParcelMarkerLabel(title: 'destination')],
        [pickup, dest],
      );
    } catch (_) {}

    final bounds = _boundsOf(pickup, dest);
    await Future.delayed(const Duration(milliseconds: 200));
    await _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    if (mounted) setState(() {});
  }

  LatLng? _latLngOf(AddressModel a) {
    final lat = double.tryParse(a.latitude ?? '');
    final lng = double.tryParse(a.longitude ?? '');
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  LatLngBounds _boundsOf(LatLng a, LatLng b) {
    return LatLngBounds(
      southwest: LatLng(
        a.latitude < b.latitude ? a.latitude : b.latitude,
        a.longitude < b.longitude ? a.longitude : b.longitude,
      ),
      northeast: LatLng(
        a.latitude > b.latitude ? a.latitude : b.latitude,
        a.longitude > b.longitude ? a.longitude : b.longitude,
      ),
    );
  }

  Future<bool> _validateAndPersistSender({bool showSnackbarOnFail = true}) async {
    final parcelController = Get.find<ParcelController>();
    final String fullNumber = '${parcelController.senderCountryCode ?? ''}${_senderPhoneController.text.trim()}';
    final PhoneValid phoneValid = await CustomValidator.isPhoneValid(fullNumber);

    if (parcelController.pickupAddress == null) {
      if (showSnackbarOnFail) showCustomSnackBar('select_pickup_address'.tr);
      return false;
    } else if (_senderNameController.text.trim().isEmpty) {
      if (showSnackbarOnFail) showCustomSnackBar('enter_sender_name'.tr);
      return false;
    } else if (_senderPhoneController.text.trim().isEmpty) {
      if (showSnackbarOnFail) showCustomSnackBar('enter_sender_phone_number'.tr);
      return false;
    } else if (!phoneValid.isValid) {
      if (showSnackbarOnFail) showCustomSnackBar('invalid_phone_number'.tr);
      return false;
    } else if (AuthHelper.isGuestLoggedIn() && _senderEmailController.text.trim().isEmpty) {
      if (showSnackbarOnFail) showCustomSnackBar('please_enter_sender_email'.tr);
      return false;
    } else if (AuthHelper.isGuestLoggedIn() && !CustomValidator.isEmailValid(_senderEmailController.text.trim())) {
      if (showSnackbarOnFail) showCustomSnackBar('enter_valid_email_address'.tr);
      return false;
    }

    final existing = parcelController.pickupAddress!;
    final AddressModel updated = AddressModel(
      address: existing.address,
      additionalAddress: existing.additionalAddress,
      addressType: existing.addressType,
      contactPersonName: _senderNameController.text.trim(),
      contactPersonNumber: phoneValid.phone,
      latitude: existing.latitude,
      longitude: existing.longitude,
      method: existing.method,
      zoneId: existing.zoneId,
      id: existing.id,
      zoneIds: existing.zoneIds,
      streetNumber: _senderStreetController.text.trim(),
      house: _senderHouseController.text.trim(),
      floor: _senderFloorController.text.trim(),
      email: _senderEmailController.text.trim(),
      zoneData: existing.zoneData,
    );
    parcelController.setPickupAddress(updated, true);
    return true;
  }

  Future<bool> _validateAndPersistReceiver({bool showSnackbarOnFail = true}) async {
    final parcelController = Get.find<ParcelController>();
    final String fullNumber = '${parcelController.receiverCountryCode ?? ''}${_receiverPhoneController.text.trim()}';
    final PhoneValid phoneValid = await CustomValidator.isPhoneValid(fullNumber);

    if (parcelController.destinationAddress == null) {
      if (showSnackbarOnFail) showCustomSnackBar('select_destination_address'.tr);
      return false;
    } else if (_receiverNameController.text.trim().isEmpty) {
      if (showSnackbarOnFail) showCustomSnackBar('enter_receiver_name'.tr);
      return false;
    } else if (_receiverPhoneController.text.trim().isEmpty) {
      if (showSnackbarOnFail) showCustomSnackBar('enter_receiver_phone_number'.tr);
      return false;
    } else if (!phoneValid.isValid) {
      if (showSnackbarOnFail) showCustomSnackBar('invalid_phone_number'.tr);
      return false;
    } else if (AuthHelper.isGuestLoggedIn() && _receiverEmailController.text.trim().isEmpty) {
      if (showSnackbarOnFail) showCustomSnackBar('please_enter_sender_email'.tr);
      return false;
    } else if (AuthHelper.isGuestLoggedIn() && !CustomValidator.isEmailValid(_receiverEmailController.text.trim())) {
      if (showSnackbarOnFail) showCustomSnackBar('enter_valid_email_address'.tr);
      return false;
    }

    final existing = parcelController.destinationAddress!;
    final AddressModel updated = AddressModel(
      address: existing.address,
      additionalAddress: existing.additionalAddress,
      addressType: existing.addressType,
      contactPersonName: _receiverNameController.text.trim(),
      contactPersonNumber: phoneValid.phone,
      latitude: existing.latitude,
      longitude: existing.longitude,
      method: existing.method,
      zoneId: existing.zoneId,
      zoneIds: existing.zoneIds,
      id: existing.id,
      streetNumber: _receiverStreetController.text.trim(),
      house: _receiverHouseController.text.trim(),
      floor: _receiverFloorController.text.trim(),
      email: _receiverEmailController.text.trim(),
      zoneData: existing.zoneData,
    );
    parcelController.setDestinationAddress(updated);
    return true;
  }

  Future<void> _onEditDone() async {
    final parcelController = Get.find<ParcelController>();
    final bool locationComplete = parcelController.pickupAddress != null
        && parcelController.destinationAddress != null;

    if (locationComplete) {
      Get.find<CheckoutController>().updateFirstTime();
      Get.find<CheckoutController>().resetOrderTax();
      Get.find<CheckoutController>().resetCheckoutSummary();
      await Future.wait(<Future<void>>[_loadTiers(), _loadCoverage()]);
      await _loadTiers();
      if (!mounted) return;
      await parcelController.getDistance(parcelController.pickupAddress!, parcelController.destinationAddress!);
      if (!mounted) return;
      await parcelController.fetchParcelSummary(widget.parcelCategory, force: true);
    }

    await _setupMap();
    if (mounted) {
      _resolvePaymentFlags();
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) => _measurePeek());
    }
  }

  Future<void> _loadTiers() async {
    final parcelController = Get.find<ParcelController>();
    final int? moduleId = Get.find<SplashController>().module?.id;
    final int? zoneId = ZoneModuleHelper.resolveZoneId(_currentPickup(), moduleId: moduleId);
    if (zoneId == null) return;
    await parcelController.loadParcelTiers(zoneId: zoneId, moduleId: moduleId);
  }

  Future<void> _loadCoverage() async {
    final parcelController = Get.find<ParcelController>();
    final int? moduleId = Get.find<SplashController>().module?.id;
    final int? zoneId = ZoneModuleHelper.resolveZoneId(_currentPickup(), moduleId: moduleId);
    if (zoneId == null) return;
    await parcelController.loadParcelCoverage(zoneId: zoneId, moduleId: moduleId);
  }

  void _openCoverageSheet() {
    ParcelCoverageBottomSheet.open(
      context,
      onConfirm: () async {
        if (!mounted) return;
        setState(() {});
        await Get.find<ParcelController>().fetchParcelSummary(widget.parcelCategory, force: true);
      },
    );
  }

  void _openEditSender() {
    ParcelInfoBottomSheet.open(
      context,
      isSender: true,
      nameController: _senderNameController,
      phoneController: _senderPhoneController,
      streetController: _senderStreetController,
      houseController: _senderHouseController,
      floorController: _senderFloorController,
      guestEmailController: _senderEmailController,
      addressController: _senderAddressController,
      onConfirm: () async {
        final ok = await _validateAndPersistSender();
        if (ok) await _onEditDone();
        return ok;
      },
    );
  }

  void _openEditReceiver() {
    ParcelInfoBottomSheet.open(
      context,
      isSender: false,
      nameController: _receiverNameController,
      phoneController: _receiverPhoneController,
      streetController: _receiverStreetController,
      houseController: _receiverHouseController,
      floorController: _receiverFloorController,
      guestEmailController: _receiverEmailController,
      addressController: _receiverAddressController,
      onConfirm: () async {
        final ok = await _validateAndPersistReceiver();
        if (ok) await _onEditDone();
        return ok;
      },
    );
  }

  void _openPaymentSheet(ParcelController parcelController, double total) {
    final bool isGuest = AuthHelper.isGuestLoggedIn();
    final bool walletActive = (Get.find<SplashController>().configModel!.customerWalletStatus == 1) && parcelController.payerIndex == 0 && !isGuest;
    final bool digitalActive = _isDigitalPaymentActive && parcelController.payerIndex == 0;
    final bool offlineActive = parcelController.offlineMethodList != null && parcelController.payerIndex == 0 && (Get.find<SplashController>().configModel?.offlinePaymentStatus ?? false);
    if (!(_isCashOnDeliveryActive || digitalActive || walletActive || offlineActive)) {
      showCustomSnackBar('no_payment_method_found'.tr);
      return;
    }
    final sheet = ParcelPaymentMethodBottomSheet(
      isCashOnDeliveryActive: _isCashOnDeliveryActive,
      isDigitalPaymentActive: digitalActive,
      totalPrice: total,
      isOfflinePaymentActive: offlineActive,
      canPayWallet: walletActive,
    );
    if (ResponsiveHelper.isDesktop(context)) {
      Get.dialog(Dialog(backgroundColor: Colors.transparent, child: sheet));
    } else {
      Get.bottomSheet(sheet, backgroundColor: Colors.transparent, isScrollControlled: true);
    }
  }

  void _handleSendRequest({
    required ParcelController parcelController, required double charge, required bool isGuestLoggedIn,
  }) {
    final pickup = _currentPickup();
    final destination = _currentDestination();
    final bool isInstructionSelected = parcelController.selectedIndexNote != -1;
    final bool isCustomNote = parcelController.customNote!.isNotEmpty;

    if(parcelController.isDeliveryChargePending) {
      showCustomSnackBar('delivery_fee_not_set_yet'.tr);
    }else if(parcelController.isTierSelectionMissing) {
      showCustomSnackBar(parcelController.needsWeightSelection && parcelController.selectedWeightId == null
          ? 'please_select_item_weight'.tr : 'please_select_item_dimension'.tr);
    }else if(parcelController.isCoverageSelectionMissing) {
      showCustomSnackBar(parcelController.isZipCodeWiseDelivery
          ? 'please_select_zip_code'.tr : 'please_select_area'.tr);
      _openCoverageSheet();
    }else if(parcelController.tips < 0) {
      showCustomSnackBar('tips_can_not_be_negative'.tr);
    }else if(parcelController.paymentIndex == -1) {
      showCustomSnackBar('please_select_payment_method_first'.tr);
    }else if(isGuestLoggedIn && Get.find<CheckoutController>().isCreateAccount && _guestPasswordController.text.isEmpty) {
      showCustomSnackBar('enter_password'.tr);
    }else if(isGuestLoggedIn && Get.find<CheckoutController>().isCreateAccount && _guestConfirmPasswordController.text.isEmpty) {
      showCustomSnackBar('enter_confirm_password'.tr);
    }else if(isGuestLoggedIn && Get.find<CheckoutController>().isCreateAccount && (_guestPasswordController.text != _guestConfirmPasswordController.text)) {
      showCustomSnackBar('confirm_password_does_not_matched'.tr);
    }else {

      PlaceOrderBodyModel placeOrderBody = PlaceOrderBodyModel(
        cart: [], couponDiscountAmount: null, distance: parcelController.distance, scheduleAt: null,
        orderAmount: charge, orderNote: '', orderType: 'parcel', receiverDetails: destination,
        paymentMethod: parcelController.paymentIndex == 0 ? 'cash_on_delivery'
            : parcelController.paymentIndex == 1 ? 'wallet'
            : parcelController.paymentIndex == 2 ? 'digital_payment' : 'offline_payment',
        couponCode: null, storeId: null, address: pickup.address, latitude: pickup.latitude,
        longitude: pickup.longitude, senderZoneId: pickup.zoneId,
        addressType: pickup.addressType,
        contactPersonName: pickup.contactPersonName ?? '',
        contactPersonNumber: pickup.contactPersonNumber ?? '',
        streetNumber: pickup.streetNumber ?? '', house: pickup.house ?? '',
        floor: pickup.floor ?? '',
        discountAmount: 0, taxAmount: 0, parcelCategoryId: widget.parcelCategory.id.toString(),
        weightId: parcelController.selectedWeightId, dimensionId: parcelController.selectedDimensionId,
        areaId: parcelController.selectedAreaId, zipCodeId: parcelController.selectedZipCodeId,
        deliveryDuration: parcelController.deliveryDurationInSeconds,
        chargePayer: parcelController.payerTypes[parcelController.payerIndex], dmTips: parcelController.tips.toString(),
        cutlery: 0, unavailableItemNote: '',
        deliveryInstruction: (isInstructionSelected ? '${parcelController.parcelInstructionList![parcelController.selectedIndexNote!].instruction}' : '') + (isInstructionSelected ? (isCustomNote ? " (${parcelController.customNote})" : '') : (isCustomNote ? parcelController.customNote ?? '' : '')),
        partialPayment: 0, guestId: AuthHelper.isGuestLoggedIn() ? int.parse(AuthHelper.getGuestId()) : 0, isBuyNow: 0,
        guestEmail: pickup.email ?? '', extraPackagingAmount: null,
        createNewUser: Get.find<CheckoutController>().isCreateAccount ? 1 : 0, password: _guestPasswordController.text,
      );

      parcelController.startLoader(true);
      parcelController.placeOrder(placeOrderBody, pickup.zoneId, charge, 0, false, false, forParcel: true, isOfflinePay: parcelController.paymentIndex == 3);
    }
  }

  @override
  Widget build(BuildContext context) {
    _isLoggedIn = AuthHelper.isLoggedIn();
    final bool isGuestLoggedIn = AuthHelper.isGuestLoggedIn();
    final bool guestCheckoutPermission = isGuestLoggedIn && Get.find<SplashController>().configModel!.guestCheckoutStatus!;

    return Scaffold(
      body: GetBuilder<CheckoutController>(builder: (checkoutController) {
        return SafeArea(
          child: (guestCheckoutPermission || _isLoggedIn) ? GetBuilder<ParcelController>(builder: (parcelController) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _measurePeek());
            double charge = -1;
            double total = 0;
            double dmTips = 0;
            double proDiscount = 0;
            double proDeliveryDiscount = 0;
            double tax = 0;
            bool taxIncluded = false;
            double additionalCharge = Get.find<SplashController>().configModel!.additionalChargeStatus! ? Get.find<SplashController>().configModel!.additionCharge! : 0;

            final ProActiveBenefit? proBenefit = Get.find<ProController>().activeOfferModel?.benefit;
            final bool isPro = _isLoggedIn && (Get.find<ProfileController>().userInfoModel?.proStatus ?? false);

            if(checkoutController.checkoutSummary?.delivery != null
                || (parcelController.distance != -1 && parcelController.extraCharge != null)) {
              final ParcelBill bill = parcelController.calculateBill(widget.parcelCategory);
              charge = bill.charge;
              dmTips = bill.dmTips;
              additionalCharge = bill.additionalCharge;
              proDiscount = bill.proDiscount;
              proDeliveryDiscount = bill.proDeliveryDiscount;
              tax = bill.tax;
              taxIncluded = bill.taxIncluded;
              total = bill.total;
            }

            return SizedBox.expand(child: Stack(children: [
              Positioned.fill(
                child: GoogleMap(
                  mapType: MapType.normal,
                  style: Get.isDarkMode ? Get.find<ThemeController>().darkMap : Get.find<ThemeController>().lightMap,
                  initialCameraPosition: CameraPosition(
                    target: _latLngOf(_currentPickup()) ?? const LatLng(0, 0),
                    zoom: 14,
                  ),
                  markers: _markers,
                  zoomControlsEnabled: false,
                  compassEnabled: false,
                  myLocationButtonEnabled: false,
                  onCameraMove: (_) {
                    if (_customInfoWindowController.onCameraMove != null) {
                      _customInfoWindowController.onCameraMove!();
                    }
                  },
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _customInfoWindowController.googleMapController = controller;
                    _setupMap();
                  },
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: true,
                  child: CustomMapInfoWindow(
                    controller: _customInfoWindowController,
                    height: 30, width: 80,
                  ),
                ),
              ),
              Positioned(
                top: Dimensions.paddingSizeSmall,
                left: Dimensions.paddingSizeDefault,
                child: _CircleIconButton(
                  icon: Icons.arrow_back, onTap: () => Get.back(),
                ),
              ),

              Positioned.fill(
                child: DraggableScrollableSheet(
                controller: _sheetController,
                expand: false,
                initialChildSize: _peekFraction,
                minChildSize: 0.2,
                maxChildSize: _maxFraction,
                snap: true,
                snapSizes: [_peekFraction, if (_maxFraction - _peekFraction > 0.02) _maxFraction],
                builder: (context, scrollController) => _SheetContent(
                  parcelController: parcelController,
                  checkoutController: checkoutController,
                  parcelCategory: widget.parcelCategory,
                  pickup: _currentPickup(),
                  destination: _currentDestination(),
                  charge: charge, dmTips: dmTips, additionalCharge: additionalCharge, isGuestLoggedIn: isGuestLoggedIn,
                  tax: tax, taxIncluded: taxIncluded,
                  proBenefit: proBenefit, isPro: isPro, proDiscount: proDiscount, proDeliveryDiscount: proDeliveryDiscount,
                  guestPasswordController: _guestPasswordController,
                  guestConfirmPasswordController: _guestConfirmPasswordController,
                  guestPasswordNode: _guestPasswordNode,
                  guestConfirmPasswordNode: _guestConfirmPasswordNode,
                  onEditSender: _openEditSender,
                  onEditReceiver: _openEditReceiver,
                  onEditPayment: () => _openPaymentSheet(parcelController, total),
                  scrollController: scrollController,
                  peekKey: _peekKey,
                  contentKey: _contentKey,
                  bottomClearance: _footerHeight + Dimensions.paddingSizeExtraSmall,
                ),
              )),

              Positioned(
                left: 0, right: 0, bottom: 0,
                child: KeyedSubtree(
                  key: _footerKey,
                  child: SafeArea(
                    top: false,
                    child: _TotalAndSendRow(
                      total: total,
                      showTaxIncluded: taxIncluded && tax > 0,
                      isLoading: parcelController.isLoading,
                      // The banner names a refusal no order can get past, so sending is barred while it shows.
                      canSend: parcelController.acceptTerms && (checkoutController.summaryError ?? '').isEmpty,
                      onSend: () => _handleSendRequest(
                        parcelController: parcelController, charge: charge, isGuestLoggedIn: isGuestLoggedIn,
                      ),
                    ),
                  ),
                ),
              ),
            ]));
          }) : NotLoggedInScreen(callBack: (value){
            initCall();
            setState(() {});
          }),
        );
      }),
    );
  }
}

class _PhoneParts {
  final String code;
  final String number;
  _PhoneParts({required this.code, required this.number});
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          child: Icon(icon, size: 22, color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
      ),
    );
  }
}

class _SheetContent extends StatelessWidget {
  final ParcelController parcelController;
  final CheckoutController checkoutController;
  final ParcelCategoryModel parcelCategory;
  final AddressModel pickup;
  final AddressModel destination;
  final double charge;
  final double dmTips;
  final double additionalCharge;
  final double tax;
  final bool taxIncluded;
  final bool isGuestLoggedIn;
  final ProActiveBenefit? proBenefit;
  final bool isPro;
  final double proDiscount;
  final double proDeliveryDiscount;
  final TextEditingController guestPasswordController;
  final TextEditingController guestConfirmPasswordController;
  final FocusNode guestPasswordNode;
  final FocusNode guestConfirmPasswordNode;
  final VoidCallback onEditSender;
  final VoidCallback onEditReceiver;
  final VoidCallback onEditPayment;
  final ScrollController scrollController;
  final GlobalKey peekKey;
  final GlobalKey contentKey;
  final double bottomClearance;

  const _SheetContent({
    required this.parcelController, required this.checkoutController, required this.parcelCategory, required this.pickup, required this.destination,
    required this.charge, required this.dmTips, required this.additionalCharge, required this.tax, required this.taxIncluded,
    required this.isGuestLoggedIn,
    required this.proBenefit, required this.isPro, required this.proDiscount, required this.proDeliveryDiscount, required this.guestPasswordController,
    required this.guestConfirmPasswordController, required this.guestPasswordNode, required this.guestConfirmPasswordNode, required this.onEditSender, required this.onEditReceiver,
    required this.onEditPayment, required this.scrollController, required this.peekKey, required this.contentKey,
    required this.bottomClearance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
        padding: EdgeInsets.only(
          left: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault, bottom: bottomClearance,
        ),
        child: KeyedSubtree(key: contentKey, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        KeyedSubtree(
          key: peekKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: _DragHandle()),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            Text('parcel_summary'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            _SummaryStatsRow(
              parcelCategoryName: parcelCategory.name ?? '',
              distance: parcelController.distance,
              charge: charge,
              chargePending: parcelController.isDeliveryChargePending,
              weightLabel: parcelController.selectedWeight?.name,
              dimensionLabel: parcelController.selectedDimension?.name,
            ),
            const ParcelQuoteErrorWidget(),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            _AddressBlock(
              pickup: pickup, destination: destination, onEditSender: onEditSender, onEditReceiver: onEditReceiver,
            ),
          ]),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        _DeliveryInstructionExpand(parcelController: parcelController),
        Divider(color: Theme.of(context).disabledColor.withValues(alpha: 0.5), height: Dimensions.paddingSizeExtraOverLarge),

        _PaymentMethodSection(parcelController: parcelController, onEdit: onEditPayment),
        Divider(color: Theme.of(context).disabledColor.withValues(alpha: 0.5), height: Dimensions.paddingSizeExtraOverLarge),

        Text('billing'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        _BillingRow(
          label: 'delivery_fee'.tr,
          valueWidget: Text(
            parcelController.isDeliveryChargePending ? 'calculating'.tr : PriceConverter.convertPrice(charge),
            style: robotoRegular.copyWith(
              color: parcelController.isDeliveryChargePending ? Colors.red : Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          tooltipMessage: DeliveryFeeTooltip.compose(
            extraCharge: checkoutController.extraCharge,
            surge: checkoutController.surgePrice,
          ),
        ),
        if (isPro && proBenefit?.type == ProBenefitType.deliveryFee && proDeliveryDiscount > 0)
          _BillingRow(
            label: 'delivery_fee_discount_pro'.tr,
            valueWidget: Text(
              '(-) ${PriceConverter.convertPrice(proDeliveryDiscount)}',
              style: robotoRegular, textDirection: TextDirection.ltr,
            ),
            tooltipMessage: '${(charge > 0 ? (proDeliveryDiscount / charge) * 100 : 0).toStringAsFixed(0)}% ${'delivery_fee_discount_applied'.tr}',
          ),
        if (!taxIncluded && tax > 0)
          _BillingRow(
            label: 'vat_tax'.tr,
            valueWidget: Text(
              '(+) ${PriceConverter.convertPrice(tax)}',
              style: robotoRegular, textDirection: TextDirection.ltr,
            ),
          ),
        if (Get.find<SplashController>().configModel!.dmTipsStatus == 1)
          _BillingRow(
            label: 'delivery_man_tips'.tr,
            valueWidget: Text(
              '(+) ${PriceConverter.convertPrice(dmTips)}',
              style: robotoRegular, textDirection: TextDirection.ltr,
            ),
          ),
        if (Get.find<SplashController>().configModel!.additionalChargeStatus ?? false)
          _BillingRow(
            label: Get.find<SplashController>().configModel!.additionalChargeName ?? '',
            valueWidget: Text(
              '(+) ${PriceConverter.convertPrice(additionalCharge)}',
              style: robotoRegular, textDirection: TextDirection.ltr,
            ),
          ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        if (isGuestLoggedIn) ...[
          GuestCreateAccount(
            guestPasswordController: guestPasswordController, guestConfirmPasswordController: guestConfirmPasswordController,
            guestPasswordNode: guestPasswordNode, guestConfirmPasswordNode: guestConfirmPasswordNode,
            fromParcel: true,
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
        ],
        const CheckoutCondition(isParcel: true),
        ])),
      ),
    );
  }
}

class _AddressBlock extends StatelessWidget {
  final AddressModel pickup;
  final AddressModel destination;
  final VoidCallback onEditSender;
  final VoidCallback onEditReceiver;

  const _AddressBlock({required this.pickup, required this.destination, required this.onEditSender, required this.onEditReceiver});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _PartyRow(
          icon: CupertinoIcons.placemark,
          name: pickup.contactPersonName ?? '',
          phone: pickup.contactPersonNumber ?? '',
          address: pickup.address ?? '',
          onEdit: onEditSender,
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),
        _PartyRow(
          icon: CupertinoIcons.location,
          name: destination.contactPersonName ?? '',
          phone: destination.contactPersonNumber ?? '',
          address: destination.address ?? '',
          onEdit: onEditReceiver,
        ),
      ]),
      PositionedDirectional(
        start: 12, top: 27, bottom: 35,
        child: SizedBox(
          width: 2,
          child: CustomPaint(
            painter: _DottedLinePainter(color: Theme.of(context).disabledColor.withValues(alpha: 0.6)),
          ),
        ),
      ),
    ]);
  }
}

class _DeliveryInstructionExpand extends StatefulWidget {
  final ParcelController parcelController;

  const _DeliveryInstructionExpand({required this.parcelController});

  @override
  State<_DeliveryInstructionExpand> createState() => _DeliveryInstructionExpandState();
}

class _DeliveryInstructionExpandState extends State<_DeliveryInstructionExpand> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.parcelController;
    final int? idx = c.selectedIndexNote;
    final String custom = c.customNote ?? '';
    final String? selected = (idx != null && idx != -1 && c.parcelInstructionList != null && idx < c.parcelInstructionList!.length)
        ? c.parcelInstructionList![idx].instruction
        : null;

    final String display;
    if ((selected ?? '').isNotEmpty && custom.isNotEmpty) {
      display = '$selected ($custom)';
    } else if ((selected ?? '').isNotEmpty) {
      display = selected!;
    } else if (custom.isNotEmpty) {
      display = custom;
    } else {
      display = '';
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              'delivery_instruction'.tr,
              style: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeSmall, color: Colors.blueAccent,
              ),
            ),
            const SizedBox(width: 2),
            AnimatedRotation(
              turns: _expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.keyboard_arrow_down, size: 18),
            ),
          ]),
        ),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: !_expanded
            ? const SizedBox.shrink()
            : Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).disabledColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
                child: Text(
                  display.isEmpty ? 'no_instruction_selected'.tr : display,
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: display.isEmpty
                        ? Theme.of(context).hintColor
                        : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
      ),
    ]);
  }
}

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
      child: Container(
        height: 4, width: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).disabledColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        ),
      ),
    );
  }
}

class _SummaryStatsRow extends StatelessWidget {
  final String parcelCategoryName;
  final double? distance;
  final double charge;
  final bool chargePending;

  final String? weightLabel;
  final String? dimensionLabel;

  const _SummaryStatsRow({required this.parcelCategoryName, required this.distance, required this.charge,
    required this.chargePending, this.weightLabel, this.dimensionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final String distanceText = DistanceConverter.labelFromKilometres(distance) ?? 'calculating'.tr;
    final String feeText = chargePending ? 'calculating'.tr : PriceConverter.convertPrice(charge);

    // The bands the parcel is priced by stand in for the stat's own caption. A zone
    // pricing by neither has nothing to name there, so it keeps the plain caption.
    final String bands = <String>[
      if ((weightLabel ?? '').isNotEmpty) weightLabel!,
      if ((dimensionLabel ?? '').isNotEmpty) dimensionLabel!,
    ].join(', ');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeDefault,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).disabledColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Row(children: [
        Expanded(child: _StatItem(
          value: parcelCategoryName,
          label: bands.isEmpty ? 'parcel_type'.tr : bands,
          labelMaxLines: 2,
        )),
        const _StatDivider(),
        Expanded(child: _StatItem(value: distanceText, label: 'total_distance'.tr)),
        const _StatDivider(),
        Expanded(child: _StatItem(value: feeText, label: 'delivery_fee'.tr)),
      ]),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) =>
      Container(height: 36, width: 1, color: Theme.of(context).disabledColor.withValues(alpha: 0.3));
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final int labelMaxLines;

  const _StatItem({required this.value, required this.label, this.labelMaxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(
        value, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr,
        style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
      ),
      const SizedBox(height: 2),
      Text(
        label, maxLines: labelMaxLines, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
      ),
    ]);
  }
}

class _PartyRow extends StatelessWidget {
  final IconData icon;
  final String name;
  final String phone;
  final String address;
  final VoidCallback onEdit;

  const _PartyRow({required this.icon, required this.name, required this.phone, required this.address, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).disabledColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(5),
        child: Icon(icon, size: 18, color: Theme.of(context).disabledColor),
      ),
      const SizedBox(width: Dimensions.paddingSizeSmall),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text.rich(
            TextSpan(children: [
              TextSpan(
                text: name,
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
              ),
              if (phone.isNotEmpty)
                TextSpan(
                  text: ' ($phone)',
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).disabledColor,
                  ),
                ),
            ]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            address, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: Theme.of(context).disabledColor,
              height: 1.4,
            ),
          ),
        ]),
      ),
      const SizedBox(width: Dimensions.paddingSizeSmall),
      InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(20),
        child: const Padding(
          padding: EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
          child: Icon(Icons.edit_outlined, size: 18, color: Colors.blueAccent),
        ),
      ),
    ]);
  }
}

class _DottedLinePainter extends CustomPainter {
  final Color color;

  _DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.height <= 0) return;
    const double dotSize = 2;
    const double gap = 3;
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    double y = dotSize / 2;
    while (y + dotSize / 2 <= size.height) {
      canvas.drawCircle(Offset(size.width / 2, y), dotSize / 2, paint);
      y += dotSize + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLinePainter old) => old.color != color;
}

class _PaymentMethodSection extends StatelessWidget {
  final ParcelController parcelController;
  final VoidCallback onEdit;

  const _PaymentMethodSection({required this.parcelController, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('payment_method'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
      Text(
        '${'payment_will_pay_by'.tr} ${parcelController.payerTypes[parcelController.payerIndex].tr}',
        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
      ),
      const SizedBox(height: Dimensions.paddingSizeSmall),
      ParcelPaymentMethodPicker(controller: parcelController, onTap: onEdit),
    ]);
  }
}

class _BillingRow extends StatelessWidget {
  final String label;
  final Widget valueWidget;
  final String? tooltipMessage;

  const _BillingRow({required this.label, required this.valueWidget, this.tooltipMessage});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Flexible(
              child: Text(
                label, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: robotoRegular.copyWith(),
              ),
            ),
            if (tooltipMessage != null) ...[
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              CustomToolTip(
                message: tooltipMessage,
                size: Dimensions.fontSizeLarge,
                preferredDirection: AxisDirection.up,
              ),
            ],
          ]),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        valueWidget,
      ]),
    );
  }
}

class _TotalAndSendRow extends StatelessWidget {
  final double total;
  final bool showTaxIncluded;
  final bool isLoading;
  final bool canSend;
  final VoidCallback onSend;

  const _TotalAndSendRow({
    required this.total, required this.showTaxIncluded, required this.isLoading, required this.canSend,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Theme.of(context).disabledColor.withValues(alpha: 0.2))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(child: Row(mainAxisSize: MainAxisSize.min, children: [
            Flexible(child: Text(
              'total'.tr, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
            )),
            if (showTaxIncluded)
              Flexible(child: Text(
                ' ${'vat_tax_inc'.tr}', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall),
              )),
          ])),
          PriceConverter.convertAnimationPrice(
            total,
            textStyle: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge!.color),
          ),
        ]),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        CustomButton(
          buttonText: 'send_request'.tr,
          isLoading: isLoading,
          onPressed: canSend ? onSend : null,
        ),
      ]),
    );
  }
}

class _ParcelMarkerLabel extends StatelessWidget {
  final String title;

  const _ParcelMarkerLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Stack(clipBehavior: Clip.none, children: [
      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          color: Colors.black,
        ),
        alignment: Alignment.center,
        child: Text(
          title.tr,
          style: robotoMedium.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall),
        ),
      ),
      Positioned(
        bottom: -6, left: 32,
        child: Transform.rotate(
          angle: math.pi / 4,
          child: Container(color: Colors.black, width: 12, height: 12),
        ),
      ),
    ]);
  }
}

// SUMMARY
// Parcel request screen. Shows the pickup and destination on a map under a draggable
// sheet holding the parcel summary, both parties' details, delivery instruction,
// payment method and the bill, with a fixed total and send footer — the sheet opening
// only as far as its own content reaches. Sending is barred while the quote carries a
// refusal, such as a receiver outside the service area.
