import 'package:get/get_connect/connect.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/api/response_parser.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/address/domain/repositories/address_repository_interface.dart';
import 'package:sixam_mart/util/app_constants.dart';

class AddressRepository implements AddressRepositoryInterface<AddressModel> {
  final ApiClient apiClient;

  AddressRepository({required this.apiClient});

  @override
  Future add(AddressModel addressModel) async {
    return await _addAddress(addressModel);
  }

  Future<ResponseModel> _addAddress(AddressModel addressModel) async {
    Response response = await apiClient.postData(AppConstants.addAddressUri, addressModel.toJson(), handleError: false);
    // This endpoint answers `201 Created`; `== 200` alone would report a saved
    // address as a failure.
    if (ApiClient.isSuccessCode(response.statusCode)) {
      // `message` sits on the envelope rather than inside the payload, so it
      // arrives via statusText; the legacy flat body still carries it in-band.
      final String? message = (response.body is Map ? response.body['message'] : null) ?? response.statusText;
      List<int> zoneIds = [];
      for (final dynamic z in ResponseParser.listOrEmpty(response.body, legacyKey: 'zone_ids')) {
        zoneIds.add(z as int);
      }
      return ResponseModel(true, message, zoneIds: zoneIds);
    } else {
      return ResponseModel(false, response.statusText == 'Out of coverage!' ? 'service_not_available_in_this_area'.tr : response.statusText);
    }
  }

  @override
  Future delete(int? id) async {
    return await _removeAddressByID(id);
  }

  Future<ResponseModel> _removeAddressByID(int? id) async {
    Response response = await apiClient.postData('${AppConstants.removeAddressUri}$id', {"_method": "delete"}, handleError: false);
    if (response.statusCode == 200) {
      return ResponseModel(true, response.body['message']);
    } else {
      return ResponseModel(false, response.statusText);
    }
  }

  @override
  Future get(String? id) {
    throw UnimplementedError();
  }

  @override
  Future getList({int? offset}) async {
    return await _getAllAddress();
  }

  Future<List<AddressModel>?> _getAllAddress() async {
    List<AddressModel>? addressList;
    Response response = await apiClient.getData(AppConstants.addressListUri);
    if (response.statusCode == 200) {
      addressList = [];
      for (final dynamic address in ResponseParser.listOrEmpty(response.body, legacyKey: 'addresses')) {
        addressList.add(AddressModel.fromJson(address));
      }
    }
    return addressList;
  }

  @override
  Future update(Map<String, dynamic> body, int? id) async {
    return await _updateAddress(body, id);
  }

  Future<ResponseModel> _updateAddress(Map<String, dynamic> addressBody, int? addressId) async {
    Response response = await apiClient.putData('${AppConstants.updateAddressUri}$addressId', addressBody);
    if (response.statusCode == 200) {
      return ResponseModel(true, response.body["message"]);
    } else {
      return ResponseModel(false, response.statusText);
    }
  }

}
