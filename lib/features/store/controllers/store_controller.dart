import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/store/domain/models/cart_suggested_item_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_category_items_model.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/store/domain/models/recommended_product_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_banner_model.dart';
import 'package:sixam_mart/features/review/domain/models/review_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/home/screens/home_screen.dart';
import 'package:sixam_mart/features/store/domain/services/store_service_interface.dart';
import 'package:sixam_mart/helper/module_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';

class StoreController extends GetxController implements GetxService {
  final StoreServiceInterface storeServiceInterface;
  StoreController({required this.storeServiceInterface});

  StoreModel? _storeModel;
  StoreModel? get storeModel => _storeModel;

  List<Store>? _popularStoreList;
  List<Store>? get popularStoreList => _popularStoreList;

  List<Store>? _latestStoreList;
  List<Store>? get latestStoreList => _latestStoreList;

  List<Store>? _topOfferStoreList;
  List<Store>? get topOfferStoreList => _topOfferStoreList;

  List<Store>? _featuredStoreList;
  List<Store>? get featuredStoreList => _featuredStoreList;

  List<Store>? _visitAgainStoreList;
  List<Store>? get visitAgainStoreList => _visitAgainStoreList;

  Store? _store;
  Store? get store => _store;

  ItemModel? _storeItemModel;
  ItemModel? get storeItemModel => _storeItemModel;

  ItemModel? _storeSearchItemModel;
  ItemModel? get storeSearchItemModel => _storeSearchItemModel;

  int _categoryIndex = 0;
  int get categoryIndex => _categoryIndex;

  int _categoryScrollIndex = 0;
  int get categoryScrollIndex => _categoryScrollIndex;

  List<CategoryModel>? _categoryList;
  List<CategoryModel>? get categoryList => _categoryList;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _filterType = 'all';
  String get filterType => _filterType;

  String _storeType = 'all';
  String get storeType => _storeType;

  List<ReviewModel>? _storeReviewList;
  List<ReviewModel>? get storeReviewList => _storeReviewList;

  String _type = 'all';
  String get type => _type;

  String _searchType = 'all';
  String get searchType => _searchType;

  String _searchText = '';
  String get searchText => _searchText;

  bool _currentState = true;
  bool get currentState => _currentState;

  bool _showFavButton = true;
  bool get showFavButton => _showFavButton;

  List<XFile> _pickedPrescriptions = [];
  List<XFile> get pickedPrescriptions => _pickedPrescriptions;

  RecommendedItemModel? _recommendedItemModel;
  RecommendedItemModel? get recommendedItemModel => _recommendedItemModel;

  CartSuggestItemModel? _cartSuggestItemModel;
  CartSuggestItemModel? get cartSuggestItemModel => _cartSuggestItemModel;

  StoreCategoryItemsModel? _storeCategoryItemsModel;
  StoreCategoryItemsModel? get storeCategoryItemsModel => _storeCategoryItemsModel;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  List<StoreBannerModel>? _storeBanners;
  List<StoreBannerModel>? get storeBanners => _storeBanners;

  List<Store>? _recommendedStoreList;
  List<Store>? get recommendedStoreList => _recommendedStoreList;

  StoreModel? _quickDeliveryStoreList;
  StoreModel? get quickDeliveryStoreList => _quickDeliveryStoreList;

  static const int _quickDeliveryPageSize = 10;
  int _quickDeliveryPage = 1;
  int get quickDeliveryPage => _quickDeliveryPage;

  bool _isQuickDeliveryPaginating = false;
  bool get isQuickDeliveryPaginating => _isQuickDeliveryPaginating;

  // Dedicated "express delivery" list for AllStoresScreen — kept separate from the
  // shared _quickDeliveryStoreList so its server-side search never mutates the home
  // quick-delivery section.
  StoreModel? _expressDeliveryStoreList;
  StoreModel? get expressDeliveryStoreList => _expressDeliveryStoreList;

  bool _isExpressDeliveryPaginating = false;
  bool get isExpressDeliveryPaginating => _isExpressDeliveryPaginating;

