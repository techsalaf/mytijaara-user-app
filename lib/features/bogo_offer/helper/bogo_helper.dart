import 'package:get/get.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/route_helper.dart';

class BogoHelper {
  // The bundle's store node may omit module_id; the offer's own module is the one its stores sit in.
  static int? storeModuleId(Store? store, int? offerModuleId) => store?.moduleId ?? offerModuleId;

  static Future<void> openStore(Store? store, {int? offerModuleId}) async {
    if(store == null || store.id == null) {
      return;
    }
    final SplashController splashController = Get.find<SplashController>();
    final int? moduleId = storeModuleId(store, offerModuleId);
    final ModuleModel? enteredFrom = splashController.module;

    // Every store request is filtered by the module in its header, so a store from
    // another module's tab answers empty until that module is the active one.
    bool switched = false;
    if(moduleId != null && enteredFrom?.id != moduleId) {
      switched = await splashController.activateModuleById(moduleId);
    }

    await Get.toNamed(RouteHelper.getStoreRoute(
      id: store.id, page: 'store', slug: store.slug ?? '', moduleId: moduleId?.toString(),
    ));

    // The switch belongs to the store visit alone. Left in place, the dashboard kept
    // the tab the customer entered from while every list under it came from the
    // store's module. Home is not reloaded either way: it was never refetched for the
    // store's module, so it still holds the module being restored.
    if(switched && splashController.module?.id == moduleId) {
      await splashController.setModule(enteredFrom);
    }
  }

  /// The store's distance, written out for display.
  ///
  /// 6amMart's store payload now carries a ready-made `distance_label` of its own,
  /// already in the platform's configured unit — so it is used as sent, and the
  /// local formatting below is only the fallback for a backend without one.
  static String? distanceLabel(Store? store) {
    final String? label = store?.distanceLabel;
    if(label != null) {
      return label;
    }
    final double? km = store?.distanceKm ?? (store?.distance != null && store!.distance! > 0 ? store.distance : null);
    if(km == null || km <= 0) {
      return null;
    }
    return '${km.toStringAsFixed(km < 10 ? 1 : 0)} ${'km'.tr}';
  }
}

// SUMMARY
// Shared helpers for the BOGO feature. Writes out a store's distance label, and opens an
// offer's store under the module that store belongs to, putting the module back when the
// customer leaves it.
