import 'package:get/get_connect.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/bogo_offer/domain/models/bogo_offer_model.dart';
import 'package:sixam_mart/features/bogo_offer/domain/repositories/bogo_offer_repository_interface.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';

class BogoOfferRepository implements BogoOfferRepositoryInterface {
  final ApiClient apiClient;
  BogoOfferRepository({required this.apiClient});

  /// Every bogo endpoint runs behind the guest check: a request carrying neither a token
  /// nor a guest id is refused, which is how offers went missing in guest mode.
  String get _guestQuery {
    final String guestId = AuthHelper.isLoggedIn() ? '' : AuthHelper.getGuestId();
    return guestId.isNotEmpty ? '&guest_id=$guestId' : '';
  }

  /// The BOGO screen lists every module that has a live offer, so it has to ask each
  /// one in turn rather than only the module the app is currently in. Copying the main
  /// headers and swapping `moduleId` queries another module without switching to it.
  ///
  /// Such a call can never be [moduleScoped]: that guard drops any response whose
  /// module id differs from the active one, which is exactly what these are.
  Map<String, String>? _headersForModule(int? moduleId) {
    if(moduleId == null) {
      return null;
    }
    final Map<String, String> headers = Map<String, String>.from(apiClient.getHeader());
    headers[AppConstants.moduleId] = '$moduleId';
    return headers;
  }

  @override
  Future<BogoHomeModel?> getBogoHomeData({int limit = 6, String? orderType, int? moduleId}) async {
    Response response = await apiClient.getData(
      '${AppConstants.bogoHomeUri}?limit=$limit${(orderType != null && orderType.isNotEmpty) ? '&order_type=$orderType' : ''}$_guestQuery',
      handleError: false,
      headers: _headersForModule(moduleId),
      // The card sits on every module home and the controller is a singleton, so a
      // response that lands after the user switched modules must be dropped. Only for
      // the active module — an explicit moduleId is deliberately a different one.
      moduleScoped: moduleId == null,
    );
    if(response.statusCode == 200) {
      return BogoHomeModel.fromJson(response.body);
    }
    return null;
  }

  @override
  Future<BogoOfferListModel?> getBogoOfferList({int offset = 1, int limit = 10, int? moduleId}) async {
    Response response = await apiClient.getData(
      '${AppConstants.bogoOfferListUri}?limit=$limit&offset=$offset$_guestQuery', handleError: false,
      headers: _headersForModule(moduleId),
    );
    if(response.statusCode == 200) {
      return BogoOfferListModel.fromJson(response.body);
    }
    return null;
  }

  @override
  Future<BogoOfferDetailsResponseModel?> getBogoOfferDetails({required String idOrSlug, int offset = 1, int limit = 10, int? moduleId}) async {
    Response response = await apiClient.getData(
      '${AppConstants.bogoOfferListUri}/$idOrSlug?limit=$limit&offset=$offset$_guestQuery', handleError: false,
      headers: _headersForModule(moduleId),
    );
    if(response.statusCode == 200) {
      return BogoOfferDetailsResponseModel.fromJson(response.body);
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
  Future getList({int? offset}) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }
}
