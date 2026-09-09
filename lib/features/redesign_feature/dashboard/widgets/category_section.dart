
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/category_widget.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

// Height of a category cell: the 64px circle image + gap + the two-line label,
// scaled by the device text scale so larger font/accessibility settings don't
// clip the label. Floored at 110 so the default phone layout is unchanged.
double _categoryCellHeight(BuildContext context) {
  final double textScale = MediaQuery.textScalerOf(context).scale(1.0);
  final double labelHeight = Dimensions.fontSizeSmall * 1.3 * 2 * textScale;
  return (64 + Dimensions.paddingSizeExtraSmall + labelHeight + 2).clamp(110.0, double.infinity).toDouble();
}

class CategorySection extends StatelessWidget {
  final bool asList;
  const CategorySection({super.key, required this.asList});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CategoryController>(builder: (controller) {
      final List<CategoryModel>? list = controller.categoryList;
      if(list == null) {
        return _CategoryShimmer(asList: asList);
      }
      if(list.isEmpty) {
        return const SizedBox.shrink();
      }
      return CategoryGridWidget(
        categories: list, asList: asList,
        onCategoryTap: _navigateToCategory,
      );
    });
  }

  void _navigateToCategory(CategoryModel category) {
    Get.toNamed(RouteHelper.getCategoryItemRoute(
      category.id, category.name ?? '',
      slug: category.slug ?? '',
    ));
  }
}

class CategoryGridWidget extends StatelessWidget {
  final List<CategoryModel> categories;
  final bool asList;
  final void Function(CategoryModel category)? onCategoryTap;
  const CategoryGridWidget({super.key, required this.categories, required this.asList, this.onCategoryTap});

  @override
  Widget build(BuildContext context) {
    final bool hasMoreCategories = categories.length > (asList ? 6 : 8);
    return asList ? SizedBox(
      height: _categoryCellHeight(context),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeExtraSmall),
        itemBuilder: (context, index) {
          if(hasMoreCategories && index == 6) {
            return _ViewAllCategoryButton(
              onTap:()=>  seeMoreCategoryAction(categories, onCategoryTap: onCategoryTap),
            );
          }

          final CategoryModel category = categories[index];
          return InkWell(
            onTap: onCategoryTap != null ? () => onCategoryTap!(category) : null,
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            child: SizedBox(
              width: 76,
              child: Column(
                children: [
                  ClipOval(child: Container(color: Theme.of(context).disabledColor, height: 64, width: 64, child: CustomImage(
                    image: category.imageFullUrl ?? '', fit: BoxFit.cover,
                    cacheWidth: 192, cacheHeight: 192,
                  ))),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  Text(
                    category.name ?? '',
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: Dimensions.paddingSizeSmall),
        itemCount: hasMoreCategories ? 6+1 : categories.length,
      ),
    ) : Column(
        children : [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            itemBuilder: (context, index) {
              if(hasMoreCategories && index == 8) {
                return _ViewAllCategoryButton(
                  onTap: () {
                   seeMoreCategoryAction(categories, onCategoryTap: onCategoryTap);
                  },
                );
              }

              final CategoryModel category = categories[index];
              return InkWell(
                onTap: onCategoryTap != null ? () => onCategoryTap!(category) : null,
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                child: Column(
                  children: [
                    SizedBox(height: 64, width: 64,
                      child: ClipOval(child: CustomImage(
                        image: category.imageFullUrl ?? '', fit: BoxFit.cover,
                        cacheWidth: 192, cacheHeight: 192,
                      )),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                    Text(
                      category.name ?? '',
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                    ),
                  ],
                ),
              );
            },
            itemCount: hasMoreCategories ? 8 : categories.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: Dimensions.paddingSizeExtraSmall,
              crossAxisSpacing: Dimensions.paddingSizeExtraSmall,
              mainAxisExtent: _categoryCellHeight(context),
            ),
          ),
          if(hasMoreCategories) Padding(
            padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
            child: GestureDetector(
              onTap:() => seeMoreCategoryAction(categories, onCategoryTap: onCategoryTap),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text("see_more".tr, style: robotoSemiBold.copyWith(color: Colors.blueAccent, fontSize: Dimensions.fontSizeLarge)),
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall,),
                  Icon(Icons.keyboard_arrow_down_outlined, size: Dimensions.fontSizeExtraLarge),
                ],
              ),
            ),
          )
        ]
    );
  }
}

