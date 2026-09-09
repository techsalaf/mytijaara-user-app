import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

enum MonthlyOrderMenuAction { addToCart, view, remove }

class MonthlyOrderMenuButton extends StatelessWidget {
  final bool showAddToCart;
  final bool showView;
  final void Function(MonthlyOrderMenuAction action) onSelected;
  const MonthlyOrderMenuButton({super.key, this.showAddToCart = true, this.showView = true, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<MonthlyOrderMenuAction>(
      icon: Icon(Icons.more_vert, color: Theme.of(context).textTheme.bodyLarge?.color),
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
      onSelected: onSelected,
      itemBuilder: (context) => [
        if(showAddToCart) PopupMenuItem<MonthlyOrderMenuAction>(
          value: MonthlyOrderMenuAction.addToCart,
          child: _MenuRow(label: 'add_to_cart'.tr, icon: Icons.shopping_cart, color: Theme.of(context).primaryColor),
        ),
        if(showView) PopupMenuItem<MonthlyOrderMenuAction>(
          value: MonthlyOrderMenuAction.view,
          child: _MenuRow(label: 'view'.tr, icon: Icons.remove_red_eye, color: Colors.blue),
        ),
        PopupMenuItem<MonthlyOrderMenuAction>(
          value: MonthlyOrderMenuAction.remove,
          child: _MenuRow(label: 'remove'.tr, icon: Icons.delete, color: Theme.of(context).colorScheme.error),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _MenuRow({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Text(label, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault)),
      ),
      const SizedBox(width: Dimensions.paddingSizeDefault),
      Icon(icon, color: color, size: 20),
    ]);
  }
}
