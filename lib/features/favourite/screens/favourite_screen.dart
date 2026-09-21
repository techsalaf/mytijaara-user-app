import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/common/widgets/not_logged_in_screen.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/common/widgets/featured_store_card.dart';
import 'package:sixam_mart/common/widgets/exclusive_deal_card.dart';
import 'package:sixam_mart/features/service_module/common/models/service_provider_model.dart';
import 'package:sixam_mart/features/service_module/provider_details/widgets/provider_service_item_widget.dart';
import 'package:sixam_mart/features/service_module/service_home/domain/models/service_model.dart';
import 'package:sixam_mart/features/service_module/service_home/widgets/service_verified_provider_card_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

enum _FavFilter { items, restaurants }

class FavouriteScreen extends StatefulWidget {
  final Function()? onBackPressed;
  const FavouriteScreen({super.key, this.onBackPressed});

  @override
  FavouriteScreenState createState() => FavouriteScreenState();
}

class FavouriteScreenState extends State<FavouriteScreen> {
  _FavFilter _selectedFilter = _FavFilter.items;

  @override
  void initState() {
    super.initState();
    _initCall();
  }

  void _initCall() {
    if (AuthHelper.isLoggedIn()) {
      Get.find<FavouriteController>().getFavouriteList();
    }
  }

  void _selectFilter(_FavFilter filter) {
    if (_selectedFilter == filter) return;
    setState(() => _selectedFilter = filter);
  }

  bool get _showRestaurantText => Get.find<SplashController>().configModel?.moduleConfig?.module?.showRestaurantText ?? false;

  bool get _isServiceModule => Get.find<SplashController>().module?.moduleType == AppConstants.service;

  String get _itemsLabel => _isServiceModule ? 'services'.tr : (_showRestaurantText ? 'foods'.tr : 'items'.tr);
  String get _storesLabel => _isServiceModule ? 'providers'.tr : (_showRestaurantText ? 'restaurants'.tr : 'stores'.tr);

