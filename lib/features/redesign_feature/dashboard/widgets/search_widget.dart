import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/redesign_feature/dashboard/controllers/food_module_home_controller.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class SearchNewWidget extends StatelessWidget {
  final String title;
  final bool isPinnedStyle;
  final bool isHomeModule;

  const SearchNewWidget({
    super.key,
    this.title = 'Search for',
    this.isPinnedStyle = false,
    this.isHomeModule = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor = Theme.of(context).disabledColor.withValues(alpha: 0.18);
    final Color backgroundColor = Theme.of(context).disabledColor.withValues(alpha: 0.15);

    return GetBuilder<FoodModuleController>(
      init: FoodModuleController(searchTitle: title),
      global: false,
      builder: (newHomeController) {
        return Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Get.toNamed(RouteHelper.getSearchRoute()),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeDefault,
                    vertical: Dimensions.paddingSizeSmall + 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge + Dimensions.radiusDefault),
                    border: Border.all(color: borderColor, width: 0.1),
                  ),
                  child: Row(
                    children: [
                      // Fixed "Search for" prefix.
                      Text(
                        '${newHomeController.searchTitle} ',
                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).disabledColor),
                      ),

                      // Trailing word rolls up from bottom to top on each change.
                      Expanded(
                        child: ClipRect(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 450),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            // Keep the word aligned to the start (left), not centered.
                            layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                              return Stack(
                                alignment: Alignment.centerLeft,
                                children: <Widget>[
                                  ...previousChildren,
                                  ?currentChild,
                                ],
                              );
                            },
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              // Incoming word enters from the bottom; outgoing exits upward.
                              final bool isIncoming = child.key == ValueKey<String>(newHomeController.currentWord);
                              final Animation<Offset> position = Tween<Offset>(
                                begin: Offset(0, isIncoming ? 1 : -1),
                                end: Offset.zero,
                              ).animate(animation);
                              return SlideTransition(position: position, child: child);
                            },
                            child: Text(
                              newHomeController.currentWord.isNotEmpty ? "'${newHomeController.currentWord}'" : '',
                              key: ValueKey<String>(newHomeController.currentWord),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.7)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeDefault),
                      Icon(
                        CupertinoIcons.search,
                        size: 20,
                        color: Theme.of(context).textTheme.bodyLarge!.color,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
