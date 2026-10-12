import 'package:flutter/material.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/helper/image_cache_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class BogoItemGroupWidget extends StatelessWidget {
  final String label;
  final List<String> thumbnails;
  final bool isGlobalCart;
  const BogoItemGroupWidget({super.key, required this.label, required this.thumbnails, this.isGlobalCart = false});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
      const SizedBox(height: Dimensions.paddingSizeSmall-3),

      BogoThumbCluster(images: thumbnails.isEmpty ? const <String>[''] : thumbnails),
    ]);
  }
}
class BogoThumbCluster extends StatelessWidget {
  final List<String> images;
    final bool isGlobalCart;
  const BogoThumbCluster({super.key, required this.images, this.isGlobalCart = false});

  static const int _maxVisible = 2;
  static const double _thumbSize = 48;
  static const double _overlap = 34;
  static const double _radius = 8;

  @override
  Widget build(BuildContext context) {
    if(images.isEmpty) return const SizedBox.shrink();
    final int visible = images.length > _maxVisible ? _maxVisible : images.length;
    final int extra = images.length - visible;
    final double stripWidth = _thumbSize + (visible - 1) * _overlap + (extra > 0 ? _overlap : 0);

    return SizedBox(
      height: _thumbSize,
      child: Stack(children: <Widget>[
        for(int i = 0; i < visible; i++)
          Positioned(
            left: i * _overlap,
            child: _RoundThumb(imageUrl: images[i]),
          ),
        if(extra > 0)
          Positioned(
            left: visible * _overlap + Dimensions.paddingSizeExtraSmall,
            child: Container(
              height: _thumbSize, width: _thumbSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isGlobalCart ? Theme.of(context).scaffoldBackgroundColor : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(_radius),
              ),
              child: Text(
                '+$extra',
                style: robotoBold.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
          ),
        SizedBox(width: stripWidth),
      ]),
    );
  }
}

class _RoundThumb extends StatelessWidget {
  final String imageUrl;
  const _RoundThumb({required this.imageUrl});

  static const double _size = BogoThumbCluster._thumbSize;
  static const double _radius = BogoThumbCluster._radius;
  static const double _borderWidth = 2;

  static const double _innerSize = _size - (_borderWidth * 2);
  static const double _innerRadius = _radius - _borderWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _size, width: _size,
      padding: const EdgeInsets.all(_borderWidth),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(_radius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_innerRadius),
        child: SizedBox(
          height: _innerSize, width: _innerSize,
          child: CustomImage(
            image: imageUrl, width: _innerSize, fit: BoxFit.cover, placeholder: Images.placeholder,
            cacheWidth: ImageCacheHelper.pixels(context, _innerSize),
          ),
        ),
      ),
    );
  }
}
