import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/controllers/theme_controller.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/common/widgets/custom_asset_image_widget.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/common/widgets/web_menu_bar.dart';
import 'package:sixam_mart/features/brands/domain/models/brands_model.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/cart/screens/global_cart_screen.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/top_picks_near_you_widget.dart';
import 'package:sixam_mart/features/redesign_feature/global_widgets/brand_item_widget.dart';
import 'package:sixam_mart/features/search/controllers/search_controller.dart' as search;
import 'package:sixam_mart/features/search/domain/models/recent_search_entry.dart';
import 'package:sixam_mart/features/search/domain/models/search_new_filter_state.dart';
import 'package:sixam_mart/features/search/domain/models/top_category_model.dart';
import 'package:sixam_mart/features/search/domain/models/trending_search_model.dart';
import 'package:sixam_mart/features/search/screens/search_new_filter_screen.dart';
import 'package:sixam_mart/features/search/screens/section/search_result_section.dart';
import 'package:sixam_mart/features/search/widgets/search_field_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/helper/voice_permission_handler.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

part './section/all_shimmer_section.dart';
part './section/search_screen_init_section.dart';
part './section/suggestion_view.dart';

class SearchScreen extends StatefulWidget {
  final String? queryText;
  final String? moduleName;
  const SearchScreen({super.key, required this.queryText, this.moduleName});

  @override
  SearchScreenState createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  late bool _isLoggedIn;

  List<RecentSearchEntry> _itemsAndStors = <RecentSearchEntry>[];
  bool _showSuggestion = false;
  bool _isSuggestionLoading = false;
  bool _showCartOnScroll = true;
  Timer? _suggestionDebounce;
  // True while a global keyword submit is fetching suggestions to resolve the
  // result module before opening the result view.
  bool _isActionSearchLoading = false;

