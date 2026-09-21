import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class ImageGalleryDialog extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  const ImageGalleryDialog({super.key, required this.images, this.initialIndex = 0});

  @override
  State<ImageGalleryDialog> createState() => _ImageGalleryDialogState();
}

class _ImageGalleryDialogState extends State<ImageGalleryDialog> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.images.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: Row(children: [
              Expanded(
                child: Text(
                  widget.images.length > 1 ? '${_currentIndex + 1}/${widget.images.length}' : 'image'.tr,
                  style: robotoMedium.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeLarge),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Get.back(),
              ),
            ]),
          ),

          Expanded(
            child: Stack(clipBehavior: Clip.none, children: [
              PhotoViewGallery.builder(
                scrollPhysics: const BouncingScrollPhysics(),
                backgroundDecoration: const BoxDecoration(color: Colors.transparent),
                itemCount: widget.images.length,
                pageController: _pageController,
                builder: (BuildContext context, int index) => PhotoViewGalleryPageOptions(
                  imageProvider: kIsWeb ? NetworkImage('${AppConstants.baseUrl}/image-proxy?url=${widget.images[index]}') : NetworkImage(widget.images[index]),
                  initialScale: PhotoViewComputedScale.contained,
                ),
                onPageChanged: (int index) => setState(() => _currentIndex = index),
              ),

              if (widget.images.length > 1 && _currentIndex != 0)
                Positioned(
                  left: 12, top: 0, bottom: 0,
                  child: Center(
                    child: InkWell(
                      onTap: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                      child: Container(
                        height: 40, width: 40,
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                        child: const Icon(Icons.keyboard_arrow_left, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                ),

              if (widget.images.length > 1 && _currentIndex != widget.images.length - 1)
                Positioned(
                  right: 12, top: 0, bottom: 0,
                  child: Center(
                    child: InkWell(
                      onTap: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                      child: Container(
                        height: 40, width: 40,
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                        child: const Icon(Icons.keyboard_arrow_right, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}
