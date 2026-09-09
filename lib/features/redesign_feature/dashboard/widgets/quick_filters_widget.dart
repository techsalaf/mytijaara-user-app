import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/dashboard/screens/dashboard_screen.dart';
import 'package:sixam_mart/features/redesign_feature/home/screens/all_stores_screen.dart';
import 'package:sixam_mart/features/offer/offer_screen.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class QuickFiltersWidget extends StatelessWidget {
  final bool? isPadding;
  final List<FoodModuleQuickFilterItem> items;
  // When provided, overrides the built-in food navigation so other modules
  // (e.g. service) can own their filter taps.
  final void Function(FoodModuleQuickFilterItem item)? onItemTap;

  const QuickFiltersWidget({
    super.key,
    this.isPadding = false,
    this.onItemTap,
    this.items = const [
      FoodModuleQuickFilterItem(titleKey: 'offers', image: Images.offerImage),
      FoodModuleQuickFilterItem(titleKey: 'express_delivery', image: Images.expressDelivery),
      FoodModuleQuickFilterItem(titleKey: 'top_rated', icon: Icons.workspace_premium_rounded, color: Color(0xFFFFB800)),
      FoodModuleQuickFilterItem(titleKey: 'nearby', icon: Icons.location_on_rounded, color: Color(0xFFFF9F1A)),
    ],
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: Dimensions.paddingSizeSmall),
        itemBuilder: (context, index) {
          final FoodModuleQuickFilterItem item = items[index];
          final padding = index == 0 ? const EdgeInsets.only(left: 16)
            : index == items.length - 1 ? const EdgeInsets.only(right: 16) : EdgeInsets.zero;
          return Padding(
            padding: (isPadding ?? false) ? padding : EdgeInsets.zero,
            child: _QuickFilterCard(item: item, onTap: () => onItemTap != null ? onItemTap!(item) : _handleTap(context, item)),
          );
        },
      ),
    );
  }

  void _handleTap(BuildContext context, FoodModuleQuickFilterItem item) {
    switch(item.titleKey) {
      case 'offers':
        // Switch the dashboard to its Offers tab in place (navbar stays visible
        // and the Offers tab highlights). Fall back to pushing the screen when
        // this widget is rendered outside the dashboard.
        if (!DashboardScreenState.switchToTab(context, DashboardScreenState.offersPageIndex)) {
          Get.to(() => const OfferScreen());
        }
        break;
      case 'express_delivery':
        Get.to(() => const AllStoresScreen());
        break;
      case 'top_rated':
        Get.to(() => const AllStoresScreen(mode: AllStoresMode.topRated));
        break;
      case 'nearby':
        Get.to(() => const AllStoresScreen(mode: AllStoresMode.nearBy));
        break;
      default:
        // Other filters are tappable for visual affordance but have no action wired yet.
        break;
    }
  }
}

class _QuickFilterCard extends StatelessWidget {
  final FoodModuleQuickFilterItem item;
  final VoidCallback onTap;

  const _QuickFilterCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color borderColor = Theme.of(context).disabledColor.withValues(alpha: 0.18);
    // final Color shadowColor = Theme.of(context).disabledColor.withValues(alpha: 0.06);
    final BorderRadius radius = BorderRadius.circular(Dimensions.radiusExtraLarge + Dimensions.radiusSmall);

    return Center(
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeSmall,
              vertical: Dimensions.paddingSizeSmall - 2,
            ),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                (item.image != null)
                    ? Image.asset(item.image!, height: 14)
                    : Icon(item.icon, size: 14, color: item.color),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Text(
                  item.titleKey.tr,
                  style: robotoSemiBold.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FoodModuleQuickFilterItem {
  final String? image;
  final String titleKey;
  final IconData? icon;
  final Color? color;

  const FoodModuleQuickFilterItem({
    this.image,
    required this.titleKey,
    this.icon,
    this.color,
  });
}
