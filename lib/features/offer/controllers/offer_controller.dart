import 'package:get/get.dart';
import 'package:sixam_mart/features/redesign_feature/common/models/new_item_model.dart';
import 'package:sixam_mart/features/offer/domain/services/offer_service_interface.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';

class OfferController extends GetxController implements GetxService {
  final OfferServiceInterface offerServiceInterface;
  OfferController({required this.offerServiceInterface});

  static const String typeAll = 'all';
  static const String typeItem = 'item';
  static const String typeStore = 'store';
  static const int pageLimit = 10;

  NewItemListResponse? _itemList;
  NewItemListResponse? get itemList => _itemList;

  StoreModel? _storeList;
  StoreModel? get storeList => _storeList;

  List<Store>? _exclusiveDeals;
  List<Store>? get exclusiveDeals => _exclusiveDeals;

  String _selectedType = typeAll;
  String get selectedType => _selectedType;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  int? _selectedModuleId;
  int? get selectedModuleId => _selectedModuleId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _itemOffset = 1;
  int get itemOffset => _itemOffset;

  int _storeOffset = 1;
  int get storeOffset => _storeOffset;

  Future<void> loadOffers({String? type, String? search, int? moduleId, bool clearModule = false, bool reload = false, bool notify = true}) async {
    final String nextType = type ?? _selectedType;
    final String nextSearch = search ?? _searchQuery;
    final int? nextModuleId = clearModule ? null : (moduleId ?? _selectedModuleId);
    final bool typeChanged = nextType != _selectedType;
    final bool searchChanged = nextSearch != _searchQuery;
    final bool moduleChanged = nextModuleId != _selectedModuleId;

    if (reload || typeChanged || searchChanged || moduleChanged) {
      _selectedType = nextType;
      _searchQuery = nextSearch;
      _selectedModuleId = nextModuleId;
      _itemList = null;
      _storeList = null;
      _itemOffset = 1;
      _storeOffset = 1;
    }

    // Exclusive deals depend on the module only — refetch on first load or a
    // module switch, but not on type/search changes (those keep the same deals).
    final bool fetchDeals = moduleChanged || _exclusiveDeals == null;
    if (fetchDeals) {
      _exclusiveDeals = null;
    }

    _isLoading = true;
    if (notify) update();

    await Future.wait<void>(<Future<void>>[
      if (_shouldFetchItems) _fetchItems(offset: 1, replace: true),
      if (_shouldFetchStores) _fetchStores(offset: 1, replace: true),
      if (fetchDeals) _fetchExclusiveDeals(),
    ]);

    _isLoading = false;
    update();
  }

  Future<void> _fetchExclusiveDeals() async {
    _exclusiveDeals = await offerServiceInterface.getExclusiveDeals(moduleId: _selectedModuleId);
  }

  Future<void> _fetchItems({required int offset, bool replace = false}) async {
    final NewItemListResponse? response = await offerServiceInterface.getOfferItems(
      offset: offset, limit: pageLimit, search: _searchQuery, moduleId: _selectedModuleId,
    );
    if (response == null) return;
    if (replace || _itemList == null) {
      _itemList = response;
    } else {
      _itemList!.items ??= <NewItem>[];
      if (response.items != null) _itemList!.items!.addAll(response.items!);
      _itemList!.totalSize = response.totalSize;
      _itemList!.limit = response.limit;
      _itemList!.offset = response.offset;
    }
    _itemOffset = offset;
  }

  Future<void> _fetchStores({required int offset, bool replace = false}) async {
    final StoreModel? response = await offerServiceInterface.getOfferStores(
      offset: offset, limit: pageLimit, search: _searchQuery, moduleId: _selectedModuleId,
    );
    if (response == null) return;
    if (replace || _storeList == null) {
      _storeList = response;
    } else {
      _storeList!.stores ??= <Store>[];
      if (response.stores != null) _storeList!.stores!.addAll(response.stores!);
      _storeList!.totalSize = response.totalSize;
      _storeList!.limit = response.limit;
      _storeList!.offset = response.offset;
    }
    _storeOffset = offset;
  }

  void setSelectedType(String type) {
    if (_selectedType == type) return;
    loadOffers(type: type, reload: true);
  }

  void setSearchQuery(String query) {
    final String trimmed = query.trim();
    if (_searchQuery == trimmed) return;
    loadOffers(search: trimmed, reload: true);
  }

  void setModuleFilter(int? moduleId) {
    if (_selectedModuleId == moduleId) return;
    loadOffers(moduleId: moduleId, clearModule: moduleId == null, reload: true);
  }

  bool get _shouldFetchItems => _selectedType == typeAll || _selectedType == typeItem;
  bool get _shouldFetchStores => _selectedType == typeAll || _selectedType == typeStore;

  int get totalResultCount {
    final int itemTotal = _itemList?.totalSize ?? 0;
    final int storeTotal = _storeList?.totalSize ?? 0;
    if (_selectedType == typeItem) return itemTotal;
    if (_selectedType == typeStore) return storeTotal;
    return itemTotal + storeTotal;
  }

  // Pagination is driven by PaginatedListView, which owns the offset/dedup/loader
  // state. These just fetch+append the requested page for the active vertical list.
  Future<void> paginateItems(int? offset) async {
    if (offset == null) return;
    await _fetchItems(offset: offset);
    update();
  }

  Future<void> paginateStores(int? offset) async {
    if (offset == null) return;
    await _fetchStores(offset: offset);
    update();
  }
}
