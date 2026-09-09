import 'package:carousel_slider/carousel_slider.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/widgets/custom_favourite_widget.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/home/controllers/advertisement_controller.dart';
import 'package:sixam_mart/features/home/domain/models/advertisement_model.dart';
import 'package:sixam_mart/features/home/widgets/highlight_widget.dart' show AdvertisementIndicator;
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/store/screens/store_screen.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:video_player/video_player.dart';

class FeaturedRestaurant extends StatefulWidget {
  final bool isShop;

  const FeaturedRestaurant({super.key, this.isShop = false});

  @override
  State<FeaturedRestaurant> createState() => _FeaturedRestaurantState();
}

class _FeaturedRestaurantState extends State<FeaturedRestaurant> {
  static const double _cardHeight = 280;

  final CarouselSliderController _carouselController = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    final double cardWidth = MediaQuery.sizeOf(context).width * 0.75;

    return GetBuilder<AdvertisementController>(builder: (advertisementController) {
      final List<AdvertisementModel>? list = advertisementController.advertisementList;

      if(list == null) {
        return _FeaturedShimmer(cardWidth: cardWidth, cardHeight: _cardHeight);
      }
      if(list.isEmpty) {
        return const SizedBox.shrink();
      }

      return _SectionFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(isShop: widget.isShop,),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            CarouselSlider.builder(
              carouselController: _carouselController,
              itemCount: list.length,
              options: CarouselOptions(
                enableInfiniteScroll: list.length > 1,
                autoPlay: advertisementController.autoPlay,
                autoPlayInterval: advertisementController.autoPlayDuration,
                enlargeCenterPage: false,
                viewportFraction: 1,
                disableCenter: true,
                height: _cardHeight + 40,
                onPageChanged: (index, reason) {
                  advertisementController.setCurrentIndex(index, true);
                  advertisementController.updateAutoPlayStatus(
                    status: list[index].addType != 'video_promotion',
                  );
                },
              ),
              itemBuilder: (context, index, realIndex) {
                final AdvertisementModel ad = list[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
                  child: _AdCard(advertisement: ad),
                );
              },
            ),

            const AdvertisementIndicator(),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          ],
        ),
      );
    });
  }
}

class _SectionFrame extends StatelessWidget {
  final Widget child;
  const _SectionFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: const Color(0xFFDBE9FF).withValues(alpha: 0.7),
        borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusDefault)),
        image: const DecorationImage(image: AssetImage(Images.advertisementBg, ), fit: BoxFit.fitHeight),
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final bool isShop;
  const _SectionHeader({required this.isShop});


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TitleWidget(title: Get.find<SplashController>().module?.moduleType?.toString() == AppConstants.food
                    ? 'featured_restaurants'.tr : 'featured_stores'.tr),

                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).disabledColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall, vertical: 2),
                  child: Text(
                    'sponsored'.tr,
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall,
                      color: Theme.of(context).textTheme.bodyLarge?.color?.withAlpha(150),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Image.asset(Images.mikeImage, height: 40, width: 40),
        ],
      ),
    );
  }
}

void _openStore(int? storeId) {
  Get.toNamed(
    RouteHelper.getStoreRoute(id: storeId, page: 'store_new', slug: 'store_$storeId'),
    arguments: StoreScreen(store: Store(id: storeId), fromModule: false),
  );
}

class _AdCard extends StatelessWidget {
  final AdvertisementModel advertisement;
  const _AdCard({required this.advertisement});

  @override
  Widget build(BuildContext context) {
    final bool isVideo = advertisement.addType == 'video_promotion';
    return _AdCardChrome(
      onTap: () => _openStore(advertisement.storeId),
      media: isVideo
          ? _AdVideoMedia(advertisement: advertisement)
          : _AdImageMedia(advertisement: advertisement),
      info: _AdCardInfo(advertisement: advertisement),
    );
  }
}

class _AdCardChrome extends StatelessWidget {
  final Widget media;
  final Widget info;
  final VoidCallback onTap;
  const _AdCardChrome({required this.media, required this.info, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(offset: const Offset(0, 5), blurRadius: 5, color: Colors.black.withAlpha(30)),
                ],
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                child: SizedBox(
                  height: 150,
                  child: media,
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: Dimensions.paddingSizeLarge,
                  left: Dimensions.paddingSizeDefault,
                  right: Dimensions.paddingSizeDefault,
                  bottom: Dimensions.paddingSizeDefault,
                ),
                child: info,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdImageMedia extends StatelessWidget {
  final AdvertisementModel advertisement;
  const _AdImageMedia({required this.advertisement});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: 0.88,
          child: CustomImage(image: advertisement.coverImageFullUrl ?? '', fit: BoxFit.cover),
        ),

        // if(advertisement.isRatingActive == 1 || advertisement.isReviewActive == 1) Positioned(
        //   right: 10,
        //   bottom: 10,
        //   child: Container(
        //     padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 4),
        //     decoration: BoxDecoration(
        //       color: Theme.of(context).primaryColor,
        //       borderRadius: BorderRadius.circular(50),
        //       border: Border.all(color: Theme.of(context).cardColor, width: 2),
        //       boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
        //     ),
        //     child: Row(mainAxisSize: MainAxisSize.min, children: [
        //       if(advertisement.isRatingActive == 1) ...[
        //         Icon(Icons.star, color: Theme.of(context).cardColor, size: 14),
        //         const SizedBox(width: 4),
        //         Text(
        //           advertisement.averageRating?.toStringAsFixed(1) ?? '0.0',
        //           style: robotoBold.copyWith(color: Theme.of(context).cardColor, fontSize: Dimensions.fontSizeSmall),
        //         ),
        //         if(advertisement.isReviewActive == 1) const SizedBox(width: 4),
        //       ],
        //       if(advertisement.isReviewActive == 1) Text(
        //         '(${advertisement.reviewsCommentsCount ?? 0})',
        //         style: robotoRegular.copyWith(color: Theme.of(context).cardColor, fontSize: Dimensions.fontSizeSmall),
        //       ),
        //     ]),
        //   ),
        // ),
      ],
    );
  }
}

