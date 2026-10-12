import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/util/app_constants.dart';

class AddressHelper {

  /// Memoised parse of the stored address, keyed on the raw JSON string.
  ///
  /// [getUserAddressFromSharedPref] has 168 call sites, 109 of them in screens and
  /// widgets — several inside a single `build()` (the home header reads it twice
  /// per frame, the ride map section four times), each one paying a full
  /// `jsonDecode` + `AddressModel.fromJson`.
  ///
  /// The memo is keyed on the raw string rather than invalidated by hand, so *any*
  /// write to [AppConstants.userAddress] — including the `remove()` on logout in
  /// `AuthRepository` — is picked up on the next read. There is no invalidation
  /// call to forget and no way for the cache to serve a stale address.
  static String? _cachedRaw;
  static AddressModel? _cachedAddress;

  static Future<bool> saveUserAddressInSharedPref(AddressModel address, {bool isInRideModule = false}) async {
    SharedPreferences sharedPreferences = Get.find<SharedPreferences>();
    String userAddress = jsonEncode(address.toJson());
    bool isRide = false;
    try{
      isRide = Get.find<SplashController>().module != null && (Get.find<SplashController>().module!.moduleType.toString() == AppConstants.ride);
      isInRideModule = isRide;
    }catch(_) {}

    Get.find<ApiClient>().updateHeader(
      sharedPreferences.getString(AppConstants.token),
      address.zoneIds,[],
      sharedPreferences.getString(AppConstants.languageCode),
      Get.find<SplashController>().module?.id?.toString(),
      address.latitude,
      address.longitude,
      isInRideModule ? address.rideZoneId : address.zoneId,
      fromModule: isInRideModule,
    );
    // Prime the memo with the instance being persisted, so the very next read is
    // consistent with what was just written without re-parsing it.
    _cachedRaw = userAddress;
    _cachedAddress = address;
    return await sharedPreferences.setString(AppConstants.userAddress, userAddress);
  }

  static AddressModel? getUserAddressFromSharedPref() {
    SharedPreferences sharedPreferences = Get.find<SharedPreferences>();
    final String? raw = sharedPreferences.getString(AppConstants.userAddress);
    if(raw == null) {
      // Preserve the original behaviour: a missing key logged a catch and
      // returned null. Clear the memo so a later write is not shadowed.
      if(!GetPlatform.isWeb && _cachedRaw != null) {
        debugPrint('Address Catch exception : no stored address');
      }
      _cachedRaw = null;
      _cachedAddress = null;
      return null;
    }
    if(raw != _cachedRaw) {
      AddressModel? addressModel;
      try {
        addressModel = AddressModel.fromJson(jsonDecode(raw));
      }catch(e) {
        if(!GetPlatform.isWeb) {
          debugPrint('Address Catch exception : $e');
        }
      }
      _cachedAddress = addressModel;
      _cachedRaw = raw;
    }
    return _cachedAddress;
  }

  static bool clearAddressFromSharedPref() {
    SharedPreferences sharedPreferences = Get.find<SharedPreferences>();
    sharedPreferences.remove(AppConstants.userAddress);
    _cachedRaw = null;
    _cachedAddress = null;
    return true;
  }

  //getIndexByAddressId
  static int getIndexByAddressId(List<AddressModel> addressList, String addressId) {
    int index = -1;
    for(int i=0; i<addressList.length; i++) {
      if(addressList[i].id.toString() == addressId) {
        index = i;
        break;
      }
    }
    return index;
  }

}