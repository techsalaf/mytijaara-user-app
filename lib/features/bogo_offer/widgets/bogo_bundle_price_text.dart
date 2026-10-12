import 'package:flutter/material.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class BogoBundlePriceText extends StatelessWidget {
  final double? bundlePrice;
  final int quantity;
  final double? fontSize;
  final Color? color;

  const BogoBundlePriceText({super.key,
    this.bundlePrice, this.quantity = 1, this.fontSize, this.color,
  });

  @override
  Widget build(BuildContext context) {
    final double price = (bundlePrice ?? 0) * quantity;

    return Text(
      PriceConverter.convertPrice(price), textDirection: TextDirection.ltr,
      style: robotoBold.copyWith(fontSize: fontSize ?? Dimensions.fontSizeLarge, color: color),
    );
  }
}
