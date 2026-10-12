import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/helper/zone_error_handler.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:get/get.dart';

class ApiChecker {
  static void checkApi(Response response, {bool getXSnackBar = false}) {
    if(response.statusCode == 401) {
      Get.find<AuthController>().clearSharedData(removeToken: false).then((value) {
        Get.find<FavouriteController>().removeFavourite();
        Get.offAllNamed(RouteHelper.getInitialRoute());
      });
    // The saved address's zone can no longer serve the active module, so every
    // request from it fails identically. A snackbar alone left the customer on a
    // screen that could never load; the set-location screen is the only way out.
    // Sits beside the 401 branch because it is the same kind of failure — one the
    // app has to act on, not just report — and it shows the message itself.
    }else if(ZoneErrorHandler.isZoneUnavailable(response)) {
      ZoneErrorHandler.sendToSetLocation(response.statusText);
    }else {
      if(response.statusText != 'The guest id field is required.') {
        showCustomSnackBar(response.statusText, getXSnackBar: getXSnackBar);
      }
    }
  }
}
