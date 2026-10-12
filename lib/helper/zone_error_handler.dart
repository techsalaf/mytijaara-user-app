import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/helper/route_helper.dart';

/// Recovers from the API refusing a request because the saved address sits in a
/// zone that cannot serve the active module.
///
/// The backend answers this as a `422` carrying the envelope's error list:
///
/// ```json
/// { "identical_code": "unprocessable_entity_422",
///   "message": "Validation failed",
///   "content": null,
///   "errors": [{"code": "zone_module_not_found",
///               "message": "Zone is not available right now"}] }
/// ```
///
/// Until now that surfaced as a snackbar and nothing else: the customer was told
/// the zone was unavailable while still sitting on a screen that could never
/// load, with no way to act on it. Every request made from that address fails
/// the same way, so the only recovery is a new address — which is what the
/// set-location screen is for.
///
/// Matched on the error **`code`**, never on `message`, which is localized and
/// free for the backend to reword.
class ZoneErrorHandler {
  ZoneErrorHandler._();

  /// The error code that means "this zone cannot serve this module".
  static const String zoneModuleNotFoundCode = 'zone_module_not_found';

  /// One redirect at a time. The home screen fires a dozen requests in parallel
  /// and every one of them fails together, so without this the customer is sent
  /// to the same screen a dozen times over.
  static bool _redirecting = false;

  /// How long the single-flight latch holds. Long enough to swallow one burst of
  /// parallel failures, short enough that a genuine failure minutes later still
  /// redirects. [_isOnLocationScreen] is the second, independent guard.
  static const Duration _latch = Duration(seconds: 3);

  /// Whether [response] is the zone-unavailable failure.
  ///
  /// Deliberately narrow: a non-2xx, the envelope shape, and the exact code. Any
  /// other failure — including other 422 validation errors, which are far more
  /// common — falls through to the caller's existing handling untouched.
  static bool isZoneUnavailable(Response response) {
    final int? status = response.statusCode;
    if (status == null || (status >= 200 && status < 300)) {
      return false;
    }
    final dynamic body = response.body;
    if (body is! Map) {
      return false;
    }
    final dynamic errors = body['errors'];
    if (errors is! List) {
      return false;
    }
    for (final dynamic error in errors) {
      if (error is Map && error['code'] == zoneModuleNotFoundCode) {
        return true;
      }
    }
    return false;
  }

  /// Sends the customer to the set-location screen, carrying the API's own
  /// explanation so they know why they were moved.
  ///
  /// Pushed rather than replacing the stack: an `offAll` would throw away a cart
  /// or a half-filled checkout the customer can still get back to once they have
  /// picked a servable address. `page=home` gives the screen its back button, so
  /// they are never trapped there.
  static void sendToSetLocation(String? message) {
    if (_redirecting || _isOnLocationScreen()) {
      return;
    }
    _redirecting = true;
    Future<void>.delayed(_latch, () => _redirecting = false);

    if (message != null && message.isNotEmpty) {
      showCustomSnackBar(message);
    }
    Get.toNamed(RouteHelper.getAccessLocationRoute('home'));
  }

  /// True while the customer is already somewhere they can fix the address.
  ///
  /// Guards the loop this would otherwise create: the location screens make API
  /// calls of their own, and any of those failing the same way would push the
  /// screen on top of itself.
  static bool _isOnLocationScreen() {
    final String route = Get.currentRoute;
    return route.startsWith(RouteHelper.accessLocation)
        || route.startsWith(RouteHelper.pickMap)
        || route.startsWith(RouteHelper.splash);
  }

  /// Test seam — the latch is static state that would otherwise leak between tests.
  static void resetForTest() => _redirecting = false;
}
