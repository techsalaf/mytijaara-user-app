import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/service_module/booking_details/domain/repositories/booking_repository_interface.dart';

class BookingRepository implements BookingRepositoryInterface {
  final ApiClient apiClient;

  BookingRepository({required this.apiClient});

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
