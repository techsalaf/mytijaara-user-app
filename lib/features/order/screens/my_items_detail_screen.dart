import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/domain/models/monthly_order_model.dart';
import 'package:sixam_mart/features/order/widgets/monthly_item_tile.dart';
import 'package:sixam_mart/features/order/widgets/monthly_order_actions.dart';
import 'package:sixam_mart/features/order/widgets/monthly_order_menu_button.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class MyItemsDetailScreen extends StatelessWidget {
  final MonthlyOrder order;
  const MyItemsDetailScreen({super.key, required this.order});

  void _onMenuSelected(MonthlyOrderMenuAction action) {
    if(action == MonthlyOrderMenuAction.remove) {
      MonthlyOrderActions.confirmRemove(order, onRemoved: () => Get.back());
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<MonthlyOrderItemPreview> items = order.itemsPreview;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: CustomAppBar(title: 'my_items'.tr),
      body: Column(children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            physics: const BouncingScrollPhysics(),
            children: [
              _StoreTile(order: order, onMenuSelected: _onMenuSelected),
              const SizedBox(height: Dimensions.paddingSizeLarge),

              Text('item_list'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: Dimensions.paddingSizeDefault,
                  mainAxisSpacing: Dimensions.paddingSizeDefault,
                  mainAxisExtent: 217,
                ),
                itemBuilder: (context, index) => Container(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    border: Border.all(color: Theme.of(context).disabledColor.withAlpha(40)),
                  ),
                  child: MonthlyItemTile(item: items[index], imageHeight: 120),
                ),
              ),
            ],
          ),
        ),

        _TotalSection(order: order),
      ]),
    );
  }
}

class _StoreTile extends StatelessWidget {
  final MonthlyOrder order;
  final void Function(MonthlyOrderMenuAction action) onMenuSelected;
  const _StoreTile({required this.order, required this.onMenuSelected});

  /// Resolve the human-readable module name from the splash module list, falling back to the raw type.
  String? _moduleName(MonthlyOrder order) {
    final List<ModuleModel> modules = Get.find<SplashController>().moduleList ?? <ModuleModel>[];
    final ModuleModel match = modules.firstWhere(
      (ModuleModel m) => m.id == order.moduleId,
      orElse: () => ModuleModel(moduleName: order.moduleType),
    );
    return match.moduleName;
  }

  @override
  Widget build(BuildContext context) {
    final String? module = _moduleName(order);
    return Container(
      padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeSmall, Dimensions.paddingSizeSmall, Dimensions.paddingSizeExtraSmall, Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).disabledColor.withAlpha(20),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Row(children: [
        ClipOval(child: CustomImage(image: order.store?.logoFullUrl ?? '', height: 36, width: 36)),
        const SizedBox(width: Dimensions.paddingSizeSmall),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Flexible(
                  child: Text(
                    order.store?.name ?? '',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                  ),
                ),
                if(module != null && module.isNotEmpty) Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    '($module)',
                    style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                  ),
                ),
              ]),
              if(MonthlyOrderActions.refillDate(order) != null) Text(
                '${'next_refill_date_is'.tr} ${MonthlyOrderActions.refillDate(order)}',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
              ),
            ],
          ),
        ),

        MonthlyOrderMenuButton(showAddToCart: false, showView: false, onSelected: onMenuSelected),
      ]),
    );
  }
}

class _TotalSection extends StatelessWidget {
  final MonthlyOrder order;
  const _TotalSection({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Theme.of(context).disabledColor.withAlpha(40), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('total_amount'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
            Text(
              PriceConverter.convertPrice(MonthlyOrderActions.totalAmount(order)),
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
            ),
          ]),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          GetBuilder<OrderController>(builder: (orderController) => CustomButton(
            buttonText: 'add_to_cart'.tr,
            isLoading: orderController.isLoading,
            onPressed: () => MonthlyOrderActions.addToCart(order),
          )),
        ]),
      ),
    );
  }
}
