import 'package:flutter/foundation.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';

/// Parses a raw JSON response body into a model on a worker isolate.
///
/// `jsonDecode` plus model construction for a large payload — a store's whole
/// catalog, for example — runs tens to hundreds of milliseconds on a mid-tier
/// device, and it runs on the very frame the screen is trying to paint. Flutter's
/// [compute] moves that work off the UI isolate; the result is returned via
/// `Isolate.exit`, so the parsed object graph is handed back **without being
/// copied** — only the raw string is sent in.
///
/// ### The [parser] must be a top-level or static function
///
/// ```dart
/// StoreCategoryItemModel storeCategoryItemModelFromRawJson(String rawJson) =>
///     StoreCategoryItemModel.fromJson(jsonDecode(rawJson) as Map<String, dynamic>);
/// ```
///
/// Never pass an inline closure. The VM captures a closure's entire enclosing
/// context, which inside a repository method means `this` — and `ApiClient` /
/// `SharedPreferences` are not sendable, so the send throws
/// `ArgumentError: Illegal argument in isolate message` at runtime, on device only.
///
/// ### The [parser] must be pure
///
/// The worker isolate has no GetX container and no plugin bindings: no
/// `Get.find`, no `BuildContext`, no `.tr`, no `SharedPreferences`. Models whose
/// `fromJson` reaches for a controller (e.g. `ItemModel.fromJson`, which calls
/// `Get.find<SplashController>()`) cannot be parsed through this helper.
class JsonParseHelper {
  const JsonParseHelper._();

  /// Below this size, spawning an isolate costs more than the parse itself.
  /// Isolate spawn is ~1-3ms on a mid-tier Android; decode + model construction
  /// runs at roughly 0.07-0.12ms per KB, so break-even lands around 32KB.
  static const int isolateThresholdBytes = 32 * 1024;

  /// Runs [parser] over [rawJson], off the UI isolate when the payload is large
  /// enough to be worth it. A [FormatException] from malformed JSON propagates
  /// to the caller exactly as it would from a direct `jsonDecode`.
  static Future<T> parse<T>(String rawJson, T Function(String rawJson) parser, {String? debugLabel}) async {
    // Web has no isolates — `compute` there just runs the callback on the current
    // event loop, so take the sync path rather than paying a microtask hop for nothing.
    if (ResponsiveHelper.isWeb() || rawJson.length < isolateThresholdBytes) {
      return parser(rawJson);
    }
    return compute<String, T>(parser, rawJson, debugLabel: debugLabel ?? 'JsonParseHelper.parse');
  }
}
