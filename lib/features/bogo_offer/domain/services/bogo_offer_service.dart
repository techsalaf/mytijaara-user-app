import 'package:sixam_mart/features/bogo_offer/domain/models/bogo_offer_model.dart';
import 'package:sixam_mart/features/bogo_offer/domain/repositories/bogo_offer_repository_interface.dart';
import 'package:sixam_mart/features/bogo_offer/domain/services/bogo_offer_service_interface.dart';

class BogoOfferService implements BogoOfferServiceInterface {
  final BogoOfferRepositoryInterface bogoOfferRepositoryInterface;
  BogoOfferService({required this.bogoOfferRepositoryInterface});

  @override
  Future<BogoHomeModel?> getBogoHomeData({int limit = 6, String? orderType, int? moduleId}) async {
    return await bogoOfferRepositoryInterface.getBogoHomeData(limit: limit, orderType: orderType, moduleId: moduleId);
  }

  @override
  Future<BogoOfferListModel?> getBogoOfferList({int offset = 1, int limit = 10, int? moduleId}) async {
    return await bogoOfferRepositoryInterface.getBogoOfferList(offset: offset, limit: limit, moduleId: moduleId);
  }

  @override
  Future<BogoOfferDetailsResponseModel?> getBogoOfferDetails({required String idOrSlug, int offset = 1, int limit = 10, int? moduleId}) async {
    return await bogoOfferRepositoryInterface.getBogoOfferDetails(idOrSlug: idOrSlug, offset: offset, limit: limit, moduleId: moduleId);
  }
}
