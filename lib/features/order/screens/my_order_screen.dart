import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_loader.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/custom_text_field.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/rental_module/common/models/trip_details_model.dart';
import 'package:sixam_mart/features/rental_module/rental_order/controllers/taxi_order_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_order/screens/taxi_order_details_screen.dart';
import 'package:sixam_mart/features/ride_share_module/ride_location/domain/models/ride_details_model.dart';
import 'package:sixam_mart/features/ride_share_module/ride_order/controllers/ride_controller.dart';
import 'package:sixam_mart/features/ride_share_module/ride_order/screens/ride_order_complete_screen.dart';
import 'package:sixam_mart/features/ride_share_module/ride_payment/screens/ride_payment_screen.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/custom_validator.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/helper/string_extension.dart';
import 'package:sixam_mart/helper/validate_check.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

enum _OrderFilter { all, running, history }

enum _ModuleKind { regular, taxi, ride }

List<ModuleModel> _visibleModulesFrom(SplashController splash) {
  return splash.moduleList ?? <ModuleModel>[];
}

_ModuleKind _kindOf(ModuleModel? module) {
  switch (module?.moduleType) {
    case AppConstants.taxi: return _ModuleKind.taxi;
    case AppConstants.ride: return _ModuleKind.ride;
    default:                return _ModuleKind.regular;
  }
}

// Shared end-action pane with a single delete action — mirrors the cart's
// Slidable styling. [onDelete] runs the confirm dialog + API and removes the row.
ActionPane _deleteActionPane(BuildContext context, Future<void> Function() onDelete) {
  return ActionPane(
    motion: const ScrollMotion(),
    extentRatio: 0.2,
    children: [
      SlidableAction(
        onPressed: (_) => onDelete(),
        backgroundColor: Theme.of(context).colorScheme.error.withValues(alpha: 0.2),
        borderRadius: BorderRadius.zero,
        foregroundColor: Theme.of(context).colorScheme.error,
        icon: CupertinoIcons.delete,
      ),
    ],
  );
}

class MyOrderScreen extends StatefulWidget {
  final Function()? onBackPressed;
  const MyOrderScreen({super.key, this.onBackPressed});

  @override
  State<MyOrderScreen> createState() => _MyOrderScreenState();
}

class _MyOrderScreenState extends State<MyOrderScreen> {
  static const int _pageLimit = 10;

  _OrderFilter _selectedFilter = _OrderFilter.all;
  int _selectedVisibleIndex = 0;
  bool _isLoggedIn = AuthHelper.isLoggedIn();

  final ScrollController _scrollController = ScrollController();
  final Map<String, List<int>> _loadedPagesByKey = <String, List<int>>{};
  bool _isPaginating = false;
  bool _isLoadingFirstPage = false;

