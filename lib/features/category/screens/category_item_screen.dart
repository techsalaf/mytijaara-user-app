import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/common_widget/featured_store_card.dart';
import 'package:sixam_mart/features/redesign_feature/global_widgets/exclusive_deal_card.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

enum _CatFilter { items, stores }

class CategoryItemScreen extends StatefulWidget {
  final String? categoryID;
  final String categoryName;
  const CategoryItemScreen({super.key, required this.categoryID, required this.categoryName});

  @override
  CategoryItemScreenState createState() => CategoryItemScreenState();
}

class CategoryItemScreenState extends State<CategoryItemScreen> {
  _CatFilter _selectedFilter = _CatFilter.items;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchTextController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    final CategoryController controller = Get.find<CategoryController>();
    controller.getSubCategoryList(widget.categoryID);
    controller.getCategoryStoreList(widget.categoryID, 1, controller.type, false);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchTextController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch(CategoryController controller) {
    if (controller.isSearching) {
      _searchTextController.clear();
      _searchFocusNode.unfocus();
    }
    controller.toggleSearch();
    if (controller.isSearching) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _searchFocusNode.requestFocus());
    }
  }

  void _submitSearch(CategoryController controller, String query) {
    controller.searchData(query, _resolveCategoryId(controller), controller.type);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels < _scrollController.position.maxScrollExtent - 100) return;
    final CategoryController controller = Get.find<CategoryController>();
    if (controller.isLoading) return;

    if (_selectedFilter == _CatFilter.items) {
      if (controller.categoryItemList == null) return;
      final int pageSize = ((controller.pageSize ?? 0) / 10).ceil();
      if (controller.offset >= pageSize) return;
      if (kDebugMode) print('end of the page (items)');
      controller.showBottomLoader();
      controller.getCategoryItemList(
        _resolveCategoryId(controller),
        controller.offset + 1, controller.type, false,
      );
    } else {
      if (controller.categoryStoreList == null) return;
      final int pageSize = ((controller.restPageSize ?? 0) / 10).ceil();
      if (controller.offset >= pageSize) return;
      if (kDebugMode) print('end of the page (stores)');
      controller.showBottomLoader();
      controller.getCategoryStoreList(
        _resolveCategoryId(controller),
        controller.offset + 1, controller.type, false,
      );
    }
  }

  String? _resolveCategoryId(CategoryController controller) {
    if (controller.subCategoryIndex == 0 || controller.subCategoryList == null) {
      return widget.categoryID;
    }
    return controller.subCategoryList![controller.subCategoryIndex].id.toString();
  }

  void _selectFilter(_CatFilter filter) {
    if (_selectedFilter == filter) return;
    setState(() => _selectedFilter = filter);
    final CategoryController controller = Get.find<CategoryController>();
    final bool isStore = filter == _CatFilter.stores;
    controller.setRestaurant(isStore);
    if (controller.isSearching) {
      controller.searchData(
        controller.searchText, _resolveCategoryId(controller), controller.type,
      );
    } else {
      if (isStore) {
        controller.getCategoryStoreList(_resolveCategoryId(controller), 1, controller.type, false);
      } else {
        controller.getCategoryItemList(_resolveCategoryId(controller), 1, controller.type, false);
      }
    }
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
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

    return GetBuilder<CategoryController>(builder: (catController) {
      final List<Item> items = catController.isSearching
          ? List<Item>.from(catController.searchItemList ?? const <Item>[])
          : List<Item>.from(catController.categoryItemList ?? const <Item>[]);
      final List<Store> stores = catController.isSearching
          ? List<Store>.from(catController.searchStoreList ?? const <Store>[])
          : List<Store>.from(catController.categoryStoreList ?? const <Store>[]);

      final bool itemsReady = catController.isSearching
          ? catController.searchItemList != null
          : catController.categoryItemList != null;
      final bool storesReady = catController.isSearching
          ? catController.searchStoreList != null
          : catController.categoryStoreList != null;

      return PopScope(
        canPop: !catController.isSearching,
        onPopInvokedWithResult: (didPop, result) async {
          if (!didPop && catController.isSearching) {
            _toggleSearch(catController);
          }
        },
        child: Scaffold(
          backgroundColor: tinted,
          appBar: CustomAppBar(
            title: widget.categoryName,
            backButton: true,
            showCart: true,
            type: catController.type,
            isSearchActive: catController.isSearching,
            onSearchTap: () => _toggleSearch(catController),
            onBackPressed: () {
              if (catController.isSearching) {
                _toggleSearch(catController);
              } else {
                Get.back();
              }
            },
            onVegFilterTap: (String type) {
              if (catController.isSearching) {
                catController.searchData(
                  _searchTextController.text, _resolveCategoryId(catController), type,
                );
              } else if (catController.isStore) {
                catController.getCategoryStoreList(_resolveCategoryId(catController), 1, type, true);
              } else {
                catController.getCategoryItemList(_resolveCategoryId(catController), 1, type, true);
              }
            },
          ),
          endDrawer: const MenuDrawer(),
          endDrawerEnableOpenDragGesture: false,
          body: SafeArea(
            bottom: false,
            child: ResponsiveHelper.isDesktop(context)
                ? Center(child: SizedBox(
                    width: Dimensions.webMaxWidth,
                    child: SingleChildScrollView(child: FooterView(child: _buildContent(
                      context: context,
                      controller: catController,
                      items: items, stores: stores,
                      itemsReady: itemsReady, storesReady: storesReady,
                      tinted: tinted,
                      asSlivers: false,
                    ))),
                  ))
                : _buildContent(
                    context: context,
                    controller: catController,
                    items: items, stores: stores,
                    itemsReady: itemsReady, storesReady: storesReady,
                    tinted: tinted,
                    asSlivers: true,
                  ),
          ),
        ),
      );
    });
  }

  Widget _buildContent({
    required BuildContext context,
    required CategoryController controller,
    required List<Item> items,
    required List<Store> stores,
    required bool itemsReady,
    required bool storesReady,
    required Color tinted,
    required bool asSlivers,
  }) {
    final Widget filterBar = _CatTypeFilterBar(
      selected: _selectedFilter,
      count: _selectedFilter == _CatFilter.items ? items.length : stores.length,
      itemsLabel: _itemsLabel,
      storesLabel: _storesLabel,
      onSelected: _selectFilter,
    );

    final Widget searchBar = _CategorySearchBar(
      controller: _searchTextController,
      focusNode: _searchFocusNode,
      onSubmitted: (String query) => _submitSearch(controller, query),
      onClear: () => _toggleSearch(controller),
    );

    final Widget subCategoryBar = (controller.subCategoryList != null && !controller.isSearching)
        ? _SubCategoryStrip(controller: controller, parentCategoryID: widget.categoryID)
        : const SizedBox.shrink();

    final Widget body = _selectedFilter == _CatFilter.items
        ? _buildItemsBody(context: context, controller: controller, items: items, itemsReady: itemsReady)
        : _buildStoresBody(context: context, controller: controller, stores: stores, storesReady: storesReady);

    final Widget paginationLoader = controller.isLoading ? const Padding(
      padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    ) : const SizedBox.shrink();

    if (!asSlivers) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        if (controller.isSearching) searchBar else subCategoryBar,
        Container(color: tinted, height: 56, child: filterBar),
        body,
        paginationLoader,
      ]);
    }

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        if (controller.isSearching)
          SliverToBoxAdapter(child: searchBar)
        else if (controller.subCategoryList != null)
          SliverToBoxAdapter(child: subCategoryBar),
        SliverPersistentHeader(
          pinned: true,
          delegate: _PinnedHeaderDelegate(height: 56, child: filterBar),
        ),
        SliverToBoxAdapter(child: body),
        SliverToBoxAdapter(child: paginationLoader),
      ],
    );
  }

  Widget _buildItemsBody({
    required BuildContext context,
    required CategoryController controller,
    required List<Item> items,
    required bool itemsReady,
  }) {
    if (!itemsReady) {
      return const _LoadingPlaceholder();
    }
    if (items.isEmpty) {
      return _EmptyView(message: 'no_category_item_found'.tr);
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
            child: ExclusiveDealCard(item: item, width: double.infinity, index: index),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStoresBody({
    required BuildContext context,
    required CategoryController controller,
    required List<Store> stores,
    required bool storesReady,
  }) {
    if (!storesReady) {
      return const _LoadingPlaceholder(isStore: true);
    }
    if (stores.isEmpty) {
      return _EmptyView(message: _showRestaurantText ? 'no_category_restaurant_found'.tr : 'no_category_store_found'.tr);
    }
    // Full-width store cards (banner ratio ~0.4 of the available content width).
    final double contentWidth = MediaQuery.sizeOf(context).width.clamp(0, Dimensions.webMaxWidth).toDouble()
        - (Dimensions.paddingSizeDefault * 2);
    final double imageHeight = contentWidth * 0.4;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeDefault,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: stores.map((Store store) {
        final bool isLast = identical(store, stores.last);
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : Dimensions.paddingSizeLarge),
          child: FeaturedStoreCard(
            data: store,
            width: double.infinity,
            imageHeight: imageHeight,
            isQuick: false,
            isFeatured: false,
            onTap: () => Get.toNamed(RouteHelper.getStoreRoute(
              id: store.id, page: 'item', slug: store.slug ?? '',
            )),
          ),
        );
      }).toList()),
    );
  }
}

