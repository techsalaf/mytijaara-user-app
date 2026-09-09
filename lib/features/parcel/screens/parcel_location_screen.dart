import 'package:country_code_picker/country_code_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_loader.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/custom_text_field.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/common/widgets/web_page_title_widget.dart';
import 'package:sixam_mart/features/address/controllers/address_controller.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/checkout/widgets/tips_widget.dart';
import 'package:sixam_mart/features/dashboard/widgets/parcel_bottom_sheet_widget.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/features/parcel/controllers/parcel_controller.dart';
import 'package:sixam_mart/features/parcel/domain/models/parcel_category_model.dart';
import 'package:sixam_mart/features/pro/widgets/pro_cart_banner_widget.dart';
import 'package:sixam_mart/features/parcel/widgets/delivery_instruction_bottom_sheet_widget.dart';
import 'package:sixam_mart/features/parcel/widgets/parcel_info_bottom_sheet.dart';
import 'package:sixam_mart/features/parcel/widgets/parcel_payment_method_bottom_sheet.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/custom_validator.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/helper/string_extension.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class ParcelLocationScreen extends StatefulWidget {
  final ParcelCategoryModel category;
  const ParcelLocationScreen({super.key, required this.category});

  @override
  State<ParcelLocationScreen> createState() => _ParcelLocationScreenState();
}

class _ParcelLocationScreenState extends State<ParcelLocationScreen> {
  final TextEditingController _senderNameController = TextEditingController();
  final TextEditingController _senderPhoneController = TextEditingController();
  final TextEditingController _receiverNameController = TextEditingController();
  final TextEditingController _receiverPhoneController = TextEditingController();
  final TextEditingController _senderStreetNumberController = TextEditingController();
  final TextEditingController _senderHouseController = TextEditingController();
  final TextEditingController _senderFloorController = TextEditingController();
  final TextEditingController _receiverStreetNumberController = TextEditingController();
  final TextEditingController _receiverHouseController = TextEditingController();
  final TextEditingController _receiverFloorController = TextEditingController();
  final TextEditingController _guestSenderEmailController = TextEditingController();
  final TextEditingController _guestReceiverEmailController = TextEditingController();
  final TextEditingController _senderAddressController = TextEditingController();
  final TextEditingController _receiverAddressController = TextEditingController();
  final TextEditingController _tipController = TextEditingController();

  String? _countryDialCode;
  late ParcelCategoryModel _category;
  bool _isCashOnDeliveryActive = false;
  bool _isDigitalPaymentActive = false;
  // True only when this screen was opened via a chip pre-seed (recent-address
  // suggestion on the parcel module screen). Used to auto-open the receiver
  // sheet once the first frame is painted so the user can fill in receiver
  // details on top of the pre-selected destination.
  bool _autoOpenReceiverSheet = false;

  @override
  void initState() {
    super.initState();
    _category = widget.category;
    _initCall();
  }

  Future<void> _initCall() async {
    _countryDialCode = Get.find<AuthController>().getUserCountryCode().isNotEmpty
        ? Get.find<AuthController>().getUserCountryCode()
        : CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).dialCode;

    final parcelController = Get.find<ParcelController>();
    final checkoutController = Get.find<CheckoutController>();
    parcelController.setPickupAddress(AddressHelper.getUserAddressFromSharedPref(), false);
    parcelController.setDestinationAddress(null, notify: false);
    final AddressModel? pendingDestination = parcelController.consumePendingDestination();
    if(pendingDestination != null) {
      parcelController.setDestinationAddress(pendingDestination, notify: false);
      _autoOpenReceiverSheet = true;
    }
    parcelController.setIsPickedUp(true, false);
    parcelController.setIsSender(true, false);
    parcelController.setCountryCode(_countryDialCode!, true);
    parcelController.setCountryCode(_countryDialCode!, false);

