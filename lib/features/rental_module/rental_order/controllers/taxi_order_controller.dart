import 'package:get/get.dart';
import 'package:sixam_mart/features/rental_module/common/models/trip_model.dart';
import 'package:sixam_mart/features/rental_module/rental_order/domain/services/taxi_order_service_interface.dart';

class TaxiOrderController extends GetxController implements GetxService {
  final TaxiOrderServiceInterface taxiOrderServiceInterface;

  TaxiOrderController({required this.taxiOrderServiceInterface});

  final bool _isLoading = false;
  bool get isLoading => _isLoading;

  TripModel? _tripModel;
  TripModel? get tripModel => _tripModel;

  TripModel? _tripHistoryModel;
  TripModel? get tripHistoryModel => _tripHistoryModel;

  Future<void> getTripList(int offset, {bool isUpdate = false, bool isRunning = true, bool fromHome = false}) async {}

  Future<bool> getTripDetails(int id, {bool willUpdate = true, String? phone}) async {
    return false;
  }

  Future<bool> deleteTrip(int? id) async {
    return false;
  }

  void removeTripFromList(int? id) {
  }
}