import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/happy_hour/domain/models/discount_eligibility_model.dart';
import 'package:sixam_mart/features/happy_hour/domain/models/happy_hour_model.dart';
import 'package:sixam_mart/features/happy_hour/domain/services/happy_hour_service_interface.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/module_helper.dart';

class HappyHourController extends GetxController with WidgetsBindingObserver implements GetxService {
  final HappyHourServiceInterface happyHourServiceInterface;
  HappyHourController({required this.happyHourServiceInterface});

  static const String timerBuilderId = 'happy_hour_timer';
  static const int _storePageSize = 10;

  HappyHourModel? _happyHour;
  HappyHourModel? get happyHour => _happyHour;

  int? _moduleId;

  Timer? _timer;
  DateTime? _fetchedAt;
  int _remainingAtFetch = 0;

  Duration _remaining = Duration.zero;
  Duration get remaining => _remaining;

  int? _dismissedHappyHourId;

  StoreModel? _storeModel;
  StoreModel? get storeModel => _storeModel;

  bool _storeLoading = false;
  bool get storeLoading => _storeLoading;

  bool get hasMoreStores {
    final StoreModel? model = _storeModel;
    return model != null && (model.stores?.length ?? 0) < (model.totalSize ?? 0);
  }

  bool get isActive => _happyHour != null && (_happyHour?.isRunningNow ?? false) && _remaining > Duration.zero;
  bool get isDismissed => _happyHour != null && _dismissedHappyHourId == _happyHour!.id;

  int get storeCount => _happyHour?.storeCount ?? 0;
  double get discountPercentage => _happyHour?.discount ?? 0;
  String get discountLabel => discountPercentage % 1 == 0 ? discountPercentage.toStringAsFixed(0) : '$discountPercentage';

  double? get minOrderAmount => _happyHour?.minOrderAmount;
  bool get hasMinOrderRequirement => (minOrderAmount ?? 0) > 0;

  bool get showHomeBanner => isActive && !isDismissed;

