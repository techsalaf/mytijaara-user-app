import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/styles.dart';

class PriceConverter {
  static final RegExp _thousandsSeparator = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');

  static String convertPrice(double? price, {double? discount, String? discountType, bool forDM = false, bool isFoodVariation = false, String? formatedStringPrice, bool forTaxi = false, bool forMenuWallet = false}) {
    if(discount != null && discountType != null){
      if(discountType == 'amount' && !isFoodVariation) {
        price = price! - discount;
      }else if(discountType == 'percent') {
        price = price! - ((discount / 100) * price);
      }
    }
    bool isRightSide = Get.find<SplashController>().configModel!.currencySymbolDirection == 'right';

    if(forMenuWallet) {
      return '${isRightSide ? '' : '${Get.find<SplashController>().configModel!.currencySymbol!} '}'
          '${intl.NumberFormat.compact().format(price)}'
          '${isRightSide ? ' ${Get.find<SplashController>().configModel!.currencySymbol!}' : ''}';
    }

    if(forTaxi && price! > 100000) {
      return '${isRightSide ? '' : '${Get.find<SplashController>().configModel!.currencySymbol!} '}'
          '${intl.NumberFormat.compact().format(price)}'
          '${isRightSide ? ' ${Get.find<SplashController>().configModel!.currencySymbol!}' : ''}';
    }
    return '${isRightSide ? '' : '${Get.find<SplashController>().configModel!.currencySymbol!} '}'
        '${formatedStringPrice ?? toFixed(price!).toStringAsFixed(forDM ? 0 : Get.find<SplashController>().configModel!.digitAfterDecimalPoint!)
        .replaceAllMapped(_thousandsSeparator, (Match m) => '${m[1]},')}'
        '${isRightSide ? ' ${Get.find<SplashController>().configModel!.currencySymbol!}' : ''}';
  }

  static Widget convertAnimationPrice(double? price, {double? discount, String? discountType, bool forDM = false, TextStyle? textStyle}) {
    if(discount != null && discountType != null){
      if(discountType == 'amount') {
        price = price! - discount;
      }else if(discountType == 'percent') {
        price = price! - ((discount / 100) * price);
      }
    }
    bool isRightSide = Get.find<SplashController>().configModel!.currencySymbolDirection == 'right';
    return Directionality(
      textDirection: TextDirection.ltr,
      child: AnimatedFlipCounter(
        duration: const Duration(milliseconds: 500),
        value: toFixed(price!),
        textStyle: textStyle ?? robotoMedium,
        fractionDigits: forDM ? 0 : Get.find<SplashController>().configModel!.digitAfterDecimalPoint!,
        prefix: isRightSide ? '' : '${Get.find<SplashController>().configModel!.currencySymbol!} ',
        suffix: isRightSide ? '${Get.find<SplashController>().configModel!.currencySymbol!} ' : '',
      ),
    );
  }

  static double? convertWithDiscount(double? price, double? discount, String? discountType, {bool isFoodVariation = false}) {
    if(discountType == 'amount' && !isFoodVariation) {
      price = price! - discount!;
    }else if(discountType == 'percent') {
      price = price! - ((discount! / 100) * price);
    }
    return price;
  }

  static double calculation(double amount, double? discount, String type, int quantity) {
    double calculatedAmount = 0;
    if(type == 'amount' || type == 'fixed') {
      calculatedAmount = discount! * quantity;
    }else if(type == 'percent') {
      calculatedAmount = (discount! / 100) * (amount * quantity);
    }
    return calculatedAmount;
  }

  static String percentageCalculation(String price, String discount, String discountType) {
    return '$discount${discountType == 'percent' ? '%' : Get.find<SplashController>().configModel!.currencySymbol}';
  }

  static double toFixed(double val) {
    num mod = power(10, Get.find<SplashController>().configModel!.digitAfterDecimalPoint!);
    return (((val * mod).toPrecision(Get.find<SplashController>().configModel!.digitAfterDecimalPoint!)).floor().toDouble() / mod);
  }

  static int power(int x, int n) {
    int retval = 1;
    for (int i = 0; i < n; i++) {
      retval *= x;
    }
    return retval;
  }

  static int get customTipIndex => AppConstants.tips.indexOf('custom');
  static int get noTipIndex => AppConstants.tips.indexOf('0');

  // The remembered pick is stored as the tip itself, never its row position, so
  // reordering the row cannot leave an old pick sitting on a different tip.
  static String tipToSave(int index) => (index >= 0 && index < AppConstants.tips.length)
      ? AppConstants.tips[index] : AppConstants.tips[noTipIndex];

  static int tipIndexFromSaved(String saved) {
    final int index = AppConstants.tips.indexOf(saved);
    return index == -1 ? noTipIndex : index;
  }

}