  @override
  void initState() {
    super.initState();
    if(!_isLoggedIn) return;

    _scrollController.addListener(_onScroll);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final SplashController splash = Get.find<SplashController>();
    final List<ModuleModel> visibleModules = _visibleModulesFrom(splash);

    if(visibleModules.isNotEmpty) {
      final ModuleModel? currentSplashModule = _moduleAtSplashIndex(splash, splash.selectedModuleIndex);
      int matchIndex = -1;
      if(currentSplashModule != null) {
        matchIndex = visibleModules.indexWhere((ModuleModel m) => m.id == currentSplashModule.id);
      }
      _selectedVisibleIndex = matchIndex >= 0 ? matchIndex : 0;

      if(matchIndex < 0) {
        // Opened from Home (no matching active module): default to the 1st module
        // and point the header at it so order details resolve correctly — but do
        // NOT change the dashboard's selected module index.
        await splash.setModule(visibleModules[_selectedVisibleIndex], notify: false);
      }
    }

    _coerceFilterForActiveKind();
    if(mounted) _loadFirstPageForActiveKind(_selectedFilter);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  OrderListType _apiTypeOf(_OrderFilter filter) => switch(filter) {
    _OrderFilter.all => OrderListType.all,
    _OrderFilter.running => OrderListType.running,
    _OrderFilter.history => OrderListType.previous,
  };

  ModuleModel? _moduleAtSplashIndex(SplashController splash, int splashIndex) {
    if(splashIndex <= 0) return null;
    final int moduleIndex = splashIndex - 1;
    if(splash.moduleList == null || moduleIndex >= splash.moduleList!.length) return null;
    return splash.moduleList![moduleIndex];
  }

  ModuleModel? get _activeModule {
    final List<ModuleModel> visible = _visibleModulesFrom(Get.find<SplashController>());
    if(visible.isEmpty || _selectedVisibleIndex >= visible.length) return null;
    return visible[_selectedVisibleIndex];
  }

  int? get _activeModuleId => _activeModule?.id;

  _ModuleKind get _activeKind => _kindOf(_activeModule);

  String get _pageKey => '${_activeKind.name}-${_activeKind == _ModuleKind.regular ? (_activeModuleId ?? 0) : 0}-${_selectedFilter.name}';

  // Taxi & ride APIs don't have an "all" type. If the user lands on a kind
  // that doesn't support All, snap to Running.
  void _coerceFilterForActiveKind() {
    if(_activeKind != _ModuleKind.regular && _selectedFilter == _OrderFilter.all) {
      _selectedFilter = _OrderFilter.running;
    }
  }

  Future<void> _loadFirstPageForActiveKind(_OrderFilter filter, {bool clearVisible = false}) async {
    _loadedPagesByKey[_pageKey] = <int>[1];
    _isLoadingFirstPage = true;
    if(mounted) setState(() {});
    try {
      switch(_activeKind) {
        case _ModuleKind.regular:
          await Get.find<OrderController>().getOrders(_apiTypeOf(filter), 1, isUpdate: clearVisible, moduleId: _activeModuleId);
        case _ModuleKind.taxi:
          await Get.find<TaxiOrderController>().getTripList(1, isUpdate: clearVisible, isRunning: filter != _OrderFilter.history);
        case _ModuleKind.ride:
          await Get.find<RideController>().getRideList(1, isUpdate: clearVisible, isRunning: filter != _OrderFilter.history);
      }
    } finally {
      if(mounted) setState(() => _isLoadingFirstPage = false);
    }
  }

  Future<void> _onRefresh() => _loadFirstPageForActiveKind(_selectedFilter);

  void _selectFilter(_OrderFilter filter) {
    if(_selectedFilter == filter) return;
    if(_activeKind != _ModuleKind.regular && filter == _OrderFilter.all) return;
    setState(() => _selectedFilter = filter);
    _loadFirstPageForActiveKind(filter, clearVisible: true);
  }

  Future<void> _onModuleSelected(int visibleIndex, ModuleModel module) async {
    if(visibleIndex == _selectedVisibleIndex) return;

    // Point the header at the picked module so order details resolve to it, but do
    // NOT change the dashboard's selected module index — returning Home stays put.
    // The order list itself is fetched with an explicit moduleId.
    await Get.find<SplashController>().setModule(module, notify: false);

    if(!mounted) return;
    _loadedPagesByKey.clear();
    Get.find<OrderController>().clearAllOrderModels(notify: false);
    setState(() => _selectedVisibleIndex = visibleIndex);
    _coerceFilterForActiveKind();
    _loadFirstPageForActiveKind(_selectedFilter, clearVisible: true);
  }

  // Returns the (totalSize, currentPage) for the active kind + filter,
  // so pagination math works the same way for orders, trips, and rides.
  ({int? totalSize, int currentPage}) _paginationStateForActiveKind() {
    switch(_activeKind) {
      case _ModuleKind.regular:
        final PaginatedOrderModel? model = Get.find<OrderController>().orderModelOf(_apiTypeOf(_selectedFilter));
        return (totalSize: model?.totalSize, currentPage: ((model?.offset ?? 1)).toInt());
      case _ModuleKind.taxi:
        final TaxiOrderController c = Get.find<TaxiOrderController>();
        final bool running = _selectedFilter != _OrderFilter.history;
        final dynamic m = running ? c.tripModel : c.tripHistoryModel;
        return (totalSize: m?.totalSize as int?, currentPage: (m?.offset as int?) ?? 1);
      case _ModuleKind.ride:
        final RideController c = Get.find<RideController>();
        final bool running = _selectedFilter != _OrderFilter.history;
        final dynamic m = running ? c.runningRideList : c.historyRideList;
        return (totalSize: m?.totalSize as int?, currentPage: int.tryParse((m?.offset as String?) ?? '1') ?? 1);
    }
  }

  void _onScroll() {
    if(!_scrollController.hasClients || _isPaginating) return;
    if(_scrollController.position.pixels < _scrollController.position.maxScrollExtent) return;

    final state = _paginationStateForActiveKind();
    if(state.totalSize == null) return;

    final List<int> loaded = _loadedPagesByKey[_pageKey] ??= <int>[1];
    final int currentPage = loaded.isEmpty ? 0 : loaded.reduce((a, b) => a > b ? a : b);
    final int totalPages = (state.totalSize! / _pageLimit).ceil();
    final int nextPage = currentPage + 1;
    if(nextPage > totalPages || loaded.contains(nextPage)) return;

    setState(() {
      _isPaginating = true;
      loaded.add(nextPage);
    });

    Future<void> request;
    switch(_activeKind) {
      case _ModuleKind.regular:
        request = Get.find<OrderController>().getOrders(_apiTypeOf(_selectedFilter), nextPage, isUpdate: true, moduleId: _activeModuleId);
      case _ModuleKind.taxi:
        request = Get.find<TaxiOrderController>().getTripList(nextPage, isUpdate: true, isRunning: _selectedFilter != _OrderFilter.history);
      case _ModuleKind.ride:
        request = Get.find<RideController>().getRideList(nextPage, isUpdate: true, isRunning: _selectedFilter != _OrderFilter.history);
    }
    request.whenComplete(() {
      if(mounted) setState(() => _isPaginating = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    _isLoggedIn = AuthHelper.isLoggedIn();
    final Color tinted = Color.alphaBlend(
      Theme.of(context).disabledColor.withAlpha(30),
      Theme.of(context).cardColor,
    );

    if(!_isLoggedIn) {
      return Scaffold(
        backgroundColor: tinted,
        appBar: CustomAppBar(title: 'my_orders'.tr, onBackPressed: widget.onBackPressed),
        body: const SafeArea(
          bottom: false,
          child: Column(children: [
            Expanded(child: _GuestTrackOrderView()),
          ]),
        ),
      );
    }

    final double bottomNavClearance = 62 + Dimensions.paddingSizeDefault + MediaQuery.of(context).padding.bottom + Dimensions.paddingSizeDefault;

    return Scaffold(
      backgroundColor: tinted,
      appBar: CustomAppBar(title: 'my_orders'.tr, onBackPressed: widget.onBackPressed),
      body: SafeArea(
        bottom: false,
        child: _buildBodyForActiveKind(bottomNavClearance),
      ),
    );
  }

  Widget _buildBodyForActiveKind(double bottomNavClearance) {
    switch(_activeKind) {
      case _ModuleKind.regular:
        return GetBuilder<OrderController>(builder: (orderController) {
          final PaginatedOrderModel? model = orderController.orderModelOf(_apiTypeOf(_selectedFilter));
          final List<OrderModel> orders = _ordersFor(orderController, _selectedFilter);
          final List<_DateGroup<OrderModel>> grouped = _groupByDate<OrderModel>(orders, (o) => o.createdAt);
          return _buildScroll(
            count: model?.totalSize ?? 0,
            isEmpty: grouped.isEmpty,
            emptyText: 'no_order_found'.tr,
            buildSection: (group) => _OrderDateSection(
              group: group,
              onConfirmDelete: _confirmDeleteOrder,
            ),
            groups: grouped,
            bottomClearance: bottomNavClearance,
          );
        });
      case _ModuleKind.taxi:
        return GetBuilder<TaxiOrderController>(builder: (taxiController) {
          final bool running = _selectedFilter != _OrderFilter.history;
          final dynamic model = running ? taxiController.tripModel : taxiController.tripHistoryModel;
          final List<TripDetailsModel> trips = List<TripDetailsModel>.from((model?.trips as List?) ?? const <TripDetailsModel>[]);
          trips.sort((a, b) => _compareDescByCreatedAt(a.createdAt, b.createdAt));
          final List<_DateGroup<TripDetailsModel>> grouped = _groupByDate<TripDetailsModel>(trips, (t) => t.createdAt);
          return _buildScroll(
            count: (model?.totalSize as int?) ?? 0,
            isEmpty: grouped.isEmpty,
            emptyText: 'no_trip_found'.tr,
            buildSection: (group) => _TripDateSection(group: group, onConfirmDelete: _confirmDeleteTrip),
            groups: grouped,
            bottomClearance: bottomNavClearance,
          );
        });
      case _ModuleKind.ride:
        return GetBuilder<RideController>(builder: (rideController) {
          final bool running = _selectedFilter != _OrderFilter.history;
          final dynamic model = running ? rideController.runningRideList : rideController.historyRideList;
          final List<RideDetails> rides = List<RideDetails>.from((model?.data as List?) ?? const <RideDetails>[]);
          rides.sort((a, b) => _compareDescByCreatedAt(a.createdAt, b.createdAt));
          final List<_DateGroup<RideDetails>> grouped = _groupByDate<RideDetails>(rides, (r) => r.createdAt);
          return _buildScroll(
            count: (model?.totalSize as int?) ?? 0,
            isEmpty: grouped.isEmpty,
            emptyText: 'no_ride_found'.tr,
            buildSection: (group) => _RideDateSection(group: group, onConfirmDelete: _confirmDeleteRide),
            groups: grouped,
            bottomClearance: bottomNavClearance,
          );
        });
    }
  }

  Widget _buildScroll<T>({required int count, required bool isEmpty, required String emptyText, required Widget Function(_DateGroup<T> group) buildSection, required List<_DateGroup<T>> groups, required double bottomClearance,}) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [

          SliverToBoxAdapter(
            child: _SolidBar(
              color: Theme.of(context).cardColor,
              child: _OrderModuleTabs(
                selectedVisibleIndex: _selectedVisibleIndex,
                onModuleSelected: _onModuleSelected,
              ),
            ),
          ),

          SliverPersistentHeader(
            pinned: true,
            delegate: _PinnedHeaderDelegate(
              height: 56,
              child: _OrderTypeFilterBar(
                selected: _selectedFilter,
                count: count,
                onSelected: _selectFilter,
                showAllChip: _activeKind == _ModuleKind.regular,
                kind: _activeKind,
              ),
            ),
          ),

          if(_isLoadingFirstPage && isEmpty) const SliverToBoxAdapter(child: _OrderListShimmer())
          else if(isEmpty) SliverFillRemaining(hasScrollBody: false, child: _EmptyOrderView(text: emptyText))
          else SliverList.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) => buildSection(groups[index]),
          ),

          if(_isPaginating) const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
              child: Center(child: SizedBox(
                height: 24, width: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )),
            ),
          ),
        ],
      ),
    );
  }

  int _compareDescByCreatedAt(String? a, String? b) {
    final DateTime? da = _parseCreatedAt(a);
    final DateTime? db = _parseCreatedAt(b);
    if(da == null && db == null) return 0;
    if(da == null) return 1;
    if(db == null) return -1;
    return db.compareTo(da);
  }

  List<OrderModel> _ordersFor(OrderController controller, _OrderFilter filter) {
    final PaginatedOrderModel? model = switch(filter) {
      _OrderFilter.all => controller.allOrderModel,
      _OrderFilter.running => controller.runningOrderModel,
      _OrderFilter.history => controller.historyOrderModel,
    };
    final List<OrderModel> orders = List<OrderModel>.from(model?.orders ?? <OrderModel>[]);
    orders.sort((a, b) => _compareDescByCreatedAt(a.createdAt, b.createdAt));
    return orders;
  }

  List<_DateGroup<T>> _groupByDate<T>(List<T> items, String? Function(T) createdAtOf) {
    final Map<String, List<T>> map = <String, List<T>>{};
    final List<String> orderedKeys = <String>[];
    for(final T item in items) {
      final String key = _dateKey(createdAtOf(item));
      if(!map.containsKey(key)) {
        map[key] = <T>[];
        orderedKeys.add(key);
      }
      map[key]!.add(item);
    }
    return orderedKeys
        .map((key) => _DateGroup<T>(dateLabel: _dateLabelOf(key), items: map[key]!))
        .toList();
  }

  String _dateKey(String? createdAt) {
    final DateTime? date = _parseCreatedAt(createdAt);
    if(date == null) return '';
    return DateConverter.dateToDate(date);
  }

  String _dateLabelOf(String key) {
    if(key.isEmpty) return '';
    try {
      final DateTime date = DateTime.parse(key);
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);
      final DateTime yesterday = today.subtract(const Duration(days: 1));
      final DateTime target = DateTime(date.year, date.month, date.day);
      if(target == today) return 'today'.tr;
      if(target == yesterday) return 'yesterday'.tr;
      return DateConverter.dateToReadableDate(date);
    } catch(_) {
      return key;
    }
  }

  DateTime? _parseCreatedAt(String? value) {
    if(value == null || value.isEmpty) return null;
    try {
      return DateTime.parse(value).toLocal();
    } catch(_) {
      try {
        return DateConverter.dateTimeStringToDate(value);
      } catch(_) {
        return null;
      }
    }
  }

  // confirmDismiss handler: shows confirm dialog, runs dummy delete API with loader,
  // returns true so Dismissible animates out. Local list removal happens in onDismissed.
  Future<bool> _confirmDeleteOrder(OrderModel order) async {
    final bool? confirmed = await Get.dialog<bool>(
      _DeleteOrderConfirmDialog(
        title: order.orderType != "parcel" ? 'delete_order_question'.tr : 'Delete this parcel?'.tr,
        subtitle: order.id != null ? 'Order #${order.id}' : '',
      ),
      barrierDismissible: true,
    );
    if(confirmed != true) return false;

    Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);
    final bool ok = await Get.find<OrderController>().deleteOrder(order.id);
    if(Get.isDialogOpen ?? false) Get.back();

    if(!ok) {
      showCustomSnackBar('failed_to_delete_order'.tr);
      return false;
    }
    return true;
  }

  Future<bool> _confirmDeleteTrip(TripDetailsModel trip) async {
    final bool? confirmed = await Get.dialog<bool>(
      _DeleteOrderConfirmDialog(
        title: 'delete_trip_question'.tr,
        subtitle: trip.id != null ? '${'trip_id'.tr} #${trip.id}' : '',
      ),
      barrierDismissible: true,
    );
    if(confirmed != true) return false;

    Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);
    final bool ok = await Get.find<TaxiOrderController>().deleteTrip(trip.id);
    if(Get.isDialogOpen ?? false) Get.back();

    if(!ok) {
      showCustomSnackBar('failed_to_delete_trip'.tr);
      return false;
    }
    return true;
  }

  Future<bool> _confirmDeleteRide(RideDetails ride) async {
    final bool? confirmed = await Get.dialog<bool>(
      _DeleteOrderConfirmDialog(
        title: 'delete_ride_question'.tr,
        subtitle: ride.refId != null ? '${'ride_id'.tr} #${ride.refId}' : '',
      ),
      barrierDismissible: true,
    );
    if(confirmed != true) return false;

    Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);
    final bool ok = await Get.find<RideController>().deleteRide(ride.id);
    if(Get.isDialogOpen ?? false) Get.back();

    if(!ok) {
      showCustomSnackBar('failed_to_delete_ride'.tr);
      return false;
    }
    return true;
  }
}

