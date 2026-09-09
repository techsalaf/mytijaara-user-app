import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/common/widgets/avg_review_widget.dart';
import 'package:sixam_mart/common/widgets/confirmation_dialog.dart';
import 'package:sixam_mart/common/widgets/custom_asset_image_widget.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/custom_tool_tip_widget.dart';
import 'package:sixam_mart/common/widgets/item_bottom_sheet_shimmer.dart';
import 'package:sixam_mart/common/widgets/quantity_decrement_icon.dart';
import 'package:sixam_mart/common/widgets/store_verified_avatar.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/features/checkout/screens/checkout_screen.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/item/widgets/item_media_dialog.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart' as web_youtube;

class ItemNewBottomSheet extends StatefulWidget {
  final int itemId;
  final bool isCampaign;
  final CartModel? cart;
  final int? cartIndex;
  final bool inStorePage;
  final Item? item;
  final int? reelId;
  const ItemNewBottomSheet({super.key, required this.itemId, this.isCampaign = false, this.cart, this.cartIndex, this.inStorePage = false, this.item, this.reelId});

  @override
  State<ItemNewBottomSheet> createState() => _ItemNewBottomSheetState();
}

class _ItemNewBottomSheetState extends State<ItemNewBottomSheet> {
  bool _newVariation = false;
  int? _highlightedVariationIndex;
  final Map<int, GlobalKey> _variationCardKeys = {};
  Timer? _highlightTimer;
  // Collapsible option cards: indexes of collapsed variation cards + the addon card.
  final Set<int> _collapsedVariationIndexes = <int>{};
  bool _collapsedAddon = false;
  // Re-entrancy guard: stays true from the first add-to-cart tap until the
  // action fully completes (including the sheet closing), so the button can't
  // be tapped again during the window where the controller's shared isLoading
  // has already reset but the sheet hasn't closed yet.
  bool _isAddingToCart = false;
  bool _sheetClosed = false;

  void _toggleVariationCollapse(int index) {
    setState(() {
      if (!_collapsedVariationIndexes.remove(index)) {
        _collapsedVariationIndexes.add(index);
      }
    });
  }

  void _toggleAddonCollapse() {
    setState(() => _collapsedAddon = !_collapsedAddon);
  }
  // Guided required-variation focus: once the user taps "choose required option",
  // selecting/fulfilling the focused variation auto-advances focus to the next missing one.
  bool _guidedFocusActive = false;
  int? _guidedFocusIndex;
  // Index of the currently shown media (video + images) in the collapsing header.
  int _selectedMediaIndex = 0;
  // Drives the swipeable header media slider; lets the arrow buttons animate pages.
  final CarouselSliderController _mediaCarouselController = CarouselSliderController();
  // The page the slider is actually showing — guards against animating back to a
  // page the user just swiped to.
  int _mediaCarouselPage = 0;

  @override
  void initState() {
    super.initState();

    ItemController itemController = Get.find<ItemController>();
    SplashController splashController = Get.find<SplashController>();

    // Controller is a singleton, so the expanded state can leak from a previously
    // opened item — start every sheet with the details collapsed.
    itemController.changeReadMore(value: false, notify: false);

    if(splashController.module == null) {
      if(splashController.cacheModule != null) {
        splashController.setCacheConfigModule(splashController.cacheModule);
      }
    }

    itemController.getItemDetails(itemId: widget.itemId, cart: widget.cart, isCampaign: widget.isCampaign).then((_) {
      if (!mounted) return;
      final item = itemController.item;
      if (item == null) return;
      _newVariation = splashController.getModuleConfig(item.moduleType).newVariation ?? false;
    });

  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    super.dispose();
  }

  int? _findFirstMissingRequiredIndex(Item item, ItemController c) {
    if (!_newVariation || item.foodVariations == null) return null;
    for (int i = 0; i < item.foodVariations!.length; i++) {
      final fv = item.foodVariations![i];
      if (fv.required != true) continue;
      final int selected = c.selectedVariationLength(c.selectedVariations, i);
      final int needed = fv.multiSelect == true ? (fv.min ?? 1) : 1;
      if (selected < needed) return i;
    }
    return null;
  }

