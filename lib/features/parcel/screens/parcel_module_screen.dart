import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/parcel/controllers/parcel_controller.dart';
import 'package:sixam_mart/features/dashboard/widgets/sliver_gap.dart';
import 'package:sixam_mart/features/parcel/screens/parcel_category_new_screen.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/features/home/widgets/views/promotional_banner_view.dart';
import 'package:sliver_tools/sliver_tools.dart';

class ParcelModuleScreen extends StatefulWidget {
  /// Height of the search bar this screen pins itself, inside the scroll view.
  ///
  /// Unlike the store modules, parcel does not hand [searchHeaderKey] to a
  /// [SearchAndQuickFilterWidget], so `MainScreen`'s shared pinned-search overlay
  /// never activates here and has no height to measure. `MainScreen` reads this
  /// constant instead, to keep the back-to-top button clear of the bar.
  static const double pinnedHeaderHeight = 70.0;

  final Key searchHeaderKey;
  final Key exploreRestaurantKey;
  const ParcelModuleScreen({super.key, required this.searchHeaderKey, required this.exploreRestaurantKey});

  @override
  State<ParcelModuleScreen> createState() => _ParcelModuleScreenState();
}

class _ParcelModuleScreenState extends State<ParcelModuleScreen> {
  @override
  void initState() {
    super.initState();
    if(AuthHelper.isLoggedIn()) {
      Get.find<ParcelController>().loadParcelRecentAddresses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [

      sliverGepY(value: Dimensions.paddingSizeDefault),
      const SliverToBoxAdapter(child: _ParcelDeliverToHeader()),

      const SliverPersistentHeader(
        pinned: true,
        delegate: _ParcelDeliverySearchBarDelegate(),
      ),

      const SliverToBoxAdapter(child: _ParcelRecentAddressChips()),

      // Section: promotional banner
      // const SliverToBoxAdapter(child: _ParcelPromotionalBannerSection()),

      // category
      const SliverToBoxAdapter(child: ParcelCategoryNewScreen()),
      sliverGepY(value: Dimensions.paddingSizeDefault),
    ]);
  }
}

/// Promotional banner plus the gap that separates it from the address chips
/// above. Both live in one widget so the gap collapses with the banner: this
/// module has no banner of its own to fall back on, so a module configured
/// without promotional artwork would otherwise leave an empty band between the
/// chips and the categories.
class _ParcelPromotionalBannerSection extends StatelessWidget {
  const _ParcelPromotionalBannerSection();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BannerController>(builder: (bannerController) {
      if(!PromotionalBannerView.hasContent(bannerController)) {
        return const SizedBox.shrink();
      }
      return const Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(height: Dimensions.paddingSizeDefault),
        PromotionalBannerView(),
      ]);
    });
  }
}

class _ParcelDeliverToHeader extends StatelessWidget {
  const _ParcelDeliverToHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: Text(
        'deliver_to'.tr,
        style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
      ),
    );
  }
}

class _ParcelDeliverySearchBarDelegate extends SliverPersistentHeaderDelegate {
  const _ParcelDeliverySearchBarDelegate();

  // top(10) + searchbar(50) + bottom(10) = 70
  static const double _height = ParcelModuleScreen.pinnedHeaderHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeSmall,
      ),
      child: const _ParcelDeliverySearchBar(),
    );
  }

  @override double get maxExtent => _height;
  @override double get minExtent => _height;
  @override bool shouldRebuild(_ParcelDeliverySearchBarDelegate old) => false;
}

void _openParcelLocationFlow() {
  if (AddressHelper.getUserAddressFromSharedPref() == null) {
    Get.find<LocationController>().navigateToLocationScreen('home', canRoute: true);
    return;
  }
  final ParcelController parcelController = Get.find<ParcelController>();
  if(parcelController.parcelCategoryList == null) {
    parcelController.getParcelCategoryList().then((_) {
      if(parcelController.parcelCategoryList != null) {
        Get.toNamed(RouteHelper.getParcelLocationRoute(parcelController.parcelCategoryList![0]));
      }
    });
    return;
  }
  Get.toNamed(RouteHelper.getParcelLocationRoute(parcelController.parcelCategoryList![0]));
}

class _ParcelDeliverySearchBar extends StatelessWidget {
  const _ParcelDeliverySearchBar();

  @override
  Widget build(BuildContext context) {
    final Color borderColor = Theme.of(context).disabledColor.withValues(alpha: 0.18);
    final Color backgroundColor = Theme.of(context).disabledColor.withValues(alpha: 0.15);

    return GestureDetector(
      onTap: _openParcelLocationFlow,
      child: Container(
        height: 50,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeSmall,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge + Dimensions.radiusDefault),
          border: Border.all(color: borderColor, width: 0.1),
        ),
        child: Row(children: [
          Expanded(
            child: Text(
              'search_delivery_address'.tr,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).disabledColor,
              ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          Icon(
            CupertinoIcons.search,
            size: 20,
            color: Theme.of(context).textTheme.bodyLarge!.color,
          ),
        ]),
      ),
    );
  }
}

class _ParcelRecentAddressChips extends StatelessWidget {
  const _ParcelRecentAddressChips();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ParcelController>(builder: (parcelController) {
      final List<AddressModel> addresses = parcelController.parcelRecentAddresses;
      if(addresses.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
        child: SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            itemCount: addresses.length,
            separatorBuilder: (_, _) => const SizedBox(width: Dimensions.paddingSizeSmall),
            itemBuilder: (context, index) => _ParcelAddressChip(address: addresses[index]),
          ),
        ),
      );
    });
  }
}

class _ParcelAddressChip extends StatelessWidget {
  final AddressModel address;
  const _ParcelAddressChip({required this.address});

  IconData get _icon {
    switch(address.addressType?.toLowerCase()) {
      case 'home': return Icons.home_outlined;
      case 'office': return Icons.work_outline_rounded;
      default:      return Icons.location_on_outlined;
    }
  }

  String get _shortLabel {
    final String raw = (address.address ?? '').trim();
    if(raw.isEmpty) return '';
    return raw.split(',').first.trim();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Get.find<ParcelController>().setPendingDestination(address);
        _openParcelLocationFlow();
      },
      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.2)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(_icon, size: 14, color: Theme.of(context).disabledColor),
          const SizedBox(width: 4),
          Text(
            _shortLabel,
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ]),
      ),
    );
  }
}


// await Get.find<ParcelController>().getParcelCategoryList();
// await Get.find<BannerController>().getParcelOtherBannerList(true);
// await Get.find<ParcelController>().getWhyChooseDetails();
// await Get.find<ParcelController>().getVideoContentDetails();
