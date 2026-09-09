import 'package:sixam_mart/features/cart/screens/global_cart_screen.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/cart_widget.dart';
import 'package:sixam_mart/common/widgets/veg_filter_widget.dart';
import 'package:sixam_mart/common/widgets/web_menu_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool backButton;
  final Function? onBackPressed;
  final bool showCart;
  final Function(String value)? onVegFilterTap;
  final String? type;
  final String? leadingIcon;
  final Widget? menuWidget;
  final String? subtitle;
  final String? cartSubtitle;
  final bool isCart;
  final VoidCallback? onSearchTap;
  final bool isSearchActive;
  const CustomAppBar({super.key, required this.title, this.backButton = true, this.onBackPressed, this.showCart = false, this.leadingIcon,
    this.onVegFilterTap, this.type, this.menuWidget, this.subtitle, this.isCart = false, this.cartSubtitle, this.onSearchTap, this.isSearchActive = false});

  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) return const WebMenuBar();

    final Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final Color iconBg = Theme.of(context).disabledColor.withValues(alpha: 0.1);

    return AppBar(
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          title,
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: textColor),
        ),
        if (isCart && cartSubtitle != null) Text(
          cartSubtitle!,
          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
        ),
      ]),
      centerTitle: false,
      titleSpacing: 0,
      leadingWidth: backButton ? 70 : 0,
      leading: backButton ? Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        child: GestureDetector(
          onTap: () => onBackPressed != null ? onBackPressed!() : Navigator.pop(context),
          child: Container(
            height: 40, width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: leadingIcon != null
                ? Image.asset(leadingIcon!, height: 22, width: 22)
                : Icon(Icons.arrow_back, color: textColor, size: 20),
          ),
        ),
      ) : null,
      bottom: subtitle != null ? PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 5.0),
          child: Text(subtitle!, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault)),
        ),
      ) : null,
      backgroundColor: Theme.of(context).cardColor,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      actions: showCart || onVegFilterTap != null || onSearchTap != null ? [
        onSearchTap != null ? IconButton(
          onPressed: onSearchTap,
          icon: Icon(isSearchActive ? Icons.close : Icons.search, color: textColor),
        ) : const SizedBox(),

        showCart ? IconButton(
          onPressed: () => Get.to(() => const GlobalCartScreen(fromNav: false)),
          icon: const CartWidget(size: 25),
        ) : const SizedBox(),

        onVegFilterTap != null ? VegFilterWidget(
          type: type,
          onSelected: onVegFilterTap,
          fromAppBar: true,
        ) : const SizedBox(),

      ] : [menuWidget ?? const SizedBox(), const SizedBox(width: Dimensions.paddingSizeDefault)],
    );
  }

  @override
  Size get preferredSize => Size(Get.width, GetPlatform.isDesktop ? 100 : subtitle != null ? 60 : 60);
}