    parcelController.getOfflineMethodList();
    parcelController.getDmTipMostTapped();
    parcelController.getParcelInstruction();
    parcelController.setPaymentIndex(-1, false);
    parcelController.setPayerIndex(0, false);
    parcelController.setInstructionSelectedIndex(-1, notify: false);
    parcelController.setCustomNoteController('', notify: false);
    parcelController.setSelectedIndex(-1);
    parcelController.setCustomNote('');
    parcelController.updateTips(
      Get.find<AuthController>().getDmTipIndex().isNotEmpty
          ? int.parse(Get.find<AuthController>().getDmTipIndex()) : PriceConverter.noTipIndex,
      notify: false,
    );

    checkoutController.resetOrderTax();
    if (checkoutController.isCreateAccount) {
      checkoutController.toggleCreateAccount(willUpdate: false);
    }

    _resolvePaymentFlags();
    _ensureDistance();

    if (AuthHelper.isLoggedIn() && Get.find<AddressController>().addressList == null) {
      Get.find<AddressController>().getAddressList();
    }

    if (AuthHelper.isLoggedIn()) {
      if (Get.find<ProfileController>().userInfoModel == null) {
        await Get.find<ProfileController>().getUserInfo();
      }
      final user = Get.find<ProfileController>().userInfoModel;
      _senderNameController.text = '${user?.fName ?? ''} ${user?.lName ?? ''}'.trim();
      _countryDialCode = _splitPhoneNumber(user?.phone ?? '', returnCountryCode: true);
      _senderPhoneController.text = _splitPhoneNumber(user?.phone ?? '', returnCountryCode: false);

      parcelController.setCountryCode(_countryDialCode!, true);
      parcelController.setCountryCode(_countryDialCode!, false);
      if (mounted) setState(() {});
    }