  @override
  Widget build(BuildContext context) {
    final Color tinted = Color.alphaBlend(
      Theme.of(context).disabledColor.withAlpha(30),
      Theme.of(context).cardColor,
    );

    return Scaffold(
      backgroundColor: tinted,
      appBar: CustomAppBar(title: 'favourite'.tr, backButton: true, onBackPressed: widget.onBackPressed),
      endDrawer: const MenuDrawer(),
      endDrawerEnableOpenDragGesture: false,
      body: AuthHelper.isLoggedIn()
          ? SafeArea(
              bottom: false,
              child: GetBuilder<FavouriteController>(builder: (controller) {
                final List<Item> items = (controller.wishItemList ?? const <Item?>[])
                    .where((Item? e) => e != null).cast<Item>().toList();
                final List<Store> stores = (controller.wishStoreList ?? const <Store?>[])
                    .where((Store? e) => e != null).cast<Store>().toList();
                final List<Service> services = (controller.wishServiceList ?? const <Service?>[])
                    .where((Service? e) => e != null).cast<Service>().toList();
                final List<ServiceProvider> providers = (controller.wishStoreList ?? const <Store?>[])
                    .where((Store? e) => e != null).map((Store? e) => ServiceProvider.fromStore(e!)).toList();

                final int primaryCount = _isServiceModule ? services.length : items.length;
                final int secondaryCount = _isServiceModule ? providers.length : stores.length;

                // The selected tab's wish list is still null on first load — show a
                // shimmer for the count instead of a misleading "0".
                final bool primaryLoading = _isServiceModule ? controller.wishServiceList == null : controller.wishItemList == null;
                final bool secondaryLoading = controller.wishStoreList == null;
                final bool countLoading = _selectedFilter == _FavFilter.items ? primaryLoading : secondaryLoading;

                return RefreshIndicator(
                  onRefresh: () async {
                    await controller.getFavouriteList();
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: <Widget>[
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _PinnedHeaderDelegate(
                          height: 56,
                          child: _FavTypeFilterBar(
                            selected: _selectedFilter,
                            count: _selectedFilter == _FavFilter.items ? primaryCount : secondaryCount,
                            itemsLabel: _itemsLabel,
                            storesLabel: _storesLabel,
                            onSelected: _selectFilter,
                            isLoading: countLoading,
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: _selectedFilter == _FavFilter.items
                            ? (_isServiceModule
                                ? _ServicesFavouriteView(isLoading: controller.wishServiceList == null, services: services)
                                : _buildItemsBody(context: context, controller: controller, items: items))
                            : (_isServiceModule
                                ? _ProvidersFavouriteView(isLoading: controller.wishStoreList == null, providers: providers)
                                : _buildRestaurantsBody(context: context, controller: controller, stores: stores)),
                      ),
                    ],
                  ),
                );
              }),
            )
          : NotLoggedInScreen(callBack: (value) {
              _initCall();
              setState(() {});
            }),
    );
  }

  Widget _buildItemsBody({required BuildContext context, required FavouriteController controller, required List<Item> items}) {
    if (controller.wishItemList == null) {
      return const _LoadingPlaceholder();
    }
    if (items.isEmpty) {
      return _EmptyView(message: 'no_wish_data_found'.tr);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeDefault,
      ),
      child: Column(
        children: items.map((Item item) {
          final bool isLast = identical(item, items.last);
          final int index = items.indexOf(item);
          return Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : Dimensions.paddingSizeDefault),
            padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
              border: isLast ? null : Border(
                bottom: BorderSide(color: Theme.of(context).disabledColor.withValues(alpha: 0.18)),
              ),
            ),
            child: ExclusiveDealCard(
              item: item,
              width: double.infinity,
              index: index,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRestaurantsBody({required BuildContext context, required FavouriteController controller, required List<Store> stores}) {
    if (controller.wishStoreList == null) {
      return const _LoadingPlaceholder(isStore: true);
    }
    if (stores.isEmpty) {
      return _EmptyView(message: 'no_wish_data_found'.tr);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeDefault,
      ),
      child: Column(
        children: stores.map((Store store) {
          final bool isLast = identical(store, stores.last);
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : Dimensions.paddingSizeDefault),
            child: FeaturedStoreCard(
              data: store,
              width: double.infinity,
              isQuick: false,
              onTap: () => Get.toNamed(RouteHelper.getStoreRoute(
                id: store.id, page: 'item', slug: store.slug ?? '',
              )),
            ),
          );
        }).toList(),
      ),
    );
  }

}

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _PinnedHeaderDelegate({required this.child, required this.height});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}

class _FavTypeFilterBar extends StatelessWidget {
  final _FavFilter selected;
  final int count;
  final String itemsLabel;
  final String storesLabel;
  final ValueChanged<_FavFilter> onSelected;
  final bool isLoading;

  const _FavTypeFilterBar({
    required this.selected, required this.count, required this.itemsLabel, required this.storesLabel, required this.onSelected,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final Color divider = Theme.of(context).disabledColor.withAlpha(60);
    final Color tinted = Color.alphaBlend(
      Theme.of(context).disabledColor.withAlpha(30),
      Theme.of(context).cardColor,
    );
    final List<(_FavFilter, String)> tabs = <(_FavFilter, String)>[
      (_FavFilter.items, itemsLabel),
      (_FavFilter.restaurants, storesLabel),
    ];

    return Material(
      color: tinted,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeDefault,
                    vertical: Dimensions.paddingSizeSmall,
                  ),
                  child: isLoading
                      ? Shimmer(
                          duration: const Duration(seconds: 2),
                          child: Container(
                            width: 70, height: 12,
                            decoration: BoxDecoration(
                              color: Theme.of(context).disabledColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                            ),
                          ),
                        )
                      : Text(
                          '$count ${selected == _FavFilter.items ? itemsLabel : storesLabel}',
                          style: robotoBold.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).disabledColor,
                          ),
                        ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeDefault,
                    vertical: Dimensions.paddingSizeSmall,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List<Widget>.generate(tabs.length, (index) {
                      final (_FavFilter filter, String label) = tabs[index];
                      return Padding(
                        padding: EdgeInsets.only(left: index == 0 ? 0 : Dimensions.paddingSizeSmall),
                        child: _FavFilterChip(
                          label: label,
                          isSelected: filter == selected,
                          onTap: () => onSelected(filter),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: divider),
        ],
      ),
    );
  }
}

