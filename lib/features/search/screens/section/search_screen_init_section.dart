part of '../search_screen.dart';

// Height of a circular-image + label row (brands / top categories), scaled by the
// device text scale so the label never clips on large fonts. Floored at [floor] to
// keep the current look at the default text scale.
double _initCircleRowHeight(BuildContext context, {required double imageSize, required int labelLines, required double floor}) {
  final double textScale = MediaQuery.textScalerOf(context).scale(1.0);
  final double labelHeight = Dimensions.fontSizeSmall * 1.3 * labelLines * textScale;
  return (imageSize + Dimensions.paddingSizeExtraSmall + labelHeight).clamp(floor, double.infinity).toDouble();
}

class _SearchScreenInitSection extends StatelessWidget {
  final search.SearchController searchController;
  final TextEditingController searchTextController;
  final bool isLoggedIn;

  const _SearchScreenInitSection({
    required this.searchController, required this.searchTextController, required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    // Top Brands only apply to grocery and shop (ecommerce) modules.
    final String? moduleType = Get.find<SplashController>().module?.moduleType;
    final bool isBrandModule = moduleType == AppConstants.grocery || moduleType == AppConstants.ecommerce;
    return SizedBox(width: Dimensions.webMaxWidth, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      if (searchController.recentSearchList.isNotEmpty) Padding(
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeDefault),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('recent_searches'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge)),
          InkWell(
            onTap: () => searchController.clearSearchHistory(),
            child: Text('clear_all'.tr, style: robotoMedium.copyWith(
              fontSize: Dimensions.fontSizeDefault, color: Colors.red,
            )),
          ),
        ]),
      ),

      if (searchController.recentSearchList.isNotEmpty) ListView.builder(
        itemCount: searchController.recentSearchList.length,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        itemBuilder: (context, index) {
          final RecentSearchEntry entry = searchController.recentSearchList[index];
          return _RecentSearchTile(
            entry: entry,
            isGlobal: searchController.isGlobalSearch,
            onTap: () {
              FocusScope.of(context).unfocus();
              searchTextController.text = entry.name;
              searchController.searchData(entry.name, false, recentEntry: entry);
            },
            onRemove: () => searchController.removeRecentSearch(entry),
          );
        },
      ),

      // Only separate from the recent-search list when it's actually shown.
      SizedBox(height: searchController.recentSearchList.isNotEmpty ? Dimensions.paddingSizeSmall : 0),

      searchController.trendingSearchList == null
          ? const _TrendingSearchShimmer()
          : searchController.trendingSearchList!.isNotEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeDefault),
                  decoration: BoxDecoration(color: Theme.of(context).disabledColor.withValues(alpha: 0.1)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    Text('trending_searches'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge)),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    Wrap(
                      children: searchController.trendingSearchList!.map((TrendingSearch trending) {
                        final String keyword = trending.keyword ?? '';
                        final bool isLoading = searchController.isTrendingLoading(trending);
                        return Padding(
                          padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall, bottom: Dimensions.paddingSizeSmall),
                          child: CustomInkWell(
                            onTap: isLoading ? null : () {
                              FocusScope.of(context).unfocus();
                              searchTextController.text = keyword;
                              // When the trending keyword has no module, the controller resolves
                              // it from the first suggestion before scoping the result view.
                              searchController.searchFromTrending(trending);
                            },
                            radius: 50,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(color: Theme.of(context).disabledColor, width: 0.1),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Flexible(child: Text(
                                  keyword,
                                  style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyMedium!.color!),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                )),
                                if (isLoading) ...[
                                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                                  SizedBox(
                                    width: 12, height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 1.5, color: Theme.of(context).primaryColor),
                                  ),
                                ],
                              ]),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ]),
                )
              : const SizedBox(),

      SizedBox(height: searchController.trendingSearchList != null && searchController.trendingSearchList!.isNotEmpty ? Dimensions.paddingSizeDefault : 0),

      // Global search shows Top Categories; module-wise search shows Top Brands.
      if (searchController.isGlobalSearch) ...[
        if (searchController.topCategoryList == null || searchController.topCategoryList!.isNotEmpty)
          _TopCategoriesSection(categories: searchController.topCategoryList),
      ] else if (isBrandModule && (searchController.brandList == null || searchController.brandList!.isNotEmpty))
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: searchController.brandList == null ?  Container(color: Theme.of(context).disabledColor.withValues(alpha: 0.12), width:  140, height: 25)
             : Text('top_brands'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge)),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          SizedBox(
            height: _initCircleRowHeight(context, imageSize: 72, labelLines: 1, floor: 100),
            child: searchController.brandList == null
                ? _BrandShimmer()
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: searchController.brandList!.length,
                    separatorBuilder: (_, _) => const SizedBox(width: Dimensions.paddingSizeDefault),
                    itemBuilder: (BuildContext context, int index) {
                      final BrandModel brand = searchController.brandList![index];
                      return Padding(
                        padding: EdgeInsets.only(
                          left: index == 0 ? Dimensions.paddingSizeDefault : 0,
                          right: index == searchController.brandList!.length - 1 ? Dimensions.paddingSizeDefault : 0,
                        ),
                        child: InkWell(
                          onTap: brand.id != null && brand.name != null
                              ? () {
                                  FocusScope.of(context).unfocus();
                                  Get.toNamed(RouteHelper.getBrandsItemScreen(brand.id!, brand.name!, slug: brand.slug ?? ''));
                                }
                              : null,
                          child: BrandItemWidget(image: brand.imageFullUrl, label: brand.name, showLabel: true, showSubTitle: false,),
                        ),
                      );
                    },
                  ),
          ),

          const Divider(),
        ]),

      const SizedBox(height: Dimensions.paddingSizeDefault),

      // Featured stores & restaurants — same data/card as HomeNewScreen.
      TopPicksNearYouWidget(title: 'featured'.tr, isFeatured: true),

      const SizedBox(height: Dimensions.paddingSizeDefault + 6),

    ]));
  }
}