class _SubCategoryStrip extends StatelessWidget {
  final CategoryController controller;
  final String? parentCategoryID;

  const _SubCategoryStrip({required this.controller, required this.parentCategoryID});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: controller.subCategoryList!.length,
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        physics: const BouncingScrollPhysics(),
        itemBuilder: (BuildContext context, int index) {
          final bool isSelected = index == controller.subCategoryIndex;
          final Color primary = Theme.of(context).primaryColor;
          return Padding(
            padding: EdgeInsets.only(right: index == controller.subCategoryList!.length - 1 ? 0 : Dimensions.paddingSizeSmall),
            child: InkWell(
              borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
              onTap: () => controller.setSubCategoryIndex(index, parentCategoryID),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault,
                  vertical: Dimensions.paddingSizeSmall,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? primary : Theme.of(context).disabledColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                ),
                child: Center(child: Text(
                  controller.subCategoryList![index].name ?? '',
                  style: robotoMedium.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                )),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CategorySearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  const _CategorySearchBar({required this.controller, required this.focusNode, required this.onSubmitted, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final Color borderColor = Theme.of(context).disabledColor.withValues(alpha: 0.18);
    final Color hintColor = Theme.of(context).disabledColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeSmall,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge + Dimensions.radiusDefault),
          border: Border.all(color: borderColor),
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: TextInputAction.search,
          onSubmitted: onSubmitted,
          style: robotoRegular.copyWith(
            fontSize: Dimensions.fontSizeDefault,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'search'.tr,
            hintStyle: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: hintColor),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
              vertical: Dimensions.paddingSizeDefault,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeSmall),
              child: Icon(Icons.search, size: 20, color: hintColor),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: GestureDetector(
              onTap: onClear,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(right: Dimensions.paddingSizeDefault),
                child: Icon(Icons.close, size: 20, color: hintColor),
              ),
            ),
            suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          ),
        ),
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