    if(_autoOpenReceiverSheet) {
      _autoOpenReceiverSheet = false;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Let the page-transition animation settle before the sheet slides in,
        // otherwise the two animations stack and feel jumpy.
        await Future.delayed(const Duration(milliseconds: 400));
        if(mounted) _openReceiverSheet();
      });
    }
  }

  void _resolvePaymentFlags() {
    final pickup = Get.find<ParcelController>().pickupAddress;
    final savedAddress = AddressHelper.getUserAddressFromSharedPref();
    final config = Get.find<SplashController>().configModel!;
    _isCashOnDeliveryActive = false;
    _isDigitalPaymentActive = false;
    if (pickup?.zoneData == null || savedAddress == null) return;
    for (ZoneData zData in pickup!.zoneData!) {
      if (zData.id == savedAddress.zoneId) {
        _isCashOnDeliveryActive = (zData.cashOnDelivery ?? false) && (config.cashOnDelivery ?? false);
        _isDigitalPaymentActive = (zData.digitalPayment ?? false) && (config.digitalPayment ?? false);
        break;
      }
    }
  }

  void _ensureDistance() {
    final parcelController = Get.find<ParcelController>();
    final pickup = parcelController.pickupAddress;
    final destination = parcelController.destinationAddress;
    if (pickup?.latitude != null && pickup?.longitude != null
        && destination?.latitude != null && destination?.longitude != null) {
      parcelController.getDistance(pickup!, destination!);
    }
  }

  Future<void> _loadDistanceAndTax() async {
    final parcelController = Get.find<ParcelController>();
    final pickup = parcelController.pickupAddress;
    final destination = parcelController.destinationAddress;
    if (pickup != null && destination != null) {
      Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);
      await parcelController.getDistance(pickup, destination);
      await parcelController.fetchOrderTax(_category);
      if (Get.isDialogOpen ?? false) Get.back();
    }
  }

  String _splitPhoneNumber(String number, {required bool returnCountryCode}) {
    String code = '';
    String pNumber = '';
    try {
      final PhoneNumber phoneNumber = PhoneNumber.parse(number);
      code = '+${phoneNumber.countryCode}';
      pNumber = phoneNumber.international.substring(code.length);
    } catch (e) {
      debugPrint('number can\'t parse : $e');
    }
    return returnCountryCode ? code : pNumber;
  }

  @override
  void dispose() {
    super.dispose();
    _senderNameController.dispose();
    _senderPhoneController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _senderStreetNumberController.dispose();
    _senderHouseController.dispose();
    _senderFloorController.dispose();
    _receiverStreetNumberController.dispose();
    _receiverHouseController.dispose();
    _receiverFloorController.dispose();
    _guestSenderEmailController.dispose();
    _guestReceiverEmailController.dispose();
    _senderAddressController.dispose();
    _receiverAddressController.dispose();
    _tipController.dispose();
  }

  Future<bool> _validateSenderInfo({bool showSnackbarOnFail = true}) async {
    final parcelController = Get.find<ParcelController>();
    final String numberWithCountryCode = '${parcelController.senderCountryCode ?? ''}${_senderPhoneController.text.trim()}';
    final PhoneValid phoneValid = await CustomValidator.isPhoneValid(numberWithCountryCode);

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
    } else if (AuthHelper.isGuestLoggedIn() && _guestSenderEmailController.text.trim().isEmpty) {
      if (showSnackbarOnFail) showCustomSnackBar('please_enter_sender_email'.tr);
      return false;
    } else if (AuthHelper.isGuestLoggedIn() && !CustomValidator.isEmailValid(_guestSenderEmailController.text.trim())) {
      if (showSnackbarOnFail) showCustomSnackBar('enter_valid_email_address'.tr);
      return false;
    }

    final AddressModel pickup = AddressModel(
      address: parcelController.pickupAddress!.address,
      additionalAddress: parcelController.pickupAddress!.additionalAddress,
      addressType: parcelController.pickupAddress!.addressType,
      contactPersonName: _senderNameController.text.trim(),
      contactPersonNumber: phoneValid.phone,
      latitude: parcelController.pickupAddress!.latitude,
      longitude: parcelController.pickupAddress!.longitude,
      method: parcelController.pickupAddress!.method,
      zoneId: parcelController.pickupAddress!.zoneId,
      id: parcelController.pickupAddress!.id,
      zoneIds: parcelController.pickupAddress!.zoneIds,
      streetNumber: _senderStreetNumberController.text.trim(),
      house: _senderHouseController.text.trim(),
      floor: _senderFloorController.text.trim(),
      email: _guestSenderEmailController.text.trim(),
      zoneData: parcelController.pickupAddress!.zoneData,
    );
    parcelController.setPickupAddress(pickup, true);
    return true;
  }

  Future<bool> _validateReceiverInfo({bool showSnackbarOnFail = true}) async {
    final parcelController = Get.find<ParcelController>();
    final String numberWithCountryCode = '${parcelController.receiverCountryCode ?? ''}${_receiverPhoneController.text.trim()}';
    final PhoneValid phoneValid = await CustomValidator.isPhoneValid(numberWithCountryCode);

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
    } else if (AuthHelper.isGuestLoggedIn() && _guestReceiverEmailController.text.trim().isEmpty) {
      if (showSnackbarOnFail) showCustomSnackBar('please_enter_sender_email'.tr);
      return false;
    } else if (AuthHelper.isGuestLoggedIn() && !CustomValidator.isEmailValid(_guestReceiverEmailController.text.trim())) {
      if (showSnackbarOnFail) showCustomSnackBar('enter_valid_email_address'.tr);
      return false;
    }

    final AddressModel destination = AddressModel(
      address: parcelController.destinationAddress!.address,
      additionalAddress: parcelController.destinationAddress!.additionalAddress,
      addressType: parcelController.destinationAddress!.addressType,
      contactPersonName: _receiverNameController.text.trim(),
      contactPersonNumber: phoneValid.phone,
      latitude: parcelController.destinationAddress!.latitude,
      longitude: parcelController.destinationAddress!.longitude,
      method: parcelController.destinationAddress!.method,
      zoneId: parcelController.destinationAddress!.zoneId,
      zoneIds: parcelController.destinationAddress!.zoneIds,
      id: parcelController.destinationAddress!.id,
      streetNumber: _receiverStreetNumberController.text.trim(),
      house: _receiverHouseController.text.trim(),
      floor: _receiverFloorController.text.trim(),
      email: _guestReceiverEmailController.text.trim(),
      zoneData: parcelController.destinationAddress!.zoneData,
    );
    parcelController.setDestinationAddress(destination);
    return true;
  }

  void _openSenderSheet() {
    ParcelInfoBottomSheet.open(
      context,
      isSender: true,
      nameController: _senderNameController,
      phoneController: _senderPhoneController,
      streetController: _senderStreetNumberController,
      houseController: _senderHouseController,
      floorController: _senderFloorController,
      guestEmailController: _guestSenderEmailController,
      addressController: _senderAddressController,
      onConfirm: () async {
        final ok = await _validateSenderInfo();
        if (ok && mounted) {
          Get.find<ParcelController>().setPaymentIndex(-1, false);
          setState(() {});
          await _loadDistanceAndTax();
        }
        return ok;
      },
    );
  }

  void _openReceiverSheet() {
    ParcelInfoBottomSheet.open(
      context,
      isSender: false,
      nameController: _receiverNameController,
      phoneController: _receiverPhoneController,
      streetController: _receiverStreetNumberController,
      houseController: _receiverHouseController,
      floorController: _receiverFloorController,
      guestEmailController: _guestReceiverEmailController,
      addressController: _receiverAddressController,
      onConfirm: () async {
        final ok = await _validateReceiverInfo();
        if (ok && mounted) {
          Get.find<ParcelController>().setPaymentIndex(-1, false);
          setState(() {});
          await _loadDistanceAndTax();
        }
        return ok;
      },
    );
  }

  void _openCategorySheet() {
    final categoryList = Get.find<ParcelController>().parcelCategoryList;
    final sheet = ParcelBottomSheetWidget(
      parcelCategoryList: categoryList,
      onCategorySelected: (selected) {
        if (mounted) setState(() => _category = selected);
      },
    );
    if (ResponsiveHelper.isDesktop(context)) {
      Get.dialog(Dialog(child: sheet));
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => sheet,
      );
    }
  }

  Future<void> _onReview() async {
    if (!await _validateSenderInfo(showSnackbarOnFail: false)) {
      _openSenderSheet();
      return;
    }
    if (!await _validateReceiverInfo(showSnackbarOnFail: false)) {
      _openReceiverSheet();
      return;
    }

    if (AddressHelper.getUserAddressFromSharedPref() == null) {
      await AddressHelper.saveUserAddressInSharedPref(Get.find<ParcelController>().pickupAddress!);
    }

    final parcelController = Get.find<ParcelController>();
    Get.toNamed(RouteHelper.getParcelRequestRoute(
      _category,
      parcelController.pickupAddress!,
      parcelController.destinationAddress!,
    ));
    Get.find<CheckoutController>().updateFirstTime();
    Get.find<CheckoutController>().updateFirstTimeCodActive();
  }

  bool _senderIsFilled(ParcelController c) {
    return c.pickupAddress != null
        && _senderNameController.text.trim().isNotEmpty
        && _senderPhoneController.text.trim().isNotEmpty;
  }

  bool _receiverIsFilled(ParcelController c) {
    return c.destinationAddress != null
        && _receiverNameController.text.trim().isNotEmpty
        && _receiverPhoneController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'set_location'.tr),
      endDrawer: const MenuDrawer(),
      endDrawerEnableOpenDragGesture: false,
      body: SafeArea(
        child: GetBuilder<ParcelController>(builder: (parcelController) {
          final Widget content = Column(children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault,
                  vertical: Dimensions.paddingSizeDefault,
                ),
                child: Center(
                  child: SizedBox(
                    width: Dimensions.webMaxWidth,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      _CategoryCard(category: _category, onEdit: _openCategorySheet),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      Container(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                        decoration: _sectionDecoration(context),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _RouteCard(
                            senderFilled: _senderIsFilled(parcelController),
                            senderName: _senderNameController.text.trim(),
                            senderCountryCode: parcelController.senderCountryCode,
                            senderPhone: _senderPhoneController.text.trim(),
                            senderAddress: parcelController.pickupAddress?.address,
                            receiverFilled: _receiverIsFilled(parcelController),
                            receiverName: _receiverNameController.text.trim(),
                            receiverCountryCode: parcelController.receiverCountryCode,
                            receiverPhone: _receiverPhoneController.text.trim(),
                            receiverAddress: parcelController.destinationAddress?.address,
                            onSenderTap: _openSenderSheet,
                            onReceiverTap: _openReceiverSheet,
                            bare: true,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                            child: Divider(height: 1, thickness: 1, color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),
                          ),
                          _DeliveryInstructionCard(controller: parcelController, bare: true),
                        ]),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      _DeliveryTipsCard(controller: parcelController, tipController: _tipController),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      _PaymentByCard(
                        controller: parcelController, isCashOnDeliveryActive: _isCashOnDeliveryActive,
                      ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      _PaymentMethodCard(
                        controller: parcelController, category: _category, isCashOnDeliveryActive: _isCashOnDeliveryActive,
                        isDigitalPaymentActive: _isDigitalPaymentActive,
                      ),
                    ]),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, 0),
              child: _ParcelLocationProBanner(
                subtotal: parcelController.calculateDeliveryCharge(_category),
                redirectRoute: RouteHelper.getParcelLocationRoute(_category),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, 0, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault),
              child: CustomButton(
                buttonText: 'review_payment_and_addresses'.tr,
                onPressed: _onReview,
              ),
            ),
          ]);

          return ResponsiveHelper.isDesktop(context)
              ? Column(children: [
                  WebScreenTitleWidget(title: 'parcel_delivery_information'.tr),
                  Expanded(child: SingleChildScrollView(child: FooterView(child: content))),
                ])
              : content;
        }),
      ),
    );
  }
}

