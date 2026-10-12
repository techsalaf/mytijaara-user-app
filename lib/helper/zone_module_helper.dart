import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';

/// Picks the zone, out of an address's overlapping zones, that actually runs a
/// given module.
///
/// A pickup address can sit inside several zones at once, and [AddressModel.zoneId]
/// is only the first of them — fine for a module every overlapping zone runs, but
/// a parcel rule (its weight bands, size classes, area/ZIP coverage) is looked up
/// for exactly one zone, and the first one may not be the one that runs Parcel at
/// all. This walks [AddressModel.zoneData] for the zone whose module list contains
/// [moduleId] and answers that zone's id instead.
class ZoneModuleHelper {
  ZoneModuleHelper._();

  /// Falls back to [AddressModel.zoneId] when no zone in [address]'s data lists
  /// the module — an address predating this lookup, or the single-zone case most
  /// addresses are, still resolves exactly as it did before.
  static int? resolveZoneId(AddressModel? address, {required int? moduleId}) {
    if(moduleId != null) {
      for(final ZoneData zone in address?.zoneData ?? const <ZoneData>[]) {
        for(final Modules module in zone.modules ?? const <Modules>[]) {
          if(module.id == moduleId) {
            return zone.id;
          }
        }
      }
    }
    return address?.zoneId;
  }
}

// SUMMARY
// Resolves the zone id that actually runs a given module out of an address's overlapping
// zones, instead of blindly using the first zone id the address carries. Falls back to
// the address's own zoneId when no zone in its zoneData lists the module.
