import 'package:flutter/material.dart';
import 'package:full_screen_bottom_sheet/full_screen_bottom_sheet.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/bundle/controllers/bundle_controller.dart';
import 'package:sixam_mart/features/bundle/domain/models/bundle_model.dart';
import 'package:sixam_mart/features/bundle/widgets/bundle_item_details_bottom_sheet.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/image_cache_helper.dart';
import 'package:sixam_mart/helper/module_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class BundleDetailsBottomSheet extends StatefulWidget {
  final int bundleId;
  final int? storeId;

  const BundleDetailsBottomSheet({super.key, required this.bundleId, this.storeId});

  static void show(BuildContext context, {int? bundleId, int? storeId}) {
    if(bundleId == null) {
      return;
    }
    final Widget sheet = BundleDetailsBottomSheet(bundleId: bundleId, storeId: storeId);
    if(ResponsiveHelper.isMobile(context)) {
      Get.bottomSheet(
        sheet,
        isScrollControlled: true,
        ignoreSafeArea: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        useRootNavigator: true,
      );
    }
  }

  @override
  State<BundleDetailsBottomSheet> createState() => _BundleDetailsBottomSheetState();
}

class _BundleDetailsBottomSheetState extends State<BundleDetailsBottomSheet> {
  @override
  void initState() {
    super.initState();

    final CartModel? existing = Get.find<CartController>().findBundleInCart(widget.bundleId, storeId: widget.storeId);
    Get.find<BundleController>().getBundleDetails(
      widget.bundleId, quantity: existing?.quantity ?? 1, notify: false,
    );
  }

  void _openItem(BuildContext context, BundleMemberItem item, Bundle bundle) {
    if(item.targetId == null) {
      return;
    }
    BundleItemDetailsBottomSheet.show(
      context, item: item, storeName: bundle.storeName, storeLogoFullUrl: bundle.storeLogoFullUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
      return GetBuilder<BundleController>(builder: (bundleController) {
        final Bundle? bundle = bundleController.bundleDetails;

        if(bundle == null) {
          return FullScreenBottomSheet(
            initialExtent: .9,
            backgroundColor: theme.cardColor,
            child: const _BundleDetailsBodyShimmer(),
            footerBuilder: (context, metrics) => const _BundleDetailsFooterShimmer(),
          );
        }

        final List<BundleMemberItem> members = bundle.items ?? const <BundleMemberItem>[];
        final String reason = !bundle.isAvailable ? (bundle.unavailableReason ?? '') : '';

        return FullScreenBottomSheet(
          initialExtent: 1.0,
          backgroundColor: theme.cardColor,
          headerBuilder: (context, metrics) => _Header(title: bundle.name ?? '', topPadding: metrics.statusBarPadding),
          headerExtent: (metrics) => metrics.statusBarPadding + _Header.heightOf(context),
          slivers: (context, scrollController) => [
            SliverToBoxAdapter(child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              itemCount: members.length,
              separatorBuilder: (context, index) => Divider(height: 1, thickness: 1, color: theme.disabledColor.withValues(alpha: 0.2)),
              itemBuilder: (context, index) => _BundleOfferItemRow(
                member: members[index],
                onTap: () => _openItem(context, members[index], bundle),
              ),
            )),

            if(reason.isNotEmpty) SliverToBoxAdapter(child: _UnavailableNote(reason: reason)),
          ],
          footerBuilder: (context, metrics) => _Footer(bundle: bundle, storeId: widget.storeId),
        );
      });
  }
}

Widget _shimmerBox(Color base, double width, double height, {double radius = Dimensions.radiusSmall}) => Container(
  width: width, height: height,
  decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(radius)),
);

class _BundleDetailsBodyShimmer extends StatelessWidget {
  const _BundleDetailsBodyShimmer();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color base = theme.disabledColor.withValues(alpha: 0.15);
    Widget box(double width, double height, {double radius = Dimensions.radiusSmall}) => _shimmerBox(base, width, height, radius: radius);