class _DateGroup<T> {
  final String dateLabel;
  final List<T> items;
  const _DateGroup({required this.dateLabel, required this.items});
}

// Opaque wrapper that prevents underlying scroll content from showing through.
class _SolidBar extends StatelessWidget {
  final Color color;
  final Widget child;
  const _SolidBar({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(color: color, elevation: 0, child: child);
  }
}

// Screen-local copy of dashboard's ModuleTabs.
// Indicator uses disabledColor tint so the selected pill is visible against
// the white module strip on this screen.
// Module tab strip — excludes taxi and ride-share modules.
class _OrderModuleTabs extends StatelessWidget {
  final int selectedVisibleIndex;
  final void Function(int visibleIndex, ModuleModel module) onModuleSelected;

  const _OrderModuleTabs({required this.selectedVisibleIndex, required this.onModuleSelected});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashController>(builder: (splashController) {
      final List<ModuleModel> visibleModules = _visibleModulesFrom(splashController);
      // Hide the strip when there's nothing to switch between (single module active).
      if(visibleModules.length <= 1) return const SizedBox.shrink();

      final int safeSelected = selectedVisibleIndex >= visibleModules.length ? 0 : selectedVisibleIndex;

      return DefaultTabController(
        key: ValueKey('order-module-tab-$safeSelected-${visibleModules.length}'),
        length: visibleModules.length,
        initialIndex: safeSelected,
        child: Center(
          child: SizedBox(
            height: 34,
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

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _PinnedHeaderDelegate({required this.child, required this.height});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}

class _OrderTypeFilterBar extends StatelessWidget {
  final _OrderFilter selected;
  final int count;
  final ValueChanged<_OrderFilter> onSelected;
  final bool showAllChip;
  final _ModuleKind kind;

  const _OrderTypeFilterBar({
    required this.selected, required this.count, required this.onSelected, required this.showAllChip, required this.kind,
  });

  @override
  Widget build(BuildContext context) {
    final Color divider = Theme.of(context).disabledColor.withAlpha(60);
    final Color tinted = Color.alphaBlend(
      Theme.of(context).disabledColor.withAlpha(30),
      Theme.of(context).cardColor,
    );
    final List<(_OrderFilter, String)> tabs = <(_OrderFilter, String)>[
      if(showAllChip) (_OrderFilter.all, 'all'.tr),
      (_OrderFilter.running, 'running'.tr),
      (_OrderFilter.history, 'history'.tr),
    ];

    return _SolidBar(
      color: tinted,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                _ResultCountBar(count: count, kind: kind),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeDefault,
                    vertical: Dimensions.paddingSizeSmall,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List<Widget>.generate(tabs.length, (index) {
                      final (_OrderFilter filter, String label) = tabs[index];
                      return Padding(
                        padding: EdgeInsets.only(left: index == 0 ? 0 : Dimensions.paddingSizeSmall),
                        child: _FilterChipItem(
                          label: label,
                          isSelected: filter == selected,
                          onTap: () => onSelected(filter),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: divider),
        ],
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    final Color textColor = isSelected
        ? Colors.white
        : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeSmall,
        ),
        decoration: BoxDecoration(
          color: isSelected ? primary : Theme.of(context).disabledColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          label,
          style: robotoSemiBold.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class _ResultCountBar extends StatelessWidget {
  final int count;
  final _ModuleKind kind;
  const _ResultCountBar({required this.count, required this.kind});

  @override
  Widget build(BuildContext context) {
    final String unit = switch(kind) {
      _ModuleKind.taxi => 'trips'.tr,
      _ModuleKind.ride => 'rides'.tr,
      _ModuleKind.regular => 'orders'.tr,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeSmall,
      ),
      child: Text(
        '$count $unit',
        style: robotoBold.copyWith(
          fontSize: Dimensions.fontSizeSmall,
          color: Theme.of(context).disabledColor,
        ),
      ),
    );
  }
}

class _OrderDateSection extends StatelessWidget {
  final _DateGroup<OrderModel> group;
  final Future<bool> Function(OrderModel) onConfirmDelete;

  const _OrderDateSection({
    required this.group,
    required this.onConfirmDelete,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> cards = <Widget>[];
    for(int i = 0; i < group.items.length; i++) {
      final OrderModel order = group.items[i];
      cards.add(order.orderType == 'parcel'
          ? _ParcelOrderItemCard(
              orderModel: order,
              onConfirmDelete: () => onConfirmDelete(order),
            )
          : _OrderItemCard(
              orderModel: order,
              onConfirmDelete: () => onConfirmDelete(order),
            ));
      if(i < group.items.length - 1) cards.add(const _OrderCardDivider());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OrderDateBand(label: group.dateLabel),
        ...cards,
      ],
    );
  }
}

class _TripDateSection extends StatelessWidget {
  final _DateGroup<TripDetailsModel> group;
  final Future<bool> Function(TripDetailsModel) onConfirmDelete;
  const _TripDateSection({required this.group, required this.onConfirmDelete});

  @override
  Widget build(BuildContext context) {
    final List<Widget> cards = <Widget>[];
    for(int i = 0; i < group.items.length; i++) {
      final TripDetailsModel trip = group.items[i];
      cards.add(_TripItemCard(
        trip: trip,
        onConfirmDelete: () => onConfirmDelete(trip),
      ));
      if(i < group.items.length - 1) cards.add(const _OrderCardDivider());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OrderDateBand(label: group.dateLabel),
        ...cards,
      ],
    );
  }
}

class _RideDateSection extends StatelessWidget {
  final _DateGroup<RideDetails> group;
  final Future<bool> Function(RideDetails) onConfirmDelete;
  const _RideDateSection({required this.group, required this.onConfirmDelete});

  @override
  Widget build(BuildContext context) {
    final List<Widget> cards = <Widget>[];
    for(int i = 0; i < group.items.length; i++) {
      final RideDetails ride = group.items[i];
      cards.add(_RideItemCard(
        ride: ride,
        onConfirmDelete: () => onConfirmDelete(ride),
      ));
      if(i < group.items.length - 1) cards.add(const _OrderCardDivider());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OrderDateBand(label: group.dateLabel),
        ...cards,
      ],
    );
  }
}

class _OrderCardDivider extends StatelessWidget {
  const _OrderCardDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: Container( height: 1, color: Theme.of(context).disabledColor.withAlpha(40),),
    );
  }
}

class _OrderDateBand extends StatelessWidget {
  final String label;
  const _OrderDateBand({required this.label});

  @override
  Widget build(BuildContext context) {
    final Color line = Theme.of(context).cardColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: line)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: Text(label, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall),),
          ),
          Expanded(child: Container(height: 1, color: line)),
        ],
      ),
    );
  }
}

