import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class HomeNewFeaturedStoresWidget extends StatelessWidget {
  const HomeNewFeaturedStoresWidget({super.key});

  static const List<_FeaturedStoreData> _stores = [
    _FeaturedStoreData(
      name: 'Mohammadia Varieties Store',
      rating: 4.5,
      ratingCount: 150,
      deliveryTime: '20-30 min',
      distance: '3.2 km',
      price: '\$5.99',
      discount: '30%',
      offer: '10%  Buy 1 Get 1 Free',
      isPopular: true,
      imageUrl: 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=400',
    ),
    _FeaturedStoreData(
      name: 'Mohammadia Restaurant',
      rating: 4.7,
      ratingCount: 220,
      deliveryTime: '20-30 min',
      distance: '2.5 km',
      price: '\$4.99',
      discount: '20%',
      offer: '15%  Free Drink',
      isPopular: true,
      imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400',
    ),
    _FeaturedStoreData(
      name: 'Pizza Palace',
      rating: 4.3,
      ratingCount: 98,
      deliveryTime: '25-35 min',
      distance: '4.1 km',
      price: '\$6.50',
      discount: '25%',
      offer: '10%  Combo Deal',
      isPopular: false,
      imageUrl: 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=400',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
            child: TitleWidget(
              title: 'Featured Stores & Restaurants',
              onTap: () => Get.toNamed(RouteHelper.getAllStoreRoute('popular')),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
              itemCount: _stores.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall, bottom: 4),
                  child: _FeaturedStoreCard(store: _stores[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedStoreData {
  final String name;
  final double rating;
  final int ratingCount;
  final String deliveryTime;
  final String distance;
  final String price;
  final String discount;
  final String offer;
  final bool isPopular;
  final String imageUrl;

  const _FeaturedStoreData({
    required this.name,
    required this.rating,
    required this.ratingCount,
    required this.deliveryTime,
    required this.distance,
    required this.price,
    required this.discount,
    required this.offer,
    required this.isPopular,
    required this.imageUrl,
  });
}

class _FeaturedStoreCard extends StatelessWidget {
  final _FeaturedStoreData store;
  const _FeaturedStoreCard({required this.store});

  @override
  Widget build(BuildContext context) {
    return CustomInkWell(
      onTap: () => Get.toNamed(RouteHelper.getAllStoreRoute('popular')),
      radius: Dimensions.radiusDefault,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.15),
              blurRadius: 6,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusDefault)),
                  child: CustomImage(
                    image: store.imageUrl,
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

                Positioned(
                  top: Dimensions.paddingSizeExtraSmall,
                  left: Dimensions.paddingSizeExtraSmall,
                  child: Row(
                    children: [
                      if (store.isPopular)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_fire_department, color: Colors.white, size: 10),
                              const SizedBox(width: 2),
                              Text(
                                'Pop',
                                style: robotoMedium.copyWith(color: Colors.white, fontSize: 9),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF43A047),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          store.discount,
                          style: robotoMedium.copyWith(color: Colors.white, fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                ),

                Positioned(
                  top: Dimensions.paddingSizeExtraSmall,
                  right: Dimensions.paddingSizeExtraSmall,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.favorite_border,
                      size: 14,
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          store.name,
                          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.star_rounded, color: Colors.orange, size: 13),
                      const SizedBox(width: 2),
                      Text(
                        store.rating.toStringAsFixed(1),
                        style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '(${store.ratingCount})',
                        style: robotoRegular.copyWith(
                          fontSize: 10,
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 12, color: Theme.of(context).disabledColor),
                      const SizedBox(width: 3),
                      Text(
                        store.deliveryTime,
                        style: robotoRegular.copyWith(
                          fontSize: 10,
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${store.distance})',
                        style: robotoRegular.copyWith(
                          fontSize: 10,
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        store.price,
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).textTheme.bodyLarge!.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF3E0),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(Dimensions.radiusDefault)),
              ),
              child: Text(
                store.offer,
                style: robotoMedium.copyWith(
                  fontSize: 10,
                  color: const Color(0xFFE53935),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
