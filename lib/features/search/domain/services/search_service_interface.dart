import 'package:get/get_connect/http/src/response/response.dart';
import 'package:sixam_mart/features/brands/domain/models/brands_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/search/domain/models/popular_categories_model.dart';
import 'package:sixam_mart/features/search/domain/models/recent_search_entry.dart';
import 'package:sixam_mart/features/search/domain/models/search_suggestion_model.dart';
import 'package:sixam_mart/features/search/domain/models/top_category_model.dart';
import 'package:sixam_mart/features/search/domain/models/trending_search_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';

abstract class SearchServiceInterface {
  Future<Response> getSearchData(String? query, bool isStore, {int offset = 1, int? moduleId, Map<String, String>? filterParams});
  Future<List<Item>?> getSuggestedItems();
  Future<bool> saveSearchHistory(
    List<RecentSearchEntry> searchHistories, {
    String moduleKey = '',
  });
  List<RecentSearchEntry> getSearchAddress({String moduleKey = ''});
  Future<bool> clearSearchHistory({String moduleKey = ''});
  List<Item>? sortItemSearchList(
    List<Item>? allItemList,
    double upperValue,
    double lowerValue,
    int rating,
    bool veg,
    bool nonVeg,
    bool isAvailableItems,
    bool isDiscountedItems,
    int sortIndex,
  );
  List<Store>? sortStoreSearchList(
    List<Store>? allStoreList,
    int storeRating,
    bool storeVeg,
    bool storeNonVeg,
    bool isAvailableStore,
    bool isDiscountedStore,
    int storeSortIndex,
  );
  Future<SearchSuggestionModel?> getSearchSuggestions(String searchText, {bool isGlobal = false});
  Future<List<PopularCategoryModel?>?> getPopularCategories();
  Future<List<BrandModel>?> getBrandList({
    required int moduleId,
    required List<int> zoneIds,
  });
  Future<List<Store>?> getExclusiveDeals();
  Future<List<TopCategory>?> getTopCategories({int offset = 1});
  Future<List<TrendingSearch>?> getTrendingSearches({bool isGlobal = false});
}
