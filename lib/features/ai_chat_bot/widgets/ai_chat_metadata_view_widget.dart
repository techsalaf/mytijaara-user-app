import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/features/ai_chat_bot/domain/models/ai_chat_message_model.dart';
import 'package:sixam_mart/features/cart/domain/models/online_cart_model.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/store/screens/store_screen.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Tap handler for AI-chat metadata cards: when the tapped entity belongs to a
/// module other than the active one, silently activates that module first (needed
/// for the detail page's API headers/config), then navigates. setModule leaves
/// home/module-page data untouched, so no confirmation is required.
void _navigateWithModuleGuard({required int? moduleId, required VoidCallback onProceed}) {
  final SplashController splash = Get.find<SplashController>();
  if (moduleId != null && splash.module?.id != moduleId) {
    final ModuleModel? target = splash.moduleList?.firstWhereOrNull((ModuleModel m) => m.id == moduleId);
    if (target != null) {
      splash.setModule(target);
    }
  }
  onProceed();
}

class AiChatMetadataViewWidget extends StatelessWidget {
  final AiChatMetadata metadata;
  const AiChatMetadataViewWidget({super.key, required this.metadata});

  @override
  Widget build(BuildContext context) {
    final List<Widget> sections = [];

    if (metadata.hasProducts) {
      sections.add(_SectionTitle(title: 'recommended_products'.tr));
      sections.add(SizedBox(
        height: 180,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(
            left: Dimensions.paddingSizeExtraSmall,
            top: Dimensions.paddingSizeExtraSmall,
            right: Dimensions.paddingSizeExtraSmall,
          ),
          itemCount: metadata.products!.length,
          separatorBuilder: (_, _) => const SizedBox(width: Dimensions.paddingSizeSmall),
          itemBuilder: (context, index) {
            return _ProductCard(product: metadata.products![index]);
          },
        ),
      ));
    }