  void _pulseMissingVariation(int idx) {
    // Expand the card if collapsed so the user can actually see/select its options.
    _collapsedVariationIndexes.remove(idx);
    final ctx = _variationCardKeys[idx]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        alignment: 0.15,
      );
    }
    setState(() => _highlightedVariationIndex = idx);
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _highlightedVariationIndex = null);
    });
  }

  // Entry point from the "choose required option" button: focus the first missing
  // required variation and arm the auto-advance flow.
  void _startGuidedFocus(int idx) {
    _guidedFocusActive = true;
    _guidedFocusIndex = idx;
    _pulseMissingVariation(idx);
  }

  // While guided focus is active, advance to the next missing required variation
  // as soon as the currently focused one is fulfilled (and stop once all are met).
  void _scheduleGuidedFocusCheck(Item item, ItemController itemController) {
    if (!_guidedFocusActive) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_guidedFocusActive) return;
      final int? next = _findFirstMissingRequiredIndex(item, itemController);
      if (next == null) {
        _guidedFocusActive = false;
        _guidedFocusIndex = null;
      } else if (next != _guidedFocusIndex) {
        _guidedFocusIndex = next;
        _pulseMissingVariation(next);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 550,
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: ResponsiveHelper.isDesktop(context) ? const BorderRadius.all(Radius.circular(Dimensions.radiusDefault)) : const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge)),
      ),
      child: GetBuilder<ItemController>(builder: (itemController) {
        
        Item? item = itemController.item;
        
        if(itemController.item == null){
          return const ItemBottomSheetShimmer();
        }

        _scheduleGuidedFocusCheck(itemController.item!, itemController);

        double? startingPrice;
        double? endingPrice;
        if (item!.choiceOptions!.isNotEmpty && item.foodVariations!.isEmpty && !_newVariation) {
          List<double?> priceList = [];
          for (var variation in item.variations!) {
            priceList.add(variation.price);
          }
          priceList.sort((a, b) => a!.compareTo(b!));
          startingPrice = priceList[0];
          if (priceList[0]! < priceList[priceList.length - 1]!) {
            endingPrice = priceList[priceList.length - 1];
          }
        } else {
          startingPrice = item.price;
        }

        double? price = item.price;
        double variationPrice = 0;
        Variation? variation;
        double? initialDiscount = item.discount;
        double? discount = item.discount;
        String? discountType = item.discountType;
        int? stock = item.stock ?? 0;

        if(discountType == 'amount'){
          discount = discount! * itemController.quantity!;
        }

        if(_newVariation) {
          for(int index = 0; index< item.foodVariations!.length; index++) {
            for(int i=0; i<item.foodVariations![index].variationValues!.length; i++) {
              if(itemController.selectedVariations[index][i]!) {
                variationPrice += item.foodVariations![index].variationValues![i].optionPrice!;
              }
            }
          }
        }else {
          List<String> variationList = [];
          for (int index = 0; index < item.choiceOptions!.length; index++) {
            if(itemController.variationIndex != null && itemController.variationIndex!.isNotEmpty && itemController.variationIndex![index] != -1) {
              variationList.add(item.choiceOptions![index].options![itemController.variationIndex![index]].replaceAll(' ', ''));
            }
          }
          String variationType = '';
          bool isFirst = true;
          for (var variation in variationList) {
            if (isFirst) {
              variationType = '$variationType$variation';
              isFirst = false;
            } else {
              variationType = '$variationType-$variation';
            }
          }

          for (Variation variations in item.variations!) {
            if (variations.type == variationType) {
              price = variations.price;
              variation = variations;
              stock = variations.stock;
              break;
            }
          }
        }

        price = price! + variationPrice;
        double priceWithDiscount = PriceConverter.convertWithDiscount(price, discount, discountType)!;
        double addonsCost = 0;
        List<AddOn> addOnIdList = [];
        List<AddOns> addOnsList = [];
        for (int index = 0; index < item.addOns!.length; index++) {
          if (itemController.addOnActiveList[index]) {
            addonsCost = addonsCost + (item.addOns![index].price! * itemController.addOnQtyList[index]!);
            addOnIdList.add(AddOn(id: item.addOns![index].id, quantity: itemController.addOnQtyList[index]));
            addOnsList.add(item.addOns![index]);
          }
        }
        priceWithDiscount = priceWithDiscount;
        double priceWithDiscountAndAddons = priceWithDiscount + addonsCost;
        bool isAvailable = DateConverter.isAvailable(item.availableTimeStarts, item.availableTimeEnds);

        return _buildProductDetailSheet(
          context: context,
          itemController: itemController,
          item: item,
          startingPrice: startingPrice,
          endingPrice: endingPrice,
          price: price,
          priceWithDiscount: priceWithDiscount,
          initialDiscount: initialDiscount,
          discount: discount,
          discountType: discountType,
          stock: stock,
          addonsCost: addonsCost,
          priceWithDiscountAndAddons: priceWithDiscountAndAddons,
          isAvailable: isAvailable,
          variation: variation,
          addOnIdList: addOnIdList,
          addOnsList: addOnsList,
        );
      }),
    );
  }

  Widget _buildProductDetailSheet({
    required BuildContext context,
    required ItemController itemController,
    required Item item,
    required double? startingPrice,
    required double? endingPrice,
    required double price,
    required double priceWithDiscount,
    required double? initialDiscount,
    required double? discount,
    required String? discountType,
    required int? stock,
    required double addonsCost,
    required double priceWithDiscountAndAddons,
    required bool isAvailable,
    required Variation? variation,
    required List<AddOn> addOnIdList,
    required List<AddOns> addOnsList,
  }) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double maxSheetHeight = screenHeight * (ResponsiveHelper.isDesktop(context) ? 0.88 : 0.94);
    final double expandedHeaderHeight = (screenHeight * 0.30).clamp(240.0, 320.0).toDouble();
    final bool showPinnedCartBar = !(!item.scheduleOrder! && !isAvailable);

    final bool addOnEnabled = Get.find<SplashController>().configModel!.moduleConfig!.module!.addOn!;
    final bool hasAddons = addOnEnabled && item.addOns!.isNotEmpty;
    final bool hasFoodVariations = _newVariation && (item.foodVariations?.isNotEmpty ?? false);
    final bool hasChoiceOptions = !_newVariation && (item.choiceOptions?.isNotEmpty ?? false);
    final bool hasVariations = hasFoodVariations || hasChoiceOptions;
    final bool showOptionsSection = hasVariations || hasAddons || !isAvailable;

    final int? missingIdx = _findFirstMissingRequiredIndex(item, itemController);
    final bool hasUnmetRequired = missingIdx != null;
    final double cartBarBaseHeight = hasUnmetRequired ? 72 : 100;
    final double bottomBarHeight = showPinnedCartBar ? cartBarBaseHeight + MediaQuery.of(context).padding.bottom : 0;

    Widget sheetChild({ScrollController? scrollController}) {
      return ClipRRect(
        borderRadius: ResponsiveHelper.isDesktop(context) ? const BorderRadius.all(Radius.circular(Dimensions.radiusDefault)) : const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge)),
        child: Stack(children: [
          CustomScrollView(controller: scrollController, slivers: [
            _buildCollapsingHeader(context, item, expandedHeaderHeight),

            SliverToBoxAdapter(
              child: Container(
                color: Theme.of(context).cardColor,
                padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge, Dimensions.paddingSizeDefault),
                child: _buildProductSummary(context: context, item: item, startingPrice: startingPrice, endingPrice: endingPrice,
                  initialDiscount: initialDiscount, discountType: discountType,
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Container(
                color: Theme.of(context).cardColor,
                padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, 0, Dimensions.paddingSizeLarge, Dimensions.paddingSizeDefault),
                child: _buildProductDetails(context, item, itemController),
              ),
            ),

            showOptionsSection ? SliverToBoxAdapter(
              child: Container(
                color: Theme.of(context).disabledColor.withValues(alpha: 0.08),
                padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeLarge, Dimensions.paddingSizeDefault, Dimensions.paddingSizeLarge),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  hasVariations ? (_newVariation ? NewVariationView(item: item, itemController: itemController, discount: initialDiscount,
                  discountType: discountType, showOriginalPrice: (price > priceWithDiscount) && (discountType == 'percent'),
                  highlightedIndex: _highlightedVariationIndex, cardKeys: _variationCardKeys,
                  collapsedIndexes: _collapsedVariationIndexes, onToggleCollapse: _toggleVariationCollapse,
                  ) : VariationView(item: item, itemController: itemController,
                  collapsedIndexes: _collapsedVariationIndexes, onToggleCollapse: _toggleVariationCollapse,
                  )) : const SizedBox.shrink(),

                  hasAddons ? AddonView(itemController: itemController, item: item,
                  collapsed: _collapsedAddon, onToggleCollapse: _toggleAddonCollapse,
                  ) : const SizedBox.shrink(),

                  isAvailable ? const SizedBox.shrink() : _buildAvailabilityWarning(context, item),
                ]),
              ),
            ) : const SliverToBoxAdapter(child: SizedBox.shrink()),

            SliverToBoxAdapter(child: SizedBox(height: bottomBarHeight /*+ Dimensions.paddingSizeDefault*/)),
          ]),

          _buildPinnedCartBar(
            context: context,
            itemController: itemController,
            item: item,
            price: price,
            discount: discount,
            discountType: discountType,
            stock: stock,
            addonsCost: addonsCost,
            priceWithDiscountAndAddons: priceWithDiscountAndAddons,
            isAvailable: isAvailable,
            variation: variation,
            addOnIdList: addOnIdList,
            addOnsList: addOnsList,
          ),
        ]),
      );
    }

    if (ResponsiveHelper.isDesktop(context)) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        child: sheetChild(),
      );
    }

    final double estimatedHeight = _estimateContentHeight(
      context: context, item: item, expandedHeaderHeight: expandedHeaderHeight,
      bottomBarHeight: bottomBarHeight, hasAddons: hasAddons,
      hasFoodVariations: hasFoodVariations, hasChoiceOptions: hasChoiceOptions, isAvailable: isAvailable,
    );
    final double contentFraction = (estimatedHeight / screenHeight).clamp(0.45, 1.0).toDouble();
    final double minFraction = (contentFraction * 0.8).clamp(0.35, contentFraction).toDouble();

    return DraggableScrollableSheet(
      initialChildSize: contentFraction,
      minChildSize: minFraction,
      maxChildSize: contentFraction,
      expand: false,
      builder: (context, scrollController) => sheetChild(scrollController: scrollController),
    );
  }

  double _estimateContentHeight({
    required BuildContext context,
    required Item item,
    required double expandedHeaderHeight,
    required double bottomBarHeight,
    required bool hasAddons,
    required bool hasFoodVariations,
    required bool hasChoiceOptions,
    required bool isAvailable,
  }) {
    // viewPadding.top is the physical status bar height. padding.top is zeroed
    // inside showModalBottomSheet by MediaQuery.removePadding(removeTop: true),
    // so padding.top would return 0 and cause the header to ignore the status bar.
    final double statusBarHeight = MediaQuery.of(context).viewPadding.top;
    double height = expandedHeaderHeight + statusBarHeight + 16;
    height += 180;

    if (item.description != null && item.description!.isNotEmpty) {
      height += 90;
    }

    if (hasFoodVariations) {
      for (final FoodVariation fv in item.foodVariations!) {
        height += 130;
        final int optionsCount = fv.variationValues?.length ?? 0;
        final int visible = optionsCount > 4 ? 4 : optionsCount;
        height += visible * 44.0;
        if (optionsCount > 4) height += 44;
      }
    }

    if (hasChoiceOptions) {
      for (final co in item.choiceOptions!) {
        height += 110;
        height += (co.options?.length ?? 0) * 44.0;
      }
    }

    if (hasAddons) {
      height += 90;
      height += item.addOns!.length * 60.0;
    }

    if (!isAvailable) {
      height += 90;
    }

    height += bottomBarHeight + Dimensions.paddingSizeDefault;
    return height;
  }

  Widget _buildCollapsingHeader(BuildContext context, Item item, double expandedHeaderHeight) {
    final double statusBarHeight = MediaQuery.of(context).viewPadding.top;
    const double statusBarGap = 16;
    final double toolbarHeight = 82 + statusBarHeight + statusBarGap;
    final double totalExpandedHeight = expandedHeaderHeight + statusBarHeight + statusBarGap;

    final List<String> mediaList = _getMediaList(item, isCampaign: widget.isCampaign);
    final int selectedMediaIndex = mediaList.isEmpty ? 0 : _selectedMediaIndex.clamp(0, mediaList.length - 1);
    if (selectedMediaIndex != _selectedMediaIndex) {
      _selectedMediaIndex = selectedMediaIndex;
    }
    final String? videoUrl = _getVideoUrl(item);
    final String selectedMediaUrl = mediaList.isNotEmpty ? mediaList[selectedMediaIndex] : (item.imageFullUrl ?? '');
    final bool isVideoSelected = videoUrl != null && selectedMediaUrl == videoUrl;
    final bool hasMultipleMedia = mediaList.length > 1;
    // Realign the swipe slider when the arrows changed the selected media.
    _syncMediaCarousel(selectedMediaIndex);

    return SliverAppBar(
      pinned: true,
      primary: false,
      elevation: 0,
      toolbarHeight: toolbarHeight,
      expandedHeight: totalExpandedHeight,
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).cardColor,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: LayoutBuilder(builder: (context, constraints) {
        final double currentHeight = constraints.biggest.height;
        final double progress = ((totalExpandedHeight - currentHeight) / (totalExpandedHeight - toolbarHeight)).clamp(0.0, 1.0).toDouble();
        final double titleOpacity = ((progress - 0.62) / 0.38).clamp(0.0, 1.0).toDouble();
        final double heroOpacity = (1 - (titleOpacity * 0.75)).clamp(0.0, 1.0).toDouble();
        final double controlsOpacity = (1 - titleOpacity).clamp(0.0, 1.0).toDouble();

        return Stack(fit: StackFit.expand, children: [
          Opacity(
            opacity: heroOpacity,
            child: mediaList.isEmpty
                ? InkWell(
                    onTap: widget.isCampaign ? null : () => _openMediaFullScreen(context, item, selectedMediaIndex),
                    child: _buildHeaderMedia(context, item, selectedMediaUrl, isVideoSelected),
                  )
                : CarouselSlider.builder(
                    carouselController: _mediaCarouselController,
                    itemCount: mediaList.length,
                    options: CarouselOptions(
                      height: currentHeight,
                      viewportFraction: 1,
                      enableInfiniteScroll: false,
                      autoPlay: false,
                      initialPage: selectedMediaIndex,
                      onPageChanged: (i, reason) {
                        _mediaCarouselPage = i;
                        // Pause the header video when it scrolls off-screen; resume
                        // when it returns (video is always media index 0 when present).
                        final bool onVideoPage = videoUrl != null && i == 0;
                        onVideoPage ? _HeaderVideoPlayerState.resumeAll() : _HeaderVideoPlayerState.pauseAll();
                        // Only a user swipe drives the selection; arrow-driven jumps
                        // already updated _selectedMediaIndex.
                        if (reason == CarouselPageChangedReason.manual && i != _selectedMediaIndex) {
                          setState(() => _selectedMediaIndex = i);
                        }
                      },
                    ),
                    itemBuilder: (context, i, _) {
                      final String url = mediaList[i];
                      final bool isVideo = videoUrl != null && url == videoUrl;
                      // The video page handles its own taps (player controls + mute);
                      // only images get the tap-to-fullscreen wrapper.
                      if (isVideo) {
                        return _buildHeaderMedia(context, item, url, true);
                      }
                      return InkWell(
                        onTap: widget.isCampaign ? null : () => _openMediaFullScreen(context, item, i),
                        child: _buildHeaderMedia(context, item, url, false),
                      );
                    },
                  ),
          ),

          if(hasMultipleMedia && selectedMediaIndex > 0) Positioned(
            left: Dimensions.paddingSizeSmall, top: 0, bottom: 0,
            child: Center(child: IgnorePointer(
              ignoring: controlsOpacity < 0.5,
              child: Opacity(
                opacity: controlsOpacity,
                child: _mediaArrowButton(
                  icon: Icons.chevron_left,
                  onTap: () => setState(() => _selectedMediaIndex = selectedMediaIndex - 1),
                ),
              ),
            )),
          ),

          if(hasMultipleMedia && selectedMediaIndex < mediaList.length - 1) Positioned(
            right: Dimensions.paddingSizeSmall, top: 0, bottom: 0,
            child: Center(child: IgnorePointer(
              ignoring: controlsOpacity < 0.5,
              child: Opacity(
                opacity: controlsOpacity,
                child: _mediaArrowButton(
                  icon: Icons.chevron_right,
                  onTap: () => setState(() => _selectedMediaIndex = selectedMediaIndex + 1),
                ),
              ),
            )),
          ),

          if(hasMultipleMedia) Positioned(
            left: 0, right: 0, bottom: Dimensions.paddingSizeSmall,
            child: IgnorePointer(
              child: Opacity(
                opacity: controlsOpacity,
                child: _buildMediaIndicator(context, mediaList.length, selectedMediaIndex),
              ),
            ),
          ),

          Positioned(
            left: Dimensions.paddingSizeDefault,
            right: Dimensions.paddingSizeDefault,
            bottom: Dimensions.paddingSizeDefault,
            child: Opacity(
              opacity: (1 - titleOpacity).clamp(0.0, 1.0).toDouble(),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                item.isStoreHalalActive == true && item.isHalalItem == true ? CustomToolTip(
                  message: 'this_is_a_halal_food'.tr,
                  preferredDirection: AxisDirection.up,
                  child: _buildImageBadge(const CustomAssetImageWidget(Images.halalTag, height: 30, width: 30)),
                ) : const SizedBox(),
                SizedBox(width: item.isStoreHalalActive == true && item.isHalalItem == true ? Dimensions.paddingSizeExtraSmall : 0),

                Get.find<SplashController>().configModel!.moduleConfig!.module!.vegNonVeg! && Get.find<SplashController>().configModel!.toggleVegNonVeg! ? CustomToolTip(
                  message: item.veg == 1 ? 'this_is_veg_item'.tr : 'this_is_non_veg_item'.tr,
                  preferredDirection: AxisDirection.up,
                  child: _buildImageBadge(
                    Image.asset(item.veg == 1 ? Images.vegTag : Images.nonVegTag, height: 30, width: 30),
                  ),
                ) : const SizedBox(),

                SizedBox(width: item.organic == 1 && item.moduleType == 'grocery' ? Dimensions.paddingSizeExtraSmall : 0),

                item.organic == 1 && item.moduleType == 'grocery' ? CustomToolTip(
                  message: 'this_is_organic_food'.tr,
                  preferredDirection: AxisDirection.up,
                  child: _buildImageBadge(const CustomAssetImageWidget(Images.organicTag, height: 30, width: 30)),
                ) : const SizedBox(),
              ]),
            ),
          ),

          Positioned(
            top: -10 + (10 * progress), left: 0, right: 0,
            height: toolbarHeight,
            child: Container(
              padding: EdgeInsets.only(
                left: Dimensions.paddingSizeDefault,
                right: Dimensions.paddingSizeDefault,
                top: statusBarHeight + statusBarGap,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withValues(alpha: titleOpacity),
              ),
              child: Row(children: [
                _buildHeaderButton(context: context, icon: Icons.close, progress: titleOpacity, onTap: () => Get.back()),

                Expanded(child: Opacity(opacity: titleOpacity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                    child: Text( item.name ?? '',
                      maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                      style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                    ),
                  ),
                )),

                widget.isCampaign ? const SizedBox(width: 52) : GetBuilder<FavouriteController>(builder: (wishList) {
                  final bool isFavourite = wishList.wishItemIdList.contains(item.id);
                  return _buildHeaderButton(
                    context: context, progress: titleOpacity,
                    icon: isFavourite ? Icons.favorite : Icons.favorite_border,
                    color: isFavourite ? Theme.of(context).primaryColor : null,
                    onTap: () => _toggleFavourite(wishList, item),
                  );
                }),
              ]),
            ),
          ),
        ]);
      }),
    );
  }

  Widget _buildHeaderButton({required BuildContext context, required IconData icon, required double progress,
  required VoidCallback onTap, Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(width: 40, height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).cardColor,
          boxShadow: progress < 0.4 ? const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 3))] : null,
        ),
        child: Icon(icon, size: 20, color: color ?? Theme.of(context).textTheme.bodyLarge!.color),
      ),
    );
  }

  Widget _buildImageBadge(Widget child) {
    return Container(height: 32, width: 32,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Theme.of(context).cardColor, width: 2)),
      child: FittedBox(fit: BoxFit.contain, child: child),
    );
  }

  // Renders the currently selected media in the header. Video media auto-plays
  // (muted, with a mute toggle); SVG images are handled separately.
  Widget _buildHeaderMedia(BuildContext context, Item item, String mediaUrl, bool isVideo) {
    if (isVideo) {
      return _HeaderVideoPlayer(
        // Stable key so the player/controller survives the per-frame rebuilds of
        // the collapsing SliverAppBar instead of restarting.
        key: ValueKey<String>('header-video-$mediaUrl'),
        videoUrl: mediaUrl,
        thumbnailUrl: item.videoThumbnailUrl?.isNotEmpty == true ? item.videoThumbnailUrl! : (item.imageFullUrl ?? ''),
        isDesktop: ResponsiveHelper.isDesktop(context),
        onFullscreenTap: widget.isCampaign ? null : () => _openMediaFullScreen(context, item, _selectedMediaIndex),
      );
    }
    final String imageUrl = mediaUrl;
    if (imageUrl.toLowerCase().endsWith('.svg')) {
      return SvgPicture.network(imageUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    }
    return CustomImage(image: imageUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
  }

  Widget _mediaArrowButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 36, width: 36,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.40),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  // Page-style dots showing the active media; the active dot stretches into a pill.
  Widget _buildMediaIndicator(BuildContext context, int count, int currentIndex) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(count, (i) {
      final bool active = i == currentIndex;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        height: 6, width: active ? 18 : 6,
        decoration: BoxDecoration(
          color: active ? Theme.of(context).primaryColor : Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(3),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
        ),
      );
    }));
  }

  void _openMediaFullScreen(BuildContext context, Item item, int initialIndex) {
    if (widget.isCampaign) return;
    // Pause the inline header video so its audio doesn't play behind fullscreen.
    _HeaderVideoPlayerState.pauseAll();
    if (ResponsiveHelper.isMobile(context)) {
      Get.toNamed(RouteHelper.getItemImagesRoute(item, initialIndex: initialIndex));
    } else {
      Get.dialog(ItemMediaDialog(item: item, isCampaign: widget.isCampaign, initialIndex: initialIndex));
    }
  }

  // Keeps the swipeable header slider aligned with [_selectedMediaIndex] when it
  // changes from outside the slider (the left/right arrow buttons).
  void _syncMediaCarousel(int targetIndex) {
    if (targetIndex == _mediaCarouselPage) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || targetIndex == _mediaCarouselPage) return;
      try {
        _mediaCarouselController.animateToPage(targetIndex, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
      } catch (_) {}
    });
  }

  // Header media list: video (if any) first, then the main image, then gallery images.
  List<String> _getMediaList(Item item, {bool isCampaign = false}) {
    final List<String> mediaList = [];
    final String? videoUrl = _getVideoUrl(item);
    if (videoUrl != null && videoUrl.isNotEmpty) {
      mediaList.add(videoUrl);
    }
    if (item.imageFullUrl?.isNotEmpty == true) {
      mediaList.add(item.imageFullUrl!);
    }
    if (!isCampaign && item.imagesFullUrl != null && item.imagesFullUrl!.isNotEmpty) {
      mediaList.addAll(item.imagesFullUrl!.where((url) => url.isNotEmpty));
    }
    return mediaList;
  }

  String? _getVideoUrl(Item item) {
    if (item.videoEmbedUrl?.isNotEmpty == true) {
      return item.videoEmbedUrl;
    }
    if (item.videoLink?.isNotEmpty == true) {
      return item.videoLink;
    }
    if (item.videoFullUrl?.isNotEmpty == true) {
      return item.videoFullUrl;
    }
    if (item.videoPreviewUrl?.isNotEmpty == true) {
      return item.videoPreviewUrl;
    }
    return null;
  }

  Widget _buildProductSummary({required BuildContext context, required Item item, required double? startingPrice, required double? endingPrice,
    required double? initialDiscount, required String? discountType}) {
    final String priceText = endingPrice != null
        ? '${PriceConverter.convertPrice(startingPrice, discount: initialDiscount, discountType: discountType)} - ${PriceConverter.convertPrice(endingPrice, discount: initialDiscount, discountType: discountType)}'
        : PriceConverter.convertPrice(startingPrice, discount: initialDiscount, discountType: discountType);
    final String originalPriceText = endingPrice != null
        ? '${PriceConverter.convertPrice(startingPrice)} - ${PriceConverter.convertPrice(endingPrice)}'
        : PriceConverter.convertPrice(startingPrice);
    final double baseDiscountedPrice = PriceConverter.convertWithDiscount(startingPrice, initialDiscount, discountType) ?? startingPrice!;
    final bool showOriginalPrice = startingPrice! > baseDiscountedPrice;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (item.storeName != null && item.storeName!.isNotEmpty) ...[
        Row(children: [

          StoreVerifiedAvatar(
            imageUrl: item.storeImageFullUrl,
            isVerified: item.verifiedSeller == 1,
            size: 18,
          ),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),

          Flexible(
            child: InkWell(
              onTap: () {
                if(widget.inStorePage) {
                  Get.back();
                }else {
                  Get.back();
                  Get.find<CartController>().forcefullySetModule(item.moduleId!);
                  Get.toNamed(
                    RouteHelper.getStoreRoute(id: item.storeId, page: 'item', slug: item.storeDetails?.slug??''),
                  );
                }
              },
              child: Text(
                item.storeName!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
              ),
            ),
          ),
        ]),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
      ],

      Text(item.name ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
        style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
      ),
      const SizedBox(height: Dimensions.paddingSizeExtraSmall),

      widget.isCampaign ? const SizedBox() : AvgReviewWidget(avgRating: item.avgRating ?? 0, ratingCount: item.ratingCount ?? 0),

      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(priceText, textDirection: TextDirection.ltr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge + 2)),
        SizedBox(width: showOriginalPrice ? Dimensions.paddingSizeExtraSmall : 0),
        showOriginalPrice ? Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Text(
            originalPriceText,
            textDirection: TextDirection.ltr,
            style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ) : const SizedBox(),
      ]),
      const SizedBox(height: Dimensions.paddingSizeExtraSmall),

      Wrap(spacing: Dimensions.paddingSizeSmall, runSpacing: Dimensions.paddingSizeSmall, children: [
        (initialDiscount ?? 0) > 0 ? _buildOfferBadge(
          context: context,
          label: _formatDiscountLabel(initialDiscount, discountType),
          backgroundColor: const Color(0xFFFF2424),
          textColor: Colors.white,
        ) : const SizedBox(),

        if (item.freeDelivery ?? false)
          _buildOfferBadge(
            context: context,
            label: 'free_delivery'.tr,
            icon: Icons.delivery_dining,
            backgroundColor: const Color(0xFFFFE8E8),
            textColor: const Color(0xFFFF2424),
          ),
      ]),
    ]);
  }

  Widget _buildOfferBadge({required BuildContext context, required String label, required Color backgroundColor,
    required Color textColor, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 2),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(30)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        icon != null ? Icon(icon, size: 16, color: textColor) : const SizedBox(),
        SizedBox(width: icon != null ? Dimensions.paddingSizeExtraSmall : 0),
        Text(label, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: textColor)),
      ]),
    );
  }

  String _formatDiscountLabel(double? discount, String? discountType) {
    if(discountType == 'percent') {
      final double discountValue = discount ?? 0;
      return '-${discountValue.toStringAsFixed(discountValue.truncateToDouble() == discountValue ? 0 : 1)}%';
    }
    return '-${PriceConverter.convertPrice(discount)}';
  }

  Widget _buildProductDetails(BuildContext context, Item item, ItemController itemController) {
    final bool hasDescription = item.description != null && item.description!.isNotEmpty;
    final bool hasNutrition = item.nutritionsName != null && item.nutritionsName!.isNotEmpty;
    final bool hasAllergy = item.allergiesName != null && item.allergiesName!.isNotEmpty;
    final bool hasGeneric = item.genericName != null && item.genericName!.isNotEmpty;

    final TextStyle descriptionStyle = robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor);

    // Collapsed view shows the first 200 characters; the full text is revealed
    // (no line cap) once expanded, so long descriptions are never cut off.
    const int collapsedCharLimit = 200;
    final String description = item.description ?? '';
    final bool descriptionTooLong = description.length > collapsedCharLimit;
    final String collapsedDescription = descriptionTooLong
        ? '${description.substring(0, collapsedCharLimit).trimRight()}...'
        : description;

    // "see more" is meaningful only when there is genuinely hidden content:
    // a truncated description, or extra info blocks revealed on expand.
    final bool hasMoreDetails = descriptionTooLong || hasNutrition || hasAllergy || hasGeneric;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        hasDescription ? Text(
          itemController.isReadMore ? description : collapsedDescription,
          style: descriptionStyle,
        ) : const SizedBox(),

        (itemController.isReadMore && hasNutrition) ? _buildInfoBlock(
          context: context,
          title: 'nutrition_details'.tr,
          value: _joinNameList(item.nutritionsName),
        ) : const SizedBox(),

        (itemController.isReadMore && hasAllergy) ? _buildInfoBlock(
          context: context,
          title: 'allergic_ingredients'.tr,
          value: _joinNameList(item.allergiesName),
        ) : const SizedBox(),

        (itemController.isReadMore && hasGeneric) ? _buildInfoBlock(
          context: context,
          title: 'generic_name'.tr,
          value: _joinNameList(item.genericName),
        ) : const SizedBox(),

        hasMoreDetails ? Center(
          child: InkWell(
            onTap: itemController.changeReadMore,
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  itemController.isReadMore ? 'see_less'.tr : 'see_more'.tr,
                  style: robotoMedium.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeDefault),
                ),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                Icon(itemController.isReadMore ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Theme.of(context).primaryColor),
              ]),
            ),
          ),
        ) : const SizedBox(),
    ]);
  }

  Widget _buildInfoBlock({required BuildContext context, required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Text(value, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor)),
      ]),
    );
  }

  String _joinNameList(List<String>? values) {
    return values == null || values.isEmpty ? '' : values.join(', ');
  }

  Widget _buildAvailabilityWarning(BuildContext context, Item item) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      // margin: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      ),
      child: Column(children: [
        Text('not_available_now'.tr, style: robotoMedium.copyWith(
          color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeLarge,
        )),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Text(
          '${'available_will_be'.tr} ${DateConverter.convertTimeToTime(item.availableTimeStarts!)} - ${DateConverter.convertTimeToTime(item.availableTimeEnds!)}',
          textAlign: TextAlign.center,
          style: robotoRegular,
        ),
      ]),
    );
  }

  Widget _buildPinnedCartBar({
    required BuildContext context,
    required ItemController itemController,
    required Item item,
    required double price,
    required double? discount,
    required String? discountType,
    required int? stock,
    required double addonsCost,
    required double priceWithDiscountAndAddons,
    required bool isAvailable,
    required Variation? variation,
    required List<AddOn> addOnIdList,
    required List<AddOns> addOnsList,
  }) {
    if(!item.scheduleOrder! && !isAvailable) {
      return const SizedBox();
    }

    final int? missingIdx = _findFirstMissingRequiredIndex(item, itemController);
    final bool hasUnmetRequired = missingIdx != null;

    double? cost = PriceConverter.convertWithDiscount((price * itemController.quantity!), discount, discountType);
    double withAddonCost = cost! + addonsCost;
    double originalTotal = (price * itemController.quantity!) + addonsCost;
    bool showOriginalTotal = (discount ?? 0) > 0 && originalTotal > withAddonCost;

    return Positioned(left: 0, right: 0, bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            Theme.of(context).cardColor,
            Theme.of(context).cardColor,
            Theme.of(context).cardColor,
            Theme.of(context).cardColor,
            Theme.of(context).cardColor.withValues(alpha: 0.95),
            // Theme.of(context).cardColor.withValues(alpha: 0.95),
            Theme.of(context).cardColor.withValues(alpha: 0.1),
          ], begin: Alignment.bottomCenter, end: Alignment.topCenter),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5, offset: const Offset(0, 0))],
          borderRadius: GetPlatform.isWeb ? const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(40)) : BorderRadius.zero,
        ),
        padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, Dimensions.paddingSizeDefault, Dimensions.paddingSizeLarge, Dimensions.paddingSizeDefault),
        child: SafeArea(
          top: false,
          child: hasUnmetRequired ? SizedBox(
            width: double.infinity,
            child: CustomButton(
              width: ResponsiveHelper.isDesktop(context) ? MediaQuery.of(context).size.width / 2.0 : null,
              height: 48,
              color: Theme.of(context).disabledColor.withValues(alpha: 0.5),
              radius: Dimensions.radiusDefault,
              fontSize: Dimensions.fontSizeLarge,
              buttonText: 'choose_required_option'.tr,
              textColor: Theme.of(context).textTheme.bodyLarge!.color,
              onPressed: () => _startGuidedFocus(missingIdx),
            ),
          ) : Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Expanded(child: RichText(
                text: TextSpan(
                  text: '${'total'.tr} ',
                  style: robotoBold.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color, fontSize: Dimensions.fontSizeLarge),
                ),
              )),
              showOriginalTotal ? Padding(
                padding: const EdgeInsets.only(right: Dimensions.paddingSizeExtraSmall),
                child: PriceConverter.convertAnimationPrice(
                  originalTotal,
                  textStyle: robotoMedium.copyWith(
                    color: Theme.of(context).disabledColor,
                    fontSize: Dimensions.fontSizeSmall,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ) : const SizedBox(),
              PriceConverter.convertAnimationPrice(
                withAddonCost,
                textStyle: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
              ),
            ]),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            Row(children: [
              _SheetQuantityButton(
                icon: Icons.remove,
                iconWidget: QuantityDecrementIcon(quantity: itemController.quantity!, size: 28),
                onTap: () {
                  if (itemController.quantity! > 1) {
                    itemController.setQuantity(false, stock, item.quantityLimit, getxSnackBar: true);
                  } else {
                    if (itemController.cartIndex != -1) {
                      Get.dialog(ConfirmationDialog(
                        icon: Images.warning,
                        description: 'Are you sure to remove this item from cart!'.tr,
                        onYesPressed: () {
                          Get.back();
                          Get.find<CartController>().removeFromCart(itemController.cartIndex);
                          Get.back();
                        },
                      ), barrierDismissible: false);
                    } else {
                      Get.back();
                    }
                  }
                },
              ),
              SizedBox(
                width: 70,
                child: Text(
                  itemController.quantity.toString(),
                  textAlign: TextAlign.center,
                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
                ),
              ),
              _SheetQuantityButton(
                icon: Icons.add,
                onTap: () => itemController.setQuantity(true, stock, item.quantityLimit, getxSnackBar: true),
              ),
              const SizedBox(width: Dimensions.paddingSizeLarge),

              Expanded(child: GetBuilder< CartController>(builder: (cartController) {
                return CustomButton(
                  width: ResponsiveHelper.isDesktop(context) ? MediaQuery.of(context).size.width / 2.0 : null,
                  height: 42,
                  radius: Dimensions.radiusDefault,
                  isLoading: cartController.isLoading || _isAddingToCart,
                  fontSize: Dimensions.fontSizeDefault,
                  buttonText: (Get.find<SplashController>().configModel!.moduleConfig!.module!.stock! && stock! <= 0)
                      ? 'out_of_stock'.tr : widget.isCampaign ? 'order_now'.tr
                      : (widget.cart != null || itemController.cartIndex != -1) ? 'update_in_cart'.tr : 'add_to_cart'.tr,
                  onPressed: (Get.find<SplashController>().configModel!.moduleConfig!.module!.stock! && stock! <= 0) ? null : () async {
                    if (_isAddingToCart || _sheetClosed) {
                      return;
                    }
                    setState(() => _isAddingToCart = true);
                    try {
                      await _handleCartAction(
                        item: item,
                        itemController: itemController,
                        cartController: cartController,
                        price: price,
                        priceWithDiscountAndAddons: priceWithDiscountAndAddons,
                        discount: discount,
                        discountType: discountType,
                        variation: variation,
                        stock: stock,
                        addOnIdList: addOnIdList,
                        addOnsList: addOnsList,
                      );
                    } finally {
                      if (mounted) {
                        setState(() => _isAddingToCart = false);
                      }
                    }
                  },
                );
              })),
            ]),
          ]),
        ),
      ),
    );
  }

  Future<void> _handleCartAction({
    required Item item,
    required ItemController itemController,
    required CartController cartController,
    required double price,
    required double priceWithDiscountAndAddons,
    required double? discount,
    required String? discountType,
    required Variation? variation,
    required int? stock,
    required List<AddOn> addOnIdList,
    required List<AddOns> addOnsList,
  }) async {
    String? invalid;

    if(AddressHelper.getUserAddressFromSharedPref() == null) {
      Get.back();
      Get.find<LocationController>().navigateToLocationScreen('home', canRoute: true);
      return;
    }

    if(_newVariation) {
      for(int index=0; index<item.foodVariations!.length; index++) {
        if(!item.foodVariations![index].multiSelect! && item.foodVariations![index].required!
            && !itemController.selectedVariations[index].contains(true)) {
          invalid = '${'choose_a_variation_from'.tr} ${item.foodVariations![index].name}';
          break;
        }else if(item.foodVariations![index].multiSelect! && (item.foodVariations![index].required!
            || itemController.selectedVariations[index].contains(true)) && item.foodVariations![index].min!
            > itemController.selectedVariationLength(itemController.selectedVariations, index)) {
          invalid = '${'select_minimum'.tr} ${item.foodVariations![index].min} '
              '${'and_up_to'.tr} ${item.foodVariations![index].max} ${'options_from'.tr}'
              ' ${item.foodVariations![index].name} ${'variation'.tr}';
          break;
        }
      }
    }

    // Only switch the active module when the item actually belongs to a different
    // module than the one currently being viewed. Calling setModule for the same
    // module needlessly clears the banner (clearBanner) without reloading it,
    // leaving the home banner slider stuck on its shimmer after add-to-cart.
    if(Get.find<SplashController>().moduleList != null && Get.find<SplashController>().module?.id != item.moduleId) {
      for(ModuleModel module in Get.find<SplashController>().moduleList!) {
        if(module.id == item.moduleId) {
          Get.find<SplashController>().setModule(module);
          break;
        }
      }
    }

    if(invalid != null) {
      showCustomSnackBar(invalid, getXSnackBar: true);
    }else {
      CartModel cartModel = CartModel(
          null, price, priceWithDiscountAndAddons, variation != null ? [variation] : [], itemController.selectedVariations,
          (price - PriceConverter.convertWithDiscount(price, discount, discountType)!),
          itemController.quantity, addOnIdList, addOnsList, widget.isCampaign, stock, item,  item.quantityLimit
      );

      List<OrderVariation> variations = _getSelectedVariations(
        isFoodVariation: Get.find<SplashController>().getModuleConfig(item.moduleType).newVariation!,
        foodVariations: item.foodVariations!, selectedVariations: itemController.selectedVariations,
      );
      List<int?> listOfAddOnId = _getSelectedAddonIds(addOnIdList: addOnIdList);
      List<int?> listOfAddOnQty = _getSelectedAddonQtnList(addOnIdList: addOnIdList);

      OnlineCart onlineCart = OnlineCart(
        (widget.cart != null || itemController.cartIndex != -1) ? widget.cart?.id ?? cartController.cartList[itemController.cartIndex].id : null,
        widget.isCampaign ? null : item.id, widget.isCampaign ? item.id : null,
        priceWithDiscountAndAddons.toString(), '', variation != null ? [variation] : null,
        Get.find<SplashController>().getModuleConfig(item.moduleType).newVariation! ? variations : null,
        itemController.quantity, listOfAddOnId, addOnsList, listOfAddOnQty, 'Item',
        reelId: widget.reelId,
      );

      if(widget.isCampaign) {
        Get.toNamed(RouteHelper.getCheckoutRoute('campaign'), arguments: CheckoutScreen(
          storeId: null, fromCart: false, cartList: [cartModel],
        ));
      }else {
        final bool isUpdate = widget.cart != null || itemController.cartIndex != -1;
        final bool success = isUpdate
            ? await Get.find<CartController>().updateCartOnline(onlineCart, storeId: item.storeId)
            : await Get.find<CartController>().addToCartOnline(onlineCart, storeId: item.storeId);

        if(success) {
          // Close the sheet FIRST, then show the snackbar. If the snackbar is shown
          // before Get.back(), the pop dismisses the open snackbar instead of the
          // sheet route — so the sheet stays open and the message never appears.
          // Popping first targets the sheet; the snackbar then shows over the screen
          // behind it (and only once, guarded by _closeSheet).
          _closeSheet();
          showCustomSnackBar(isUpdate ? 'item_updated_in_cart'.tr : 'item_added_to_cart'.tr, getXSnackBar: true, isError: false);
        }
      }
    }
  }

  // Closes the sheet exactly once. If the widget is already gone (sheet closed by
  // hand) or we've already closed it, this is a no-op — so a successful cart action
  // can never pop a second, unintended route (e.g. the screen behind the sheet).
  void _closeSheet() {
    if (_sheetClosed || !mounted) return;
    _sheetClosed = true;
    Get.back();
  }

  void _toggleFavourite(FavouriteController wishList, Item item) {
    if(AuthHelper.isLoggedIn()) {
      wishList.wishItemIdList.contains(item.id) ? wishList.removeFromFavouriteList(item.id, false, getXSnackBar: true)
          : wishList.addToFavouriteList(item, null, false, getXSnackBar: true);
    }else {
      showCustomSnackBar('you_are_not_logged_in'.tr, getXSnackBar: true);
    }
  }

  List<OrderVariation> _getSelectedVariations({required bool isFoodVariation, required List<FoodVariation>? foodVariations, required List<List<bool?>> selectedVariations}) {
    List<OrderVariation> variations = [];
    if(isFoodVariation) {
      for(int i=0; i<foodVariations!.length; i++) {
        if(selectedVariations[i].contains(true)) {
          variations.add(OrderVariation(name: foodVariations[i].name, values: OrderVariationValue(label: [])));
          for(int j=0; j<foodVariations[i].variationValues!.length; j++) {
            if(selectedVariations[i][j]!) {
              variations[variations.length-1].values!.label!.add(foodVariations[i].variationValues![j].level);
            }
          }
        }
      }
    }
    return variations;
  }

  List<int?> _getSelectedAddonIds({required List<AddOn> addOnIdList }) {
    List<int?> listOfAddOnId = [];
    for (var addOn in addOnIdList) {
      listOfAddOnId.add(addOn.id);
    }
    return listOfAddOnId;
  }

  List<int?> _getSelectedAddonQtnList({required List<AddOn> addOnIdList }) {
    List<int?> listOfAddOnQty = [];
    for (var addOn in addOnIdList) {
      listOfAddOnQty.add(addOn.quantity);
    }
    return listOfAddOnQty;
  }

}