class _OrderItemCard extends StatelessWidget {
  final OrderModel orderModel;
  final Future<bool> Function() onConfirmDelete;

  const _OrderItemCard({required this.orderModel, required this.onConfirmDelete,});

  @override
  Widget build(BuildContext context) {

    // Only delivered and canceled orders can be deleted.
    final String status = (orderModel.orderStatus ?? '').toLowerCase();
    final bool canDelete = status == 'delivered' || status == 'canceled';

    return Slidable(
      key: ValueKey<int?>(orderModel.id),
      endActionPane: canDelete ? _deleteActionPane(context, () async {
        final bool ok = await onConfirmDelete();
        if(ok) Get.find<OrderController>().removeOrderFromList(orderModel.id);
      }) : null,
      child: ClipRRect(
        borderRadius: canDelete ? BorderRadius.circular(Dimensions.radiusExtraLarge) : BorderRadius.zero,
        child: InkWell(
          onTap: () => Get.toNamed(RouteHelper.getOrderDetailsRoute(orderModel.id)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeDefault),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OrderCardHeader(orderModel: orderModel, amount: orderModel.orderAmount,),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Row(
                  children: [
                    ImagePreviewWidget(image: ((orderModel.itemsPreview != null && orderModel.itemsPreview!.isNotEmpty) ? orderModel.itemsPreview : null)?.first.imageFullUrl ?? '', extraCount: (orderModel.itemCount)! - 1),
                    const SizedBox(width: Dimensions.paddingSizeSmall),

                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orderModel.parcelCategory != null
                              ? orderModel.parcelCategory?.name??''
                              : (orderModel.itemNames != null && orderModel.itemNames!.isNotEmpty)
                              ? orderModel.itemNames!.join(', ')
                              : '${orderModel.detailsCount ?? 0} ${'items'.tr}',
                          style: orderModel.parcelCategory != null ? robotoSemiBold.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                          ) : robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).disabledColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if(orderModel.parcelCategory != null) Text(
                          DateConverter.dateTimeStringToTime(orderModel.createdAt!),
                          style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeExtraSmall,
                            color: Theme.of(context).disabledColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    )),
                    _OrderActionButton(orderModel: orderModel),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCardHeader extends StatelessWidget {
  final double? amount;
  final OrderModel orderModel;
  const _OrderCardHeader({required this.orderModel, this.amount});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if(orderModel.store != null)
          Text(
            orderModel.store?.name ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
          ),
        Row(
          children: [
            Text(
              '${'order'.tr} #${orderModel.id ?? ''}',
              style: orderModel.parcelCategory != null ? robotoSemiBold.copyWith(
                fontSize: Dimensions.fontSizeSmall
              ) : robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeExtraSmall,
                color: Theme.of(context).disabledColor,
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeDefault),
            StatusCard(orderStatus: (orderModel.orderStatus ?? '').tr),
            const Spacer(),
            Text(
              PriceConverter.convertPrice(amount ?? -1),
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
            ),
          ],
        ),
      ],
    );
  }
}

class _OrderActionButton extends StatelessWidget {
  final OrderModel orderModel;
  const _OrderActionButton({required this.orderModel});

