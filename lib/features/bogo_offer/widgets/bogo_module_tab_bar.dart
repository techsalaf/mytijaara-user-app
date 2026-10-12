import 'package:flutter/material.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class BogoModuleTabBar extends StatelessWidget {
  final List<ModuleModel> modules;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const BogoModuleTabBar({super.key, required this.modules, required this.selectedIndex, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).cardColor,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: Row(children: List.generate(modules.length, (index) => _ModuleTab(
            name: modules[index].moduleName ?? '',
            isSelected: index == selectedIndex,
            onTap: () => onSelected(index),
          ))),
        ),
      ),
    );
  }
}

class _ModuleTab extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModuleTab({required this.name, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.surface : Colors.transparent,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(Dimensions.radiusDefault),
            topRight: Radius.circular(Dimensions.radiusDefault),
          ),
        ),
        child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: isSelected
            ? robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge!.color)
            : robotoRegular.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).disabledColor)),
      ),
    );
  }
}
