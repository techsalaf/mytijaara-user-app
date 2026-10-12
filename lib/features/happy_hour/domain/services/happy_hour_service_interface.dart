import 'package:sixam_mart/features/happy_hour/domain/models/discount_eligibility_model.dart';
import 'package:sixam_mart/features/happy_hour/domain/models/happy_hour_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';

abstract class HappyHourServiceInterface {
  Future<RunningHappyHourModel?> getRunningHappyHour();
  Future<StoreModel?> getStoreList({required int offset, int limit = 10, bool runningOnly = true});

  /// A Happy Hour configured at 0% counts as no Happy Hour at all, so a misconfigured
  /// one cannot strip a discount the store already had.
  bool isValidHappyHour(RunningHappyHourModel? model);

  int resolveRemainingSeconds(HappyHourModel happyHour);

  /// The server's shortfall for one store's basket. Null when the call fails, so the
  /// caller can fall back rather than blank the banner.
  Future<DiscountEligibilityModel?> getDiscountEligibility(int storeId);
}
