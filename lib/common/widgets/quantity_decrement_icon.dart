import 'package:flutter/material.dart';
import 'package:sixam_mart/util/images.dart';

class QuantityDecrementIcon extends StatelessWidget {
  final int quantity;
  final double size;
  final Color? minusColor;
  final Color? deleteColor;

  const QuantityDecrementIcon({super.key, required this.quantity, this.size = 16, this.minusColor, this.deleteColor});

  @override
  Widget build(BuildContext context) {
    if (quantity <= 1) {
      return Image.asset(Images.delete, height: size, width: size, color: deleteColor ?? Theme.of(context).colorScheme.error);
    }
    return Icon(Icons.remove, size: size, color: minusColor ?? Theme.of(context).textTheme.bodyLarge?.color);
  }
}
