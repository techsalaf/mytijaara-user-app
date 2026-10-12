import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/avg_review_widget.dart';
import 'package:sixam_mart/common/widgets/custom_asset_image_widget.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/item_bottom_sheet_shimmer.dart';
import 'package:sixam_mart/features/bundle/domain/models/bundle_model.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/image_cache_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class BundleItemDetailsBottomSheet extends StatefulWidget {
  final BundleMemberItem item;
  final String? storeName;
  final String? storeLogoFullUrl;

  const BundleItemDetailsBottomSheet({super.key, required this.item, this.storeName, this.storeLogoFullUrl});

  static void show(BuildContext context, {required BundleMemberItem item, String? storeName, String? storeLogoFullUrl}) {
    final Widget sheet = BundleItemDetailsBottomSheet(
      item: item, storeName: storeName, storeLogoFullUrl: storeLogoFullUrl,
    );
    if(ResponsiveHelper.isMobile(context)) {
      Get.bottomSheet(
        sheet,
        isScrollControlled: true,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        useRootNavigator: true,
      );
    }
  }

  @override
  State<BundleItemDetailsBottomSheet> createState() => _BundleItemDetailsBottomSheetState();
}

const double _barHeight = 56;
const double _barContentHeight = 40;

class _BundleItemDetailsBottomSheetState extends State<BundleItemDetailsBottomSheet> {
  static const int _collapsedDescriptionLimit = 200;