    Widget memberRow() => Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        box(60, 60),
        const SizedBox(width: Dimensions.paddingSizeDefault),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          box(140, 14),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          box(70, 14),
        ])),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        box(34, 26),
      ]),
    );

    return Shimmer(
      duration: const Duration(seconds: 2),
      child: Column(mainAxisSize: MainAxisSize.min, children: [

        // Header: title + close button
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeSmall, Dimensions.paddingSizeSmall,
          ),
          child: Row(children: [
            Expanded(child: box(160, 20)),
            const SizedBox(width: Dimensions.paddingSizeDefault),
            Container(width: 30, height: 30, decoration: BoxDecoration(color: base, shape: BoxShape.circle)),
          ]),
        ),
        Divider(height: 1, thickness: 1, color: theme.disabledColor.withValues(alpha: 0.2)),

        // Member rows
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: Column(children: [
            memberRow(),
            Divider(height: 1, thickness: 1, color: theme.disabledColor.withValues(alpha: 0.2)),
            memberRow(),
            Divider(height: 1, thickness: 1, color: theme.disabledColor.withValues(alpha: 0.2)),
            memberRow(),
          ]),
        ),
      ]),
    );
  }
}

class _BundleDetailsFooterShimmer extends StatelessWidget {
  const _BundleDetailsFooterShimmer();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color base = theme.disabledColor.withValues(alpha: 0.15);
    Widget box(double width, double height, {double radius = Dimensions.radiusSmall}) => _shimmerBox(base, width, height, radius: radius);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [

        Divider(height: 1, thickness: 1, color: theme.disabledColor.withValues(alpha: 0.2)),

        Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeDefault), child: Shimmer(
          duration: const Duration(seconds: 2),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              box(80, 16),
              const Spacer(),
              box(90, 20),
            ]),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Row(children: [
              box(40, 40, radius: Dimensions.radiusDefault),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              box(20, 20),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              box(40, 40, radius: Dimensions.radiusDefault),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              Expanded(child: box(double.infinity, 44, radius: Dimensions.radiusDefault)),
            ]),
          ]),
        )),
      ])),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final double topPadding;
  const _Header({required this.title, required this.topPadding});

  static const double _closeButtonSize = 30;
  static const double _dividerHeight = 1;

  static double heightOf(BuildContext context) {
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final double titleLine = scaler.scale(Dimensions.fontSizeExtraLarge * 1.3);
    return Dimensions.paddingSizeDefault
        + (titleLine > _closeButtonSize ? titleLine : _closeButtonSize)
        + Dimensions.paddingSizeSmall + _dividerHeight;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Pinned over the list, so without a fill of its own the rows scroll through it.
    return ColoredBox(
      color: theme.cardColor,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault + topPadding,
            Dimensions.paddingSizeSmall, Dimensions.paddingSizeSmall,
          ),
          child: Row(children: [
            Expanded(child: Text(
              title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
            )),

            InkWell(
              onTap: () => Get.back(),
              customBorder: const CircleBorder(),
              child: Container(
                height: _closeButtonSize, width: _closeButtonSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.disabledColor.withValues(alpha: 0.12),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.close, size: 16, color: theme.textTheme.bodyLarge?.color),
              ),
            ),
          ]),
        ),

        Divider(height: _dividerHeight, thickness: _dividerHeight, color: theme.disabledColor.withValues(alpha: 0.2)),
      ]),
    );
  }
}
class _UnavailableNote extends StatelessWidget {
  final String reason;
  const _UnavailableNote({required this.reason});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall,
        Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall,
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.error_outline, size: 16, color: theme.colorScheme.error),
        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
        Expanded(child: Text(
          reason,
          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: theme.colorScheme.error),
        )),
      ]),
    );
  }
}

