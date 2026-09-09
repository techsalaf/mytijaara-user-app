import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/profile/domain/constant.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class ProfileMenuSectionWidget extends StatelessWidget {
  final String titleKey;
  final List<ProfileMenuItem> items;

  const ProfileMenuSectionWidget({
    super.key,
    required this.titleKey,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeSmall,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        // boxShadow: lightShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Dimensions.paddingSizeDefault,
              Dimensions.paddingSizeDefault,
              Dimensions.paddingSizeDefault,
              Dimensions.paddingSizeSmall,
            ),
            child: Text(
              titleKey.tr,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeLarge,
                color: Theme.of(context).disabledColor,
              ),
            ),
          ),
          ...List.generate(items.length, (index) {
            final isLast = index == items.length - 1;
            return Column(
              children: [
                _ProfileMenuTile(item: items[index]),
                if (!isLast)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: Theme.of(context).disabledColor.withValues(alpha: 0.15),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final ProfileMenuItem item;
  const _ProfileMenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final Color textColor = item.color ?? Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return InkWell(
      onTap: () {
        if (item.onTap != null) {
          item.onTap!();
        } else if (item.route != null && item.route!.isNotEmpty) {
          Get.toNamed(item.route!);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeDefault,
        ),
        child: Row(
          children: [
            Image.asset(
              item.iconAsset,
              width: 16,
              height: 16,
              fit: BoxFit.contain,
              color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.6),
            ),
            const SizedBox(width: Dimensions.paddingSizeDefault),
            Expanded(
              child: Text(
                item.titleKey.tr,
                style: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: textColor,
                ),
              ),
            ),
            // Icon(
            //   Icons.arrow_forward_ios_rounded,
            //   size: 14,
            //   color: Theme.of(context).disabledColor,
            // ),
          ],
        ),
      ),
    );
  }
}