    if (metadata.hasCategories) {
      sections.add(const SizedBox(height: Dimensions.paddingSizeSmall));
      sections.add(_SectionTitle(title: 'categories'.tr));
      sections.add(SizedBox(
        height: 100,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          itemCount: metadata.categories!.length,
          separatorBuilder: (_, _) => const SizedBox(width: Dimensions.paddingSizeSmall),
          itemBuilder: (context, index) {
            return _CategoryCard(category: metadata.categories![index]);
          },
        ),
      ));
    }

    if (metadata.hasStores) {
      sections.add(const SizedBox(height: Dimensions.paddingSizeSmall));
      sections.add(_SectionTitle(title: 'recommended_stores'.tr));
      sections.add(SizedBox(
        height: 215,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeExtraSmall,
            vertical: Dimensions.paddingSizeExtraSmall,
          ),
          itemCount: metadata.stores!.length,
          separatorBuilder: (_, _) => const SizedBox(width: Dimensions.paddingSizeSmall),
          itemBuilder: (context, index) {
            return _AiChatStoreCard(store: metadata.stores![index]);
          },
        ),
      ));
    }

    if (metadata.hasCartItems) {
      sections.add(const SizedBox(height: Dimensions.paddingSizeSmall));
      sections.add(_SectionTitle(title: 'in_your_cart'.tr));
      sections.add(SizedBox(
        height: 90,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          itemCount: metadata.cartItems!.length,
          separatorBuilder: (_, _) => const SizedBox(width: Dimensions.paddingSizeSmall),
          itemBuilder: (context, index) {
            return _CartItemCard(cartItem: metadata.cartItems![index]);
          },
        ),
      ));
    }

    if (sections.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraSmall),
      child: Text(
        title,
        style: robotoMedium.copyWith(
          fontSize: Dimensions.fontSizeSmall,
          color: Theme.of(context).hintColor,
        ),
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final OnlineCartModel cartItem;
  const _CartItemCard({required this.cartItem});

  @override
  Widget build(BuildContext context) {
    final String name = cartItem.item?.name ?? '';
    final String image = cartItem.item?.imageFullUrl ?? '';
    final double unitPrice = cartItem.price ?? cartItem.item?.price ?? 0;
    final int qty = cartItem.quantity ?? 0;

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
          color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
          width: 0.6,
        ),
      ),
      child: CustomInkWell(
        radius: Dimensions.radiusDefault,
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              child: CustomImage(
                image: image,
                height: 56, width: 56, fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                Text(
                  name,
                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),

                Text(
                  PriceConverter.convertPrice(unitPrice),
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 2),

                Text(
                  '${'qty'.tr}: $qty',
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeExtraSmall,
                    color: Theme.of(context).hintColor,
                  ),
                ),

              ]),
            ),

          ]),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      onTap: category.id == null ? null : () => _navigateWithModuleGuard(
        moduleId: category.moduleId,
        onProceed: () => Get.toNamed(RouteHelper.getCategoryItemRoute(
          category.id, category.name ?? '', moduleId: category.moduleId, slug: category.slug ?? 'category_${category.id}',
        )),
      ),
      child: SizedBox(
        width: 90,
        child: Column(children: [
          Container(
            height: 60, width: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              child: CustomImage(
                image: category.imageFullUrl ?? '',
                height: 60, width: 60, fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

          Text(
            category.name ?? '',
            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall),
            maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
          ),

        ]),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Item product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final double price = product.price ?? 0;
    final double discount = product.discount ?? 0;
    final String? discountType = product.discountType;
    final double discountedPrice = PriceConverter.convertWithDiscount(price, discount, discountType) ?? price;
    final bool hasDiscount = discount > 0 && discountedPrice < price;

    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
          color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
          width: 0.6,
        ),
      ),
      child: CustomInkWell(
        radius: Dimensions.radiusDefault,
        onTap: () => _navigateWithModuleGuard(
          moduleId: product.moduleId,
          onProceed: () => Get.find<ItemController>().navigateToItemPage(product, context),
        ),
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          Stack(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              child: CustomImage(
                image: product.imageFullUrl ?? '',
                height: 90, width: double.infinity, fit: BoxFit.cover,
              ),
            ),
            if (hasDiscount)
              Positioned(
                top: Dimensions.paddingSizeExtraSmall,
                left: Dimensions.paddingSizeExtraSmall,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeExtraSmall,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  ),
                  child: Text(
                    discountType == 'percent'
                        ? '${discount.toStringAsFixed(0)}% ${'off'.tr}'
                        : '${PriceConverter.convertPrice(discount)} ${'off'.tr}',
                    style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          Text(
            product.name ?? '',
            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),

          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [

            Flexible(
              child: Text(
                PriceConverter.convertPrice(discountedPrice),
                style: robotoBold.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).primaryColor,
                ),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ),

            if (hasDiscount) ...[
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              Flexible(
                child: Text(
                  PriceConverter.convertPrice(price),
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeExtraSmall,
                    color: Theme.of(context).hintColor,
                    decoration: TextDecoration.lineThrough,
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

          ]),

        ]),
      ),
    );
  }
}

class _AiChatStoreCard extends StatelessWidget {
  final Store store;
  const _AiChatStoreCard({required this.store});

