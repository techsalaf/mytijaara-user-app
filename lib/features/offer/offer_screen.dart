import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/paginated_list_view.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/offer/domain/models/new_item_model.dart';
import 'package:sixam_mart/common/widgets/featured_store_card.dart';
import 'package:sixam_mart/common/widgets/food_item_card.dart';
import 'package:sixam_mart/common/widgets/exclusive_deal_card.dart';
import 'package:sixam_mart/common/widgets/store_offer_group.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/offer/controllers/offer_controller.dart';
import 'package:sixam_mart/features/service_module/common/models/service_provider_model.dart';
import 'package:sixam_mart/features/service_module/service_home/domain/models/service_model.dart';
import 'package:sixam_mart/features/service_module/provider_details/widgets/provider_service_item_widget.dart';
import 'package:sixam_mart/features/service_module/common/widgets/service_item_card.dart';
import 'package:sixam_mart/features/service_module/service_home/widgets/service_verified_provider_card_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/gaps.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

enum _OfferFilter { all, food, restaurants }

const Set<String> _excludedModuleTypes = <String>{
  AppConstants.parcel,
  AppConstants.taxi,
  AppConstants.ride,
};

List<ModuleModel> _visibleModulesFrom(SplashController splash) {
  final List<ModuleModel> modules = splash.moduleList ?? <ModuleModel>[];
  return modules.where((ModuleModel m) => !_excludedModuleTypes.contains(m.moduleType)).toList();
}

class OfferScreen extends StatefulWidget {
  final Function()? onBackPressed;
  const OfferScreen({super.key, this.onBackPressed});

  @override
  State<OfferScreen> createState() => _OfferScreenState();
}

class _OfferScreenState extends State<OfferScreen> {
  _OfferFilter _selectedFilter = _OfferFilter.all;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Debounces search input so continuous typing hits the offers API only once
  // the user pauses, instead of firing a request per keystroke.
  Timer? _searchDebounce;

  int _selectedVisibleIndex = 0;

  // The global module active when this screen was opened. Opening an offer detail
  // switches the global module (via _applySelectedModule) so the details API uses
  // the offer's module; on leaving we restore this so the caller screen keeps its
  // own module. For the dashboard tab (never disposed on tab switch) the dashboard
  // performs the restore; for pushed routes dispose() handles it.
  ModuleModel? _entryModule;

  @override
  void initState() {
    super.initState();

    final SplashController splash = Get.find<SplashController>();
    _entryModule = splash.module;
    final List<ModuleModel> visibleModules = _visibleModulesFrom(splash);

    int? initialModuleId;
    String? initialModuleType;
    if (visibleModules.isNotEmpty) {
      final ModuleModel? currentSplashModule = _moduleAtSplashIndex(splash, splash.selectedModuleIndex);
      int matchIndex = -1;
      if (currentSplashModule != null && !_excludedModuleTypes.contains(currentSplashModule.moduleType)) {
        matchIndex = visibleModules.indexWhere((ModuleModel m) => m.id == currentSplashModule.id);
      }
      _selectedVisibleIndex = matchIndex >= 0 ? matchIndex : 0;
      initialModuleId = visibleModules[_selectedVisibleIndex].id;
      initialModuleType = visibleModules[_selectedVisibleIndex].moduleType;
    }

    // Offers are scoped by explicit moduleId only — the dashboard's selected
    // module index is intentionally left untouched here.
    Get.find<OfferController>().loadOffers(
      type: _typeForFilter(_selectedFilter), search: '',
      moduleId: initialModuleId, moduleType: initialModuleType,
      clearModule: initialModuleId == null,
      reload: true, notify: false,
    );
  }

  ModuleModel? _moduleAtSplashIndex(SplashController splash, int splashIndex) {
    if (splashIndex <= 0) return null;
    final int moduleIndex = splashIndex - 1;
    if (splash.moduleList == null || moduleIndex >= splash.moduleList!.length) return null;
    return splash.moduleList![moduleIndex];
  }

  void _onModuleSelected(int visibleIndex, ModuleModel module) {
    setState(() => _selectedVisibleIndex = visibleIndex);
    // Filter offers by the picked module only (explicit moduleId). Do NOT change
    // the dashboard's selected module index, so returning to the main screen
    // keeps its own selection. Detail navigation handles the header via
    // _applySelectedModule().
    Get.find<OfferController>().setModuleFilter(module.id, moduleType: module.moduleType);
  }

