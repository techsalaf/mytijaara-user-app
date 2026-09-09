import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:url_launcher/url_launcher_string.dart';

class StoreUserAddressBlock extends StatelessWidget {
  final OrderModel order;

  const StoreUserAddressBlock({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    // For a parcel there is no store: the top row is the sender (the order's
    // delivery_address) and the bottom row is the receiver (receiver_details).
    final bool isParcel = order.orderType == 'parcel';

    final String topName = isParcel ? (order.deliveryAddress?.contactPersonName ?? '') : (order.store?.name ?? '');
    final String topAddress = isParcel ? (order.deliveryAddress?.address ?? '') : (order.store?.address ?? '');
    final String? topPhone = isParcel ? order.deliveryAddress?.contactPersonNumber : null;

    final AddressModel? bottom = isParcel ? order.receiverDetails : order.deliveryAddress;
    final String bottomName = bottom?.contactPersonName ?? '';
    final String bottomAddress = bottom?.address ?? '';
    final String? bottomPhone = bottom?.contactPersonNumber;

    // DEBUG: Log address values
    print('🔍 DEBUG AddressSection - isParcel: $isParcel');
    print('🔍 DEBUG AddressSection - topName: "$topName" (isEmpty: ${topName.isEmpty})');
    print('🔍 DEBUG AddressSection - topAddress: "$topAddress" (isEmpty: ${topAddress.isEmpty})');
    print('🔍 DEBUG AddressSection - store?.name: "${order.store?.name}" (null: ${order.store?.name == null})');
    print('🔍 DEBUG AddressSection - deliveryAddress?.contactPersonName: "${order.deliveryAddress?.contactPersonName}"');
    print('🔍 DEBUG AddressSection - bottomName: "$bottomName" (isEmpty: ${bottomName.isEmpty})');
    print('🔍 DEBUG AddressSection - bottomAddress: "$bottomAddress" (isEmpty: ${bottomAddress.isEmpty})');
    print('🔍 DEBUG AddressSection - receiverDetails?.contactPersonName: "${order.receiverDetails?.contactPersonName}"');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AddressTimeline(lineHeight: 52),
        const SizedBox(width: Dimensions.paddingSizeSmall),

        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            SizedBox( height: 66,
              child: _AddressEntryRow(
                title: topName ,
                address: topAddress,
                phone: topPhone,
                trailing: _AddressActionSlot(order: order),
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            _AddressEntryRow(
              title: bottomName ,
              address: bottomAddress,
              phone: bottomPhone,
            ),
          ]),
        ),
      ],
    );
  }
}


class _AddressEntryRow extends StatelessWidget {
  final String title;
  final String? phone;
  final String address;
  final Widget? trailing;

  const _AddressEntryRow({
    required this.title,
    required this.address,
    this.phone,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = Theme.of(context).disabledColor;
    final hasPhone = phone != null && phone!.trim().isNotEmpty;

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: robotoBold.copyWith(
                  fontSize: Dimensions.fontSizeLarge,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                children: [
                  TextSpan(text: title),
                  if (hasPhone)
                    TextSpan(
                      text: ' ($phone)',
                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
                    ),
                ],
              ),
            ),
            Text(
              address, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: disabled),
            ),
          ],
        ),
      ),
      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
      ?trailing,
    ]);
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    const dashHeight = 3.0;
    const dashSpace = 3.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(size.width / 2, y), Offset(size.width / 2, y + dashHeight), paint);
      y += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) => old.color != color;
}

class AddressTimeline extends StatelessWidget {
  final double lineHeight;
  final double iconSize;
  final double circleSize;
  final IconData topIcon;
  final IconData bottomIcon;
  final Color? color;

  const AddressTimeline({
    super.key,
    required this.lineHeight,
    this.iconSize = 16,
    this.circleSize = 28,
    this.topIcon = Icons.location_on_outlined,
    this.bottomIcon = Icons.near_me_outlined,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).disabledColor;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _TimelineIcon(icon: topIcon, color: tint, circleSize: circleSize, iconSize: iconSize),
      SizedBox(
        width: 2,
        height: lineHeight,
        child: CustomPaint(painter: _DashedLinePainter(color: tint)),
      ),
      _TimelineIcon(icon: bottomIcon, color: tint, circleSize: circleSize, iconSize: iconSize),
    ]);
  }
}

class _TimelineIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double circleSize;
  final double iconSize;

  const _TimelineIcon({
    required this.icon,
    required this.color,
    required this.circleSize,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: circleSize,
      height: circleSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}

class _AddressActionSlot extends StatelessWidget {
  final OrderModel order;

  const _AddressActionSlot({required this.order});

  @override
  Widget build(BuildContext context) {
    final status = order.orderStatus;
    final bool refundActive = Get.find<SplashController>().configModel?.refundActiveStatus ?? false;

    if (status == 'delivered' && refundActive) {
      return _RefundOrderPill(orderId: order.id);
    }

    if (order.orderType == 'parcel') {
      return const SizedBox.shrink();
    }

    const calling = ['accepted', 'confirmed', 'processing', 'handover', 'picked_up'];
    if (calling.contains(status)) {
      return _StoreContactActions(order: order);
    }

    return const SizedBox.shrink();
  }
}

class _StoreContactActions extends StatelessWidget {
  final OrderModel order;

  const _StoreContactActions({required this.order});

  String? get _phone {
    if (order.store?.phone != null && order.store!.phone!.isNotEmpty) {
      return order.store!.phone;
    }
    return order.store?.phone;
  }

  Future<void> _call(BuildContext context) async {
    final phone = _phone;
    if (phone == null || phone.isEmpty) {
      showCustomSnackBar('${'can_not_launch'.tr} -');
      return;
    }
    if (await canLaunchUrlString('tel:$phone')) {
      await launchUrlString('tel:$phone', mode: LaunchMode.externalApplication);
    } else {
      showCustomSnackBar('${'can_not_launch'.tr} $phone');
    }
  }

  Future<void> _chat() async {
    final store = order.store;
    if (store == null) return;
    await Get.toNamed(RouteHelper.getChatRoute(
      notificationBody: NotificationBodyModel(restaurantId: store.id, name: store.name, orderId: int.tryParse(order.id.toString())),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final canChat = order.store != null;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _SoftCircleAction(
        icon: Images.newCallIcon,
        onTap: () => _call(context),
      ),
      if (canChat) ...[
        const SizedBox(width: Dimensions.paddingSizeDefault),
        _SoftCircleAction(
          icon: Images.chattingIcon,
          onTap: () => _chat(),
        ),
        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
      ],
    ]);
  }
}

class _SoftCircleAction extends StatelessWidget {
  final String icon;
  final VoidCallback onTap;

  const _SoftCircleAction({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Image.asset(icon, width: 18, height: 18),
    );
  }
}

class _RefundOrderPill extends StatelessWidget {
  final int? orderId;

  const _RefundOrderPill({required this.orderId});

  @override
  Widget build(BuildContext context) {
    final Color errorColor = Theme.of(context).colorScheme.error;
    return InkWell(
      onTap: () => Get.toNamed(RouteHelper.getRefundRequestRoute(orderId.toString())),
      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeSmall,
          vertical: Dimensions.paddingSizeSmall,
        ),
        decoration: BoxDecoration(
          color: errorColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          boxShadow: [
            BoxShadow(color: errorColor.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.currency_exchange_rounded, size: 12, color: Colors.white),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),

          Text(
            'refund_order'.tr,
            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Colors.white),
          ),
        ]),
      ),
    );
  }
}
