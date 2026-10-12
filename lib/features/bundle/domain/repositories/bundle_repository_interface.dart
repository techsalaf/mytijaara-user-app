import 'package:sixam_mart/features/bundle/domain/models/bundle_model.dart';
import 'package:sixam_mart/interfaces/repository_interface.dart';

abstract class BundleRepositoryInterface extends RepositoryInterface {
  Future<BundleListModel?> getBundleHome({int limit = 10, int? storeId, String? search});
  Future<BundleListModel?> getBundleList({int offset = 1, int limit = 10, int? storeId, String? search});
  Future<BundleListModel?> getStoreBundles({required int storeId, int offset = 1, int limit = 10});
  Future<Bundle?> getBundleDetails(int bundleId);
}