  bool _isFoodModuleSelected(SplashController splash) {
    final List<ModuleModel> visibleModules = _visibleModulesFrom(splash);
    if (visibleModules.isEmpty || _selectedVisibleIndex >= visibleModules.length) return false;
    return visibleModules[_selectedVisibleIndex].moduleType == AppConstants.food;
  }

  @override
  void dispose() {
    // Restore the module that was active when this screen was opened (a pushed
    // route restores on pop here; the dashboard tab is restored by the dashboard).
    restoreEntryModule();
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Reverts any module change made while browsing offers back to the module that
  // was active on entry, so the screen we return to keeps its own module/header.
  void restoreEntryModule() {
    final SplashController splash = Get.find<SplashController>();
    if (splash.module?.id != _entryModule?.id) {
      splash.setModule(_entryModule, notify: false);
    }
  }

  String _typeForFilter(_OfferFilter filter) {
    switch (filter) {
      case _OfferFilter.food:
        return OfferController.typeItem;
      case _OfferFilter.restaurants:
        return OfferController.typeStore;
      case _OfferFilter.all:
        return OfferController.typeAll;
    }
  }

  void _selectFilter(_OfferFilter filter) {
    if (_selectedFilter == filter) return;
    setState(() => _selectedFilter = filter);
    Get.find<OfferController>().setSelectedType(_typeForFilter(filter));
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      Get.find<OfferController>().setSearchQuery(value);
    });
  }

  void _clearSearch() {
    // Clearing is explicit — apply immediately and drop any pending debounce.
    _searchDebounce?.cancel();
    _searchController.clear();
    Get.find<OfferController>().setSearchQuery('');
  }

  List<StoreOfferGroupData> _mapStoresToRestaurantData(List<Store>? stores) {
    if (stores == null || stores.isEmpty) return <StoreOfferGroupData>[];
    return stores.map(StoreOfferGroupData.fromStore).toList();
  }

  // Point the active module at the offer's selected module so item/store/service
  // details opened from here resolve under the correct module header.
  void _applySelectedModule() {
    final List<ModuleModel> visibleModules = _visibleModulesFrom(Get.find<SplashController>());
    if (visibleModules.isEmpty || _selectedVisibleIndex >= visibleModules.length) return;
    final ModuleModel module = visibleModules[_selectedVisibleIndex];
    final SplashController splash = Get.find<SplashController>();
    if (module.id != null && splash.module?.id != module.id) {
      splash.setModule(module, notify: false);
    }
  }

  // --- Food/ecommerce navigation ---

  void _openStore(StoreOfferGroupData data) {
    _applySelectedModule();
    Get.toNamed(RouteHelper.getStoreRoute(
      id: data.store.id, page: 'store_new', slug: data.store.slug ?? '',
    ));
  }

  void _openExclusiveStore(Store store) {
    _applySelectedModule();
    Get.toNamed(RouteHelper.getStoreRoute(
      id: store.id, page: 'store_new', slug: store.slug ?? '',
    ));
  }

  void _openItem(StoreOfferGroupData data, TopItem item) {
    _applySelectedModule();
    Get.find<ItemController>().navigateToItemPage(
      Item(id: item.id, name: item.name, slug: item.name?.replaceAll(' ', '_')), context, inStore: false, isCampaign: false,
    );
  }

  // --- Service module navigation ---

  void _openServiceItem(Service service) {
    _applySelectedModule();
    Get.toNamed(RouteHelper.getServiceDetailsRoute(id: service.id ?? 0, slug: service.slug ?? ''));
  }

  void _openProvider(Store store) {
    _applySelectedModule();
    final ServiceProvider provider = ServiceProvider.fromStore(store);
    Get.toNamed(
      RouteHelper.getProviderDetailsRoute(store.id ?? 0, slug: store.slug),
      arguments: provider,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color tinted = Color.alphaBlend(
      Theme.of(context).disabledColor.withAlpha(30),
      Theme.of(context).cardColor,
    );

    return Scaffold(
      backgroundColor: tinted,
      appBar: CustomAppBar(title: 'offers'.tr, backButton: true, onBackPressed: widget.onBackPressed),
      body: SafeArea(
        bottom: false,
        child: GetBuilder<OfferController>(builder: (controller) {
          final List<NewItem> items = controller.itemList?.items ?? <NewItem>[];
          final List<StoreOfferGroupData> restaurants = _mapStoresToRestaurantData(controller.storeList?.stores);
          final List<Store> exclusiveDeals = controller.exclusiveDeals ?? <Store>[];
          final int totalCount = controller.totalResultCount;
          final bool hasSearchText = controller.searchQuery.isNotEmpty;
          final bool isFood = _isFoodModuleSelected(Get.find<SplashController>());
          final bool isService = controller.isServiceModule;
          final Size screenSize = MediaQuery.of(context).size;
          final double moduleTabHeight = (screenSize.height * 0.045).clamp(32.0, 44.0);
          final double typeFilterHeight = (screenSize.height * 0.072).clamp(50.0, 64.0);
          // Hide the module tab strip when there's nothing to switch between
          // (single module active).
          final bool showModuleTabs = _visibleModulesFrom(Get.find<SplashController>()).length > 1;

          // Shimmer condition accounts for both food and service item lists.
          final bool showShimmer = controller.isLoading &&
              (isService ? controller.serviceItemList == null : controller.itemList == null) &&
              controller.storeList == null;

          return CustomScrollView(controller: _scrollController, slivers: <Widget>[

            if (showModuleTabs)
              SliverPersistentHeader(
                pinned: true,
                delegate: _PinnedHeaderDelegate(
                  height: moduleTabHeight,
                  child: _SolidBar(
                    color: Theme.of(context).cardColor,
                    child: _OfferModuleTabs(
                      selectedVisibleIndex: _selectedVisibleIndex,
                      onModuleSelected: _onModuleSelected,
                      height: moduleTabHeight,
                    ),
                  ),
                ),
              ),

            SliverToBoxAdapter(
              child: _OfferSearchBar(
                controller: _searchController,
                hasText: hasSearchText,
                onChanged: _onSearchChanged,
                onClear: _clearSearch,
              ),
            ),

            SliverPersistentHeader(
              pinned: true,
              delegate: _PinnedHeaderDelegate(
                height: typeFilterHeight,
                child: _OfferTypeFilterBar(
                  selected: _selectedFilter,
                  count: totalCount,
                  onSelected: _selectFilter,
                  isFood: isFood,
                  isService: isService,
                  isLoading: controller.isLoading,
                ),
              ),
            ),

            if (showShimmer)
              const SliverToBoxAdapter(child: _OfferShimmer())
            else
              SliverToBoxAdapter(
                // The All & Restaurants tabs paginate the vertical store/provider
                // list; the Food/Services tab paginates the vertical item list.
                // (In the All tab the items/services rail is horizontal, so it
                // stays on page one.)
                child: PaginatedListView(
                  scrollController: _scrollController,
                  totalSize: _selectedFilter == _OfferFilter.food
                      ? (isService ? controller.serviceItemList?.totalSize : controller.itemList?.totalSize)
                      : controller.storeList?.totalSize,
                  offset: _selectedFilter == _OfferFilter.food
                      ? (isService ? controller.serviceItemOffset : controller.itemOffset)
                      : controller.storeOffset,
                  onPaginate: _selectedFilter == _OfferFilter.food
                      ? (isService ? controller.paginateServiceItems : controller.paginateItems)
                      : controller.paginateStores,
                  itemView: isService
                      ? _buildServiceBody(context: context, controller: controller)
                      : _buildBody(
                          context: context,
                          items: items,
                          restaurants: restaurants,
                          exclusiveDeals: exclusiveDeals,
                          isFood: isFood,
                        ),
                ),
              ),

          ]);
        }),
      ),
    );
  }

  // ─── Food / Ecommerce / Grocery / Pharmacy body ────────────────────────────

  Widget _buildBody({
    required BuildContext context,
    required List<NewItem> items,
    required List<StoreOfferGroupData> restaurants,
    required List<Store> exclusiveDeals,
    required bool isFood,
  }) {
    if (_selectedFilter == _OfferFilter.food) {
      return _buildFoodOnlyBody(context: context, deals: items, isFood: isFood);
    }
    if (_selectedFilter == _OfferFilter.restaurants) {
      return _buildRestaurantOnlyBody(context: context, restaurants: restaurants, isFood: isFood);
    }

    if (items.isEmpty && restaurants.isEmpty && exclusiveDeals.isEmpty) {
      return _buildNoResultsView(context: context);
    }

    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final double cardWidth = math.max(100, viewportWidth * 0.35);
    final double textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final double cardHeight = cardWidth + Dimensions.paddingSizeDefault + 130 * textScale;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      if (items.isNotEmpty) ...<Widget>[
        Gaps.verticalGapOf(Dimensions.paddingSizeDefault),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: Text(isFood ? 'foods'.tr : 'items'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
        ),
        Gaps.verticalGapOf(Dimensions.paddingSizeDefault),
        _PaginatedItemsRail(items: items, cardWidth: cardWidth, cardHeight: cardHeight, onBeforeTap: _applySelectedModule),
      ],
      if (exclusiveDeals.isNotEmpty)
        _OfferExclusiveDealsSection(stores: exclusiveDeals, onStoreTap: _openExclusiveStore),
      if (restaurants.isNotEmpty) ...<Widget>[
        Gaps.verticalGapOf(Dimensions.paddingSizeSmall),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: Text(isFood ? 'restaurants'.tr : 'stores'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
        ),
        Gaps.verticalGapOf(Dimensions.paddingSizeLarge),
        ...restaurants.map((StoreOfferGroupData restaurant) {
          return StoreOfferGroup(
            data: restaurant,
            showBottomDivider: restaurant != restaurants.last,
            onStoreTap: () => _openStore(restaurant),
            onItemTap: (TopItem item) => _openItem(restaurant, item),
          );
        }),
      ],
      Gaps.verticalGapOf(Dimensions.paddingSizeSmall),
    ]);
  }

  Widget _buildFoodOnlyBody({
    required BuildContext context,
    required List<NewItem> deals,
    required bool isFood,
  }) {
    if (deals.isEmpty) {
      return _buildNoResultsView(context: context);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Gaps.verticalGapOf(Dimensions.paddingSizeDefault),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        child: Text(isFood ? 'all_food_result'.tr : 'all_item_result'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
      ),
      Gaps.verticalGapOf(Dimensions.paddingSizeDefault),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        child: Column(
          children: deals.map((NewItem deal) {
            final bool isLast = identical(deal, deals.last);
            return Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : Dimensions.paddingSizeDefault),
              padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                border: isLast ? null : Border(
                  bottom: BorderSide(color: Theme.of(context).disabledColor.withValues(alpha: 0.18)),
                ),
              ),
              child: ExclusiveDealCard(item: deal.toItem(), width: double.infinity, onBeforeTap: _applySelectedModule),
            );
          }).toList(),
        ),
      ),
      Gaps.verticalGapOf(Dimensions.paddingSizeSmall),
    ]);
  }

  Widget _buildRestaurantOnlyBody({
    required BuildContext context,
    required List<StoreOfferGroupData> restaurants,
    required bool isFood,
  }) {
    if (restaurants.isEmpty) {
      return _buildNoResultsView(context: context);
    }
    final double storeImageHeight = (MediaQuery.of(context).size.width * 0.38).clamp(130.0, 220.0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Gaps.verticalGapOf(Dimensions.paddingSizeDefault),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        child: Text(isFood ? 'all_restaurant_result'.tr : 'all_store_result'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
      ),
      Gaps.verticalGapOf(Dimensions.paddingSizeLarge),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        child: Column(
          children: restaurants.map((StoreOfferGroupData restaurant) {
            return Padding(
              padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
              child: FeaturedStoreCard(
                data: restaurant.store, width: double.infinity, imageHeight: storeImageHeight, isQuick: false,
                onTap: () => _openStore(restaurant),
              ),
            );
          }).toList(),
        ),
      ),
      Gaps.verticalGapOf(Dimensions.paddingSizeSmall),
    ]);
  }

  // ─── Service module body ────────────────────────────────────────────────────

  Widget _buildServiceBody({required BuildContext context, required OfferController controller}) {
    final List<Service> services = controller.serviceItemList?.services ?? <Service>[];
    final List<Store> providers = controller.storeList?.stores ?? <Store>[];

    if (_selectedFilter == _OfferFilter.food) {
      return _buildServiceOnlyBody(context: context, services: services);
    }
    if (_selectedFilter == _OfferFilter.restaurants) {
      return _buildProviderOnlyBody(context: context, providers: providers);
    }

    // All tab
    if (services.isEmpty && providers.isEmpty) {
      return _buildNoResultsView(context: context);
    }

    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final double cardWidth = math.max(100, viewportWidth * 0.35);
    final double textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final double cardHeight = cardWidth + Dimensions.paddingSizeDefault + 130 * textScale;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      if (services.isNotEmpty) ...<Widget>[
        Gaps.verticalGapOf(Dimensions.paddingSizeDefault),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: Text('services'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
        ),
        Gaps.verticalGapOf(Dimensions.paddingSizeDefault),
        _PaginatedServiceItemsRail(services: services, cardWidth: cardWidth, cardHeight: cardHeight, onTap: _openServiceItem),
      ],
      if (providers.isNotEmpty) ...<Widget>[
        Gaps.verticalGapOf(Dimensions.paddingSizeSmall),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: Text('providers'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
        ),
        Gaps.verticalGapOf(Dimensions.paddingSizeLarge),
        // Mirror the other modules' All tab: each provider renders as a store
        // group (header + horizontal top-services rail) via StoreOfferGroup.
        ...providers.map((Store store) {
          return StoreOfferGroup(
            data: StoreOfferGroupData.fromStore(store),
            showBottomDivider: store != providers.last,
            onStoreTap: () => _openProvider(store),
            onItemTap: (TopItem item) => _openServiceTopItem(item),
          );
        }),
      ],
      Gaps.verticalGapOf(Dimensions.paddingSizeSmall),
    ]);
  }

  // Opens a provider's top service (from the All-tab provider group). Applies the
  // offer's selected module first so details resolve under the correct module.
  void _openServiceTopItem(TopItem item) {
    _applySelectedModule();
    Get.toNamed(RouteHelper.getServiceDetailsRoute(id: item.id ?? 0, slug: item.slug ?? ''));
  }

  Widget _buildServiceOnlyBody({required BuildContext context, required List<Service> services}) {
    if (services.isEmpty) {
      return _buildNoResultsView(context: context);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Gaps.verticalGapOf(Dimensions.paddingSizeDefault),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        child: Text('all_service_result'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
      ),
      ...services.map((Service service) {
        final bool isLast = identical(service, services.last);
        return Column(children: [
          ProviderServiceItemWidget(service: service, onBeforeTap: _applySelectedModule),
          if (!isLast) Divider(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.18),
            height: 1, indent: Dimensions.paddingSizeDefault, endIndent: Dimensions.paddingSizeDefault,
          ),
        ]);
      }),
      Gaps.verticalGapOf(Dimensions.paddingSizeSmall),
    ]);
  }

  Widget _buildProviderOnlyBody({required BuildContext context, required List<Store> providers}) {
    if (providers.isEmpty) {
      return _buildNoResultsView(context: context);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Gaps.verticalGapOf(Dimensions.paddingSizeDefault),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        child: Text('all_provider_result'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
      ),
      Gaps.verticalGapOf(Dimensions.paddingSizeLarge),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        child: Column(
          children: providers.map((Store store) {
            final ServiceProvider provider = ServiceProvider.fromStore(store);
            return Padding(
              padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
              child: GestureDetector(
                onTap: () => _openProvider(store),
                child: AbsorbPointer(
                  child: ServiceVerifiedProviderCard(provider: provider, width: double.infinity),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      Gaps.verticalGapOf(Dimensions.paddingSizeSmall),
    ]);
  }

  Widget _buildNoResultsView({required BuildContext context}) {
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
          'no_offers_available'.tr,
          style: robotoMedium.copyWith(
            fontSize: Dimensions.fontSizeDefault,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }
}

// Horizontal items rail for the All tab (food/ecommerce). Paginates the item
// list sideways: scrolling to the right edge fetches the next page and appends
// to the rail, independent of the vertical store pagination.
class _PaginatedItemsRail extends StatefulWidget {
  final List<NewItem> items;
  final double cardWidth;
  final double cardHeight;
  final VoidCallback? onBeforeTap;

  const _PaginatedItemsRail({required this.items, required this.cardWidth, required this.cardHeight, this.onBeforeTap});

  @override
  State<_PaginatedItemsRail> createState() => _PaginatedItemsRailState();
}

class _PaginatedItemsRailState extends State<_PaginatedItemsRail> {
  final ScrollController _railController = ScrollController();
  int _offset = 1;
  List<int> _offsetList = <int>[1];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _railController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _railController.removeListener(_handleScroll);
    _railController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_isLoading || !_railController.hasClients) return;
    final int? total = Get.find<OfferController>().itemList?.totalSize;
    if (total == null) return;
    if (_railController.position.pixels >= _railController.position.maxScrollExtent - 100) {
      _paginate(total);
    }
  }

  Future<void> _paginate(int total) async {
    final int pageSize = (total / OfferController.pageLimit).ceil();
    if (_offset >= pageSize || _offsetList.contains(_offset + 1)) return;

    setState(() {
      _offset += 1;
      _offsetList.add(_offset);
      _isLoading = true;
    });
    await Get.find<OfferController>().paginateItems(_offset);
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // Sync to the controller's offset so a tab/module/search reset (offset → 1)
    // also resets the rail's pagination.
    _offset = Get.find<OfferController>().itemOffset;
    _offsetList = <int>[for (int i = 1; i <= _offset; i++) i];

    final int count = widget.items.length + (_isLoading ? 1 : 0);
    return SizedBox(
      height: widget.cardHeight,
      child: ListView.separated(
        controller: _railController,
        scrollDirection: Axis.horizontal,
        primary: false,
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        itemCount: count,
        separatorBuilder: (BuildContext context, int index) => Gaps.horizontalGapOf(Dimensions.paddingSizeSmall),
        itemBuilder: (BuildContext context, int index) {
          if (index >= widget.items.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            );
          }
          return FoodItemCard(data: widget.items[index].toItem(), width: widget.cardWidth, index: index, onBeforeTap: widget.onBeforeTap);
        },
      ),
    );
  }
}

// Horizontal services rail for the All tab (service module). Mirrors
// _PaginatedItemsRail but uses ServiceItemCard and serviceItemList.
class _PaginatedServiceItemsRail extends StatefulWidget {
  final List<Service> services;
  final double cardWidth;
  final double cardHeight;
  final void Function(Service) onTap;

  const _PaginatedServiceItemsRail({
    required this.services, required this.cardWidth, required this.cardHeight, required this.onTap,
  });

  @override
  State<_PaginatedServiceItemsRail> createState() => _PaginatedServiceItemsRailState();
}

class _PaginatedServiceItemsRailState extends State<_PaginatedServiceItemsRail> {
  final ScrollController _railController = ScrollController();
  int _offset = 1;
  List<int> _offsetList = <int>[1];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _railController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _railController.removeListener(_handleScroll);
    _railController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_isLoading || !_railController.hasClients) return;
    final int? total = Get.find<OfferController>().serviceItemList?.totalSize;
    if (total == null) return;
    if (_railController.position.pixels >= _railController.position.maxScrollExtent - 100) {
      _paginate(total);
    }
  }

  Future<void> _paginate(int total) async {
    final int pageSize = (total / OfferController.pageLimit).ceil();
    if (_offset >= pageSize || _offsetList.contains(_offset + 1)) return;

    setState(() {
      _offset += 1;
      _offsetList.add(_offset);
      _isLoading = true;
    });
    await Get.find<OfferController>().paginateServiceItems(_offset);
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // Sync to the controller's offset so a tab/module/search reset (offset → 1)
    // also resets the rail's pagination.
    _offset = Get.find<OfferController>().serviceItemOffset;
    _offsetList = <int>[for (int i = 1; i <= _offset; i++) i];

    final int count = widget.services.length + (_isLoading ? 1 : 0);
    return SizedBox(
      height: widget.cardHeight,
      child: ListView.separated(
        controller: _railController,
        scrollDirection: Axis.horizontal,
        primary: false,
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        itemCount: count,
        separatorBuilder: (BuildContext context, int index) => Gaps.horizontalGapOf(Dimensions.paddingSizeSmall),
        itemBuilder: (BuildContext context, int index) {
          if (index >= widget.services.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            );
          }
          final Service service = widget.services[index];
          return ServiceItemCard(service: service, width: widget.cardWidth, onTap: () => widget.onTap(service));
        },
      ),
    );
  }
}