// Pro banner on the set-location screen. For pro members it shows the active benefit
// (e.g. "you get 78% off on delivery charge as a pro member"); for non-pro users it shows
// the subscribe banner, redirecting back here after subscribing. There is no cart subtotal
// on this screen yet, so promo mode forces the achieved-benefit text.
class _ParcelLocationProBanner extends StatelessWidget {
  // Parcel has no item subtotal, so the Pro benefit applies on the delivery
  // charge — pass it as the banner subtotal so the savings shown are correct.
  final double subtotal;
  final String redirectRoute;
  const _ParcelLocationProBanner({required this.subtotal, required this.redirectRoute});

  @override
  Widget build(BuildContext context) {
    if (!Get.find<SplashController>().proStaus) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: ProCartBannerWidget(subtotal: subtotal, redirectRoute: redirectRoute,),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final ParcelCategoryModel category;
  final VoidCallback onEdit;

  const _CategoryCard({required this.category, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          child: CustomImage(
            image: category.imageFullUrl ?? '',
            height: 40,
            width: 40,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: Dimensions.paddingSizeDefault),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              category.name ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
            ),
            const SizedBox(height: 2),
            Text(
              'parcel_type'.tr,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).disabledColor,
              ),
            ),
          ]),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        GestureDetector(
          onTap: onEdit,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
            child: Icon(Icons.edit_outlined, size: 18, color: Theme.of(context).primaryColor),
          ),
        ),
      ]),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final bool senderFilled;
  final String senderName;
  final String? senderCountryCode;
  final String senderPhone;
  final String? senderAddress;
  final bool receiverFilled;
  final String receiverName;
  final String? receiverCountryCode;
  final String receiverPhone;
  final String? receiverAddress;
  final VoidCallback onSenderTap;
  final VoidCallback onReceiverTap;
  // When true, renders the content without the outer Container decoration
  // so it can be visually merged with an adjacent card. Default false keeps
  // standalone behavior unchanged.
  final bool bare;

  const _RouteCard({
    required this.senderFilled, required this.senderName, required this.senderCountryCode, required this.senderPhone, required this.senderAddress,
    required this.receiverFilled, required this.receiverName, required this.receiverCountryCode, required this.receiverPhone, required this.receiverAddress,
    required this.onSenderTap, required this.onReceiverTap, this.bare = false,
  });

  @override
  Widget build(BuildContext context) {
    final Widget content = Stack(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _RouteRow(
          icon: CupertinoIcons.placemark,
          filled: senderFilled,
          name: senderName,
          countryCode: senderCountryCode,
          phone: senderPhone,
          address: senderAddress,
          placeholder: 'sender_info'.tr,
          actionLabel: senderFilled ? 'edit'.tr : 'add'.tr,
          onAction: onSenderTap,
        ),
        const SizedBox(height: Dimensions.paddingSizeLarge),
        _RouteRow(
          icon: CupertinoIcons.location,
          filled: receiverFilled,
          name: receiverName,
          countryCode: receiverCountryCode,
          phone: receiverPhone,
          address: receiverAddress,
          placeholder: 'receiver_info'.tr,
          actionLabel: receiverFilled ? 'edit'.tr : 'add'.tr,
          onAction: onReceiverTap,
        ),
      ]),
      PositionedDirectional(
        start: 17,
        top: 40,
        bottom: 40,
        child: SizedBox(
          width: 2,
          child: CustomPaint(
            painter: _DottedLinePainter(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    ]);

    if(bare) return content;
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: _sectionDecoration(context),
      child: content,
    );
  }
}