class _CatTypeFilterBar extends StatelessWidget {
  final _CatFilter selected;
  final int count;
  final String itemsLabel;
  final String storesLabel;
  final ValueChanged<_CatFilter> onSelected;

  const _CatTypeFilterBar({required this.selected,
    required this.count, required this.itemsLabel, required this.storesLabel, required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final Color divider = Theme.of(context).disabledColor.withAlpha(60);
    final Color tinted = Color.alphaBlend(
      Theme.of(context).disabledColor.withAlpha(30),
      Theme.of(context).cardColor,
    );
    final List<(_CatFilter, String)> tabs = <(_CatFilter, String)>[
      (_CatFilter.items, itemsLabel),
      (_CatFilter.stores, storesLabel),
    ];

    return Material(
      color: tinted,
      child: Column(children: <Widget>[
        Expanded(child: Row(children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
              vertical: Dimensions.paddingSizeSmall,
            ),
            child: Text(
              '$count ${selected == _CatFilter.items ? itemsLabel : storesLabel}',
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
            child: Row(mainAxisSize: MainAxisSize.min,
              children: List<Widget>.generate(tabs.length, (int index) {
                final (_CatFilter filter, String label) = tabs[index];
                return Padding(
                  padding: EdgeInsets.only(left: index == 0 ? 0 : Dimensions.paddingSizeSmall),
                  child: _CatFilterChip(
                    label: label,
                    isSelected: filter == selected,
                    onTap: () => onSelected(filter),
                  ),
                );
              }),
            ),
          ),
        ])),
        Container(height: 1, color: divider),
      ]),
    );
  }
}

class _CatFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CatFilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    final Color textColor = isSelected
        ? Colors.white
        : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return InkWell(
      borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: isSelected ? primary : Theme.of(context).disabledColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        ),
        child: Text(
          label,
          style: robotoBold.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  final bool isStore;
  const _LoadingPlaceholder({this.isStore = false});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      duration: const Duration(seconds: 1),
      interval: const Duration(milliseconds: 500),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(
          children: List<Widget>.generate(
            isStore ? 4 : 6,
            (int index) => Padding(
              padding: EdgeInsets.only(bottom: index == (isStore ? 3 : 5) ? 0 : Dimensions.paddingSizeLarge),
              child: isStore ? const _StoreShimmerBlock() : const _ItemShimmerRow(),
            ),
          ),
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

/// Mimics a full-width category item row (image + text lines).
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

/// Mimics a store summary row plus its horizontal item preview strip.
class _StoreShimmerBlock extends StatelessWidget {
  const _StoreShimmerBlock();

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      const Row(children: <Widget>[
        _ShimmerBox(width: 48, height: 48, radius: Dimensions.radiusDefault),
        SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            _ShimmerBox(width: 150, height: 14),
            SizedBox(height: Dimensions.paddingSizeSmall),
            _ShimmerBox(width: 100, height: 12),
          ]),
        ),
      ]),
      const SizedBox(height: Dimensions.paddingSizeDefault),
      SizedBox(
        height: 150,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          primary: false,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          separatorBuilder: (BuildContext context, int index) => const SizedBox(width: Dimensions.paddingSizeSmall),
          itemBuilder: (BuildContext context, int index) => const Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            _ShimmerBox(width: 115, height: 110, radius: Dimensions.radiusDefault),
            SizedBox(height: Dimensions.paddingSizeSmall),
            _ShimmerBox(width: 90, height: 12),
            SizedBox(height: Dimensions.paddingSizeExtraSmall),
            _ShimmerBox(width: 60, height: 12),
          ]),
        ),
      ),
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