  // The active express-delivery search term, reused across pagination requests.
  String _expressDeliverySearchName = '';
  String get expressDeliverySearchName => _expressDeliverySearchName;

  StoreModel? _nearbyStoreList;
  StoreModel? get nearbyStoreList => _nearbyStoreList;

  static const int _nearbyPageSize = 10;
  int _nearbyPage = 1;
  int get nearbyPage => _nearbyPage;

  bool _isNearbyPaginating = false;
  bool get isNearbyPaginating => _isNearbyPaginating;

  // Dedicated "top rated" list for AllStoresScreen — kept separate from the
  // shared _storeModel/_storeType so it never affects the Explore Stores section.
  StoreModel? _topRatedStoreList;
  StoreModel? get topRatedStoreList => _topRatedStoreList;

  static const int _topRatedPageSize = 12;

  bool _isTopRatedPaginating = false;
  bool get isTopRatedPaginating => _isTopRatedPaginating;

  String _topOfferFilter = '';
  String get topOfferFilter => _topOfferFilter;

  String _topOfferSort = '';
  String get topOfferSort => _topOfferSort;

  bool _isAvailableItems = false;
  bool get isAvailableItems => _isAvailableItems;

  bool _isDiscountedItems = false;
  bool get isDiscountedItems => _isDiscountedItems;

  List<String>? _filter = [];
  List<String>? get filter => _filter;

  int _rating = -1;
  int get rating => _rating;

  double _lowerValue = 0;
  double get lowerValue => _lowerValue;

  double _upperValue = 0;
  double get upperValue => _upperValue;

  double _lowerLimit = 0;
  double get getLowerLimit => _lowerLimit;

  double _upperLimit = 99999;
  double get getUpperLimit => _upperLimit;

  double getRestaurantDistance(LatLng storeLatLng){
    double distance = 0;
    if(AddressHelper.getUserAddressFromSharedPref() != null) {
      distance = Geolocator.distanceBetween(storeLatLng.latitude, storeLatLng.longitude,
          double.parse(AddressHelper.getUserAddressFromSharedPref()?.latitude ?? '0'),
          double.parse(AddressHelper.getUserAddressFromSharedPref()?.longitude ?? '0')) / 1000;
    }
    return distance;
  }

  String filteringUrl(String slug){
    return storeServiceInterface.filterRestaurantLinkUrl(slug, _store!);
  }

  void pickPrescriptionImage({required bool isRemove, required bool isCamera}) async {
    if(isRemove) {
      _pickedPrescriptions = [];
    }else {
      XFile? xFile = await ImagePicker().pickImage(source: isCamera ? ImageSource.camera : ImageSource.gallery, imageQuality: 50);
      if(xFile != null) {
        _pickedPrescriptions.add(xFile);
      }
      update();
    }
  }

  void removePrescriptionImage(int index) {
    _pickedPrescriptions.removeAt(index);
    update();
  }

  void changeFavVisibility(){
    _showFavButton = !_showFavButton;
    update();
  }

  void hideAnimation(){
    _currentState = false;
  }

  void setCategoryScrollIndex(int index) {
    _categoryScrollIndex = index;
    update();
  }

  void setCategoryIndexOnly(int index) {
    _categoryIndex = index;
    update();
  }

  void showButtonAnimation(){
    Future.delayed(const Duration(seconds: 3), () {
      _currentState = true;
      update();
    });
  }

  Future<void> getStoreCategoryItems(int storeId, {bool notify = true}) async {
    _storeCategoryItemsModel = null;
    if (notify) update();
    _storeCategoryItemsModel = await storeServiceInterface.getStoreCategoryItems(storeId);
    update();
  }

  Future<void> getRestaurantRecommendedItemList(int? storeId, bool reload) async {
    if(reload) {
      _storeModel = null;
      update();
    }
    RecommendedItemModel? recommendedItemModel = await storeServiceInterface.getStoreRecommendedItemList(storeId);
    if (recommendedItemModel != null) {
      _recommendedItemModel = recommendedItemModel;
    }
    update();
  }