class _SheetQuantityButton extends StatelessWidget {
  final IconData icon;
  final Widget? iconWidget;
  final VoidCallback onTap;
  const _SheetQuantityButton({required this.icon, this.iconWidget, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        height: 42, width: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        child: iconWidget ?? Icon(icon, size: 28, color: Theme.of(context).textTheme.bodyLarge!.color),
      ),
    );
  }
}

class AddonView extends StatelessWidget {
  final Item item;
  final ItemController itemController;
  final bool collapsed;
  final VoidCallback? onToggleCollapse;
  const AddonView({super.key, required this.item, required this.itemController, this.collapsed = false, this.onToggleCollapse});

  @override
  Widget build(BuildContext context) {
    return _OptionCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _OptionHeader(
          title: 'addons'.tr,
          subtitle: 'To add more additional items',
          chipText: 'optional'.tr,
          chipColor: Theme.of(context).disabledColor.withValues(alpha: 0.12),
          chipTextColor: Theme.of(context).hintColor,
          collapsed: collapsed,
          onToggle: onToggleCollapse,
        ),

        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: collapsed ? const SizedBox(width: double.infinity) : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: Dimensions.paddingSizeLarge),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: item.addOns!.length,
          separatorBuilder: (context, index) => const SizedBox(height: Dimensions.paddingSizeDefault),
          itemBuilder: (context, index) {
            final bool active = itemController.addOnActiveList[index];
            return InkWell(
              onTap: () {
                if (!active) {
                  itemController.addAddOn(true, index);
                } else if (itemController.addOnQtyList[index] == 1) {
                  itemController.addAddOn(false, index);
                }
              },
              child: Row(children: [
                Expanded(child: Text(item.addOns![index].name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: active ? robotoMedium : robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
                )),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Text(
                  item.addOns![index].price! > 0 ? '+ ${PriceConverter.convertPrice(item.addOns![index].price)}' : 'free'.tr,
                  maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr,
                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
                ),
                const SizedBox(width: Dimensions.paddingSizeDefault),

                active ? _AddonQuantityControl(
                  quantity: itemController.addOnQtyList[index] ?? 1,
                  onDecrease: () {
                    if (itemController.addOnQtyList[index]! > 1) {
                      itemController.setAddOnQuantity(false, index);
                    } else {
                      itemController.addAddOn(false, index);
                    }
                  },
                  onIncrease: () => itemController.setAddOnQuantity(true, index),
                ) : _SmallActionButton(
                  icon: Icons.add,
                  onTap: () => itemController.addAddOn(true, index),
                ),
              ]),
            );
          },
        ),
            ])),
      ]),
    );
  }
}

