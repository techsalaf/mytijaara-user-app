import 'package:get/get_connect/http/src/response/response.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/location/domain/models/zone_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/features/location/domain/repositories/location_repository_interface.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';

class LocationRepository implements LocationRepositoryInterface {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;

  LocationRepository({required this.apiClient, required this.sharedPreferences});

  @override
  Future<String> getAddressFromGeocode(LatLng latLng) async {
    Response response = await apiClient.getData('${AppConstants.geocodeUri}?lat=${latLng.latitude}&lng=${latLng.longitude}', handleError: false);
    String address = 'Unknown Location Found';
    if(response.statusCode == 200 && response.body['status'] == 'OK') {
      address = response.body['results'][0]['formatted_address'].toString();
    }else {
      showCustomSnackBar(response.body['error_message'] ?? response.bodyString);
    }
    return address;
  }

  @override
  Future<ZoneResponseModel> getZone(String? lat, String? lng, {bool handleError = false}) async {
    // GEMINI-MYTJ start: preserve encoded coordinates and all successful API responses.
    final Uri zoneUri = Uri.parse(AppConstants.zoneUri).replace(queryParameters: {
      'lat': lat ?? '',
      'lng': lng ?? '',
    });
    Response response = await apiClient.getData(zoneUri.toString(), handleError: handleError);
    if(ApiClient.isSuccessCode(response.statusCode) && response.body is Map<String, dynamic>) {
      try {
        final ZoneModel zone = ZoneModel.fromJson(response.body as Map<String, dynamic>);
        return ZoneResponseModel(true, '', zone.zoneIds ?? [], zone.zoneData ?? [], [], response.statusCode, null);
      } catch(error) {
        return ZoneResponseModel(false, 'Invalid zone response: $error', [], [], [], response.statusCode, null);
      }
    }
    return ZoneResponseModel(false, response.statusText, [], [], [], response.statusCode, null);
    // GEMINI-MYTJ end
  }

  @override
  Future<Response> searchLocation(String text) async {
    return await apiClient.getData('${AppConstants.searchLocationUri}?search_text=$text');
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
  Future<Response> get(String? id) async {
    Response response = await apiClient.getData('${AppConstants.placeDetailsUri}?placeid=$id');
    return response;
  }

  @override
  Future getList({int? offset}) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }
  @override
  String? getUserAddress() {
    return sharedPreferences.getString(AppConstants.userAddress);
  }

  @override
  String? getRecentDeliveryAddresses() {
    return sharedPreferences.getString(AppConstants.recentDeliveryAddresses);
  }

  @override
  Future<void> saveRecentDeliveryAddresses(String addresses) async {
    await sharedPreferences.setString(AppConstants.recentDeliveryAddresses, addresses);
  }

}