class _RouteRow extends StatelessWidget {
  final IconData icon;
  final bool filled;
  final String name;
  final String? countryCode;
  final String phone;
  final String? address;
  final String placeholder;
  final String actionLabel;
  final VoidCallback onAction;

  const _RouteRow({
    required this.icon,
    required this.filled,
    required this.name,
    required this.countryCode,
    required this.phone,
    required this.address,
    required this.placeholder,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final String formattedPhone = (countryCode != null && countryCode!.isNotEmpty && phone.isNotEmpty)
        ? '$countryCode $phone'
        : phone;

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).disabledColor.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: Theme.of(context).disabledColor),
      ),
      const SizedBox(width: Dimensions.paddingSizeDefault),
      Expanded(
        child: filled
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                ),
                const SizedBox(height: 2),
                Text(
                  formattedPhone,
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).disabledColor,
                  ),
                ),
                if ((address ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    address!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).disabledColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ])
            : Padding(
                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                child: Text(
                  placeholder,
                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                ),
              ),
      ),
      const SizedBox(width: Dimensions.paddingSizeSmall),
      InkWell(
        onTap: onAction,
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
            vertical: Dimensions.paddingSizeExtraSmall,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
          ),
          child: Text(
            actionLabel,
            style: robotoMedium.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
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

BoxDecoration _sectionDecoration(BuildContext context) => BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
    );

