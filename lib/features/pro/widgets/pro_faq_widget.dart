import 'package:sixam_mart/features/pro/domain/models/pro_faq_model.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProFaqWidget extends StatefulWidget {
  final List<ProFaqModel>? faqList;
  const ProFaqWidget({super.key, required this.faqList});

  @override
  State<ProFaqWidget> createState() => _ProFaqWidgetState();
}

class _ProFaqWidgetState extends State<ProFaqWidget> {
  int _expandedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final List<ProFaqModel> items = widget.faqList?.where((faq) => faq.question != null && faq.question!.trim().isNotEmpty).toList() ?? [];
    if (items.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('frequently_asked_questions'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        ...items.asMap().entries.map((e) => _buildFaqItem(context, e.key, e.value)),
      ],
    );
  }

  Widget _buildFaqItem(BuildContext context, int index, ProFaqModel item) {
    final bool isExpanded = _expandedIndex == index;
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expandedIndex = isExpanded ? -1 : index),
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
            child: Row(
              children: [
                Expanded(child: Text(item.question ?? '', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault))),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: Theme.of(context).hintColor,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
            child: Text(item.answer ?? '', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
          ),
        Divider(color: Theme.of(context).disabledColor.withValues(alpha: 0.2), height: 1),
      ],
    );
  }
}
