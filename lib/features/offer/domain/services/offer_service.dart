import 'package:sixam_mart/features/redesign_feature/common/models/new_item_model.dart';
import 'package:sixam_mart/features/offer/domain/repositories/offer_repository_interface.dart';
import 'package:sixam_mart/features/offer/domain/services/offer_service_interface.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';

class OfferService implements OfferServiceInterface {
  final OfferRepositoryInterface offerRepositoryInterface;
  OfferService({required this.offerRepositoryInterface});

  @override
  Future<NewItemListResponse?> getOfferItems({required int offset, int limit = 10, String search = '', int? moduleId}) {
    return offerRepositoryInterface.getOfferItems(offset: offset, limit: limit, search: search, moduleId: moduleId);
  }

  @override
  Future<StoreModel?> getOfferStores({required int offset, int limit = 10, String search = '', int? moduleId}) {
    return offerRepositoryInterface.getOfferStores(offset: offset, limit: limit, search: search, moduleId: moduleId);
  }

  @override
  Future<List<Store>?> getExclusiveDeals({int? moduleId}) {
    return offerRepositoryInterface.getExclusiveDeals(moduleId: moduleId);
  }
}
