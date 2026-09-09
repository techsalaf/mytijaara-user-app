import 'package:sixam_mart/features/pro/domain/models/pro_active_offer_model.dart';
import 'package:sixam_mart/features/pro/domain/models/pro_faq_model.dart';
import 'package:sixam_mart/features/pro/domain/models/pro_plan_model.dart';
import 'package:sixam_mart/features/pro/domain/repositories/pro_repository_interface.dart';
import 'package:sixam_mart/features/pro/domain/services/pro_service_interface.dart';
import 'package:get/get_connect.dart';

class ProService implements ProServiceInterface {
  final ProRepositoryInterface proRepositoryInterface;
  ProService({required this.proRepositoryInterface});

  @override
  Future<ProPlanModel?> getProPlans() async {
    return await proRepositoryInterface.getProPlans();
  }

  @override
  Future<List<ProFaqModel>?> getProFaqs() async {
    return await proRepositoryInterface.getProFaqs();
  }

  @override
  Future<ProActiveOfferModel?> getProActiveOffer({required String? moduleType}) async {
    return await proRepositoryInterface.getProActiveOffer(moduleType: moduleType);
  }

  @override
  Future<Response> subscribePlan({required int planId, required String paymentType, required String paymentMethod, String? callback, required String paymentPlatform}) async {
    return await proRepositoryInterface.subscribePlan(planId: planId, paymentType: paymentType, paymentMethod: paymentMethod, callback: callback, paymentPlatform: paymentPlatform);
  }

  @override
  Future<Response> cancelSubscription() async {
    return await proRepositoryInterface.cancelSubscription();
  }

  @override
  Future<bool> saveCurrentPath(String route) async {
    return await proRepositoryInterface.saveCurrentPath(route);
  }

  @override
  String? getSavedRoute() {
    return proRepositoryInterface.getSavedRoute();
  }

  @override
  Future<bool> removeSavedRoute() async {
    return await proRepositoryInterface.removeSavedRoute();
  }

  @override
  bool getRenewBottomSheetShown() {
    return proRepositoryInterface.getRenewBottomSheetShown();
  }

  @override
  Future<bool> saveRenewBottomSheetShown(bool shown) async {
    return await proRepositoryInterface.saveRenewBottomSheetShown(shown);
  }
}
