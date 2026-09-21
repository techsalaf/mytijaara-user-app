/// Service Module — one selected variation of a cart-less **buy-now** (campaign)
/// line. The booking payload sends these as a `variation` array of
/// `{variant_key, quantity}` entries with the summed total as the top-level
/// `price`. [price] (discounted unit price) and [name] are client-side only —
/// subtotal math and the route round-trip / display; they are not sent per entry.
class ServiceBuyNowVariant {
  final String variantKey;
  final String name;
  final int quantity;
  final double price;

  const ServiceBuyNowVariant({required this.variantKey, required this.name, required this.quantity, required this.price});

  /// Booking / get-tax `variation` array entry — `{variant_key, quantity}`.
  /// The line's money goes as the top-level `price` (Σ unit×qty), not per entry.
  Map<String, dynamic> toJson() => <String, dynamic>{'variant_key': variantKey, 'quantity': quantity};

  /// Full map used for the route round-trip (preserves [name] for display).
  Map<String, dynamic> toRouteJson() =>
      <String, dynamic>{'variant_key': variantKey, 'name': name, 'quantity': quantity, 'price': price};

  factory ServiceBuyNowVariant.fromJson(Map<String, dynamic> json) => ServiceBuyNowVariant(
    variantKey: json['variant_key']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    quantity: int.tryParse(json['quantity']?.toString() ?? '') ?? 1,
    price: double.tryParse(json['price']?.toString() ?? '') ?? 0,
  );
}
