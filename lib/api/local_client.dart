
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:drift/drift.dart' as drift;
import 'package:sixam_mart/helper/db_helper.dart';
import 'package:sixam_mart/local/cache_response.dart';
import 'package:sixam_mart/util/app_constants.dart';

class LocalClient {

  static String _versionedId(String cacheId) => '${AppConstants.appVersion}|$cacheId';

  static Future<String?> organize(DataSourceEnum source, String cacheId, String? responseBody, Map<String, String>? header) async {
    SharedPreferences sharedPreferences = Get.find();
    cacheId = _versionedId(cacheId);
    switch(source) {
      case DataSourceEnum.client:
        // An empty body is not cacheable: every read site does `jsonDecode(row)`
        // guarded only on null, and `jsonDecode('')` throws a FormatException.
        // Skipping the write leaves the previous good row in place (or no row at
        // all), which the caller already handles as a cache miss.
        if(responseBody == null || responseBody.isEmpty) {
          return null;
        }
        try{
          // print('==========cache data : endpoint banner=${cacheId}, '
          //     'header= ${header.toString()}, '
          //     'response= ${responseBody}');

          if(GetPlatform.isWeb) {
            await sharedPreferences.setString(cacheId, responseBody);
          } else {
            DbHelper.insertOrUpdate(
              id: cacheId,
              data: CacheResponseCompanion(
                endPoint: drift.Value(cacheId),
                header: drift.Value(header.toString()),
                response: drift.Value(responseBody),
              ),
            );
          }
        } catch(e) {
          if (kDebugMode) {
            print('=====error occure in repo api bannaer add: $e');
          }
        }
      case DataSourceEnum.local:
        try {
          // Reported as a miss rather than an empty string, so a row written by
          // an older build (which did not guard the write) cannot reach
          // `jsonDecode` and throw. Callers treat null as "no cache".
          if(GetPlatform.isWeb) {
            final String? cacheData = sharedPreferences.getString(cacheId);
            return (cacheData == null || cacheData.isEmpty) ? null : cacheData;
          } else {
            final CacheResponseData? cacheResponseData = await database.getCacheResponseById(cacheId);
            final String? cached = cacheResponseData?.response;
            return (cached == null || cached.isEmpty) ? null : cached;
          }

        } catch (e) {
          if (kDebugMode) {
            print('=====error occur in repo local banner: $e');
          }
        }
    }
    return null;
  }
}