class _DeliveryInstructionCard extends StatelessWidget {
  final ParcelController controller;
  final bool bare;

  const _DeliveryInstructionCard({required this.controller, this.bare = false});

  void _openSheet(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) {
      showDialog(
        context: context,
        builder: (_) => const Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(Dimensions.radiusDefault))),
          child: DeliveryInstructionBottomSheetWidget(),
        ),
      );
    } else {
      Get.bottomSheet(
        const DeliveryInstructionBottomSheetWidget(),
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
      );
    }
  }

  void _clear() {
    controller.setInstructionSelectedIndex(-1, notify: false);
    controller.setCustomNoteController('');
    controller.setSelectedIndex(-1);
    controller.setCustomNote('');
  }

  @override
  Widget build(BuildContext context) {
    final int? selectedIndex = controller.selectedIndexNote;
    final String customNote = controller.customNote ?? '';
    final String? instructionText = (selectedIndex != null && selectedIndex != -1 && controller.parcelInstructionList != null
            && selectedIndex < controller.parcelInstructionList!.length)
        ? controller.parcelInstructionList![selectedIndex].instruction
        : null;

    final String displayText;
    if ((instructionText ?? '').isNotEmpty && customNote.isNotEmpty) {
      displayText = '$instructionText ($customNote)';
    } else if ((instructionText ?? '').isNotEmpty) {
      displayText = instructionText!;
    } else if (customNote.isNotEmpty) {
      displayText = customNote;
    } else {
      displayText = '';
    }
    final bool hasSelection = displayText.isNotEmpty;

    final Widget content = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('delivery_instruction'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
        Text(
          '(${'optional'.tr})',
          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
        ),
      ]),
      const SizedBox(height: Dimensions.paddingSizeSmall),
      InkWell(
        onTap: () => _openSheet(context),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
            vertical: Dimensions.paddingSizeDefault,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.3), width: 0.7),
          ),
          child: Row(children: [
            Expanded(
              child: Text(
                hasSelection ? displayText : 'select_your_instruction'.tr,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: hasSelection
                      ? Theme.of(context).textTheme.bodyLarge?.color
                      : Theme.of(context).hintColor,
                ),
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            hasSelection
                ? InkWell(
                    onTap: _clear,
                    child: Icon(Icons.clear, size: 18, color: Theme.of(context).disabledColor),
                  )
                : Icon(Icons.keyboard_arrow_down, size: 20, color: Theme.of(context).disabledColor),
          ]),
        ),
      ),
    ]);

    if(bare) return content;
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: _sectionDecoration(context),
      child: content,
    );
  }
}

