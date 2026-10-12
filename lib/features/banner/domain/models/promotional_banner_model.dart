import 'package:sixam_mart/api/response_parser.dart';

class PromotionalBanner {
  String? basicSectionNearbyFullUrl;
  String? bottomSectionBannerFullUrl;

  PromotionalBanner({
    this.basicSectionNearbyFullUrl,
    this.bottomSectionBannerFullUrl,
  });

  /// `/other-banners` is polymorphic by module — the same endpoint answers a 200
  /// `Successfully fetched` in three different shapes, and all of them have to
  /// parse into a banner:
  ///
  /// - store modules: `{"bottom_section_banner_full_url": "https://…"}`, or the
  ///   same key holding `null` when no artwork is configured;
  /// - parcel: `{"data": [{"value_full_url": …}], "pagination": {…}}`;
  /// - food: a bare `[]` — the backend's idiom for "nothing configured" (five
  ///   other endpoints in the api/v1 capture answer the same way).
  ///
  /// That last shape is why this takes `dynamic` instead of a `Map`: refusing to
  /// parse it left the controller holding null, which the view reads as "still
  /// loading" and shimmers forever. Every 2xx now yields a banner — with a null
  /// URL when there is no artwork — so "loaded and empty" stays distinguishable
  /// from "not loaded yet".
  factory PromotionalBanner.fromResponse(dynamic body) {
    if (body is Map) {
      final dynamic flat = body['bottom_section_banner_full_url'];
      final dynamic nearby = body['basic_section_nearby_full_url'];
      return PromotionalBanner(
        basicSectionNearbyFullUrl: nearby is String ? nearby : null,
        bottomSectionBannerFullUrl: flat is String && flat.isNotEmpty ? flat : _firstBannerUrlIn(body),
      );
    }
    return PromotionalBanner(bottomSectionBannerFullUrl: _firstBannerUrlIn(body));
  }

  /// First non-empty `value_full_url` in the list shapes — `{"data": [...]}` for
  /// parcel, or a bare list. Null when the list is absent, empty, or every entry
  /// is blank (which is what the dev environment returns for parcel).
  static String? _firstBannerUrlIn(dynamic body) {
    for (final dynamic entry in ResponseParser.listOrEmpty(body)) {
      if (entry is Map) {
        final dynamic url = entry['value_full_url'];
        if (url is String && url.isNotEmpty) return url;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['basic_section_nearby_full_url'] = basicSectionNearbyFullUrl;
    data['bottom_section_banner_full_url'] = bottomSectionBannerFullUrl;
    return data;
  }
}
