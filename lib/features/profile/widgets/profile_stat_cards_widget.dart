import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/order/screens/my_order_screen.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class ProfileStatCardsWidget extends StatelessWidget {
  const ProfileStatCardsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(builder: (profileController) {
      final bool isLoggedIn = AuthHelper.isLoggedIn();
      if (!isLoggedIn || profileController.userInfoModel == null) {
        return const SizedBox.shrink();
      }

      final user = profileController.userInfoModel!;
      final List<_StatItemData> items = [
        _StatItemData(
          iconAsset: Images.loyaltyIcon2,
          iconBgColor: const Color(0xFFFFF4D6),
          value: (user.loyaltyPoint ?? 0).toString(),
          labelKey: 'loyalty_point',
          onTap: () => Get.toNamed(RouteHelper.getLoyaltyRoute()),
        ),
        _StatItemData(
          iconAsset: Images.walletIcon2,
          iconBgColor: const Color(0xFFE6F0FF),
          value: PriceConverter.convertPrice(user.walletBalance, forMenuWallet: true),
          labelKey: 'wallet',
          onTap: () => Get.toNamed(RouteHelper.getWalletRoute()),
        ),
        _StatItemData(
          iconAsset: Images.shoppingBagIcon,
          iconBgColor: const Color(0xFFE7F7EC),
          value: (user.orderCount ?? 0).toString(),
          labelKey: 'order',
          onTap: () => Get.to(() => const MyOrderScreen()),
        ),
      ];

      return Container(
        margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
        height: MediaQuery.of(context).size.width * 0.18,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: Dimensions.paddingSizeSmall),
          itemBuilder: (context, index) => _StatCard(data: items[index]),
        ),
      );
    });
  }
}

class _StatItemData {
  final String iconAsset;
  final Color iconBgColor;
  final String value;
  final String labelKey;
  final VoidCallback onTap;

  const _StatItemData({
    required this.iconAsset,
    required this.iconBgColor,
    required this.value,
    required this.labelKey,
    required this.onTap,
  });
}

class _StatCard extends StatelessWidget {
  final _StatItemData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.4,
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeSmall,
          vertical: Dimensions.paddingSizeSmall,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          boxShadow: lightShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Image.asset(data.iconAsset, fit: BoxFit.contain),
                ),
                Flexible(
                  child: Text(
                    data.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    data.labelKey.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