class VariationView extends StatelessWidget {
  final Item? item;
  final ItemController itemController;
  final Set<int>? collapsedIndexes;
  final void Function(int index)? onToggleCollapse;
  const VariationView({super.key, required this.item, required this.itemController, this.collapsedIndexes, this.onToggleCollapse});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: item!.choiceOptions!.length,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: item!.choiceOptions!.isNotEmpty ? Dimensions.paddingSizeDefault : 0),
      itemBuilder: (context, index) {
        final bool collapsed = collapsedIndexes?.contains(index) ?? false;
        return _OptionCard(
          margin: EdgeInsets.only(bottom: index != item!.choiceOptions!.length - 1 ? Dimensions.paddingSizeDefault : 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _OptionHeader(
              title: item!.choiceOptions![index].title ?? '',
              subtitle: 'select_one'.tr,
              chipText: 'required'.tr,
              chipColor: const Color(0xFFFFE8E8),
              chipTextColor: const Color(0xFFFF2424),
              collapsed: collapsed,
              onToggle: onToggleCollapse == null ? null : () => onToggleCollapse!(index),
            ),

            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: collapsed ? const SizedBox(width: double.infinity) : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: Dimensions.paddingSizeLarge),

                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: item!.choiceOptions![index].options!.length,
                  separatorBuilder: (context, i) => const SizedBox(height: Dimensions.paddingSizeLarge),
                  itemBuilder: (context, i) {
                    final bool selected = itemController.variationIndex != null && itemController.variationIndex!.isNotEmpty && itemController.variationIndex![index] == i;
                    return InkWell(
                      onTap: () => itemController.setCartVariationIndex(index, i, item),
                      child: Row(children: [
                        Expanded(
                          child: Text(
                            item!.choiceOptions![index].options![i].trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: selected ? robotoMedium : robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
                          ),
                        ),
                        _SelectionBox(selected: selected, isRadio: true),
                      ]),
                    );
                  },
                ),
              ]),
            ),
          ]),
        );
      },
    );
  }
}