  void _openStore() {
    if (store.id == null) {
      return;
    }
    _navigateWithModuleGuard(
      moduleId: store.moduleId,
      onProceed: () => Get.toNamed(
        RouteHelper.getStoreRoute(id: store.id, page: 'store', slug: store.slug ?? 'store_${store.id}', moduleId: store.moduleId?.toString()),
        arguments: StoreScreen(store: store, fromModule: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOpen = store.open == 1;
    final double rating = store.avgRating ?? 0;
    final int ratingCount = store.ratingCount ?? 0;
    final double distanceKm = store.distance ?? 0;
    final bool hasDistance = store.distance != null && store.distance! > 0;
    final bool freeDelivery = store.freeDelivery == true;
    final String deliveryTime = store.deliveryTime ?? '';

    final double discountAmount = store.discount?.discount ?? 0;
    final bool isPercentDiscount = store.discount?.discountType == 'percent';
    final bool hasDiscount = discountAmount > 0;
    final String discountText = hasDiscount
        ? (isPercentDiscount
            ? '${discountAmount.toStringAsFixed(0)}% ${'off'.tr}'
            : '${PriceConverter.convertPrice(discountAmount)} ${'off'.tr}')
        : '';

    const Color openColor = Color(0xff1FA84B);
    final Color closedColor = Theme.of(context).colorScheme.error;

    return Container(
      width: 230,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
          color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
          width: 0.6,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.08),
            blurRadius: 4, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        onTap: _openStore,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          Stack(children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(Dimensions.radiusDefault),
                topRight: Radius.circular(Dimensions.radiusDefault),
              ),
              child: CustomImage(
                image: store.coverPhotoFullUrl ?? '',
                height: 90, width: 230, fit: BoxFit.cover,
              ),
            ),

            if (hasDiscount)
              Positioned(
                top: Dimensions.paddingSizeExtraSmall,
                left: Dimensions.paddingSizeExtraSmall,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeExtraSmall, vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  ),
                  child: Text(
                    discountText,
                    style: robotoMedium.copyWith(
                      color: Colors.white, fontSize: Dimensions.fontSizeExtraSmall,
                    ),
                  ),
                ),
              ),

            Positioned(
              top: Dimensions.paddingSizeExtraSmall,
              right: Dimensions.paddingSizeExtraSmall,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeExtraSmall, vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: (isOpen ? openColor : closedColor).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                ),
                child: Text(
                  isOpen ? 'open_now'.tr : 'closed_now'.tr,
                  style: robotoMedium.copyWith(
                    color: Colors.white, fontSize: Dimensions.fontSizeOverSmall,
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: -18, left: Dimensions.paddingSizeSmall,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
                    width: 0.6,
                  ),
                ),
                child: ClipOval(
                  child: CustomImage(
                    image: store.logoFullUrl ?? '',
                    height: 36, width: 36, fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ]),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              Dimensions.paddingSizeSmall,
              Dimensions.paddingSizeLarge + 2,
              Dimensions.paddingSizeSmall,
              Dimensions.paddingSizeSmall,
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              Text(
                store.name ?? '',
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),

              Row(children: [
                Icon(Icons.star_rounded, size: 14, color: Theme.of(context).primaryColor),
                const SizedBox(width: 2),
                Text(
                  rating > 0 ? rating.toStringAsFixed(1) : '-',
                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall),
                ),
                if (ratingCount > 0) ...[
                  const SizedBox(width: 2),
                  Text(
                    '($ratingCount)',
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeOverSmall,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ]),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),

              if (deliveryTime.isNotEmpty)
                Row(children: [
                  Icon(Icons.access_time_rounded, size: 13, color: Theme.of(context).hintColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      deliveryTime,
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeOverSmall,
                        color: Theme.of(context).hintColor,
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              if (deliveryTime.isNotEmpty) const SizedBox(height: 2),

              if (hasDistance)
                Row(children: [
                  Icon(Icons.place_outlined, size: 13, color: Theme.of(context).hintColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${distanceKm > 100 ? '100+' : distanceKm.toStringAsFixed(2)} ${'km'.tr}',
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeOverSmall,
                        color: Theme.of(context).hintColor,
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              if (hasDistance) const SizedBox(height: Dimensions.paddingSizeExtraSmall),

              if (freeDelivery)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeExtraSmall, vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  ),
                  child: Text(
                    'free_delivery'.tr,
                    style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeOverSmall,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),

            ]),
          ),

        ]),
      ),
    );
  }
}
