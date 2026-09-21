import 'package:get/get.dart';
import 'package:sixam_mart/common/models/ongoing_order_model.dart';
import 'package:sixam_mart/features/service_module/booking_details/domain/models/booking_model.dart';
import 'package:sixam_mart/features/service_module/booking_details/domain/services/booking_service_interface.dart';

class BookingController extends GetxController implements GetxService {
  final BookingServiceInterface bookingServiceInterface;

  BookingController({required this.bookingServiceInterface});

  List<OrderData>? get dashboardRunningBookings => null;

  PaginatedBookingModel? bookingModelOf(BookingListType type) => null;

  Future<void> getBookings(BookingListType type, int offset, {bool isUpdate = false, bool notify = true}) async {}

  Future<void> getDashboardRunningBookings() async {}

  Future<bool> deleteBooking(int id) async => false;

  void removeBookingFromList(int? id, {List<BookingListType> listTypes = BookingListType.values}) {}

  Future<void> refreshBookingDetail(int id, {bool notify = false}) async {}
}