class NewVariationView extends StatelessWidget {
  final Item? item;
  final ItemController itemController;
  final double? discount;
  final String? discountType;
  final bool showOriginalPrice;
  final int? highlightedIndex;
  final Map<int, GlobalKey>? cardKeys;
  final Set<int>? collapsedIndexes;
  final void Function(int index)? onToggleCollapse;
  const NewVariationView({super.key, required this.item, required this.itemController, required this.discount, required this.discountType, required this.showOriginalPrice, this.highlightedIndex, this.cardKeys, this.collapsedIndexes, this.onToggleCollapse});

  @override
  Widget build(BuildContext context) {
    return item!.foodVariations != null ? ListView.builder(
      shrinkWrap: true,
      itemCount: item!.foodVariations!.length,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: (item!.foodVariations != null && item!.foodVariations!.isNotEmpty) ? Dimensions.paddingSizeDefault : 0),
      itemBuilder: (context, index) {
        final FoodVariation foodVariation = item!.foodVariations![index];
        final List<VariationValue> values = foodVariation.variationValues ?? [];
        final bool isRequired = foodVariation.required == true;
        final bool isHighlighted = highlightedIndex == index;
        final bool hasMore = values.length > 4;
        final bool isCollapsed = hasMore && itemController.collapseVariation[index];
        final int visibleCount = isCollapsed ? 4 : values.length;
        final GlobalKey? cardKey = cardKeys?.putIfAbsent(index, () => GlobalKey());
        final bool cardCollapsed = collapsedIndexes?.contains(index) ?? false;

        return _OptionCard(
          key: cardKey,
          margin: EdgeInsets.only(bottom: index != item!.foodVariations!.length - 1 ? Dimensions.paddingSizeDefault : 0),
          highlighted: isHighlighted,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _OptionHeader(
              title: foodVariation.name ?? '',
              subtitle: foodVariation.multiSelect! ? 'Select any of ${foodVariation.max}' : 'select_one'.tr,
              chipText: isRequired ? 'required'.tr : 'optional'.tr,
              chipColor: isRequired ? const Color(0xFFFFE8E8) : Theme.of(context).disabledColor.withValues(alpha: 0.12),
              chipTextColor: isRequired ? const Color(0xFFFF2424) : Theme.of(context).hintColor,
              emphasised: isHighlighted && isRequired,
              collapsed: cardCollapsed,
              onToggle: onToggleCollapse == null ? null : () => onToggleCollapse!(index),
            ),

            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: cardCollapsed ? const SizedBox(width: double.infinity) : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: Dimensions.paddingSizeLarge),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: visibleCount,
              separatorBuilder: (context, i) => const SizedBox(height: Dimensions.paddingSizeDefault),
              itemBuilder: (context, i) {
                final bool selected = itemController.selectedVariations[index][i] == true;
                final double optionPrice = values[i].optionPrice ?? 0;
                return InkWell(
                  onTap: () => itemController.setNewCartVariationIndex(index, i, item!),
                  child: Row(children: [
                    Expanded(
                      child: Text(
                        values[i].level?.trim() ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: selected ? robotoMedium : robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
                      ),
                    ),
                    showOriginalPrice ? Text(
                      '+ ${PriceConverter.convertPrice(optionPrice)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.ltr,
                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor, decoration: TextDecoration.lineThrough),
                    ) : const SizedBox(),
                    SizedBox(width: showOriginalPrice ? Dimensions.paddingSizeExtraSmall : 0),
                    Text(
                      '+ ${PriceConverter.convertPrice(optionPrice, discount: discount, discountType: discountType, isFoodVariation: true)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.ltr,
                      style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeDefault),
                    _SelectionBox(selected: selected, isRadio: !foodVariation.multiSelect!),
                  ]),
                );
              },
            ),

