import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_loader.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/domain/models/monthly_order_model.dart';
import 'package:sixam_mart/features/order/widgets/monthly_store_card.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class _ModuleTab {
  final String labelKey;
  final String moduleType;
  const _ModuleTab({required this.labelKey, required this.moduleType});
}

const List<_ModuleTab> _moduleTabs = <_ModuleTab>[
  _ModuleTab(labelKey: 'grocery', moduleType: AppConstants.grocery),
  _ModuleTab(labelKey: 'pharmacy', moduleType: AppConstants.pharmacy),
];

class MyItemsScreen extends StatefulWidget {
  const MyItemsScreen({super.key});

  @override
  State<MyItemsScreen> createState() => _MyItemsScreenState();
}

class _MyItemsScreenState extends State<MyItemsScreen> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    Get.find<OrderController>().getMonthlyOrderList(notify: false, moduleType: _moduleTabs[_selectedTabIndex].moduleType);
  }

  void _onTabChanged(int index) {
    if(index == _selectedTabIndex) return;
    setState(() => _selectedTabIndex = index);
    Get.find<OrderController>().getMonthlyOrderList(moduleType: _moduleTabs[index].moduleType);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: CustomAppBar(title: 'my_items'.tr),
      body: GetBuilder<SplashController>(builder: (controller) {
          return controller.configModel?.monthlyOrderRemainder == 1 ?
           Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            //tabs
            const SizedBox(height: Dimensions.paddingSizeDefault,),
            _ModuleTabBar(
              selectedIndex: _selectedTabIndex,
              onSelected: _onTabChanged,
            ),

            // store list
            const SizedBox(height: Dimensions.paddingSizeDefault,),
            Expanded(
              child: GetBuilder<OrderController>(builder: (orderController) {
                final List<MonthlyOrder>? visibleOrders = orderController.monthlyOrders;
                if(visibleOrders == null) return const Center(child: CustomLoaderWidget());

                if(visibleOrders.isEmpty) {
                  return Center(child: Text(
                    'no_items_found'.tr,
                    style: robotoMedium.copyWith(color: Theme.of(context).disabledColor),
                  ));
                }

                return RefreshIndicator(
                  onRefresh: () => orderController.getMonthlyOrderList(moduleType: _moduleTabs[_selectedTabIndex].moduleType),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: visibleOrders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: Dimensions.paddingSizeDefault),
                    itemBuilder: (context, index) => MonthlyStoreCard(order: visibleOrders[index]),
                  ),
                );
              }),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault,),
          ]) :  SizedBox(
            child: Center(child: Text(
              'monthly_order_is_disable'.tr,
              style: robotoMedium.copyWith(color: Theme.of(context).disabledColor),
            )),
          );
        }
      ),
    );
  }
}

class _ModuleTabBar extends StatelessWidget {
  final int selectedIndex;
  final void Function(int index) onSelected;
  const _ModuleTabBar({required this.selectedIndex, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault,),
        itemCount: _moduleTabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: Dimensions.paddingSizeSmall),
        itemBuilder: (context, index) {
          final bool isSelected = index == selectedIndex;
          return InkWell(
            onTap: () => onSelected(index),
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).disabledColor.withAlpha(80)),
              ),
              child: Text(
                _moduleTabs[index].labelKey.tr,
                style: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
