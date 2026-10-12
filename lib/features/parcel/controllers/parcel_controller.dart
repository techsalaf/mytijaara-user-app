import 'dart:convert';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/api/json_reader.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/parcel/domain/models/parcel_cancellation_reasons_model.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/checkout/domain/models/checkout_summary_body_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/coverage_list_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/checkout_summary_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/features/parcel/domain/models/parcel_category_model.dart';
import 'package:sixam_mart/features/parcel/domain/models/parcel_tier_model.dart';
import 'package:sixam_mart/features/parcel/domain/models/video_content_model.dart';
import 'package:sixam_mart/features/parcel/domain/models/why_choose_model.dart';
import 'package:sixam_mart/features/parcel/domain/services/parcel_service_interface.dart';
import 'package:sixam_mart/features/payment/domain/models/offline_method_model.dart';
import 'package:sixam_mart/features/pro/controllers/pro_controller.dart';
import 'package:sixam_mart/features/pro/domain/models/pro_active_offer_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';

import '../domain/models/parcel_instruction_model.dart';
import 'package:universal_html/html.dart' as html;

class ParcelController extends GetxController implements GetxService {
  final ParcelServiceInterface parcelServiceInterface;
  ParcelController({required this.parcelServiceInterface});

  List<ParcelCategoryModel>? _parcelCategoryList;
  List<ParcelCategoryModel>? get parcelCategoryList => _parcelCategoryList;

  AddressModel? _pickupAddress;
  AddressModel? get pickupAddress => _pickupAddress;

  AddressModel? _destinationAddress;
  AddressModel? get destinationAddress => _destinationAddress;

  // One-shot pre-seed for the destination on the next ParcelLocationScreen entry.
  // Written by the parcel module screen when the user taps a recent-address chip;
  // read and cleared by ParcelLocationScreen._initCall after the default home-address seed.
  AddressModel? _pendingDestination;

  void setPendingDestination(AddressModel? address) {
    _pendingDestination = address;
  }

  AddressModel? consumePendingDestination() {
    final AddressModel? pending = _pendingDestination;
    _pendingDestination = null;
    return pending;
  }

  List<AddressModel> _parcelRecentAddresses = [];
  List<AddressModel> get parcelRecentAddresses => _parcelRecentAddresses;

  bool? _isPickedUp = true;
  bool? get isPickedUp => _isPickedUp;

  bool _isSender = true;
  bool get isSender => _isSender;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  double? _distance = -1;
  double? get distance => _distance;

  final List<String> _payerTypes = ['sender', 'receiver'];
  List<String> get payerTypes => _payerTypes;

  int _payerIndex = 0;
  int get payerIndex => _payerIndex;

  int _paymentIndex = -1;
  int get paymentIndex => _paymentIndex;

  bool _acceptTerms = true;
  bool get acceptTerms => _acceptTerms;

  double? _extraCharge;
  double? get extraCharge => _extraCharge;

  String? _digitalPaymentName;
  String? get digitalPaymentName => _digitalPaymentName;

  WhyChooseModel? _whyChooseDetails;
  WhyChooseModel? get whyChooseDetails => _whyChooseDetails;

  VideoContentModel? _videoContentDetails;
  VideoContentModel? get videoContentDetails => _videoContentDetails;

  int _selectedOfflineBankIndex = 0;
  int get selectedOfflineBankIndex => _selectedOfflineBankIndex;

  List<Data>? _parcelInstructionList;
  List<Data>? get parcelInstructionList => _parcelInstructionList;

  int _instructionSelectedIndex = -1;
  int get instructionSelectedIndex => _instructionSelectedIndex;

  final TextEditingController _customNoteController = TextEditingController();
  TextEditingController get customNoteController => _customNoteController;

  String _customNote = '';
  String? get customNote => _customNote;

  int _selectedIndexNote = -1;
  int? get selectedIndexNote => _selectedIndexNote;

  String? _senderCountryCode;
  String? get senderCountryCode => _senderCountryCode;

  String? _receiverCountryCode;
  String? get receiverCountryCode => _receiverCountryCode;

  List<OfflineMethodModel>? _offlineMethodList;
  List<OfflineMethodModel>? get offlineMethodList => _offlineMethodList;

  int? _mostDmTipAmount;
  int? get mostDmTipAmount => _mostDmTipAmount;

  double _tips = 0.0;
  double get tips => _tips;

  int _selectedTips = 0;
  int get selectedTips => _selectedTips;

  bool _canShowTipsField = false;
  bool get canShowTipsField => _canShowTipsField;

  bool _isDmTipSave = false;
  bool get isDmTipSave => _isDmTipSave;

  List<Reason>? _parcelCancellationReasons;
  List<Reason>? get parcelCancellationReasons => _parcelCancellationReasons;

  ParcelTierListModel<ParcelWeightModel>? _weightTier;
  ParcelTierListModel<ParcelWeightModel>? get weightTier => _weightTier;

  ParcelTierListModel<ParcelDimensionModel>? _dimensionTier;
  ParcelTierListModel<ParcelDimensionModel>? get dimensionTier => _dimensionTier;

  int? _selectedWeightId;
  int? get selectedWeightId => _selectedWeightId;

  int? _selectedDimensionId;
  int? get selectedDimensionId => _selectedDimensionId;