            hasMore ? Center(
              child: Padding(
                padding: const EdgeInsets.only(top: Dimensions.paddingSizeLarge),
                child: InkWell(
                  onTap: () => itemController.showMoreSpecificSection(index),
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                        isCollapsed ? 'see_more'.tr : 'see_less'.tr,
                        style: robotoMedium.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeExtraLarge),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                      Icon(isCollapsed ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up, color: Theme.of(context).primaryColor),
                    ]),
                  ),
                ),
              ),
            ) : const SizedBox(),
              ],
            ),
          ),
          ]),
        );
      },
    ) : const SizedBox();
  }
}

class _OptionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final bool highlighted;
  const _OptionCard({super.key, required this.child, this.margin, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    const Color highlightColor = Color(0xFFFF2424);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        border: Border.all(
          color: highlighted ? highlightColor : Colors.transparent,
          width: highlighted ? 2 : 1.5,
        ),
        boxShadow: highlighted ? [BoxShadow(
          color: highlightColor.withValues(alpha: 0.18),
          blurRadius: 14, spreadRadius: 1,
        )] : null,
      ),
      child: child,
    );
  }
}

class _OptionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String chipText;
  final Color chipColor;
  final Color chipTextColor;
  final bool emphasised;
  final bool collapsed;
  final VoidCallback? onToggle;
  const _OptionHeader({required this.title, required this.subtitle, required this.chipText, required this.chipColor, required this.chipTextColor, this.emphasised = false, this.collapsed = false, this.onToggle});

  @override
  Widget build(BuildContext context) {
    const Color emphasisColor = Color(0xFFFF2424);
    final Color resolvedChipColor = emphasised ? emphasisColor : chipColor;
    final Color resolvedChipTextColor = emphasised ? Colors.white : chipTextColor;
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
          ]),
        ),
        const SizedBox(width: Dimensions.paddingSizeDefault),
        AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
          decoration: BoxDecoration(color: resolvedChipColor, borderRadius: BorderRadius.circular(30)),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 280),
            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: resolvedChipTextColor),
            child: Text(chipText),
          ),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Container(width: 28, height: 28,
          decoration: BoxDecoration(color: Theme.of(context).disabledColor.withValues(alpha: 0.12), shape: BoxShape.circle),
          // Chevron points down when collapsed (tap to expand), up when expanded.
          child: AnimatedRotation(
            turns: collapsed ? 0.0 : 0.5,
            duration: const Duration(milliseconds: 250),
            child: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).textTheme.bodyLarge!.color, size: 20),
          ),
        ),
      ]),
    );
  }
}

