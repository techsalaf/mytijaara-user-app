import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/no_data_screen.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/cart/domain/models/all_carts_model.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/store/screens/store_screen.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/common/widgets/confirmation_dialog.dart';
import 'package:sixam_mart/util/styles.dart';

const Set<String> _excludedModuleTypes = <String>{
  AppConstants.parcel,
  AppConstants.taxi,
  AppConstants.ride,
};

List<ModuleModel> _visibleModulesFrom(SplashController splash) {
  final List<ModuleModel> modules = splash.moduleList ?? <ModuleModel>[];
  return modules.where((ModuleModel m) => !_excludedModuleTypes.contains(m.moduleType)).toList();
}

class GlobalCartScreen extends StatefulWidget {
  const GlobalCartScreen({super.key, required this.fromNav, this.initialModuleId});
  final bool fromNav;
  // When provided (e.g. from the search screen), pre-selects this module's tab
  // instead of deriving it from the dashboard's selected module index.
  final int? initialModuleId;

  @override
  State<GlobalCartScreen> createState() => _GlobalCartScreenState();
}

class _GlobalCartScreenState extends State<GlobalCartScreen> {
  int _selectedVisibleIndex = 0;
  // The active module when this screen opened. Selecting another module's cart
  // re-points the header (setModule), which also clears the banner — so we
  // restore this module (and its banner) when leaving.
  ModuleModel? _entryModule;

  @override
  void initState() {
    super.initState();

    final SplashController splash = Get.find<SplashController>();
    _entryModule = splash.module;
    final List<ModuleModel> visibleModules = _visibleModulesFrom(splash);
    ModuleModel? initialModule;
    if(visibleModules.isNotEmpty) {
      int matchIndex = -1;
      // Prefer the explicitly-passed module (e.g. from search), then fall back to
      // the dashboard's selected module.
      if(widget.initialModuleId != null) {
        matchIndex = visibleModules.indexWhere((ModuleModel m) => m.id == widget.initialModuleId);
      }
      if(matchIndex < 0) {
        final ModuleModel? currentSplashModule = _moduleAtSplashIndex(splash, splash.selectedModuleIndex);
        if(currentSplashModule != null && !_excludedModuleTypes.contains(currentSplashModule.moduleType)) {
          matchIndex = visibleModules.indexWhere((ModuleModel m) => m.id == currentSplashModule.id);
        }
      }
      _selectedVisibleIndex = matchIndex >= 0 ? matchIndex : 0;
      initialModule = visibleModules[_selectedVisibleIndex];
    }

    // getAllCarts is module-scoped by header. When the auto-selected tab's module
    // differs from the active one (e.g. opened from Home, where the active module
    // is stale), point the header at it so its carts are fetched. setModule sets
    // the header + triggers getAllCarts, without touching the dashboard index.
    if(initialModule?.id != null && splash.module?.id != initialModule!.id) {
      Get.find<CartController>().setAllCartsLoading(notify: false);
      splash.setModule(initialModule, notify: false);
    } else {
      Get.find<CartController>().getAllCarts(notify: false);
    }
  }

  @override
  void dispose() {
    // If a different module's cart was selected here, the active module/header
    // was switched (and the shared banner cleared). Restore the module we
    // entered with and re-fetch its banner so the dashboard isn't left showing
    // a banner shimmer for the wrong/cleared module.
    final SplashController splash = Get.find<SplashController>();
    if(splash.module?.id != _entryModule?.id) {
      splash.setModule(_entryModule, notify: false);
      if(_entryModule != null) {
        Get.find<BannerController>().getBannerList(true);
      }
    }
    super.dispose();
  }

  ModuleModel? _moduleAtSplashIndex(SplashController splash, int splashIndex) {
    if(splashIndex <= 0) return null;
    final int moduleIndex = splashIndex - 1;
    if(splash.moduleList == null || moduleIndex >= splash.moduleList!.length) return null;
    return splash.moduleList![moduleIndex];
  }

  void _onModuleSelected(int visibleIndex, ModuleModel module) {
    final SplashController splash = Get.find<SplashController>();
    final bool isSwitching = splash.module?.id != module.id;
    if (isSwitching) {
      Get.find<CartController>().setAllCartsLoading();
    }
    setState(() => _selectedVisibleIndex = visibleIndex);
    if (isSwitching) {
      // getAllCarts is module-scoped by header, so we must point the active
      // module at the picked tab to re-fetch its carts. setModule does that (and
      // triggers getAllCarts) WITHOUT changing the dashboard's selected module
      // index — so returning to the main screen keeps its own selection.
      splash.setModule(module, notify: false);
    }
  }

  ModuleModel? _selectedModule() {
    final List<ModuleModel> visibleModules = _visibleModulesFrom(Get.find<SplashController>());
    if(visibleModules.isEmpty) return null;
    final int safeIndex = _selectedVisibleIndex >= visibleModules.length ? 0 : _selectedVisibleIndex;
    return visibleModules[safeIndex];
  }

