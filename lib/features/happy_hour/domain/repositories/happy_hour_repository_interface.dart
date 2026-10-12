import 'package:sixam_mart/features/happy_hour/domain/models/discount_eligibility_model.dart';
import 'package:sixam_mart/features/happy_hour/domain/models/happy_hour_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/interfaces/repository_interface.dart';

abstract class HappyHourRepositoryInterface extends RepositoryInterface {
  Future<RunningHappyHourModel?> getRunningHappyHour();

  Future<DiscountEligibilityModel?> getDiscountEligibility(int storeId);

  @override
  Future<StoreModel?> getList({int? offset, int limit = 10, bool runningOnly = true});
}
