import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/common/models/restaurant_offer_chip.dart';
import 'package:sixam_mart/common/widgets/paginated_list_view.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/common/widgets/featured_store_card.dart';
import 'package:sixam_mart/common/widgets/food_item_card.dart';
import 'package:sixam_mart/features/search/domain/models/food_item.dart';
import 'package:sixam_mart/common/widgets/exclusive_deal_card.dart';
import 'package:sixam_mart/common/widgets/restaurant_item_card.dart';
import 'package:sixam_mart/common/widgets/restaurant_summary_row.dart';
import 'package:sixam_mart/features/search/controllers/search_controller.dart'
    as search;
import 'package:sixam_mart/features/service_module/service_home/controllers/service_controller.dart';
import 'package:sixam_mart/features/service_module/service_home/domain/models/service_model.dart';
import 'package:sixam_mart/features/service_module/common/widgets/service_item_card.dart';
import 'package:sixam_mart/features/service_module/service_home/widgets/service_search_card.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/gaps.dart';
import 'package:sixam_mart/util/styles.dart';

enum _SearchFilter { all, items, stores }

// Card widths for the result carousels; the row heights are derived from these so a
// card's square image + text block never clips and scales with the device text size.
const double _kFoodCardWidth = 158;
const double _kStoreItemCardWidth = 100;

// FoodItemCard = square image (== width) + info block. Floored at 310 (current design).
double _foodCardRowHeight(BuildContext context) {
  final double textScale = MediaQuery.textScalerOf(context).scale(1.0);
  return (_kFoodCardWidth + Dimensions.paddingSizeDefault + 130 * textScale).clamp(310.0, double.infinity).toDouble();
}

// RestaurantItemCard = square image + gaps + 2-line name + price + struck price.
// Floored at 200 (current design).
double _storeItemRowHeight(BuildContext context) {
  final double textScale = MediaQuery.textScalerOf(context).scale(1.0);
  final double textBlock = (Dimensions.fontSizeSmall * 1.3 * 2
      + Dimensions.fontSizeLarge * 1.3
      + Dimensions.fontSizeSmall * 1.3) * textScale;
  return (_kStoreItemCardWidth + 10 + 6 + textBlock).clamp(200.0, double.infinity).toDouble();
}

class SearchResultSection extends StatefulWidget {
  final String searchText;
  const SearchResultSection({super.key, required this.searchText});

  @override
  SearchResultSectionState createState() => SearchResultSectionState();
}

