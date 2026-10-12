import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/bogo_offer/domain/models/bogo_offer_model.dart';
import 'package:sixam_mart/features/bogo_offer/domain/services/bogo_offer_service_interface.dart';
import 'package:get/get.dart';

class BogoOfferController extends GetxController implements GetxService {
  final BogoOfferServiceInterface bogoOfferServiceInterface;
  BogoOfferController({required this.bogoOfferServiceInterface});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  BogoHomeModel? _bogoHomeModel;
  BogoHomeModel? get bogoHomeModel => _bogoHomeModel;

  bool get showHomeCard => _bogoHomeModel?.isLive ?? false;

  /// A null result means the request failed or was dropped as stale after a module
  /// switch — not that the offer ended. Overwriting on null wiped a card that was
  /// already on screen. An offer that has genuinely finished comes back as a 200 with
  /// `is_live: false`, which is a real model and still hides the card.
  Future<void> getBogoHomeData({int limit = 6, String? orderType}) async {
    final BogoHomeModel? result = await bogoOfferServiceInterface.getBogoHomeData(limit: limit, orderType: orderType);
    if(result == null) {
      return;
    }
    _bogoHomeModel = result;
    update();
  }

  /// Called on a module switch: the offers are module-scoped, so the previous
  /// module's card must not stay on screen while the new one loads.
  ///
  /// Deliberately no update() — the same rule the other module-scoped clears follow
  /// (clearBanner, clearItemLists, clearModuleStoreLists). A switch tears the old
  /// module screen down, and rebuilding a GetBuilder inside that deactivating tree
  /// trips LazySliver's SliverLayoutBuilder with an inactive parent. The new module
  /// screen reads the nulled state when it builds.
  void clearBogoHomeData() {
    _bogoHomeModel = null;
  }

  // --- Module tabs on the BOGO screen -------------------------------------------
  // The screen lists every module running a live offer, not just the active one, so
  // each module is asked separately and only the live ones become tabs.

  /// null while the modules are still being checked, [] when none is running one.
  List<ModuleModel>? _bogoModules;
  List<ModuleModel>? get bogoModules => _bogoModules;

  int _selectedBogoModuleIndex = 0;
  int get selectedBogoModuleIndex => _selectedBogoModuleIndex;

  ModuleModel? get selectedBogoModule => (_bogoModules != null && _selectedBogoModuleIndex < _bogoModules!.length)
      ? _bogoModules![_selectedBogoModuleIndex] : null;

  /// The module the offer list currently belongs to, so pagination keeps asking the
  /// same one after a tab change.
  int? _offerListModuleId;

  /// [modules] comes from SplashController — passed in rather than looked up so the
  /// controller keeps to its own feature.
  /// [initialModuleId] preselects that module's tab — the module the screen was
  /// opened from. It is ignored when that module turns out to have no live offer.
  Future<void> getLiveBogoModules(List<ModuleModel>? modules, {bool notify = true, int? initialModuleId}) async {
    _bogoModules = null;
    _isLoading = true;
    if(notify) update();

    final List<ModuleModel> allModules = modules ?? [];
    final List<BogoHomeModel?> results = await Future.wait(
      allModules.map((module) => bogoOfferServiceInterface.getBogoHomeData(moduleId: module.id)),
    );

    // Keep the module list's own order so the tabs read the same as the module switcher.
    final List<ModuleModel> liveModules = [];
    for(int i = 0; i < allModules.length; i++) {
      if(results[i]?.isLive == true) {
        liveModules.add(allModules[i]);
      }
    }
    _bogoModules = liveModules;
    final int initialIndex = initialModuleId != null
        ? liveModules.indexWhere((module) => module.id == initialModuleId) : -1;
    _selectedBogoModuleIndex = initialIndex >= 0 ? initialIndex : 0;

    if(liveModules.isEmpty) {
      _bogoOfferListModel = null;
      _isLoading = false;
      update();
      return;
    }
    await getBogoOfferList(moduleId: liveModules[_selectedBogoModuleIndex].id);
  }

  Future<void> setSelectedBogoModule(int index) async {
    if(_bogoModules == null || index == _selectedBogoModuleIndex || index >= _bogoModules!.length) {
      return;
    }
    _selectedBogoModuleIndex = index;
    update();
    await getBogoOfferList(moduleId: _bogoModules![index].id);
  }

  BogoOfferListModel? _bogoOfferListModel;
  List<BogoOfferCardModel>? get bogoOfferList => _bogoOfferListModel?.offers;

  bool _bogoOfferPaginate = false;
  bool get bogoOfferPaginate => _bogoOfferPaginate;

  // Bumped on every fresh first-page load so a page that was already in flight, or a
  // pagination call, can tell that the list it belongs to has been replaced.
  int _offerListRequestId = 0;

  /// [showLoader] off keeps the offers on screen while they reload, which is what a pull
  /// to refresh wants - the refresh indicator is already saying the work is happening.
  Future<void> getBogoOfferList({bool showLoader = true, int? moduleId}) async {
    final int requestId = ++_offerListRequestId;
    _offerListModuleId = moduleId ?? _offerListModuleId;
    if(showLoader) {
      _isLoading = true;
      update();
    }

    BogoOfferListModel? offerList = await bogoOfferServiceInterface.getBogoOfferList(moduleId: _offerListModuleId);
    if(requestId != _offerListRequestId) {
      return;
    }

    _bogoOfferListModel = offerList;
    _bogoOfferPaginate = false;
    _isLoading = false;
    update();
  }

  Future<void> loadMoreBogoOffers() async {
    if(_bogoOfferPaginate || _bogoOfferListModel?.offers == null) {
      return;
    }
    int limit = int.tryParse(_bogoOfferListModel!.limit ?? '10') ?? 10;
    int totalPage = ((_bogoOfferListModel!.totalSize ?? 0) / limit).ceil();
    int nextOffset = (_bogoOfferListModel!.offset ?? 1) + 1;
    if(nextOffset > totalPage) {
      return;
    }

    final int requestId = _offerListRequestId;
    _bogoOfferPaginate = true;
    update();

    BogoOfferListModel? nextPage = await bogoOfferServiceInterface.getBogoOfferList(
      offset: nextOffset, limit: limit, moduleId: _offerListModuleId,
    );
    // The list was refreshed underneath this page, appending it would duplicate offers.
    if(requestId != _offerListRequestId) {
      return;
    }
    if(nextPage != null) {
      _bogoOfferListModel!.offers!.addAll(nextPage.offers ?? []);
      _bogoOfferListModel!.offset = nextPage.offset;
      _bogoOfferListModel!.totalSize = nextPage.totalSize;
    }
    _bogoOfferPaginate = false;
    update();
  }

  final Map<String, Future<BogoOfferDetailsResponseModel?>> _offerDetailsCache = {};

  /// Caches by offer so several cart tiles sharing one offer trigger a single request.
  Future<BogoOfferDetailsResponseModel?> getCachedOfferDetails(String idOrSlug, {int limit = 100}) {
    return _offerDetailsCache.putIfAbsent(
      idOrSlug, () => bogoOfferServiceInterface.getBogoOfferDetails(idOrSlug: idOrSlug, limit: limit),
    );
  }
}