class _SelectionBox extends StatelessWidget {
  final bool selected;
  final bool isRadio;
  const _SelectionBox({required this.selected, required this.isRadio});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 20, width: 20,
      decoration: BoxDecoration(
        shape: isRadio ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isRadio ? null : BorderRadius.circular(Dimensions.radiusSmall),
        border: Border.all(color: selected ? Theme.of(context).primaryColor : Theme.of(context).disabledColor, width: 1),
        color: selected ? Theme.of(context).primaryColor : Colors.transparent,
      ),
      child: selected ? Icon(isRadio ? Icons.circle : Icons.check, size: isRadio ? 12 : 16, color: Colors.white) : null,
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SmallActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Theme.of(context).disabledColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        child: Icon(icon, size: 20, color: Theme.of(context).textTheme.bodyLarge!.color),
      ),
    );
  }
}

class _AddonQuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  const _AddonQuantityControl({required this.quantity, required this.onDecrease, required this.onIncrease});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).disabledColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(onPressed: onDecrease, icon: const Icon(Icons.remove), splashRadius: 20),
        Text(quantity.toString(), style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
        IconButton(onPressed: onIncrease, icon: const Icon(Icons.add), splashRadius: 20),
      ]),
    );
  }
}

// Auto-playing header video. Starts muted (so it never blares on open) and shows
// a mute/unmute toggle. Supports YouTube (web + mobile) and direct video files.
// Self-contained on purpose so it doesn't touch the shared ItemMediaPreviewWidget
// / _ItemMediaVideoView used by the fullscreen viewer.
class _HeaderVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String thumbnailUrl;
  final bool isDesktop;
  final VoidCallback? onFullscreenTap;
  const _HeaderVideoPlayer({super.key, required this.videoUrl, required this.thumbnailUrl, required this.isDesktop, this.onFullscreenTap});

  @override
  State<_HeaderVideoPlayer> createState() => _HeaderVideoPlayerState();
}