  Future<void> getCartStoreSuggestedItemList(int? storeId) async {
    CartSuggestItemModel? cartSuggestItemModel = await storeServiceInterface.getCartStoreSuggestedItemList(storeId, Get.find<LocalizationController>().locale.languageCode,
        ModuleHelper.getModule(), ModuleHelper.getCacheModule()?.id, ModuleHelper.getModule()?.id);
    if (cartSuggestItemModel != null) {
      _cartSuggestItemModel = cartSuggestItemModel;
    }
    update();
  }

  Future<void> getStoreBannerList(int? storeId) async {
    List<StoreBannerModel>? storeBanners = await storeServiceInterface.getStoreBannerList(storeId);
    if (storeBanners != null) {
      _storeBanners = [];
      _storeBanners!.addAll(storeBanners);
    }
    update();
  }

  Future<void> getStoreList(int offset, bool reload, {DataSourceEnum source = DataSourceEnum.local}) async {
    if(reload) {
      _storeModel = null;
      update();
    }
    StoreModel? storeModel;
    if(source == DataSourceEnum.local && offset == 1) {
      storeModel = await storeServiceInterface.getStoreList(offset, _filterType, _storeType, source: DataSourceEnum.local);
      _prepareStoreModel(storeModel, offset);
      getStoreList(offset, false, source: DataSourceEnum.client);
    } else {
      storeModel = await storeServiceInterface.getStoreList(offset, _filterType, _storeType, source: DataSourceEnum.client);
      _prepareStoreModel(storeModel, offset);
    }
  }

  void _prepareStoreModel(StoreModel? storeModel, int offset) {
    if (storeModel != null) {
      if (offset == 1) {
        _storeModel = storeModel;
      }else {
        _storeModel!.totalSize = storeModel.totalSize;
        _storeModel!.offset = storeModel.offset;
        _storeModel!.stores!.addAll(storeModel.stores!);
      }
      update();
    }
  }

  void setFilterType(String type) {
    _filterType = type;
    getStoreList(1, true);
  }

  void setStoreType(String type) {
    _storeType = type;
    getStoreList(1, true);
  }

  void resetStoreData() {
    _filterType = 'all';
    _storeType = 'all';
  }

  Future<void> getPopularStoreList(bool reload, String type, bool notify, {DataSourceEnum dataSource = DataSourceEnum.local, bool fromRecall = false}) async {
    _type = type;
    if(reload) {
      _popularStoreList = null;
    }
    if(notify) {
      update();
    }
    if(_popularStoreList == null || reload || fromRecall) {
      List<Store>? popularStoreList;
      if(dataSource == DataSourceEnum.local) {
        popularStoreList = await storeServiceInterface.getPopularStoreList(type, source: DataSourceEnum.local);
        if (popularStoreList != null) {
          _popularStoreList = [];
          _popularStoreList!.addAll(popularStoreList);
        }
        update();
        getPopularStoreList(false, type, notify, dataSource: DataSourceEnum.client, fromRecall: true);
      } else {
        popularStoreList = await storeServiceInterface.getPopularStoreList(type, source: DataSourceEnum.client);
        if (popularStoreList != null) {
          _popularStoreList = [];
          _popularStoreList!.addAll(popularStoreList);
        }
        update();
      }

    }
  }

  Future<void> getLatestStoreList(bool reload, String type, bool notify, {DataSourceEnum dataSource = DataSourceEnum.local, bool fromRecall = false}) async {
    _type = type;
    if(reload){
      _latestStoreList = null;
    }
    if(notify) {
      update();
    }
    if(_latestStoreList == null || reload || fromRecall) {
      List<Store>? latestStoreList;
      if(dataSource == DataSourceEnum.local) {
        latestStoreList = await storeServiceInterface.getLatestStoreList(type, source: DataSourceEnum.local);
        if (latestStoreList != null) {
          _latestStoreList = [];
          _latestStoreList!.addAll(latestStoreList);
        }
        update();
        getLatestStoreList(false, type, notify, fromRecall: true, dataSource: DataSourceEnum.client);
      } else {
        latestStoreList = await storeServiceInterface.getLatestStoreList(type, source: DataSourceEnum.client);
        if (latestStoreList != null) {
          _latestStoreList = [];
          _latestStoreList!.addAll(latestStoreList);
        }
        update();
      }
    }
  }