class _DeliveryTipsCard extends StatelessWidget {
  final ParcelController controller;
  final TextEditingController tipController;

  const _DeliveryTipsCard({required this.controller, required this.tipController});

  @override
  Widget build(BuildContext context) {
    if (Get.find<SplashController>().configModel!.dmTipsStatus != 1) {
      return const SizedBox.shrink();
    }
    final bool showCustomField = AppConstants.tips[controller.selectedTips] == 'custom' && controller.canShowTipsField;

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: _sectionDecoration(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('delivery_tips'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        showCustomField
            ? Row(children: [
                Expanded(
                  child: CustomTextField(
                    titleText: 'enter_amount'.tr,
                    controller: tipController,
                    inputAction: TextInputAction.done,
                    inputType: TextInputType.number,
                    onSubmit: (value) => _applyCustomTip(value),
                    onChanged: (value) => _applyCustomTip(value),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                InkWell(
                  onTap: () {
                    controller.updateTips(PriceConverter.noTipIndex);
                    controller.showTipsField();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    child: const Icon(Icons.clear),
                  ),
                ),
              ])
            : SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: AppConstants.tips.length,
                  itemBuilder: (context, index) {
                    final String raw = AppConstants.tips[index];
                    final bool isCustomChip = raw == 'custom';
                    return TipsWidget(
                      title: raw == '0'
                          ? 'not_now'.tr
                          : isCustomChip
                              ? raw.tr.toCapitalized()
                              : '\$$raw',
                      isSelected: controller.selectedTips == index,
                      isSuggested: raw != '0' && !isCustomChip && raw == controller.mostDmTipAmount.toString(),
                      onTap: () {
                        controller.updateTips(index);
                        if (!isCustomChip) {
                          controller.addTips(double.parse(raw));
                        }
                        if (isCustomChip) {
                          controller.showTipsField();
                        }
                        tipController.text = controller.tips.toString();
                      },
                    );
                  },
                ),
              ),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        showCustomField
            ? const SizedBox.shrink()
            : InkWell(
                onTap: () => controller.toggleDmTipSave(),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.3), width: 1),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
                  child: Row(children: [
                    Expanded(
                      child: Text(
                        'save_it_for_later'.tr,
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),

                    SizedBox(
                      height: 22, width: 22,
                      child: Checkbox(
                        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                        activeColor: Theme.of(context).primaryColor,
                        value: controller.isDmTipSave,
                        onChanged: (bool? isChecked) => controller.toggleDmTipSave(),
                      ),
                    ),
                  ]),
                ),
              ),
      ]),
    );
  }

  void _applyCustomTip(String value) {
    if (value.isEmpty) {
      controller.addTips(0.0);
      return;
    }
    final parsed = double.tryParse(value);
    if (parsed == null) return;
    if (parsed < 0) {
      showCustomSnackBar('tips_can_not_be_negative'.tr);
      return;
    }
    controller.addTips(parsed);
  }
}

class _PaymentByCard extends StatelessWidget {
  final ParcelController controller;
  final bool isCashOnDeliveryActive;

