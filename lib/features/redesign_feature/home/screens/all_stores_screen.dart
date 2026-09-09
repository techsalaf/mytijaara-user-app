import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/paginated_list_view.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/common_widget/featured_store_card.dart';
import 'package:sixam_mart/features/redesign_feature/global_widgets/store_offer_group.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

enum AllStoresMode { quickDelivery, topRated, nearBy}

class AllStoresScreen extends StatefulWidget {
  final AllStoresMode mode;
  // Pre-filled search query for nearBy mode (e.g. opened from search "near me").
  final String? initialSearch;
  const AllStoresScreen({super.key, this.mode = AllStoresMode.quickDelivery, this.initialSearch});

  @override
  State<AllStoresScreen> createState() => _AllStoresScreenState();
}

class _AllStoresScreenState extends State<AllStoresScreen> {
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();

    // Pre-fill the nearby search box when a query was passed in (e.g. "near me").
    final String initialNearbyQuery = widget.mode == AllStoresMode.nearBy
        ? (widget.initialSearch?.trim() ?? '')
        : '';
    if(initialNearbyQuery.isNotEmpty) {
      _searchController.text = initialNearbyQuery;
    }

    final StoreController controller = Get.find<StoreController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(!mounted) return;
      if(widget.mode == AllStoresMode.topRated) {
        // Dedicated top-rated list — reload with a loader, independent of the
        // shared Explore Stores state.
        controller.getTopRatedStoreList(reload: true);
      } else if(widget.mode == AllStoresMode.nearBy) {
        // Distance-sorted stores — location sensitive, so always reload. Use the
        // passed query (empty resets any term left over from a previous visit).
        controller.getNearbyStoreList(reload: true, name: initialNearbyQuery);
      } else {
        // Dedicated express-delivery list — reload with a loader so its search
        // never mutates the shared home quick-delivery section.
        controller.getExpressDeliveryStoreList(reload: true, name: '');
      }
    });
  }

  @override
  void dispose() {
    // Drop the dedicated lists so the next visit starts fresh (loader, no stale
    // data) and the search term never leaks into a later visit.
    final StoreController controller = Get.find<StoreController>();
    if(widget.mode == AllStoresMode.topRated) {
      controller.clearTopRatedStoreList();
    } else if(widget.mode == AllStoresMode.quickDelivery) {
      controller.clearExpressDeliveryStoreList();
    }
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _search(value.trim());
    });
  }

  void _onClearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    _search('');
  }

  // Forwards the (debounced) search term to the active mode's controller method,
  // each of which reloads page 1 server-side and reuses the term while paginating.
  void _search(String name) {
    final StoreController controller = Get.find<StoreController>();
    switch(widget.mode) {
      case AllStoresMode.quickDelivery:
        controller.getExpressDeliveryStoreList(reload: true, name: name);
      case AllStoresMode.nearBy:
        controller.getNearbyStoreList(reload: true, name: name);
      case AllStoresMode.topRated:
        controller.getTopRatedStoreList(reload: true, name: name);
    }
  }

  // Called by PaginatedListView when the next page is needed.
  Future<void> _onPaginate(int? offset) async {
    final StoreController controller = Get.find<StoreController>();
    switch(widget.mode) {
      case AllStoresMode.quickDelivery:
        await controller.loadMoreExpressDeliveryStores();
      case AllStoresMode.nearBy:
        await controller.loadMoreNearbyStores();
      case AllStoresMode.topRated:
        await controller.loadMoreTopRatedStores();
    }
  }

  Future<void> _onRefresh() async {
    final StoreController controller = Get.find<StoreController>();
    if(widget.mode == AllStoresMode.quickDelivery) {
      await controller.getExpressDeliveryStoreList(reload: true);
    } else if(widget.mode == AllStoresMode.nearBy) {
      await controller.getNearbyStoreList(reload: true);
    } else {
      await controller.getTopRatedStoreList(reload: true);
    }
  }

  void _openStore(StoreOfferGroupData data) {
    Get.toNamed(RouteHelper.getStoreRoute(
      id: data.store.id, page: 'store_new', slug: data.store.slug ?? '',
    ));
  }

  String _title() => switch(widget.mode) {
    AllStoresMode.quickDelivery => 'express_delivery'.tr,
    AllStoresMode.topRated => 'top_rated'.tr,
    AllStoresMode.nearBy => 'nearby'.tr,
  };

  @override
  Widget build(BuildContext context) {
    final Color tinted = Color.alphaBlend(
      Theme.of(context).disabledColor.withAlpha(30),
      Theme.of(context).cardColor,
    );
    const double bottomNavClearance = 10; //+ Dimensions.paddingSizeDefault + MediaQuery.of(context).padding.bottom + Dimensions.paddingSizeDefault;

    return Scaffold(
      backgroundColor: tinted,
      appBar: CustomAppBar(title: _title(), backButton: true),
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          _StoreSearchField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            onClear: _onClearSearch,
          ),

          Expanded(
            child: GetBuilder<StoreController>(builder: (controller) {
              final (List<StoreOfferGroupData> rows, bool isInitialLoading, int? totalSize, int? offset) = _resolveData(controller);

              if(isInitialLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if(rows.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                        child: Center(
                          child: Text(
                            'no_data_found'.tr,
                            style: robotoMedium.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              color: Theme.of(context).disabledColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _onRefresh,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                  child: Column(children: [
                    PaginatedListView(
                      scrollController: _scrollController,
                      totalSize: totalSize,
                      offset: offset,
                      onPaginate: _onPaginate,
                      itemView: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: rows.length,
                        itemBuilder: (context, index) {
                          final StoreOfferGroupData data = rows[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.paddingSizeDefault,
                              vertical: Dimensions.paddingSizeExtraSmall,
                            ),
                            child: FeaturedStoreCard(
                              data: data.store,
                              width: double.infinity,
                              imageHeight: 150,
                              isQuick: widget.mode == AllStoresMode.quickDelivery,
                              onTap: () => _openStore(data),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: bottomNavClearance),
                  ]),
                ),
              );
            }),
          ),
        ]),
      ),
    );
  }

  // Returns (rows, isInitialLoading, totalSize, currentOffset) for the active mode.
  (List<StoreOfferGroupData>, bool, int?, int?) _resolveData(StoreController controller) {
    final StoreModel? model = switch(widget.mode) {
      AllStoresMode.quickDelivery => controller.expressDeliveryStoreList,
      AllStoresMode.nearBy => controller.nearbyStoreList,
      AllStoresMode.topRated => controller.topRatedStoreList,
    };
    final List<Store> stores = model?.stores ?? const <Store>[];
    return (
      stores.map(StoreOfferGroupData.fromStore).toList(),
      model == null,
      model?.totalSize,
      model?.offset,
    );
  }
}

class _StoreSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _StoreSearchField({required this.controller, required this.onChanged, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall,
        Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
        decoration: InputDecoration(
          hintText: 'search_stores'.tr,
          hintStyle: robotoRegular.copyWith(
            fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).disabledColor,
          ),
          prefixIcon: Icon(Icons.search, color: Theme.of(context).disabledColor),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (BuildContext context, TextEditingValue value, Widget? child) {
              if(value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: Icon(Icons.clear, color: Theme.of(context).disabledColor),
                onPressed: onClear,
              );
            },
          ),
          isDense: true,
          filled: true,
          fillColor: Theme.of(context).cardColor,
          contentPadding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
            borderSide: BorderSide(color: Theme.of(context).disabledColor.withValues(alpha: 0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
            borderSide: BorderSide(color: Theme.of(context).disabledColor.withValues(alpha: 0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
            borderSide: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.5)),
          ),
        ),
      ),
    );
  }
}
