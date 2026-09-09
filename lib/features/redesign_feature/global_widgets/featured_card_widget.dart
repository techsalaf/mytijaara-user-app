import 'package:flutter/material.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/gaps.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class FeaturedCardWidget extends StatelessWidget {
  final double width;
  final String imageUrl;
  final String title;
  final String rating;
  final String reviewCount;
  final String deliveryTime;
  final String distance;
  final String? topLeftBadge;
  final String? topRightBadge;
  final String? bottomRightBadge;
  final List<String> tags;

  const FeaturedCardWidget({super.key, required this.width, required this.imageUrl, required this.title, required this.rating, required this.reviewCount,
    required this.deliveryTime, required this.distance, this.topLeftBadge, this.topRightBadge, this.bottomRightBadge, required this.tags});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(Dimensions.radiusLarge),),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          child: SizedBox(height: 156, width: width,
            child: Stack(children: <Widget>[
              Positioned.fill(child: CustomImage(image: imageUrl, placeholder: Images.placeholder)),
              Positioned(top: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall,
                child: Container(height: 28, width: 28,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.favorite_border, size: 18, color: Color(0xFFE84D4F)),
                ),
              ),
             if (topLeftBadge != null || topRightBadge != null)
              Positioned(left: Dimensions.paddingSizeSmall, bottom: Dimensions.paddingSizeSmall,
                child: Container(
                  decoration: BoxDecoration(color: Color(0xFF3F81EA), borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge)),
                  padding: EdgeInsets.all(3),
                  child: Row(children: <Widget>[
                    if (topLeftBadge != null)
                      _OverlayBadge(text: topLeftBadge!, backgroundColor: const Color(0xFFFFF4E8), textColor: const Color(0xFFEA8C21),
                          icon: Icons.star, iconColor: Theme.of(context).colorScheme.error),
                    if (topRightBadge != null)
                      _OverlayBadge(text: topRightBadge!, backgroundColor: const Color(0xFF3F81EA), textColor: Colors.white),
                  ]),
                ),
              ),
              if (bottomRightBadge != null)
                Positioned(right: Dimensions.paddingSizeSmall, bottom: Dimensions.paddingSizeSmall,
                  child: _OverlayBadge(text: bottomRightBadge!, textColor: Colors.white),
                ),
            ]),
          ),
        ),
        Row(children: [
          Expanded(
            flex: 10,
            child: Padding(
              padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall, left: Dimensions.paddingSizeExtraSmall),
              child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color,),
              ),
            ),
          ),
          Spacer(),
          Padding(
            padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeExtraSmall),
            child: Row(children: <Widget>[
              const Icon(Icons.star, size: 14, color: Color(0xFFF0A500)),
              Gaps.horizontalGapOf(4),
              Text(rating, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge?.color)),
              Gaps.horizontalGapOf(4),
              Text('($reviewCount)', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
              ),
            ]),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall, left: Dimensions.paddingSizeExtraSmall, right: Dimensions.paddingSizeExtraSmall),
          child: Row(children: <Widget>[
            Icon(Icons.access_time_filled, size: 14, color: Theme.of(context).disabledColor),
            Gaps.horizontalGapOf(4),
            Flexible(
              child: Text('$deliveryTime ($distance)', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall, left: Dimensions.paddingSizeExtraSmall, right: Dimensions.paddingSizeExtraSmall,),
          child: Wrap(spacing: Dimensions.paddingSizeExtraSmall, runSpacing: Dimensions.paddingSizeExtraSmall, children: tags.map((_TagData.new)).toList()),
        ),
      ]),
    );
  }
}

class _TagData extends StatelessWidget {
  final String label;

  const _TagData( this.label);

  @override
  Widget build(BuildContext context) {
    final _FeaturedTagConfig config = _FeaturedTagConfig.fromLabel(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall, vertical: Dimensions.paddingSizeExtraSmall),
      decoration: BoxDecoration(color: config.backgroundColor, borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge)),
      child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
        if (config.iconAsset != null) ...<Widget>[
          Image.asset(config.iconAsset!, height: Dimensions.fontSizeSmall, width: Dimensions.fontSizeSmall, color: config.iconColor,),
          Gaps.horizontalGapOf(4),
        ],
        Text(label, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: config.textColor,),
        ),
      ]),
    );
  }
}

class _FeaturedTagConfig {
  final String? iconAsset;
  final Color backgroundColor;
  final Color textColor;
  final Color? iconColor;

  const _FeaturedTagConfig({this.iconAsset, required this.backgroundColor, required this.textColor, this.iconColor});

  factory _FeaturedTagConfig.fromLabel(String label) {
    switch (label) {
      case 'Free':
        return const _FeaturedTagConfig(iconAsset: Images.freeDelivery, backgroundColor: Color(0xFFFFEFEE), textColor: Color(0xFFE84D4F), iconColor: Color(0xFFE84D4F));
      case 'Buy 1 Get 1 Free':
        return const _FeaturedTagConfig(iconAsset: Images.couponOfferIcon, backgroundColor: Color(0xFFFFEFEE), textColor: Color(0xFFE84D4F), iconColor: Color(0xFFE84D4F));
      default:
        return const _FeaturedTagConfig(backgroundColor: Color(0xFFFFEFEE), textColor: Color(0xFFE84D4F));
    }
  }
}

class _OverlayBadge extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color textColor;
  final IconData? icon;
  final Color? iconColor;

  const _OverlayBadge({required this.text, this.backgroundColor, required this.textColor, this.icon, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall, vertical: 4),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge)),
      child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon, size: 12, color: iconColor),
          Gaps.horizontalGapOf(3),
        ],
        Text(text,
          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeOverSmall, color: textColor),
        ),
      ]),
    );
  }
}
