import 'dart:async';
import 'package:get/get.dart';
import 'package:sixam_mart/features/home/domain/models/cashback_model.dart';
import 'package:sixam_mart/features/home/domain/models/top_offer_model.dart';
import 'package:sixam_mart/features/home/domain/services/home_service_interface.dart';

class HomeController extends GetxController implements GetxService {
  final HomeServiceInterface homeServiceInterface;
  HomeController({required this.homeServiceInterface});

  List<CashBackModel>? _cashBackOfferList;
  List<CashBackModel>? get cashBackOfferList => _cashBackOfferList;

  CashBackModel? _cashBackData;
  CashBackModel? get cashBackData => _cashBackData;

  TopOfferModel? _topOffer;
  TopOfferModel? get topOffer => _topOffer;

  bool _showFavButton = true;
  bool get showFavButton => _showFavButton;

  // Modules whose flash-sale promo banner the user has closed. The banner shows the
  // first time per module and stays hidden for that module afterwards.
  final Set<int> _dismissedFlashPromoModules = <int>{};
  bool isFlashPromoVisible(int? moduleId) => moduleId != null && !_dismissedFlashPromoModules.contains(moduleId);

  void hideFlashPromoBanner(int? moduleId) {
    if(moduleId == null) return;
    if(_dismissedFlashPromoModules.add(moduleId)) {
      update();
    }
  }

  Future<void> getCashBackOfferList() async {
    _cashBackOfferList = null;
    _cashBackOfferList = await homeServiceInterface.getCashBackOfferList();
    update();
  }

  void forcefullyNullCashBackOffers() {
    _cashBackOfferList = null;
    update();
  }

  Future<void> getCashBackData(double amount) async {
    CashBackModel? cashBackModel = await homeServiceInterface.getCashBackData(amount);
    if(cashBackModel != null) {
      _cashBackData = cashBackModel;
    }
    update();
  }

  Future<void> getTopOffer({bool notify = true}) async {
    _topOffer = null;
    if(notify) update();
    _topOffer = await homeServiceInterface.getTopOffer();
    update();
  }
  void changeFavVisibility({required bool value}){
    _showFavButton = value;
    update();
  }

  Future<bool> saveRegistrationSuccessfulSharedPref(bool status) async {
    return await homeServiceInterface.saveRegistrationSuccessful(status);
  }

  Future<bool> saveIsStoreRegistrationSharedPref(bool status) async {
    return await homeServiceInterface.saveIsRestaurantRegistration(status);
  }

  bool getRegistrationSuccessfulSharedPref() {
    return homeServiceInterface.getRegistrationSuccessful();
  }

  bool getIsStoreRegistrationSharedPref() {
    return homeServiceInterface.getIsRestaurantRegistration();
  }

}