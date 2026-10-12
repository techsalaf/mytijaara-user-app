import 'package:sixam_mart/features/bogo_offer/domain/models/bogo_offer_model.dart';
import 'package:sixam_mart/features/bogo_offer/domain/services/bogo_offer_service_interface.dart';
import 'package:get/get.dart';

class BogoOfferDetailsController extends GetxController implements GetxService {
  final BogoOfferServiceInterface bogoOfferServiceInterface;
  BogoOfferDetailsController({required this.bogoOfferServiceInterface});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  BogoOfferDetailsResponseModel? _bogoOfferDetailsModel;
  BogoOfferDetailsResponseModel? get bogoOfferDetailsModel => _bogoOfferDetailsModel;

  bool _bundlePaginate = false;
  bool get bundlePaginate => _bundlePaginate;

  String? _idOrSlug;

  /// The module the offer belongs to. An offer opened from another module's tab is
  /// only resolvable under that module's id — asking under the active one 404s.
  int? _moduleId;
  int? get offerModuleId => _moduleId;

  Future<void> getBogoOfferDetails(String idOrSlug, {int? moduleId}) async {
    _idOrSlug = idOrSlug;
    _moduleId = moduleId;
    _isLoading = true;
    update();

    _bogoOfferDetailsModel = await bogoOfferServiceInterface.getBogoOfferDetails(idOrSlug: idOrSlug, moduleId: moduleId);

    _isLoading = false;
    update();
  }

  Future<void> loadMoreBundles() async {
    if(_bundlePaginate || _idOrSlug == null || _bogoOfferDetailsModel?.bundles == null) {
      return;
    }
    int limit = int.tryParse(_bogoOfferDetailsModel!.limit ?? '10') ?? 10;
    int totalPage = ((_bogoOfferDetailsModel!.totalSize ?? 0) / limit).ceil();
    int nextOffset = (_bogoOfferDetailsModel!.offset ?? 1) + 1;
    if(nextOffset > totalPage) {
      return;
    }

    _bundlePaginate = true;
    update();

    BogoOfferDetailsResponseModel? nextPage = await bogoOfferServiceInterface.getBogoOfferDetails(
      idOrSlug: _idOrSlug!, offset: nextOffset, limit: limit, moduleId: _moduleId,
    );
    if(nextPage != null) {
      _bogoOfferDetailsModel!.bundles!.addAll(nextPage.bundles ?? []);
      _bogoOfferDetailsModel!.offset = nextPage.offset;
      _bogoOfferDetailsModel!.totalSize = nextPage.totalSize;
    }
    _bundlePaginate = false;
    update();
  }
}