class _HeaderVideoPlayerState extends State<_HeaderVideoPlayer> {
  // Active header-video instances, so the carousel/fullscreen can pause/resume them.
  static final Set<_HeaderVideoPlayerState> _instances = <_HeaderVideoPlayerState>{};
  static void pauseAll() { for (final s in _instances.toList()) s._pause(); }
  static void resumeAll() { for (final s in _instances.toList()) s._resume(); }

  VideoPlayerController? _fileController;
  YoutubePlayerController? _ytController;
  web_youtube.YoutubePlayerController? _ytWebController;
  bool _isYoutube = false;
  bool _ready = false;
  bool _hasError = false;
  bool _muted = true;

  @override
  void initState() {
    super.initState();
    _instances.add(this);
    _initialize();
  }

  Future<void> _initialize() async {
    final String? videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
    if (videoId != null && videoId.isNotEmpty) {
      _isYoutube = true;
      if (kIsWeb) {
        _ytWebController = web_youtube.YoutubePlayerController.fromVideoId(
          videoId: videoId, autoPlay: true,
          params: const web_youtube.YoutubePlayerParams(mute: true, showControls: true, showFullscreenButton: true),
        );
      } else {
        _ytController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(autoPlay: true, mute: true, loop: true),
        );
      }
      _ready = true;
      if (mounted) setState(() {});
      return;
    }

    try {
      _fileController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _fileController!.initialize();
      await _fileController!.setVolume(0); // start muted
      await _fileController!.setLooping(true);
      await _fileController!.play();
      _fileController!.addListener(_onFileTick);
      _ready = true;
    } catch (_) {
      _hasError = true;
    }
    if (mounted) setState(() {});
  }

  void _onFileTick() {
    if (mounted) setState(() {});
  }

  void _pause() {
    _fileController?.pause();
    _ytController?.pause();
    _ytWebController?.pauseVideo();
  }

  void _resume() {
    _fileController?.play();
    _ytController?.play();
    _ytWebController?.playVideo();
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    if (_fileController != null) {
      _fileController!.setVolume(_muted ? 0 : 1);
    } else if (_ytController != null) {
      _muted ? _ytController!.mute() : _ytController!.unMute();
    } else if (_ytWebController != null) {
      _muted ? _ytWebController!.mute() : _ytWebController!.unMute();
    }
  }

  @override
  void dispose() {
    _instances.remove(this);
    _fileController?.removeListener(_onFileTick);
    _fileController?.dispose();
    _ytController?.dispose();
    _ytWebController?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: <Widget>[
      // Thumbnail underneath so there's never a blank frame while the player warms up.
      _thumbnail(),
      if (!_hasError) _player(),
      if (_ready && !_hasError) Positioned(
        left: Dimensions.paddingSizeDefault,
        bottom: Dimensions.paddingSizeLarge,
        child: _MuteToggleButton(muted: _muted, onTap: _toggleMute),
      ),
    ]);
  }

  Widget _thumbnail() {
    if (widget.thumbnailUrl.isEmpty) return Container(color: Colors.black);
    if (widget.thumbnailUrl.toLowerCase().endsWith('.svg')) {
      return SvgPicture.network(widget.thumbnailUrl, fit: BoxFit.cover);
    }
    return CustomImage(image: widget.thumbnailUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
  }

  Widget _player() {
    if (_isYoutube) {
      if (kIsWeb && _ytWebController != null) {
        return web_youtube.YoutubePlayer(controller: _ytWebController!, aspectRatio: 16 / 9);
      }
      if (!kIsWeb && _ytController != null) {
        return Center(child: YoutubePlayer(
          controller: _ytController!,
          showVideoProgressIndicator: true,
          // Replace the default bottom row so the fullscreen icon opens the in-app
          // viewer instead of rotating the whole app to landscape fullscreen.
          bottomActions: <Widget>[
            const SizedBox(width: Dimensions.paddingSizeSmall),
            const CurrentPosition(),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            const ProgressBar(isExpanded: true),
            const RemainingDuration(),
            if (widget.onFullscreenTap != null)
              IconButton(
                icon: const Icon(Icons.fullscreen, color: Colors.white),
                onPressed: widget.onFullscreenTap,
              ),
          ],
        ));
      }
      return const SizedBox.shrink();
    }
    final VideoPlayerController? c = _fileController;
    if (c != null && c.value.isInitialized) {
      // Cover the header area like the thumbnail it replaces.
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(width: c.value.size.width, height: c.value.size.height, child: VideoPlayer(c)),
      );
    }
    return const SizedBox.shrink();
  }
}

class _MuteToggleButton extends StatelessWidget {
  final bool muted;
  final VoidCallback onTap;
  const _MuteToggleButton({required this.muted, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 36, width: 36,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: Icon(muted ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
