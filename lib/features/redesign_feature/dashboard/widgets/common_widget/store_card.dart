
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class StoreCard extends StatelessWidget {
  final Store store;
  final double width;

  const StoreCard({super.key, required this.store, required this.width});
  final showItemStackCount = 3;

  @override
  Widget build(BuildContext context) {
    final Color surfaceColor = Theme.of(context).cardColor;
    final Color titleColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final Color subtitleColor = Theme.of(context).hintColor;

    final List<String> previewItems = store.storeItemImageList?.whereType<String>().toList() ?? const <String>[];

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  offset: Offset(0, 5),
                  blurRadius: 5,
                  color: Colors.black.withAlpha(30),
                ),
              ],
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              child: SizedBox(
                height: 150,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Opacity(
                      opacity: 0.88,
                      child: CustomImage(image: store.coverPhotoFullUrl ?? '', fit: BoxFit.cover,),
                    ),
                    Center(
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          size: 30,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                top: Dimensions.paddingSizeSmall,
                left: Dimensions.paddingSizeDefault,
                right: Dimensions.paddingSizeDefault,
                bottom: Dimensions.paddingSizeDefault,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.name ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: titleColor,),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            store.description ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeExtraSmall,
                              color: subtitleColor,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: surfaceColor,
                        border: Border.all(color: Theme.of(context).disabledColor.withAlpha(100),),
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        color: Color(0xFFEF5350),
                        size: 20,
                      ),
                    ),
                  ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Column(crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  Row(children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Color(0xFFFFB800),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      (store.avgRating ?? 0).toStringAsFixed(1),
                                      style: robotoBold.copyWith(
                                        fontSize: Dimensions.fontSizeSmall,
                                        color: titleColor,
                                      ),
                                    ),
                                  ],),
                                  const SizedBox(width: 8),

                                  Text(
                                    '${store.ratingCount ?? 0}+ ${'reviews'.tr}',
                                    overflow: TextOverflow.ellipsis,
                                    style: robotoSemiBold.copyWith(
                                      fontSize: Dimensions.fontSizeExtraSmall,
                                      color: subtitleColor,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(width: Dimensions.paddingSizeSmall),
                              Container(width: 1, color: Theme.of(context).disabledColor.withAlpha(100),),
                              const SizedBox(width: Dimensions.paddingSizeSmall),

                              Expanded(
                                child: Center(
                                  child: Row(
                                    children: [
                                      Expanded(child: Row(
                                        children: [
                                          Flexible(child: _ItemsPreviewStack(items: (previewItems.length > showItemStackCount) ?  previewItems.getRange(0, showItemStackCount).toList() : previewItems)),

                                          if(previewItems.length > showItemStackCount) ...[
                                            const SizedBox(width: Dimensions.paddingSizeExtraSmall,),
                                            Text(
                                              '+ ${previewItems.length - showItemStackCount}',
                                              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: subtitleColor,),
                                            ),
                                          ],
                                        ],
                                      )),

                                      SizedBox(width: Dimensions.paddingSizeExtraSmall,),

                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall,),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor,
                                          borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                                        ),
                                        child: Text(
                                          'see_menu'.tr,
                                          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.white,),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemsPreviewStack extends StatelessWidget {
  final List<String> items;

  const _ItemsPreviewStack({required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 31.5,
      width: (items.length * 25) + 5,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: List.generate(items.length, (index) {
          return Positioned(
            left: index * 25,
            child: Padding(
              padding: EdgeInsets.only(bottom: 2),
              child: Container(
                height: 30, width: 30,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).cardColor, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        offset: Offset(0, 1),
                        blurRadius: 1,
                        color: Theme.of(context).textTheme.bodyLarge!.color!.withAlpha(50),
                      )
                    ]
                ),
                child: ClipOval(child: CustomImage(image: items[index], height: 26, width: 26, fit: BoxFit.cover,)),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// Localization keys used in this file:
// 'reviews' -> already exists in language files
// 'see_menu' -> add to assets/language/en.json, ar.json, bn.json, es.json