  @override
  Widget build(BuildContext context) {
    final Color tinted = Color.alphaBlend(
      Theme.of(context).disabledColor.withAlpha(30),
      Theme.of(context).cardColor,
    );

    return Scaffold(
      backgroundColor: tinted,
      appBar: CustomAppBar(title: 'all_carts'.tr, backButton: !widget.fromNav),
      body: SafeArea(
        bottom: false,
        child: Column(children: <Widget>[
          Material(
            color: Theme.of(context).cardColor,
            child: _CartModuleTabs(
              selectedVisibleIndex: _selectedVisibleIndex,
              onModuleSelected: _onModuleSelected,
            ),
          ),

          Expanded(
            child: GetBuilder<CartController>(builder: (cartController) {
              if(cartController.isAllCartsLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final ModuleModel? module = _selectedModule();
              final List<AllCartsModel> groups = cartController.getCartsForModule(module?.id);

              if(groups.isEmpty) {
                return const NoDataScreen(isCart: true, text: '', showFooter: false);
              }

              return RefreshIndicator(
                onRefresh: () => cartController.getAllCarts(),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeDefault,
                    vertical: Dimensions.paddingSizeDefault,
                  ),
                  itemCount: groups.length,
                  itemBuilder: (BuildContext context, int index) {
                    final AllCartsModel group = groups[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                      child: _StoreCartCard(
                        group: group,
                        onDelete: () => _confirmDelete(cartController, group),
                        onViewCart: () => _openStoreThenCart(group),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ]),
      ),
    );
  }

  void _openStoreThenCart(AllCartsModel group) {
    final int? storeId = group.store?.id;
    if(storeId == null) return;
    final String slug = group.store?.slug ?? '';

    // Point the active module at the selected cart's module so the store details
    // and cart resolve under the correct module header.
    final ModuleModel? module = _selectedModule();
    final SplashController splash = Get.find<SplashController>();
    if(module?.id != null && splash.module?.id != module!.id) {
      splash.setModule(module, notify: false);
    }

    Get.toNamed(
      RouteHelper.getStoreRoute(id: storeId, page: 'store', slug: slug),
      arguments: StoreScreen(store: Store(id: storeId), fromModule: false, slug: slug, fromGlobalCart: true,),
    );
  }

  void _confirmDelete(CartController controller, AllCartsModel group) {
    final int? storeId = group.store?.id;
    if(storeId == null) return;
    Get.dialog(ConfirmationDialog(
      icon: Images.warning,
      description: 'do_you_want_to_clear_cart'.tr,
      onYesPressed: () {
        Get.back();
        controller.removeStoreCart(storeId);
      },
    ));
  }
}

class _CartModuleTabs extends StatelessWidget {
  final int selectedVisibleIndex;
  final void Function(int visibleIndex, ModuleModel module) onModuleSelected;

  const _CartModuleTabs({required this.selectedVisibleIndex, required this.onModuleSelected});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashController>(builder: (splashController) {
      final List<ModuleModel> visibleModules = _visibleModulesFrom(splashController);
      // Hide the strip when there's nothing to switch between (single module active).
      if(visibleModules.length <= 1) return const SizedBox.shrink();

      final int safeSelected = selectedVisibleIndex >= visibleModules.length ? 0 : selectedVisibleIndex;

      return DefaultTabController(
        key: ValueKey('cart-module-tab-$safeSelected-${visibleModules.length}'),
        length: visibleModules.length,
        initialIndex: safeSelected,
        child: Center(
          child: SizedBox(
            height: 35,
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
              labelPadding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              indicator: BoxDecoration(
                color: Theme.of(context).disabledColor.withAlpha(30),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusDefault)),
              ),
              labelStyle: robotoBold.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).textTheme.bodyLarge!.color,
              ),
              unselectedLabelStyle: robotoBold.copyWith(
                fontSize: Dimensions.fontSizeDefault,
              ),
              labelColor: Theme.of(context).textTheme.bodyLarge?.color,
              unselectedLabelColor: Theme.of(context).disabledColor,
              onTap: (index) => onModuleSelected(index, visibleModules[index]),
              tabs: visibleModules.map((ModuleModel module) {
                return Tab(text: _moduleLabel(module.moduleName, module.moduleType ?? ''));
              }).toList(),
            ),
          ),
        ),
      );
    });
  }

  String _moduleLabel(String? moduleName, String moduleType) {
    if(moduleName != null && moduleName.trim().isNotEmpty) return moduleName;
    if(moduleType == AppConstants.food) return 'Food';
    if(moduleType == AppConstants.grocery) return 'Grocery';
    if(moduleType == AppConstants.ecommerce) return 'Shop';
    if(moduleType == AppConstants.pharmacy) return 'Pharmacy';
    return moduleType.isNotEmpty ? moduleType : 'Module';
  }
}

class _StoreCartCard extends StatelessWidget {
  final AllCartsModel group;
  final VoidCallback onDelete;
  final VoidCallback onViewCart;

