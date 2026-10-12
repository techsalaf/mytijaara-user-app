import 'package:flutter/material.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/helper/image_cache_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class BundleThumbnailGridWidget extends StatelessWidget {
  final List<String> thumbnails;
  final int totalCount;
  final double size;
  final Widget? action;

  const BundleThumbnailGridWidget({super.key,
    required this.thumbnails, required this.totalCount, this.size = 132, this.action,
  });

  /// Everything scales off [size] so one card can serve the home strip and the
  /// cart tile without a second set of numbers.
  double get _panelPadding => Dimensions.paddingSizeSmall;
  double get _gap => Dimensions.paddingSizeExtraSmall;
  double get _tileRadius => size * 0.07;
  double get _imagePadding => size * 0.05;
  double get _chip => size * 0.20;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    /// A bundle with members but no pictures still draws its cells, so the
    /// layout reflects the real count instead of collapsing to one placeholder.
    final int cells = totalCount > 0 ? totalCount : (thumbnails.isEmpty ? 1 : thumbnails.length);
    final int shown = cells > 4 ? 4 : (cells < 1 ? 1 : cells);
    final int hidden = totalCount - shown;

    final double inner = size - (_panelPadding * 2);
    final double half = (inner - _gap) / 2;

    return SizedBox(
      width: size, height: size,
      child: Stack(clipBehavior: Clip.none, children: [

        Container(
          width: size, height: size,
          padding: EdgeInsets.all(_panelPadding),
          decoration: BoxDecoration(
            color: theme.disabledColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(size * 0.1),
          ),
          child: Stack(clipBehavior: Clip.none, children: [

            ..._tiles(shown: shown, half: half, inner: inner),

            /// Dead centre of the panel, over the seam where the tiles meet.
            if(hidden > 0)
              Positioned(
                left: (inner - _chip) / 2, top: (inner - _chip) / 2,
                child: _CountChip(hidden: hidden, size: _chip, radius: size * 0.05),
              ),
          ]),
        ),

        if(action != null)
          Positioned(right: _panelPadding, bottom: _panelPadding, child: action!),

      ]),
    );
  }

  List<Widget> _tiles({required int shown, required double half, required double inner}) {
    Widget tile({required double width, required double height, required int index}) => _Tile(
      width: width, height: height,
      image: index < thumbnails.length ? thumbnails[index] : '',
      radius: _tileRadius, padding: _imagePadding,
    );

    switch(shown) {
      case 1:
        return [tile(width: inner, height: inner, index: 0)];

      case 2:
        return [
          Positioned(left: 0, top: 0, child: tile(width: half, height: inner, index: 0)),
          Positioned(right: 0, top: 0, child: tile(width: half, height: inner, index: 1)),
        ];

      case 3:
        return [
          Positioned(left: 0, top: 0, child: tile(width: half, height: half, index: 0)),
          Positioned(left: 0, bottom: 0, child: tile(width: half, height: half, index: 1)),
          Positioned(right: 0, top: 0, child: tile(width: half, height: inner, index: 2)),
        ];

      default:
        return [
          Positioned(left: 0, top: 0, child: tile(width: half, height: half, index: 0)),
          Positioned(right: 0, top: 0, child: tile(width: half, height: half, index: 1)),
          Positioned(left: 0, bottom: 0, child: tile(width: half, height: half, index: 2)),
          Positioned(right: 0, bottom: 0, child: tile(width: half, height: half, index: 3)),
        ];
    }
  }
}

class _Tile extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final double padding;
  final String image;

  const _Tile({required this.width, required this.height, required this.radius, required this.padding, required this.image});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      height: height, width: width,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: theme.disabledColor.withAlpha(80)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CustomImage(image: image, fit: BoxFit.cover, cacheWidth: ImageCacheHelper.pixels(context, width)),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final int hidden;
  final double size;
  final double radius;
  const _CountChip({required this.hidden, required this.size, required this.radius});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      height: size, width: size,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 8)],
      ),
      alignment: Alignment.center,
      child: FittedBox(
        child: Padding(
          padding: EdgeInsets.all(size * 0.18),
          child: Text('+$hidden', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
        ),
      ),
    );
  }
}
