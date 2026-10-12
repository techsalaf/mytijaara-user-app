import 'package:get/get.dart';
import 'package:sixam_mart/features/bundle/domain/models/bundle_model.dart';
import 'package:sixam_mart/features/bundle/domain/services/bundle_service_interface.dart';

class BundleController extends GetxController implements GetxService {
  final BundleServiceInterface bundleServiceInterface;
  BundleController({required this.bundleServiceInterface});

  /// ------------------------------------------------------------- home strip

  List<Bundle>? _homeBundles;
  List<Bundle>? get homeBundles => _homeBundles;

  bool _homeLoaded = false;

  /// `GET /bundle/home` — a strip, so it takes `limit` only and returns no
  /// pagination.
  ///
  /// The strip sits on the module home and this controller is a singleton, so
  /// [reload] guards against re-fetching on every visit.
  Future<void> getBundleHome({int limit = 10, bool reload = false, bool notify = true}) async {
    if(_homeLoaded && !reload) {
      return;
    }
    if(reload) {
      _homeBundles = null;
      if(notify) {
        update();
      }
    }

    final BundleListModel? model = await bundleServiceInterface.getBundleHome(limit: limit);
    _homeBundles = model?.bundles ?? <Bundle>[];
    _homeLoaded = true;
    update();
  }

  /// Called on a module switch: bundles are module-scoped, so the previous
  /// module's strip and store caches must not stay on screen while the new
  /// module loads. Resetting [_homeLoaded] is what makes the next module
  /// screen's [getBundleHome] actually re-fetch instead of returning early.
  ///
  /// Deliberately no update() — the same rule the other module-scoped clears
  /// follow (clearBogoHomeData, clearBanner, clearItemLists). A switch tears
  /// the old module screen down, and rebuilding a GetBuilder inside that
  /// deactivating tree trips LazySliver's SliverLayoutBuilder with an
  /// inactive parent. The new module screen reads the nulled state when it
  /// builds.
  void clearBundleHomeData() {
    _homeBundles = null;
    _homeLoaded = false;
    _storeBundles.clear();
  }

  /// ------------------------------------------------------------ paged list

  List<Bundle>? _bundleList;
  List<Bundle>? get bundleList => _bundleList;

  int _offset = 1;
  int get offset => _offset;

  int? _lastPage;
  bool _isListLoading = false;
  bool get isListLoading => _isListLoading;

  /// True once the list has been read to its end, so the screen stops asking for
  /// pages the server does not have.
  bool get hasReachedEnd => _lastPage != null && _offset >= _lastPage!;

  /// `offset` is a 1-based page number despite its name.
  Future<void> getBundleList({int offset = 1, String? search, bool notify = true}) async {
    if(offset == 1) {
      _offset = 1;
      _bundleList = null;
      _lastPage = null;
      if(notify) {
        update();
      }
    } else {
      _isListLoading = true;
      update();
    }

    final BundleListModel? model = await bundleServiceInterface.getBundleList(offset: offset, search: search);
    if(model != null) {
      _offset = offset;
      _lastPage = model.lastPage;
      _bundleList = <Bundle>[...?(offset == 1 ? null : _bundleList), ...model.bundles];
    }
    _isListLoading = false;
    update();
  }

  /// ---------------------------------------------------------- store bundles

  final Map<int, List<Bundle>> _storeBundles = <int, List<Bundle>>{};

  /// The bundles of one store, or null while they are still being fetched — the
  /// store screen hides its section entirely rather than showing an empty one.
  List<Bundle>? storeBundlesOf(int storeId) => _storeBundles[storeId];

  Future<void> getStoreBundles(int storeId, {bool reload = false, bool notify = true}) async {
    if(_storeBundles.containsKey(storeId) && !reload) {
      return;
    }
    if(reload) {
      _storeBundles.remove(storeId);
      if(notify) {
        update();
      }
    }

    final BundleListModel? model = await bundleServiceInterface.getStoreBundles(storeId: storeId);
    _storeBundles[storeId] = model?.bundles ?? <Bundle>[];
    update();
  }

  /// --------------------------------------------------------------- details

  Bundle? _bundleDetails;
  Bundle? get bundleDetails => _bundleDetails;

  /// How many copies the details sheet is about to add. Reset on every open so a
  /// quantity chosen for one bundle never carries into the next.
  int _detailsQuantity = 1;
  int get detailsQuantity => _detailsQuantity;

  /// `GET /bundle/{id}` is the only endpoint that fills `items`, so the details
  /// sheet always fetches even when opened from a card that already has the rest.
  ///
  /// A bundle that is switched off, outside its window, or in a module without
  /// the feature answers **404** rather than an unavailable payload — the browse
  /// scope excludes it before the availability rule runs. So a null here means
  /// "gone", not "temporarily unavailable".
  Future<void> getBundleDetails(int bundleId, {int quantity = 1, bool notify = true}) async {
    _bundleDetails = null;
    _detailsQuantity = quantity < 1 ? 1 : quantity;
    if(notify) {
      update();
    }

    _bundleDetails = await bundleServiceInterface.getBundleDetails(bundleId);
    update();
  }

  void setDetailsQuantity(int quantity) {
    if(quantity < 1) {
      return;
    }
    _detailsQuantity = quantity;
    update();
  }
}
