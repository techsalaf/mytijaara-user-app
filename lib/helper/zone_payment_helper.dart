import 'package:get/get.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';

class ZonePaymentHelper {

  static bool isCashOnDeliveryActive(AddressModel? address) =>
      (_zoneOf(address)?.cashOnDelivery ?? false)
          && (Get.find<SplashController>().configModel?.cashOnDelivery ?? false);

  static bool isDigitalPaymentActive(AddressModel? address) =>
      (_zoneOf(address)?.digitalPayment ?? false)
          && (Get.find<SplashController>().configModel?.digitalPayment ?? false);

  static ZoneData? _zoneOf(AddressModel? address) {
    final List<ZoneData> zones = address?.zoneData ?? const <ZoneData>[];
    if(zones.isEmpty) {
      return null;
    }
    // The address's own zone, not the saved location's: a parcel is sent from the
    // pickup address, and its zone set need not contain the saved location's zone.
    final int? zoneId = address?.zoneId ?? AddressHelper.getUserAddressFromSharedPref()?.zoneId;
    for(final ZoneData zone in zones) {
      if(zone.id == zoneId) {
        return zone;
      }
    }
    return null;
  }
}

// SUMMARY
// Answers which payment methods an address's zone allows. Reads cash on delivery and
// digital payment from the zone the address itself sits in, each also requiring the
// matching platform config, and reports them as inactive when the address carries no
// zone data rather than throwing.