// In-screen search field.
class _OfferSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool hasText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _OfferSearchBar({required this.controller, required this.hasText, required this.onChanged, required this.onClear});

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
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          style: robotoRegular.copyWith(
            fontSize: Dimensions.fontSizeDefault,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'search_for_offers'.tr,
            hintStyle: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: hintColor),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
              vertical: Dimensions.paddingSizeSmall + 2,
            ),
            suffixIcon: hasText
                ? GestureDetector(
                    onTap: onClear,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(right: Dimensions.paddingSizeDefault),
                      child: Icon(Icons.close, size: 20, color: hintColor),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(right: Dimensions.paddingSizeDefault),
                    child: Icon(Icons.search, size: 20, color: hintColor),
                  ),
            suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          ),
        ),
      ),
    );
  }
}

// Opaque wrapper so the underlying scroll content can't bleed through.
class _SolidBar extends StatelessWidget {
  final Color color;
  final Widget child;
  const _SolidBar({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(color: color, elevation: 0, child: child);
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

// Module tab strip — excludes home, parcel, rental and ride-share modules.
class _OfferModuleTabs extends StatelessWidget {
  final int selectedVisibleIndex;
  final void Function(int visibleIndex, ModuleModel module) onModuleSelected;
  final double height;

  const _OfferModuleTabs({required this.selectedVisibleIndex, required this.onModuleSelected, required this.height});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashController>(builder: (splashController) {
      final List<ModuleModel> visibleModules = _visibleModulesFrom(splashController);
      if (visibleModules.isEmpty) return const SizedBox.shrink();

      final int safeSelected = selectedVisibleIndex >= visibleModules.length ? 0 : selectedVisibleIndex;

      return DefaultTabController(
        key: ValueKey('offer-module-tab-$safeSelected-${visibleModules.length}'),
        length: visibleModules.length,
        initialIndex: safeSelected,
        child: Center(
          child: SizedBox(
            height: height,
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
              labelPadding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              indicator: BoxDecoration(
                color: Theme.of(context).disabledColor.withAlpha(30),
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
              onTap: (index) => onModuleSelected(index, visibleModules[index]),
              tabs: visibleModules.map((ModuleModel module) {
                return Tab(text: _moduleLabel(module.moduleName, module.moduleType ?? ''));
              }).toList(),
            ),
          ),
        ),
      );
    });
  }

  String _moduleLabel(String? moduleName, String moduleType) {
    if (moduleName != null && moduleName.trim().isNotEmpty) return moduleName;
    if (moduleType == AppConstants.food) return 'Food';
    if (moduleType == AppConstants.grocery) return 'Grocery';
    if (moduleType == AppConstants.ecommerce) return 'Shop';
    if (moduleType == AppConstants.pharmacy) return 'Pharmacy';
    if (moduleType == AppConstants.service) return 'Service';
    return moduleType.isNotEmpty ? moduleType : 'Module';
  }
}

class _OfferTypeFilterBar extends StatelessWidget {
  final _OfferFilter selected;
  final int count;
  final ValueChanged<_OfferFilter> onSelected;
  final bool isFood;
  final bool isService;
  final bool isLoading;

  const _OfferTypeFilterBar({
    required this.selected, required this.count, required this.onSelected, required this.isFood, required this.isService,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final Color divider = Theme.of(context).disabledColor.withAlpha(60);
    final Color tinted = Color.alphaBlend(
      Theme.of(context).disabledColor.withAlpha(30),
      Theme.of(context).cardColor,
    );

    final String itemLabel = isService ? 'services'.tr : (isFood ? 'food'.tr : 'items'.tr);
    final String storeLabel = isService ? 'providers'.tr : (isFood ? 'restaurants'.tr : 'stores'.tr);

    final List<(_OfferFilter, String)> tabs = <(_OfferFilter, String)>[
      (_OfferFilter.all, 'all'.tr),
      (_OfferFilter.food, itemLabel),
      (_OfferFilter.restaurants, storeLabel),
    ];

    return _SolidBar(
      color: tinted,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                _ResultCountBar(count: count, isLoading: isLoading),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeDefault,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List<Widget>.generate(tabs.length, (index) {
                      final (_OfferFilter filter, String label) = tabs[index];
                      return _FilterChipItem(
                        label: label,
                        isSelected: filter == selected,
                        onTap: () => onSelected(filter),
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

class _FilterChipItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipItem({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    final Color textColor = isSelected
        ? Colors.white
        : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return InkWell(
      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeSmall,
        ),
        decoration: BoxDecoration(
          color: isSelected ? primary : null,
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

class _ResultCountBar extends StatelessWidget {
  final int count;
  final bool isLoading;
  const _ResultCountBar({required this.count, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeSmall,
      ),
      // While a fresh page is fetching the result total is not yet known, so show
      // a shimmer placeholder instead of a misleading "0 results".
      child: isLoading
          ? Shimmer(
              duration: const Duration(seconds: 2),
              child: const _ShimmerBar(width: 56, height: 14),
            )
          : Text(
              '$count ${'results'.tr}',
              style: robotoBold.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).disabledColor,
              ),
            ),
    );
  }
}

// Horizontal "Exclusive Deals" store carousel shown in the All tab (after the
// items rail), for non-service modules only.
class _OfferExclusiveDealsSection extends StatelessWidget {
  final List<Store> stores;
  final void Function(Store store) onStoreTap;

  const _OfferExclusiveDealsSection({required this.stores, required this.onStoreTap});

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
            separatorBuilder: (BuildContext context, int index) => const SizedBox(width: Dimensions.paddingSizeDefault),
            itemBuilder: (BuildContext context, int index) {
              final Store store = stores[index];
              return FeaturedStoreCard(
                data: store,
                width: cardWidth,
                imageHeight: imageHeight,
                isQuick: false,
                onTap: () => onStoreTap(store),
              );
            },
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
      ]),
    );
  }
}

// Initial-load placeholder that mirrors the offer body (an items rail + a few
// store-offer cards), shown only while the first page is fetching.
class _OfferShimmer extends StatelessWidget {
  const _OfferShimmer();

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double cardWidth = screenSize.width * 0.40;
    final double itemListHeight = cardWidth + (screenSize.height * 0.19).clamp(140.0, 170.0);
    final double storeImageHeight = (screenSize.width * 0.38).clamp(130.0, 220.0);

    return Shimmer(
      duration: const Duration(seconds: 2),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[

        // Items rail.
        Gaps.verticalGapOf(Dimensions.paddingSizeDefault),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: _ShimmerBar(width: 120, height: 18),
        ),
        Gaps.verticalGapOf(Dimensions.paddingSizeDefault),
        SizedBox(
          height: itemListHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            primary: false,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            itemCount: 4,
            separatorBuilder: (BuildContext context, int index) => Gaps.horizontalGapOf(Dimensions.paddingSizeSmall),
            itemBuilder: (BuildContext context, int index) => _ShimmerItemCard(width: cardWidth),
          ),
        ),

        // Store-offer cards.
        Gaps.verticalGapOf(Dimensions.paddingSizeDefault),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: _ShimmerBar(width: 150, height: 18),
        ),
        Gaps.verticalGapOf(Dimensions.paddingSizeLarge),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: Column(
            children: List<Widget>.generate(3, (int index) => Padding(
              padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
              child: _ShimmerStoreCard(imageHeight: storeImageHeight),
            )),
          ),
        ),
        Gaps.verticalGapOf(Dimensions.paddingSizeSmall),
      ]),
    );
  }
}