class SearchResultSectionState extends State<SearchResultSection> {
  _SearchFilter _filter = _SearchFilter.all;
  final ScrollController _scrollController = ScrollController();
  String? _requestedStoreSearchText;
  String? _requestedItemSearchText;
  int _appliedFilterVersion = 0;
  bool _showModuleTabs = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Get.find<search.SearchController>().getExclusiveDeals(notify: false);
  }

  @override
  void didUpdateWidget(SearchResultSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchText != widget.searchText) {
      _requestedStoreSearchText = null;
      setState(() => _filter = _SearchFilter.all);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // Pagination is handled by PaginatedListView; this listener only drives the
  // module tab strip (hide while scrolling down, reveal on scroll up).
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final ScrollDirection direction = _scrollController.position.userScrollDirection;
    if (direction == ScrollDirection.reverse && _showModuleTabs) {
      setState(() => _showModuleTabs = false);
    } else if (direction == ScrollDirection.forward && !_showModuleTabs) {
      setState(() => _showModuleTabs = true);
    }
  }

  void _selectFilter(_SearchFilter filter) {
    if (_filter == filter) return;
    // The needed items/stores for the new tab are fetched by _loadResultsForCurrentTab.
    setState(() => _filter = filter);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<search.SearchController>(
      builder: (sc) {
        final bool isServiceModule = sc.isServiceModule;
        final List<Service> services = sc.searchServiceList ?? [];
        final List<Item> items = sc.searchItemList ?? [];
        final int itemCount = isServiceModule
            ? (sc.searchServiceTotalSize ?? services.length)
            : (sc.searchItemTotalSize ?? items.length);
        final int storeCount = sc.searchStoreList?.length ?? 0;
        final int count = _filter == _SearchFilter.items
            ? itemCount
            : _filter == _SearchFilter.stores
            ? storeCount
            : itemCount + storeCount;

        // The count total isn't known until the tab's underlying list(s) resolve;
        // until then show a shimmer instead of a misleading "0". The All tab needs
        // both lists before its combined total is meaningful.
        final bool itemsLoaded = isServiceModule ? sc.searchServiceList != null : sc.searchItemList != null;
        final bool storesLoaded = sc.searchStoreList != null;
        final bool countLoading = _filter == _SearchFilter.items
            ? !itemsLoaded
            : _filter == _SearchFilter.stores
            ? !storesLoaded
            : (!itemsLoaded || !storesLoaded);

        // A new filter (filterVersion change) clears both lists — re-arm the
        // lazy-load guards so the current tab re-fetches with the new filter.
        if (sc.filterVersion != _appliedFilterVersion) {
          _appliedFilterVersion = sc.filterVersion;
          _requestedItemSearchText = null;
          _requestedStoreSearchText = null;
        }
        _loadResultsForCurrentTab(sc);

        return Column(
          children: [
            if (sc.isGlobalSearch)
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _showModuleTabs
                    ? _SearchModuleTabs(
                      selectedModuleId: sc.selectedResultModuleId,
                      onSelected: (ModuleModel module) {
                        if (module.id != null) {
                          sc.selectSearchModule(module.id!, widget.searchText);
                        }
                      },
                    )
                    : const SizedBox(width: double.infinity),
              ),
            _ResultFilterBar(
              count: count,
              selected: _filter,
              onSelected: _selectFilter,
              searchText: widget.searchText,
              isLoading: countLoading,
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).disabledColor.withValues(alpha: 0.15),
            ),
            Expanded(child: _buildBody(context, sc, items, services, isServiceModule)),
          ],
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    search.SearchController sc,
    List<Item> items,
    List<Service> services,
    bool isServiceModule,
  ) {
    // ── Items tab ────────────────────────────────────────────────────────────
    if (_filter == _SearchFilter.items) {
      // Service module renders service cards from the parallel service list.
      if (isServiceModule) {
        if (sc.searchServiceList == null) return const _SearchResultShimmer();
        if (services.isEmpty) return const _NoResultView();
        return SingleChildScrollView(
          controller: _scrollController,
          child: PaginatedListView(
            scrollController: _scrollController,
            totalSize: sc.searchServiceTotalSize,
            offset: sc.searchServiceOffset,
            onPaginate: (int? offset) async => await sc.paginateSearchServices(widget.searchText),
            itemView: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: Dimensions.paddingSizeDefault),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeDefault,
                  ),
                  child: Text(
                    'all_service_result'.tr,
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeExtraLarge,
                    ),
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),
                _ServicesSection(services: services),
                const SizedBox(height: Dimensions.paddingSizeDefault),
              ],
            ),
          ),
        );
      }
      if (sc.searchItemList == null) return const _SearchResultShimmer();
      if (items.isEmpty) return const _NoResultView();
      return SingleChildScrollView(
        controller: _scrollController,
        child: PaginatedListView(
          scrollController: _scrollController,
          totalSize: sc.searchItemTotalSize,
          offset: sc.searchItemOffset,
          onPaginate: (int? offset) async => await sc.paginateSearchItems(widget.searchText),
          itemView: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: Dimensions.paddingSizeDefault),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault,
                ),
                child: Text(
                  'all_food_result'.tr,
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeExtraLarge,
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              _ItemsSection(items: items),
              const SizedBox(height: Dimensions.paddingSizeDefault),
            ],
          ),
        ),
      );
    }

    // ── Stores tab ───────────────────────────────────────────────────────────
    if (_filter == _SearchFilter.stores) {
      if (sc.searchStoreList == null) return const _SearchResultShimmer();
      if (sc.searchStoreList!.isEmpty) return const _NoResultView(kind: _EmptyKind.store);
      final bool showRestaurant = Get.find<SplashController>()
          .configModel!
          .moduleConfig!
          .module!
          .showRestaurantText!;
      final List<Store> stores = sc.searchStoreList!;
      return SingleChildScrollView(
        controller: _scrollController,
        child: PaginatedListView(
          scrollController: _scrollController,
          totalSize: sc.searchStoreTotalSize,
          offset: sc.searchStoreOffset,
          onPaginate: (int? offset) async => await sc.paginateSearchStores(widget.searchText),
          itemView: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: Dimensions.paddingSizeDefault),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault,
                ),
                child: Text(
                  isServiceModule
                      ? 'all_provider_result'.tr
                      : showRestaurant
                      ? 'all_restaurant_result'.tr
                      : 'all_store_result'.tr,
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeExtraLarge,
                  ),
                ),
              ),
              Gaps.verticalGapOf(Dimensions.paddingSizeLarge),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault,
                ),
                child: Column(
                  children: List.generate(stores.length, (int index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                      child: FeaturedStoreCard(
                        data: stores[index],
                        width: double.infinity,
                        imageHeight: 150,
                        isQuick: false,
                        onTap: () => _openSearchStore(stores[index]),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
            ],
          ),
        ),
      );
    }

    // ── All tab ──────────────────────────────────────────────────────────────
    final List<Store> exclusiveDeals = sc.exclusiveDealsStores ?? <Store>[];
    // In the service module the "items" half of the All tab is the service list.
    final bool itemsLoaded = isServiceModule ? sc.searchServiceList != null : sc.searchItemList != null;
    final bool hasItemResults = isServiceModule ? services.isNotEmpty : items.isNotEmpty;
    final bool storesLoaded = sc.searchStoreList != null;
    // Both result lists still loading — e.g. right after a filter apply, which
    // clears both — show the shimmer even when cached exclusive deals are present
    // (otherwise the stale deals carousel would hide the loading state). Partial
    // states (one list already resolved) keep the original progressive render;
    // once each list resolves its own section renders an empty state if needed.
    if (!itemsLoaded && !storesLoaded) {
      return const _SearchResultShimmer();
    }
    final bool showRestaurant = Get.find<SplashController>().configModel!.moduleConfig!.module!.showRestaurantText!;

    return SingleChildScrollView(
      controller: _scrollController,
      // Vertical scroll loads more stores; items also paginate so the carousel
      // keeps growing. The store totals drive the pagination guard/loader.
      child: PaginatedListView(
        scrollController: _scrollController,
        totalSize: sc.searchStoreTotalSize,
        offset: sc.searchStoreOffset,
        onPaginate: (int? offset) async {
          await sc.paginateSearchStores(widget.searchText);
          if (isServiceModule) {
            await sc.paginateSearchServices(widget.searchText);
          } else {
            await sc.paginateSearchItems(widget.searchText);
          }
        },
        itemView: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (itemsLoaded) ...[
              const SizedBox(height: Dimensions.paddingSizeDefault),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault,
                ),
                child: Text(
                  isServiceModule ? 'services'.tr : showRestaurant ? 'foods'.tr : 'items'.tr,
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeExtraLarge,
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              if (hasItemResults)
                SizedBox(
                  height: _foodCardRowHeight(context),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    primary: false,
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault,
                    ),
                    itemCount: isServiceModule ? services.length : items.length,
                    separatorBuilder: (_, _) =>
                        Gaps.horizontalGapOf(Dimensions.paddingSizeSmall),
                    itemBuilder: (BuildContext context, int index) {
                      if (isServiceModule) {
                        final Service service = services[index];
                        return ServiceItemCard(
                          service: service,
                          width: _kFoodCardWidth,
                          onTap: () => Get.toNamed(RouteHelper.getServiceDetailsRoute(
                            id: service.id ?? 0, slug: service.slug ?? '',
                          )),
                          onFavourite: () => Get.find<ServiceController>().toggleFavourite(service),
                        );
                      }
                      return FoodItemCard(data: items[index], width: _kFoodCardWidth, index: index);
                    },
                  ),
                )
              else
                const _NoResultView(kind: _EmptyKind.items),
            ],

            if (exclusiveDeals.isNotEmpty) _ExclusiveDealsSection(stores: exclusiveDeals),

            if (storesLoaded) ...[
              Gaps.verticalGapOf(exclusiveDeals.isNotEmpty ? Dimensions.paddingSizeDefault : Dimensions.paddingSizeExtraSmall),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault,
                ),
                child: Text(
                  isServiceModule ? 'providers'.tr : showRestaurant ? 'restaurants'.tr : 'stores'.tr,
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeExtraLarge,
                  ),
                ),
              ),
              Gaps.verticalGapOf(Dimensions.paddingSizeLarge),
              if (sc.searchStoreList!.isNotEmpty)
                ..._storeGroupWidgets(sc.searchStoreList!)
              else
                const _NoResultView(kind: _EmptyKind.store),
            ],
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          ],
        ),
      ),
    );
  }

  // Fetches whichever lists the active tab needs (items and/or stores) when they
  // aren't loaded yet — so a filter apply calls only the relevant API(s):
  // all → both, items → items only, stores → stores only.
  void _loadResultsForCurrentTab(search.SearchController sc) {
    final bool needItems = _filter == _SearchFilter.items || _filter == _SearchFilter.all;
    final bool needStores = _filter == _SearchFilter.stores || _filter == _SearchFilter.all;
    final String searchText = widget.searchText;
    final bool isServiceModule = sc.isServiceModule;
    final bool itemsLoaded = isServiceModule ? sc.searchServiceList != null : sc.searchItemList != null;

    if (needItems && !itemsLoaded && _requestedItemSearchText != searchText) {
      _requestedItemSearchText = searchText;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || widget.searchText != searchText) return;
        final search.SearchController controller = Get.find<search.SearchController>();
        if (isServiceModule ? controller.searchServiceList != null : controller.searchItemList != null) return;
        _fetchItemResults(searchText);
      });
    }

    if (needStores && sc.searchStoreList == null && _requestedStoreSearchText != searchText) {
      _requestedStoreSearchText = searchText;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || widget.searchText != searchText) return;
        if (Get.find<search.SearchController>().searchStoreList != null) return;
        _fetchStoreResults(searchText, restoreItemSearchMode: _filter == _SearchFilter.all);
      });
    }
  }

  Future<void> _fetchItemResults(String searchText) async {
    final search.SearchController searchController = Get.find<search.SearchController>();
    searchController.setStore(false);
    await searchController.searchData(searchText, false);
  }

  Future<void> _fetchStoreResults(
    String searchText, {
    required bool restoreItemSearchMode,
  }) async {
    final search.SearchController searchController =
        Get.find<search.SearchController>();
    searchController.setStore(true);
    await searchController.searchData(searchText, false);
    if (!mounted || widget.searchText != searchText) return;
    if (restoreItemSearchMode && _filter != _SearchFilter.stores) {
      searchController.setStore(false);
    }
  }

  Iterable<Widget> _storeGroupWidgets(List<Store> stores) sync* {
    for (int index = 0; index < stores.length; index++) {
      final Store store = stores[index];
      yield _SearchStoreGroup(
        store: store,
        storeItems: store.topItems ?? [],
        showBottomDivider: index != stores.length - 1,
      );
    }
  }
}