class _AdVideoMedia extends StatefulWidget {
  final AdvertisementModel advertisement;
  const _AdVideoMedia({required this.advertisement});

  @override
  State<_AdVideoMedia> createState() => _AdVideoMediaState();
}

class _AdVideoMediaState extends State<_AdVideoMedia> {
  late final VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(
      widget.advertisement.videoAttachmentFullUrl ?? '',
    ));

    _videoPlayerController.addListener(_onVideoTick);

    await _videoPlayerController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      aspectRatio: _videoPlayerController.value.aspectRatio,
    );
    _chewieController?.setVolume(0);

    if(mounted) setState(() {});
  }

  void _onVideoTick() {
    if(_videoPlayerController.value.duration == _videoPlayerController.value.position
        && _videoPlayerController.value.duration > Duration.zero) {
      if(GetPlatform.isWeb) {
        Future.delayed(const Duration(seconds: 4), () {
          Get.find<AdvertisementController>().updateAutoPlayStatus(status: true, shouldUpdate: true);
        });
      } else {
        Get.find<AdvertisementController>().updateAutoPlayStatus(status: true, shouldUpdate: true);
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerController.removeListener(_onVideoTick);
    _chewieController?.dispose();
    _videoPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
          ? Chewie(controller: _chewieController!)
          : const CircularProgressIndicator(),
    );
  }
}

class _AdCardInfo extends StatelessWidget {
  final AdvertisementModel advertisement;
  const _AdCardInfo({required this.advertisement});

  @override
  Widget build(BuildContext context) {
    final Color titleColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final Color subtitleColor = Theme.of(context).hintColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Text(
              advertisement.title ?? '',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: titleColor),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          GetBuilder<FavouriteController>(builder: (favouriteController) {
            final bool isWished = favouriteController.wishStoreIdList.contains(advertisement.storeId);
            return CustomFavouriteWidget(
              isWished: isWished, isStore: true, storeId: advertisement.storeId, size: 22,
            );
          }),
        ]),

        const SizedBox(height: 4),
        Text(
          advertisement.description ?? '',
          maxLines: 2, overflow: TextOverflow.ellipsis,
          style: robotoRegular.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: subtitleColor,
            height: 1.25,
          ),
        ),

        const Spacer(),

        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          if(advertisement.isRatingActive == 1) _RatingSummary(
            rating: advertisement.averageRating ?? 0,
            reviewCount: advertisement.isReviewActive == 1 ? (advertisement.reviewsCommentsCount ?? 0) : null,
            titleColor: titleColor, subtitleColor: subtitleColor,
          ),

          if(advertisement.isRatingActive == 1) Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
            child: Container(width: 1, height: 28, color: Theme.of(context).disabledColor.withAlpha(70)),
          ),

          Expanded(child: _TopItemsStack(items: advertisement.store?.topItems ?? const [], subtitleColor: subtitleColor)),

          const SizedBox(width: Dimensions.paddingSizeSmall),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
            child: Text(
              'see_menu'.tr,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.white),
            ),
          ),
        ]),
      ],
    );
  }
}

class _RatingSummary extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final Color titleColor;
  final Color subtitleColor;
  const _RatingSummary({required this.rating, required this.reviewCount, required this.titleColor, required this.subtitleColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 16),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: titleColor),
          ),
        ]),
        if(reviewCount != null) ...[
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              '$reviewCount+ ${'rev'.tr}',
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: subtitleColor),
            ),
          ),
        ],
      ],
    );
  }
}

class _TopItemsStack extends StatelessWidget {
  final List<TopItems> items;
  final Color subtitleColor;
  const _TopItemsStack({required this.items, required this.subtitleColor});

  static const int _maxVisible = 3;
  static const double _avatarSize = 26;
  static const double _avatarOverlap = 10;

  @override
  Widget build(BuildContext context) {
    if(items.isEmpty) return const SizedBox.shrink();

    final int visibleCount = items.length < _maxVisible ? items.length : _maxVisible;
    final int extraCount = items.length - visibleCount;
    final double stackWidth = _avatarSize + (visibleCount - 1) * (_avatarSize - _avatarOverlap);

    return Row(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: stackWidth, height: _avatarSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: List.generate(visibleCount, (i) {
            return Positioned(
              left: i * (_avatarSize - _avatarOverlap),
              child: Container(
                width: _avatarSize, height: _avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).cardColor, width: 1.5),
                ),
                child: ClipOval(
                  child: CustomImage(image: items[i].imageFullUrl ?? '', fit: BoxFit.cover),
                ),
              ),
            );
          }),
        ),
      ),
      if(extraCount > 0) ...[
        const SizedBox(width: 4),
        Text(
          '+$extraCount',
          style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: subtitleColor),
        ),
      ],
    ]);
  }
}

class _FeaturedShimmer extends StatelessWidget {
  final double cardWidth;
  final double cardHeight;
  const _FeaturedShimmer({required this.cardWidth, required this.cardHeight});

  @override
  Widget build(BuildContext context) {
    final Color shimmerColor = Theme.of(context).disabledColor.withAlpha(60);

    return _SectionFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(isShop: false,),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          Shimmer(
            duration: const Duration(seconds: 2),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
              height: cardHeight,
              decoration: BoxDecoration(
                color: shimmerColor,
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        ],
      ),
    );
  }
}
