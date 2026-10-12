import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:sixam_mart/common/widgets/bogo_item_group_widget.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/order/domain/models/order_details_model.dart';
import 'package:sixam_mart/features/order/widgets/collapsible_header.dart';
import 'package:sixam_mart/helper/image_cache_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

const double _thumbSize = 52;

class ItemInfoSection extends StatefulWidget {
  final List<OrderDetailsModel> orderDetails;

  const ItemInfoSection({super.key, required this.orderDetails});

  @override
  State<ItemInfoSection> createState() => _ItemInfoSectionState();
}

class _ItemInfoSectionState extends State<ItemInfoSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      CollapsibleSectionHeader(
        title: '${'item_info'.tr} (${widget.orderDetails.length})',
        expanded: _expanded,
        onTap: () => setState(() => _expanded = !_expanded),
      ),

      AnimatedCrossFade(
        firstChild: const SizedBox(width: double.infinity),
        secondChild: Padding(
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeLarge),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (int i = 0; i < widget.orderDetails.length; i++) ...[
              _OrderItemRow(orderDetails: widget.orderDetails[i]),
              if (i != widget.orderDetails.length - 1)
                const SizedBox(height: Dimensions.paddingSizeExtraLarge),
            ],
          ]),
        ),
        crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 200),
      ),
    ]);
  }
}

class _OrderItemRow extends StatefulWidget {
  final OrderDetailsModel orderDetails;

  const _OrderItemRow({required this.orderDetails});

  @override
  State<_OrderItemRow> createState() => _OrderItemRowState();
}

class _OrderItemRowState extends State<_OrderItemRow> {
  bool _additionalExpanded = false;

  String _buildVariationText() {
    final od = widget.orderDetails;
    String text = '';

    if (od.variation != null && od.variation!.isNotEmpty) {
      final types = od.variation![0].type?.split('-') ?? const <String>[];
      final choices = od.itemDetails?.choiceOptions;
      if (choices != null && types.length == choices.length) {
        for (int i = 0; i < choices.length; i++) {
          text += '${i == 0 ? '' : ',  '}${choices[i].title} - ${types[i]}';
        }
      } else if (od.itemDetails?.variations != null && od.itemDetails!.variations!.isNotEmpty) {
        text = od.itemDetails!.variations![0].type ?? '';
      }
    }

    if (od.foodVariation != null && od.foodVariation!.isNotEmpty) {
      for (final fv in od.foodVariation!) {
        final values = fv.variationValues?.map((v) => v.level ?? '').where((v) => v.isNotEmpty).join(', ') ?? '';
        final segment = values.isNotEmpty ? '${fv.name} ($values)' : (fv.name ?? '');
        if (segment.isNotEmpty) {
          text += '${text.isEmpty ? '' : ',  '}$segment';
        }
      }
    }

    return text;
  }

  String _buildAddOnText() {
    final od = widget.orderDetails;
    if (od.addOns == null || od.addOns!.isEmpty) return '';
    return od.addOns!.map((a) => '${a.name} (${a.quantity})').join(',  ');
  }