  /// Whether this `(zone, module)` prices by the tier at all. Both switches are
  /// independent — a rule may price by weight and not by size — so each is asked
  /// separately and each picker is drawn separately.
  bool get needsWeightSelection => _weightTier?.requiresSelection ?? false;
  bool get needsDimensionSelection => _dimensionTier?.requiresSelection ?? false;

  /// A tier is on and offers bands, but nothing is picked. The fee would then be
  /// quoted without that band's charge — the engine simply charges nothing for a
  /// tier it was sent no id for — so the customer would be shown a price the
  /// order will not honour once they pick.
  bool get isTierSelectionMissing =>
      (needsWeightSelection && _selectedWeightId == null)
      || (needsDimensionSelection && _selectedDimensionId == null);

  ParcelWeightModel? get selectedWeight => _findById(_weightTier?.data, _selectedWeightId, (ParcelWeightModel w) => w.id);
  ParcelDimensionModel? get selectedDimension => _findById(_dimensionTier?.data, _selectedDimensionId, (ParcelDimensionModel d) => d.id);

  /// What the sender's zone asks the customer to pick from before its delivery
  /// rule can price the parcel — an area, a ZIP code, or nothing at all.
  ///
  /// Held here rather than on `CheckoutController`, which keeps its own copy for
  /// a store checkout: that one is loaded against the *store's* zone and its
  /// `needCoverageAreaSelection` is gated on `orderType == 'delivery'`, so
  /// sharing the field would have a parcel priced by a store's rule and cleared
  /// by `clearPrevData()` on the next checkout visit.
  CoverageListModel? _coverage;
  CoverageListModel? get coverage => _coverage;

  /// Only one can be set — which one depends on [isZipCodeWiseDelivery] — and it
  /// is posted to both the quote and `place_order`, because the fee moves with it.
  int? _selectedAreaId;
  int? get selectedAreaId => _selectedAreaId;

  int? _selectedZipCodeId;
  int? get selectedZipCodeId => _selectedZipCodeId;

  /// Whether this zone prices by area or ZIP at all. False for `distance_wise`,
  /// `fixed_amount`, and a rule with no options configured.
  bool get needsCoverageSelection => _coverage?.requiresSelection ?? false;

  /// Which key the pick is posted under, and which wording the customer sees.
  bool get isZipCodeWiseDelivery => _coverage?.isZipCode ?? false;

  CoverageOption? get selectedCoverageOption {
    final int? id = isZipCodeWiseDelivery ? _selectedZipCodeId : _selectedAreaId;
    return _findById(_coverage?.coverage, id, (CoverageOption o) => o.id);
  }

  /// The zone prices by area or ZIP but nothing is picked. As with the tiers,
  /// the quote is not refused — it falls back to the rule's own minimum — so the
  /// customer would be shown a price the order will not honour once they pick.
  bool get isCoverageSelectionMissing => needsCoverageSelection && selectedCoverageOption == null;

  static T? _findById<T>(List<T>? list, int? id, int? Function(T) idOf) {
    if (list == null || id == null) return null;
    for (final T row in list) {
      if (idOf(row) == id) return row;
    }
    return null;
  }

  void showTipsField(){
    _canShowTipsField = !_canShowTipsField;
    update();
  }

  Future<void> addTips(double tips) async {
    _tips = tips;
    update();
  }

  void toggleDmTipSave() {
    _isDmTipSave = !_isDmTipSave;
    update();
  }

  void setCountryCode(String code, bool isSender) {
    if(isSender) {
      _senderCountryCode = code;
    } else {
      _receiverCountryCode = code;
    }
  }

  void selectOfflineBank(int index){
    _selectedOfflineBankIndex = index;
    update();
  }

  void changeDigitalPaymentName(String name){
    _digitalPaymentName = name;
    update();
  }

  void toggleTerms() {
    _acceptTerms = !_acceptTerms;
    update();
  }

  Future<void> getParcelCategoryList() async {
    List<ParcelCategoryModel>? categoryModelList = await parcelServiceInterface.getParcelCategory();
    if(categoryModelList != null) {
      _parcelCategoryList = [];
      _parcelCategoryList!.addAll(categoryModelList);
    }
    update();
  }

  /// Loads the weight bands and dimension classes this `(zone, module)` prices by.
  ///
  /// Both are fetched together because the two switches are independent and a
  /// screen needs to know about both before it can decide what to draw. The zone
  /// is the sender's — a delivery rule is looked up for exactly one zone, so the
  /// caller resolves it with [ZoneModuleHelper] rather than passing the address's
  /// first overlapping zone (it is what `senderZoneId` posts at placement).
  ///
  /// An existing pick is re-validated rather than cleared up front: this is fired
  /// un-awaited from `initState`, and clearing eagerly silently discards a pick
  /// the customer already made — the quote would then be priced without that
  /// band. See [_survivingPick] for exactly what does and does not drop one, and
  /// [clearTierSelections] for the separate question of starting a screen empty.
  Future<void> loadParcelTiers({required int zoneId, int? moduleId}) async {
    final int? previousWeightId = _selectedWeightId;
    final int? previousDimensionId = _selectedDimensionId;

    final List<dynamic> tiers = await Future.wait(<Future<dynamic>>[
      parcelServiceInterface.getParcelWeightList(zoneId: zoneId, moduleId: moduleId),
      parcelServiceInterface.getParcelDimensionList(zoneId: zoneId, moduleId: moduleId),
    ]);
    final ParcelTierListModel<ParcelWeightModel>? weight = tiers[0] as ParcelTierListModel<ParcelWeightModel>?;
    final ParcelTierListModel<ParcelDimensionModel>? dimension = tiers[1] as ParcelTierListModel<ParcelDimensionModel>?;

    // Assigned only when the request answered. Overwriting with null on a failure
    // destroyed a list that was still correct, and the screens read the *list* to
    // decide what to draw: the review screen reloads these on entry, so one
    // dropped request left the customer coming back to a set-location screen with
    // no weight, no size and no way to edit either — while the picks themselves,
    // which [_survivingPick] deliberately keeps, were still set underneath.
    if (weight != null) _weightTier = weight;
    if (dimension != null) _dimensionTier = dimension;

    _selectedWeightId = _survivingPick(_weightTier, previousWeightId, (ParcelWeightModel w) => w.id);
    _selectedDimensionId = _survivingPick(_dimensionTier, previousDimensionId, (ParcelDimensionModel d) => d.id);

    update();
  }

