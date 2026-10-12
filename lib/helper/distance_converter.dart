import 'package:get/get.dart';
import 'package:sixam_mart/common/models/config_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';

/// Renders a distance the app computed in kilometres in whatever unit the
/// platform is configured for.
///
/// **This is not the same job as suffixing a rate.** `distance_unit` decides the
/// unit *rates* are quoted in, and a per-unit price is entered against that unit
/// already — so those only need `ConfigModel.distanceUnitSuffix`, never a
/// conversion. A distance the client measured is different: `getDistanceInKM`
/// returns kilometres whatever the setting says, so relabelling it `mi` without
/// converting reports a number roughly 1.6× too large.
///
/// Distances the **API** sends are also not this job — `Store.distanceLabel` and
/// the rental trip distance arrive already expressed in the configured unit and
/// are rendered as sent.
class DistanceConverter {
  const DistanceConverter._();

  /// Exact, by definition of the international mile.
  static const double _kilometresPerMile = 1.609344;

  static ConfigModel? get _config =>
      Get.isRegistered<SplashController>() ? Get.find<SplashController>().configModel : null;

  /// The configured unit, matched on [MeasurementUnitModel.unit] where the
  /// platform sends the structured block and on the flat `distance_unit_label`
  /// otherwise — the two report the same setting.
  static String? get _configuredUnit {
    final ConfigModel? config = _config;
    return config?.distanceUnit?.unit ?? config?.distanceUnitLabel;
  }

  /// What to write after the number. Falls back to `km`, which is also what the
  /// unconverted value is in, so an unreadable config cannot produce a mislabel.
  ///
  /// Also the right thing for a **per-unit rate** — `৳50 /km` — on its own,
  /// without [fromKilometres]: a rate is entered against the configured unit
  /// already, so only the word after it changes.
  static String get unitSuffix => _config?.distanceUnitSuffix ?? 'km';

  /// [kilometres] expressed in the platform's unit.
  static double fromKilometres(double kilometres) => convert(kilometres, _configuredUnit);

  /// `12.34 km`, or null when there is no distance to show yet — the caller
  /// renders "calculating" rather than a zero, which reads as "next door".
  static String? labelFromKilometres(double? kilometres, {int decimals = 2}) {
    if (kilometres == null || kilometres < 0) return null;
    return format(kilometres, _configuredUnit, suffix: unitSuffix, decimals: decimals);
  }

  /// Pure form of [fromKilometres], so the arithmetic can be checked without a
  /// GetX container standing behind it.
  ///
  /// Converts only for a unit positively recognised as miles. Anything else —
  /// `km`, an empty config, a unit this build has never heard of — is left
  /// alone, so an unrecognised setting degrades to the value the app actually
  /// holds rather than to a silently scaled one.
  static double convert(double kilometres, String? unit) =>
      _isMiles(unit) ? kilometres / _kilometresPerMile : kilometres;

  /// Pure form of [labelFromKilometres].
  static String format(double kilometres, String? unit, {required String suffix, int decimals = 2}) =>
      '${convert(kilometres, unit).toStringAsFixed(decimals)} $suffix';

  static bool _isMiles(String? unit) {
    final String normalised = (unit ?? '').trim().toLowerCase();
    return normalised == 'mi' || normalised == 'mile' || normalised == 'miles';
  }
}