class _CategoryShimmer extends StatelessWidget {
  final bool asList;
  const _CategoryShimmer({required this.asList});

  @override
  Widget build(BuildContext context) {
    final Color shimmerColor = Theme.of(context).disabledColor.withAlpha(60);

    if(asList) {
      return SizedBox(
        height: _categoryCellHeight(context),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 7,
          separatorBuilder: (context, index) => const SizedBox(width: Dimensions.paddingSizeSmall),
          itemBuilder: (context, index) => _ShimmerCell(color: shimmerColor),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      itemCount: 8,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: Dimensions.paddingSizeDefault,
        crossAxisSpacing: Dimensions.paddingSizeSmall,
        mainAxisExtent: _categoryCellHeight(context),
      ),
      itemBuilder: (context, index) => _ShimmerCell(color: shimmerColor),
    );
  }
}

class _ShimmerCell extends StatelessWidget {
  final Color color;
  const _ShimmerCell({required this.color});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      duration: const Duration(seconds: 2),
      child: SizedBox(
        width: 76,
        child: Column(children: [
          Container(
            height: 64, width: 64,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Container(
            height: 10, width: 50,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ViewAllCategoryButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ViewAllCategoryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      child: InkWell(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        onTap: onTap,
        child: Column(
          children: [
            SizedBox(
              height: 64,
              width: 64,
              child: Center(
                child: Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_rounded, color: Colors.blue, size: 22),
                ),
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            Text(
              'view_all'.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: Dimensions.fontSizeSmall),
            ),
          ],
        ),
      ),
    );
  }
}


void seeMoreCategoryAction(List<CategoryModel> categories, {void Function(CategoryModel category)? onCategoryTap}) {
  Get.bottomSheet(
    categories.length >= 16
      ? _CategoryDraggableBottomSheet(categories: categories, onCategoryTap: onCategoryTap)
      : _CategoryStaticBottomSheet(categories: categories, onCategoryTap: onCategoryTap),
    isScrollControlled: true,
    useRootNavigator: true,
    ignoreSafeArea: false,
    backgroundColor: Colors.transparent,
  );
}

class _CategoryStaticBottomSheet extends StatelessWidget {
  final List<CategoryModel> categories;
  final void Function(CategoryModel category)? onCategoryTap;
  const _CategoryStaticBottomSheet({required this.categories, this.onCategoryTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 600,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(Dimensions.radiusDefault), topRight: Radius.circular(Dimensions.radiusDefault),),
      ),
      child: FoodModuleCategoryScreen(
        categories: categories,
        showAsFullPage: false,
        onCategoryTap: onCategoryTap,
      ),
    );
  }
}

class _CategoryDraggableBottomSheet extends StatefulWidget {
  final List<CategoryModel> categories;
  final void Function(CategoryModel category)? onCategoryTap;
  const _CategoryDraggableBottomSheet({required this.categories, this.onCategoryTap});

  @override
  State<_CategoryDraggableBottomSheet> createState() => _CategoryDraggableBottomSheetState();
}

class _CategoryDraggableBottomSheetState extends State<_CategoryDraggableBottomSheet> {
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  final ValueNotifier<bool> _isAtMaxExtent = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _sheetController.addListener(_listenSheetExtent);
  }

  void _listenSheetExtent() {
    if(!_sheetController.isAttached) {
      return;
    }

    final bool isAtMaxExtent = _sheetController.size >= 1 - 0.01;
    if(isAtMaxExtent != _isAtMaxExtent.value) {
      _isAtMaxExtent.value = isAtMaxExtent;
    }
  }

  @override
  void dispose() {
    _sheetController.removeListener(_listenSheetExtent);
    _sheetController.dispose();
    _isAtMaxExtent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 1,
      snap: false,
      builder: (context, scrollController) => ValueListenableBuilder<bool>(
        valueListenable: _isAtMaxExtent,
        builder: (context, isAtMaxExtent, _) => AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isAtMaxExtent ? 0 : Dimensions.radiusDefault),
              topRight: Radius.circular(isAtMaxExtent ? 0 : Dimensions.radiusDefault),
            ),
          ),
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(top: isAtMaxExtent ? MediaQuery.of(context).padding.top : 0),
            child: FoodModuleCategoryScreen(
              categories: widget.categories,
              showAsFullPage: true,
              scrollController: scrollController,
              isAtMaxExtent: isAtMaxExtent,
              onCategoryTap: widget.onCategoryTap,
            ),
          ),
        ),
      ),
    );
  }
}
