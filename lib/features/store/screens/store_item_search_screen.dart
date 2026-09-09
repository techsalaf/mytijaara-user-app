import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/cart/domain/models/all_carts_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/redesign_feature/global_widgets/exclusive_deal_card.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/widgets/bottom_add_to_cart_widget.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/paginated_list_view.dart';
import 'package:sixam_mart/common/widgets/veg_filter_widget.dart';

class StoreItemSearchScreen extends StatefulWidget {
  final String? storeID;
  const StoreItemSearchScreen({super.key, required this.storeID});

  @override
  State<StoreItemSearchScreen> createState() => _StoreItemSearchScreenState();
}

class _StoreItemSearchScreenState extends State<StoreItemSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    Get.find<StoreController>().initSearchData();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StoreController>(
      builder: (storeController) {
        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size(Dimensions.webMaxWidth, 60),
            child: Container(
              height: 60 + context.mediaQueryPadding.top, width: Dimensions.webMaxWidth,
              padding: EdgeInsets.only(top: context.mediaQueryPadding.top),
              color: Theme.of(context).cardColor,
              alignment: Alignment.center,
              child: SizedBox(width: Dimensions.webMaxWidth, child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeSmall),
                child: Row(children: [

                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).primaryColor),
                  ),

                  Expanded(child: TextField(
                    controller: _searchController,
                    style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeLarge),
                    textInputAction: TextInputAction.search,
                    cursorColor: Theme.of(context).primaryColor,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: 'search_item_in_store'.tr,
                      hintStyle: robotoRegular.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).hintColor),
                      isDense: true,
                      contentPadding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                        borderSide: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.3), width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                        borderSide: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.3), width: 1),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.search, color: Theme.of(context).hintColor, size: 25),
                        onPressed: () => Get.find<StoreController>().getStoreSearchItemList(
                          _searchController.text.trim(), widget.storeID, 1, Get.find<StoreController>().searchType,
                        ),
                      ),
                    ),
                    onSubmitted: (text) => Get.find<StoreController>().getStoreSearchItemList(
                      _searchController.text.trim(), widget.storeID, 1, Get.find<StoreController>().searchType,
                    ),
                  )),
                  const SizedBox(width: Dimensions.paddingSizeSmall),


                  VegFilterWidget(
                    type: storeController.searchText.isNotEmpty ? storeController.searchType : null,
                    onSelected: (String type) {
                      storeController.getStoreSearchItemList(storeController.searchText, widget.storeID, 1, type);
                    },
                    fromAppBar: true,
                  )

                ]),
              )),
            ),
          ),

          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: ResponsiveHelper.isDesktop(context) ? null : const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  child: FooterView(child: SizedBox(width: Dimensions.webMaxWidth, child: PaginatedListView(
                    scrollController: _scrollController,
                    onPaginate: (int? offset) => storeController.getStoreSearchItemList(
                      storeController.searchText, widget.storeID, offset!, storeController.searchType,
                    ),
                    totalSize: storeController.storeSearchItemModel?.totalSize,
                    offset: storeController.storeSearchItemModel?.offset,
                    itemView: _SearchItemListView(
                      items: storeController.storeSearchItemModel?.items,
                      hasSearched: storeController.searchText.isNotEmpty,
                    ),
                  ))),
                ),
              ),

              GetBuilder<CartController>(
                builder: (cartController) {
                  if (ResponsiveHelper.isDesktop(context)) return const SizedBox();
                  final int? currentStoreId = int.tryParse(widget.storeID??'');
                  if (currentStoreId == null) return const SizedBox();
                  final AllCartsModel? existingCart = cartController.getCartsForStore(currentStoreId);
                  return existingCart != null && Get.find<StoreController>().store != null ? BottomAddToCartWidget(storeId: currentStoreId) : const SizedBox();
                },
              ),
            ],
          ),

          // bottomNavigationBar: GetBuilder<CartController>(builder: (cartController) {
          //   return cartController.cartList.isNotEmpty && !ResponsiveHelper.isDesktop(context) ? const BottomCartWidget() : const SizedBox();
          // })

        );
      }
    );
  }
}

class _SearchItemListView extends StatelessWidget {
  final List<Item>? items;
  final bool hasSearched;

  const _SearchItemListView({required this.items, required this.hasSearched});

  @override
  Widget build(BuildContext context) {
    if (items == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraLarge * 2),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (items!.isEmpty) {
      if (!hasSearched) return const SizedBox();
      return Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Center(
          child: Text('no_items_found'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
        ),
      );
    }
    return Column(
      children: List.generate(items!.length, (index) {
        final Item item = items![index];
        final bool isLast = index == items!.length - 1;
        return Container(
          margin: EdgeInsets.only(bottom: isLast ? 0 : Dimensions.paddingSizeDefault),
          padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            border: isLast ? null : Border(
              bottom: BorderSide(color: Theme.of(context).disabledColor.withValues(alpha: 0.18)),
            ),
          ),
          child: ExclusiveDealCard(
            item: item,
            width: double.infinity,
            index: index,
          ),
        );
      }),
    );
  }
}
