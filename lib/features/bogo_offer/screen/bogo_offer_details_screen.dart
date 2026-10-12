import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/no_data_screen.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';
import 'package:sixam_mart/features/bogo_offer/controllers/bogo_offer_details_controller.dart';
import 'package:sixam_mart/features/bogo_offer/domain/models/bogo_offer_model.dart';
import 'package:sixam_mart/features/bogo_offer/widgets/bogo_store_offer_card.dart';
import 'package:sixam_mart/features/bogo_offer/widgets/bogo_store_offer_card_shimmer.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class BogoOfferDetailsScreen extends StatefulWidget {
  final String? offerIdOrSlug;

  /// The module the offer belongs to, carried over from the tab it was opened from.
  final int? moduleId;

  const BogoOfferDetailsScreen({super.key, this.offerIdOrSlug, this.moduleId});

  @override
  State<BogoOfferDetailsScreen> createState() => _BogoOfferDetailsScreenState();
}

class _BogoOfferDetailsScreenState extends State<BogoOfferDetailsScreen> {
  static const int _shimmerItemCount = 3;
  final ScrollController _scrollController = ScrollController();

  ModuleModel? _entryModule;
  bool _switchedModule = false;

  @override
  void initState() {
    super.initState();
    _entryModule = Get.find<SplashController>().module;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOffer());
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadOffer() async {
    final SplashController splashController = Get.find<SplashController>();
    // The bundles are added to the cart, and their stores opened, under the active module's
    // header — so an offer reached from another module's tab has to move the app to it first.
    if(widget.moduleId != null && splashController.module?.id != widget.moduleId) {
      _switchedModule = await splashController.activateModuleById(widget.moduleId);
    }
    if(!mounted || widget.offerIdOrSlug == null || widget.offerIdOrSlug!.isEmpty) {
      return;
    }
    Get.find<BogoOfferDetailsController>().getBogoOfferDetails(widget.offerIdOrSlug!, moduleId: widget.moduleId);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    // The switch above belongs to this screen. Left active it relocated the customer for
    // good: the dashboard kept the tab they came from, and the next screen to read the
    // active module — the BOGO list's own tab — opened on the offer's module instead.
    // notify: false because a rebuild cannot be requested from dispose.
    final SplashController splashController = Get.find<SplashController>();
    if(_switchedModule && splashController.module?.id == widget.moduleId) {
      splashController.setModule(_entryModule, notify: false);
    }
    super.dispose();
  }

  void _onScroll() {
    if(_scrollController.position.pixels < _scrollController.position.maxScrollExtent - 200) {
      return;
    }
    Get.find<BogoOfferDetailsController>().loadMoreBundles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'bogo_offer_details'.tr),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: GetBuilder<BogoOfferDetailsController>(builder: (bogoOfferDetailsController) {
        final BogoOfferDetailsResponseModel? details = bogoOfferDetailsController.bogoOfferDetailsModel;
        final bool isLoading = bogoOfferDetailsController.isLoading;
        final bool paginate = bogoOfferDetailsController.bundlePaginate;
        final List<BogoBundleModel> bundles = details?.bundles ?? [];

        return details == null && !isLoading ? const _OfferUnavailableView() : CustomScrollView(controller: _scrollController, slivers: [
          SliverToBoxAdapter(
            child: AspectRatio(
              aspectRatio: 2.5,
              child: isLoading
                ? Shimmer(child: Container(color: Theme.of(context).shadowColor))
                : CustomImage(image: details?.imageFullUrl ?? '', fit: BoxFit.fill),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              color: Theme.of(context).cardColor,
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: isLoading ? const _HeaderShimmer() : Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                if(details?.title != null && details!.title!.isNotEmpty) 
                  Text(details.title ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                    style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
               
                if(details?.description != null && details!.description!.isNotEmpty)...[
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  Text(details.description!, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).disabledColor)),
                ],
                const SizedBox(height: Dimensions.paddingSizeDefault),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(Dimensions.radiusMedium),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(
                      child: Text(details!.offerLabel?.toUpperCase() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeLarge, color: Colors.blueAccent)),
                    ),
                    if(details.validUntil != null) ...[
                      const SizedBox(width: Dimensions.paddingSizeSmall),

                      Flexible(
                        child: Text('${'valid_until'.tr} : ${details.validUntil}', maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
                      ),
                    ],
                  ]),
                ),
              ]),
            ),
          ),

          isLoading || bundles.isEmpty ? const SliverToBoxAdapter(child: SizedBox.shrink()) : SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingSizeDefault, Dimensions.paddingSizeLarge, Dimensions.paddingSizeDefault, 0,
              ),
              child: TitleWidget(title: 'explore_offer'.tr, titleFontSize: Dimensions.fontSizeExtraLarge),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            sliver: isLoading ? SliverList.separated(
              itemCount: _shimmerItemCount,
              separatorBuilder: (context, index) => const SizedBox(height: Dimensions.paddingSizeLarge),
              itemBuilder: (context, index) => const BogoStoreOfferCardShimmer(),
            ) : bundles.isEmpty ? SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: NoDataScreen(text: 'no_offer_found'.tr, isNotScrollable: true)),
            ) : SliverList.separated(
              itemCount: bundles.length + (paginate ? 1 : 0),
              separatorBuilder: (context, index) => const SizedBox(height: Dimensions.paddingSizeLarge),
              itemBuilder: (context, index) => index < bundles.length
                ? BogoStoreOfferCard(bundle: bundles[index], offerTitle: details?.title, offerLabel: details?.offerLabel, validUntil: details?.validUntil, remainingUses: details?.remainingUses, offerModuleId: bogoOfferDetailsController.offerModuleId)
                : const Padding(
                    padding: EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                    child: Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                  ),
            ),
          ),
        ]);
      }),
    );
  }
}

class _OfferUnavailableView extends StatelessWidget {
  const _OfferUnavailableView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

        Text('this_offer_is_currently_unavailable'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
        Text('please_tap_the_button_below_to_explore_other_available_offers'.tr,
          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall), textAlign: TextAlign.center),
        const SizedBox(height: 40),
        IconButton(
          onPressed: () => Get.offNamed(RouteHelper.getBogoOfferRoute()),
          icon: Icon(Icons.arrow_circle_right_outlined, color: Theme.of(context).primaryColor, size: 40),
        ),
      ]),
    );
  }
}

class _HeaderShimmer extends StatelessWidget {
  const _HeaderShimmer();

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).shadowColor;

    return Shimmer(
      child: Container(
        width: double.infinity, height: 44,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
      ),
    );
  }
}

// SUMMARY
// BOGO offer details page. Shows the offer banner, title, description, label and
// validity, then the paginated list of store bundles running that offer, each opening
// its own bundle sheet. Activates the offer's own module on entry, so bundles added
// from here land in that module's cart and its stores open under it, and puts the
// module the customer arrived in back when the page is left.