class _BundleOfferItemRow extends StatelessWidget {
  final BundleMemberItem member;
  final VoidCallback onTap;
  const _BundleOfferItemRow({required this.member, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

          ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            child: CustomImage(
              image: member.imageFullUrl ?? '', height: 60, width: 60, fit: BoxFit.cover,
              cacheWidth: ImageCacheHelper.pixels(context, 60)
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeDefault),

          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            Text(
              member.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
            ),
            const SizedBox(height: 2),

            Text(
              PriceConverter.convertPrice(member.unitPrice),
              textDirection: TextDirection.ltr,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
            ),

            if((member.unitType ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${'unit'.tr} : ${member.unitType}',
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: theme.hintColor),
                ),
              ),

            if((member.variationSummary ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${'variation'.tr} : ${member.variationSummary}', maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: theme.hintColor),
                ),
              ),

            if((member.addOnSummary ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${'addons'.tr} : ${member.addOnSummary}', maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: theme.hintColor),
                ),
              ),
          ])),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          Container(
            constraints: const BoxConstraints(minWidth: 34),
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall,
            ),
            decoration: BoxDecoration(
              color: theme.disabledColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            ),
            alignment: Alignment.center,
            child: Text('${member.quantity}', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
          ),
        ]),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final Bundle bundle;
  final int? storeId;
  const _Footer({required this.bundle, this.storeId});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return GetBuilder<CartController>(builder: (cartController) {
      return GetBuilder<BundleController>(builder: (bundleController) {
        final CartModel? existing = cartController.findBundleInCart(bundle.id, storeId: storeId ?? bundle.storeId);
        final bool isInCart = existing != null;
        final int quantity = bundleController.detailsQuantity;
        final bool isLast = isInCart && quantity == 1;

        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2))],
          ),
          child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [

            Divider(height: 1, thickness: 1, color: theme.disabledColor.withValues(alpha: 0.2)),

            Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeDefault), child: Column(mainAxisSize: MainAxisSize.min, children: [

            Row(children: [
              Text('total'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              Expanded(child: Get.find<SplashController>().configModel?.systemTaxIncludeStatus == 1 ? Text(
                'inc_vat_tax'.tr,
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: theme.hintColor),
              ) : const SizedBox.shrink()),

              if(bundle.hasSaving)
                Padding(
                  padding: const EdgeInsets.only(right: Dimensions.paddingSizeExtraSmall),
                  child: Text(
                    PriceConverter.convertPrice(bundle.basePrice * quantity),
                    textDirection: TextDirection.ltr,
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall, color: theme.hintColor,
                      decoration: TextDecoration.lineThrough, decorationColor: theme.hintColor,
                    ),
                  ),
                ),

              Text(
                PriceConverter.convertPrice(bundle.finalPrice * quantity),
                textDirection: TextDirection.ltr,
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
              ),
            ]),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            Row(children: [

              _StepperButton(
                icon: isLast ? Icons.delete_outline : Icons.remove,
                color: isLast ? theme.colorScheme.error : theme.textTheme.bodyLarge?.color,
                onTap: cartController.isLoading ? null : () {
                  if(isLast) {
                    cartController.removeBundle(existing).then((_) => Get.back());
                  } else {
                    bundleController.setDetailsQuantity(quantity - 1);
                  }
                },
              ),

              SizedBox(
                width: 40,
                child: Text(
                  '$quantity', textAlign: TextAlign.center,
                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
                ),
              ),

              _StepperButton(
                icon: Icons.add,
                color: theme.textTheme.bodyLarge?.color,
                onTap: cartController.isLoading ? null : () => bundleController.setDetailsQuantity(quantity + 1),
              ),
              const SizedBox(width: Dimensions.paddingSizeDefault),

              Expanded(child: CustomButton(
                buttonText: isInCart ? 'update_cart'.tr : 'add_to_cart'.tr,
                isLoading: cartController.isLoading,
                radius: Dimensions.radiusDefault,
                onPressed: !bundle.isAvailable || bundle.id == null ? null : () async {
                  final bool isSuccess = isInCart
                      ? await cartController.setBundleQuantity(existing, quantity)
                      : await cartController.addBundleToCart(bundle.id!, quantity);
                  if(isSuccess) {
                    Get.back();
                    final String message = isInCart ? 'cart_updated'.tr : 'bundle_added_to_cart'.tr;

                    if(ModuleHelper.isBookingModule()) {
                      showCustomSnackBar(
                        message, isError: false,
                        actionLabel: 'view_cart'.tr,
                        onAction: () => Get.toNamed(RouteHelper.getGlobalCartRoute()),
                      );
                    } else {
                      RouteHelper.openCart(storeId: storeId ?? bundle.storeId);
                      showCustomSnackBar(message, isError: false);
                    }
                  }
                },
              )),
            ]),
            ])),
          ])),
        );
      });
    });
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;
  const _StepperButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        height: 40, width: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).disabledColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

// SUMMARY
// Full-screen sheet for one bundle. Lists every member with its locked variation,
// add-ons and quantity, states why an unavailable bundle cannot be bought, and holds
// the total, the copy stepper and the only add-to-cart there is for a bundle — which
// closes the sheet and opens the cart.
