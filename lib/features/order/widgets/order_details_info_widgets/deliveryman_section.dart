import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/chat/domain/models/conversation_model.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:url_launcher/url_launcher_string.dart';

class DeliveryManSection extends StatelessWidget {
  final OrderModel order;

  const DeliveryManSection({super.key, required this.order});

  Future<void> _call() async {
    final phone = order.deliveryMan?.phone;
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
    final dm = order.deliveryMan;
    if (dm == null) return;
    await Get.toNamed(RouteHelper.getChatRoute(
      notificationBody: NotificationBodyModel(deliverymanId: dm.id, orderId: int.tryParse(order.id.toString())),
      user: User(id: dm.id, fName: dm.fName, lName: dm.lName, imageFullUrl: dm.imageFullUrl),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final deliveryMan = order.deliveryMan!;
    final name = '${deliveryMan.fName ?? ''} ${deliveryMan.lName ?? ''}'.trim();
    final disabled = Theme.of(context).disabledColor;
    final bool showContactActions = order.deliveryMan != null;

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).disabledColor.withAlpha(30),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Row(children: [
        Icon(Icons.directions_bike, color: Theme.of(context).textTheme.bodyLarge?.color, size: 24),

        const SizedBox(width: Dimensions.paddingSizeSmall),

        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(name.isEmpty ? '-' : name.capitalize!, style: robotoBold, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),

            Row(children: [
              const Icon(Icons.star, color: Colors.amber, size: 12),
              const SizedBox(width: 2),
              Text(
                (deliveryMan.avgRating ?? 0).toStringAsFixed(1),
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: disabled),
              ),
              const SizedBox(width: 6),
              Text(
                '(${deliveryMan.ratingCount ?? 0})',
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: disabled),
              ),
            ]),
          ]),
        ),

        if (showContactActions) ...[
          const SizedBox(width: Dimensions.paddingSizeSmall),
          _ContactAction(icon: Images.newCallIcon, onTap: _call),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          _ContactAction(icon: Images.chattingIcon, onTap: _chat),
        ],
      ]),
    );
  }
}

class _ContactAction extends StatelessWidget {
  final String icon;
  final VoidCallback onTap;

  const _ContactAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Image.asset(icon, width: 20, height: 20),
    );
  }
}