  Item? _itemDetails;
  bool _detailsLoaded = false;
  bool _isDescriptionExpanded = false;
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  final GlobalKey _contentKey = GlobalKey();
  double? _measuredFraction;
  final GlobalKey _viewportKey = GlobalKey();
  final GlobalKey _titleKey = GlobalKey();
  final ValueNotifier<double> _barTitleOpacity = ValueNotifier<double>(0);
  static const double _titleFadeDistance = 24;
  final ValueNotifier<double> _barTopInset = ValueNotifier<double>(0);
  late final TapGestureRecognizer _descriptionToggle = TapGestureRecognizer()
    ..onTap = () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded);

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  @override
  void dispose() {
    _descriptionToggle.dispose();
    _sheetController.dispose();
    _barTitleOpacity.dispose();
    _barTopInset.dispose();
    super.dispose();
  }

  void _syncBarTitle(double barBottom) {
    final RenderObject? title = _titleKey.currentContext?.findRenderObject();
    final RenderObject? viewport = _viewportKey.currentContext?.findRenderObject();
    if(title is! RenderBox || viewport is! RenderBox || !title.hasSize || !viewport.hasSize) {
      return;
    }

    final double titleBottom = title.localToGlobal(Offset.zero, ancestor: viewport).dy + title.size.height;
    final double opacity = ((barBottom - titleBottom) / _titleFadeDistance).clamp(0.0, 1.0);
    if((_barTitleOpacity.value - opacity).abs() > 0.01) {
      _barTitleOpacity.value = opacity;
    }
  }

  void _syncBarTopInset({required double extent, required double screenHeight, required double topInset}) {
    final double sheetTop = screenHeight * (1 - extent);
    final double inset = (topInset - sheetTop).clamp(0.0, topInset);
    if((_barTopInset.value - inset).abs() > 0.5) {
      _barTopInset.value = inset;
    }
  }

  void _syncToContent(double headerHeight, double screenHeight) {
    if(!mounted) return;
    final RenderObject? box = _contentKey.currentContext?.findRenderObject();
    if(box is! RenderBox || !box.hasSize) return;

    final double fraction = ((headerHeight + box.size.height) / screenHeight).clamp(0.3, 1.0).toDouble();
    if(_measuredFraction != null && (_measuredFraction! - fraction).abs() < 0.005) return;

    setState(() => _measuredFraction = fraction);
    if(_sheetController.isAttached) {
      _sheetController.jumpTo(fraction);
    }
  }

  Future<void> _loadItem() async {
    final int? itemId = widget.item.isService ? null : widget.item.itemId;
    if(itemId == null) {
      setState(() => _detailsLoaded = true);
      return;
    }
    final ItemController itemController = Get.find<ItemController>();
    await itemController.getItemDetails(itemId: itemId);
    if(mounted) {
      setState(() {
        _itemDetails = itemController.item;
        _detailsLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: 550,
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge)),
      ),
      clipBehavior: Clip.antiAlias,
      child: _detailsLoaded ? _sheet(context) : const ItemBottomSheetShimmer(),
    );
  }

  Widget _sheet(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final BundleMemberItem item = widget.item;

    final String image = (item.imageFullUrl?.isNotEmpty ?? false) ? item.imageFullUrl! : (_itemDetails?.imageFullUrl ?? '');
    final String name = (item.name?.isNotEmpty ?? false) ? item.name! : (_itemDetails?.name ?? '');
    final String storeName = widget.storeName ?? '';
    final String storeLogo = widget.storeLogoFullUrl ?? '';
    final String description = _itemDetails?.description ?? '';
    final String variation = item.variationSummary ?? '';
    final String addOns = item.addOnSummary ?? '';
    final String unit = item.unitType ?? '';

    final bool showHalal = _itemDetails?.isStoreHalalActive == true && _itemDetails?.isHalalItem == true;
    final bool showVeg = (Get.find<SplashController>().configModel?.toggleVegNonVeg ?? false) && _itemDetails?.veg == 1;

    // Read off the view: a modal route strips the top inset from its own MediaQuery.
    final double topInset = MediaQueryData.fromView(View.of(context)).padding.top;
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    final double expandedHeaderHeight = (screenHeight * 0.30).clamp(240.0, 320.0).toDouble();

    final double estimatedHeight = _estimateContentHeight(
      expandedHeaderHeight: expandedHeaderHeight, topInset: topInset, bottomInset: bottomInset,
      hasStore: storeName.isNotEmpty, hasName: name.isNotEmpty,
      showRating: AvgReviewWidget.showRating(_itemDetails?.avgRating ?? 0),
      showPrice: item.unitPrice > 0,
      description: description, variation: variation, addOns: addOns, unit: unit,
    );
    final double contentFraction = _measuredFraction
        ?? (estimatedHeight / screenHeight).clamp(0.45, 1.0).toDouble();
    final double minFraction = (contentFraction * 0.8).clamp(0.3, contentFraction).toDouble();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncToContent(expandedHeaderHeight, screenHeight);
      _syncBarTopInset(
        extent: _sheetController.isAttached ? _sheetController.size : contentFraction,
        screenHeight: screenHeight, topInset: topInset,
      );
    });

    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: contentFraction,
      minChildSize: minFraction,
      maxChildSize: contentFraction,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) => NotificationListener<DraggableScrollableNotification>(
        onNotification: (DraggableScrollableNotification notification) {
          _syncBarTopInset(extent: notification.extent, screenHeight: screenHeight, topInset: topInset);
          return false;
        },
        child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          _syncBarTitle(_barHeight + _barTopInset.value);
          return false;
        },
        child: CustomScrollView(
        key: _viewportKey,
        controller: scrollController,
        slivers: [

        SliverPersistentHeader(
          pinned: true,
          delegate: _ItemHeaderDelegate(
            image: image, title: name, titleOpacity: _barTitleOpacity,
            showHalal: showHalal, showVeg: showVeg,
            expandedHeight: expandedHeaderHeight,
            // Reserved unconditionally: the list only scrolls once the drag has taken the
            // sheet to the top, so by the time this bar pins it is against the status bar.
            collapsedHeight: _barHeight + topInset,
            topPadding: _barTopInset,
          ),
        ),

        SliverToBoxAdapter(child: Padding(
          key: _contentKey,
          padding: EdgeInsets.fromLTRB(
            Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault + bottomInset,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            if(storeName.isNotEmpty) Padding(
              padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
              child: Row(children: [
                if(storeLogo.isNotEmpty) ...[
                  ClipOval(child: CustomImage(image: storeLogo, height: 18, width: 18, fit: BoxFit.cover)),
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                ],
                Flexible(child: Text(
                  storeName, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: theme.hintColor),
                )),
              ]),
            ),

            if(name.isNotEmpty) Text(
              name, key: _titleKey, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
            ),

            if(AvgReviewWidget.showRating(_itemDetails?.avgRating ?? 0)) Padding(
              padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
              child: AvgReviewWidget(avgRating: _itemDetails?.avgRating ?? 0, ratingCount: _itemDetails?.ratingCount ?? 0),
            ),

            // The bundle's frozen price, not today's menu price.
            if(item.unitPrice > 0) Padding(
              padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
              child: Text(
                PriceConverter.convertPrice(item.unitPrice), textDirection: TextDirection.ltr,
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
              ),
            ),

            if(description.isNotEmpty) _DetailCard(
              title: 'product_details'.tr,
              child: _descriptionText(context, description),
            ),

            if(variation.isNotEmpty) _DetailCard(title: 'variation'.tr, child: _bodyText(context, variation)),

            if(addOns.isNotEmpty) _DetailCard(title: 'addons'.tr, child: _bodyText(context, addOns)),

            if(unit.isNotEmpty) _DetailCard(title: 'unit'.tr, child: _bodyText(context, unit)),
          ]),
        )),
        ],
        ),
        ),
      ),
    );
  }

  double _estimateContentHeight({
    required double expandedHeaderHeight,
    required double topInset,
    required double bottomInset,
    required bool hasStore,
    required bool hasName,
    required bool showRating,
    required bool showPrice,
    required String description,
    required String variation,
    required String addOns,
    required String unit,
  }) {
    double height = expandedHeaderHeight + topInset + (Dimensions.paddingSizeDefault * 2) + bottomInset;
    if(hasStore) height += 26;
    if(hasName) height += 56;
    if(showRating) height += 24;
    if(showPrice) height += 32;
    // A collapsed description never shows more than the limit, however long it really is.
    if(description.isNotEmpty) {
      final int shown = description.length > _collapsedDescriptionLimit ? _collapsedDescriptionLimit : description.length;
      height += _cardHeight(shown);
    }
    if(variation.isNotEmpty) height += _cardHeight(variation.length);
    if(addOns.isNotEmpty) height += _cardHeight(addOns.length);
    if(unit.isNotEmpty) height += _cardHeight(unit.length);
    return height;
  }

  // A card's title, its padding and however many lines its text wraps to.
  double _cardHeight(int textLength) {
    const int charsPerLine = 38;
    final int lines = (textLength / charsPerLine).ceil().clamp(1, 12);
    return 70 + (lines * 20);
  }

  Widget _bodyText(BuildContext context, String text) => Text(
    text,
    style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor),
  );

  Widget _descriptionText(BuildContext context, String description) {
    final bool isTooLong = description.length > _collapsedDescriptionLimit;
    if(!isTooLong) {
      return _bodyText(context, description);
    }

    final String visible = _isDescriptionExpanded
        ? description
        : '${description.substring(0, _collapsedDescriptionLimit).trimRight()}... ';

    return Text.rich(TextSpan(children: [
      TextSpan(text: visible),
      TextSpan(
        text: _isDescriptionExpanded ? ' ${'see_less'.tr}' : 'see_more'.tr,
        style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).primaryColor),
        recognizer: _descriptionToggle,
      ),
    ]), style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor));
  }
}

