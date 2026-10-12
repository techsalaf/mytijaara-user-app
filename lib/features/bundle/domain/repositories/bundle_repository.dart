import 'package:get/get_connect.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/bundle/domain/models/bundle_model.dart';
import 'package:sixam_mart/features/bundle/domain/repositories/bundle_repository_interface.dart';
import 'package:sixam_mart/util/app_constants.dart';

/// The customer half of the bundle API (§4 of the bundle API guide).
///
/// All four endpoints are public — a browsing visitor sees bundles without a
/// token — and all four return the same object shape, so they share one model.
class BundleRepository implements BundleRepositoryInterface {
  final ApiClient apiClient;
  BundleRepository({required this.apiClient});

  /// `GET /bundle/home` — the home-screen strip. Takes `limit` only, and returns
  /// no pagination block: it is a strip, not a page.
  @override
  Future<BundleListModel?> getBundleHome({int limit = 10, int? storeId, String? search}) async {
    Response response = await apiClient.getData(
      '${AppConstants.bundleHomeUri}?limit=$limit'
      '${storeId != null ? '&store_id=$storeId' : ''}'
      '${_searchQuery(search)}',
      handleError: false,
      // The strip sits on every module home and the controller is a singleton,
      // so a response that lands after the user switched modules must be
      // dropped rather than overwrite the now-active module's strip.
      moduleScoped: true,
    );
    if(response.statusCode == 200) {
      return BundleListModel.fromJson(response.body);
    }
    return null;
  }

  /// `offset` is a 1-based page number despite its name.
  @override
  Future<BundleListModel?> getBundleList({int offset = 1, int limit = 10, int? storeId, String? search}) async {
    Response response = await apiClient.getData(
      '${AppConstants.bundleListUri}?limit=$limit&offset=$offset'
      '${storeId != null ? '&store_id=$storeId' : ''}'
      '${_searchQuery(search)}',
      handleError: false,
      moduleScoped: true,
    );
    if(response.statusCode == 200) {
      return BundleListModel.fromJson(response.body);
    }
    return null;
  }

  /// One store's bundles. `store_id` is required — without it the endpoint
  /// answers `404 store_id` rather than an empty list.
  @override
  Future<BundleListModel?> getStoreBundles({required int storeId, int offset = 1, int limit = 10}) async {
    Response response = await apiClient.getData(
      '${AppConstants.storeBundlesUri}?store_id=$storeId&limit=$limit&offset=$offset',
      handleError: false,
      moduleScoped: true,
    );
    if(response.statusCode == 200) {
      return BundleListModel.fromJson(response.body);
    }
    return null;
  }

  /// The only endpoint that fills `items` — the list endpoints all send null, so
  /// a details screen cannot be rendered from a card's data alone.
  ///
  /// A bundle that is switched off, outside its window, or in a module without
  /// the feature is not merely unavailable here: it answers **404**, because the
  /// browse scope excludes it before the availability rule runs.
  @override
  Future<Bundle?> getBundleDetails(int bundleId) async {
    Response response = await apiClient.getData('${AppConstants.bundleDetailsUri}$bundleId', handleError: false);
    if(response.statusCode == 200) {
      return Bundle.fromResponse(response.body);
    }
    return null;
  }

  /// Capped at 100 characters by the server; a longer term is rejected rather
  /// than truncated.
  String _searchQuery(String? search) {
    if(search == null || search.trim().isEmpty) {
      return '';
    }
    final String trimmed = search.trim();
    return '&search=${Uri.encodeQueryComponent(trimmed.length > 100 ? trimmed.substring(0, 100) : trimmed)}';
  }

  @override
  Future add(value) => throw UnimplementedError();

  @override
  Future update(Map<String, dynamic> body, int? id) => throw UnimplementedError();

  @override
  Future delete(int? id) => throw UnimplementedError();

  @override
  Future getList({int? offset}) => getBundleList(offset: offset ?? 1);

  @override
  Future get(String? id) => getBundleDetails(int.tryParse(id ?? '') ?? 0);
}
