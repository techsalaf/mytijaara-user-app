/// Reads list payloads out of a response body without caring which API format
/// produced it.
///
/// The API moved list payloads under `content.data`. [ApiClient.unwrapEnvelope]
/// already strips the `content` wrapper, so by the time a repository sees the
/// body a list arrives in one of three shapes:
///
/// - a bare `List` — the legacy shape for most endpoints (`/categories`, `/module`)
/// - `{"data": [...], "pagination": {...}}` — the new shape
/// - `{"<legacyKey>": [...]}` — the legacy shape for endpoints that named their
///   list (`stores`, `addresses`, `smart_banners`)
///
/// Using this instead of `response.body.forEach(...)` keeps every repository
/// working against both the current and the new backend, so this migration does
/// not have to land in lockstep with the backend cutover.
class ResponseParser {
  const ResponseParser._();

  /// The payload inside an envelope, for a body that was **not** put through
  /// [ApiClient.handleResponse].
  ///
  /// `getData(rawBody: true)` deliberately skips decoding so the caller can parse
  /// on a worker isolate, which also skips the envelope unwrap. Those isolate
  /// entry points must call this on the decoded map or they hand the model
  /// `{identical_code, message, content, errors}` and it parses nothing.
  ///
  /// Pure and dependency-free, so it is safe to run inside an isolate. There is
  /// no status code here because `rawBody` only skips decoding on a 2xx.
  static dynamic payloadOf(dynamic decoded) {
    if (decoded is Map && decoded.containsKey('identical_code') && decoded['content'] != null) {
      return decoded['content'];
    }
    return decoded;
  }

  /// The list inside [body], or `null` when there is nothing list-shaped in it.
  ///
  /// [legacyKey] is the key the old API used for this endpoint's list, when it
  /// used one. It is checked *before* `data`: an explicitly named key is a
  /// stronger signal than the generic one, and checking it first keeps a
  /// transitional body that carries both from silently picking the wrong list.
  ///
  /// Only for responses holding a **single** list. For a body with several lists
  /// side by side (`{"vehicles": [...], "providers": [...]}`) use [namedListOf],
  /// which never falls back to `data` — the fallback would otherwise hand every
  /// caller the same list.
  static List<dynamic>? listOf(dynamic body, {String? legacyKey}) {
    if (body is List) return body;
    if (body is Map) {
      if (legacyKey != null) {
        final dynamic legacy = body[legacyKey];
        if (legacy is List) return legacy;
      }
      final dynamic data = body['data'];
      if (data is List) return data;
    }
    return null;
  }

  /// Same as [listOf] but never null — saves an `?? []` at most call sites.
  static List<dynamic> listOrEmpty(dynamic body, {String? legacyKey}) =>
      listOf(body, legacyKey: legacyKey) ?? <dynamic>[];

  /// The list stored under exactly [key], with **no** `data` fallback.
  ///
  /// Use for a body that holds more than one list — a wish list of vehicles and
  /// providers, banners split into campaigns and banners. Falling back to `data`
  /// there would return the same list for every key.
  static List<dynamic> namedListOf(dynamic body, String key) {
    if (body is Map) {
      final dynamic value = body[key];
      if (value is List) return value;
    }
    return <dynamic>[];
  }
}