  static const Set<String> _trackable = <String>{
    'confirmed', 'accepted', 'processing', 'handover',
    'picked_up', 'out_for_delivery',
  };

  @override
  Widget build(BuildContext context) {
    final String status = (orderModel.orderStatus ?? '').toLowerCase();
    final bool reorderEnabled = Get.find<SplashController>().configModel?.repeatOrderOption == 1;
    final (String label, VoidCallback onTap) = (status == 'delivered' && reorderEnabled)
        ? ('reorder'.tr, () => Get.find<OrderController>().reorder(orderModel))
        : _trackable.contains(status)
        ? ('track_order'.tr, () => Get.toNamed(RouteHelper.getOrderTrackingRoute(orderModel.id, orderModel.deliveryAddress?.contactPersonNumber)))
        : ('details'.tr, () => Get.toNamed(RouteHelper.getOrderDetailsRoute(orderModel.id)));

    return CustomButton(
      height: 32,
      width: 90,
      color: Theme.of(context).primaryColor,
      buttonText: label,
      onPressed: onTap,
      fontSize: Dimensions.fontSizeSmall,
    );
  }
}

class _ParcelOrderItemCard extends StatelessWidget {
  final OrderModel orderModel;
  final Future<bool> Function() onConfirmDelete;

  const _ParcelOrderItemCard({required this.orderModel, required this.onConfirmDelete});