  Future<void> getTopOfferStoreList(bool reload, bool notify, {DataSourceEnum dataSource = DataSourceEnum.local, bool fromRecall = false}) async {
    if(reload){
      _topOfferStoreList = null;
    }
    if(notify) {
      update();
    }
    if(_topOfferStoreList == null || reload || fromRecall) {
      List<Store>? latestStoreList;
      if(dataSource == DataSourceEnum.local) {
        latestStoreList = await storeServiceInterface.getTopOfferStoreList(source: DataSourceEnum.local, filterBy: _topOfferFilter, sortBy: _topOfferSort);
        if (latestStoreList != null) {
          _topOfferStoreList = [];
          _topOfferStoreList!.addAll(latestStoreList);
        }
        update();
        getTopOfferStoreList(false, notify, dataSource: DataSourceEnum.client, fromRecall: true);
      } else {
        latestStoreList = await storeServiceInterface.getTopOfferStoreList(source: DataSourceEnum.client, filterBy: _topOfferFilter, sortBy: _topOfferSort);
        if (latestStoreList != null) {
          _topOfferStoreList = [];
          _topOfferStoreList!.addAll(latestStoreList);
        }
        update();
      }
    }
  }

  void setTopOfferFilter(String type) {
    _topOfferFilter = type;
   getTopOfferStoreList(true, false);
  }

  void setTopOfferSort(String sort) {
    _topOfferSort = sort;
    getTopOfferStoreList(true, false);
  }

  Future<void> getFeaturedStoreList({bool fromHome = false, DataSourceEnum dataSource = DataSourceEnum.local, bool notify = true}) async {
    List<Store>? stores;
    if(dataSource == DataSourceEnum.local) {
      if(fromHome) {
        // The featured list is shared with module screens, which load it scoped to
        // the active module. When re-entering Home, reset it first so stale module
        // data isn't shown while the global (home) featured list reloads.
        _featuredStoreList = null;
        if(notify) update();
      }
      stores = await storeServiceInterface.getFeaturedStoreList(source: dataSource, fromHome: fromHome);
      _prepareFeaturedStore(stores);
      getFeaturedStoreList(fromHome: fromHome, dataSource: DataSourceEnum.client);
    } else {
      stores = await storeServiceInterface.getFeaturedStoreList(source: dataSource, fromHome: fromHome);
      _prepareFeaturedStore(stores);
    }

  }

  void _prepareFeaturedStore(List<Store>? stores) {
    if (stores != null) {
      _featuredStoreList = [];
      List<Modules> moduleList = [];
      moduleList.addAll(storeServiceInterface.moduleList());
      for (Store store in stores) {
        for (var module in moduleList) {
          if(module.id == store.moduleId){
            if(module.pivot!.zoneId == store.zoneId){
              _featuredStoreList!.add(store);
            }
          }
        }
      }
    }
    update();
  }

  Future<void> getVisitAgainStoreList({bool fromModule = false, DataSourceEnum dataSource = DataSourceEnum.local, bool fromRecall = false}) async {
    if(fromModule && !fromRecall) {
      _visitAgainStoreList = null;
    }
    List<Store>? stores;
    if(dataSource == DataSourceEnum.local) {
      stores = await storeServiceInterface.getVisitAgainStoreList(source: DataSourceEnum.local);
      _prepareVisitAgainStore(stores);
      getVisitAgainStoreList(dataSource: DataSourceEnum.client, fromRecall: true);
    } else {
      stores = await storeServiceInterface.getVisitAgainStoreList(source: DataSourceEnum.client);
      _prepareVisitAgainStore(stores);
    }

  }

  void _prepareVisitAgainStore(List<Store>? stores) {
    if (stores != null) {
      _visitAgainStoreList = [];
      List<Modules> moduleList = [];
      moduleList.addAll(storeServiceInterface.moduleList());
      for (var store in stores) {
        for (var module in moduleList) {
          if(module.id == store.moduleId){
            if(module.pivot!.zoneId == store.zoneId){
              _visitAgainStoreList!.add(store);
            }
          }
        }
      }
    }
    update();
  }

