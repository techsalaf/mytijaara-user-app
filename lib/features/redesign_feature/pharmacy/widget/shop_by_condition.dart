import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/sliver_gap.dart';
import 'package:sixam_mart/features/redesign_feature/pharmacy/widget/madicine_card.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sliver_tools/sliver_tools.dart';

class ShopByConditionSection extends StatefulWidget {
  final String? title;
  const ShopByConditionSection({super.key, this.title});

  @override
  State<ShopByConditionSection> createState() => _ShopByConditionSectionState();
}

class _ShopByConditionSectionState extends State<ShopByConditionSection> {
  @override
  void initState() {
    super.initState();
    final ItemController itemController = Get.find<ItemController>();
    if (itemController.commonConditions == null || itemController.commonConditions!.isEmpty) {
      itemController.getCommonConditions(false);
    } else if (itemController.conditionWiseProduct == null) {
      itemController.getConditionsWiseItem(
        itemController.commonConditions![itemController.selectedCommonCondition].id!, false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ItemController>(
      builder: (itemController) {
        if (itemController.commonConditions == null) {
          return MultiSliver(children: [
            sliverPadX(child: TitleWidget(title: (widget.title ?? 'shop_by_condition').tr)),
            const SliverToBoxAdapter(child: _FilterChipShimmer()),
            sliverGepY(value: Dimensions.paddingSizeSmall),
            const SliverToBoxAdapter(child: _ShopByConditionShimmer()),
          ]);
        }

        if (itemController.commonConditions!.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox());
        }

        return MultiSliver(
          children: [
            sliverPadX(child: TitleWidget(title: (widget.title ?? 'shop_by_condition').tr)),
            SliverToBoxAdapter(child: FoodModuleExploreRestaurantFilterHeaderWidget(itemController: itemController)),
            sliverGepY(value: Dimensions.paddingSizeSmall),
            SliverToBoxAdapter(child: FoodModuleExploreRestaurantsListWidget(itemController: itemController)),
          ],
        );
      },
    );
  }
}

class FoodModuleExploreRestaurantFilterHeaderWidget extends StatelessWidget {
  static const double height = 46;
  final Key? filterKey;
  final ItemController itemController;

  const FoodModuleExploreRestaurantFilterHeaderWidget({super.key, this.filterKey, required this.itemController});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: filterKey,
      height: height,
      color: Theme.of(context).cardColor,
      child: Center(
        child: Container(
          width: Dimensions.webMaxWidth,
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: FoodModuleExploreRestaurantsFilterWidget(itemController: itemController),
        ),
      ),
    );
  }
}

class FoodModuleExploreRestaurantsFilterWidget extends StatelessWidget {
  final ItemController itemController;
  const FoodModuleExploreRestaurantsFilterWidget({super.key, required this.itemController});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(itemController.commonConditions!.length, (index) {
          final condition = itemController.commonConditions![index];
          final bool isSelected = itemController.selectedCommonCondition == index;
          return InkWell(
            onTap: () => itemController.selectCommonCondition(index),
            child: _ExploreFilterChip(label: condition.name ?? '', isSelected: isSelected),
          );
        }),
      ),
    );
  }
}

class FoodModuleExploreRestaurantsListWidget extends StatelessWidget {
  final ItemController itemController;
  const FoodModuleExploreRestaurantsListWidget({super.key, required this.itemController});

  @override
  Widget build(BuildContext context) {
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final double cardWidth = math.max(300, math.min(viewportWidth - 52, 340));

    if (itemController.conditionWiseProduct == null) {
      return const _ShopByConditionShimmer();
    }

    if (itemController.conditionWiseProduct!.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(child: Text('no_product_available'.tr, style: robotoRegular)),
      );
    }

    final List<Item> products = itemController.conditionWiseProduct!;

    return SizedBox(
      height: 272,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: cardWidth,
          crossAxisSpacing: Dimensions.paddingSizeSmall,
            mainAxisSpacing: Dimensions.paddingSizeSmall
        ),
        itemCount: products.length,
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        itemBuilder: (context, index) {
          final Item item = products[index];
          return CustomInkWell(
            onTap: () => itemController.navigateToItemPage(item, context),
            child: MadicineCardWidget(item: item, width: cardWidth, isBorder: true),
          );
        },
      ),
    );
  }
}

class _ExploreFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _ExploreFilterChip({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    return Container(
      height: FoodModuleExploreRestaurantFilterHeaderWidget.height,
      margin: const EdgeInsets.only(right: 24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(width: 3, color: isSelected ? primary : Colors.transparent)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: (isSelected ? robotoBold : robotoMedium).copyWith(
          fontSize: Dimensions.fontSizeDefault,
          color: isSelected ? primary : const Color(0xFF777777),
        ),
      ),
    );
  }
}

class _ShopByConditionShimmer extends StatelessWidget {
  const _ShopByConditionShimmer();

  @override
  Widget build(BuildContext context) {
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final double cardWidth = math.max(300, math.min(viewportWidth - 52, 340));
    final Color shimmerColor = Theme.of(context).disabledColor.withAlpha(60);

    return SizedBox(
      height: 272,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: cardWidth,
          crossAxisSpacing: Dimensions.paddingSizeSmall,
        ),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              left: (index == 0 || index == 1) ? Dimensions.paddingSizeDefault : Dimensions.paddingSizeSmall,
              right: 0,
            ),
            child: _MadicineCardShimmer(width: cardWidth, color: shimmerColor),
          );
        },
      ),
    );
  }
}

class _MadicineCardShimmer extends StatelessWidget {
  final double width;
  final Color color;
  const _MadicineCardShimmer({required this.width, required this.color});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      duration: const Duration(seconds: 2),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(color: Theme.of(context).disabledColor.withAlpha(50)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall, vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(height: 16, width: 16, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Expanded(child: Container(height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)))),
                    ]),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    Container(height: 12, width: double.infinity, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(Dimensions.radiusSmall))),
                    const SizedBox(height: 6),
                    Container(height: 12, width: width * 0.55, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(Dimensions.radiusSmall))),
                    const Spacer(),
                    Row(children: [
                      Container(height: 14, width: 50, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(Dimensions.radiusSmall))),
                      const SizedBox(width: 8),
                      Container(height: 12, width: 36, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(Dimensions.radiusSmall))),
                    ]),
                    const Spacer(),
                    Container(height: 10, width: width * 0.5, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(Dimensions.radiusSmall))),
                  ],
                ),
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Container(
              width: 120,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChipShimmer extends StatelessWidget {
  const _FilterChipShimmer();

  @override
  Widget build(BuildContext context) {
    final Color shimmerColor = Theme.of(context).disabledColor.withAlpha(60);
    return Container(
      height: FoodModuleExploreRestaurantFilterHeaderWidget.height,
      color: Theme.of(context).cardColor,
      child: Center(
        child: Container(
          width: Dimensions.webMaxWidth,
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: Shimmer(
            duration: const Duration(seconds: 2),
            child: Row(children: List.generate(4, (index) => Padding(
              padding: const EdgeInsets.only(right: Dimensions.paddingSizeDefault),
              child: Container(
                height: 14, width: 70,
                decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
              ),
            ))),
          ),
        ),
      ),
    );
  }
}