  @override
  Widget build(BuildContext context) {
    // Only delivered and canceled orders can be deleted.
    final String status = (orderModel.orderStatus ?? '').toLowerCase();
    final bool canDelete = status == 'delivered' || status == 'canceled';

    // For a parcel, delivery_address is the sender and receiver_details the receiver.
    final sender = orderModel.deliveryAddress;
    final receiver = orderModel.receiverDetails;

    return Slidable(
      key: ValueKey<int?>(orderModel.id),
      endActionPane: canDelete ? _deleteActionPane(context, () async {
        final bool ok = await onConfirmDelete();
        if(ok) Get.find<OrderController>().removeOrderFromList(orderModel.id);
      }) : null,
      child: ClipRRect(
        borderRadius: canDelete ? BorderRadius.circular(Dimensions.radiusExtraLarge) : BorderRadius.zero,
        child: InkWell(
          onTap: () => Get.toNamed(RouteHelper.getOrderDetailsRoute(orderModel.id)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeDefault),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Header: parcel category + id + status on the left, amount on the right.
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    orderModel.parcelCategory?.name ?? 'parcel'.tr,
                    style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                  Row(children: [
                    Flexible(child: Text(
                      '${'parcel'.tr} #${orderModel.id ?? ''}',
                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    )),
                    const SizedBox(width: Dimensions.paddingSizeSmall),

                    StatusCard(orderStatus: (orderModel.orderStatus ?? '').tr),
                  ]),
                ])),
                const SizedBox(width: Dimensions.paddingSizeSmall),

                Text(
                  PriceConverter.convertPrice(orderModel.orderAmount ?? -1),
                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                ),
              ]),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              // Sender -> receiver addresses on the left, track/details button on the right.
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _ParcelAddressLine(
                    icon: Icons.location_on_outlined,
                    label: sender?.addressType,
                    address: sender?.address ?? '',
                  ),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                  _ParcelAddressLine(
                    icon: Icons.near_me_outlined,
                    label: receiver?.addressType,
                    address: receiver?.address ?? '',
                  ),
                ])),
                const SizedBox(width: Dimensions.paddingSizeSmall),

                _OrderActionButton(orderModel: orderModel),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

// One address row of the parcel card: a leading icon, an optional bold type label
// (e.g. "Office :"), and the address. Label is hidden when the type is empty.
class _ParcelAddressLine extends StatelessWidget {
  final IconData icon;
  final String? label;
  final String address;

  const _ParcelAddressLine({required this.icon, required this.address, this.label});

  @override
  Widget build(BuildContext context) {
    final Color disabled = Theme.of(context).disabledColor;
    final bool hasLabel = label != null && label!.trim().isNotEmpty;

    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Icon(icon, size: 16, color: disabled),
      const SizedBox(width: Dimensions.paddingSizeSmall),

      Expanded(child: RichText(
        maxLines: 1, overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: disabled),
          children: [
            if(hasLabel) TextSpan(
              text: '${label!.tr.toTitleCase()} : ',
              style: robotoBold.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            TextSpan(text: address),
          ],
        ),
      )),
    ]);
  }
}

class _TripItemCard extends StatelessWidget {
  final TripDetailsModel trip;
  final Future<bool> Function() onConfirmDelete;
  const _TripItemCard({required this.trip, required this.onConfirmDelete});

