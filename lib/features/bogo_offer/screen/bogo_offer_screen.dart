import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_asset_image_widget.dart';
import 'package:sixam_mart/common/widgets/no_data_screen.dart';
import 'package:sixam_mart/features/bogo_offer/controllers/bogo_offer_controller.dart';
import 'package:sixam_mart/features/bogo_offer/domain/models/bogo_offer_model.dart';
import 'package:sixam_mart/features/bogo_offer/widgets/bogo_module_tab_bar.dart';
import 'package:sixam_mart/features/bogo_offer/widgets/bogo_offer_item_card.dart';
import 'package:sixam_mart/features/bogo_offer/widgets/bogo_offer_item_shimmer_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class BogoOfferScreen extends StatefulWidget {
  /// The module this screen was opened from — its tab is selected on entry.
  final int? moduleId;
  const BogoOfferScreen({super.key, this.moduleId});

  @override
  State<BogoOfferScreen> createState() => _BogoOfferScreenState();
}

class _BogoOfferScreenState extends State<BogoOfferScreen> {
  static const int _shimmerItemCount = 4;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Not deferred to a post-frame callback: the controller is a singleton, so until
    // this runs the screen paints the tab and offers left behind by the last visit.
    _loadModules(notify: false);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Re-checks which modules are running an offer, then loads the selected one's list.
  Future<void> _loadModules({bool notify = true}) {
    return Get.find<BogoOfferController>().getLiveBogoModules(
      Get.find<SplashController>().moduleList, notify: notify,
      // The screen opens on the module being browsed. The route only carries it when
      // the caller knew it — the offer-unavailable link, for one, does not.
      initialModuleId: widget.moduleId ?? Get.find<SplashController>().module?.id,
    );
  }

  Future<void> _onRefresh() => _loadModules();

  void _onScroll() {
    if(_scrollController.position.pixels < _scrollController.position.maxScrollExtent - 200) {
      return;
    }
    Get.find<BogoOfferController>().loadMoreBogoOffers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'bogo_offer'.tr),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: GetBuilder<BogoOfferController>(builder: (bogoOfferController) {
        final List<BogoOfferCardModel> offers = bogoOfferController.bogoOfferList ?? [];
        final bool isLoading = bogoOfferController.isLoading;
        final bool paginate = bogoOfferController.bogoOfferPaginate;

        final List<ModuleModel>? modules = bogoOfferController.bogoModules;

        return Column(children: [
          if(modules != null && modules.isNotEmpty) BogoModuleTabBar(
            modules: modules,
            selectedIndex: bogoOfferController.selectedBogoModuleIndex,
            onSelected: (index) => bogoOfferController.setSelectedBogoModule(index),
          ),

          Expanded(child: RefreshIndicator(
            onRefresh: _onRefresh,
            child: CustomScrollView(controller: _scrollController, physics: const AlwaysScrollableScrollPhysics(), slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraLarge),
                  child: Column(children: [
                    const CustomAssetImageWidget(Images.bogoOffers, height: 80, width: 80),
                    const SizedBox(height: Dimensions.paddingSizeDefault),

                    Text('hurry_up_bogo_offer_is_live'.tr, textAlign: TextAlign.center,
                      style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                    Text('get_best_value_from_order_with_exclusive_bogo_deals'.tr, textAlign: TextAlign.center,
                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
                  ]),
                ),
              ),

              DecoratedSliver(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(Dimensions.radiusExtraLarge),
                    topRight: Radius.circular(Dimensions.radiusExtraLarge),
                  ),
                ),
                sliver: SliverMainAxisGroup(slivers: [
                  SliverPadding(
                    padding: EdgeInsets.all(Dimensions.fontSizeExtraLarge),
                    sliver: isLoading ? SliverList.separated(
                      itemCount: _shimmerItemCount,
                      separatorBuilder: (context, index) => const SizedBox(height: Dimensions.paddingSizeLarge),
                      itemBuilder: (context, index) => const BogoOfferItemShimmerWidget(),
                    ) : offers.isEmpty ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: NoDataScreen(text: 'no_offer_found'.tr, isNotScrollable: true)),
                    ) : SliverList.separated(
                      itemCount: offers.length + (paginate ? 1 : 0),
                      separatorBuilder: (context, index) => const SizedBox(height: Dimensions.paddingSizeLarge),
                      itemBuilder: (context, index) => index < offers.length
                        ? BogoOfferItemCard(offer: offers[index], moduleId: bogoOfferController.selectedBogoModule?.id)
                        : const Padding(
                            padding: EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                            child: Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                          ),
                    ),
                  ),

                  const SliverFillRemaining(hasScrollBody: false, child: SizedBox.shrink()),
                ]),
              ),
            ]),
          )),
        ]);
      }),
    );
  }
}
