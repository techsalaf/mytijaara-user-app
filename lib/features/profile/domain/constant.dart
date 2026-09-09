import 'package:flutter/material.dart';

class ProfileMockData {
  ProfileMockData._();

  static const double rating = 4.5;
}

class ProfileMenuItem {
  final String titleKey;
  final String iconAsset;
  final String? route;
  final VoidCallback? onTap;
  final Color? color;

  const ProfileMenuItem({
    required this.titleKey,
    required this.iconAsset,
    this.route,
    this.onTap,
    this.color,
  });
}