  List<InlineSpan> _buildCollapsedSpans({required String variationText, required String addOnText, required Color color}) {
    final TextStyle labelStyle = robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: color);
    final List<InlineSpan> spans = [];
    if (variationText.isNotEmpty) {
      spans.add(TextSpan(text: '${'variations'.tr}: ', style: labelStyle));
      spans.add(TextSpan(text: variationText));
    }
    if (variationText.isNotEmpty && addOnText.isNotEmpty) {
      spans.add(const TextSpan(text: '   •   '));
    }
    if (addOnText.isNotEmpty) {
      spans.add(TextSpan(text: '${'addons'.tr}: ', style: labelStyle));
      spans.add(TextSpan(text: addOnText));
    }
    return spans;
  }

  bool _spansOverflowOneLine(BuildContext context, List<InlineSpan> spans, Color color, double maxWidth) {
    final TextPainter painter = TextPainter(
      text: TextSpan(style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: color), children: spans),
      maxLines: 1,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: maxWidth);
    return painter.didExceedMaxLines;
  }

  @override
  Widget build(BuildContext context) {
    final od = widget.orderDetails;
    if (od.isBogoBundle) {
      return _BogoBundleItemRow(orderDetails: od);
    }
    if (od.isBundle) {
      final OrderBundleDetailsModel bundle = od.bundleDetails!;
      return BundleOrderItemRow(
        name: bundle.name ?? '',
        totalPrice: bundle.totalPrice ?? 0,
        images: (bundle.items ?? const <OrderBundleItemModel>[]).map((item) => item.imageFullUrl ?? '').toList(),
        itemCount: bundle.items?.length ?? 0,
        quantity: od.quantity ?? bundle.quantity,
      );
    }

    final disabled = Theme.of(context).disabledColor;
    final imageUrl = od.imageFullUrl ?? '';
    final discountedPrice = od.price ?? 0;
    final originalPrice = od.itemDetails?.price;
    final hasDiscount = originalPrice != null && originalPrice > discountedPrice;
    final variationText = _buildVariationText();
    final addOnText = _buildAddOnText();
    final hasAdditional = variationText.isNotEmpty || addOnText.isNotEmpty;

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

      ClipRRect(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        child: imageUrl.isEmpty
        ? Container(width: _thumbSize, height: _thumbSize,
            color: disabled.withValues(alpha: 0.15),
            child: Icon(Icons.fastfood, color: disabled),
          )
        : Image.network(imageUrl, width: _thumbSize, height: _thumbSize, fit: BoxFit.cover,
            cacheWidth: ImageCacheHelper.pixels(context, _thumbSize),
            errorBuilder: (context, error, stack) => Container(width: _thumbSize, height: _thumbSize,
              color: disabled.withValues(alpha: 0.15),
              child: Icon(Icons.fastfood, color: disabled),
            ),
          ),
      ),
      const SizedBox(width: Dimensions.paddingSizeDefault),

      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            od.itemDetails?.name ?? '',
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Text(
              PriceConverter.convertPrice(discountedPrice),
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
            ),
            if (hasDiscount) ...[
              const SizedBox(width: 6),
              Text(
                PriceConverter.convertPrice(originalPrice),
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: disabled,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ]),

          if (hasAdditional) ...[
            const SizedBox(height: 6),
            LayoutBuilder(builder: (context, constraints) {
              const double arrowReservedWidth = 24;
              final double textMaxWidth = (constraints.maxWidth - arrowReservedWidth).clamp(0.0, double.infinity);
              final List<InlineSpan> collapsedSpans = _buildCollapsedSpans(
                variationText: variationText, addOnText: addOnText, color: disabled,
              );
              final bool needsToggle = _spansOverflowOneLine(context, collapsedSpans, disabled, textMaxWidth);

              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: _additionalExpanded
                  ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (variationText.isNotEmpty)
                        _LabeledNote(label: 'variations'.tr, value: variationText, color: disabled),
                      if (variationText.isNotEmpty && addOnText.isNotEmpty)
                        const SizedBox(height: 2),
                      if (addOnText.isNotEmpty)
                        _LabeledNote(label: 'addons'.tr, value: addOnText, color: disabled),
                    ])
                  : RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: disabled), children: collapsedSpans),
                    ),
                ),
                if (needsToggle)
                  InkWell(
                    onTap: () => setState(() => _additionalExpanded = !_additionalExpanded),
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: AnimatedRotation(
                        turns: _additionalExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(Icons.keyboard_arrow_down, size: 18, color: disabled),
                      ),
                    ),
                  ),
              ]);
            }),
          ],
        ]),
      ),
      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
        decoration: BoxDecoration(
          color: disabled.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        child: Text(
          '${'qty'.tr} : ${od.quantity ?? 0}',
          style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
        ),
      ),
    ]);
  }
}

class _BogoBundleItemRow extends StatelessWidget {
  final OrderDetailsModel orderDetails;
  const _BogoBundleItemRow({required this.orderDetails});

