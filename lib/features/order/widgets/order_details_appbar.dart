part of '../screens/order_details_new_screen.dart';

class _OrderDetailsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool deliveryManAssigned;

  const _OrderDetailsAppBar({required this.deliveryManAssigned});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).cardColor,
      surfaceTintColor: Theme.of(context).cardColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        child: Row(children: [
          _CircleIconButton(
            icon: Icons.arrow_back,
            onTap: () => Get.back(),
            isback: true,
          ),
          const SizedBox(width: Dimensions.paddingSizeDefault),

          Expanded(
            child: Text(
              'order_details'.tr,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
            ),
          ),

          // Invoice icon commented out — POS receipt action not wired yet.
          // if (deliveryManAssigned) ...[
          //   _CircleIconButton(
          //     image: Images.docsIcon,
          //     onTap: () {},
          //   ),
          //   const SizedBox(width: Dimensions.paddingSizeSmall),
          // ],

          _CircleIconButton(image: Images.supprotIcon, onTap: () => Get.toNamed(RouteHelper.getSupportRoute())),
        ]),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData? icon;
  final String? image;
  final VoidCallback onTap;
  final bool isback;

  const _CircleIconButton({this.icon, this.image, required this.onTap, this.isback = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: isback ? BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).disabledColor.withAlpha(40),
        ) : null,
        width: 40, height: 40,alignment: Alignment.center,
        child: image != null ? Image.asset(image!, width: 22, height: 22)
            : Icon(icon, size: 22, color: Theme.of(context).textTheme.bodyLarge?.color),
      ),
    );
  }
}
