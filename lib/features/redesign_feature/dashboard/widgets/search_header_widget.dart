import 'package:flutter/material.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/quick_filters_widget.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/widgets/search_widget.dart';
import 'package:sixam_mart/util/dimensions.dart';

class SearchAndQuickFilterWidget extends StatelessWidget {
  static const double height = 135;
  static const double topFilterHeight = Dimensions.paddingSizeDefault + 40;
  static const double searchOnlyHeight = height - topFilterHeight;
  final bool isPinned;
  final bool showQuickFilters;
  final double topFilterScrollOutOffset;
  final bool isHomeModule;
  // When pinned, draws a bottom divider + soft shadow so the sticky header reads as
  // a separate section from the scrolling content below.
  final bool showBottomDivider;
  // Optional override of the quick-filter pills (e.g. the service module passes
  // its own). When null, the default food filters + food navigation are used.
  final List<FoodModuleQuickFilterItem>? quickFilterItems;
  final void Function(FoodModuleQuickFilterItem item)? onQuickFilterTap;

  const SearchAndQuickFilterWidget({super.key, required this.isPinned, this.showQuickFilters = true, this.topFilterScrollOutOffset = 0, this.isHomeModule = false,
    this.showBottomDivider = false, this.quickFilterItems, this.onQuickFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final double pinnedTopFilterScrollOutOffset = topFilterScrollOutOffset.clamp(0, topFilterHeight).toDouble();
    final double visibleTopFilterHeight = showQuickFilters ? topFilterHeight - pinnedTopFilterScrollOutOffset : 0;

    return SizedBox(
      height: showQuickFilters ? height - pinnedTopFilterScrollOutOffset : searchOnlyHeight,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: showBottomDivider
              ? Border(bottom: BorderSide(color: Theme.of(context).disabledColor.withValues(alpha: 0.15), width: 1))
              : null,
          boxShadow: showBottomDivider
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))]
              : null,
        ),
        child: Center(
          child: Container(
            width: Dimensions.webMaxWidth,
            padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Dimensions.paddingSizeDefault,
                    Dimensions.paddingSizeDefault + 7,
                    Dimensions.paddingSizeDefault,
                    0,
                  ),
                  child: SearchNewWidget(isPinnedStyle: isPinned, isHomeModule: isHomeModule),
                ),
                if(showQuickFilters)
                  SizedBox(
                    height: visibleTopFilterHeight,
                    child: ClipRect(
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          Positioned(
                            top: -pinnedTopFilterScrollOutOffset,
                            left: 0,
                            right: 0,
                            child: SizedBox(
                              height: topFilterHeight,
                              child: Column(
                                children: [
                                  const SizedBox(height: Dimensions.paddingSizeDefault),
                                  quickFilterItems == null
                                      ? const QuickFiltersWidget()
                                      : QuickFiltersWidget(items: quickFilterItems!, onItemTap: onQuickFilterTap),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