  void setCategoryList() {
    if(Get.find<CategoryController>().categoryList != null && _store != null) {
      _categoryList = [];
      _categoryList!.add(CategoryModel(id: 0, name: 'all'.tr));
      for (var category in Get.find<CategoryController>().categoryList!) {
        if(_store!.categoryIds!.contains(category.id)) {
          _categoryList!.add(category);
        }
      }
    }
  }

  Future<Store?> getStoreDetails(Store store, bool fromModule, {bool fromCart = false, String slug = ''}) async {
    _categoryIndex = 0;
    if(store.name != null) {
      _store = store;
    }else {
      _isLoading = true;
      _store = null;
      Store? storeDetails = await storeServiceInterface.getStoreDetails(store.id.toString(), fromCart, slug, Get.find<LocalizationController>().locale.languageCode,
          ModuleHelper.getModule(), ModuleHelper.getCacheModule()?.id, ModuleHelper.getModule()?.id);
      if (storeDetails != null) {
        _store = storeDetails;
        Get.find<CheckoutController>().initializeTimeSlot(_store!);
        if(!fromCart && slug.isEmpty){
          Get.find<CheckoutController>().getDistanceInKM(
            LatLng(
              double.parse(AddressHelper.getUserAddressFromSharedPref()?.latitude??'0'),
              double.parse(AddressHelper.getUserAddressFromSharedPref()?.longitude??'0'),
            ),
            LatLng(double.parse(_store!.latitude!), double.parse(_store!.longitude!)),
          );
        }
        if(slug.isNotEmpty){
          await Get.find<LocationController>().setStoreAddressToUserAddress(LatLng(double.parse(_store!.latitude!), double.parse(_store!.longitude!)));
        }
        if(fromModule) {
          HomeScreen.loadData(true);
        }/*else {
          Get.find<CheckoutController>().clearPrevData();
        }*/
      }
      Get.find<CheckoutController>().setOrderType(
        _store != null ? _store!.delivery! ? 'delivery' : 'take_away' : 'delivery', notify: false,
      );
      _isLoading = false;
      update();
    }
    return _store;
  }

  Future<void> getRecommendedStoreList({DataSourceEnum dataSource = DataSourceEnum.local, bool fromRecall = false}) async {
    if(!fromRecall) {
      _recommendedStoreList = null;
    }
    List<Store>? recommendedStoreList;
    if(dataSource == DataSourceEnum.local) {
      recommendedStoreList = await storeServiceInterface.getRecommendedStoreList(source: DataSourceEnum.local);
      _prepareRecommendedStores(recommendedStoreList);
      getRecommendedStoreList(dataSource: DataSourceEnum.client, fromRecall: true);
    } else {
      recommendedStoreList = await storeServiceInterface.getRecommendedStoreList(source: DataSourceEnum.client);
      _prepareRecommendedStores(recommendedStoreList);
    }
  }

  void _prepareRecommendedStores(List<Store>? recommendedStoreList) {
    if (recommendedStoreList != null) {
      _recommendedStoreList = [];
      _recommendedStoreList!.addAll(recommendedStoreList);
    }
    update();
  }

  Future<void> getQuickDeliveryStoreList({bool reload = false, int? moduleId}) async {
    if(reload) {
      _quickDeliveryStoreList = null;
      _quickDeliveryPage = 1;
    }
    final StoreModel? response = await storeServiceInterface.getQuickDeliveryStores(
      offset: 1, limit: _quickDeliveryPageSize, moduleId: moduleId,
    );
    if(response != null) {
      _quickDeliveryStoreList = response;
      _quickDeliveryPage = 1;
      update();
    }
  }