class _ItemHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String image;
  final String title;
  final ValueListenable<double> titleOpacity;
  final bool showHalal;
  final bool showVeg;
  final double expandedHeight;
  final double collapsedHeight;
  final ValueListenable<double> topPadding;

  const _ItemHeaderDelegate({
    required this.image, required this.title, required this.titleOpacity,
    required this.showHalal, required this.showVeg,
    required this.expandedHeight, required this.collapsedHeight, required this.topPadding,
  });

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => collapsedHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final ThemeData theme = Theme.of(context);
    final double collapsed = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final double barFade = ((collapsed - 0.55) / 0.45).clamp(0.0, 1.0);

    return ClipRect(child: Stack(fit: StackFit.expand, children: [

      OverflowBox(
        alignment: Alignment.topCenter,
        minHeight: maxExtent, maxHeight: maxExtent,
        child: Stack(children: [
          Positioned.fill(child: CustomImage(
            image: image, fit: BoxFit.cover, width: double.infinity, height: double.infinity, placeholder: Images.placeholder,
            cacheWidth: ImageCacheHelper.pixels(context, MediaQuery.sizeOf(context).width), cacheHeight: ImageCacheHelper.pixels(context, maxExtent),
          )),

          if(showHalal || showVeg) Positioned(
            right: Dimensions.paddingSizeDefault, bottom: Dimensions.paddingSizeDefault,
            child: Row(children: [
              if(showHalal) const CustomAssetImageWidget(Images.halalTag, height: 28, width: 28),
              if(showHalal && showVeg) const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              if(showVeg) const CustomAssetImageWidget(Images.vegTag, height: 28, width: 28),
            ]),
          ),
        ]),
      ),

      Opacity(opacity: barFade, child: ColoredBox(color: theme.cardColor)),

      Align(
        alignment: Alignment.topLeft,
        child: _HeaderBar(title: title, titleOpacity: titleOpacity, height: collapsedHeight, topPadding: topPadding),
      ),
    ]));
  }

  @override
  bool shouldRebuild(covariant _ItemHeaderDelegate oldDelegate) {
    return oldDelegate.image != image || oldDelegate.title != title
        || oldDelegate.titleOpacity != titleOpacity
        || oldDelegate.showHalal != showHalal || oldDelegate.showVeg != showVeg
        || oldDelegate.expandedHeight != expandedHeight || oldDelegate.collapsedHeight != collapsedHeight
        || oldDelegate.topPadding != topPadding;
  }
}

