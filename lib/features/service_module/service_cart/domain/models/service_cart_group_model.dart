import 'package:sixam_mart/features/service_module/service_cart/domain/models/service_cart_model.dart';

/// Service Module — one provider group from the booking-cart `get-all` endpoint.
/// The cart can hold services from several providers; `get-all` groups the rows
/// by provider so the global cart can render a card per provider.
class ServiceCartGroupModel {
  final ServiceCartProvider? provider;
  ServiceCartSummary? summary;
  final List<ServiceCartModel> carts;

  ServiceCartGroupModel({this.provider, this.summary, this.carts = const []});

  factory ServiceCartGroupModel.fromJson(Map<String, dynamic> json) => ServiceCartGroupModel(
    provider: json['provider'] != null ? ServiceCartProvider.fromJson(json['provider'] as Map<String, dynamic>) : null,
    summary: json['summary'] is Map<String, dynamic>
        ? ServiceCartSummary.fromJson(json['summary'] as Map<String, dynamic>)
        : null,
    carts: (json['carts'] as List<dynamic>?)
        ?.map((e) => ServiceCartModel.fromJson(e as Map<String, dynamic>))
        .toList() ?? <ServiceCartModel>[],
  );
}

/// Per-provider price summary from the `get-all` endpoint.
/// `totalAmount` = `subtotal + taxAmount` when tax is `excluded`, and equals
/// `subtotal` when `included` (the tax is already inside the line prices).
class ServiceCartSummary {
  final double? subtotal;
  final double? discount;
  final double? taxAmount;
  final String? taxStatus;
  final double? totalAmount;

  ServiceCartSummary({this.subtotal, this.discount, this.taxAmount, this.taxStatus, this.totalAmount});

  factory ServiceCartSummary.fromJson(Map<String, dynamic> json) => ServiceCartSummary(
    subtotal: double.tryParse(json['subtotal']?.toString() ?? ''),
    // `get-all` returns `discount_amount`; `discount` is kept as a tolerant alias.
    discount: double.tryParse((json['discount_amount'] ?? json['discount'])?.toString() ?? ''),
    taxAmount: double.tryParse(json['tax_amount']?.toString() ?? ''),
    taxStatus: json['tax_status']?.toString(),
    totalAmount: double.tryParse(json['total_amount']?.toString() ?? ''),
  );
}

class ServiceCartProvider {
  final int? id;
  final String? name;
  final String? slug;
  final String? logoFullUrl;
  final int? verifiedProvider;
  final int? serviceCount;
  final double? distance;
  final double? distanceKm;
  // Which location(s) the customer may pick for this booking — 'customer',
  // 'provider', or both. Null/empty means unrestricted (both allowed).
  final List<String>? chooseServiceLocation;
  final int? zoneId;

  ServiceCartProvider({this.id, this.name, this.slug, this.logoFullUrl, this.verifiedProvider,
    this.serviceCount, this.distance, this.distanceKm, this.chooseServiceLocation, this.zoneId,
  });

  factory ServiceCartProvider.fromJson(Map<String, dynamic> json) => ServiceCartProvider(
    id: int.tryParse(json['id']?.toString() ?? ''),
    name: json['name']?.toString(),
    slug: json['slug']?.toString(),
    logoFullUrl: json['logo_full_url']?.toString(),
    verifiedProvider: int.tryParse(json['verified_provider']?.toString() ?? ''),
    serviceCount: int.tryParse(json['service_count']?.toString() ?? ''),
    distance: double.tryParse(json['distance']?.toString() ?? ''),
    distanceKm: double.tryParse(json['distance_km']?.toString() ?? ''),
    chooseServiceLocation: json['choose_service_location'] is List
        ? (json['choose_service_location'] as List).map((e) => e.toString()).toList()
        : null,
    zoneId: int.tryParse(json['zone_id']?.toString() ?? ''),
  );
}