class _ShimmerItemCard extends StatelessWidget {
  final double width;

  const _ShimmerItemCard({required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        _ShimmerBox(height: width, width: width, radius: Dimensions.radiusExtraLarge),
        const SizedBox(height: Dimensions.paddingSizeDefault),
        _ShimmerBar(width: width * 0.9, height: 12),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        _ShimmerBar(width: width * 0.6, height: 12),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        _ShimmerBar(width: width * 0.4, height: 14),
      ]),
    );
  }
}

class _ShimmerStoreCard extends StatelessWidget {
  final double imageHeight;

  const _ShimmerStoreCard({required this.imageHeight});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      _ShimmerBox(height: imageHeight, radius: Dimensions.radiusDefault),
      const SizedBox(height: Dimensions.paddingSizeSmall),
      const _ShimmerBar(width: 180, height: 14),
      const SizedBox(height: Dimensions.paddingSizeSmall),
      const _ShimmerBar(width: 120, height: 12),
    ]);
  }
}

class _ShimmerBox extends StatelessWidget {
  final double height;
  final double? width;
  final double radius;

  const _ShimmerBox({required this.height, this.width, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(color: _shimmerColor(context), borderRadius: BorderRadius.circular(radius)),
    );
  }
}

class _ShimmerBar extends StatelessWidget {
  final double width;
  final double height;

  const _ShimmerBar({required this.width, this.height = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(color: _shimmerColor(context), borderRadius: BorderRadius.circular(99)),
    );
  }
}

Color _shimmerColor(BuildContext context) {
  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? Colors.white.withValues(alpha: 0.18) : const Color(0xFFE9E9E9);
}
