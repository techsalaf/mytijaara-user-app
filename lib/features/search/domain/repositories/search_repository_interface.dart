import 'package:sixam_mart/features/brands/domain/models/brands_model.dart';
import 'package:sixam_mart/features/search/domain/models/popular_categories_model.dart';
import 'package:sixam_mart/features/search/domain/models/recent_search_entry.dart';
import 'package:sixam_mart/features/search/domain/models/search_suggestion_model.dart';
import 'package:sixam_mart/features/search/domain/models/top_category_model.dart';
import 'package:sixam_mart/features/search/domain/models/trending_search_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/interfaces/repository_interface.dart';

abstract class SearchRepositoryInterface extends RepositoryInterface {
  Future<bool> saveSearchHistory(List<RecentSearchEntry> searchHistories, {String moduleKey = ''});
  List<RecentSearchEntry> getSearchAddress({String moduleKey = ''});
  Future<bool> clearSearchHistory({String moduleKey = ''});
  @override
  Future getList({int? offset, String? query, bool? isStore, bool isSuggestedItems = false, int? moduleId, Map<String, String>? filterParams});
  Future<SearchSuggestionModel?> getSearchSuggestions(String searchText, {bool isGlobal = false});
  Future<List<PopularCategoryModel?>?> getPopularCategories();
  Future<List<BrandModel>?> getBrandList({required int moduleId, required List<int> zoneIds});
  Future<List<Store>?> getExclusiveDeals();
  Future<List<TopCategory>?> getTopCategories({int offset = 1});
  Future<List<TrendingSearch>?> getTrendingSearches({bool isGlobal = false});
}