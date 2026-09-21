import 'package:sixam_mart/features/service_module/booking_details/domain/repositories/booking_repository_interface.dart';
import 'package:sixam_mart/features/service_module/booking_details/domain/services/booking_service_interface.dart';

class BookingService implements BookingServiceInterface {
  final BookingRepositoryInterface bookingRepositoryInterface;

  BookingService({required this.bookingRepositoryInterface});
}