  @override
  void initState() {
    super.initState();
    _isLoggedIn = AuthHelper.isLoggedIn();
    // "Home" tab (selectedModuleIndex == 0) means no module is contextually
    // selected — the Home tab does not clear SplashController.module, so the
    // tab index is the reliable global-vs-module signal here.
    final bool isGlobal = Get.find<SplashController>().selectedModuleIndex == 0;
    Get.find<search.SearchController>().setSearchMode(true, canUpdate: false);
    Get.find<search.SearchController>().setGlobalSearch(isGlobal, canUpdate: false);
    Get.find<search.SearchController>().getTrendingSearches();
    Get.find<StoreController>().getFeaturedStoreList();
    if(isGlobal) {
      // Top Categories replace Top Brands in global search.
      Get.find<search.SearchController>().getTopCategories();
    }
    if(_isLoggedIn) {
      Get.find<search.SearchController>().getSuggestedItems();
    }
    Get.find<search.SearchController>().getHistoryList(moduleKey: isGlobal ? '' : (widget.moduleName ?? ''));
    // Top Brands only apply to grocery and shop (ecommerce) modules.
    final String? moduleType = Get.find<SplashController>().module?.moduleType;
    if(moduleType == AppConstants.grocery || moduleType == AppConstants.ecommerce) {
      Get.find<search.SearchController>().getBrandList(notify: false);
    }
    // Featured stores & restaurants for the init section (reuse home's list if loaded).
    if(Get.find<StoreController>().featuredStoreList == null) {
      Get.find<StoreController>().getFeaturedStoreList(fromHome: true, notify: false);
    }
    if(widget.queryText!.isNotEmpty) {
      // Global search resolves the result module from suggestions first, so show the
      // loader on the first frame instead of flashing the init view.
      if(isGlobal) _isActionSearchLoading = true;
      // Deferred to post-frame so _actionSearch's setState calls are always safe.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if(mounted) _actionSearch(true, widget.queryText, true);
      });
    }

    // Route voice-search auto-submit through _actionSearch so it fetches
    // suggestions and resolves the result module — identical to the keyboard flow.
    Get.find<search.SearchController>().registerVoiceSubmitCallback(
      (String text) => _actionSearch(true, text, false),
    );
  }

  void _searchSuggestions(String query) {
    _suggestionDebounce?.cancel();
    if (query.isEmpty) {
      setState(() {
        _showSuggestion = false;
        _isSuggestionLoading = false;
        _showCartOnScroll = true;
        _itemsAndStors = [];
      });
      return;
    }
    // Check if query is only whitespace
    if (query.trim().isEmpty) {
      showCustomSnackBar('search_field_empty_error'.tr);
      return;
    }
    setState(() {
      _showSuggestion = true;
      _isSuggestionLoading = true;
      _itemsAndStors = [];
    });
    _suggestionDebounce = Timer(const Duration(milliseconds: 400), () => _fetchSuggestions(query));
  }

  Future<void> _fetchSuggestions(String query) async {
    final List<RecentSearchEntry> results = await Get.find<search.SearchController>().getSearchSuggestions(query);
    // Drop stale responses if the user kept typing while the request was in flight.
    if (!mounted || query != _searchController.text.trim()) return;
    // Ordering is handled by the controller: strong name-matches are floated to the
    // top, weaker matches stay shuffled (interleaving items & stores) below.
    setState(() {
      _itemsAndStors = results;
      _isSuggestionLoading = false;
    });
  }

  @override
  void dispose() {
    _suggestionDebounce?.cancel();
    _searchController.dispose();
    Get.find<search.SearchController>().unregisterVoiceSubmitCallback();
    super.dispose();
  }

  /// Steps back through the three search states instead of leaving the screen:
  ///   • search result  → back to search mode (initial view)
  ///   • suggestion list → back to the initial view (query cleared)
  ///   • initial view    → returns true so the caller pops the screen
  bool _handleSearchBack() {
    final search.SearchController sc = Get.find<search.SearchController>();
    final bool isInitial = sc.isSearchMode && !_showSuggestion;
    if (isInitial) {
      return true;
    }
    // Result or suggestion → fall back to the initial search view.
    _showSuggestion = false;
    sc.setStore(false);
    sc.setSearchMode(true);
    // On web the field isn't auto-synced from the controller, so clear it here.
    if (GetPlatform.isWeb) {
      _searchController.text = '';
    }
    if (mounted) setState(() {});
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Intercept every back: we step through the search states ourselves and
      // only leave the screen from the initial view (see _handleSearchBack).
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_handleSearchBack()) {
          Get.back();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).cardColor,
        appBar: ResponsiveHelper.isDesktop(context) ? const WebMenuBar() : null,
        endDrawer: const MenuDrawer(), endDrawerEnableOpenDragGesture: false,
        body: SafeArea(child: NotificationListener<UserScrollNotification>(
          // Hide the floating cart while scrolling the content down (any list on
          // the screen), reveal it on scroll up.
          onNotification: (UserScrollNotification notification) {
            // Only react to vertical scrolling, not horizontal carousels.
            if (notification.metrics.axis != Axis.vertical) return false;
            final ScrollDirection dir = notification.direction;
            if (dir == ScrollDirection.reverse && _showCartOnScroll) {
              setState(() => _showCartOnScroll = false);
            } else if (dir == ScrollDirection.forward && !_showCartOnScroll) {
              setState(() => _showCartOnScroll = true);
            }
            return false;
          },
          child: Padding(
          padding: ResponsiveHelper.isDesktop(context) ? EdgeInsets.zero : const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
          child: GetBuilder<search.SearchController>(builder: (searchController) {
            // Only update controller if text differs to preserve cursor position
            if(!GetPlatform.isWeb && _searchController.text != searchController.searchText) {
              final int cursorPos = _searchController.selection.base.offset;
              _searchController.text = searchController.searchText!;
              // Restore cursor position if it's within bounds
              if(cursorPos >= 0 && cursorPos <= _searchController.text.length) {
                _searchController.selection = TextSelection.fromPosition(
                  TextPosition(offset: cursorPos),
                );
              }
            }
            return Column(children: [
              ResponsiveHelper.isDesktop(context) ? Container(
                width : double.infinity,
                color: Theme.of(context).primaryColor.withValues(alpha: 0.10),
                child: SizedBox(
                  width: Dimensions.webMaxWidth,
                  child: Column(
                    children: [
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      Text('search_items_and_stores'.tr, style: robotoMedium),
                      const SizedBox(height: Dimensions.paddingSizeDefault),

                      SizedBox(width: Dimensions.webMaxWidth, child: GetBuilder<search.SearchController>(builder: (searchController) {
                        return SearchFieldWidget(
                          controller: _searchController,
                          radius: 50,
                          prefixWidget: searchController.isNearbyFilter
                              ? _NearMeChip(onClear: () => searchController.setNearbyFilter(false))
                              : null,
                          hint: (widget.moduleName != null && widget.moduleName!.isNotEmpty)
                              ? "${'search_for'.tr} '${widget.moduleName}'"
                              : 'search_item_or_store'.tr,
                          suffixIcon: searchController.searchHomeText!.isNotEmpty ? Icons.cancel : Icons.keyboard_voice_sharp,
                          iconColor: Theme.of(context).disabledColor,
                          filledColor: Theme.of(context).colorScheme.surface,
                          onChanged: (text) {
                            _searchSuggestions(text);
                            searchController.setSearchText(text);
                          },
                          iconPressed: () async {
                            if(searchController.searchHomeText!.isNotEmpty) {
                              _searchController.text = '';
                              _showSuggestion = false;
                              searchController.setSearchMode(true);
                              searchController.clearSearchHomeText();
                            }else {
                              // searchData();
                              await VoicePermissionHandler.openVoiceSearch(
                                context: context,
                                searchTextEditingController: _searchController,
                                isDesktop: ResponsiveHelper.isDesktop(context),
                              );
                            }
                          },
                          onSubmit: (text) => searchData(),
                        );
                      })),
                      const SizedBox(height: Dimensions.paddingSizeDefault),

                    ],
                  ),
                ),
              ) : const SizedBox(),

              widget.queryText!.isNotEmpty ? const SizedBox() : Center(child: ResponsiveHelper.isDesktop(context) ? const SizedBox() : Container(
                width: Dimensions.webMaxWidth,
                decoration: BoxDecoration(
                  color: Get.find<ThemeController>().darkTheme ? Colors.black12 : Theme.of(context).cardColor,
                ),
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeSmall),
              child: Row(children: [
              
                IconButton(
                  onPressed: () {
                    if (_handleSearchBack()) {
                      Get.back();
                    }
                  },
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                    ),
                    backgroundColor: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                  ),
                  icon: const Icon(Icons.arrow_back, size: 20),
                ),
              
                Expanded(
                  child: Row(children: [
                    Expanded(child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.2), width: 1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: SearchFieldWidget(
                        controller: _searchController,
                        radius: 40,
                        dense: true,
                        filledColor: Theme.of(context).cardColor,
                        prefixWidget: searchController.isNearbyFilter
                            ? _NearMeChip(onClear: () => searchController.setNearbyFilter(false))
                            : null,
                        hint: (widget.moduleName != null && widget.moduleName!.isNotEmpty)
                            ? "${'search_for'.tr} '${widget.moduleName}'"
                            : Get.find<SplashController>().configModel!.moduleConfig!.module!.showRestaurantText!
                                ? 'search_food_or_restaurant'.tr : 'search_item_or_store'.tr,
                        suffixIcon: _searchController.text.isNotEmpty ? Icons.clear : Icons.keyboard_voice_sharp,
                        iconPressed: () async {
                          if(_searchController.text.isNotEmpty) {
                            _showSuggestion = false;
                            searchController.setSearchMode(true);
                            searchController.setStore(false);
                            if(GetPlatform.isWeb) {
                              _searchController.text = '';
                            }
                          } else {
                            await VoicePermissionHandler.openVoiceSearch(
                              context: context,
                              searchTextEditingController: _searchController,
                              isDesktop: ResponsiveHelper.isDesktop(context),
                            );
                          }
                        },
                        onChanged: (text) {
                          searchController.setSearchText(text);
                          _searchSuggestions(text);
                          // _searchController.text = searchController.searchText!;
                        },
                        onSubmit: (text) => _actionSearch(true, _searchController.text.trim(), false),
                      ),
                    )),
                                
                    // Filter — shown only while results (SearchResultSection) are visible.
                    if(!searchController.isSearchMode) ...[
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      IconButton(
                        onPressed: _openFilter,
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge)),
                          backgroundColor: searchController.hasActiveItemFilter
                              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                              : Theme.of(context).disabledColor.withValues(alpha: 0.1),
                        ),
                        icon: Icon(Icons.tune, size: 20,
                          color: searchController.hasActiveItemFilter ? Theme.of(context).primaryColor : null,
                        ),
                      ),
                    ],
                  ]),
                ),
              ]))),

              if(searchController.isSearchMode || _showSuggestion)
               Divider(color: Theme.of(context).disabledColor.withValues(alpha: 0.2), thickness: 1, height: 1),

              // Suggestions take precedence over both the initial view AND the
              // results view, so editing the query after a search re-opens the
              // suggestion list (and lets the user search again) instead of being
              // stuck on the previous results.
              Expanded(child: _isActionSearchLoading ? const _SearchResultLoadingShimmer() : _showSuggestion ? _SuggestionsView(
                suggestions: _itemsAndStors,
                searchQuery: _searchController.text.trim(),
                isLoading: _isSuggestionLoading,
                isGlobal: searchController.isGlobalSearch,
                onSuggestionTap: (entry) {
                  FocusScope.of(context).unfocus();
                  _searchController.text = entry.name;
                  _actionSearch(true, entry.name, false, entry: entry);
                },
                onNearMeTap: () {
                  FocusScope.of(context).unfocus();
                  _actionSearch(true, _searchController.text.trim(), false, nearby: true);
                },
                onSearchForTap: () {
                  FocusScope.of(context).unfocus();
                  _actionSearch(true, _searchController.text.trim(), false);
                },
              ) : searchController.isSearchMode ? SingleChildScrollView(
                child: FooterView(child: _SearchScreenInitSection(
                  searchController: searchController,
                  searchTextController: _searchController,
                  isLoggedIn: _isLoggedIn,
                )),
              ) : Container( color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                    child: SearchResultSection(
                      key: ValueKey('search_result_${searchController.selectedResultModuleId}_${_searchController.text.trim()}'),
                      searchText: _searchController.text.trim(),
                    )),
              ),
            ]);
          }),
        ))),

        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: GetBuilder<CartController>(builder: (cartController) {
          // Always shown when the cart has items, except while the suggestion list
          // is visible (_showSuggestion) or while scrolling content down (_showCartOnScroll).
          final bool showCart = cartController.allCartsGroups != null
              && cartController.allCartsGroups!.isNotEmpty
              && !ResponsiveHelper.isDesktop(context)
              && !_showSuggestion
              && _showCartOnScroll;
          return showCart
              ? _ViewCartFloatingButton(count: cartController.allCartsGroups!.length)
              : const SizedBox.shrink();
        }),
      ),
    );
  }

  void searchData() {
    if (_searchController.text.trim().isEmpty) {
      showCustomSnackBar('please_enter_search_text'.tr);
    } else {
      _actionSearch(true, _searchController.text, true);
    }
  }

  Future<void> _actionSearch(bool isSubmit, String? queryText, bool fromHome, {RecentSearchEntry? entry, bool nearby = false}) async {
    // Leaving the suggestion view for results — dismiss suggestions and reveal the
    // cart again (guarded so it never calls setState during initState).
    if (_showSuggestion || !_showCartOnScroll) {
      _showSuggestion = false;
      _showCartOnScroll = true;
      if (mounted) setState(() {});
    }
    final search.SearchController searchController = Get.find<search.SearchController>();
    if(searchController.isSearchMode || isSubmit) {
      if(queryText!.isNotEmpty) {
        // Apply (or clear) the nearby filter before fetching so items, stores and
        // pagination all carry `filter_by=nearby` for a "Near me" search.
        searchController.setNearbyFilter(nearby);
        // For a plain keyword search (no specific suggestion tapped, and not a
        // "Near me" search), scope the global result view to the first suggestion
        // row's module so results open under the most relevant module. "Near me"
        // is intentionally excluded so its behaviour stays unchanged.
        int? preferredModuleId = (entry == null && !nearby && _itemsAndStors.isNotEmpty)
            ? _itemsAndStors.first.moduleId
            : null;

        // Global keyword submit with no suggestions fetched yet (e.g. submitted
        // before the suggestion debounce fired): fetch suggestions first, then scope
        // the result module to the first suggestion. Falls back to the default module
        // when nothing matches. Module-wise search is unaffected.
        final bool needSuggestionFirst = entry == null && !nearby
            && searchController.isGlobalSearch && _itemsAndStors.isEmpty;
        if(needSuggestionFirst) {
          _suggestionDebounce?.cancel();
          _isActionSearchLoading = true;
          if(mounted) setState(() {});
          final List<RecentSearchEntry> results = await searchController.getSearchSuggestions(queryText);
          if(!mounted) return;
          // Ignore the response if the user changed the query while it was in flight.
          if(queryText == _searchController.text.trim()) {
            _itemsAndStors = results;
            preferredModuleId = results.isNotEmpty ? results.first.moduleId : null;
          }
          _isActionSearchLoading = false;
          if(mounted) setState(() {});
        } else if(_isActionSearchLoading) {
          _isActionSearchLoading = false;
          if(mounted) setState(() {});
        }

        searchController.searchData(queryText, fromHome, recentEntry: entry, preferredModuleId: preferredModuleId);
      } else {
        showCustomSnackBar('please_enter_search_text'.tr);
      }
    } else {
      _openFilter();
    }
  }

  Future<void> _openFilter() async {
    final search.SearchController sc = Get.find<search.SearchController>();

    // Load real categories so the filter screen's Categories section is dynamic.
    final CategoryController catController = Get.find<CategoryController>();
    if (catController.categoryList == null) {
      await catController.getCategoryList(false);
    }
    final List<String> categoryNames = (catController.categoryList ?? <CategoryModel>[])
        .map((CategoryModel c) => c.name ?? '')
        .where((String n) => n.isNotEmpty)
        .toList();
    if (!mounted) return;

    final SearchNewFilterState? result = await Get.bottomSheet<SearchNewFilterState>(
      // A modal bottom sheet zeroes the top padding, so the screen's SafeArea
      // can't clear the status bar. Restore the real padding for the sheet.
      MediaQuery(
        data: MediaQuery.of(context),
        child: SearchNewFilterScreen(
          initialFilter: sc.searchFilter ?? SearchNewFilterState.initial(),
          dynamicCategories: categoryNames.isNotEmpty ? categoryNames : null,
          isFood: Get.find<SplashController>().module?.moduleType == AppConstants.food,
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
    );
    if (result == null) return;

    // Apply the chosen filters to the search API (server-side filtering).
    sc.applySearchFilter(result);
  }
}

// Floating "View Cart (N)" pill shown at the bottom-center of the search screen
// when the selected module's cart has items.
// Visual-only tag shown inside the search field while a "Near me" search is
// active, so the user knows results are nearby-filtered. Tapping the close icon
// clears the filter. This text is never added to the search query / API param.
class _NearMeChip extends StatelessWidget {
  final VoidCallback onClear;
  const _NearMeChip({required this.onClear});

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeExtraSmall),
      child: Container(
        padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeSmall, 4, Dimensions.paddingSizeExtraSmall, 4),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.near_me, size: 14, color: primary),
          const SizedBox(width: 3),
          Text('near_me'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: primary)),
          const SizedBox(width: 2),
          InkWell(
            onTap: onClear,
            borderRadius: BorderRadius.circular(20),
            child: Icon(Icons.close, size: 15, color: primary),
          ),
        ]),
      ),
    );
  }
}

class _ViewCartFloatingButton extends StatelessWidget {
  final int count;
  const _ViewCartFloatingButton({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: Material(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(100),
        elevation: 3,
        shadowColor: Theme.of(context).primaryColor.withValues(alpha: 0.4),
        child: InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: () => Get.to(GlobalCartScreen(
            fromNav: false,
            initialModuleId: Get.find<SplashController>().module?.id,
          )),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeExtraLarge + Dimensions.paddingSizeDefault,
              vertical: Dimensions.paddingSizeDefault,
            ),
            child: Text(
              '${'view_cart'.tr} ($count)',
              style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeDefault),
            ),
          ),
        ),
      ),
    );
  }
}
