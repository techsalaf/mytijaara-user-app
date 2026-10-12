import 'package:sixam_mart/features/bogo_offer/domain/models/bogo_offer_model.dart';

abstract class BogoOfferServiceInterface {
  Future<BogoHomeModel?> getBogoHomeData({int limit = 6, String? orderType, int? moduleId});
  Future<BogoOfferListModel?> getBogoOfferList({int offset = 1, int limit = 10, int? moduleId});
  Future<BogoOfferDetailsResponseModel?> getBogoOfferDetails({required String idOrSlug, int offset = 1, int limit = 10, int? moduleId});
}
