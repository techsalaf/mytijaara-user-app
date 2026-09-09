import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class NotesCollapsible extends StatefulWidget {
  final OrderModel order;

  const NotesCollapsible({super.key, required this.order});


  static bool _isNotBlank(String? s) {
    if (s == null) return false;
    final trimmed = s.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.toLowerCase() == 'null') return false;
    return true;
  }

  @override
  State<NotesCollapsible> createState() => NotesCollapsibleState();
}

class NotesCollapsibleState extends State<NotesCollapsible> {
  bool _expanded = false;

  static const _animDuration = Duration(milliseconds: 250);
  static const _animCurve = Curves.easeInOut;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    const primary = Colors.blueAccent;
    final hasInstruction = NotesCollapsible._isNotBlank(order.deliveryInstruction);
    final hasUnavailable = NotesCollapsible._isNotBlank(order.unavailableItemNote);
    final hasOrderNote = NotesCollapsible._isNotBlank(order.orderNote);
    final hasBringChangeAmount = order.bringChangeAmount != null && order.bringChangeAmount! > 0;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

      AnimatedCrossFade(
        firstChild: const SizedBox(width: double.infinity),
        secondChild: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (hasInstruction || hasUnavailable || hasOrderNote)
            _BlueNotesPanel(
              instruction: hasInstruction ? order.deliveryInstruction : null,
              unavailable: hasUnavailable ? order.unavailableItemNote : null,
              additionalNote: hasOrderNote ? order.orderNote : null,
            ),
          if (hasBringChangeAmount) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            _BringChangeAmountPanel(amount: order.bringChangeAmount!),
          ],
          const SizedBox(height: Dimensions.paddingSizeSmall),
        ]),
        crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        duration: _animDuration,
        sizeCurve: _animCurve,
        firstCurve: _animCurve,
        secondCurve: _animCurve,
      ),

      Center(
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
              vertical: Dimensions.paddingSizeExtraSmall,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              AnimatedSwitcher(
                duration: _animDuration,
                switchInCurve: _animCurve,
                switchOutCurve: _animCurve,
                transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                child: Text(
                  _expanded ? 'see_less'.tr : 'see_more'.tr,
                  key: ValueKey(_expanded),
                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: primary),
                ),
              ),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: _animDuration,
                curve: _animCurve,
                child: const Icon(Icons.keyboard_arrow_down, size: 20, color: primary),
              ),
            ]),
          ),
        ),
      ),
    ]);
  }
}

class _BlueNotesPanel extends StatelessWidget {
  final String? instruction;
  final String? unavailable;
  final String? additionalNote;

  const _BlueNotesPanel({required this.instruction, required this.unavailable, required this.additionalNote});

  @override
  Widget build(BuildContext context) {
    final dividerColor = Theme.of(context).disabledColor.withValues(alpha: 0.25);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color:  Colors.blue.shade100.withAlpha(60),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (instruction != null)
          _NoteSection(title: 'delivery_instruction'.tr, body: instruction!),
        if (instruction != null && unavailable != null)
          Divider(height: 6, thickness: 1, color: dividerColor, indent: Dimensions.paddingSizeSmall, endIndent: Dimensions.paddingSizeSmall),
        if (unavailable != null)
          _NoteSection(title: 'if_item_unavailable'.tr, body: unavailable!),
        if (unavailable != null && additionalNote != null)
          Divider(height: 6, thickness: 1, color: dividerColor, indent: Dimensions.paddingSizeSmall, endIndent: Dimensions.paddingSizeSmall),
        if (additionalNote != null)
          _NoteSection(title: 'additional_note'.tr, body: additionalNote!),
      ]),
    );
  }
}

class _BringChangeAmountPanel extends StatelessWidget {
  final double amount;

  const _BringChangeAmountPanel({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7DB),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: RichText(
        text: TextSpan(children: [
          TextSpan(text: 'please_bring'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault)),
          TextSpan(text: ' ${PriceConverter.convertPrice(amount)}', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault)),
          TextSpan(text: ' ${'in_change_when_making_the_delivery'.tr}', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault)),
        ]),
      ),
    );
  }
}

class _NoteSection extends StatelessWidget {
  final String title;
  final String body;

  const _NoteSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault)),
        const SizedBox(height: 2),
        Text(body.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
        ),
      ]),
    );
  }
}