  static List<String> _thumbnailsOf(List<OrderBogoItemModel>? items) {
    return (items ?? const <OrderBogoItemModel>[]).map((item) => item.imageFullUrl ?? '').where((url) => url.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final OrderBogoDetailsModel bogo = orderDetails.bogoDetails!;
    final Color disabled = Theme.of(context).disabledColor;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            BogoItemGroupWidget(label: 'buying_item'.tr, thumbnails: _thumbnailsOf(bogo.buyItems)),
            const SizedBox(width: Dimensions.paddingSizeExtraLarge),
            BogoItemGroupWidget(label: 'free_item'.tr, thumbnails: _thumbnailsOf(bogo.freeItems)),
          ]), 
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
          decoration: BoxDecoration(
            color: disabled.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
          child: Text(
            '${'qty'.tr} : ${orderDetails.quantity ?? bogo.quantity ?? 0}',
            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
          ),
        ),
      ]),
      const SizedBox(height: Dimensions.paddingSizeSmall),
      Text(
        bogo.offerTitle ?? 'bogo_offer'.tr,
        style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
        maxLines: 2, overflow: TextOverflow.ellipsis,
      ),
      Text(
        PriceConverter.convertPrice(bogo.totalPrice ?? 0),
        style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge), textDirection: TextDirection.ltr,
      ),
    ]);
  }
}

class BundleOrderItemRow extends StatelessWidget {
  final String name;
  final double totalPrice;
  final List<String> images;
  final int itemCount;

  /// Null where the row has no count to state — a service booking's bundle does not
  /// carry one — and the chip is then left off rather than printed as zero.
  final int? quantity;

  const BundleOrderItemRow({super.key, required this.name, required this.totalPrice, required this.images,
    required this.itemCount, this.quantity,
  });

  static const int _visibleThumbnails = 3;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      Text(
        name,
        maxLines: 1, overflow: TextOverflow.ellipsis,
        style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
      ),
      const SizedBox(height: Dimensions.paddingSizeSmall),

      Row(children: [
        BundleThumbnailStrip(images: images, totalCount: itemCount, maxVisible: _visibleThumbnails),
        const SizedBox(width: Dimensions.paddingSizeSmall),

        Expanded(child: Text(
          PriceConverter.convertPrice(totalPrice),
          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
        )),

        if(quantity != null) Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
          child: Text(
            '${'qty'.tr} : $quantity',
            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
          ),
        ),
      ]),
    ]);
  }
}

class BundleThumbnailStrip extends StatelessWidget {
  final List<String> images;
  final int totalCount;
  final int maxVisible;

  static const double _size = 48;
  static const double _overlap = 15;

  const BundleThumbnailStrip({super.key, required this.images, required this.totalCount, required this.maxVisible});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final List<String> shown = images.isEmpty ? const [''] : images;
    final int visibleCount = shown.length < maxVisible ? shown.length : maxVisible;
    final int hiddenCount = totalCount - visibleCount;
    final bool showCounter = hiddenCount > 0;
    final int circleCount = visibleCount + (showCounter ? 1 : 0);
    const double step = _size - _overlap;

    return SizedBox(
      height: _size,
      width: _size + step * (circleCount - 1),
      child: Stack(children: List.generate(circleCount, (index) {
        final bool isCounter = showCounter && index == visibleCount;

        return Positioned(
          left: step * index,
          child: Material(
            borderRadius: BorderRadius.circular(_size / 2),
            child: Container(
              height: _size, width: _size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.disabledColor.withAlpha(50),
                border: isCounter ? null : Border.all(color: theme.cardColor, width: 1.5),
              ),
              alignment: Alignment.center,
              clipBehavior: Clip.antiAlias,
              child: isCounter ? Text(
                '+$hiddenCount',
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall),
              ) : ClipOval(child: CustomImage(image: shown[index], height: _size, width: _size, fit: BoxFit.fill)),
            ),
          ),
        );
      })),
    );
  }
}

class _LabeledNote extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _LabeledNote({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: color), children: [
        TextSpan(
          text: '$label: ',
          style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: color),
        ),
        TextSpan(text: value),
      ]),
    );
  }
}