  Future<void> loadMoreQuickDeliveryStores({int? moduleId}) async {
    final StoreModel? current = _quickDeliveryStoreList;
    if(current == null || _isQuickDeliveryPaginating) return;

    final int loaded = current.stores?.length ?? 0;
    final int total = current.totalSize ?? 0;
    if(loaded >= total) return;

    _isQuickDeliveryPaginating = true;
    update();

    final int nextOffset = (loaded ~/ _quickDeliveryPageSize) + 1;
    final StoreModel? response = await storeServiceInterface.getQuickDeliveryStores(
      offset: nextOffset, limit: _quickDeliveryPageSize, moduleId: moduleId,
    );
    if(response?.stores != null) {
      current.stores!.addAll(response!.stores!);
      current.offset = response.offset;
      current.totalSize = response.totalSize;
      _quickDeliveryPage = nextOffset;
    }
    _isQuickDeliveryPaginating = false;
    update();
  }

  Future<void> getExpressDeliveryStoreList({bool reload = false, int? moduleId, String? name}) async {
    if(name != null) _expressDeliverySearchName = name;
    if(reload) {
      _expressDeliveryStoreList = null;
      update();
    }
    final StoreModel? response = await storeServiceInterface.getQuickDeliveryStores(
      offset: 1, limit: _quickDeliveryPageSize, moduleId: moduleId, name: _expressDeliverySearchName,
    );
    if(response != null) {
      _expressDeliveryStoreList = response;
      update();
    }
  }

  Future<void> loadMoreExpressDeliveryStores({int? moduleId}) async {
    final StoreModel? current = _expressDeliveryStoreList;
    if(current == null || _isExpressDeliveryPaginating) return;

    final int loaded = current.stores?.length ?? 0;
    final int total = current.totalSize ?? 0;
    if(loaded >= total) return;

    _isExpressDeliveryPaginating = true;
    update();

    final int nextOffset = (loaded ~/ _quickDeliveryPageSize) + 1;
    final StoreModel? response = await storeServiceInterface.getQuickDeliveryStores(
      offset: nextOffset, limit: _quickDeliveryPageSize, moduleId: moduleId, name: _expressDeliverySearchName,
    );
    if(response?.stores != null) {
      current.stores!.addAll(response!.stores!);
      current.offset = response.offset;
      current.totalSize = response.totalSize;
    }
    _isExpressDeliveryPaginating = false;
    update();
  }

  void clearExpressDeliveryStoreList() {
    _expressDeliveryStoreList = null;
    _expressDeliverySearchName = '';
  }

  // The active "nearby" search term, reused across pagination requests.
  String _nearbySearchName = '';
  String get nearbySearchName => _nearbySearchName;

  Future<void> getNearbyStoreList({bool reload = false, int? moduleId, String? name}) async {
    if(name != null) _nearbySearchName = name;
    if(reload) {
      _nearbyStoreList = null;
      _nearbyPage = 1;
      update();
    }
    final StoreModel? response = await storeServiceInterface.getNearbyStores(
      offset: 1, limit: _nearbyPageSize, moduleId: moduleId, name: _nearbySearchName,
    );
    if(response != null) {
      _nearbyStoreList = response;
      _nearbyPage = 1;
      update();
    }
  }

  Future<void> loadMoreNearbyStores({int? moduleId}) async {
    final StoreModel? current = _nearbyStoreList;
    if(current == null || _isNearbyPaginating) return;

    final int loaded = current.stores?.length ?? 0;
    final int total = current.totalSize ?? 0;
    if(loaded >= total) return;

    _isNearbyPaginating = true;
    update();

    final int nextOffset = (loaded ~/ _nearbyPageSize) + 1;
    final StoreModel? response = await storeServiceInterface.getNearbyStores(
      offset: nextOffset, limit: _nearbyPageSize, moduleId: moduleId, name: _nearbySearchName,
    );
    if(response?.stores != null) {
      current.stores!.addAll(response!.stores!);
      current.offset = response.offset;
      current.totalSize = response.totalSize;
      _nearbyPage = nextOffset;
    }
    _isNearbyPaginating = false;
    update();
  }

  // The active top-rated search term, reused across pagination requests.
  String _topRatedSearchName = '';
  String get topRatedSearchName => _topRatedSearchName;