  bool showBannerForModule(int? moduleId) => moduleId != null && moduleId == _moduleId && showHomeBanner;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if(state == AppLifecycleState.resumed) {
      getRunningHappyHour();
    }
  }

  Future<void> getRunningHappyHour() async {
    final int? moduleId = Get.find<SplashController>().module?.id;
    final RunningHappyHourModel? model = await happyHourServiceInterface.getRunningHappyHour();
    if(model == null) {
      return;
    }

    if(!happyHourServiceInterface.isValidHappyHour(model)) {
      _clear();
      update();
      return;
    }

    final HappyHourModel next = model.happyHour!;
    final int remainingSeconds = happyHourServiceInterface.resolveRemainingSeconds(next);
    if(remainingSeconds <= 0) {
      _clear();
      update();
      return;
    }

    if(next.id != _happyHour?.id) {
      _dismissedHappyHourId = null;
      _storeModel = null;
      _eligibility.clear();
      _eligibilityAttempted.clear();
    }
    _happyHour = next;
    _moduleId = moduleId;
    _remainingAtFetch = remainingSeconds;
    _fetchedAt = DateTime.now();
    _startTimer();
    _tick();
    update();
  }

  Future<void> getStoreList(int offset, bool reload, {bool notify = true}) async {
    if(_storeLoading || (offset == 1 && !reload && _storeModel != null)) {
      return;
    }

    _storeLoading = true;
    if(reload) {
      _storeModel = null;
    }
    if(notify) {
      update();
    }

    final StoreModel? model = await happyHourServiceInterface.getStoreList(offset: offset, limit: _storePageSize);
    if(model != null) {
      if(offset == 1) {
        _storeModel = model;
      } else if(_storeModel != null) {
        _storeModel!.totalSize = model.totalSize;
        _storeModel!.offset = model.offset ?? offset;
        _storeModel!.stores ??= [];
        _storeModel!.stores!.addAll(model.stores ?? []);
      }
    }
    _storeLoading = false;
    update();
  }

  Future<void> loadMoreStores() async {
    if(_storeLoading || !hasMoreStores) {
      return;
    }
    await getStoreList((_storeModel?.offset ?? 1) + 1, false);
  }

  bool showStoreBanner(bool? isStoreHappyHourRunning) {
    return isActive && (isStoreHappyHourRunning ?? false);
  }

  final Map<int, DiscountEligibilityModel> _eligibility = <int, DiscountEligibilityModel>{};
  final Set<int> _eligibilityLoading = <int>{};
  final Set<int> _eligibilityStale = <int>{};

  final Set<int> _eligibilityAttempted = <int>{};

  DiscountEligibilityModel? eligibilityFor(int? storeId) => storeId == null ? null : _eligibility[storeId];

  Future<void> getDiscountEligibility(int? storeId) async {
    if(storeId == null) {
      return;
    }
    if(_eligibilityLoading.contains(storeId)) {
      _eligibilityStale.add(storeId);
      return;
    }

    _eligibilityLoading.add(storeId);
    final DiscountEligibilityModel? model = await happyHourServiceInterface.getDiscountEligibility(storeId);
    _eligibilityLoading.remove(storeId);
    _eligibilityAttempted.add(storeId);
    if(model != null) {
      _eligibility[storeId] = model;
    }
    update();

    if(_eligibilityStale.remove(storeId)) {
      await getDiscountEligibility(storeId);
    }
  }

  bool discountPending(int? storeId, bool? isStoreHappyHourRunning) {
    return showStoreBanner(isStoreHappyHourRunning) && storeId != null && !_eligibilityAttempted.contains(storeId);
  }

  bool withholdsDiscount(int? storeId) {
    final DiscountEligibilityModel? eligibility = eligibilityFor(storeId);
    return eligibility != null && eligibility.isHappyHour && !(eligibility.isQualified ?? false);
  }

  double discountAmountFor({required int? storeId, required double fallback}) {
    final DiscountEligibilityModel? eligibility = eligibilityFor(storeId);
    if(eligibility == null || !eligibility.providesDiscountAmount) {
      return fallback;
    }
    final double? amount = eligibility.discountAmount;
    return (amount != null && amount >= 0) ? amount : fallback;
  }

  String? discountSourceMessageFor(int? storeId, {bool hasStoreDiscount = false}) {
    final DiscountEligibilityModel? eligibility = eligibilityFor(storeId);
    if(eligibility != null && eligibility.providesDiscountAmount) {
      return eligibility.isHappyHour ? 'happy_hour_discount_applied'.tr : ModuleHelper.storeDiscountAppliedLabel();
    }
    // The eligibility call only prices a happy hour; a plain store-wide discount comes
    // back unattributed, so the store's own configured rate is what names this line.
    return hasStoreDiscount ? ModuleHelper.storeDiscountAppliedLabel() : null;
  }

  double qualifiedDiscount(int? storeId) {
    final DiscountEligibilityModel? eligibility = eligibilityFor(storeId);
    if(eligibility == null || !eligibility.isHappyHour || !(eligibility.isQualified ?? false)) {
      return 0;
    }
    return eligibility.discountAmount ?? 0;
  }

  double remainingForDiscount(double subtotal) {
    final double? minOrder = minOrderAmount;
    if(minOrder == null || minOrder <= 0) {
      return 0;
    }
    final double remaining = minOrder - subtotal;
    return remaining > 0 ? remaining : 0;
  }

  double progressForDiscount(double subtotal) {
    final double? minOrder = minOrderAmount;
    if(minOrder == null || minOrder <= 0) {
      return 1;
    }
    return (subtotal / minOrder).clamp(0.0, 1.0);
  }

  double _bannerHeight = 0;
  double get bannerHeight => _bannerHeight;

  void reportHeight(double height) {
    if(height != _bannerHeight) {
      _bannerHeight = height;
      update();
    }
  }

  void dismiss() {
    _dismissedHappyHourId = _happyHour?.id;
    update();
  }

  String get formattedRemaining {
    final int minutes = _remaining.inMinutes;
    final int seconds = _remaining.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _clear() {
    _stopTimer();
    _happyHour = null;
    _moduleId = null;
    _storeModel = null;
    _eligibility.clear();
    _eligibilityAttempted.clear();
    _fetchedAt = null;
    _remainingAtFetch = 0;
    _remaining = Duration.zero;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _tick() {
    if(_fetchedAt == null) {
      _remaining = Duration.zero;
      return;
    }
    final int left = _remainingAtFetch - DateTime.now().difference(_fetchedAt!).inSeconds;
    _remaining = left > 0 ? Duration(seconds: left) : Duration.zero;
    if(_remaining == Duration.zero) {
      _stopTimer();
      _onExpired();
    }
    update([timerBuilderId]);
  }

  void _onExpired() {
    getRunningHappyHour();
    final int? storeId = Get.isRegistered<StoreController>() ? Get.find<StoreController>().store?.id : null;
    Get.find<CartController>().getCartDataOnline(storeId: storeId);
    update();
  }

  @override
  void onClose() {
    _stopTimer();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}

// SUMMARY
// Drives the Happy Hour offer: the running offer and its countdown, the stores taking
// part, and the server's per-store discount eligibility — how much the basket still
// needs, whether it qualifies, and what the discount comes to.
