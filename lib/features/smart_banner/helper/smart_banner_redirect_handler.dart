import 'package:get/get.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/offer/offer_screen.dart';
import 'package:sixam_mart/features/smart_banner/domain/models/smart_banner_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/route_helper.dart';

class SmartBannerRedirectHandler {
  const SmartBannerRedirectHandler._();

  static void handle(SmartBanner banner) {
    switch (banner.redirectType) {
      case 'module_home':
        _handleModuleHome(banner);
        return;

      case 'store_page':
        _handleStorePage(banner);
        return;

      case 'category':
        _handleCategory(banner);
        return;

      case 'offer_page':
        Get.to(() => const OfferScreen());
        return;

      default:
        return;
    }
  }

  static void _handleModuleHome(SmartBanner banner) {
    final int? moduleId = banner.moduleId;
    if (moduleId == null) return;
    final SplashController splash = Get.find<SplashController>();
    final List<ModuleModel>? modules = splash.moduleList;
    if (modules == null || modules.isEmpty) return;
    final int index = modules.indexWhere((ModuleModel m) => m.id == moduleId);
    if (index != -1) {
      // index is 0-based in moduleList; selectModuleByTabIndex expects 1-based
      // (tab 0 = Home landing, tab 1 = first module). This mirrors what the
      // module grid cards do: selectModuleByTabIndex(index + 1).
      splash.selectModuleByTabIndex(index + 1);
    }
  }

  static void _handleStorePage(SmartBanner banner) {
    if (banner.redirectTargetId == null) {
      return;
    }
    if(Get.find<SplashController>().moduleList != null) {
      for(ModuleModel module in Get.find<SplashController>().moduleList!) {
        if(module.id == banner.moduleId) {
          Get.find<SplashController>().setModule(module);
          break;
        }
      }
    }
    Get.toNamed(RouteHelper.getStoreRoute(
      id: banner.redirectTargetId,
      page: 'store',
      slug: 'store_${banner.redirectTargetId}',
      moduleId: banner.moduleId?.toString(),
    ));
  }

  static void _handleCategory(SmartBanner banner) {
    if (banner.redirectTargetId == null) {
      return;
    }
    if(Get.find<SplashController>().moduleList != null) {
      for(ModuleModel module in Get.find<SplashController>().moduleList!) {
        if(module.id == banner.moduleId) {
          Get.find<SplashController>().setModule(module);
          break;
        }
      }
    }
    Get.toNamed(RouteHelper.getCategoryItemRoute(
      banner.redirectTargetId, banner.title ?? '',
      moduleId: banner.moduleId,
      slug: 'category_${banner.redirectTargetId}',
    ));
  }
}
