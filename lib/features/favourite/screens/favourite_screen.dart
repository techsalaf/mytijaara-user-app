import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/common/widgets/not_logged_in_screen.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/common_widget/featured_store_card.dart';
import 'package:sixam_mart/features/redesign_feature/global_widgets/exclusive_deal_card.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
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

  String get _itemsLabel => _showRestaurantText ? 'foods'.tr : 'items'.tr;
  String get _storesLabel => _showRestaurantText ? 'restaurants'.tr : 'stores'.tr;

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
                            count: _selectedFilter == _FavFilter.items ? items.length : stores.length,
                            itemsLabel: _itemsLabel,
                            storesLabel: _storesLabel,
                            onSelected: _selectFilter,
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: _selectedFilter == _FavFilter.items
                            ? _buildItemsBody(context: context, controller: controller, items: items)
                            : _buildRestaurantsBody(context: context, controller: controller, stores: stores),
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
      return const _LoadingPlaceholder();
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

  const _FavTypeFilterBar({required this.selected,
    required this.count, required this.itemsLabel, required this.storesLabel, required this.onSelected,
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
                  child: Text(
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

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraLarge * 2),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
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
