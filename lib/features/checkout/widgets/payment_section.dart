import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/checkout/widgets/payment_method_bottom_sheet.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/string_extension.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class PaymentSection extends StatelessWidget {
  final int? storeId;
  final bool isCashOnDeliveryActive;
  final bool isDigitalPaymentActive;
  final bool isWalletActive;
  final double total;
  final CheckoutController checkoutController;
  final bool isOfflinePaymentActive;
  const PaymentSection({
    super.key,
    this.storeId,
    required this.isCashOnDeliveryActive,
    required this.isDigitalPaymentActive,
    required this.isWalletActive,
    required this.total,
    required this.checkoutController,
    required this.isOfflinePaymentActive,
  });

  bool get _anyMethodActive =>
      isCashOnDeliveryActive || isDigitalPaymentActive || isWalletActive || isOfflinePaymentActive;

  void _openPicker(BuildContext context) {
    if (!_anyMethodActive) {
      showCustomSnackBar('no_payment_method_found'.tr);
      return;
    }
    final sheet = PaymentMethodBottomSheet(
      isCashOnDeliveryActive: isCashOnDeliveryActive,
      isDigitalPaymentActive: isDigitalPaymentActive,
      totalPrice: total,
      isOfflinePaymentActive: isOfflinePaymentActive,
    );
    if (ResponsiveHelper.isDesktop(context)) {
      Get.dialog(Dialog(backgroundColor: Colors.transparent, child: sheet));
    } else {
      Get.bottomSheet(sheet, backgroundColor: Colors.transparent, isScrollControlled: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CheckoutController>(builder: (controller) {
      final bool isReorderCod = storeId != null && controller.paymentMethodIndex == 0;
      final bool methodSelected = controller.paymentMethodIndex != -1;
      final bool partial = controller.isPartialPay;

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        _PaymentHeader(
          showEdit: methodSelected && !isReorderCod,
          onEdit: () => _openPicker(context),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        if (isReorderCod)
          _ReorderCodReadonlyRow(total: total)
        else if (!methodSelected)
          _PaymentEmptyButton(onTap: () => _openPicker(context))
        else if (partial)
          _PaymentPartialRows(
            controller: controller,
            total: total,
          )
        else
          _PaymentSingleRow(
            controller: controller,
            total: controller.viewTotalPrice ?? total,
          ),
      ]);
    });
  }
}

class _PaymentHeader extends StatelessWidget {
  final bool showEdit;
  final VoidCallback onEdit;

  const _PaymentHeader({required this.showEdit, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('payment_method'.tr, style: robotoBold),
          const SizedBox(height: 2),
          Text(
            'add_at_least_one_option_to_pay_your_order'.tr,
            style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: Theme.of(context).disabledColor,
            ),
          ),
        ]),
      ),
      if (showEdit)
        GestureDetector(
          onTap: onEdit,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
            child: Icon(Icons.edit_outlined, size: 18, color: Theme.of(context).primaryColor),
          ),
        ),
    ]);
  }
}

class _PaymentEmptyButton extends StatelessWidget {
  final VoidCallback onTap;

  const _PaymentEmptyButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.add_circle_outline, size: 20, color: Theme.of(context).textTheme.bodyLarge!.color),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Text(
            'add_payment_method'.tr,
            style: robotoBold.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ]),
      ),
    );
  }
}

class _PaymentSingleRow extends StatelessWidget {
  final CheckoutController controller;
  final double total;

  const _PaymentSingleRow({required this.controller, required this.total});

  @override
  Widget build(BuildContext context) {
    return _PaymentMethodRow(
      iconAsset: _PaymentRowHelper.iconForIndex(controller.paymentMethodIndex),
      label: _PaymentRowHelper.labelForIndex(controller),
      amount: total,
    );
  }
}

class _PaymentPartialRows extends StatelessWidget {
  final CheckoutController controller;
  final double total;

  const _PaymentPartialRows({required this.controller, required this.total});

  @override
  Widget build(BuildContext context) {
    final double walletBalance = Get.find<ProfileController>().userInfoModel?.walletBalance ?? 0;
    final double walletShare = walletBalance.clamp(0, total).toDouble();
    final double remainder = (total - walletShare).clamp(0, total).toDouble();
    final bool secondarySet = controller.paymentMethodIndex != -1 && controller.paymentMethodIndex != 1;

    return Column(children: [
      _PaymentMethodRow(
        iconAsset: Images.wallet,
        label: 'wallet_payment'.tr,
        amount: walletShare,
      ),
      const SizedBox(height: Dimensions.paddingSizeDefault),
      secondarySet
          ? _PaymentMethodRow(
              iconAsset: _PaymentRowHelper.iconForIndex(controller.paymentMethodIndex),
              label: _PaymentRowHelper.labelForIndex(controller),
              amount: remainder,
            )
          : _PaymentMethodRow(
              iconAsset: Images.cash,
              label: 'select_payment_method'.tr,
              amount: null,
            ),
    ]);
  }
}

class _ReorderCodReadonlyRow extends StatelessWidget {
  final double total;

  const _ReorderCodReadonlyRow({required this.total});

  @override
  Widget build(BuildContext context) {
    return _PaymentMethodRow(
      iconAsset: Images.cash,
      label: 'cash_on_delivery'.tr,
      amount: total,
    );
  }
}

class _PaymentMethodRow extends StatelessWidget {
  final String iconAsset;
  final String label;
  final double? amount;

  const _PaymentMethodRow({required this.iconAsset, required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).disabledColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        ),
        alignment: Alignment.center,
        child: Image.asset(
          iconAsset,
          width: 20, height: 20,
          color: Theme.of(context).disabledColor,
        ),
      ),
      const SizedBox(width: Dimensions.paddingSizeDefault),
      Expanded(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: robotoMedium.copyWith(
            fontSize: Dimensions.fontSizeDefault,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ),
      if (amount != null)
        Text(
          PriceConverter.convertPrice(amount),
          textDirection: TextDirection.ltr,
          style: robotoMedium.copyWith(
            fontSize: Dimensions.fontSizeDefault,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
    ]);
  }
}

class _PaymentRowHelper {
  static String iconForIndex(int index) {
    switch (index) {
      case 0:
        return Images.cash;
      case 1:
        return Images.wallet;
      case 2:
        return Images.digitalPayment;
      case 3:
        return Images.cash;
      default:
        return Images.cash;
    }
  }

  static String labelForIndex(CheckoutController c) {
    switch (c.paymentMethodIndex) {
      case 0:
        return c.isPartialPay ? '${'cash_on_delivery'.tr} (${'partial'.tr})' : 'cash_on_delivery'.tr;
      case 1:
        return 'wallet_payment'.tr;
      case 2:
        final String name = c.digitalPaymentName?.replaceAll('_', ' ').toTitleCase() ?? '';
        if (name.isEmpty) return 'digital_payment'.tr;
        return c.isPartialPay ? '$name (${'partial'.tr})' : name;
      case 3:
        final List? methods = c.offlineMethodList;
        final int idx = c.selectedOfflineBankIndex;
        final String methodName = (methods != null && idx >= 0 && idx < methods.length)
            ? (methods[idx].methodName ?? '')
            : '';
        final String base = methodName.isNotEmpty ? '${'offline_payment'.tr} ($methodName)' : 'offline_payment'.tr;
        return c.isPartialPay ? '$base - ${'partial'.tr}' : base;
      default:
        return 'select_payment_method'.tr;
    }
  }
}
