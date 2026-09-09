import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/widgets/paginated_list_view.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/common_widget/featured_store_card.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/sliver_gap.dart';
import 'package:sixam_mart/features/store/screens/store_screen.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sliver_tools/sliver_tools.dart';

class ExploreRestaurantSection extends StatelessWidget {
  final String? title;
  final Key exploreRestaurantKey;
  final ScrollController scrollController;
  const ExploreRestaurantSection({super.key, required this.exploreRestaurantKey, required this.scrollController, this.title});

  @override
  Widget build(BuildContext context) {
    return MultiSliver(
      children: [
        sliverPadX(child: TitleWidget(title: (title ?? 'explore_restaurant').tr)),
        SliverPersistentHeader(
          pinned: true,
          delegate: FoodModuleExploreRestaurantFilterHeaderDelegate(filterKey: exploreRestaurantKey),
        ),
        sliverPadX(child: FoodModuleExploreRestaurantsListWidget(scrollController: scrollController)),
        sliverGepY(value: Dimensions.paddingSizeExtraLarge),
      ],
    );
  }
}

class FoodModuleExploreRestaurantFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Key filterKey;

  FoodModuleExploreRestaurantFilterHeaderDelegate({required this.filterKey});

  @override
  double get minExtent => FoodModuleExploreRestaurantFilterHeaderWidget.height;

  @override
  double get maxExtent => FoodModuleExploreRestaurantFilterHeaderWidget.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return FoodModuleExploreRestaurantFilterHeaderWidget(filterKey: filterKey);
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return oldDelegate is FoodModuleExploreRestaurantFilterHeaderDelegate && oldDelegate.filterKey != filterKey;
  }
}

class FoodModuleExploreRestaurantFilterHeaderWidget extends StatelessWidget {
  static const double height = 55;
  final Key? filterKey;
  // When pinned as the bottom of the sticky stack, draws a divider + soft shadow
  // separating it from the scrolling content below.
  final bool showBottomDivider;

  const FoodModuleExploreRestaurantFilterHeaderWidget({super.key, this.filterKey, this.showBottomDivider = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: filterKey,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: showBottomDivider
            ? Border(bottom: BorderSide(color: Theme.of(context).disabledColor.withValues(alpha: 0.15), width: 1))
            : null,
        boxShadow: showBottomDivider
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))]
            : null,
      ),
      child: Center(
        child: Container(
          width: Dimensions.webMaxWidth,
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: const FoodModuleExploreRestaurantsFilterWidget(),
        ),
      ),
    );
  }
}

class FoodModuleExploreRestaurantsFilterWidget extends StatelessWidget {
  const FoodModuleExploreRestaurantsFilterWidget({super.key});

  static const List<({String type, String labelKey})> _filters = [
    (type: 'all', labelKey: 'all'),
    (type: 'newly_joined', labelKey: 'newly_joined'),
    (type: 'popular', labelKey: 'popular'),
    (type: 'top_rated', labelKey: 'top_rated'),
  ];

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StoreController>(builder: (storeController) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: _filters.map((filter) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _ExploreFilterChip(
              label: filter.labelKey.tr,
              isSelected: storeController.storeType == filter.type,
              onTap: () => storeController.setStoreType(filter.type),
            ),
          )).toList(),
        ),
      );
    });
  }
}

class FoodModuleExploreRestaurantsListWidget extends StatelessWidget {
  final ScrollController scrollController;
  const FoodModuleExploreRestaurantsListWidget({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StoreController>(builder: (storeController) {
      final List<Store>? stores = storeController.storeModel?.stores;

      if(stores == null) {
        return const _ExploreShimmer();
      }
      if(stores.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge),
          child: Center(
            child: Text(
              'no_store_available'.tr,
              style: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).disabledColor,
              ),
            ),
          ),
        );
      }

      return PaginatedListView(
        scrollController: scrollController,
        totalSize: storeController.storeModel?.totalSize,
        offset: storeController.storeModel?.offset,
        onPaginate: (int? offset) async => await storeController.getStoreList(offset!, false),
        itemView: ListView.builder(
          shrinkWrap: true,
          primary: false,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
          itemCount: stores.length,
          itemBuilder: (context, index) {
            final Store store = stores[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
              child: FeaturedStoreCard(
                data: store,
                width: double.infinity,
                imageHeight: 150,
                isQuick: false,
                onTap: () => _openStore(store),
              ),
            );
          },
        ),
      );
    });
  }
}

void _openStore(Store store) {
  Get.toNamed(
    RouteHelper.getStoreRoute(id: store.id, page: 'store_new', slug: store.slug ?? ''),
    arguments: StoreScreen(store: store, fromModule: false),
  );
}

class _ExploreFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ExploreFilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : null,
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
          border: isSelected ? null : Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.5), width: 0.5),
        ),
        child: Text(
          label,
          style: robotoMedium.copyWith(
            fontSize: Dimensions.fontSizeDefault,
            color: isSelected ? Colors.white : Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }
}

class _ExploreShimmer extends StatelessWidget {
  const _ExploreShimmer();

  @override
  Widget build(BuildContext context) {
    final Color shimmerColor = Theme.of(context).disabledColor.withAlpha(60);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: 3,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
        child: Shimmer(
          duration: const Duration(seconds: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Container(
                height: 14,
                width: 180,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 12,
                width: 120,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
