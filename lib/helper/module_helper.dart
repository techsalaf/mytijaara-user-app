import 'package:get/get.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/common/models/config_model.dart';
import 'package:sixam_mart/util/app_constants.dart';

class ModuleHelper {

  static ModuleModel? getModule() {
    return Get.find<SplashController>().module;
  }

  static bool isActiveServiceModule() {
    return (Get.find<SplashController>().moduleList ?? []).any((module) => module.moduleType == AppConstants.service);
  }

  static ModuleModel? getCacheModule() {
    return Get.find<SplashController>().getCacheModule();
  }

  static Module getModuleConfig(String? moduleType) {
    return Get.find<SplashController>().getModuleConfig(moduleType);
  }

  static String proMinSpendLabel({String? moduleType, required String fallbackKey}) {
    final String? type = moduleType ?? getModule()?.moduleType ?? getCacheModule()?.moduleType;
    switch (type) {
      case AppConstants.parcel:
        return 'min_delivery_fee'.tr;
      case AppConstants.taxi:
        return 'min_rental_trip'.tr;
      case AppConstants.ride:
        return 'min_ride'.tr;
      case AppConstants.service:
        return 'min_booking'.tr;
      default:
        return fallbackKey.tr;
    }
  }

  /// True when the module books rather than orders — service copy reads
  /// "booking" wherever store copy reads "order". Single source of truth so
  /// every pro/checkout surface words itself the same way.
  static bool isBookingModule({String? moduleType}) =>
      (moduleType ?? getModule()?.moduleType ?? getCacheModule()?.moduleType) == AppConstants.service;

  static ModuleModel? getModuleByType(String moduleType) {
    final List<ModuleModel> modules = Get.find<SplashController>().moduleList ?? [];
    for (final ModuleModel module in modules) {
      if (module.moduleType == moduleType) {
        return module;
      }
    }
    return null;
  }

  // Single source of truth for module tab labels so every screen that lists
  // modules (dashboard tabs, my-items tabs, etc.) shows the exact same name.
  static String moduleDisplayName(String moduleType, {String? moduleName}) {
    final String? name = moduleName ?? getModuleByType(moduleType)?.moduleName;
    if (name != null && name.trim().isNotEmpty) {
      return name;
    }
    return _fallbackModuleDisplayName(moduleType);
  }

  static String _fallbackModuleDisplayName(String moduleType) {
    if (moduleType == AppConstants.food) {
      return 'Food';
    } else if (moduleType == AppConstants.grocery) {
      return 'Grocery';
    } else if (moduleType == AppConstants.ecommerce) {
      return 'Shop';
    } else if (moduleType == AppConstants.pharmacy) {
      return 'Pharmacy';
    }
    return moduleType.isNotEmpty ? moduleType : 'Module';
  }

}