  Future<void> getTopRatedStoreList({bool reload = false, DataSourceEnum source = DataSourceEnum.local, String? name}) async {
    if(name != null) _topRatedSearchName = name;
    if(reload) {
      _topRatedStoreList = null;
      update();
    }
    // Search results are dynamic — always hit the server and skip the local-first cache.
    final bool searching = _topRatedSearchName.isNotEmpty;
    final DataSourceEnum effectiveSource = searching ? DataSourceEnum.client : source;
    // Fetch with explicit types so the shared _storeType/_storeModel stay untouched.
    final StoreModel? response = await storeServiceInterface.getStoreList(1, 'all', 'top_rated', source: effectiveSource, name: _topRatedSearchName);
    if(response != null) {
      _topRatedStoreList = response;
      update();
    }
    if(!searching && source == DataSourceEnum.local) {
      getTopRatedStoreList(reload: false, source: DataSourceEnum.client);
    }
  }

  Future<void> loadMoreTopRatedStores() async {
    final StoreModel? current = _topRatedStoreList;
    if(current == null || _isTopRatedPaginating) return;

    final int loaded = current.stores?.length ?? 0;
    final int total = current.totalSize ?? 0;
    if(loaded >= total) return;

    _isTopRatedPaginating = true;
    update();

    final int nextOffset = (loaded ~/ _topRatedPageSize) + 1;
    final StoreModel? response = await storeServiceInterface.getStoreList(nextOffset, 'all', 'top_rated', source: DataSourceEnum.client, name: _topRatedSearchName);
    if(response?.stores != null) {
      current.stores!.addAll(response!.stores!);
      current.offset = response.offset;
      current.totalSize = response.totalSize;
    }
    _isTopRatedPaginating = false;
    update();
  }

  void clearTopRatedStoreList() {
    _topRatedStoreList = null;
    _topRatedSearchName = '';
  }

  Future<void> getStoreItemList(int? storeID, int offset, String type, bool notify) async {
    if(offset == 1 || _storeItemModel == null) {
      _type = type;
      _storeItemModel = null;
      if(notify) {
        update();
      }
    }
    ItemModel? storeItemModel = await storeServiceInterface.getStoreItemList(
      storeID: storeID, offset: offset,
      categoryID: (_store != null && _store!.categoryIds!.isNotEmpty && _categoryIndex != 0) ? _categoryList![_categoryIndex].id : 0,
      type: type,
      filter: _filter,
      rating: _rating == -1 ? null : _rating,
      lowerValue: _lowerValue == 0 ? null : _lowerValue,
      upperValue: _upperValue == 0 ? null : _upperValue,
    );
    if (storeItemModel != null) {
      if (offset == 1) {
        _storeItemModel = storeItemModel;
      }else {
        _storeItemModel!.items!.addAll(storeItemModel.items!);
        _storeItemModel!.totalSize = storeItemModel.totalSize;
        _storeItemModel!.offset = storeItemModel.offset;
        _storeItemModel!.minPrice = storeItemModel.minPrice;
        _storeItemModel!.maxPrice = storeItemModel.maxPrice;
      }
      setLowerAndUpperLimit(lower: _storeItemModel?.minPrice?.toDouble() ?? 0, upper: _storeItemModel?.maxPrice?.toDouble() ?? 99999);
    }
    update();
  }

  Future<void> getStoreSearchItemList(String searchText, String? storeID, int offset, String type) async {
    if(searchText.isEmpty) {
      showCustomSnackBar('write_item_name'.tr);
    }else {
      _isSearching = true;
      _searchText = searchText;
      _type = type;
      if(offset == 1 || _storeSearchItemModel == null) {
        _searchType = type;
        _storeSearchItemModel = null;
        update();
      }
      ItemModel? storeSearchItemModel = await storeServiceInterface.getStoreSearchItemList(searchText, storeID, offset, type,
          (_store != null && _store!.categoryIds!.isNotEmpty && _categoryIndex != 0) ? _categoryList![_categoryIndex].id : 0);
      if (storeSearchItemModel != null) {
        if (offset == 1) {
          _storeSearchItemModel = storeSearchItemModel;
        }else {
          _storeSearchItemModel!.items!.addAll(storeSearchItemModel.items!);
          _storeSearchItemModel!.totalSize = storeSearchItemModel.totalSize;
          _storeSearchItemModel!.offset = storeSearchItemModel.offset;
        }
      }
      update();
    }
  }