  const _PaymentByCard({required this.controller, required this.isCashOnDeliveryActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: _sectionDecoration(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('payment_by'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
        const SizedBox(height: 2),
        Text(
          'choose_who_will_pay_and_how_to_pay'.tr,
          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
          ),
          child: Row(children: [
            Expanded(child: _SegmentButton(
              label: 'sender_will_pay'.tr, isSelected: controller.payerIndex == 0,
              onTap: () => controller.setPayerIndex(0, true),
            )),
            if (isCashOnDeliveryActive) Expanded(child: _SegmentButton(
              label: 'receiver_will_pay'.tr, isSelected: controller.payerIndex == 1,
              onTap: () => controller.setPayerIndex(1, true),
            )),
          ]),
        ),
      ]),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentButton({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).cardColor : Colors.transparent,
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: Text(
          label,
          style: robotoMedium.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: isSelected
                ? Theme.of(context).textTheme.bodyLarge?.color
                : Theme.of(context).disabledColor,
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final ParcelController controller;
  final ParcelCategoryModel category;
  final bool isCashOnDeliveryActive;
  final bool isDigitalPaymentActive;

  const _PaymentMethodCard({
    required this.controller, required this.category, required this.isCashOnDeliveryActive, required this.isDigitalPaymentActive,
  });

  Future<void> _openSheet(BuildContext context) async {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);
    final bool isGuest = AuthHelper.isGuestLoggedIn();
    final bool walletActive = (Get.find<SplashController>().configModel!.customerWalletStatus == 1) && controller.payerIndex == 0 && !isGuest;
    final bool digitalActive = isDigitalPaymentActive && controller.payerIndex == 0;
    final bool offlineActive = controller.offlineMethodList != null && controller.payerIndex == 0 && (Get.find<SplashController>().configModel?.offlinePaymentStatus ?? false);

    if (!(isCashOnDeliveryActive || digitalActive || walletActive || offlineActive)) {
      showCustomSnackBar('no_payment_method_found'.tr);
      return;
    }

    double total = controller.calculateBill(category).total;

    final sheet = ParcelPaymentMethodBottomSheet(
      isCashOnDeliveryActive: isCashOnDeliveryActive,
      isDigitalPaymentActive: digitalActive,
      totalPrice: total,
      isOfflinePaymentActive: offlineActive,
      canPayWallet: walletActive,
    );
    if (isDesktop) {
      Get.dialog(Dialog(backgroundColor: Colors.transparent, child: sheet));
    } else {
      Get.bottomSheet(sheet, backgroundColor: Colors.transparent, isScrollControlled: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int paymentIndex = controller.paymentIndex;
    final bool hasSelection = paymentIndex != -1;

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: _sectionDecoration(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('payment_method'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        hasSelection
            ? _SelectedPaymentRow(controller: controller, onEdit: () => _openSheet(context))
            : InkWell(
                onTap: () => _openSheet(context),
                child: DottedBorder(
                  options: RoundedRectDottedBorderOptions(
                    color: Theme.of(context).disabledColor.withValues(alpha: 0.5),
                    strokeWidth: 1,
                    dashPattern: const [5, 4],
                    radius: const Radius.circular(Dimensions.radiusDefault),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).disabledColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add_circle_outline, size: 18, color: Theme.of(context).textTheme.bodyLarge?.color),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      Text(
                        'add_payment_method'.tr,
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
      ]),
    );
  }
}

class _SelectedPaymentRow extends StatelessWidget {
  final ParcelController controller;
  final VoidCallback onEdit;

  const _SelectedPaymentRow({required this.controller, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final int idx = controller.paymentIndex;
    final String label = idx == 0
        ? 'cash_on_delivery'.tr
        : idx == 1
        ? 'wallet_payment'.tr
        : idx == 2
        ? '${'digital_payment'.tr} (${controller.digitalPaymentName?.replaceAll('_', ' ').toTitleCase() ?? ''})'
        : idx == 3
        ? '${'offline_payment'.tr}(${controller.offlineMethodList?[controller.selectedOfflineBankIndex].methodName ?? ''})'
        : 'select_payment_method'.tr;
    final String iconAsset = idx == 0
        ? Images.cash
        : idx == 1
        ? Images.wallet
        : idx == 2
        ? Images.digitalPayment
        : Images.cash;

    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeSmall,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.3), width: 0.7),
        ),
        child: Row(children: [
          Image.asset(iconAsset, width: 22, height: 22, color: Theme.of(context).textTheme.bodyMedium?.color),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Icon(Icons.edit_outlined, size: 18, color: Theme.of(context).primaryColor),
        ]),
      ),
    );
  }
}
