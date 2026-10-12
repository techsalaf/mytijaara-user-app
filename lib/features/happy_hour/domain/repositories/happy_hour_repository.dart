import 'package:get/get_connect.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/happy_hour/domain/models/discount_eligibility_model.dart';
import 'package:sixam_mart/features/happy_hour/domain/models/happy_hour_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/happy_hour/domain/repositories/happy_hour_repository_interface.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';

class HappyHourRepository implements HappyHourRepositoryInterface {
  final ApiClient apiClient;
  HappyHourRepository({required this.apiClient});

  /// Both happy hour endpoints run behind the guest check: a request carrying neither
  /// a token nor a guest id is refused, so guests would otherwise never see an offer.
  String get _guestQuery {
    final String guestId = AuthHelper.isLoggedIn() ? '' : AuthHelper.getGuestId();
    return guestId.isNotEmpty ? '&guest_id=$guestId' : '';
  }

  @override
  Future<RunningHappyHourModel?> getRunningHappyHour() async {
    // A Happy Hour belongs to the module it was configured for, and the controller is
    // a singleton shared by every module home — a response landing after the user has
    // switched modules must be dropped rather than left driving the banner.
    final String guest = _guestQuery;
    Response response = await apiClient.getData(
      '${AppConstants.happyHourRunningUri}${guest.isEmpty ? '' : '?${guest.substring(1)}'}',
      handleError: false, moduleScoped: true,
    );
    if(response.statusCode == 200) {
      return RunningHappyHourModel.fromJson(response.body);
    }
    return null;
  }

  @override
  Future<StoreModel?> getList({int? offset, int limit = 10, bool runningOnly = true}) async {
    Response response = await apiClient.getData(
      '${AppConstants.happyHourStoreUri}?limit=$limit&offset=${offset ?? 1}'
      '${runningOnly ? '&running=1' : ''}$_guestQuery',
      handleError: false, moduleScoped: true,
    );
    if(response.statusCode == 200) {
      return StoreModel.fromJson(response.body);
    }
    return null;
  }

  @override
  Future<DiscountEligibilityModel?> getDiscountEligibility(int storeId) async {
    Response response = await apiClient.getData(
      '${AppConstants.cartDiscountEligibilityUri}?store_id=$storeId$_guestQuery',
      handleError: false, moduleScoped: true,
    );
    if(response.statusCode == 200) {
      return DiscountEligibilityModel.fromJson(response.body);
    }
    return null;
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    throw UnimplementedError();
  }

  @override
  Future get(String? id) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }
}
