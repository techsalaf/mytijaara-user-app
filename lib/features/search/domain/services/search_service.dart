import 'package:get/get.dart';
import 'package:sixam_mart/features/brands/domain/models/brands_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/search/domain/models/popular_categories_model.dart';
import 'package:sixam_mart/features/search/domain/models/recent_search_entry.dart';
import 'package:sixam_mart/features/search/domain/models/search_suggestion_model.dart';
import 'package:sixam_mart/features/search/domain/models/top_category_model.dart';
import 'package:sixam_mart/features/search/domain/models/trending_search_model.dart';
import 'package:sixam_mart/features/search/domain/repositories/search_repository_interface.dart';
import 'package:sixam_mart/features/search/domain/services/search_service_interface.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/date_converter.dart';

class SearchService implements SearchServiceInterface {
  final SearchRepositoryInterface searchRepositoryInterface;
  SearchService({required this.searchRepositoryInterface});

  @override
  Future<Response> getSearchData(
    String? query,
    bool isStore, {
    int offset = 1,
    int? moduleId,
    Map<String, String>? filterParams,
  }) async {
    return await searchRepositoryInterface.getList(
      offset: offset,
      query: query,
      isStore: isStore,
      moduleId: moduleId,
      filterParams: filterParams,
    );
  }

  @override
  Future<List<Item>?> getSuggestedItems() async {
    return await searchRepositoryInterface.getList(isSuggestedItems: true);
  }

  @override
  Future<bool> saveSearchHistory(
    List<RecentSearchEntry> searchHistories, {
    String moduleKey = '',
  }) async {
    return await searchRepositoryInterface.saveSearchHistory(
      searchHistories,
      moduleKey: moduleKey,
    );
  }

  @override
  List<RecentSearchEntry> getSearchAddress({String moduleKey = ''}) {
    return searchRepositoryInterface.getSearchAddress(moduleKey: moduleKey);
  }

  @override
  Future<bool> clearSearchHistory({String moduleKey = ''}) async {
    return await searchRepositoryInterface.clearSearchHistory(
      moduleKey: moduleKey,
    );
  }

  @override
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
  ) {
    List<Item>? searchItemList = [];
    searchItemList.addAll(allItemList!);
    if (upperValue > 0) {
      searchItemList.removeWhere(
        (product) =>
            product.price! <= lowerValue || product.price! > upperValue,
      );
    }
    if (rating != -1) {
      searchItemList.removeWhere((product) => product.avgRating! < rating);
    }
    if (!veg && nonVeg) {
      searchItemList.removeWhere((product) => product.veg == 1);
    }
    if (!nonVeg && veg) {
      searchItemList.removeWhere((product) => product.veg == 0);
    }
    if (isAvailableItems || isDiscountedItems) {
      if (isAvailableItems) {
        searchItemList.removeWhere(
          (product) => !DateConverter.isAvailable(
            product.availableTimeStarts,
            product.availableTimeEnds,
          ),
        );
      }
      if (isDiscountedItems) {
        searchItemList.removeWhere((product) => product.discount == 0);
      }
    }
    if (sortIndex != -1) {
      if (sortIndex == 0) {
        searchItemList.sort(
          (a, b) => a.name!.toLowerCase().compareTo(b.name!.toLowerCase()),
        );
      } else {
        searchItemList.sort(
          (a, b) => a.name!.toLowerCase().compareTo(b.name!.toLowerCase()),
        );
        Iterable iterable = searchItemList.reversed;
        searchItemList = iterable.toList() as List<Item>?;
      }
    }
    return searchItemList;
  }

  @override
  List<Store>? sortStoreSearchList(
    List<Store>? allStoreList,
    int storeRating,
    bool storeVeg,
    bool storeNonVeg,
    bool isAvailableStore,
    bool isDiscountedStore,
    int storeSortIndex,
  ) {
    List<Store>? searchStoreList = [];
    searchStoreList.addAll(allStoreList!);
    if (storeRating != -1) {
      searchStoreList.removeWhere((store) => store.avgRating! < storeRating);
    }
    if (!storeVeg && storeNonVeg) {
      searchStoreList.removeWhere((product) => product.nonVeg == 0);
    }
    if (!storeNonVeg && storeVeg) {
      searchStoreList.removeWhere((product) => product.veg == 0);
    }
    if (isAvailableStore || isDiscountedStore) {
      if (isAvailableStore) {
        searchStoreList.removeWhere(
          (store) => store.open == 0 || !store.active!,
        );
      }
      if (isDiscountedStore) {
        searchStoreList.removeWhere((store) => store.discount == null);
      }
    }
    if (storeSortIndex != -1) {
      if (storeSortIndex == 0) {
        searchStoreList.sort(
          (a, b) => a.name!.toLowerCase().compareTo(b.name!.toLowerCase()),
        );
      } else {
        searchStoreList.sort(
          (a, b) => a.name!.toLowerCase().compareTo(b.name!.toLowerCase()),
        );
        Iterable iterable = searchStoreList.reversed;
        searchStoreList = iterable.toList() as List<Store>?;
      }
    }
    return searchStoreList;
  }

  @override
  Future<SearchSuggestionModel?> getSearchSuggestions(String searchText, {bool isGlobal = false}) async {
    return await searchRepositoryInterface.getSearchSuggestions(searchText, isGlobal: isGlobal);
  }

  @override
  Future<List<PopularCategoryModel?>?> getPopularCategories() async {
    return await searchRepositoryInterface.getPopularCategories();
  }

  @override
  Future<List<BrandModel>?> getBrandList({
    required int moduleId,
    required List<int> zoneIds,
  }) async {
    return await searchRepositoryInterface.getBrandList(
      moduleId: moduleId,
      zoneIds: zoneIds,
    );
  }

  @override
  Future<List<Store>?> getExclusiveDeals() async {
    return await searchRepositoryInterface.getExclusiveDeals();
  }

  @override
  Future<List<TopCategory>?> getTopCategories({int offset = 1}) async {
    return await searchRepositoryInterface.getTopCategories(offset: offset);
  }

  @override
  Future<List<TrendingSearch>?> getTrendingSearches({bool isGlobal = false}) async {
    return await searchRepositoryInterface.getTrendingSearches(isGlobal: isGlobal);
  }
}