  @override
  Widget build(BuildContext context) {
    final String status = trip.tripStatus ?? '';
    final bool isFailed = status == 'payment_failed';
    final Color statusColor = isFailed ? Colors.redAccent : Theme.of(context).primaryColor;
    final String quantityText = '${trip.quantity ?? 0} ${(trip.quantity ?? 0) > 1 ? 'vehicles'.tr : 'vehicle'.tr}';

    // Only confirmed and canceled trips can be deleted.
    final String statusLower = status.toLowerCase();
    final bool canDelete = statusLower == 'confirmed' || statusLower == 'canceled';

    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: Slidable(
        key: ValueKey<int?>(trip.id),
        endActionPane: canDelete ? _deleteActionPane(context, () async {
          final bool ok = await onConfirmDelete();
          if(ok) Get.find<TaxiOrderController>().removeTripFromList(trip.id);
        }) : null,
        child: GestureDetector(
        onTap: () => Get.to(() => TaxiOrderDetailsScreen(tripId: trip.id!)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeDefault),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(
                  '${'trip_id'.tr}: #${trip.id ?? ''}',
                  style: robotoBlack.copyWith(fontSize: Dimensions.fontSizeSmall),
                ),
                const SizedBox(width: Dimensions.paddingSizeDefault),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeSmall,
                    vertical: Dimensions.paddingSizeExtraSmall,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    color: statusColor.withValues(alpha: 0.1),
                  ),
                  child: Text(
                    status.tr.toTitleCase(),
                    style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall,
                      color: statusColor,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  quantityText,
                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                ),
              ]),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Row(
                children: [
                  Container(
                    height: 30, width: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).cardColor, width: 2),
                    ),
                    child: ClipOval(
                      child: CustomImage(image: trip.provider?.logoFullUrl ?? '', fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Expanded(
                    child: Text(
                      trip.provider?.name ?? '',
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).disabledColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  CustomButton(
                    height: 32,
                    width: 90,
                    color: Theme.of(context).primaryColor,
                    buttonText: 'details'.tr,
                    onPressed: () => Get.to(() => TaxiOrderDetailsScreen(tripId: trip.id!)),
                    fontSize: Dimensions.fontSizeSmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _RideItemCard extends StatelessWidget {
  final RideDetails ride;
  final Future<bool> Function() onConfirmDelete;
  const _RideItemCard({required this.ride, required this.onConfirmDelete});

  @override
  Widget build(BuildContext context) {
    final String status = ride.currentStatus ?? '';
    final bool isCancelled = status == AppConstants.cancelled;
    final Color statusColor = isCancelled ? Colors.redAccent : Theme.of(context).primaryColor;
    final String iconAsset = status == 'pending'
        ? Images.searchImageIcon
        : ride.vehicleCategory?.type == 'car' ? Images.car : Images.bikeTop;

    // Only cancelled and completed rides can be deleted.
    final bool canDelete = status == AppConstants.cancelled || status == AppConstants.completed;

    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: Slidable(
        key: ValueKey<String?>(ride.id),
        endActionPane: canDelete ? _deleteActionPane(context, () async {
          final bool ok = await onConfirmDelete();
          if(ok) Get.find<RideController>().removeRideFromList(ride.id);
        }) : null,
        child: GestureDetector(
        onTap: () => _navigateForRide(ride),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeDefault),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(
                  '${'ride_id'.tr}: #${ride.refId ?? ''}',
                  style: robotoBlack.copyWith(fontSize: Dimensions.fontSizeSmall),
                ),
                const SizedBox(width: Dimensions.paddingSizeDefault),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeSmall,
                    vertical: Dimensions.paddingSizeExtraSmall,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    color: statusColor.withValues(alpha: 0.1),
                  ),
                  child: Text(
                    status.tr.toTitleCase(),
                    style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall,
                      color: statusColor,
                    ),
                  ),
                ),
                const Spacer(),
              ]),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Row(
                children: [
                  Container(
                    height: 36, width: 36, alignment: Alignment.center,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                      child: Image.asset(iconAsset, height: 36, width: 36, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Expanded(
                    child: Text(
                      (ride.vehicleCategory?.type ?? '').tr.toTitleCase(),
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).disabledColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  CustomButton(
                    height: 32,
                    width: 90,
                    color: Theme.of(context).primaryColor,
                    buttonText: 'details'.tr,
                    onPressed: () => _navigateForRide(ride),
                    fontSize: Dimensions.fontSizeSmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Future<void> _navigateForRide(RideDetails ride) async {
    final bool isRunning = ride.currentStatus != AppConstants.completed
        && ride.currentStatus != AppConstants.cancelled;
    if(isRunning) {
      await Get.find<RideController>().getCurrentRideStatus(fromRefresh: true);
      return;
    }
    final bool unpaid = ride.paymentStatus == 'unpaid'
        && (ride.currentStatus == AppConstants.completed || ride.currentStatus == AppConstants.cancelled);
    if(unpaid) {
      if(ride.currentStatus == AppConstants.cancelled && ride.tripStatus?.ongoing == null) {
        Get.to(() => RideOrderCompleteScreen(tripId: ride.id!, fromRideList: true));
      } else {
        Get.find<RideController>().getFinalFare(ride.id!);
        Get.to(() => RidePaymentScreen(rideId: ride.id!));
      }
    } else {
      Get.to(() => RideOrderCompleteScreen(tripId: ride.id!, fromRideList: true));
    }
  }
}

class _DeleteOrderConfirmDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  const _DeleteOrderConfirmDialog({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.delete,
              size: 40,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Text(
              title,
              textAlign: TextAlign.center,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).disabledColor,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Get.back(result: false),
                    style: TextButton.styleFrom(
                      backgroundColor: Theme.of(context).disabledColor.withAlpha(60),
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                      ),
                    ),
                    child: Text(
                      'no'.tr,
                      style: robotoBold.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeDefault),
                Expanded(
                  child: CustomButton(
                    buttonText: 'yes'.tr,
                    onPressed: () => Get.back(result: true),
                    height: 44,
                    radius: Dimensions.radiusSmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Shimmer placeholder shown while the first page is loading (data null/fetching)
// and for pagination — replaces the circular loaders so the list "fills in".
class _OrderListShimmer extends StatelessWidget {
  const _OrderListShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      duration: const Duration(seconds: 2),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
          child: Center(child: _OrderShimmerBlock(width: 90, height: 12)),
        ),
        ...List<Widget>.generate(6, (_) => const _OrderShimmerCard()),
      ]),
    );
  }
}

// Mirrors the layout of [_OrderItemCard] so the shimmer matches the real card.
class _OrderShimmerCard extends StatelessWidget {
  const _OrderShimmerCard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: Padding(
        padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _OrderShimmerBlock(width: 140, height: 14),
          SizedBox(height: Dimensions.paddingSizeSmall),
          Row(children: [
            _OrderShimmerBlock(width: 70, height: 10),
            SizedBox(width: Dimensions.paddingSizeDefault),
            _OrderShimmerBlock(width: 60, height: 18),
            Spacer(),
            _OrderShimmerBlock(width: 50, height: 12),
          ]),
          SizedBox(height: Dimensions.paddingSizeSmall),
          Row(children: [
            _OrderShimmerBlock(width: 30, height: 30, circle: true),
            SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _OrderShimmerBlock(width: 160, height: 10),
              SizedBox(height: 6),
              _OrderShimmerBlock(width: 100, height: 10),
            ])),
            SizedBox(width: Dimensions.paddingSizeSmall),
            _OrderShimmerBlock(width: 120, height: 40),
          ]),
        ]),
      ),
    );
  }
}

