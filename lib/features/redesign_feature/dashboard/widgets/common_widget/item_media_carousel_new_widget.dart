import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/item/widgets/item_image_view_widget.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ItemMediaCarouselNewWidget extends StatefulWidget {
  final Item item;
  final bool isCampaign;
  final double mainHeight;
  final bool showThumbnails;
  const ItemMediaCarouselNewWidget({super.key, required this.item, this.isCampaign = false, required this.mainHeight, this.showThumbnails = true});

  static const double thumbStripHeight = 66;

  static void stopAllVideo() => ItemImageViewWidget.stopAllVideo();

  static bool isYoutubeUrl(String url) => url.contains('youtube.com') || url.contains('youtu.be');

  static bool isVideoMedia(String url) {
    final String s = url.toLowerCase();
    return isYoutubeUrl(s) || s.endsWith('.mp4') || s.endsWith('.mov') || s.endsWith('.m4v') || s.endsWith('.webm') || s.endsWith('.mkv');
  }

  static String? getVideoUrl(Item item) {
    if(item.videoEmbedUrl?.isNotEmpty == true) return item.videoEmbedUrl;
    if(item.videoLink?.isNotEmpty == true) return item.videoLink;
    if(item.videoFullUrl?.isNotEmpty == true) return item.videoFullUrl;
    if(item.videoPreviewUrl?.isNotEmpty == true) return item.videoPreviewUrl;
    return null;
  }

  static List<String> getMediaList(Item item, {bool isCampaign = false}) {
    final List<String> mediaList = [];
    final String? videoUrl = getVideoUrl(item);
    if(videoUrl != null && videoUrl.isNotEmpty) mediaList.add(videoUrl);
    if(item.imageFullUrl?.isNotEmpty == true) mediaList.add(item.imageFullUrl!);
    if(!isCampaign && item.imagesFullUrl != null && item.imagesFullUrl!.isNotEmpty) {
      mediaList.addAll(item.imagesFullUrl!.where((u) => u.isNotEmpty));
    }
    return mediaList;
  }

  static String thumbnailUrl(Item item, String mediaUrl, List<String> mediaList) {
    if(item.videoThumbnailUrl?.isNotEmpty == true && isVideoMedia(mediaUrl)) return item.storeImageFullUrl??'';
    if(isYoutubeUrl(mediaUrl)) {
      final String? id = YoutubePlayer.convertUrlToId(mediaUrl);
      if(id != null && id.isNotEmpty) return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
    }
    if(!isVideoMedia(mediaUrl)) return mediaUrl;
    for(final String m in mediaList) {
      if(m.isNotEmpty && !isVideoMedia(m)) return m;
    }
    return item.imageFullUrl ?? '';
  }

  @override
  State<ItemMediaCarouselNewWidget> createState() => _ItemMediaCarouselNewWidgetState();
}

class _ItemMediaCarouselNewWidgetState extends State<ItemMediaCarouselNewWidget> {
  // Drives the swipeable image slider (and lets thumbnail taps jump pages).
  final CarouselSliderController _carouselController = CarouselSliderController();
  // The page the carousel is actually showing — used to avoid animating back to
  // a page the user just swiped to.
  int _currentPage = 0;

  void _syncCarousel(int targetIndex) {
    if(targetIndex == _currentPage) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(!mounted || targetIndex == _currentPage) return;
      try {
        _carouselController.animateToPage(targetIndex, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<String> mediaList = ItemMediaCarouselNewWidget.getMediaList(widget.item, isCampaign: widget.isCampaign);
    final double sliderHeight = widget.mainHeight + MediaQuery.of(context).padding.top;

    return GetBuilder<ItemController>(builder: (controller) {
      final int currentIndex = mediaList.isNotEmpty && controller.imageSliderIndex < mediaList.length ? controller.imageSliderIndex : 0;
      // Keep the slider in sync when the page changes from outside (thumbnail tap).
      _syncCarousel(currentIndex);

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          height: sliderHeight,
          width: double.infinity,
          child: mediaList.isNotEmpty ? CarouselSlider.builder(
            carouselController: _carouselController,
            itemCount: mediaList.length,
            options: CarouselOptions(
              height: sliderHeight,
              viewportFraction: 1,
              enableInfiniteScroll: false,
              autoPlay: false,
              initialPage: currentIndex,
              onPageChanged: (i, reason) {
                _currentPage = i;
                // Only a user swipe should push the index back to the controller;
                // programmatic jumps already came from the controller.
                if(reason == CarouselPageChangedReason.manual) {
                  controller.setImageSliderIndex(i);
                }
              },
            ),
            itemBuilder: (context, i, _) {
              final String url = mediaList[i];
              return ItemMediaCarouselNewWidget.isVideoMedia(url) ? ItemMediaPreviewWidget(
                mediaUrl: url,
                thumbnailUrl: ItemMediaCarouselNewWidget.thumbnailUrl(widget.item, url, mediaList),
                width: MediaQuery.of(context).size.width,
                height: widget.mainHeight,
                isDesktop: false,
              ) : CustomImage(image: url, height: widget.mainHeight, width: double.infinity, fit: BoxFit.cover);
            },
          ) : CustomImage(image: '', height: widget.mainHeight, width: double.infinity, fit: BoxFit.cover),
        ),

        if(widget.showThumbnails && mediaList.length > 1) MediaThumbStripWidget(
          item: widget.item, isCampaign: widget.isCampaign,
        ),
      ]);
    });
  }
}

class MediaThumbStripWidget extends StatelessWidget {
  final Item item;
  final bool isCampaign;
  const MediaThumbStripWidget({super.key, required this.item, this.isCampaign = false});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ItemController>(builder: (controller) {
      final List<String> mediaList = ItemMediaCarouselNewWidget.getMediaList(item, isCampaign: isCampaign);
      if(mediaList.length < 2) return const SizedBox.shrink();
      final int currentIndex = controller.imageSliderIndex < mediaList.length ? controller.imageSliderIndex : 0;

      return Container(
        height: ItemMediaCarouselNewWidget.thumbStripHeight,
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall, top: Dimensions.paddingSizeSmall),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: mediaList.length,
          separatorBuilder: (context, index) => const SizedBox(width: Dimensions.paddingSizeSmall),
          itemBuilder: (context, i) {
            final String url = mediaList[i];
            final bool isSelected = i == currentIndex;
            final String thumbUrl = ItemMediaCarouselNewWidget.isVideoMedia(url)
                ? ItemMediaCarouselNewWidget.thumbnailUrl(item, url, mediaList) : url;
            return GestureDetector(
              onTap: () => controller.setImageSliderIndex(i),
              child: Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  border: Border.all(
                    color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault - 2),
                  child: Stack(fit: StackFit.expand, children: [
                    CustomImage(image: thumbUrl, fit: BoxFit.cover, width: 60, height: 60),
                    if(ItemMediaCarouselNewWidget.isVideoMedia(url)) Container(
                      color: Colors.black.withValues(alpha: 0.35),
                      alignment: Alignment.center,
                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 22),
                    ),
                  ]),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
