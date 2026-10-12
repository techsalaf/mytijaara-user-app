import 'package:sixam_mart/features/bogo_offer/domain/models/bogo_offer_model.dart';
import 'package:sixam_mart/interfaces/repository_interface.dart';

abstract class BogoOfferRepositoryInterface extends RepositoryInterface {
  Future<BogoHomeModel?> getBogoHomeData({int limit = 6, String? orderType, int? moduleId});
  Future<BogoOfferListModel?> getBogoOfferList({int offset = 1, int limit = 10, int? moduleId});
  Future<BogoOfferDetailsResponseModel?> getBogoOfferDetails({required String idOrSlug, int offset = 1, int limit = 10, int? moduleId});
}