  void changeSearchStatus({bool isUpdate = true}) {
    _isSearching = !_isSearching;
    if(isUpdate) {
      update();
    }
  }

  void initSearchData() {
    _storeSearchItemModel = ItemModel(items: []);
    _searchText = '';
  }

  void setCategoryIndex(int index, {bool itemSearching = false}) {
    _categoryIndex = index;
    if(itemSearching){
      _storeSearchItemModel = null;
      getStoreSearchItemList(_searchText, _store!.id.toString(), 1, type);
    } else {
      _storeItemModel = null;
      getStoreItemList(_store!.id, 1, Get.find<StoreController>().type, false);
    }
    update();
  }

  bool isStoreClosed(bool today, bool active, List<Schedules>? schedules) {
    if(!active) {
      return true;
    }
    DateTime date = DateTime.now();
    if(!today) {
      date = date.add(const Duration(days: 1));
    }
    int weekday = date.weekday;
    if(weekday == 7) {
      weekday = 0;
    }
    for(int index=0; index<schedules!.length; index++) {
      if(weekday == schedules[index].day) {
        return false;
      }
    }
    return true;
  }

  bool isStoreOpenNow(bool active, List<Schedules>? schedules) {
    if(isStoreClosed(true, active, schedules)) {
      return false;
    }
    int weekday = DateTime.now().weekday;
    if(weekday == 7) {
      weekday = 0;
    }
    for(int index=0; index<schedules!.length; index++) {
      if(weekday == schedules[index].day
          && DateConverter.isAvailable(schedules[index].openingTime, schedules[index].closingTime)) {
        return true;
      }
    }
    return false;
  }

  bool isOpenNow(Store store) => store.open == 1 && store.active!;

  double? getDiscount(Store store) => store.discount != null ? store.discount!.discount : 0;

  String? getDiscountType(Store store) => store.discount != null ? store.discount!.discountType : 'percent';

  void shareStore() {
    if(ResponsiveHelper.isDesktop(Get.context)){
      String shareUrl = '${AppConstants.webHostedUrl}${filteringUrl(store!.slug ?? '')}';

      Clipboard.setData(ClipboardData(text: shareUrl));
      showCustomSnackBar('store_url_copied'.tr, isError: false);
    } else {
      String shareUrl = '${AppConstants.webHostedUrl}${filteringUrl(store!.slug ?? '')}';
      SharePlus.instance.share(ShareParams(text: shareUrl));
    }
  }

  void setRating(int rate) {
    _rating = rate;
    update();
  }


  void toggleAvailableItems() {
    _isAvailableItems = !_isAvailableItems;
    if(_isAvailableItems) {
      _filter!.add("available_now");
    } else {
      _filter!.remove("available_now");
    }
    update();
  }

  void toggleDiscountedItems() {
    _isDiscountedItems = !_isDiscountedItems;
    if(_isDiscountedItems) {
      _filter!.add("discounted");
    } else {
      _filter!.remove("discounted");
    }
    update();
  }

  void setLowerAndUpperValue({double? lower, double? upper, bool reload = false}) {
    if(lower != null){
      _lowerValue = lower.clamp(getLowerLimit, getUpperLimit);
    }
    if(upper != null){
      _upperValue = upper.clamp(getLowerLimit, getUpperLimit);
    }
    if(reload){
      update();
    }
  }

  void setLowerAndUpperLimit({double? lower, double? upper, bool reload = true}) {
    if(lower != null){
      _lowerLimit = lower;
      _lowerValue = _lowerValue.clamp(getLowerLimit, getUpperLimit);
    }
    if(upper != null){
      _upperLimit = upper;
      _upperValue = upper;
      _upperValue = _upperValue.clamp(getLowerLimit, getUpperLimit);
    }

    if(reload) update();
  }

  void resetFilter({bool isUpdate = true}) {
    _isAvailableItems = false;
    _isDiscountedItems = false;
    _rating = -1;
    _lowerValue = 0;
    _upperValue = 0;
    _filter = [];
    if(isUpdate) {
      update();
    }
  }

}