// ── Module tab strip (global search only) — mirrors offer_screen._OfferModuleTabs ─

class _SearchModuleTabs extends StatelessWidget {
  final int? selectedModuleId;
  final void Function(ModuleModel module) onSelected;

  const _SearchModuleTabs({required this.selectedModuleId, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final List<ModuleModel> modules = Get.find<search.SearchController>().resultModules;
    if (modules.isEmpty) return const SizedBox.shrink();

    int selectedIndex = modules.indexWhere((ModuleModel m) => m.id == selectedModuleId);
    if (selectedIndex < 0) selectedIndex = 0;

    return Material(
      color: Theme.of(context).cardColor,
      child: DefaultTabController(
        key: ValueKey('search-module-tab-$selectedIndex-${modules.length}'),
        length: modules.length,
        initialIndex: selectedIndex,
        child: SizedBox(
          height: 42,
          child: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
            labelPadding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            indicator: BoxDecoration(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusDefault)),
            ),
            labelStyle: robotoBold.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: Theme.of(context).textTheme.bodyLarge!.color,
            ),
            unselectedLabelStyle: robotoBold.copyWith(
              fontSize: Dimensions.fontSizeDefault,
            ),
            labelColor: Theme.of(context).textTheme.bodyLarge?.color,
            unselectedLabelColor: Theme.of(context).disabledColor,
            onTap: (int index) => onSelected(modules[index]),
            tabs: modules.map((ModuleModel module) {
              return Tab(text: _moduleLabel(module.moduleName, module.moduleType ?? ''));
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _moduleLabel(String? moduleName, String moduleType) {
    if (moduleName != null && moduleName.trim().isNotEmpty) return moduleName;
    if (moduleType == AppConstants.food) return 'Food';
    if (moduleType == AppConstants.grocery) return 'Grocery';
    if (moduleType == AppConstants.ecommerce) return 'Shop';
    if (moduleType == AppConstants.pharmacy) return 'Pharmacy';
    return moduleType.isNotEmpty ? moduleType : 'Module';
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _ResultFilterBar extends StatelessWidget {
  final int count;
  final _SearchFilter selected;
  final ValueChanged<_SearchFilter> onSelected;
  final String searchText;
  final bool isLoading;

  const _ResultFilterBar({
    required this.count, required this.selected, required this.onSelected, required this.searchText, required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final bool showRestaurant = Get.find<SplashController>()
        .configModel!
        .moduleConfig!
        .module!
        .showRestaurantText!;
    final bool isServiceModule = Get.find<SplashController>().module?.moduleType == AppConstants.service;
    final List<(_SearchFilter, String)> filters = [
      (_SearchFilter.all, 'all'.tr),
      (_SearchFilter.items, isServiceModule ? 'services'.tr : showRestaurant ? 'food'.tr : 'item'.tr),
      (_SearchFilter.stores, isServiceModule ? 'providers'.tr : showRestaurant ? 'restaurants'.tr : 'stores'.tr),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeSmall,
      ),
      child: Row(
        children: [
          isLoading
              ? Shimmer(
                  duration: const Duration(seconds: 2),
                  child: Container(
                    width: 22, height: 12,
                    decoration: BoxDecoration(
                      color: Theme.of(context).disabledColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    ),
                  ),
                )
              : Text(
                  count.toString(),
                  style: robotoBold.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontSize: Dimensions.fontSizeSmall,
                  ),
                ),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Expanded(
            child: Text(
              '${'results_for'.tr} "$searchText"',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: robotoMedium.copyWith(
                color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.5),
                fontSize: Dimensions.fontSizeDefault,
              ),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(filters.length, (i) {
              final (_SearchFilter filter, String label) = filters[i];
              return _FilterChip(
                label: label,
                isSelected: filter == selected,
                onTap: () => onSelected(filter),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? Dimensions.paddingSizeDefault : Dimensions.paddingSizeSmall,
          vertical: Dimensions.paddingSizeSmall,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          label,
          style: robotoSemiBold.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: isSelected
                ? Theme.of(context).cardColor
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }
}

// ── Items section (Food tab) ──────────────────────────────────────────────────

class _ItemsSection extends StatelessWidget {
  final List<Item> items;
  const _ItemsSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final bool isLast = index == items.length - 1;
          return Container(
            margin: EdgeInsets.only(
              bottom: isLast ? 0 : Dimensions.paddingSizeDefault,
            ),
            padding: const EdgeInsets.only(
              bottom: Dimensions.paddingSizeDefault,
            ),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(
                      bottom: BorderSide(
                        color: Theme.of(
                          context,
                        ).disabledColor.withValues(alpha: 0.18),
                      ),
                    ),
            ),
            child: ExclusiveDealCard(
              item: items[index],
              width: double.infinity,
              index: index,
            ),
          );
        }),
      ),
    );
  }
}

// ── Services section (service module item tab) ────────────────────────────────

class _ServicesSection extends StatelessWidget {
  final List<Service> services;
  const _ServicesSection({required this.services});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
      ),
      child: Column(
        children: List.generate(services.length, (index) {
          final bool isLast = index == services.length - 1;
          final Service service = services[index];
          return Container(
            margin: EdgeInsets.only(
              bottom: isLast ? 0 : Dimensions.paddingSizeDefault,
            ),
            padding: const EdgeInsets.only(
              bottom: Dimensions.paddingSizeDefault,
            ),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(
                      bottom: BorderSide(
                        color: Theme.of(
                          context,
                        ).disabledColor.withValues(alpha: 0.18),
                      ),
                    ),
            ),
            child: ServiceSearchCard(
              service: service,
              width: double.infinity,
              onFavourite: () => Get.find<ServiceController>().toggleFavourite(service),
            ),
          );
        }),
      ),
    );
  }
}

// Opens a search-result store: results can span modules, so point the active
// module at the store's module (header) before navigating so its details resolve.
// In the service module the "store" is a provider, so route to provider details.
void _openSearchStore(Store store) {
  final List<ModuleModel>? modules = Get.find<SplashController>().moduleList;
  ModuleModel? storeModule;
  if (modules != null && store.moduleId != null) {
    for (final ModuleModel module in modules) {
      if (module.id == store.moduleId) {
        storeModule = module;
        if (Get.find<SplashController>().module?.id != module.id) {
          Get.find<SplashController>().setModule(module, notify: false);
        }
        break;
      }
    }
  }
  final bool isServiceModule = (storeModule?.moduleType ?? Get.find<SplashController>().module?.moduleType) == AppConstants.service;
  if (isServiceModule) {
    Get.toNamed(RouteHelper.getProviderDetailsRoute(store.id ?? 0, slug: store.slug));
    return;
  }
  Get.toNamed(RouteHelper.getStoreRoute(id: store.id, page: 'store_new', slug: store.slug ?? ''));
}

// ── Exclusive deals (horizontal store carousel) ───────────────────────────────

class _ExclusiveDealsSection extends StatelessWidget {
  final List<Store> stores;
  const _ExclusiveDealsSection({required this.stores});

  @override
  Widget build(BuildContext context) {
    final double cardWidth = MediaQuery.sizeOf(context).width * 0.80;
    final double imageHeight = cardWidth * 0.45;
    final double sectionHeight = imageHeight + 107;

    return Container(
      color: Theme.of(context).cardColor,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        const SizedBox(height: Dimensions.paddingSizeDefault),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: Text(
            'exclusive_deals'.tr,
            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),
        SizedBox(
          height: sectionHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            itemCount: stores.length,
            separatorBuilder: (_, _) => const SizedBox(width: Dimensions.paddingSizeDefault),
            itemBuilder: (BuildContext context, int index) {
              final Store store = stores[index];
              return FeaturedStoreCard(
                data: store,
                width: cardWidth,
                imageHeight: imageHeight,
                isQuick: false,
                onTap: () => _openSearchStore(store),
              );
            },
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
      ]),
    );
  }
}

// ── No result ─────────────────────────────────────────────────────────────────

// Which empty state to render: the Items/Services tab, the Stores tab (module-
// aware wording), or the All tab (generic — the mixed result set has no single
// entity name, so it stays "no result found").
enum _EmptyKind { items, store, all }

class _NoResultView extends StatelessWidget {
  final _EmptyKind kind;
  const _NoResultView({this.kind = _EmptyKind.items});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Text(
          _message(),
          style: robotoMedium.copyWith(color: Theme.of(context).disabledColor),
        ),
      ),
    );
  }

  String _message() {
    switch (kind) {
      case _EmptyKind.items:
        return 'no_item_available'.tr;
      case _EmptyKind.all:
        return 'no_result_found'.tr;
      case _EmptyKind.store:
        // Follows the same terminology as the rest of the search UI: provider
        // (service module), restaurant (food / showRestaurantText), or store.
        final bool isServiceModule = Get.find<SplashController>().module?.moduleType == AppConstants.service;
        if (isServiceModule) return 'no_provider_available'.tr;
        final bool showRestaurant = Get.find<SplashController>().configModel!.moduleConfig!.module!.showRestaurantText!;
        return showRestaurant ? 'no_restaurant_available'.tr : 'no_store_available'.tr;
    }
  }
}

