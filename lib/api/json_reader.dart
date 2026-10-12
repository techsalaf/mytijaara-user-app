/// Tolerant readers for numeric JSON values.
///
/// Models were written against a payload that always sent a number, so they read
/// amounts as `json['price'].toDouble()`. That is a crash, not a null, the moment
/// the API drops the field or sends it as a string — and it takes the whole list
/// down with it, not just one value. Two real outages came from exactly this:
/// `flash-sales` moved pricing onto its nested item, and `storage[].data_id`
/// changed from string to int.
///
/// Use these instead of calling `.toDouble()` / `.toInt()` on a JSON value.
class JsonReader {
  const JsonReader._();

  /// A `double` from a num, a numeric string, or null when absent/unparseable.
  static double? toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  /// An `int` from a num, a numeric string, or null when absent/unparseable.
  /// A fractional number is truncated, matching `num.toInt()`.
  static int? toInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  /// A `String` from any scalar, or null when absent. Use for fields declared
  /// `String?` that the API may send as a number — assigning an int straight to
  /// a `String?` field throws a type error.
  static String? toStr(dynamic value) => value?.toString();

  /// A `List<String>` from a JSON array, or null when the key is absent or holds
  /// something other than a list.
  ///
  /// Use instead of `json['x'].cast<String>()`, which is the list-shaped version
  /// of the same crash: `cast` on a dropped field throws NoSuchMethodError and
  /// takes the whole parse down. `get-trip-details` stopped sending
  /// `images_full_url` / `documents_full_url` on `vehicle_details`, which blanked
  /// the trip screen the booking flow had just opened.
  static List<String>? toStringList(dynamic value) {
    if (value is! List) return null;
    return value.map((dynamic e) => e?.toString() ?? '').toList();
  }

  /// A `List<int>` from a JSON array, dropping entries that don't parse rather
  /// than crashing the whole list — `null`/absent entries become nothing, not 0.
  static List<int> toIntList(dynamic value) {
    if (value is! List) return const <int>[];
    return value.map((dynamic e) => toInt(e)).whereType<int>().toList();
  }
}
