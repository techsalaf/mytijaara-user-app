
import 'package:flutter/cupertino.dart';

class FoodModuleExploreRestaurantData {
  final String title;
  final String cuisineLabel;
  final String imagePath;
  final double rating;
  final int reviewCount;
  final String deliveryTime;
  final String distanceLabel;
  final String deliveryFee;
  final String badgeLabel;
  final String badgeHighlight;
  final Color imageOverlayColor;
  final List<FoodModuleExploreRestaurantOfferData> offers;
  final bool showPromotionalBadge;

  const FoodModuleExploreRestaurantData({
    required this.title,
    required this.cuisineLabel,
    required this.imagePath,
    required this.rating,
    required this.reviewCount,
    required this.deliveryTime,
    required this.distanceLabel,
    required this.deliveryFee,
    required this.badgeLabel,
    required this.badgeHighlight,
    required this.imageOverlayColor,
    this.offers = const <FoodModuleExploreRestaurantOfferData>[],
    this.showPromotionalBadge = true,
  });
}

class FoodModuleExploreRestaurantOfferData{
  final IconData? icon;
  final String label;
  const FoodModuleExploreRestaurantOfferData({this.icon, required this.label});
}
