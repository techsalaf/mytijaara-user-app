import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/common/widgets/no_data_screen.dart';
import 'package:sixam_mart/features/item/controllers/campaign_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/redesign_feature/global_widgets/exclusive_deal_card.dart';
import 'package:sixam_mart/util/dimensions.dart';

class ItemCampaignScreen extends StatefulWidget {
  final bool isJustForYou;
  const ItemCampaignScreen({super.key, required this.isJustForYou});

  @override
  State<ItemCampaignScreen> createState() => _ItemCampaignScreenState();
}

class _ItemCampaignScreenState extends State<ItemCampaignScreen> {
  @override
  void initState() {
    super.initState();

    Get.find<CampaignController>().getItemCampaignList(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: widget.isJustForYou ? 'just_for_you'.tr : 'campaigns'.tr),
      endDrawer: const MenuDrawer(),
      endDrawerEnableOpenDragGesture: false,
      body: SingleChildScrollView(
        child: FooterView(
          child: SizedBox(
            width: Dimensions.webMaxWidth,
            child: GetBuilder<CampaignController>(builder: (campController) {
              final List<Item>? items = campController.itemCampaignList;
              if (items == null) {
                return const _CampaignListShimmer();
              }
              if (items.isEmpty) {
                return NoDataScreen(text: 'no_campaign_found'.tr);
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: Dimensions.paddingSizeDefault),
                itemBuilder: (context, index) => ExclusiveDealCard(
                  item: items[index], width: double.infinity, index: index, isCampaign: true,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _CampaignListShimmer extends StatelessWidget {
  const _CampaignListShimmer();

  @override
  Widget build(BuildContext context) {
    final Color base = Theme.of(context).disabledColor.withValues(alpha: 0.12);
    return Shimmer(
      duration: const Duration(seconds: 2),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        itemCount: 8,
        separatorBuilder: (_, _) => const SizedBox(height: Dimensions.paddingSizeDefault),
        itemBuilder: (context, index) => Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                height: 12, width: 120,
                decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
              ),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              Container(
                height: 14, width: 180,
                decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
              ),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              Container(
                height: 14, width: 80,
                decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
              ),
            ]),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Container(
            height: 115, width: 115,
            decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(12)),
          ),
        ]),
      ),
    );
  }
}
