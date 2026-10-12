import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';

/// The BOGO / Happy Hour broadcast reaches the customer by FCM topic, not by token, and the
/// topic is scoped to zone **and** module: `zone_{zoneId}_module_{moduleId}_customer`.
///
/// A subscription outlives the process, so the topic the device last joined is remembered —
/// without it a customer who moves zone or switches module stays on the old topic for good
/// and hears about offers in a city or vertical they have left.
class NotificationTopicHelper {
  NotificationTopicHelper._();

  static String topicFor(int zoneId, int moduleId) => 'zone_${zoneId}_module_${moduleId}_customer';

  /// Joins the topic for the customer's current zone and module, leaving whichever one the
  /// device was on. Safe to call often — it does nothing when the topic has not changed.
  static Future<void> syncCustomerTopic() async {
    if(GetPlatform.isWeb) {
      return;
    }

    final int? zoneId = AddressHelper.getUserAddressFromSharedPref()?.zoneId;
    final int? moduleId = Get.find<SplashController>().module?.id ?? Get.find<SplashController>().cacheModule?.id;
    final String? topic = (zoneId != null && moduleId != null) ? topicFor(zoneId, moduleId) : null;

    final SharedPreferences prefs = Get.find<SharedPreferences>();
    final String? previous = prefs.getString(AppConstants.customerBroadcastTopic);
    if(previous == topic) {
      return;
    }

    if(previous != null && previous.isNotEmpty) {
      await FirebaseMessaging.instance.unsubscribeFromTopic(previous);
    }
    if(topic == null) {
      await prefs.remove(AppConstants.customerBroadcastTopic);
      return;
    }

    await FirebaseMessaging.instance.subscribeToTopic(topic);
    await prefs.setString(AppConstants.customerBroadcastTopic, topic);
  }

  /// On logout: leave the topic and forget it, so the next customer on this device does not
  /// inherit the last one's zone.
  static Future<void> clearCustomerTopic() async {
    if(GetPlatform.isWeb) {
      return;
    }
    final SharedPreferences prefs = Get.find<SharedPreferences>();
    final String? previous = prefs.getString(AppConstants.customerBroadcastTopic);
    if(previous != null && previous.isNotEmpty) {
      await FirebaseMessaging.instance.unsubscribeFromTopic(previous);
    }
    await prefs.remove(AppConstants.customerBroadcastTopic);
  }
}
