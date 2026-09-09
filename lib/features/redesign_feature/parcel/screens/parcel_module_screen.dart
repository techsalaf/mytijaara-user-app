import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/parcel/controllers/parcel_controller.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/sliver_gap.dart';
import 'package:sixam_mart/features/redesign_feature/parcel/screens/parcel_category_screen.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sliver_tools/sliver_tools.dart';

class ParcelModuleScreen extends StatefulWidget {
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


      // category
      const SliverToBoxAdapter(child: ParcelCategoryNewScreen()),
      sliverGepY(value: Dimensions.paddingSizeDefault),
    ]);
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
  static const double _height = 70.0;

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