// A single recent-search row. In global (no-module) mode it shows the module
// image + an "is a … Item / Restaurant" subtitle; in module-wise mode it shows
// a generic kind icon (item / store / keyword) with the name only.
class _RecentSearchTile extends StatelessWidget {
  final RecentSearchEntry entry;
  final bool isGlobal;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _RecentSearchTile({required this.entry, required this.isGlobal, required this.onTap, required this.onRemove});

  // Resolve the entry's module from the loaded list — by id first, then by
  // type — so older entries or sparse module ids still render a logo/name.
  ModuleModel? _module() {
    final List<ModuleModel>? modules = Get.find<SplashController>().moduleList;
    if (modules == null) return null;
    if (entry.moduleId != null) {
      for (final ModuleModel module in modules) {
        if (module.id == entry.moduleId) return module;
      }
    }
    if (entry.moduleType != null) {
      for (final ModuleModel module in modules) {
        if (module.moduleType == entry.moduleType) return module;
      }
    }
    return null;
  }

  IconData _kindIcon() {
    switch (entry.kind) {
      case RecentSearchKind.item:
        return CupertinoIcons.cube_box;
      case RecentSearchKind.store:
        return Icons.storefront_outlined;
      case RecentSearchKind.keyword:
        return Icons.history;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showModuleStyle = isGlobal && entry.kind != RecentSearchKind.keyword;
    final ModuleModel? module = _module();
    final String? moduleImage = entry.moduleImage?.isNotEmpty == true
        ? entry.moduleImage
        : (module?.iconFullUrl ?? module?.thumbnailFullUrl);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
        child: Row(children: [

          (showModuleStyle && (moduleImage?.isNotEmpty ?? false))
              ? Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
            padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
            child: CustomImage(image: moduleImage!, fit: BoxFit.cover),
          )
              : Icon(_kindIcon(), size: 20, color: Theme.of(context).disabledColor),
          const SizedBox(width: Dimensions.paddingSizeDefault),

          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                entry.name,
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              // if (showModuleStyle) ...[
              //   const SizedBox(height: 2),
              //   Text(
              //     _subtitle(),
              //     style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor),
              //     maxLines: 1, overflow: TextOverflow.ellipsis,
              //   ),
              // ],
            ],
          )),

          InkWell(
            onTap: onRemove,
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
              child: Icon(Icons.close, color: Theme.of(context).disabledColor, size: 20),
            ),
          ),

        ]),
      ),
    );
  }
}

// Top Categories row (global search only) — circular image + name, like the brands row.
class _TopCategoriesSection extends StatelessWidget {
  final List<TopCategory>? categories;
  const _TopCategoriesSection({required this.categories});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        child: Text('top_categories'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge)),
      ),
      const SizedBox(height: Dimensions.paddingSizeDefault),
      SizedBox(
        height: _initCircleRowHeight(context, imageSize: 64, labelLines: 2, floor: 104),
        child: categories == null
            ? const _TopCategoryShimmer()
            : ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                itemCount: categories!.length,
                separatorBuilder: (_, _) => const SizedBox(width: Dimensions.paddingSizeLarge),
                itemBuilder: (BuildContext context, int index) => _TopCategoryItem(category: categories![index]),
              ),
      ),
    ]);
  }
}

class _TopCategoryItem extends StatelessWidget {
  final TopCategory category;
  const _TopCategoryItem({required this.category});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: category.id != null
          ? () {
              FocusScope.of(context).unfocus();
              final SplashController splash = Get.find<SplashController>();
              if (category.moduleId != null && splash.moduleList != null) {
                for (final ModuleModel module in splash.moduleList!) {
                  if (module.id == category.moduleId) {
                    splash.setModule(module);
                    break;
                  }
                }
              }
              Get.toNamed(RouteHelper.getCategoryItemRoute(category.id, category.name ?? '', slug: category.slug ?? ''));
            }
          : null,
      child: SizedBox(
        width: 68,
        child: Column(children: [
          ClipOval(
            child: CustomImage(
              image: category.imageFullUrl ?? '',
              width: 64, height: 64, fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Text(
            category.name ?? '',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
          ),
        ]),
      ),
    );
  }
}

class _TopCategoryShimmer extends StatelessWidget {
  const _TopCategoryShimmer();

  @override
  Widget build(BuildContext context) {
    final Color base = Theme.of(context).disabledColor.withValues(alpha: 0.12);
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(width: Dimensions.paddingSizeLarge),
      itemBuilder: (_, _) => Shimmer(
        duration: const Duration(seconds: 2),
        child: SizedBox(
          width: 68,
          child: Column(children: [
            Container(width: 64, height: 64, decoration: BoxDecoration(color: base, shape: BoxShape.circle)),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            Container(width: 50, height: 12, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(Dimensions.radiusSmall))),
          ]),
        ),
      ),
    );
  }
}