class _OrderShimmerBlock extends StatelessWidget {
  final double width;
  final double height;
  final bool circle;
  const _OrderShimmerBlock({required this.width, required this.height, this.circle = false});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color color = isDark ? Colors.white.withValues(alpha: 0.18) : const Color(0xFFE9E9E9);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(8),
      ),
    );
  }
}

class _EmptyOrderView extends StatelessWidget {
  final String text;
  const _EmptyOrderView({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Text(
          text,
          style: robotoMedium.copyWith(
            fontSize: Dimensions.fontSizeDefault,
            color: Theme.of(context).disabledColor,
          ),
        ),
      ),
    );
  }
}

class StatusCard extends StatelessWidget {
  final String orderStatus;
  const StatusCard({super.key, required this.orderStatus});

  @override
  Widget build(BuildContext context) {
    final String lower = orderStatus.toLowerCase();
    final Color color = lower.contains("pending") ? Colors.blueAccent
        : lower.contains("cancel") ? Theme.of(context).colorScheme.error
        : Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeSmall,
        vertical: Dimensions.paddingSizeExtraSmall,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        color: color.withValues(alpha: 0.1),
      ),
      child: Text(
        orderStatus.toTitleCase(),
        style: robotoMedium.copyWith(
          fontSize: Dimensions.fontSizeExtraSmall,
          color: color,
        ),
      ),
    );
  }
}

class ImagePreviewWidget extends StatelessWidget {
  final String? image;
  final int extraCount;
  final double imageSize;

  const ImagePreviewWidget({super.key, required this.image, required this.extraCount, this.imageSize = 30});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: extraCount > 0 ? (imageSize * 2) - 5 : imageSize,
      height: imageSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: imageSize,
            width: imageSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).cardColor, width: 2),
            ),
            child: ClipOval(child: CustomImage(image: image ?? '', fit: BoxFit.cover)),
          ),
          if(extraCount > 0) Positioned(
            left: imageSize - 5,
            child: Container(
              height: imageSize,
              width: imageSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).cardColor,
              ),
              child: Text(
                '+$extraCount', textAlign: TextAlign.center, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestTrackOrderView extends StatefulWidget {
  const _GuestTrackOrderView();

  @override
  State<_GuestTrackOrderView> createState() => _GuestTrackOrderViewState();
}

class _GuestTrackOrderViewState extends State<_GuestTrackOrderView> {
  final TextEditingController _orderIdController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final FocusNode _orderFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  String? _countryDialCode;

  @override
  void initState() {
    super.initState();
    final String userDialCode = Get.find<AuthController>().getUserCountryCode();
    _countryDialCode = userDialCode.isNotEmpty
        ? userDialCode
        : CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).dialCode;
  }

  @override
  void dispose() {
    _orderIdController.dispose();
    _phoneNumberController.dispose();
    _orderFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  Future<void> _onTrackPressed(OrderController controller) async {
    final String phone = _phoneNumberController.text.trim();
    final String orderId = _orderIdController.text.trim();
    final String numberWithCountryCode = (_countryDialCode ?? '') + phone;
    final PhoneValid phoneValid = await CustomValidator.isPhoneValid(numberWithCountryCode);
    final String validatedNumber = phoneValid.phone;

    if(orderId.isEmpty) {
      showCustomSnackBar('please_enter_order_id'.tr);
      return;
    }
    if(phone.isEmpty) {
      showCustomSnackBar('enter_phone_number'.tr);
      return;
    }
    if(!phoneValid.isValid) {
      showCustomSnackBar('invalid_phone_number'.tr);
      return;
    }

    final response = await controller.trackOrder(
      orderId, null, false,
      contactNumber: validatedNumber, fromGuestInput: true,
    );
    if(response != null && response.isSuccess) {
      Get.toNamed(RouteHelper.getGuestTrackOrderScreen(orderId, validatedNumber));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.radiusExtraLarge,
          vertical: Dimensions.paddingSizeLarge,
        ),
        child: Column(children: [
          CustomTextField(
            labelText: 'order_id'.tr,
            titleText: 'write_order_id'.tr,
            controller: _orderIdController,
            focusNode: _orderFocus,
            nextFocus: _phoneFocus,
            inputType: TextInputType.number,
            showTitle: isDesktop,
            required: true,
            validator: (value) => ValidateCheck.validateEmptyText(value, null),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraLarge),

          CustomTextField(
            titleText: 'enter_phone_number'.tr,
            labelText: 'phone'.tr,
            controller: _phoneNumberController,
            focusNode: _phoneFocus,
            inputType: TextInputType.phone,
            inputAction: TextInputAction.done,
            isPhone: true,
            showTitle: isDesktop,
            onCountryChanged: (CountryCode countryCode) => _countryDialCode = countryCode.dialCode,
            countryDialCode: _countryDialCode ?? Get.find<LocalizationController>().locale.countryCode,
            required: true,
            validator: (value) => ValidateCheck.validateEmptyText(value, null),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraLarge),

          GetBuilder<OrderController>(builder: (orderController) {
            return CustomButton(
              buttonText: 'track_order'.tr,
              isLoading: orderController.isLoading,
              width: isDesktop ? 300 : double.infinity,
              onPressed: () => _onTrackPressed(orderController),
            );
          }),
        ]),
      ),
    );
  }
}