// Shimmer placeholder shown while the first page of results is loading.
class _SearchResultShimmer extends StatelessWidget {
  const _SearchResultShimmer();

  @override
  Widget build(BuildContext context) {
    final Color base = Theme.of(context).disabledColor.withValues(alpha: 0.12);

    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
    );

    return ListView.separated(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(height: Dimensions.paddingSizeDefault),
      itemBuilder: (BuildContext context, int index) => Shimmer(
        duration: const Duration(seconds: 2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Container(
            height: 64, width: 64,
            decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
          ),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            bar(double.infinity, 14),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            bar(180, 12),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            bar(110, 12),
          ])),
        ]),
      ),
    );
  }
}

// ── Store group (All tab) — mirrors offer_screen.dart _StoreOfferGroup ────────

class _SearchStoreGroup extends StatelessWidget {
  final Store store;
  final List<TopItem> storeItems;
  final bool showBottomDivider;

  const _SearchStoreGroup({
    required this.store,
    required this.storeItems,
    required this.showBottomDivider,
  });

  static const int _maxInlineItems = 4;

  List<RestaurantOfferChipData> _buildOffers() {
    return <RestaurantOfferChipData>[
      if ((store.discount?.discount ?? 0) > 0)
        RestaurantOfferChipData(
          label: '-${store.discount!.discount!.toStringAsFixed(0)}%',
          labelDirection: TextDirection.ltr,
        ),
      if (store.freeDelivery == true)
        RestaurantOfferChipData(
          label: 'free_delivery'.tr,
          icon: Icons.local_shipping_outlined,
        ),
      if (store.offerLabel != null && store.offerLabel!.isNotEmpty)
        RestaurantOfferChipData(
          label: store.offerLabel!,
          icon: Icons.discount_outlined,
        ),
    ];
  }

