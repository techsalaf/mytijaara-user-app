import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:flutter/material.dart';

class SlotWidget extends StatelessWidget {
  final String title;
  final bool isSelected;
  final Function onTap;
  const SlotWidget({super.key, required this.title, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap as void Function()?,
      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeSmall),
        alignment: Alignment.center,
        decoration: isSelected ? BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          border: isSelected ? null : Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.2)),
        ) : null,
        child: Text(
          title, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
          style: robotoBold.copyWith(
            color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge!.color,
            fontSize: Dimensions.fontSizeSmall,
          ),
        ),
      ),
    );
  }
}
