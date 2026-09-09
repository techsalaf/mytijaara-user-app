import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/pro/domain/models/pro_active_offer_model.dart';
import 'package:sixam_mart/features/pro/domain/models/pro_faq_model.dart';
import 'package:sixam_mart/features/pro/domain/models/pro_plan_model.dart';
import 'package:sixam_mart/features/pro/domain/repositories/pro_repository_interface.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:get/get_connect.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProRepository implements ProRepositoryInterface {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  ProRepository({required this.apiClient, required this.sharedPreferences});

  @override
  Future<ProPlanModel?> getProPlans() async {
    ProPlanModel? model;
    Response response = await apiClient.getData(AppConstants.proPlansUri);
    if (response.statusCode == 200) {
      model = ProPlanModel.fromJson(response.body);
    }
    return model;
  }

  @override
  Future<List<ProFaqModel>?> getProFaqs() async {
    List<ProFaqModel>? faqs;
    Response response = await apiClient.getData(AppConstants.proFaqsUri);
    if (response.statusCode == 200 && response.body['faqs'] != null) {
      faqs = [];
      response.body['faqs'].forEach((faq) {
        faqs!.add(ProFaqModel.fromJson(faq));
      });
    }
    return faqs;
  }

  @override
  Future<ProActiveOfferModel?> getProActiveOffer({required String? moduleType}) async {
    ProActiveOfferModel? model;
    Response response = await apiClient.getData(
      moduleType != null && moduleType.isNotEmpty
          ? '${AppConstants.proActiveOfferUri}?module_type=$moduleType'
          : AppConstants.proActiveOfferUri,
    );
    if (response.statusCode == 200) {
      model = ProActiveOfferModel.fromJson(response.body);
    }
    return model;
  }

  @override
  Future<Response> subscribePlan({required int planId, required String paymentType, required String paymentMethod, String? callback, required String paymentPlatform}) async {
    return await apiClient.postData(AppConstants.proCustomerSubscribeUri, {
      'plan_id': planId,
      'payment_type': paymentType,
      'payment_method': paymentMethod,
      'callback': callback,
      'payment_platform': paymentPlatform,
    });
  }

  @override
  Future<Response> cancelSubscription() async {
    return await apiClient.postData(AppConstants.proCancelSubscriptionsUri, {});
  }

  @override
  Future<bool> saveCurrentPath(String route) async {
    return await sharedPreferences.setString(AppConstants.savedRoute, route);
  }

  @override
  String? getSavedRoute() {
    return sharedPreferences.getString(AppConstants.savedRoute);
  }

  @override
  Future<bool> removeSavedRoute() async {
    return await sharedPreferences.remove(AppConstants.savedRoute);
  }

  @override
  bool getRenewBottomSheetShown() {
    return sharedPreferences.getBool(AppConstants.renewBottomSheetShown) ?? false;
  }

  @override
  Future<bool> saveRenewBottomSheetShown(bool shown) async {
    return await sharedPreferences.setBool(AppConstants.renewBottomSheetShown, shown);
  }

  @override
  Future add(value) { throw UnimplementedError(); }
  @override
  Future delete(int? id) { throw UnimplementedError(); }
  @override
  Future get(String? id) { throw UnimplementedError(); }
  @override
  Future getList({int? offset}) { throw UnimplementedError(); }
  @override
  Future update(Map<String, dynamic> body, int? id) { throw UnimplementedError(); }
}
