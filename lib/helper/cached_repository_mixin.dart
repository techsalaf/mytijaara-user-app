import 'dart:convert';
import 'package:sixam_mart/api/response_parser.dart';

import 'package:get/get.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/api/local_client.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';

/// Cache-first GET plumbing, shared by repositories.
///
/// Thirteen repositories hand-roll the same `switch (source)` block. This is that
/// block in one place: the canonical implementation was lifted from
/// `ServiceRepository` (`service_module/service_home/domain/repositories/`).
///
/// Usage — the mixin only needs the repository's [apiClient]:
///
/// ```dart
/// class BrandsRepository with CachedRepositoryMixin implements BrandsRepositoryInterface {
///   @override
///   final ApiClient apiClient;
///   BrandsRepository({required this.apiClient});
///
///   @override
///   Future<BrandModel?> getBrandList({required DataSourceEnum source}) async {
///     final dynamic body = await cachedGet(AppConstants.brandUri, source);
///     return body != null ? BrandModel.fromJson(body) : null;
///   }
/// }
/// ```
///
/// The controller drives the "show cached, then refresh" behaviour by calling with
/// [DataSourceEnum.local] first and recalling itself with [DataSourceEnum.client]:
///
/// ```dart
/// if (_brands == null || reload || fromRecall) {
///   if (dataSource == DataSourceEnum.local) {
///     _brands = await serviceInterface.getBrandList(source: DataSourceEnum.local);
///     update();
///     getBrandList(reload, dataSource: DataSourceEnum.client, fromRecall: true);
///   } else { ... }
/// }
/// ```
///
/// There is intentionally no TTL. Every cached read is immediately followed by a
/// network refresh, so nothing is served stale for longer than one round-trip, and
/// [cacheKey] scopes entries to the active module. Adding an expiry column would
/// mean a Drift schema migration for no behavioural gain.
mixin CachedRepositoryMixin {
  ApiClient get apiClient;

  /// Cache key for [uri], scoped to the active module so modules never read each
  /// other's cached data.
  ///
  /// Always use this rather than building a key by hand — repositories currently
  /// mix `'$uri-$moduleId'` and `'$uri $moduleId'`, which silently stores the same
  /// payload under two rows.
  ///
  /// Pass the full path *including* the query string when a request is
  /// parameterised, so two different filters cannot collide on one key.
  String cacheKey(String uri) => '$uri-${Get.find<SplashController>().module?.id ?? ''}';

  /// GET [uri] through the cache.
  ///
  /// * [DataSourceEnum.client] — hits the network and, on 200, writes the raw body
  ///   to the local cache before returning the decoded JSON.
  /// * [DataSourceEnum.local] — returns the previously cached JSON, or null on a
  ///   cache miss.
  ///
  /// Returns the decoded body (`Map` or `List`) so each caller maps its own model.
  /// Pass [key] when the cache key must differ from [uri] — for example a
  /// paginated endpoint that caches only page 1.
  Future<dynamic> cachedGet(String uri, DataSourceEnum source, {String? key}) async {
    final String id = key ?? cacheKey(uri);
    switch (source) {
      case DataSourceEnum.client:
        final Response response = await apiClient.getData(uri);
        if (response.statusCode == 200) {
          LocalClient.organize(DataSourceEnum.client, id, response.bodyString ?? '', apiClient.getHeader());
          return response.body;
        }
        return null;
      case DataSourceEnum.local:
        final String? cached = await LocalClient.organize(DataSourceEnum.local, id, null, null);
        return cached != null ? ResponseParser.payloadOf(jsonDecode(cached)) : null;
    }
  }
}
