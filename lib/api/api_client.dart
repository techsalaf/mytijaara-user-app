import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:path/path.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get_connect/http/src/request/request.dart';
import 'package:http_parser/http_parser.dart';
import 'package:sixam_mart/api/api_checker.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/common/models/error_response.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiClient extends GetxService {
  final String appBaseUrl;
  final SharedPreferences sharedPreferences;
  static final String noInternetMessage = 'connection_to_api_server_failed'.tr;
  final int timeoutInSeconds = 40;

  /// Characters of a raw (off-isolate parsed) response body to print in debug logs.
  static const int _rawBodyLogLimit = 1000;

  String? token;
  late Map<String, String> _mainHeaders;

  /// Memoised parse of the `cacheModuleId` pref, keyed on the raw stored string.
  ///
  /// [updateHeader] has 25 call sites and re-ran `jsonDecode` + `ModuleModel.fromJson`
  /// on every one of them. Keying the memo on the raw string means a write to the
  /// pref invalidates it on its own — there is no separate invalidation call to
  /// forget, and no way for the header to go stale after a module switch.
  String? _cachedModuleIdRaw;
  int? _cachedModuleIdValue;

  ApiClient({required this.appBaseUrl, required this.sharedPreferences}) {
    token = sharedPreferences.getString(AppConstants.token);
    if (kDebugMode) {
      print('Token: $token');
    }
    AddressModel? addressModel;
    try {
      addressModel = AddressModel.fromJson(jsonDecode(sharedPreferences.getString(AppConstants.userAddress)!));
    } catch (_) {}
    int? moduleID;
    if (GetPlatform.isWeb && sharedPreferences.containsKey(AppConstants.moduleId)) {
      try {
        moduleID = ModuleModel.fromJson(jsonDecode(sharedPreferences.getString(AppConstants.moduleId)!)).id;
      } catch (_) {}
    }
    updateHeader(token, addressModel?.zoneIds, addressModel?.areaIds, sharedPreferences.getString(AppConstants.languageCode),
      moduleID?.toString(), addressModel?.latitude, addressModel?.longitude, null);
  }

  Map<String, String> updateHeader(String? token, List<int>? zoneIDs, List<int>? operationIds, String? languageCode, String? moduleID,
      String? latitude, String? longitude, int? zoneId, {bool setHeader = true, fromModule = false,
  }) {
    Map<String, String> header = {};

    final String? cachedModuleRaw = sharedPreferences.getString(AppConstants.cacheModuleId);
    if (moduleID != null || cachedModuleRaw != null) {
      header.addAll({AppConstants.moduleId: '${moduleID ?? _moduleIdFromCachePref(cachedModuleRaw!)}'});
    }
    header.addAll({
      'Content-Type': 'application/json; charset=UTF-8',
      AppConstants.zoneId: (zoneId != null && fromModule) ? '$zoneId' : zoneIDs != null ? jsonEncode(zoneIDs) : '',

      ///this will add in ride module
      // AppConstants.operationAreaId: operationIds != null ? jsonEncode(operationIds) : '',
      AppConstants.localizationKey: languageCode ?? AppConstants.languages[0].languageCode!,
      AppConstants.latitude: latitude != null ? jsonEncode(latitude) : '',
      AppConstants.longitude: longitude != null ? jsonEncode(longitude) : '',
      'Authorization': 'Bearer $token',
    });
    if (setHeader) {
      _mainHeaders = header;
    }
    return header;
  }

  /// The module id inside [raw], parsed at most once per distinct stored value.
  ///
  /// A malformed value still throws exactly where it did before — the memo fields
  /// are only assigned after a successful parse, so a bad write cannot poison the
  /// cache and cannot silently turn into a `null` module id in the header.
  int? _moduleIdFromCachePref(String raw) {
    if (raw != _cachedModuleIdRaw) {
      _cachedModuleIdValue = ModuleModel.fromJson(jsonDecode(raw)).id;
      _cachedModuleIdRaw = raw;
    }
    return _cachedModuleIdValue;
  }

  Map<String, String> getHeader() => _mainHeaders;

  Future<Response> getData(String uri, {Map<String, dynamic>? query, Map<String, String>? headers, bool handleError = true, bool moduleScoped = false,
    bool rawBody = false}) async {
    try {
      final Map<String, String> requestHeaders = headers ?? _mainHeaders;
      // For module-scoped calls, remember the module this request was sent for so a
      // late response can be dropped if the user has since switched modules.
      final String? requestModuleId = moduleScoped ? requestHeaders[AppConstants.moduleId] : null;
      if (kDebugMode) {
        log('====> API Call: $uri\nHeader: $requestHeaders');
      }
      http.Response response = await http.get(Uri.parse(appBaseUrl + uri), headers: requestHeaders).timeout(Duration(seconds: timeoutInSeconds));
      // Module switched while this was in flight — drop it so it can't overwrite the
      // shared controllers bound to the now-active module's screen.
      if (moduleScoped && requestModuleId != _mainHeaders[AppConstants.moduleId]) {
        return const Response(statusCode: 499, statusText: 'stale module response');
      }
      return handleResponse(response, uri, handleError, rawBody: rawBody);
    } catch (e) {
      if (kDebugMode) {
        print('------------${e.toString()}');
      }
      return Response(statusCode: 1, statusText: noInternetMessage);
    }
  }

  Future<Response> postData(String uri, dynamic body, {Map<String, String>? headers, int? timeout, bool handleError = true,}) async {
    try {
      if (kDebugMode) {
        print('====> API Call: $uri\nHeader: ${headers ?? _mainHeaders}');
        print('====> API Body: $body');
      }

      Map<dynamic, dynamic> newBody = {};
      if (body != null) {
        body.forEach((key, value) {
          if (value != null && value.toString().isNotEmpty) {
            newBody.addAll({key: value});
          }
        });
      }

      http.Response response = await http.post(
        Uri.parse(appBaseUrl + uri),
        body: jsonEncode(newBody), headers: headers ?? _mainHeaders).timeout(Duration(seconds: timeout ?? timeoutInSeconds)
      );
      return handleResponse(response, uri, handleError);
    } catch (e) {
      return Response(statusCode: 1, statusText: noInternetMessage);
    }
  }

  Future<Response> postMultipartData(
    String uri,
    Map<String, String> body,
    List<MultipartBody> multipartBody, {
    List<MultipartDocument>? multipartDoc,
    Map<String, String>? headers,
    bool handleError = true,
  }) async {
    try {
      debugPrint('====> API Call: $uri\nHeader: $_mainHeaders');
      debugPrint(
        '====> API Body: $body with ${multipartBody.length} and multipart ${multipartDoc?.length}',
      );
      http.MultipartRequest request = http.MultipartRequest(
        'POST',
        Uri.parse(appBaseUrl + uri),
      );
      final Map<String, String> multipartHeaders = Map<String, String>.from(headers ?? _mainHeaders);
      multipartHeaders.removeWhere((key, value) => key.toLowerCase() == 'content-type');
      request.headers.addAll(multipartHeaders);
      for (MultipartBody multipart in multipartBody) {
        if (multipart.file != null) {
          if (kIsWeb) {
            Uint8List bytes = await multipart.file!.readAsBytes();

            http.MultipartFile part = http.MultipartFile.fromBytes(multipart.key, bytes, filename: 'image.jpg', contentType: MediaType('image', 'jpeg'));

            request.files.add(part);
          } else {
            File file = File(multipart.file!.path);
            request.files.add(
              http.MultipartFile(multipart.key, file.readAsBytes().asStream(), file.lengthSync(), filename: file.path.split('/').last),
            );
          }
        }
      }

      if (multipartDoc != null && multipartDoc.isNotEmpty) {
        for (MultipartDocument file in multipartDoc) {
          if (kIsWeb) {
            PlatformFile platformFile = file.file!.files.first;
            request.files.add(
              http.MultipartFile.fromBytes(file.key, platformFile.bytes!, filename: platformFile.name),
            );
          } else {
            File other = File(file.file!.files.single.path!);
            Uint8List list0 = await other.readAsBytes();
            var part = http.MultipartFile(file.key, other.readAsBytes().asStream(), list0.length, filename: basename(other.path));
            request.files.add(part);
          }
        }
      }

      request.fields.addAll(body);
      debugPrint(
        '====> API Multipart file parts: ${request.files.map((f) => '${f.field} (${f.filename}, ${f.length} bytes)').toList()}',
      );
      http.Response response = await http.Response.fromStream(await request.send());
      return handleResponse(response, uri, handleError);
    } catch (e) {
      return Response(statusCode: 1, statusText: noInternetMessage);
    }
  }

  Future<Response> putData(
    String uri,
    dynamic body, {Map<String, String>? headers, bool handleError = true}) async {
    try {
      if (kDebugMode) {
        print('====> API Call: $uri\nHeader: ${headers ?? _mainHeaders}');
        print('====> API Body: $body');
      }
      http.Response response = await http.put(Uri.parse(appBaseUrl + uri), body: jsonEncode(body), headers: headers ?? _mainHeaders).timeout(Duration(seconds: timeoutInSeconds));
      return handleResponse(response, uri, handleError);
    } catch (e) {
      return Response(statusCode: 1, statusText: noInternetMessage);
    }
  }

  Future<Response> deleteData(
    String uri, {
    dynamic body,
    Map<String, String>? headers,
    bool handleError = true,
  }) async {
    try {
      if (kDebugMode) {
        print('====> API Call: $uri\nHeader: ${headers ?? _mainHeaders}');
      }
      http.Response response = await http
          .delete(Uri.parse(appBaseUrl + uri), headers: headers ?? _mainHeaders, body: body != null ? jsonEncode(body) : null)
          .timeout(Duration(seconds: timeoutInSeconds));
      return handleResponse(response, uri, handleError);
    } catch (e) {
      return Response(statusCode: 1, statusText: noInternetMessage);
    }
  }

  Response handleResponse(
    http.Response response,
    String uri,
    bool handleError, {
    bool rawBody = false,
  }) {
    // `http.Response.body` is a *getter* that re-runs the charset decode over
    // `bodyBytes` on every access, so reading it twice (once to parse, once for
    // `bodyString`) UTF-8-decoded the whole payload twice per request. Read it
    // once here and reuse it — same value, half the work.
    final String bodyText = response.body;
    dynamic body;
    // Opt-in: leave a successful body as the raw string so the caller can decode it
    // on a worker isolate (JsonParseHelper) instead of blocking a frame here. Every
    // non-2xx still decodes, so the error-shape handling below and ApiChecker are
    // untouched — and no existing call site passes rawBody, so nothing else changes.
    final bool skipDecode = rawBody && isSuccessCode(response.statusCode);
    if (!skipDecode) {
      try {
        body = jsonDecode(bodyText);
      } catch (_) {}
    }
    // The envelope carries its human-readable `message` at the top level, beside
    // `content` rather than inside it — so unwrapping would throw away the success
    // message that a flat response used to deliver as `body['message']`. Lift it
    // onto `statusText` (which otherwise only holds the HTTP reason phrase) so
    // callers still have somewhere to read it from.
    final String? envelopeMessage = envelopeMessageOf(body, response.statusCode);
    body = unwrapEnvelope(body, response.statusCode);
    Response response0 = Response(
      body: body ?? bodyText,
      bodyString: bodyText,
      request: Request(
        headers: response.request!.headers,
        method: response.request!.method,
        url: response.request!.url,
      ),
      headers: response.headers,
      statusCode: response.statusCode,
      statusText: envelopeMessage ?? response.reasonPhrase,
    );
    if (!isSuccessCode(response0.statusCode) &&
        response0.body != null &&
        response0.body is! String) {
      // The new envelope leads with `identical_code` and carries its
      // human-readable reason at the top level, so none of the legacy `startsWith`
      // shapes below match it — the user was shown the bare HTTP reason phrase
      // ("Unprocessable Content") instead of what actually failed ("The dm tips
      // must be a number."). Checked first, and typed rather than by string prefix.
      final String? envelopeError = envelopeErrorMessageOf(response0.body);
      if (envelopeError != null) {
        response0 = Response(
          statusCode: response0.statusCode,
          body: response0.body,
          statusText: envelopeError,
        );
      } else if (response0.body.toString().startsWith('{errors: [{code:')) {
        ErrorResponse errorResponse = ErrorResponse.fromJson(response0.body);
        response0 = Response(
          statusCode: response0.statusCode,
          body: response0.body,
          statusText: errorResponse.errors![0].message,
        );
      } else if (response0.body.toString().startsWith('{response_code: zone_404, message:')) {
        response0 = Response(statusCode: response0.statusCode, body: response0.body, statusText: response0.body['message']);
      } else if(response0.body.toString().startsWith('{response_code: route_404, message:')) {
        response0 = Response(statusCode: response0.statusCode, body: response0.body, statusText: response0.body['message']);
      } else if(response0.body.toString().startsWith('{response_code: incomplete_ride_403, message:')) {
        response0 = Response(statusCode: response0.statusCode, body: response0.body, statusText: response0.body['message']);
      } else if(response0.body.toString().startsWith('{errors: [{code: interest, message:')) {
        response0 = Response(statusCode: response0.statusCode, body: response0.body, statusText: response0.body['message']);
      }else if (response0.body.toString().startsWith('{message')) {
        response0 = Response(statusCode: response0.statusCode, body: response0.body, statusText: response0.body['message']);
      }
    } else if (!isSuccessCode(response0.statusCode) && response0.body == null) {
      response0 = Response(statusCode: 0, statusText: noInternetMessage);
    }
    if (kDebugMode) {
      log('====> API Response: [${response0.statusCode}] $uri');
      if (skipDecode) {
        final String raw = response0.bodyString ?? '';
        log('====> API Response Body: [${raw.length} chars, decoded off-isolate] '
            '${raw.length > _rawBodyLogLimit ? '${raw.substring(0, _rawBodyLogLimit)}…<truncated>' : raw}');
      } else if (!ResponsiveHelper.isWeb() || response.statusCode != 500) {
        log('====> API Response Body: ${response0.body}');
      }
    }
    if (handleError) {
      if (isSuccessCode(response0.statusCode)) {
        return response0;
      } else {
        ApiChecker.checkApi(response0);
        return const Response();
      }
    } else {
      return response0;
    }
  }

  /// Any 2xx counts as success. The API returns `201 Created` on several endpoints
  /// (`auth/guest/request`, `customer/cart/add`, `customer/address/add`,
  /// `customer/order/offline-payment`, `service/requested-services`); treating only
  /// `200` as success swallowed those responses and showed the user an error snackbar.
  static bool isSuccessCode(int? statusCode) =>
      statusCode != null && statusCode >= 200 && statusCode < 300;

  /// The API wraps successful payloads in
  /// `{identical_code, message, content, errors}`. Unwrap it once here so every
  /// repository keeps reading its payload straight off `response.body`.
  ///
  /// Deliberately conservative, so the app works against both the current and the
  /// new backend:
  /// - Gated on `identical_code`, which only the new format carries — a legacy
  ///   response is returned untouched.
  /// - Only unwraps a 2xx. Error bodies keep the envelope so the `errors` handling
  ///   in [handleResponse] and [ApiChecker] still see the shape they expect.
  /// - Only unwraps a non-null `content`. When `content` is null the envelope is
  ///   left in place, because its top-level `message` sits exactly where the old
  ///   flat `{"message": …}` body had it, so callers reading `body['message']`
  ///   keep working.
  static dynamic unwrapEnvelope(dynamic body, int? statusCode) {
    if (!isSuccessCode(statusCode) || body is! Map) return body;
    if (!body.containsKey('identical_code') || body['content'] == null) return body;
    return body['content'];
  }

  /// The envelope's top-level `message` for a response [unwrapEnvelope] will
  /// unwrap, or null for anything else — including errors, whose message is left
  /// to the error-shape handling in [handleResponse] and [ApiChecker].
  static String? envelopeMessageOf(dynamic body, int? statusCode) {
    if (!isSuccessCode(statusCode) || body is! Map) return null;
    if (!body.containsKey('identical_code') || body['content'] == null) return null;
    final dynamic message = body['message'];
    return message is String ? message : null;
  }

  /// The new envelope's human-readable failure reason, or null when [body] isn't a
  /// new-format error body (so every legacy shape falls through to the handling in
  /// [handleResponse] untouched).
  ///
  /// Prefers the top-level `message`. Falls back to `errors`, which arrives in two
  /// shapes: the legacy `[{code, message}]` list, and — on validation failures like
  /// `customer/order/place` — a map keyed by field, `{"dm_tips": ["The dm tips must
  /// be a number."]}`.
  /// `errors` first, `message` only as a fallback. The envelope's `message` is a
  /// category ("Permission denied"); the entry inside `errors` is the sentence written
  /// for the customer ("You can only use this offer 3 more times") — showing the former
  /// told them nothing about what actually stopped them.
  static String? envelopeErrorMessageOf(dynamic body) {
    if (body is! Map || !body.containsKey('identical_code')) return null;

    final dynamic errors = body['errors'];
    if (errors is List && errors.isNotEmpty) {
      final dynamic first = errors.first;
      if (first is Map && first['message'] is String && (first['message'] as String).isNotEmpty) {
        return first['message'] as String;
      }
    } else if (errors is Map && errors.isNotEmpty) {
      final dynamic first = errors.values.first;
      if (first is List) {
        if (first.isNotEmpty) return first.first?.toString();
      } else if (first != null) {
        return first.toString();
      }
    }

    final dynamic message = body['message'];
    if (message is String && message.isNotEmpty) return message;
    return null;
  }
}

class MultipartBody {
  String key;
  XFile? file;

  MultipartBody(this.key, this.file);
}

class MultipartDocument {
  String key;
  FilePickerResult? file;
  MultipartDocument(this.key, this.file);
}
