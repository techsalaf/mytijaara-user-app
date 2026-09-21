import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class FoodModuleCategoryScreen extends StatefulWidget {
  final bool showAsFullPage;
  final List<CategoryModel> categories;
  final ScrollController? scrollController;
  final bool isAtMaxExtent;
  final void Function(CategoryModel category)? onCategoryTap;

  const FoodModuleCategoryScreen({super.key,
    required this.categories, required this.showAsFullPage, this.scrollController, this.isAtMaxExtent = false, this.onCategoryTap,
  });

  @override
  State<FoodModuleCategoryScreen> createState() => _FoodModuleCategoryScreenState();
}

class _FoodModuleCategoryScreenState extends State<FoodModuleCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<CategoryModel> get _filteredCategories {
    final String query = _searchController.text.trim().toLowerCase();
    if(query.isEmpty) {
      return widget.categories;
    }

    return widget.categories.where((category) => (category.name??'').toLowerCase().contains(query)).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<CategoryModel> filteredCategories = _filteredCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BottomSheetHeaderWidget(showDragHandler: true, isAtMaxExtent: widget.isAtMaxExtent,),

        if(widget.showAsFullPage) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, widget.isAtMaxExtent ? Dimensions.paddingSizeSmall : 0, Dimensions.paddingSizeDefault, 0),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'search_by_category_name'.tr,
                hintStyle: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeDefault),
                suffixIcon: _searchController.text.isNotEmpty ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close_rounded),
                ) : const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Theme.of(context).disabledColor.withValues(alpha: 0.08),
                contentPadding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault,),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                  borderSide: BorderSide(color: Theme.of(context).disabledColor.withValues(alpha: 0.18)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                  borderSide: BorderSide(color: Theme.of(context).disabledColor.withValues(alpha: 0.18)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                  borderSide: BorderSide(color: Theme.of(context).disabledColor),
                ),
              ),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
        ],

        Expanded(
          child: filteredCategories.isEmpty ? Center(
            child: Text(
              'no_category_found'.tr,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
            ),
          ) : GridView.builder(
            controller: widget.scrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
              vertical: Dimensions.paddingSizeSmall,
            ),
            physics: widget.scrollController != null
                ? const AlwaysScrollableScrollPhysics()
                : (filteredCategories.length <= 16 ? const NeverScrollableScrollPhysics() : null),
            itemCount: filteredCategories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisExtent: 100,
              mainAxisSpacing: Dimensions.paddingSizeDefault,
              crossAxisSpacing: Dimensions.paddingSizeSmall,
            ),
            itemBuilder: (context, index) {
              final CategoryModel category = filteredCategories[index];
              return InkWell(
                onTap: widget.onCategoryTap != null ? () {
                  Get.back();
                  widget.onCategoryTap!(category);
                } : null,
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                child: Column(
                  children: [
                    SizedBox.square(
                      dimension: 60,
                      child: ClipOval(child: CustomImage(
                        image: category.imageFullUrl ?? '', fit: BoxFit.cover,
                        cacheWidth: 180, cacheHeight: 180,
                      )),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                    Text(
                      category.name ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault,)
      ],
    );
  }
}

class BottomSheetHeaderWidget extends StatelessWidget {
  final bool showDragHandler;
  final bool isAtMaxExtent;
  const BottomSheetHeaderWidget({super.key, required this.showDragHandler, this.isAtMaxExtent = false,});

  static const Duration _animDuration = Duration(milliseconds: 220);
  static const Curve _animCurve = Curves.easeOut;

  @override
  Widget build(BuildContext context) {
    // Float the close button to the top-right corner only while the draggable
    // sheet is partially open. The static sheet (no drag handle) and the
    // fully-expanded state keep the existing in-row placement.
    final bool floatCloseTopRight = showDragHandler && !isAtMaxExtent;

    return AnimatedContainer(
      duration: _animDuration,
      curve: _animCurve,
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(
          color: Theme.of(context).disabledColor.withAlpha(isAtMaxExtent ? 25 : 0),
        )),
      ),
      child: Stack(children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if(showDragHandler) ClipRect(
              child: AnimatedAlign(
                duration: _animDuration,
                curve: _animCurve,
                alignment: Alignment.topCenter,
                heightFactor: isAtMaxExtent ? 0 : 1,
                child: AnimatedOpacity(
                  duration: _animDuration,
                  curve: _animCurve,
                  opacity: isAtMaxExtent ? 0 : 1,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          color: Theme.of(context).disabledColor.withAlpha(100),
                        ),
                        height: 5,
                        width: 50,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'all_categories'.tr,
                    style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                  ),
                ),
                if(!floatCloseTopRight) _SheetCloseButton(isAtMaxExtent: isAtMaxExtent),
              ],
            ),
          ],
        ),

        if(floatCloseTopRight) Positioned(
          top: 0, right: 0,
          child: _SheetCloseButton(isAtMaxExtent: isAtMaxExtent),
        ),
      ]),
    );
  }
}

class _SheetCloseButton extends StatelessWidget {
  final bool isAtMaxExtent;
  const _SheetCloseButton({required this.isAtMaxExtent});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.back(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).disabledColor.withAlpha(isAtMaxExtent ? 35 : 50),
        ),
        child: const Icon(Icons.close, size: 16),
      ),
    );
  }
}
