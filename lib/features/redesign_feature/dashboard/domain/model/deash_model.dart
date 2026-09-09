class TrendingDishData {
  final String storeName;
  final String title;
  final String currentPrice;
  final String previousPrice;
  final String? discountLabel;
  final String imagePath;
  final String? phrmaName;
  final String? packData;
  final String? packType;
  final bool? freeDelivery;

  const TrendingDishData({
    required this.storeName,
    required this.title,
    required this.currentPrice,
    required this.previousPrice,
    this.discountLabel,
    required this.imagePath,
    this.freeDelivery, this.phrmaName, this.packData, this.packType,
  });
}