class _HeaderBar extends StatelessWidget {
  final String title;
  final ValueListenable<double> titleOpacity;
  final double height;
  final ValueListenable<double> topPadding;

  const _HeaderBar({required this.title, required this.titleOpacity, required this.height, required this.topPadding});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: topPadding,
      builder: (BuildContext context, double inset, Widget? child) => Container(
        height: height,
        width: double.infinity,
        alignment: Alignment.topCenter,
        padding: EdgeInsets.only(top: inset),
        child: child,
      ),
      child: SizedBox(
        height: _barContentHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: ValueListenableBuilder<double>(
            valueListenable: titleOpacity,
            builder: (BuildContext context, double opacity, Widget? child) {
              final bool titleShown = opacity > 0;
              return Row(children: [
                if(!titleShown) const _CloseButton(),

                Expanded(child: IgnorePointer(
                  ignoring: !titleShown,
                  child: Opacity(opacity: opacity, child: child),
                )),
              ]);
            },
            child: Row(children: [
              Expanded(child: Text(
                title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
              )),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              const _CloseButton(),
            ]),
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return InkWell(
      onTap: () => Get.back(),
      customBorder: const CircleBorder(),
      child: Container(
        height: 32, width: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: theme.cardColor),
        child: Icon(Icons.close, size: 18, color: theme.textTheme.bodyLarge?.color),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _DetailCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(color: theme.disabledColor.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        child,
      ]),
    );
  }
}

// SUMMARY
// Read-only sheet for one item of a bundle. Shows the item's image, which collapses on
// scroll into a pinned bar holding the close button and the item's name, then the
// store, name, rating, the price the bundle was built on, and cards for its description
// and the variation, add-ons and unit it is locked to — each shown only when there is
// something to show. Opens at the height its own content works out to and drags down
// from there, waiting on a shimmer until the item has loaded and that height is known.
