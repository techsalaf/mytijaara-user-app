class FoodItem {
  final String imageUrl;
  final String restaurantName;
  final String restaurantLogoUrl;
  final double rating;
  final String itemName;
  final double price;
  final double? originalPrice;
  final double? discountPercent;
  final bool isFreeDelivery;
  final bool isHalal;
  final bool isVeg;
  final bool isFavourited;

  const FoodItem({
    required this.imageUrl,
    required this.restaurantName,
    required this.restaurantLogoUrl,
    required this.rating,
    required this.itemName,
    required this.price,
    this.originalPrice,
    this.discountPercent,
    this.isFreeDelivery = false,
    this.isHalal = false,
    this.isVeg = false,
    this.isFavourited = false,
  });

  bool get hasDiscount {
    return discountPercent != null && discountPercent! > 0 && originalPrice != null;
  }
}
