import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/search/domain/models/search_new_filter_state.dart';
import 'package:sixam_mart/features/brands/domain/models/brands_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/search/domain/models/popular_categories_model.dart';
import 'package:sixam_mart/features/search/domain/models/recent_search_entry.dart';
import 'package:sixam_mart/features/search/domain/models/search_suggestion_model.dart';
import 'package:sixam_mart/features/search/domain/models/top_category_model.dart';
import 'package:sixam_mart/features/search/domain/models/trending_search_model.dart';
import 'package:sixam_mart/features/search/domain/services/search_service_interface.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart' hide Items;
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SearchController extends GetxController implements GetxService {
  final SearchServiceInterface searchServiceInterface;
  SearchController({required this.searchServiceInterface}) {
    _speech = stt.SpeechToText();
  }

  List<Item>? _searchItemList;
  List<Item>? get searchItemList => _searchItemList;

  int? _searchItemTotalSize;
  int? get searchItemTotalSize => _searchItemTotalSize;

  int _searchItemOffset = 1;
  int get searchItemOffset => _searchItemOffset;

  int _searchItemLimit = 10;

  final List<int> _searchItemOffsetList = [];

  bool _isSearchItemPaginating = false;
  bool get isSearchItemPaginating => _isSearchItemPaginating;

  bool get hasMoreSearchItems {
    if (_searchItemTotalSize == null) return false;
    final int pageSize = _searchItemLimit > 0 ? _searchItemLimit : 10;
    return _searchItemOffset < (_searchItemTotalSize! / pageSize).ceil();
  }

  List<Item>? _allItemList;
  List<Item>? get allItemList => _allItemList;

  List<Item>? _suggestedItemList;
  List<Item>? get suggestedItemList => _suggestedItemList;

  List<Store>? _searchStoreList;
  List<Store>? get searchStoreList => _searchStoreList;

  List<Store>? _allStoreList;
  List<Store>? get allStoreList => _allStoreList;

  int? _searchStoreTotalSize;
  int? get searchStoreTotalSize => _searchStoreTotalSize;

  int _searchStoreOffset = 1;
  int get searchStoreOffset => _searchStoreOffset;
  int _searchStoreLimit = 10;
  final List<int> _searchStoreOffsetList = [];

  bool _isSearchStorePaginating = false;
  bool get isSearchStorePaginating => _isSearchStorePaginating;

  bool get hasMoreSearchStores {
    if (_searchStoreTotalSize == null) return false;
    final int pageSize = _searchStoreLimit > 0 ? _searchStoreLimit : 10;
    return _searchStoreOffset < (_searchStoreTotalSize! / pageSize).ceil();
  }

  String? _searchText = '';
  String? get searchText => _searchText;

  String? _storeResultText = '';

  String? _itemResultText = '';

  // Incremented every time the user returns to search mode (setSearchMode(true)).
  // Captured at the start of each searchData call so that stale in-flight API
  // responses (from a previous search) are discarded instead of overwriting the
  // reset state, which would cause the guard to block the next search attempt.
  int _searchVersion = 0;

  double _lowerValue = 0;
  double get lowerValue => _lowerValue;

  double _upperValue = 0;
  double get upperValue => _upperValue;

  List<RecentSearchEntry> _historyList = [];
  List<RecentSearchEntry> get historyList => _historyList;

  /// Recent searches capped for display: at most 2 items, 2 stores and
  /// 1 keyword (5 total). Items/stores keep most-recent-first order; the
  /// keyword is always appended last.
  List<RecentSearchEntry> get recentSearchList {
    int itemCount = 0, storeCount = 0, keywordCount = 0;
    final List<RecentSearchEntry> primary = [];
    final List<RecentSearchEntry> keywords = [];
    for (final RecentSearchEntry entry in _historyList) {
      if (entry.kind == RecentSearchKind.item) {
        if (itemCount >= 2) continue;
        itemCount++;
        primary.add(entry);
      } else if (entry.kind == RecentSearchKind.store) {
        if (storeCount >= 2) continue;
        storeCount++;
        primary.add(entry);
      } else {
        if (keywordCount >= 1) continue;
        keywordCount++;
        keywords.add(entry);
      }
    }
    return <RecentSearchEntry>[...primary, ...keywords];
  }

  /// True when the user opened search without an active module — results and
  /// recent searches then span all modules (and show module image + type).
  bool _isGlobalSearch = false;
  bool get isGlobalSearch => _isGlobalSearch;

  void setGlobalSearch(bool isGlobal, {bool canUpdate = true}) {
    _isGlobalSearch = isGlobal;
    if (canUpdate) update();
  }

  /// The module the global result view is scoped to (the tapped suggestion's
  /// module, or the module tab the user picked). Null in module-wise search.
  int? _selectedResultModuleId;
  int? get selectedResultModuleId => _selectedResultModuleId;

  static const Set<String> _excludedResultModuleTypes = <String>{
    AppConstants.parcel, AppConstants.taxi, AppConstants.ride,
  };

  /// Modules shown in the global result-view tab strip — mirrors the offer
  /// screen (excludes parcel, rental and ride-share).
  List<ModuleModel> get resultModules {
    final List<ModuleModel> modules = Get.find<SplashController>().moduleList ?? <ModuleModel>[];
    return modules.where((ModuleModel m) => !_excludedResultModuleTypes.contains(m.moduleType)).toList();
  }

  int? _defaultResultModuleId() {
    final List<ModuleModel> modules = resultModules;
    if (modules.isEmpty) return null;
    final int? activeId = Get.find<SplashController>().module?.id;
    if (activeId != null && modules.any((ModuleModel m) => m.id == activeId)) return activeId;
    return modules.first.id;
  }

  /// In global search the result list is scoped per-call, but downstream screens
  /// (item details, store details, add-to-cart) rely on the global module header.
  /// Point the active module at the scoped result module so those calls resolve
  /// correctly — same convention the app already uses on cross-module item taps.
  void _syncActiveModuleToResult() {
    if (!_isGlobalSearch || _selectedResultModuleId == null) return;
    final SplashController splash = Get.find<SplashController>();
    if (splash.module?.id == _selectedResultModuleId) return;
    final List<ModuleModel>? modules = splash.moduleList;
    if (modules == null) return;
    for (final ModuleModel module in modules) {
      if (module.id == _selectedResultModuleId) {
        splash.setModule(module, notify: false);
        break;
      }
    }
  }

  /// Re-runs the current query scoped to [moduleId] without leaving the search
  /// screen (filter-in-place). Also points the active module at it so item/store
  /// details opened from these results use the correct module header.
  void selectSearchModule(int moduleId, String query) {
    if (_selectedResultModuleId == moduleId) return;
    _selectedResultModuleId = moduleId;
    _itemResultText = '';
    _storeResultText = '';
    _searchItemList = null;
    _allItemList = null;
    _searchStoreList = null;
    _allStoreList = null;
    _searchItemTotalSize = null;
    _searchItemOffset = 1;
    _searchItemLimit = 10;
    _searchItemOffsetList.clear();
    _isStore = false;
    _syncActiveModuleToResult();
    update();
    searchData(query, false);
  }

  bool _isSearchMode = true;
  bool get isSearchMode => _isSearchMode;

  final List<String> _sortList = ['ascending'.tr, 'descending'.tr];
  List<String> get sortList => _sortList;

  int _sortIndex = -1;
  int get sortIndex => _sortIndex;

  int _storeSortIndex = -1;
  int get storeSortIndex => _storeSortIndex;

  int _rating = -1;
  int get rating => _rating;

  int _storeRating = -1;
  int get storeRating => _storeRating;

  bool _isStore = false;
  bool get isStore => _isStore;

  bool _isAvailableItems = false;
  bool get isAvailableItems => _isAvailableItems;

  bool _isAvailableStore = false;
  bool get isAvailableStore => _isAvailableStore;

  bool _isDiscountedItems = false;
  bool get isDiscountedItems => _isDiscountedItems;

  bool _isDiscountedStore = false;
  bool get isDiscountedStore => _isDiscountedStore;

  bool _veg = false;
  bool get veg => _veg;

  bool _storeVeg = false;
  bool get storeVeg => _storeVeg;

  bool _nonVeg = false;
  bool get nonVeg => _nonVeg;

  bool _storeNonVeg = false;
  bool get storeNonVeg => _storeNonVeg;

  String? _searchHomeText = '';
  String? get searchHomeText => _searchHomeText;

  String _moduleKey = '';
  String get moduleKey => _moduleKey;

  SearchSuggestionModel? _searchSuggestionModel;
  SearchSuggestionModel? get searchSuggestionModel => _searchSuggestionModel;

  List<PopularCategoryModel?>? _popularCategoryList;
  List<PopularCategoryModel?>? get popularCategoryList => _popularCategoryList;

  List<TrendingSearch>? _trendingSearchList;
  List<TrendingSearch>? get trendingSearchList => _trendingSearchList;

  Future<void> getTrendingSearches() async {
    _trendingSearchList = null;
    _trendingSearchList = await searchServiceInterface.getTrendingSearches(isGlobal: _isGlobalSearch);
    update();
  }

  // The specific trending entry resolving its module from the suggestions API —
  // used to show a loader on (only) the tapped chip and block re-taps mid-resolve.
  TrendingSearch? _loadingTrending;
  TrendingSearch? get loadingTrending => _loadingTrending;
  bool isTrendingLoading(TrendingSearch trending) => identical(_loadingTrending, trending);

  /// Trending-search tap. When the keyword carries a module, scope the result view
  /// to it directly; otherwise resolve the module from the keyword's first
  /// suggestion (item/store), then run the search scoped to that module.
  Future<void> searchFromTrending(TrendingSearch trending) async {
    if (_loadingTrending != null) return;
    final String keyword = trending.keyword ?? '';
    if (keyword.isEmpty) return;

    int? moduleId = trending.moduleId;
    if (moduleId == null) {
      _loadingTrending = trending;
      update();
      final List<RecentSearchEntry> suggestions = await getSearchSuggestions(keyword);
      if (suggestions.isNotEmpty) moduleId = suggestions.first.moduleId;
      _loadingTrending = null;
      update();
    }

    await searchData(keyword, false, recentEntry: _trendingKeywordEntry(keyword, moduleId));
  }

  // Builds a keyword recent-search entry carrying the resolved module so the
  // result view (in global search) scopes to it and a later re-tap reopens the
  // same module. Module type/name/image are resolved from the loaded module list.
  RecentSearchEntry _trendingKeywordEntry(String keyword, int? moduleId) {
    ModuleModel? module;
    if (moduleId != null) {
      for (final ModuleModel m in Get.find<SplashController>().moduleList ?? <ModuleModel>[]) {
        if (m.id == moduleId) {
          module = m;
          break;
        }
      }
    }
    return RecentSearchEntry.keyword(keyword,
      moduleId: moduleId, moduleType: module?.moduleType, moduleName: module?.moduleName, moduleImage: _moduleImage(moduleId),
    );
  }

  void toggleVeg() {
    _veg = !_veg;
    update();
  }

  void toggleStoreVeg() {
    _storeVeg = !_storeVeg;
    update();
  }

  void toggleNonVeg() {
    _nonVeg = !_nonVeg;
    update();
  }

  void toggleStoreNonVeg() {
    _storeNonVeg = !_storeNonVeg;
    update();
  }

  void toggleAvailableItems() {
    _isAvailableItems = !_isAvailableItems;
    update();
  }

  void toggleAvailableStore() {
    _isAvailableStore = !_isAvailableStore;
    update();
  }

  void toggleDiscountedItems() {
    _isDiscountedItems = !_isDiscountedItems;
    update();
  }

  void toggleDiscountedStore() {
    _isDiscountedStore = !_isDiscountedStore;
    update();
  }

  void setStore(bool isStore) {
    _isStore = isStore;
    update();
  }

  void setSearchMode(bool isSearchMode, {bool canUpdate = true}) {
    _isSearchMode = isSearchMode;
    if (isSearchMode) {
      _searchVersion++;
      _searchText = '';
      _itemResultText = '';
      _storeResultText = '';
      _allStoreList = null;
      _allItemList = null;
      _searchItemList = null;
      _searchStoreList = null;
      _searchItemTotalSize = null;
      _searchItemOffset = 1;
      _searchItemLimit = 10;
      _searchItemOffsetList.clear();
      _isSearchItemPaginating = false;
      _searchStoreTotalSize = null;
      _searchStoreOffset = 1;
      _searchStoreLimit = 10;
      _searchStoreOffsetList.clear();
      _isSearchStorePaginating = false;
      _searchFilter = null;
      _nearbyFilter = false;
      _sortIndex = -1;
      _storeSortIndex = -1;
      _isDiscountedItems = false;
      _isDiscountedStore = false;
      _isAvailableItems = false;
      _isAvailableStore = false;
      _veg = false;
      _storeVeg = false;
      _nonVeg = false;
      _storeNonVeg = false;
      _rating = -1;
      _storeRating = -1;
      _upperValue = 0;
      _lowerValue = 0;
      _selectedResultModuleId = null;
    }
    if (_isStore) {
      _isStore = !_isStore;
    }
    if (canUpdate) {
      update();
    }
  }

  void setLowerAndUpperValue(double lower, double upper) {
    _lowerValue = lower;
    _upperValue = upper;
    update();
  }

  void sortItemSearchList() {
    _searchItemList = searchServiceInterface.sortItemSearchList(
      _allItemList,
      _upperValue,
      _lowerValue,
      _rating,
      _veg,
      _nonVeg,
      _isAvailableItems,
      _isDiscountedItems,
      _sortIndex,
    );
    update();
  }

  void sortStoreSearchList() {
    _searchStoreList = searchServiceInterface.sortStoreSearchList(
      _allStoreList,
      _storeRating,
      _storeVeg,
      _storeNonVeg,
      _isAvailableStore,
      _isDiscountedStore,
      _storeSortIndex,
    );
    update();
  }

  void setSearchText(String text) {
    _searchText = text;
    update();
  }

  void getSuggestedItems() async {
    List<Item>? suggestedItemList = await searchServiceInterface
        .getSuggestedItems();
    if (suggestedItemList != null) {
      _suggestedItemList = [];
      _suggestedItemList!.addAll(suggestedItemList);
    }
    update();
  }

  Future<void> searchData(
    String? query,
    bool fromHome, {
    int offset = 1,
    RecentSearchEntry? recentEntry,
    int? preferredModuleId,
  }) async {
    final bool isStoreSearch = _isStore;
    final bool isPaginating = offset > 1;
    final int version = _searchVersion;
    if ((isStoreSearch &&
            query!.isNotEmpty &&
            (query != _storeResultText || isPaginating)) ||
        (!isStoreSearch &&
            query!.isNotEmpty &&
            (query != _itemResultText || fromHome || isPaginating))) {
      _searchHomeText = query;
      _searchText = query;
      if (!isPaginating) {
        _rating = -1;
        _storeRating = -1;
        _upperValue = 0;
        _lowerValue = 0;
        if (isStoreSearch) {
          _searchStoreList = null;
          _allStoreList = null;
          _searchStoreTotalSize = null;
          _searchStoreOffset = 1;
          _searchStoreLimit = 10;
          _searchStoreOffsetList.clear();
        } else {
          _searchItemList = null;
          _allItemList = null;
          _searchItemTotalSize = null;
          _searchItemOffset = 1;
          _searchItemLimit = 10;
          _searchItemOffsetList.clear();
          // Only clear store results when the query actually changed — a same-query
          // re-fetch (e.g. after applying a filter) must not wipe loaded stores.
          if (query != _storeResultText) {
            _searchStoreList = null;
            _allStoreList = null;
            _storeResultText = '';
            _searchStoreTotalSize = null;
            _searchStoreOffset = 1;
            _searchStoreLimit = 10;
            _searchStoreOffsetList.clear();
          }
        }
        _addRecentSearch(recentEntry ?? RecentSearchEntry(
          name: query,
          kind: RecentSearchKind.keyword,
          moduleId: Get.find<SplashController>().module?.id,
          moduleType: Get.find<SplashController>().module?.moduleType,
          moduleName: Get.find<SplashController>().module?.moduleName,
        ));
        // In global search, scope the results to the tapped suggestion's module
        // (or keep/seed a default when the search came from a keyword), and point
        // the active module at it so detail screens use the right module header.
        if (_isGlobalSearch) {
          if (recentEntry?.moduleId != null) {
            _selectedResultModuleId = recentEntry!.moduleId;
          } else if (preferredModuleId != null
              && resultModules.any((ModuleModel m) => m.id == preferredModuleId)) {
            // Keyword search (no specific suggestion tapped): scope the result
            // view to the first suggestion's module, when it's a valid result module.
            _selectedResultModuleId = preferredModuleId;
          } else {
            _selectedResultModuleId ??= _defaultResultModuleId();
          }
          _syncActiveModuleToResult();
        }
        _isSearchMode = false;
        if (!fromHome) {
          update();
        }
      }

      final int? scopeModuleId = _isGlobalSearch ? _selectedResultModuleId : null;
      Response response = await searchServiceInterface.getSearchData(
        query,
        isStoreSearch,
        offset: offset,
        moduleId: scopeModuleId,
        filterParams: _buildFilterQuery(),
      );
      // The user navigated back while this request was in flight — discard the
      // response so stale results don't overwrite _itemResultText/_storeResultText
      // and block the guard on the next search attempt.
      if (version != _searchVersion) return;
      if (response.statusCode == 200) {
        if (query.isEmpty) {
          if (isStoreSearch) {
            _searchStoreList = [];
          } else {
            _searchItemList = [];
            _allItemList = [];
            _searchItemTotalSize = 0;
          }
        } else {
          if (isStoreSearch) {
            _storeResultText = query;
            StoreModel storeModel = StoreModel.fromJson(response.body);
            _searchStoreTotalSize = storeModel.totalSize ?? _searchStoreTotalSize;
            _searchStoreOffset = storeModel.offset ?? offset;
            _searchStoreLimit =
                int.tryParse(storeModel.limit ?? '') ?? _searchStoreLimit;
            if (isPaginating) {
              _searchStoreList ??= [];
              _allStoreList ??= [];
            } else {
              _searchStoreList = [];
              _allStoreList = [];
              _searchStoreOffsetList.add(_searchStoreOffset);
            }
            _searchStoreList!.addAll(storeModel.stores ?? []);
            _allStoreList!.addAll(storeModel.stores ?? []);
          } else {
            _itemResultText = query;
            ItemModel itemModel = ItemModel.fromJson(response.body);
            _searchItemTotalSize = itemModel.totalSize ?? _searchItemTotalSize;
            _searchItemOffset = itemModel.offset ?? offset;
            _searchItemLimit =
                int.tryParse(itemModel.limit ?? '') ?? _searchItemLimit;
            if (isPaginating) {
              _searchItemList ??= [];
              _allItemList ??= [];
            } else {
              _searchItemList = [];
              _allItemList = [];
              _searchItemOffsetList.add(_searchItemOffset);
            }
            _allItemList!.addAll(itemModel.items ?? []);
            if (_hasActiveItemFilter()) {
              _searchItemList = searchServiceInterface.sortItemSearchList(
                _allItemList,
                _upperValue,
                _lowerValue,
                _rating,
                _veg,
                _nonVeg,
                _isAvailableItems,
                _isDiscountedItems,
                _sortIndex,
              );
            } else {
              _searchItemList!.addAll(itemModel.items ?? []);
            }
          }
        }
      }
      update();
    }
  }

  Future<void> paginateSearchItems(String? query) async {
    if (query == null ||
        query.trim().isEmpty ||
        _isSearchItemPaginating ||
        !hasMoreSearchItems) {
      return;
    }
    final int nextOffset = _searchItemOffset + 1;
    if (_searchItemOffsetList.contains(nextOffset)) return;
    _searchItemOffsetList.add(nextOffset);
    _isSearchItemPaginating = true;
    update();

    final bool previousIsStore = _isStore;
    _isStore = false;
    await searchData(query, false, offset: nextOffset);
    _isStore = previousIsStore;
    if (_searchItemOffset < nextOffset) {
      _searchItemOffsetList.remove(nextOffset);
    }

    _isSearchItemPaginating = false;
    update();
  }

  Future<void> paginateSearchStores(String? query) async {
    if (query == null ||
        query.trim().isEmpty ||
        _isSearchStorePaginating ||
        !hasMoreSearchStores) {
      return;
    }
    final int nextOffset = _searchStoreOffset + 1;
    if (_searchStoreOffsetList.contains(nextOffset)) return;
    _searchStoreOffsetList.add(nextOffset);
    _isSearchStorePaginating = true;
    update();

    final bool previousIsStore = _isStore;
    _isStore = true;
    await searchData(query, false, offset: nextOffset);
    _isStore = previousIsStore;
    if (_searchStoreOffset < nextOffset) {
      _searchStoreOffsetList.remove(nextOffset);
    }

    _isSearchStorePaginating = false;
    update();
  }

  // The applied filter (from the filter screen). Sent to the search API as query
  // params so the server returns filtered, paginated results.
  SearchNewFilterState? _searchFilter;
  SearchNewFilterState? get searchFilter => _searchFilter;

  // "Near me" search: when on, both the items and stores search requests carry
  // `filter_by=nearby`. Treated like a sticky filter so it applies to items,
  // stores and pagination until a new/normal search resets it.
  bool _nearbyFilter = false;
  bool get isNearbyFilter => _nearbyFilter;

  /// Turns the nearby filter on/off and re-fetches in place (bumps [filterVersion]
  /// and clears both result sets so the result view reloads with the new param).
  void setNearbyFilter(bool nearby) {
    if (_nearbyFilter == nearby) return;
    _nearbyFilter = nearby;
    _filterVersion++;
    _resetItemResults();
    _resetStoreResults();
    update();
  }

  bool get hasActiveItemFilter => _searchFilter?.hasActiveFilters ?? false;

  // Bumped each time a filter is applied so the result section knows to re-fetch.
  int _filterVersion = 0;
  int get filterVersion => _filterVersion;

  void _resetItemResults() {
    _searchItemList = null;
    _allItemList = null;
    _searchItemTotalSize = null;
    _searchItemOffset = 1;
    _searchItemOffsetList.clear();
    _itemResultText = '';
  }

  void _resetStoreResults() {
    _searchStoreList = null;
    _allStoreList = null;
    _searchStoreTotalSize = null;
    _searchStoreOffset = 1;
    _searchStoreOffsetList.clear();
    _storeResultText = '';
  }

  /// Applies the chosen filters and clears both result sets. The result section
  /// then re-fetches items and/or stores for its active tab (all = both,
  /// items = items only, stores = stores only).
  void applySearchFilter(SearchNewFilterState filter) {
    _searchFilter = filter;
    _filterVersion++;
    _resetItemResults();
    _resetStoreResults();
    update();
  }

  Map<String, String> _buildFilterQuery() {
    final Map<String, String> q = <String, String>{};
    if (_nearbyFilter) q['filter_by'] = 'nearby';
    final SearchNewFilterState? f = _searchFilter;
    if (f == null || !f.hasActiveFilters) return q;
    if (f.minPrice > 0) q['min_price'] = f.minPrice.toStringAsFixed(0);
    if (f.maxPrice < 1000) q['max_price'] = f.maxPrice.toStringAsFixed(0);
    if (f.ratings.isNotEmpty) {
      // Multi-select ratings → rating_counts=[2,5]
      final List<int> ratings = f.ratings.toList()..sort();
      q['rating_plus'] = jsonEncode(ratings);
    }
    // Type is single-select → filter=non_veg (plain value, not a list).
    if (f.types.contains('Veg')) {
      q['filter'] = 'veg';
    } else if (f.types.contains('Non - Veg')) {
      q['filter'] = 'non_veg';
    } else if (f.types.contains('Halal')) {
      q['filter'] = 'halal';
    }
    final List<int> categoryIds = _categoryIdsForNames(f.categories);
    if (categoryIds.isNotEmpty) q['category_ids'] = jsonEncode(categoryIds);
    return q;
  }

  List<int> _categoryIdsForNames(Set<String> names) {
    if (names.isEmpty) return <int>[];
    final List<CategoryModel>? categories = Get.find<CategoryController>().categoryList;
    if (categories == null) return <int>[];
    final List<int> ids = <int>[];
    for (final CategoryModel c in categories) {
      if (c.id != null && c.name != null && names.contains(c.name)) ids.add(c.id!);
    }
    return ids;
  }

  bool _hasActiveItemFilter() {
    return _upperValue > 0 ||
        _rating != -1 ||
        _veg ||
        _nonVeg ||
        _isAvailableItems ||
        _isDiscountedItems ||
        _sortIndex != -1;
  }

  void getHistoryList({String moduleKey = ''}) {
    _moduleKey = moduleKey;
    _isSearchMode = true;
    _searchText = '';
    _historyList = [];
    _historyList.addAll(
      searchServiceInterface.getSearchAddress(moduleKey: _moduleKey),
    );
  }

  void _addRecentSearch(RecentSearchEntry entry) {
    if (entry.name.trim().isEmpty) return;
    _historyList.removeWhere((RecentSearchEntry e) =>
        e.kind == entry.kind && e.name.toLowerCase() == entry.name.toLowerCase());
    _historyList.insert(0, entry);
    searchServiceInterface.saveSearchHistory(_historyList, moduleKey: _moduleKey);
  }

  void removeRecentSearch(RecentSearchEntry entry) {
    _historyList.removeWhere((RecentSearchEntry e) =>
        e.kind == entry.kind && e.name == entry.name && e.moduleId == entry.moduleId);
    searchServiceInterface.saveSearchHistory(_historyList, moduleKey: _moduleKey);
    update();
  }

  void clearSearchHistory() async {
    searchServiceInterface.clearSearchHistory(moduleKey: _moduleKey);
    _historyList = [];
    update();
  }

  void setRating(int rate) {
    _rating = rate;
    update();
  }

  void setStoreRating(int rate) {
    _storeRating = rate;
    update();
  }

  void setSortIndex(int index) {
    _sortIndex = index;
    update();
  }

  void setStoreSortIndex(int index) {
    _storeSortIndex = index;
    update();
  }

  void resetFilter() {
    _rating = -1;
    _upperValue = 0;
    _lowerValue = 0;
    _isAvailableItems = false;
    _isDiscountedItems = false;
    _veg = false;
    _nonVeg = false;
    _sortIndex = -1;
    update();
  }

  void resetStoreFilter() {
    _storeRating = -1;
    _isAvailableStore = false;
    _isDiscountedStore = false;
    _storeVeg = false;
    _storeNonVeg = false;
    _storeSortIndex = -1;
    update();
  }

  void clearSearchHomeText() {
    _searchHomeText = '';
    update();
  }

  Future<List<RecentSearchEntry>> getSearchSuggestions(String searchText) async {
    final List<RecentSearchEntry> suggestions = <RecentSearchEntry>[];
    _searchSuggestionModel = await searchServiceInterface.getSearchSuggestions(
      searchText,
      isGlobal: _isGlobalSearch,
    );
    final int? fallbackModuleId = Get.find<SplashController>().module?.id;
    final String? fallbackModuleType = Get.find<SplashController>().module?.moduleType;
    final String? fallbackModuleName = Get.find<SplashController>().module?.moduleName;
    if (_searchSuggestionModel != null) {
      for (final Items item in _searchSuggestionModel!.items ?? <Items>[]) {
        final int? moduleId = item.moduleId ?? fallbackModuleId;
        suggestions.add(RecentSearchEntry(
          name: item.name ?? '',
          kind: RecentSearchKind.item,
          moduleId: moduleId,
          moduleType: item.moduleType ?? fallbackModuleType,
          moduleName: item.moduleName ?? fallbackModuleName,
          moduleImage: _moduleImage(moduleId),
        ));
      }
      for (final Stores store in _searchSuggestionModel!.stores ?? <Stores>[]) {
        final int? moduleId = store.moduleId ?? fallbackModuleId;
        suggestions.add(RecentSearchEntry(
          name: store.name ?? '',
          kind: RecentSearchKind.store,
          moduleId: moduleId,
          moduleType: store.moduleType ?? fallbackModuleType,
          moduleName: store.moduleName ?? fallbackModuleName,
          moduleImage: _moduleImage(moduleId),
        ));
      }
    }
    return _prioritizeByMatch(searchText, suggestions);
  }

  // Suggestions whose name matches the query at or above this score float to the
  // top (sorted by score); weaker matches keep their shuffled order below.
  static const double _strongMatchThreshold = 0.70;

  /// Floats strong name-matches (>= [_strongMatchThreshold]) to the top sorted by
  /// score, while the remaining (weak) suggestions stay shuffled — preserving the
  /// previous "interleave items & stores" behaviour for non-prioritised entries.
  List<RecentSearchEntry> _prioritizeByMatch(String query, List<RecentSearchEntry> list) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty || list.length < 2) {
      list.shuffle();
      return list;
    }

    final List<_ScoredEntry> strong = <_ScoredEntry>[];
    final List<RecentSearchEntry> weak = <RecentSearchEntry>[];
    for (final RecentSearchEntry entry in list) {
      final double score = _suggestionMatchScore(q, entry.name);
      if (score >= _strongMatchThreshold) {
        strong.add(_ScoredEntry(entry, score));
      } else {
        weak.add(entry);
      }
    }

    // Strong bucket: highest score first; ties → shorter name (closer to exact),
    // kept deterministic so the order doesn't jitter between keystrokes.
    strong.sort((a, b) {
      final int byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.entry.name.length.compareTo(b.entry.name.length);
    });
    weak.shuffle();

    return <RecentSearchEntry>[...strong.map((e) => e.entry), ...weak];
  }

  /// 0.0–1.0 match score of [name] against the already-lowercased [query],
  /// taken as the best score across the full name and its word tokens.
  double _suggestionMatchScore(String query, String name) {
    final String normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return 0;

    double best = _candidateScore(query, normalized);
    for (final String token in normalized.split(RegExp(r'\s+'))) {
      if (token.isEmpty) continue;
      best = math.max(best, _candidateScore(query, token));
      if (best >= 1.0) break;
    }
    return best;
  }

  double _candidateScore(String query, String candidate) {
    if (candidate == query) return 1.0;
    if (candidate.startsWith(query)) {
      return 0.90 + 0.10 * (query.length / candidate.length);
    }
    if (candidate.contains(query)) {
      return 0.70 + 0.20 * (query.length / candidate.length);
    }
    // Fuzzy fallback for typos — only for queries long enough to be meaningful,
    // so 1–2 char queries don't over-match unrelated names.
    if (query.length >= 3) {
      final int distance = _levenshtein(query, candidate);
      final int maxLen = math.max(query.length, candidate.length);
      if (maxLen == 0) return 0;
      return (1 - distance / maxLen).clamp(0.0, 1.0).toDouble();
    }
    return 0;
  }

  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    List<int> previous = List<int>.generate(b.length + 1, (int i) => i);
    List<int> current = List<int>.filled(b.length + 1, 0);
    for (int i = 0; i < a.length; i++) {
      current[0] = i + 1;
      for (int j = 0; j < b.length; j++) {
        final int cost = a.codeUnitAt(i) == b.codeUnitAt(j) ? 0 : 1;
        current[j + 1] = math.min(math.min(current[j] + 1, previous[j + 1] + 1), previous[j] + cost);
      }
      final List<int> temp = previous;
      previous = current;
      current = temp;
    }
    return previous[b.length];
  }

  /// Resolves a module's logo from the loaded module list, captured at the time
  /// a suggestion is tapped so the saved recent search renders it offline.
  String? _moduleImage(int? moduleId) {
    if (moduleId == null) return null;
    final List<ModuleModel>? modules = Get.find<SplashController>().moduleList;
    if (modules == null) return null;
    for (final ModuleModel module in modules) {
      if (module.id == moduleId) return module.iconFullUrl ?? module.thumbnailFullUrl;
    }
    return null;
  }

  Future<void> getPopularCategories() async {
    _popularCategoryList = null;
    _popularCategoryList = await searchServiceInterface.getPopularCategories();
    update();
  }

  ///Voice Search..................

  bool voiceIsListening = false;
  String voiceText = '';
  double voiceSoundLevel = 0.0;
  bool voiceAvailable = false;
  Timer? _voiceAutoSubmitTimer;

  // When set, submitVoiceNow() delegates to this instead of calling searchData()
  // directly — lets the screen run its full _actionSearch flow (suggestion fetch +
  // module scoping) the same way a keyboard submit does.
  void Function(String)? _voiceSubmitCallback;

  void registerVoiceSubmitCallback(void Function(String) callback) {
    _voiceSubmitCallback = callback;
  }

  void unregisterVoiceSubmitCallback() {
    _voiceSubmitCallback = null;
  }

  late stt.SpeechToText _speech;

  /// Initialize speech (safe to call multiple times)
  Future<void> initVoice({bool isUpdate = true}) async {
    try {
      final available = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
      );
      voiceAvailable = available;
    } catch (e) {
      voiceAvailable = false;
    }
    if (isUpdate) update();
  }

  void _onStatus(String status) {
    if (status == stt.SpeechToText.listeningStatus) {
      setVoiceListening(true);
      cancelVoiceAutoSubmit();
    } else if (status == stt.SpeechToText.doneStatus ||
        status == stt.SpeechToText.notListeningStatus ||
        status == 'not listening') {
      setVoiceListening(false);
      scheduleVoiceAutoSubmit(const Duration(seconds: 2));
    }
  }

  void _onError(dynamic error) {
    setVoiceListening(false);
  }

  /// Start listening and optionally update an external TextEditingController live
  Future<void> startVoiceListening({
    TextEditingController? externalController,
  }) async {
    cancelVoiceAutoSubmit();

    // clear any previous session
    try {
      if (_speech.isListening) await _speech.stop();
      await _speech.cancel();
    } catch (_) {}

    if (!voiceAvailable) {
      await initVoice();
      if (!voiceAvailable) return;
    }

    // reset
    setVoiceText('');
    setVoiceSoundLevel(0.0);

    try {
      await _speech.listen(
        onResult: (result) {
          final recognized = result.recognizedWords;
          setVoiceText(recognized);
          if (externalController != null) {
            externalController.text = recognized;
            externalController.selection = TextSelection.fromPosition(
              TextPosition(offset: externalController.text.length),
            );
          }
        },
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 5),
        onSoundLevelChange: (level) {
          final normalized = (level / 50).clamp(0.0, 1.0);
          setVoiceSoundLevel(normalized);
        },
        localeId:
            '${Get.find<LocalizationController>().locale.languageCode}_${Get.find<LocalizationController>().locale.countryCode}',
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.search,
        ),
      );
      if (_speech.isListening) {
        setVoiceListening(true);
      } else {
        setVoiceListening(false);
      }
    } catch (e) {
      setVoiceListening(false);
    }
  }

  /// Stop or cancel listening
  Future<void> stopVoiceListening({bool submit = false}) async {
    cancelVoiceAutoSubmit();
    try {
      await _speech.stop();
    } catch (e) {
      try {
        await _speech.cancel();
      } catch (_) {}
    }
    setVoiceListening(false);
    if (submit) await submitVoiceNow();
  }

  void setVoiceListening(bool value, {bool isUpdate = true}) {
    voiceIsListening = value;
    if (isUpdate) update();
  }

  void setVoiceText(String text, {bool isUpdate = true}) {
    voiceText = text;
    if (isUpdate) update();
  }

  void setVoiceSoundLevel(double level, {bool isUpdate = true}) {
    voiceSoundLevel = level;
    if (isUpdate) update();
  }

  void scheduleVoiceAutoSubmit(Duration duration) {
    _voiceAutoSubmitTimer?.cancel();
    _voiceAutoSubmitTimer = Timer(duration, () async {
      await submitVoiceNow();
    });
  }

  void cancelVoiceAutoSubmit() {
    _voiceAutoSubmitTimer?.cancel();
    _voiceAutoSubmitTimer = null;
  }

  Future<void> submitVoiceNow() async {
    cancelVoiceAutoSubmit();
    final text = voiceText.trim();
    if (text.isNotEmpty) {
      try {
        if ((Get.isBottomSheetOpen ?? false) || (Get.isDialogOpen ?? false)) {
          Get.back();
        }
      } catch (_) {}
      if (_voiceSubmitCallback != null) {
        // Keep the search field text in sync before _actionSearch reads it.
        setSearchText(text);
        _voiceSubmitCallback!(text);
      } else {
        await searchData(text, false);
      }
    }
  }

  @override
  void onClose() {
    _voiceAutoSubmitTimer?.cancel();
    super.onClose();
  }

  List<Store>? _exclusiveDealsStores;
  List<Store>? get exclusiveDealsStores => _exclusiveDealsStores;

  // Top categories — shown only in global search (init view), fetched across all
  // modules. UI section is wired separately.
  List<TopCategory>? _topCategoryList;
  List<TopCategory>? get topCategoryList => _topCategoryList;

  Future<void> getTopCategories() async {
    _topCategoryList = null;
    _topCategoryList = await searchServiceInterface.getTopCategories();
    update();
  }

  Future<void> getExclusiveDeals({bool notify = true}) async {
    _exclusiveDealsStores = null;
    if (notify) update();
    _exclusiveDealsStores = await searchServiceInterface.getExclusiveDeals();
    update();
  }

  List<BrandModel>? _brandList;
  List<BrandModel>? get brandList => _brandList;

  Future<void> getBrandList({bool notify = true}) async {
    final int? moduleId = Get.find<SplashController>().module?.id;
    final List<int>? zoneIds =
        AddressHelper.getUserAddressFromSharedPref()?.zoneIds;
    if (moduleId == null || zoneIds == null || zoneIds.isEmpty) {
      return;
    }
    _brandList = null;
    if (notify) update();
    _brandList = await searchServiceInterface.getBrandList(
      moduleId: moduleId,
      zoneIds: zoneIds,
    );
    update();
  }
}

// Pairs a suggestion with its computed match score for ranking.
class _ScoredEntry {
  final RecentSearchEntry entry;
  final double score;
  const _ScoredEntry(this.entry, this.score);
}
