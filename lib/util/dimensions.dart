import 'package:get/get.dart';

class Dimensions {
  /// 8
  static double fontSizeOverSmall = Get.context!.width >= 1300 ? 10 : 8;
  /// 10
  static double fontSizeExtraSmall = Get.context!.width >= 1300 ? 12 : 10;
  /// 12
  static double fontSizeSmall = Get.context!.width >= 1300 ? 14 : 12;
  /// 14
  static double fontSizeDefault = Get.context!.width >= 1300 ? 16 : 14;
  /// 16
  static double fontSizeLarge = Get.context!.width >= 1300 ? 18 : 16;
  /// 18
  static double fontSizeExtraLarge = Get.context!.width >= 1300 ? 20 : 18;
  /// 20
  static double fontSizeExtremeLarge = Get.context!.width >= 1300 ? 22 : 20;
  /// 24
  static double fontSizeOverLarge = Get.context!.width >= 1300 ? 26 : 24;

  /// 5.0
  static const double paddingSizeExtraSmall = 5.0;
  /// 10.0
  static const double paddingSizeSmall = 10.0;
  /// 15.00
  static const double paddingSizeDefault = 15.0;
  /// 20.0
  static const double paddingSizeLarge = 20.0;
  /// 24.0
  static const double paddingSizeExtraLarge = 24.0;
  /// 30.0
  static const double paddingSizeExtremeLarge = 30.0;
  /// 35.0
  static const double paddingSizeExtraOverLarge = 35.0;

  /// 5.0
  static const double radiusSmall = 5.0;
  /// 8.0
  static const double radiusMedium = 8.0;
  /// 10.0
  static const double radiusDefault = 10.0;
  /// 15.0
  static const double radiusLarge = 15.0;
  /// 20.0
  static const double radiusExtraLarge = 20.0;

  static const double webMaxWidth = 1170;
  static const int messageInputLength = 1000;

  static const double pickMapIconSize = 100.0;
}
