part of '../screens/order_details_new_screen.dart';

class _OrderDetailsStatus extends StatelessWidget {
  final OrderModel order;
  final bool ongoing;

  const _OrderDetailsStatus({required this.order, required this.ongoing});

  void _showHistorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => OrderStatusHistorySheet(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFood = order.moduleType == 'food';
    final showTimer = isFood  && ongoing  && DateConverter.isBeforeTime(order.scheduleAt)
        && (Get.find<SplashController>().getModuleConfig(order.moduleType).newVariation ?? false);

    final bool isParcel = order.orderType == 'parcel';
    final _StatusContent content = _StatusContent.resolve(order.orderType, order.orderStatus);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeLarge),
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showHistorySheet(context),
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              SizedBox(
                width: order.orderStatus == 'pending' || (order.orderStatus == 'processing' && order.moduleType == 'food') ? 80 : 60,
                height: order.orderStatus == 'pending' || (order.orderStatus == 'processing' && order.moduleType == 'food') ? 80 : 60,
                child: Image.asset(_StatusBannerImage.resolve(order.moduleType, order.orderStatus),
                fit: order.orderStatus == 'pending' ? BoxFit.cover : BoxFit.contain),
              ),
              SizedBox(width: order.orderStatus == 'pending'  ? 0 : Dimensions.paddingSizeDefault),

              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (showTimer)
                    _RestaurantTimer(order: order)
                  else if (order.orderStatus == 'pending' && !isParcel)
                    const SizedBox.shrink()
                  else
                    Text(
                      content.title,
                      style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
                    ),

                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                  Text(
                    content.sentence,
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                ]),
              ),

              Icon(
                Get.find<LocalizationController>().isLtr ? Icons.arrow_forward : Icons.arrow_back,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _RestaurantTimer extends StatelessWidget {
  final OrderModel order;

  const _RestaurantTimer({required this.order});

  @override
  Widget build(BuildContext context) {
    final minutes = DateConverter.differenceInMinute(
      order.store!.deliveryTime,
      order.createdAt,
      order.processingTime,
      order.scheduleAt,
    );
    final range = minutes < 5 ? '1 - 5' : '${minutes - 5} - $minutes';

    return Text(
      "$range ${'mins'.tr}".capitalize!,
      style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
      textDirection: TextDirection.ltr,
    );
  }
}

class _StatusBannerImage {
  static String resolve(String? moduleType, String? status) {
    print('==========>> status: [$status],  moduleType: [$moduleType] <<==========');

    if (status == 'pending') {
      return Images.pendingOrderDetails;
    } else if (status == 'confirmed' || status == 'accepted') {
      return Images.confirmedGif;
    } else if (status == 'processing') {
      if (moduleType == 'food') {
        return Images.preparingFoodOrderDetails;
      } else if (moduleType == 'grocery') {
        return Images.preparingGroceryOrderDetails;
      } else {
        return Images.processingGif;
      }
    } else if (status == 'handover' || status == 'picked_up') {
      return Images.onTheWayGif;
    } else if (status == 'delivered') {
      return Images.taxiCompletedGif;
    } else if (status == 'canceled') {
      return Images.cancelGif;
    } else if (status == 'failed') {
      return Images.unverifiedIcon;
    }

    return Images.ongoingAnimation;
  }
}

class _StatusContent {
  final String title;
  final String sentence;
  const _StatusContent({required this.title, required this.sentence});

  static _StatusContent resolve(String? orderType, String? status) {
    if (orderType == 'parcel') {
      return _StatusContent(title: _parcelTitle(status), sentence: _parcelSentence(status));
    }
    return _StatusContent(title: _StatusTitle.resolve(status), sentence: _StatusSentence.resolve(status));
  }

  static String _parcelTitle(String? status) {
    switch (status) {
      case 'pending':
        return 'request_placed'.tr;
      case 'delivered':
        return 'delivered'.tr;
      case 'canceled':
        return 'request_cancelled'.tr;
      case 'failed':
        return 'order_cancelled'.tr;
      default:
        return (status ?? '').tr;
    }
  }

  static String _parcelSentence(String? status) {
    switch (status) {
      case 'pending':
        return 'we_are_processing_your_request_confirmation_coming_soon'.tr;
      case 'confirmed':
      case 'accepted':
      case 'processing':
      case 'handover':
        return 'your_request_is_confirmed_a_rider_will_pick_it_up_soon'.tr;
      case 'picked_up':
      case 'out_for_delivery':
        return 'your_parcel_is_on_the_way_to_the_destination'.tr;
      case 'delivered':
        return 'reached_your_destination_thanks_for_choosing'.tr;
      case 'canceled':
        return 'your_delivery_request_has_been_cancelled'.tr;
      case 'failed':
        return 'order_cancelled'.tr;
      default:
        return (status ?? '').tr;
    }
  }
}

class _StatusTitle {
  static String resolve(String? status) {
    if (status == 'delivered') return 'order_delivered'.tr;
    return (status ?? '').tr;
  }
}

class _StatusSentence {
  static String resolve(String? status) {
    switch (status) {
      case 'pending':
        return 'your_order_has_been_placed_waiting_for_confirmation'.tr;
      case 'confirmed':
      case 'accepted':
      case 'processing':
      case 'handover':
        return 'your_order_is_confirmed_and_being_prepared'.tr;
      case 'picked_up':
        return 'order_picked_up_on_the_way'.tr;
      case 'delivered':
        return 'enjoy_your_food'.tr;
      case 'canceled':
      case 'failed':
        return 'order_cancelled'.tr;
      default:
        return (status ?? '').tr;
    }
  }
}
