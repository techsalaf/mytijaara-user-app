import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class ProfileAppBarWidget extends StatelessWidget {
  final Function()? onBackPressed;
  const ProfileAppBarWidget({super.key, this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: SizedBox(
              width: Dimensions.webMaxWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeSmall,
                  vertical: Dimensions.paddingSizeDefault,
                ),
                child: Row(
                  children: [
                    _BackButtonWidget(onTap: onBackPressed??(){}),
                    const SizedBox(width: Dimensions.paddingSizeDefault),
                    Expanded(
                      child: Text(
                        'my_profile'.tr,
                        style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeLarge,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                    // const _ThemeToggleButton(),
                  ],
                ),
              ),
            ),
          ),
          Divider(height: 1, thickness: 1, color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),
        ],
      ),
    );
  }
}

class _BackButtonWidget extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButtonWidget({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).disabledColor.withValues(alpha: 0.12),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }
}

// class _ThemeToggleButton extends StatelessWidget {
//   const _ThemeToggleButton();

//   @override
//   Widget build(BuildContext context) {
//     return GetBuilder<ThemeController>(builder: (themeController) {
//       return InkWell(
//         onTap: () => themeController.toggleTheme(),
//         borderRadius: BorderRadius.circular(100),
//         child: Container(
//           padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: Theme.of(context).disabledColor.withValues(alpha: 0.12),
//           ),
//           alignment: Alignment.center,
//           child: themeController.darkTheme
//               ? Icon(Icons.wb_sunny_outlined, size: 18, color: Theme.of(context).textTheme.bodyLarge?.color)
//               : Image.asset(Images.moon, height: 18, width: 18, color: Theme.of(context).textTheme.bodyLarge?.color),
//         ),
//       );
//     });
//   }
// }