  String _deliveryInfo() {
    final String dist = store.distance != null
        ? ' (${formatDistance(store.distance! / 1000)})'
        : '';
    return '${store.deliveryTime ?? ''}$dist'.trim();
  }

  FoodItem _toFoodItem(TopItem item) {
    final double base = item.price ?? 0;
    final double disc = item.discount ?? 0;
    final bool hasDisc = disc > 0;
    final double current = hasDisc
        ? (item.discountType == 'percent'
              ? base * (1 - disc / 100)
              : base - disc)
        : base;
    return FoodItem(
      imageUrl: item.imageFullUrl ?? '',
      restaurantName: store.name ?? '',
      restaurantLogoUrl: store.logoFullUrl ?? '',
      rating: item.avgRating ?? 0,
      itemName: item.name ?? '',
      price: current,
      originalPrice: hasDisc ? base : null,
      discountPercent: (hasDisc && item.discountType == 'percent')
          ? disc
          : null,
    );
  }

  // In the service module the "store" is a provider, so this routes to provider
  // details; otherwise it opens the store page. _openSearchStore handles both.
  void _openStore() => _openSearchStore(store);

  @override
  Widget build(BuildContext context) {
    final int total = storeItems.length;
    final bool showViewAll = total >= 5;
    final int count = showViewAll ? _maxInlineItems + 1 : total;

    return Padding(
      padding: EdgeInsets.only(bottom: showBottomDivider ? Dimensions.paddingSizeLarge : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
            ),
            child: RestaurantSummaryRow(
              restaurantName: store.name ?? '',
              restaurantLogoUrl: store.logoFullUrl ?? '',
              deliveryInfoText: _deliveryInfo(),
              offers: _buildOffers(),
              badgeText: store.sponsored == true ? 'AD' : null,
              onTap: _openStore,
              onArrowTap: _openStore,
            ),
          ),
          if (total > 0) ...<Widget>[
            Gaps.verticalGapOf(Dimensions.paddingSizeLarge),
            SizedBox(
              height: _storeItemRowHeight(context),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                primary: false,
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault,
                ),
                itemCount: count,
                separatorBuilder: (_, _) => Gaps.horizontalGapOf(Dimensions.paddingSizeSmall),
                itemBuilder: (BuildContext context, int index) {
                  if (showViewAll && index == _maxInlineItems) {
                    return _ViewAllCard(onTap: _openStore);
                  }
                  return RestaurantItemCard(
                    item: _toFoodItem(storeItems[index]),
                    width: _kStoreItemCardWidth,
                    // onTap: () => _openItem(storeItems[index], context),
                    onTap: _openStore,
                  );
                },
              ),
            ),
          ],
          if (showBottomDivider)
            Padding(
              padding: const EdgeInsets.only(top: Dimensions.paddingSizeLarge, right: Dimensions.paddingSizeLarge),
              child: Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
                indent: 16,
              ),
            ),
        ],
      ),
    );
  }
}

class _ViewAllCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ViewAllCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    final Color border = Theme.of(context).disabledColor.withValues(alpha: 0.2);
    final Color bg = Theme.of(context).disabledColor.withValues(alpha: 0.08);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: _kStoreItemCardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              height: _kStoreItemCardWidth,
              width: _kStoreItemCardWidth,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Center(
                child: Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: border),
                  ),
                  child: Icon(Icons.arrow_forward, size: 18, color: primary),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                'view_all'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
