import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/brands/domain/models/brands_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/search/domain/models/popular_categories_model.dart';
import 'package:sixam_mart/features/search/domain/models/recent_search_entry.dart';
import 'package:sixam_mart/features/search/domain/models/search_suggestion_model.dart';
import 'package:sixam_mart/features/search/domain/models/top_category_model.dart';
import 'package:sixam_mart/features/search/domain/models/trending_search_model.dart';
import 'package:sixam_mart/features/search/domain/repositories/search_repository_interface.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/util/app_constants.dart';

class SearchRepository implements SearchRepositoryInterface {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  SearchRepository({required this.apiClient, required this.sharedPreferences});

  String _historyKey(String moduleKey) => moduleKey.isEmpty
      ? AppConstants.searchHistory
      : '${AppConstants.searchHistory}_$moduleKey';

  @override
  Future<bool> saveSearchHistory(
    List<RecentSearchEntry> searchHistories, {
    String moduleKey = '',
  }) async {
    final List<String> encoded = searchHistories
        .map((RecentSearchEntry entry) => jsonEncode(entry.toJson()))
        .toList();
    return await sharedPreferences.setStringList(_historyKey(moduleKey), encoded);
  }

  @override
  List<RecentSearchEntry> getSearchAddress({String moduleKey = ''}) {
    final List<String> stored = sharedPreferences.getStringList(_historyKey(moduleKey)) ?? [];
    final List<RecentSearchEntry> entries = [];
    for (final String value in stored) {
      try {
        final dynamic decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) {
          entries.add(RecentSearchEntry.fromJson(decoded));
          continue;
        }
      } catch (_) {}
      // Legacy plain-string history — treat as a free-text keyword.
      entries.add(RecentSearchEntry.keyword(value));
    }
    return entries;
  }

  @override
  Future<bool> clearSearchHistory({String moduleKey = ''}) async {
    return sharedPreferences.setStringList(_historyKey(moduleKey), []);
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    throw UnimplementedError();
  }

  @override
  Future get(String? id) {
    throw UnimplementedError();
  }

  @override
  Future getList({
    int? offset,
    String? query,
    bool? isStore,
    bool isSuggestedItems = false,
    int? moduleId,
    Map<String, String>? filterParams,
  }) async {
    if (isSuggestedItems) {
      return await _getSuggestedItems();
    } else {
      return await _getSearchData(query, isStore!, offset ?? 1, moduleId: moduleId, filterParams: filterParams);
    }
  }

  Future<List<Item>?> _getSuggestedItems() async {
    List<Item>? suggestedItemList;
    Response response = await apiClient.getData(AppConstants.suggestedItemUri);
    if (response.statusCode == 200) {
      suggestedItemList = [];
      response.body.forEach(
        (suggestedItem) => suggestedItemList!.add(Item.fromJson(suggestedItem)),
      );
    }
    return suggestedItemList;
  }

  Future<Response> _getSearchData(
    String? query,
    bool isStore,
    int offset, {
    int? moduleId,
    Map<String, String>? filterParams,
  }) async {
    // In global search, scope the results to the selected module by overriding
    // the module_id header just for this call.
    final Map<String, String>? headers = moduleId != null
        ? {...apiClient.getHeader(), AppConstants.moduleId: moduleId.toString()}
        : null;
    final StringBuffer uri = StringBuffer(
      '${AppConstants.searchUri}${isStore ? 'stores' : 'items'}/search?name=$query&offset=$offset&limit=10',
    );
    // Apply the filter params (category_ids, filter, rating_counts, min_price,
    // max_price) to the search request. Values are appended raw so list brackets
    // (e.g. category_ids=[2,1,5]) aren't percent-encoded.
    filterParams?.forEach((String key, String value) {
      uri.write('&$key=$value');
    });
    return await apiClient.getData(uri.toString(), headers: headers);
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }

  @override
  Future<SearchSuggestionModel?> getSearchSuggestions(String searchText, {bool isGlobal = false}) async {
    SearchSuggestionModel? searchSuggestionModel;
    // Global suggestions span all modules — drop the module_id header so the
    // backend isn't scoped to the active module, and flag it with is_global.
    final Map<String, String> headers = {...apiClient.getHeader()};
    if (isGlobal) {
      headers.remove(AppConstants.moduleId);
    }
    Response response = await apiClient.getData(
      '${AppConstants.searchSuggestionsUri}?name=$searchText&is_global=${isGlobal ? 1 : 0}',
      headers: headers,
    );
    if (response.statusCode == 200) {
      searchSuggestionModel = SearchSuggestionModel.fromJson(response.body);
    }
    return searchSuggestionModel;
  }

  @override
  Future<List<PopularCategoryModel?>?> getPopularCategories() async {
    List<PopularCategoryModel?>? popularCategoryList;
    Response response = await apiClient.getData(
      AppConstants.searchPopularCategoriesUri,
    );
    if (response.statusCode == 200) {
      popularCategoryList = [];
      response.body.forEach((category) {
        popularCategoryList!.add(PopularCategoryModel.fromJson(category));
      });
    }
    return popularCategoryList;
  }

  @override
  Future<List<BrandModel>?> getBrandList({
    required int moduleId,
    required List<int> zoneIds,
  }) async {
    List<BrandModel>? brandList;
    final Map<String, String> headers = {
      ...apiClient.getHeader(),
      AppConstants.moduleId: moduleId.toString(),
      AppConstants.zoneId: jsonEncode(zoneIds),
      'top': '1',
    };
    Response response = await apiClient.getData(
      AppConstants.brandListUri,
      headers: headers,
    );
    if (response.statusCode == 200) {
      brandList = [];
      response.body.forEach(
        (brand) => brandList!.add(BrandModel.fromJson(brand)),
      );
    }
    return brandList;
  }

  @override
  Future<List<Store>?> getExclusiveDeals() async {
    List<Store>? stores;
    Response response = await apiClient.getData(AppConstants.exclusiveDealsUri);
    if (response.statusCode == 200) {
      stores = StoreModel.fromJson(response.body).stores;
    }
    return stores;
  }

  @override
  Future<List<TrendingSearch>?> getTrendingSearches({bool isGlobal = false}) async {
    List<TrendingSearch>? trendingSearches;
    // In global search, fetch trending across all modules by dropping module_id.
    final Map<String, String>? headers = isGlobal
        ? ({...apiClient.getHeader()}..remove(AppConstants.moduleId))
        : null;
    Response response = await apiClient.getData('${AppConstants.trendingSearchesUri}${isGlobal ? '?is_global=true' : ''}', headers: headers);
    if (response.statusCode == 200) {
      trendingSearches = TrendingSearchModel.fromJson(response.body).trendingSearches;
    }
    return trendingSearches;
  }

  @override
  Future<List<TopCategory>?> getTopCategories({int offset = 1}) async {
    List<TopCategory>? categories;
    // Top categories are shown only in global search — fetch across all modules
    // by dropping the module_id header for this call.
    final Map<String, String> headers = {...apiClient.getHeader()}..remove(AppConstants.moduleId);
    Response response = await apiClient.getData(
      '${AppConstants.topCategoriesUri}?limit=10&offset=$offset',
      headers: headers,
    );
    if (response.statusCode == 200) {
      categories = TopCategoryModel.fromJson(response.body).categories;
    }
    return categories;
  }
}