  /// A pick made on this screen, kept unless this zone's bands prove it wrong.
  ///
  /// This is about a *reload* — an edited sender address moving the parcel to a
  /// different zone, or a refetch — not about arriving at the screen. Entry
  /// starts with nothing chosen, via [clearTierSelections]; from then on, what
  /// the customer picked stands until something contradicts it.
  ///
  /// Only one thing does: a real list of bands that does not contain the id,
  /// which means it belongs to some other zone's bands. Everything else leaves
  /// it standing —
  ///
  /// - **no answer at all** ([tier] is null) is a failed or dropped request.
  ///   Absence of evidence is not evidence against the pick, and discarding it
  ///   here made a flaky connection look like the app forgetting a choice the
  ///   customer had just made.
  /// - **a tier this zone does not price by** has nothing to contradict. An id
  ///   posted at a switched-off tier costs nothing — the engine re-checks the
  ///   switch — so an address edit that passes through such a zone does not cost
  ///   the customer their pick.
  static int? _survivingPick<T>(ParcelTierListModel<T>? tier, int? id, int? Function(T) idOf) {
    if (id == null) return null;
    if (tier == null || !tier.requiresSelection) return id;
    return tier.data.any((T row) => idOf(row) == id) ? id : null;
  }

  // Carries the picks past ParcelLocationScreen's entry clear, once.
  int? _pendingWeightId;
  int? _pendingDimensionId;

  void holdTierSelectionForNextEntry() {
    _pendingWeightId = _selectedWeightId;
    _pendingDimensionId = _selectedDimensionId;
  }

  void consumeHeldTierSelection({bool notify = true}) {
    _selectedWeightId = _pendingWeightId;
    _selectedDimensionId = _pendingDimensionId;
    _pendingWeightId = null;
    _pendingDimensionId = null;
    if (notify) update();
  }

  /// Drops both tier picks, so a screen starts with nothing chosen.
  ///
  /// Called when entering the set-location screen. The controller is a singleton
  /// and would otherwise carry the previous parcel's weight and size in, showing
  /// them pre-selected for a parcel the customer has not described yet — a fee
  /// quoted against a band they never chose for *this* parcel.
  ///
  /// Deliberately *not* called when moving on to the review screen: the picks
  /// made here have to survive that step, or the order would be placed without
  /// the bands it was quoted with.
  void clearTierSelections({bool notify = true}) {
    _selectedWeightId = null;
    _selectedDimensionId = null;
    if (notify) update();
  }

  /// Records the weight pick. The fee moves with it, so the caller requotes.
  void setWeightSelection(int? id, {bool notify = true}) {
    _selectedWeightId = id;
    if (notify) update();
  }

  /// Records the dimension pick. The fee moves with it, so the caller requotes.
  void setDimensionSelection(int? id, {bool notify = true}) {
    _selectedDimensionId = id;
    if (notify) update();
  }

  /// Loads the areas or ZIP codes the sender's zone prices by.
  ///
  /// Same zone as [loadParcelTiers] and for the same reason: a delivery rule is
  /// looked up for exactly one zone, resolved by the caller with [ZoneModuleHelper]
  /// rather than the address's first overlapping zone — the same single id that
  /// `senderZoneId` posts at placement. The `zoneId` header is a list wherever
  /// zones overlap and will not do.
  ///
  /// An existing pick is re-validated rather than cleared up front, exactly as
  /// [_survivingPick] does for the tiers — this is fired un-awaited from
  /// `initState`, and clearing eagerly would silently discard a pick the
  /// customer had already made.
  Future<void> loadParcelCoverage({required int zoneId, int? moduleId}) async {
    final int? previousAreaId = _selectedAreaId;
    final int? previousZipCodeId = _selectedZipCodeId;

    final CoverageListModel? loaded =
        await parcelServiceInterface.getParcelCoverageList(zoneId: zoneId, moduleId: moduleId);

    // Kept on a failed request for the same reason as the tiers above: the
    // Area/ZIP row is drawn from this list, so overwriting it with null hid the
    // row — and with it the only way to edit the pick.
    if (loaded != null) _coverage = loaded;

    // Keep the pick only if the new list still offers it. A null response is a
    // failed request, not evidence against the pick; a rule that asks for
    // nothing has nothing to contradict.
    final bool isZip = isZipCodeWiseDelivery;
    final int? previousId = isZip ? previousZipCodeId : previousAreaId;
    final bool stillOffered = previousId != null
        && (!needsCoverageSelection
            || _coverage!.coverage.any((CoverageOption option) => option.id == previousId));

    _selectedAreaId = (stillOffered && !isZip) ? previousId : null;
    _selectedZipCodeId = (stillOffered && isZip) ? previousId : null;

    update();
  }

