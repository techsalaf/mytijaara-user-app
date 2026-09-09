import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:sixam_mart/features/order/domain/models/order_details_model.dart';
import 'package:sixam_mart/features/order/widgets/collapsible_header.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

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

  @override
  Widget build(BuildContext context) {
    final od = widget.orderDetails;
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
        ? Container(width: 52, height: 52,
            color: disabled.withValues(alpha: 0.15),
            child: Icon(Icons.fastfood, color: disabled),
          )
        : Image.network(imageUrl, width: 52, height: 52, fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => Container(width: 52, height: 52,
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
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (variationText.isNotEmpty)
                    _LabeledNote(label: 'variations'.tr, value: variationText, expanded: _additionalExpanded, color: disabled),
                  if (variationText.isNotEmpty && addOnText.isNotEmpty)
                    const SizedBox(height: 2),
                  if (addOnText.isNotEmpty)
                    _LabeledNote(label: 'addons'.tr, value: addOnText, expanded: _additionalExpanded, color: disabled),
                ]),
              ),
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
            ]),
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

class _LabeledNote extends StatelessWidget {
  final String label;
  final String value;
  final bool expanded;
  final Color color;

  const _LabeledNote({required this.label, required this.value, required this.expanded, required this.color});

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: expanded ? null : 1,
      overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
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