  const _StoreCartCard({required this.group, required this.onDelete, required this.onViewCart});

  @override
  Widget build(BuildContext context) {
    final AllCartsStore? store = group.store;
    final List<CartModel> carts = Get.find<CartController>().localCartsOfGroup(group);
    final double subtotal = Get.find<CartController>().calculateGCartSubTotal(carts);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        boxShadow: <BoxShadow>[BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
            child: CustomImage(
              image: store?.logoFullUrl ?? '',
              height: 38, width: 38, fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: <Widget>[
              InkWell(
                onTap: () => Get.to(() => StoreScreen(store: Store(id: store?.id), fromModule: false, slug: store?.slug ?? store?.name ?? '')),
                child: Text(
                  store?.name ?? '',
                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Image.asset(Images.biking, width: 14, height: 14),
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                  Text(
                    '${store?.deliveryTime} (${store?.distanceKm} km)',
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                ],
              ),
            ]),
          ),
          _StoreCartMenu(onAddMore: () =>  Get.to(() => StoreScreen(store: Store(id: store!.id), fromModule: false, slug: store.slug?? store.name ?? '')), onDelete: onDelete),
        ]),

        const SizedBox(height: Dimensions.paddingSizeDefault),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeSmall,
            vertical: Dimensions.paddingSizeSmall,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
          child: Row(children: <Widget>[
            Expanded(child: _CartItemThumbStrip(carts: carts)),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Text(
              PriceConverter.convertPrice(subtotal),
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
            ),
          ]),
        ),

        const SizedBox(height: Dimensions.paddingSizeSmall),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
            Expanded(
              child: InkWell(
                onTap: () {
                  Get.to(() => StoreScreen(store: Store(id: store!.id), fromModule: false, slug: store.slug??''));
                },
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                  child: Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
                    Icon(Icons.add_circle_outline, size: 18, color: Theme.of(context).textTheme.bodyLarge?.color),
                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                    Flexible(
                      child: Text(
                        'add_more_items'.tr,
                        style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: ElevatedButton(
                onPressed: onViewCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
                ),
                child: Text(
                  'view_cart'.tr,
                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Colors.white),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _CartItemThumbStrip extends StatelessWidget {
  final List<CartModel> carts;
  const _CartItemThumbStrip({required this.carts});

  static const int _maxVisible = 3;
  static const double _thumbSize = 36;
  static const double _overlap = 22;

  @override
  Widget build(BuildContext context) {
    if(carts.isEmpty) return const SizedBox.shrink();
    final int visible = carts.length > _maxVisible ? _maxVisible : carts.length;
    final int extra = carts.length - visible;
    final double stripWidth = _thumbSize + (visible - 1) * _overlap + (extra > 0 ? _overlap : 0);

    return SizedBox(
      height: _thumbSize,
      child: Stack(children: <Widget>[
        for(int i = 0; i < visible; i++)
          Positioned(
            left: i * _overlap,
            child: _RoundThumb(imageUrl: carts[i].item?.imageFullUrl ?? ''),
          ),
        if(extra > 0)
          Positioned(
            left: visible * _overlap + Dimensions.paddingSizeExtraSmall,
            child: Container(
              height: _thumbSize, width: _thumbSize,
              alignment: Alignment.center,
              child: Text(
                '+$extra',
                style: robotoBold.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
          ),
        SizedBox(width: stripWidth),
      ]),
    );
  }
}

class _RoundThumb extends StatelessWidget {
  final String imageUrl;
  const _RoundThumb({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36, width: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).cardColor, width: 2),
      ),
      child: ClipOval(
        child: CustomImage(image: imageUrl, height: 36, width: 36, fit: BoxFit.cover),
      ),
    );
  }
}

class _StoreCartMenu extends StatelessWidget {
  final VoidCallback onAddMore;
  final VoidCallback onDelete;
  const _StoreCartMenu({required this.onAddMore, required this.onDelete});

  static const String _kAddMore = 'add_more';
  static const String _kDelete = 'delete';

  void _showMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: _kAddMore,
          child: Row(children: <Widget>[
            Icon(Icons.add_circle_outline, size: 18, color: Theme.of(context).textTheme.bodyLarge?.color),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Text('add_more_items'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault)),
          ]),
        ),
        PopupMenuItem<String>(
          value: _kDelete,
          child: Row(children: <Widget>[
            Image.asset(Images.delete, height: 18, width: 18),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Text(
              'delete_cart'.tr,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ]),
        ),
      ],
    ).then((String? value) {
      if(value == _kAddMore) {
        onAddMore();
      } else if(value == _kDelete) {
        onDelete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showMenu(context),
      child: Icon(Icons.more_vert, color: Theme.of(context).textTheme.bodyLarge!.color?.withAlpha(180)),
    );
  }
}
