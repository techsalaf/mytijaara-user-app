
import 'package:flutter/material.dart';

class FoodModuleTopPickOfferChipData {
  final String label;
  final IconData? icon;

  const FoodModuleTopPickOfferChipData({
    required this.label,
    this.icon,
  });
}

class TopPickImageBadgeData {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final Color? borderColor;

  const TopPickImageBadgeData({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    this.borderColor,
  });
}