class _FavFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FavFilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    final Color textColor = isSelected
        ? Colors.white
        : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeSmall,
        ),
        decoration: BoxDecoration(
          color: isSelected ? primary : Theme.of(context).disabledColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          label,
          style: robotoSemiBold.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class _ServicesFavouriteView extends StatelessWidget {
  final bool isLoading;
  final List<Service> services;
  const _ServicesFavouriteView({required this.isLoading, required this.services});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _LoadingPlaceholder();
    }
    if (services.isEmpty) {
      return _EmptyView(message: 'no_wish_data_found'.tr);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeDefault,
      ),
      child: Column(
        children: services.map((Service service) {
          final bool isLast = identical(service, services.last);
          return Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : Dimensions.paddingSizeDefault),
            padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
              border: isLast ? null : Border(
                bottom: BorderSide(color: Theme.of(context).disabledColor.withValues(alpha: 0.18)),
              ),
            ),
            child: ProviderServiceItemWidget(service: service),
          );
        }).toList(),
      ),
    );
  }
}

class _ProvidersFavouriteView extends StatelessWidget {
  final bool isLoading;
  final List<ServiceProvider> providers;
  const _ProvidersFavouriteView({required this.isLoading, required this.providers});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _LoadingPlaceholder(isStore: true);
    }
    if (providers.isEmpty) {
      return _EmptyView(message: 'no_wish_data_found'.tr);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeDefault,
      ),
      child: Column(
        children: providers.map((ServiceProvider provider) {
          final bool isLast = identical(provider, providers.last);
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : Dimensions.paddingSizeDefault),
            child: ServiceVerifiedProviderCard(provider: provider, width: double.infinity),
          );
        }).toList(),
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  // Banner-style card placeholders (stores/providers) vs full-width row
  // placeholders (items/services).
  final bool isStore;
  const _LoadingPlaceholder({this.isStore = false});

  @override
  Widget build(BuildContext context) {
    final int count = isStore ? 4 : 6;
    return Shimmer(
      duration: const Duration(seconds: 2),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(
          children: List<Widget>.generate(count, (int index) => Padding(
            padding: EdgeInsets.only(bottom: index == count - 1 ? 0 : Dimensions.paddingSizeLarge),
            child: isStore ? const _StoreShimmerBlock() : const _ItemShimmerRow(),
          )),
        ),
      ),
    );
  }
}

/// Grey placeholder box used as the base for the shimmer sweep.
class _ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const _ShimmerBox({this.width, required this.height, this.radius = Dimensions.radiusSmall});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).disabledColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Mimics a full-width favourite item/service row (image + text lines).
class _ItemShimmerRow extends StatelessWidget {
  const _ItemShimmerRow();

  @override
  Widget build(BuildContext context) {
    return const Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      _ShimmerBox(width: 90, height: 90, radius: Dimensions.radiusDefault),
      SizedBox(width: Dimensions.paddingSizeDefault),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          _ShimmerBox(width: 160, height: 14),
          SizedBox(height: Dimensions.paddingSizeSmall),
          _ShimmerBox(width: 110, height: 12),
          SizedBox(height: Dimensions.paddingSizeSmall),
          _ShimmerBox(width: 70, height: 12),
          SizedBox(height: Dimensions.paddingSizeSmall),
          _ShimmerBox(width: 90, height: 14),
        ]),
      ),
    ]);
  }
}

/// Mimics a full-width favourite store/provider card (banner image + text lines).
class _StoreShimmerBlock extends StatelessWidget {
  const _StoreShimmerBlock();

  @override
  Widget build(BuildContext context) {
    return const Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      _ShimmerBox(height: 150, radius: Dimensions.radiusDefault),
      SizedBox(height: Dimensions.paddingSizeDefault),
      _ShimmerBox(width: 180, height: 14),
      SizedBox(height: Dimensions.paddingSizeSmall),
      _ShimmerBox(width: 120, height: 12),
    ]);
  }
}

class _EmptyView extends StatelessWidget {
  final String message;
  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        decoration: BoxDecoration(
          color: Theme.of(context).disabledColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: robotoMedium.copyWith(
            fontSize: Dimensions.fontSizeDefault,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }
}
