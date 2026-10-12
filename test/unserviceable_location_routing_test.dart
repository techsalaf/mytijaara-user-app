import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/helper/route_helper.dart';

/// Where a customer lands when their location has no service.
///
/// `_prepareZoneData` used to show the "no service in this location" snackbar
/// and then only push the map picker when `route == 'splash'`. Onboarding passes
/// `RouteHelper.onBoarding`, so that branch never fired: the customer was told
/// there was no service and left on the onboarding screen with no way to choose
/// somewhere else.
///
/// It now routes from every entry point, guarded only against pushing a second
/// picker over the first — `PickMapScreen` confirms through the same path, so an
/// unserviceable pick made *on* the map would otherwise stack.
void main() {
  group('shouldRouteToPickMap', () {
    test('routes from onboarding — the case that was stranded', () {
      expect(LocationController.shouldRouteToPickMap(RouteHelper.onBoarding), isTrue);
    });

    test('still routes from splash, which already worked', () {
      expect(LocationController.shouldRouteToPickMap('/splash'), isTrue);
    });

    test('routes from every other entry point too', () {
      for(final String route in <String>[
        RouteHelper.accessLocation, RouteHelper.signUp, '/sign-in', '/home', '/verification', '/',
      ]) {
        expect(LocationController.shouldRouteToPickMap(route), isTrue, reason: route);
      }
    });

    test('does not stack a second picker over the picker', () {
      expect(LocationController.shouldRouteToPickMap(RouteHelper.pickMap), isFalse);
    });

    test('recognises the picker with its query string attached', () {
      // `Get.currentRoute` carries the real arguments, not the bare constant.
      expect(
        LocationController.shouldRouteToPickMap(RouteHelper.getPickMapRoute(RouteHelper.onBoarding, false)),
        isFalse,
      );
      expect(
        LocationController.shouldRouteToPickMap(RouteHelper.getPickMapRoute(null, true)),
        isFalse,
      );
    });

    test('a route that merely contains the picker path still routes', () {
      // Only a prefix match counts — the guard is about being *on* the picker.
      expect(LocationController.shouldRouteToPickMap('/address/pick-map'), isTrue);
    });
  });
}
