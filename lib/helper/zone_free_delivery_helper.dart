import 'package:get/get.dart';
import 'package:sixam_mart/common/models/config_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/address_helper.dart';

class ZoneFreeDeliveryStatus {
  final bool isFree;
  final double remaining;
  final double percentage;

  const ZoneFreeDeliveryStatus.free() : isFree = true, remaining = 0, percentage = 1;

  const ZoneFreeDeliveryStatus.towards({required this.remaining, required this.percentage}) : isFree = false;
}

class ZoneFreeDeliveryHelper {
  static const String _zoneAllStore = 'all_store';
  static const String _zoneOverOrderAmount = 'specific_criteria';
  static const String _adminAllStore = 'free_delivery_to_all_store';
  static const String _adminOverOrderAmount = 'free_delivery_by_order_amount';

  static ZoneFreeDeliveryStatus? progressFor({required Store? store, required double subtotal}) {
    print('ZoneFreeDeliveryHelper.progressFor: store=$store, subtotal=${store?.freeDelivery}');
    if(store == null || (store.freeDelivery ?? false)) {
      return null;
    }
    final Modules? module = moduleIn(
      AddressHelper.getUserAddressFromSharedPref()?.zoneData ?? const <ZoneData>[],
      zoneId: store.zoneId, moduleId: store.moduleId,
    );
    final ZoneFreeDelivery? setting = module?.freeDelivery;
    print('ZoneFreeDeliveryHelper.progressFor: module=$module, setting=${setting?.toJson()}');
    if(setting?.status ?? false) {
      return progressOf(setting: setting, subtotal: subtotal);
    }
    return null;
  }

  static ZoneFreeDeliveryStatus? progressOf({required ZoneFreeDelivery? setting, required double subtotal}) {
    if(!(setting?.status ?? false)) {
      return null;
    }
    return switch(setting!.type) {
      _zoneAllStore => const ZoneFreeDeliveryStatus.free(),
      _zoneOverOrderAmount => _towards(minimum: setting.minimumOrderAmount, subtotal: subtotal),
      _ => null,
    };
  }

  static ZoneFreeDeliveryStatus? _towards({required double? minimum, required double subtotal}) {
    // An amount rule with no amount is a rule that was never finished, so it promises
    // nothing rather than promising everything.
    if(minimum == null || minimum <= 0) {
      return null;
    }
    if(subtotal >= minimum) {
      return const ZoneFreeDeliveryStatus.free();
    }
    return ZoneFreeDeliveryStatus.towards(remaining: minimum - subtotal, percentage: subtotal / minimum);
  }

  // The customer's location can sit in several zones at once, so the store's own zone
  // decides which one prices its delivery, and its module which rule inside that zone.
  static Modules? moduleIn(List<ZoneData> zones, {required int? zoneId, required int? moduleId}) {
    if(zoneId == null || moduleId == null) {
      return null;
    }
    for(final ZoneData zone in zones) {
      if(zone.id != zoneId) {
        continue;
      }
      for(final Modules module in zone.modules ?? const <Modules>[]) {
        if(module.id == moduleId) {
          return module;
        }
      }
      return null;
    }
    return null;
  }
}

// SUMMARY
// Answers where a cart stands against the free delivery on offer. Reads the rule of the
// store's own module inside the store's own zone, falling back to the platform's offer
// where that zone sets none, and reports either that delivery is free or what is left to
// spend and how far along the cart is — or nothing at all when no rule is offered.
