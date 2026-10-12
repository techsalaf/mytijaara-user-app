import 'package:sixam_mart/features/bundle/domain/models/bundle_model.dart';
import 'package:sixam_mart/features/bundle/domain/repositories/bundle_repository_interface.dart';
import 'package:sixam_mart/features/bundle/domain/services/bundle_service_interface.dart';

class BundleService implements BundleServiceInterface {
  final BundleRepositoryInterface bundleRepositoryInterface;
  BundleService({required this.bundleRepositoryInterface});

  @override
  Future<BundleListModel?> getBundleHome({int limit = 10, int? storeId, String? search}) async {
    return await bundleRepositoryInterface.getBundleHome(limit: limit, storeId: storeId, search: search);
  }

  @override
  Future<BundleListModel?> getBundleList({int offset = 1, int limit = 10, int? storeId, String? search}) async {
    return await bundleRepositoryInterface.getBundleList(offset: offset, limit: limit, storeId: storeId, search: search);
  }

  @override
  Future<BundleListModel?> getStoreBundles({required int storeId, int offset = 1, int limit = 10}) async {
    return await bundleRepositoryInterface.getStoreBundles(storeId: storeId, offset: offset, limit: limit);
  }

  @override
  Future<Bundle?> getBundleDetails(int bundleId) async {
    return await bundleRepositoryInterface.getBundleDetails(bundleId);
  }
}
