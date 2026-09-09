import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class OrderStatusHistorySheet extends StatelessWidget {
  final OrderModel order;

  const OrderStatusHistorySheet({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps(order);
    final completedSteps = steps.where((s) => s.isCompleted).toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge)),
      ),
      padding: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeSmall,
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeLarge,
      ),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [

          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                color: Theme.of(context).disabledColor.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Row(children: [
            Expanded(
              child: Text(
                'order_history'.tr,
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
              ),
            ),
            InkWell(
              onTap: () => Get.back(),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).disabledColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, size: 18, color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
            ),
          ]),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          for (int i = 0; i < completedSteps.length; i++)
            _StatusHistoryStep(
              step: completedSteps[i],
              isFirst: i == 0,
              isLast: i == completedSteps.length - 1,
            ),
        ]),
      ),
    );
  }

  static List<_HistoryStep> _buildSteps(OrderModel order) {
    // Top-to-bottom: future statuses first, completed statuses at the bottom.
    return [
      _HistoryStep(
        label: 'cancelled'.tr,
        description: 'order_cancelled'.tr,
        timestamp: order.canceled,
      ),
      _HistoryStep(
        label: 'refunded'.tr,
        description: 'refund_completed'.tr,
        timestamp: order.refunded,
      ),
      _HistoryStep(
        label: 'refund_requested'.tr,
        description: 'refund_requested_description'.tr,
        timestamp: order.refundRequested,
      ),
      _HistoryStep(
        label: 'failed'.tr,
        description: 'payment_failed_description'.tr,
        timestamp: order.failed ?? (order.orderStatus == 'failed' ? order.updatedAt : null),
      ),
      _HistoryStep(
        label: 'delivered'.tr,
        description: 'will_enjoy_your_food'.tr,
        timestamp: order.delivered,
      ),
      _HistoryStep(
        label: 'picked_up'.tr,
        description: 'after_handover'.tr,
        timestamp: order.pickedUp,
      ),
      _HistoryStep(
        label: 'order_handover'.tr,
        description: 'after_preparation'.tr,
        timestamp: order.handover,
      ),
      _HistoryStep(
        label: 'preparing_item'.tr,
        description: 'your_item_are_preparing'.tr,
        timestamp: order.processing,
      ),
      _HistoryStep(
        label: 'order_accepted'.tr,
        description: 'waiting_for_preparation'.tr,
        timestamp: order.accepted,
      ),
      _HistoryStep(
        label: 'order_confirmed'.tr,
        description: 'waiting_for_confirmation'.tr,
        timestamp: order.confirmed,
      ),
      _HistoryStep(
        label: 'order_placed'.tr,
        description: 'waiting_for_confirmation'.tr,
        timestamp: order.pending ?? order.createdAt,
      ),
    ];
  }
}

class _HistoryStep {
  final String label;
  final String description;
  final String? timestamp;

  const _HistoryStep({
    required this.label,
    required this.description,
    required this.timestamp,
  });

  bool get isCompleted => timestamp != null && timestamp!.trim().isNotEmpty;
}

class _StatusHistoryStep extends StatelessWidget {
  final _HistoryStep step;
  final bool isFirst;
  final bool isLast;

  const _StatusHistoryStep({
    required this.step,
    required this.isFirst,
    required this.isLast,
  });

  String _formatTimestamp(String raw) {
    try {
      return DateFormat('d MMM y h:mm a').format(DateTime.parse(raw).toLocal());
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final disabled = Theme.of(context).disabledColor;
    final completed = step.isCompleted;

    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

        SizedBox(
          width: 28,
          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            _StepDot(completed: completed, primary: primary, disabled: disabled),
            if (!isLast)
              Expanded(
                child: CustomPaint(
                  painter: _DashedLinePainter(color: disabled.withValues(alpha: 0.6)),
                  size: const Size(2, double.infinity),
                ),
              ),
          ]),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),

        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : Dimensions.paddingSizeDefault),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                step.label,
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
              ),
              const SizedBox(height: 2),
              Text(
                completed ? _formatTimestamp(step.timestamp!) : step.description,
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: disabled,
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool completed;
  final Color primary;
  final Color disabled;

  const _StepDot({required this.completed, required this.primary, required this.disabled});

  @override
  Widget build(BuildContext context) {
    if (completed) {
      return Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
        child: Icon(Icons.check, color: Theme.of(context).cardColor, size: 16),
      );
    }
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: disabled.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.check, color: disabled, size: 14),
    );
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
    const dashHeight = 4.0;
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
