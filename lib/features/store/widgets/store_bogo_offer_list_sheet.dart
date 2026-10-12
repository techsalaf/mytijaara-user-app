import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/no_data_screen.dart';
import 'package:sixam_mart/features/bogo_offer/domain/models/bogo_offer_model.dart';
import 'package:sixam_mart/features/bogo_offer/widgets/bogo_bundle_price_text.dart';
import 'package:sixam_mart/features/bogo_offer/widgets/bogo_full_screen_sheet.dart';
import 'package:sixam_mart/features/bogo_offer/widgets/bogo_offer_details_bottom_sheet.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class StoreBogoOfferListSheet extends StatelessWidget {
  final List<StoreBogoOfferModel> offers;
  const StoreBogoOfferListSheet({super.key, required this.offers});

  static Future<void> show(BuildContext context, {required List<StoreBogoOfferModel> offers}) {
    return BogoFullScreenSheet.show(context, child: StoreBogoOfferListSheet(offers: offers));
  }

  @override
  Widget build(BuildContext context) {
    return BogoFullScreenSheet(
      title: 'bogo_offer_list'.tr,
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          sliver: offers.isEmpty
            ? SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: NoDataScreen(text: 'no_offer_found'.tr, isNotScrollable: true)),
              )
            : SliverList.separated(
                itemCount: offers.length,
                separatorBuilder: (BuildContext context, int index) => const SizedBox(height: Dimensions.paddingSizeDefault),
                itemBuilder: (BuildContext context, int index) => _StoreBogoOfferTile(item: offers[index]),
              ),
        ),
      ],
    );
  }
}

class _StoreBogoOfferTile extends StatelessWidget {
  final StoreBogoOfferModel item;
  const _StoreBogoOfferTile({required this.item});

  static const double _innerMargin = 5;

  void _openBundle(BuildContext context) {
    if(item.bundle.bundleId == null) {
      return;
    }
    BogoOfferDetailsBottomSheet.show(
      context,
      bundle: item.bundle, offerTitle: item.offer.title, offerLabel: item.offer.offerLabel, validUntil: item.offer.validUntil,
      remainingUses: item.offer.remainingUses,
    );
  }

  @override
  Widget build(BuildContext context) {
    final BogoOfferCardModel offer = item.offer;
    final BogoBundleModel bundle = item.bundle;
    final int buyCount = bundle.buyCount ?? offer.buyQty ?? bundle.buyItems.length;
    final int getCount = bundle.getCount ?? offer.getQty ?? bundle.freeItems.length;


    return GestureDetector(
      onTap: () => _openBundle(context),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[

          if(offer.imageFullUrl != null && offer.imageFullUrl!.isNotEmpty) Padding(
            padding: const EdgeInsets.fromLTRB(_innerMargin, _innerMargin, _innerMargin, 0),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusLarge)),
              child: Stack(children: <Widget>[
                AspectRatio(
                  aspectRatio: 2.8,
                  child: CustomImage(image: offer.imageFullUrl!, fit: BoxFit.fill, placeholder: Images.placeholder),
                ),

                // Fades the banner into the white block below it, so the two read as one card.
                Positioned(
                  left: 0, right: 0, bottom: 0,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: <Color>[
                          Theme.of(context).cardColor,
                          Theme.of(context).cardColor.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: _innerMargin),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(Dimensions.radiusLarge)),
            ),
            padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault, bottom: Dimensions.paddingSizeSmall),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: <Widget>[
                  Text(offer.title ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge)),
                        
                  if(offer.validUntil != null && offer.validUntil!.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Text('${'validity'.tr} : ${offer.validUntil}', maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
                  ],
                ]),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
                        
              BogoBundlePriceText(
                bundlePrice: bundle.bundlePrice,
                fontSize: Dimensions.fontSizeExtraLarge,
              ),
            ]),
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall,
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: <Widget>[
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _LabelledCluster(
                    items: bundle.buyItems,
                    label: 'buy_count_item'.trParams(<String, String>{'count': '$buyCount'}),
                  ),
                ),
              ),

              Icon(
                Directionality.of(context) == TextDirection.ltr ? Icons.arrow_forward : Icons.arrow_back,
                size: 20, color: Theme.of(context).hintColor,
              ),

              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _LabelledCluster(
                    items: bundle.freeItems,
                    label: 'get_count_free'.trParams(<String, String>{'count': '$getCount'}),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        ]),
      ),
    );
  }
}

class _LabelledCluster extends StatelessWidget {
  final List<BogoOfferItemModel> items;
  final String label;

  const _LabelledCluster({required this.items, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
      _OverlappingImageCluster(items: items),
      const SizedBox(height: Dimensions.paddingSizeExtraSmall),

      Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
    ]);
  }
}

/// Circular thumbnails laid over one another, the remainder as a `+N` circle.
class _OverlappingImageCluster extends StatelessWidget {
  final List<BogoOfferItemModel> items;

  const _OverlappingImageCluster({required this.items});

  static const double _size = 44;
  static const double _borderWidth = 2;
  static const double _innerSize = _size - (_borderWidth * 2);
  static const int _maxVisible = 3;
  static const double _overlap = 14;
  static const double _step = _size - _overlap;

  @override
  Widget build(BuildContext context) {
    if(items.isEmpty) {
      return const SizedBox(height: _size, width: _size);
    }

    final int visibleCount = items.length > _maxVisible ? _maxVisible : items.length;
    final int overflowCount = items.length - visibleCount;
    final int circleCount = visibleCount + (overflowCount > 0 ? 1 : 0);

    return SizedBox(
      height: _size,
      width: _size + (circleCount - 1) * _step,
      child: Stack(children: <Widget>[
        for(int index = 0; index < visibleCount; index++)
          Positioned(
            left: index * _step,
            child: _ClusterCircle(child: CustomImage(
              image: items[index].item.imageFullUrl ?? '',
              height: _innerSize, width: _innerSize, fit: BoxFit.cover, placeholder: Images.placeholder,
            )),
          ),

        if(overflowCount > 0) Positioned(
          left: visibleCount * _step,
          child: _ClusterCircle(
            child: Center(child: Text('+$overflowCount', style: robotoBold.copyWith(
              fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge!.color))),
          ),
        ),
      ]),
    );
  }
}

class _ClusterCircle extends StatelessWidget {
  final Widget child;
  const _ClusterCircle({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _OverlappingImageCluster._size,
      width: _OverlappingImageCluster._size,
      padding: const EdgeInsets.all(_OverlappingImageCluster._borderWidth),
      decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).cardColor),
      child: ClipOval(
        child: SizedBox(
          height: _OverlappingImageCluster._innerSize,
          width: _OverlappingImageCluster._innerSize,
          child: ColoredBox(color: Theme.of(context).cardColor, child: child),
        ),
      ),
    );
  }
}