  /// Records the coverage pick. The fee moves with it, so the caller requotes.
  ///
  /// Sets one id and nulls the other: only one can apply, and posting `area_id`
  /// and `zip_code_id` together is not a request the endpoint accepts.
  void setCoverageSelection(int? id, {bool notify = true}) {
    if (isZipCodeWiseDelivery) {
      _selectedZipCodeId = id;
      _selectedAreaId = null;
    } else {
      _selectedAreaId = id;
      _selectedZipCodeId = null;
    }
    if (notify) update();
  }

  /// Drops the coverage pick, so a screen starts with nothing chosen. The
  /// counterpart of [clearTierSelections], called from the same place and for
  /// the same reason — this controller is a singleton.
  void clearCoverageSelection({bool notify = true}) {
    _selectedAreaId = null;
    _selectedZipCodeId = null;
    if (notify) update();
  }

  void setPickupAddress(AddressModel? addressModel, bool notify) {
    _pickupAddress = addressModel;
    if(notify) {
      update();
    }
  }

  void setDestinationAddress(AddressModel? addressModel, {bool notify = true}) {
    _destinationAddress = addressModel;
    if(notify) {
      update();
    }
  }

  void loadParcelRecentAddresses() {
    try {
      final SharedPreferences prefs = Get.find<SharedPreferences>();
      final String? raw = prefs.getString(AppConstants.parcelRecentAddresses);
      if (raw == null || raw.isEmpty) {
        _parcelRecentAddresses = [];
        return;
      }
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      _parcelRecentAddresses = decoded
          .map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Parcel recent addresses load error: $e');
      }
      _parcelRecentAddresses = [];
    }
  }

  Future<void> addParcelRecentAddress(AddressModel address) async {
    if (address.latitude == null || address.longitude == null) {
      return;
    }
    if (_parcelRecentAddresses.isEmpty) {
      loadParcelRecentAddresses();
    }
    _parcelRecentAddresses.removeWhere((a) =>
        a.latitude == address.latitude
        && a.longitude == address.longitude
        && a.address == address.address);
    _parcelRecentAddresses.insert(0, address);
    if (_parcelRecentAddresses.length > AppConstants.parcelRecentAddressesMax) {
      _parcelRecentAddresses = _parcelRecentAddresses.sublist(0, AppConstants.parcelRecentAddressesMax);
    }
    try {
      final SharedPreferences prefs = Get.find<SharedPreferences>();
      final String encoded = jsonEncode(_parcelRecentAddresses.map((a) => a.toJson()).toList());
      await prefs.setString(AppConstants.parcelRecentAddresses, encoded);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Parcel recent addresses save error: $e');
      }
    }
    update();
  }

  void setLocationFromPlace(String? placeID, String? address, bool? isPickedUp) async {
    LatLng latLng = await parcelServiceInterface.getPlaceDetails(placeID);
    await _processAddressAndAction(latLng, address);
  }

  Future<void> _processAddressAndAction(LatLng latLng, String? address) async {
    AddressModel address0 = AddressModel(
      address: address, addressType: 'others', latitude: latLng.latitude.toString(),
      longitude: latLng.longitude.toString(),
      contactPersonName: AddressHelper.getUserAddressFromSharedPref()!.contactPersonName,
      contactPersonNumber: AddressHelper.getUserAddressFromSharedPref()!.contactPersonNumber,
    );
    ZoneResponseModel response0 = await Get.find<LocationController>().getZone(address0.latitude, address0.longitude, false);
    if (response0.isSuccess) {
      bool inZone = false;
      for(int zoneId in AddressHelper.getUserAddressFromSharedPref()!.zoneIds!) {
        if(response0.zoneIds.contains(zoneId)) {
          inZone = true;
          break;
        }
      }
      if(inZone) {
        address0.zoneId =  response0.zoneIds[0];
        address0.zoneIds = [];
        address0.zoneIds!.addAll(response0.zoneIds);
        address0.zoneData = [];
        address0.zoneData!.addAll(response0.zoneData);
        if(isPickedUp!) {
          setPickupAddress(address0, true);
        }else {
          setDestinationAddress(address0);
        }
      }else {
        showCustomSnackBar('your_selected_location_is_from_different_zone_store'.tr);
      }
    } else {
      showCustomSnackBar(response0.message);
    }

  }

  Future<void> getWhyChooseDetails({DataSourceEnum source = DataSourceEnum.local}) async {
    if(source == DataSourceEnum.local) {
      _whyChooseDetails = await parcelServiceInterface.getWhyChooseDetails(source: source);
      update();
      getWhyChooseDetails(source: DataSourceEnum.client);
    } else {
      _whyChooseDetails = await parcelServiceInterface.getWhyChooseDetails(source: source);
      update();
    }
  }

  Future<void> getVideoContentDetails({DataSourceEnum source = DataSourceEnum.local}) async {
    if(source == DataSourceEnum.local) {
      _videoContentDetails = await parcelServiceInterface.getVideoContentDetails(source: source);
      update();
      getVideoContentDetails(source: DataSourceEnum.client);
    } else {
      _videoContentDetails = await parcelServiceInterface.getVideoContentDetails(source: source);
      update();
    }
  }

  void setIsPickedUp(bool? isPickedUp, bool notify) {
    _isPickedUp = isPickedUp;
    if(notify) {
      update();
    }
  }

  void setIsSender(bool sender, bool notify) {
    _isSender = sender;
    if(notify) {
      update();
    }
  }

  Future<void> getDistance(AddressModel pickedUpAddress, AddressModel destinationAddress) async {
    _distance = -1;
    _distance = await Get.find<CheckoutController>().getDistanceInKM(
      LatLng(double.parse(pickedUpAddress.latitude!), double.parse(pickedUpAddress.longitude!)),
      LatLng(double.parse(destinationAddress.latitude!), double.parse(destinationAddress.longitude!)),
    );

    _extraCharge = Get.find<CheckoutController>().extraCharge;
    // Read from the same call as the distance, so the two always describe the
    // same measured route. Null whenever the routing API did not answer and the
    // distance fell back to a straight line.
    _deliveryDuration = Get.find<CheckoutController>().deliveryDuration;

    update();
  }

  /// Seconds `config/distance-api` estimated for the leg, posted as
  /// `delivery_duration` at placement. Rounded there, kept exact here.
  double? _deliveryDuration;
  double? get deliveryDuration => _deliveryDuration;

  /// The value `place_order` takes — whole seconds, or null when the route was
  /// never measured.
  int? get deliveryDurationInSeconds => _deliveryDuration?.round();

  /// The delivery charge to show, and the one the order will be charged.
  ///
  /// A parcel fee is `base + category + weight + dimension`, where `base` comes
  /// from the zone's active delivery rule (area / zip / distance / fixed). The
  /// client cannot see that rule, so it cannot compute the fee — only
  /// `checkout-summary`, priced by the same methods `place_order` calls, can.
  /// Wherever it has answered it is authoritative.
  ///
  /// [calculateDeliveryCharge] remains the fallback for the two moments the quote
  /// cannot cover: before the first one lands, and when the call fails.
  ///
  /// Returns the **gross** fee. `delivery_charge` is already net of the Pro
  /// saving, but every caller here treats the charge as gross and subtracts the
  /// Pro line itself — so `before_pro_discount` is taken, which the API
  /// guarantees equals `delivery_charge` when no Pro applied. Taking the net
  /// figure would double-count the saving.
  double deliveryCharge(ParcelCategoryModel category, {double? surgePrice, String? surgePriceType}) {
    final CheckoutSummaryDelivery? summaryDelivery = Get.find<CheckoutController>().checkoutSummary?.delivery;
    final double? quoted = summaryDelivery?.deliveryChargeBeforeProDiscount ?? summaryDelivery?.deliveryCharge;
    if (quoted != null) return PriceConverter.toFixed(quoted);
    if (!canEstimateClientSide) return 0;
    return calculateDeliveryCharge(category, surgePrice: surgePrice, surgePriceType: surgePriceType);
  }

  /// Whether the client-side per-km estimate can stand in for the quote at all.
  ///
  /// [calculateDeliveryCharge] models the superseded `distance × per-km` rule. A
  /// zone that prices by area or ZIP does not charge by distance, so there the
  /// estimate is not a rough figure — it is a different rule's answer, and the
  /// distance still resolves, so nothing else would catch it. The fee must come
  /// from the quote in that case; until it lands the row reads "calculating".
  bool get canEstimateClientSide => !needsCoverageSelection;

  /// Whether a fee can be rendered at all — an answered quote, or a zone the
  /// client estimate is valid for with its inputs resolved.
  bool get hasRenderableDeliveryCharge =>
      Get.find<CheckoutController>().checkoutSummary?.delivery != null
      || (canEstimateClientSide && _distance != -1 && _extraCharge != null);

  /// Whether there is no fee to show yet, so the row must read "calculating".
  ///
  /// **Not the same question as "is the distance resolved".** The fee used to be
  /// distance × per-km, so gating the view on the distance was the same test;
  /// it no longer is. A zone whose delivery rule is fixed, area-wise or ZIP-wise
  /// quotes a fee without a distance ever being resolved, and gating on the
  /// distance there leaves the customer on "calculating" forever with a priced
  /// order underneath it.
  ///
  /// A quote in flight is pending. An answered quote is never pending — it *is*
  /// the fee. Only with no quote at all does the client fallback apply, and that
  /// one genuinely does need a distance.
  bool get isDeliveryChargePending {
    final CheckoutController checkoutController = Get.find<CheckoutController>();
    // An answered quote is checked *first*, so a refresh does not blank a figure
    // that is already on screen. Every address, category and tier change fires a
    // new quote, and flipping the summary back to "calculating" each time made
    // the panel look broken while the previous, still-valid numbers were sitting
    // right there.
    if (checkoutController.checkoutSummary?.delivery != null) return false;
    if (checkoutController.summaryLoading) return true;
    // Nothing has been quoted and this zone cannot be estimated client-side, so
    // there is genuinely no fee to show yet — see [canEstimateClientSide].
    if (!canEstimateClientSide) return true;
    return _distance == -1 || _extraCharge == null;
  }

  /// The superseded per-km estimate — distance × per-km, floored at the minimum
  /// shipping charge, plus the extra charge and optional surge.
  ///
  /// This is the *old* pricing model and is no longer how a parcel is charged.
  /// Kept only as the fallback behind [deliveryCharge], so the screen shows a
  /// figure rather than a blank while the quote is in flight.
  double calculateDeliveryCharge(ParcelCategoryModel category, {double? surgePrice, String? surgePriceType}) {
    double charge = 0;
    if (_distance != -1 && _extraCharge != null) {
      final config = Get.find<SplashController>().configModel!;
      final double perKmCharge = (category.parcelPerKmShippingCharge ?? 0) > 0
          ? category.parcelPerKmShippingCharge! : config.parcelPerKmShippingCharge!;
      final double minimumCharge = (category.parcelMinimumShippingCharge ?? 0) > 0
          ? category.parcelMinimumShippingCharge! : config.parcelMinimumShippingCharge!;
      charge = _distance! * perKmCharge;
      if (charge < minimumCharge) {
        charge = minimumCharge;
      }
      charge = charge + _extraCharge!;
      if (surgePrice != null && surgePrice > 0) {
        charge = surgePriceType == 'percent' ? charge + (charge * (surgePrice / 100)) : charge + surgePrice;
      }
    }
    return PriceConverter.toFixed(charge);
  }

  // Parcel has no item subtotal, so the Pro discount applies on the delivery charge (the parcel order amount).
  double calculateProDiscount(double charge, ProActiveBenefit? benefit) {
    if (benefit == null || benefit.type != ProBenefitType.discount || charge <= 0) return 0;
    final bool meetsMinOrder = benefit.minOrderStatus != true || charge >= (benefit.minOrderAmount ?? 0);
    if (!meetsMinOrder) return 0;
    double proDiscount = charge * ((benefit.percentage ?? 0) / 100);
    if (benefit.maxAmount != null && benefit.maxAmount! > 0 && proDiscount > benefit.maxAmount!) {
      proDiscount = benefit.maxAmount!;
    }
    if (proDiscount > charge) proDiscount = charge;
    return PriceConverter.toFixed(proDiscount);
  }

  double calculateProDeliveryDiscount(double charge, ProActiveBenefit? benefit) {
    if (benefit == null || benefit.type != ProBenefitType.deliveryFee || charge <= 0) return 0;
    final bool meetsMinOrder = benefit.minOrderStatus != true || charge >= (benefit.minOrderAmount ?? 0);
    if (!meetsMinOrder) return 0;
    if (benefit.offerType == ProOfferType.fullFree) return PriceConverter.toFixed(charge);
    return PriceConverter.toFixed(charge * ((benefit.chargeDiscountPercentage ?? 0) / 100));
  }

  ParcelBill calculateBill(ParcelCategoryModel category, {double? surgePrice, String? surgePriceType}) {
    final config = Get.find<SplashController>().configModel!;
    final CheckoutController checkoutController = Get.find<CheckoutController>();
    final double additionalCharge = (config.additionalChargeStatus ?? false) ? (config.additionCharge ?? 0) : 0;

    final CheckoutSummaryDelivery? summaryDelivery = checkoutController.checkoutSummary?.delivery;
    final CheckoutSummaryPro? summaryPro = checkoutController.checkoutSummary?.pro;

    final CheckoutSummaryTax? summaryTax = checkoutController.checkoutSummary?.tax;
    // Only the quote can price this: the rate and the fee it applies to are both
    // worked out server-side.
    final double tax = summaryTax?.taxAmount ?? 0;
    final bool taxIncluded = summaryTax?.isTaxIncluded ?? false;

    double charge = 0;
    double proDiscount = 0;
    double proDeliveryDiscount = 0;
    double total = 0;

    // A quote prices the parcel without needing a distance; the client fallback
    // cannot, so it stays gated on one being resolved — and on the zone being
    // one the per-km rule actually applies to.
    if (hasRenderableDeliveryCharge) {
      charge = deliveryCharge(category, surgePrice: surgePrice, surgePriceType: surgePriceType);
      // An included tax is already inside the fee; only one charged on top is added.
      total = charge + _tips + additionalCharge + (taxIncluded ? 0 : tax);

      final bool isPro = AuthHelper.isLoggedIn() && (Get.find<ProfileController>().userInfoModel?.proStatus ?? false);
      if (summaryDelivery != null) {
        // The server recomputes what the membership was actually worth on this
        // order rather than applying the notional percentage, so it wins where
        // present. Paired with the gross fee above, "gross minus saving" holds.
        proDiscount = summaryPro?.discount ?? 0;
        proDeliveryDiscount = summaryDelivery.proCustomerSavings ?? 0;
        total = total - proDiscount - proDeliveryDiscount;
      } else if (isPro) {
        final ProActiveBenefit? benefit = Get.find<ProController>().activeOfferModel?.benefit;
        proDiscount = calculateProDiscount(charge, benefit);
        proDeliveryDiscount = calculateProDeliveryDiscount(charge, benefit);
        total = total - proDiscount - proDeliveryDiscount;
      }
    }

    return ParcelBill(
      charge: charge, dmTips: _tips, additionalCharge: additionalCharge,
      proDiscount: proDiscount, proDeliveryDiscount: proDeliveryDiscount,
      tax: tax, taxIncluded: taxIncluded, total: total,
    );
  }

  /// Quotes the parcel — delivery, surge and Pro — in one call.
  ///
  /// Replaces the old `get-Tax` round trip: the fee itself now comes back here
  /// too, because `base + category + weight + dimension` is only computable
  /// server-side. Refire it whenever anything the fee moves with changes —
  /// category, weight, dimension, either address, or the distance. The
  /// signature check inside `getCheckoutSummary` swallows the no-op requotes,
  /// so callers do not have to be careful about firing it too often.
  ///
  /// `receiver_details` is required for `order_type=parcel`: the quote reads the
  /// receiver's zone out of it, and its absence answers 500 rather than naming
  /// what was missing.
  Future<void> fetchParcelSummary(ParcelCategoryModel category, {bool force = false}) async {
    final AddressModel? pickup = _pickupAddress;
    final AddressModel? destination = _destinationAddress;
    if (pickup == null || destination == null) return;

    final CheckoutSummaryBodyModel body = CheckoutSummaryBodyModel(
      orderType: 'parcel',
      // Parcel has no basket; the fee is the order amount. Seeded with the client
      // estimate so free-delivery and Pro minimums have something to measure
      // against — the server prices the fee itself regardless.
      orderAmount: calculateDeliveryCharge(category),
      distance: _distance == -1 ? null : _distance,
      latitude: pickup.latitude,
      longitude: pickup.longitude,
      parcelCategoryId: category.id,
      weightId: _selectedWeightId,
      dimensionId: _selectedDimensionId,
      // The same ids `place_order` posts. The fee moves with the pick, so
      // sending it to only one of the two is how the quote and the charge come
      // apart.
      areaId: _selectedAreaId,
      zipCodeId: _selectedZipCodeId,
      receiverDetails: destination,
      guestId: AuthHelper.isGuestLoggedIn() ? AuthHelper.getGuestId() : null,
    );
    await Get.find<CheckoutController>().getCheckoutSummary(body, force: force);
    // The quote lands in CheckoutController, so it notifies *that* controller's
    // builders. The parcel screens are built inside `GetBuilder<ParcelController>`,
    // which would otherwise keep painting the fallback estimate after the real
    // fee had arrived.
    update();
  }

  void setPayerIndex(int index, bool notify) {
    _payerIndex = index;
    if(_payerIndex == 1) {
      _paymentIndex = 0;
    }
    if(notify) {
      update();
    }
  }

  void setPaymentIndex(int index, bool notify) {
    _paymentIndex = index;
    if(notify) {
      update();
    }
  }

  void startLoader(bool isEnable, {bool canUpdate = true}) {
    _isLoading = isEnable;
    if(canUpdate) {
      update();
    }
  }

  Future<void> getParcelInstruction() async {
    _parcelInstructionList = null;
    _parcelInstructionList = await parcelServiceInterface.getParcelInstruction(1);
    update();
  }

  void setInstructionSelectedIndex(int index, {bool notify = true}) {
    // If the same index is tapped again → unselect
    if (_instructionSelectedIndex == index) {
      _instructionSelectedIndex = -1;
    } else {
      _instructionSelectedIndex = index;
    }

    if (notify) {
      update();
    }
  }

  void setCustomNoteController(String customNote, {bool notify = true}) {
    _customNoteController.text = customNote;
    if(notify) {
      update();
    }
  }

  void setCustomNote(String? customNoteText) {
    if (customNoteText != null && customNoteText.isNotEmpty) {
      _customNote = customNoteText;
      update();
    }else {
      _customNote = _customNoteController.text;
    }
    if(customNoteText == null) {
      update();
    }
  }

  void setSelectedIndex(int? index) {
    if(index != null) {
      _selectedIndexNote = index;
    }else{
      _selectedIndexNote = _instructionSelectedIndex;
    }
    if(index == null) {
      update();
    }
  }

  Future<void> getOfflineMethodList()async {
    _offlineMethodList = null;
    _offlineMethodList = await parcelServiceInterface.getOfflineMethodList();
    update();
  }

  Future<void> getDmTipMostTapped()async {
    _mostDmTipAmount = await parcelServiceInterface.getDmTipMostTapped();
    update();
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

  Future<String> placeOrder(PlaceOrderBodyModel placeOrderBody, int? zoneID, double amount, double? maximumCodOrderAmount, bool fromCart, bool isCashOnDeliveryActive, {bool forParcel = false, bool isOfflinePay = false}) async {
    _isLoading = true;
    update();
    String orderID = '';
    Response response = await parcelServiceInterface.placeOrder(placeOrderBody);
    _isLoading = false;
    // Any 2xx is a placed order. Every documented create in this API answers `201`
    // (`identical_code: default_store_201`), and matching only 200 sent a successfully
    // placed order down the failure branch — which shows a snackbar and never calls
    // parcelCallback, so no success screen.
    if (ApiClient.isSuccessCode(response.statusCode)) {
      final Map<String, dynamic> placed = response.body is Map<String, dynamic>
          ? response.body as Map<String, dynamic>
          : const <String, dynamic>{};
      // The envelope's `message` is lifted onto `statusText` when `content` is
      // unwrapped, so a body-level `message` is no longer guaranteed.
      String? message = placed['message'] ?? response.statusText;
      orderID = placed['order_id']?.toString() ?? '';
      // `user_id` only comes back when the API created an account for a guest, so it is
      // absent on an ordinary logged-in order. Assigning it into a non-nullable `int`
      // threw a TypeError right here — after the order had been created server-side but
      // before parcelCallback could redirect, which is exactly "the order went through
      // but nothing happened". It is optional the whole way down: parcelCallback,
      // RouteHelper.getPaymentRoute and the route parser all take `int?`.
      final int? createUserId = JsonReader.toInt(placed['user_id']);

      if(forParcel && _destinationAddress != null) {
        await addParcelRecentAddress(_destinationAddress!);
      }

      if(!isOfflinePay) {
        parcelCallback(true, message, orderID, zoneID, amount, maximumCodOrderAmount, isCashOnDeliveryActive, placeOrderBody.contactPersonNumber, createUserId: createUserId);
      } else {
        Get.offNamed(RouteHelper.getOfflinePaymentScreen(
          zoneId: zoneID, total: amount, orderId: orderID, contactNumber: placeOrderBody.contactPersonNumber??'',
          maxCodOrderAmount: maximumCodOrderAmount, fromCart: false, isCodActive: isCashOnDeliveryActive, forParcel: true,
        ));
      }
      if (kDebugMode) {
        print('-------- Order placed successfully $orderID ----------');
      }
    } else {
      if(!isOfflinePay) {
        parcelCallback(false, response.statusText, '-1', zoneID, amount, maximumCodOrderAmount, isCashOnDeliveryActive, placeOrderBody.contactPersonNumber);
      } else {
        showCustomSnackBar(response.statusText);
      }
    }
    update();

    return orderID;
  }

  Future<void> parcelCallback(bool isSuccess, String? message, String orderID, int? zoneID, double orderAmount, double? maxCodAmount, bool isCashOnDeliveryActive, String? contactNumber, {int? createUserId}) async {
    Get.find<ParcelController>().startLoader(false);
    if(isSuccess) {
      if(isDmTipSave){
        Get.find<AuthController>().saveDmTipIndex(PriceConverter.tipToSave(selectedTips));
      }
      Get.find<CheckoutController>().setGuestAddress(null);
      if(Get.find<ParcelController>().paymentIndex == 2) {
        if(GetPlatform.isWeb) {
          // Get.back();
          await Get.find<AuthController>().saveGuestNumber(contactNumber ?? '');
          String? hostname = html.window.location.hostname;
          String protocol = html.window.location.protocol;
          String selectedUrl = '${AppConstants.baseUrl}/payment-mobile?order_id=$orderID&&customer_id=${Get.find<ProfileController>().userInfoModel?.id ?? (Get.find<CheckoutController>().isCreateAccount ? createUserId : AuthHelper.getGuestId())}'
              '&payment_method=${Get.find<ParcelController>().digitalPaymentName}&payment_platform=web&&callback=$protocol//$hostname${RouteHelper.orderSuccess}?id=$orderID&status=';
          html.window.open(selectedUrl,"_self");
        } else{
          Get.offNamed(RouteHelper.getPaymentRoute(
            orderID, Get.find<ProfileController>().userInfoModel?.id ?? 0, 'parcel', orderAmount, isCashOnDeliveryActive,
            Get.find<ParcelController>().digitalPaymentName, guestId: AuthHelper.getGuestId(),
            contactNumber: contactNumber, createAccount: Get.find<CheckoutController>().isCreateAccount, createUserId: createUserId,
          ));
        }
      }else {
        Get.offNamed(RouteHelper.getOrderSuccessRoute(orderID, contactNumber, createAccount: Get.find<CheckoutController>().isCreateAccount));
      }
      updateTips(PriceConverter.noTipIndex, notify: false);
    }else {
      showCustomSnackBar(message);
    }
  }

  Future<void> getParcelCancellationReasons({required bool isBeforePickup}) async {
    _parcelCancellationReasons = null;
    ParcelCancellationReasonsModel? parcelCancellationReasons = await parcelServiceInterface.getParcelCancellationReasons(isBeforePickup: isBeforePickup);
    if(parcelCancellationReasons != null) {
      _parcelCancellationReasons = [];
      _parcelCancellationReasons!.addAll(parcelCancellationReasons.data!);
    }
    update();
  }

}

class ParcelBill {
  final double charge;
  final double dmTips;
  final double additionalCharge;
  final double proDiscount;
  final double proDeliveryDiscount;

  /// The quote's tax amount. Inside [total] only when it is charged on top.
  final double tax;

  /// True when the amount above is already inside the fee, so the bill names it
  /// beside the total instead of listing it as a charge of its own.
  final bool taxIncluded;

  final double total;

  const ParcelBill({
    required this.charge, required this.dmTips, required this.additionalCharge, required this.proDiscount,
    required this.proDeliveryDiscount, required this.tax, required this.taxIncluded, required this.total,
  });
}

// SUMMARY
// Parcel state and pricing. Holds the picked category, addresses, weight and dimension
// tiers, tips, payer and payment choice, quotes the parcel against the server summary,
// and builds the bill — delivery fee, tips, additional charge and Pro savings — that the
// parcel screens show and place an order with.
