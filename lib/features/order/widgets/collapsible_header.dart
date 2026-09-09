import 'package:flutter/material.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class CollapsibleSectionHeader extends StatelessWidget {
  final String title;
  final bool expanded;
  final VoidCallback onTap;

  const CollapsibleSectionHeader({super.key, required this.title, required this.expanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = Theme.of(context).disabledColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
        child: Row(children: [
          Expanded(
            child: Text(
              title,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
            ),
          ),
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: disabled.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
            ),
            child: AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
