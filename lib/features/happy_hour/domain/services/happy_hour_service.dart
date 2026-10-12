import 'package:sixam_mart/features/happy_hour/domain/models/discount_eligibility_model.dart';
import 'package:sixam_mart/features/happy_hour/domain/models/happy_hour_model.dart';
import 'package:sixam_mart/features/happy_hour/domain/repositories/happy_hour_repository_interface.dart';
import 'package:sixam_mart/features/happy_hour/domain/services/happy_hour_service_interface.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/date_converter.dart';

class HappyHourService implements HappyHourServiceInterface {
  final HappyHourRepositoryInterface happyHourRepositoryInterface;
  HappyHourService({required this.happyHourRepositoryInterface});

  @override
  Future<RunningHappyHourModel?> getRunningHappyHour() async {
    return await happyHourRepositoryInterface.getRunningHappyHour();
  }

  @override
  Future<StoreModel?> getStoreList({required int offset, int limit = 10, bool runningOnly = true}) async {
    return await happyHourRepositoryInterface.getList(offset: offset, limit: limit, runningOnly: runningOnly);
  }

  @override
  Future<DiscountEligibilityModel?> getDiscountEligibility(int storeId) async {
    return await happyHourRepositoryInterface.getDiscountEligibility(storeId);
  }

  @override
  bool isValidHappyHour(RunningHappyHourModel? model) {
    final HappyHourModel? happyHour = model?.happyHour;
    return (model?.isRunning ?? false) && happyHour != null && (happyHour.discount ?? 0) > 0;
  }

  @override
  int resolveRemainingSeconds(HappyHourModel happyHour) {
    final int? remaining = happyHour.remainingSeconds;
    if(remaining != null && remaining > 0) {
      return remaining;
    }
    // `ends_at` carries no timezone, so it is only a fallback for a missing
    // `remaining_seconds` — never the primary source.
    final int seconds = DateConverter.secondsUntil(happyHour.endsAt);
    return seconds > 0 ? seconds : 0;
  }
}
