import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/featured_store_card.dart';
import 'package:sixam_mart/common/widgets/no_data_screen.dart';
import 'package:sixam_mart/features/bogo_offer/widgets/bogo_full_screen_sheet.dart';
import 'package:sixam_mart/features/happy_hour/controllers/happy_hour_controller.dart';
import 'package:sixam_mart/features/happy_hour/widgets/happy_hour_banner_widget.dart';
import 'package:sixam_mart/features/happy_hour/widgets/happy_hour_palette.dart';
import 'package:sixam_mart/features/happy_hour/widgets/happy_hour_promo_banner_card_widget.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
class HappyHourScreen extends StatefulWidget {
  const HappyHourScreen({super.key});

  static Future<void> show(BuildContext context) {
    return BogoFullScreenSheet.show(context, child: const HappyHourScreen());
  }

  @override
  State<HappyHourScreen> createState() => _HappyHourScreenState();
}

class _HappyHourScreenState extends State<HappyHourScreen> {
  static const double _collapseThreshold = 90;

  VoidCallback? _happyHourDisposer;
  bool _closing = false;
  bool _collapsed = false;

  @override
  void initState() {
    super.initState();
    final HappyHourController happyHourController = Get.find<HappyHourController>();
    _happyHourDisposer = happyHourController.addListener(_closeWhenExpired);
    WidgetsBinding.instance.addPostFrameCallback((_) => happyHourController.getStoreList(1, false, notify: false));
  }

  @override
  void dispose() {
    _happyHourDisposer?.call();
    super.dispose();
  }

  void _closeWhenExpired() {
    if(_closing || !mounted || Get.find<HappyHourController>().isActive) {
      return;
    }
    _closing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(mounted && Get.isBottomSheetOpen == true) {
        Get.back();
      }
    });
  }

  void _openStore(Store store) {
    Get.back();
    Get.toNamed(RouteHelper.getStoreRoute(id: store.id, page: 'store_new', slug: store.slug ?? ''));
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScroll,
      child: BogoFullScreenSheet(
      header: _HappyHourSheetHeader(collapsed: _collapsed),
      slivers: [
        const SliverToBoxAdapter(child: Padding(
          padding: EdgeInsets.fromLTRB(
            Dimensions.paddingSizeLarge, Dimensions.paddingSizeSmall,
            Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge,
          ),
          child: HappyHourPromoBannerCardWidget(),
        )),

        // The list rides on its own rounded surface panel.
        SliverToBoxAdapter(
          child: GetBuilder<HappyHourController>(builder: (happyHourController) {
            final StoreModel? storeModel = happyHourController.storeModel;
            final List<Store> stores = storeModel?.stores ?? const <Store>[];

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusLarge)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

                if(storeModel == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraLarge),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if(stores.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraLarge),
                    child: NoDataScreen(text: 'no_store_available'.tr, isNotScrollable: true),
                  )
                else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                    itemCount: stores.length,
                    separatorBuilder: (context, index) => const SizedBox(height: Dimensions.paddingSizeDefault),
                    itemBuilder: (context, index) => FeaturedStoreCard(
                      data: stores[index], width: double.infinity, imageHeight: 150,
                      isQuick: false, onTap: () => _openStore(stores[index]),
                    ),
                  ),

                  if(happyHourController.hasMoreStores) const Padding(
                    padding: EdgeInsets.only(top: Dimensions.paddingSizeDefault),
                    child: Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                  ),
                ],
              ]),
            );
          }),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: ColoredBox(color: Theme.of(context).colorScheme.surface),
        ),
      ],
    ));
  }

  bool _handleScroll(ScrollNotification notification) {
    if(notification.depth != 0) {
      return false;
    }
    if(notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200) {
      Get.find<HappyHourController>().loadMoreStores();
    }
    final bool collapsed = notification.metrics.pixels > _collapseThreshold;
    if(collapsed != _collapsed) {
      setState(() => _collapsed = collapsed);
    }
    return false;
  }
}

class _HappyHourSheetHeader extends StatelessWidget {
  final bool collapsed;

  const _HappyHourSheetHeader({required this.collapsed});

  static const Duration _duration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: _duration,
      padding: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeLarge, 0, Dimensions.paddingSizeLarge, Dimensions.paddingSizeSmall,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(
          color: collapsed ? Theme.of(context).disabledColor.withValues(alpha: 0.3) : Colors.transparent,
        )),
      ),
      child: Row(children: [

        Expanded(child: IgnorePointer(
          ignoring: !collapsed,
          child: AnimatedOpacity(
            opacity: collapsed ? 1 : 0, duration: _duration,
            child: GetBuilder<HappyHourController>(builder: (happyHourController) {
              final String title = 'happy_hours_offer_title'.tr
                  .replaceAll('{percentage}', happyHourController.discountLabel);
              return Text(
                title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
              );
            }),
          ),
        )),
        IgnorePointer(
          ignoring: !collapsed,
          child: AnimatedOpacity(
            opacity: collapsed ? 1 : 0, duration: _duration, 
            child: const HappyHourCountdownChip(background: HappyHourPalette.timer))
          ),
        const SizedBox(width: Dimensions.paddingSizeSmall),

        const BogoSheetCloseButton(),
      ]),
    );
  }
}
