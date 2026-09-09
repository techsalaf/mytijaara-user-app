import 'package:get/get.dart';
import 'package:sixam_mart/features/pro/domain/models/pro_active_offer_model.dart';
import 'package:sixam_mart/features/pro/domain/models/pro_plan_model.dart';
import 'package:sixam_mart/helper/module_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/app_constants.dart';

class ProBenefitItems {
  ProBenefitItems._();

  static List<Map<String, String>> fromPlanBenefits(PlanBenefits? benefits) {
    final List<Map<String, String>> items = [];
    if (benefits == null) return items;

    final DiscountBenefit? discount = benefits.discount;
    if (discount?.active == 1) {
      final Map<String, DiscountConfig>? modules = discount!.modules;
      if (modules != null && modules.isNotEmpty) {
        modules.forEach((moduleType, config) => items.add(_discountItem(moduleType, config)));
      } else if (discount.config != null) {
        items.add(_discountItem(null, discount.config!));
      }
    }

    if (benefits.deliveryFee?.active == 1) {
      benefits.deliveryFee!.modules?.forEach((moduleType, config) => items.add(_deliveryItem(moduleType, config)));
    }

    if (benefits.coupon?.active == true) {
      items.add({'title': 'exclusive_coupon_on_order'.tr, 'subtitle': 'unlock_exclusive_coupon_deals'.tr});
    }
    return items;
  }

  static Map<String, String> _discountItem(String? moduleType, DiscountConfig config) {
    final double pct = config.percentage ?? 0;
    final double max = config.maxAmount ?? 0;
    final String minLabel = ModuleHelper.proMinSpendLabel(moduleType: moduleType, fallbackKey: 'minimum_order_amount');
    return {
      'title': moduleType != null
          ? '${_moduleLabel(moduleType)} (${pct.toStringAsFixed(0)}%)'
          : '${'discount_on_all_orders'.tr} (${pct.toStringAsFixed(0)}%)',
      'subtitle': '${'get_up_to'.tr} ${PriceConverter.convertPrice(max)} ${'discount'.tr}${(config.minOrderStatus ?? false) ? ', $minLabel ${PriceConverter.convertPrice(config.minOrderAmount)}' : ""}',
    };
  }

  static Map<String, String> _deliveryItem(String moduleType, DeliveryFeeModuleBenefit config) {
    final String label = _moduleLabel(moduleType);
    final String minLabel = ModuleHelper.proMinSpendLabel(moduleType: moduleType, fallbackKey: 'minimum_order_amount');
    final String minSuffix = (config.minOrderStatus ?? false) ? ', $minLabel ${PriceConverter.convertPrice(config.minOrderAmount)}' : "";
    if (config.offerType == ProOfferType.partialFree) {
      final double pct = config.chargeDiscountPercentage ?? 0;
      return {
        'title': '$label - ${'discount_on_delivery_fee'.tr} (${pct.toStringAsFixed(0)}%)',
        'subtitle': '${'save_on_every_delivery'.tr}$minSuffix',
      };
    }
    return {
      'title': '$label - ${'free_delivery'.tr}',
      'subtitle': '${'enjoy_unlimited_free_deliveries'.tr}$minSuffix',
    };
  }

  static String _moduleLabel(String moduleType) {
    switch (moduleType) {
      case AppConstants.grocery: return 'grocery'.tr;
      case AppConstants.food: return 'food'.tr;
      case AppConstants.pharmacy: return 'pharmacy'.tr;
      case AppConstants.ecommerce: return 'ecommerce'.tr;
      case AppConstants.taxi: return 'rental'.tr;
      case AppConstants.ride: return 'ride_share'.tr;
      case AppConstants.parcel: return 'parcel'.tr;
      default: return moduleType.replaceAll('-', ' ').replaceAll('_', ' ').capitalizeFirst ?? moduleType;
    }
  }
}
