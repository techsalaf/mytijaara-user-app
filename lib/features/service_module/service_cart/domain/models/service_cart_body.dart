/// Service Module — request payload for booking-cart `add` and `update`
/// endpoints (served through core `customer/cart/*` routes).
///
/// For `add`:    use [toJson]       — server computes price from variant definition.
/// For `update`: use [toUpdateJson] — only cart_id + quantity + store_id needed.
class ServiceCartBody {
  final int? cartId;
  final int serviceId;
  final int storeId;
  final int quantity;
  final String? variantKey;
  final List<ServiceVariantEntry>? variants;

  ServiceCartBody({this.cartId, required this.serviceId, required this.storeId,
    required this.quantity, this.variantKey, this.variants,
  });

  /// Payload for the `add` endpoint.
  /// When [variants] is set it takes precedence (multi-variant atomic add).
  /// When [variantKey] is set it adds a single variant row.
  /// Otherwise adds a variant-less service row.
  Map<String, dynamic> toJson() {
    if (variants != null && variants!.isNotEmpty) {
      return <String, dynamic>{
        'service_id': serviceId,
        'model': 'Service',
        'store_id': storeId,
        'variants': variants!.map((v) => v.toJson()).toList(),
      };
    }
    return <String, dynamic>{
      'service_id': serviceId,
      'model': 'Service',
      'store_id': storeId,
      'quantity': quantity,
      if (variantKey != null) 'variant_key': variantKey,
    };
  }

  /// Payload for the `update` endpoint: only cart row identity + new quantity.
  Map<String, dynamic> toUpdateJson() => <String, dynamic>{
    'cart_id': cartId,
    'quantity': quantity,
    'store_id': storeId,
  };
}

/// One entry in the `variants` array of an `add` request when multiple
/// variants of the same service are being added/replaced atomically.
class ServiceVariantEntry {
  final String variantKey;
  final int quantity;

  const ServiceVariantEntry({required this.variantKey, required this.quantity});

  Map<String, dynamic> toJson() => <String, dynamic>{'variant_key': variantKey, 'quantity': quantity};
}
