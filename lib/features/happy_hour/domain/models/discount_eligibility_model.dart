/// `GET /customer/cart/discount-eligibility` — what a store-wide discount comes to on
/// this cart, and how much more the basket needs. Per store: a basket split across
/// three stores can qualify at one and fall short at the other two.
///
/// This is the server's answer to "spend X more to save Y%", and it is authoritative:
/// [qualifyingAmount] excludes what the rate cannot reach, and [maxDiscount] caps what
/// the store will actually give away. Neither is derivable from the cart subtotal.
class DiscountEligibilityModel {
  /// `happy_hour` or `store_discount` — worth wording differently, since a happy hour
  /// is time-limited.
  String? source;
  double? percentage;
  double? minPurchase;

  /// Null when the discount has no cap.
  double? maxDiscount;
  double? qualifyingAmount;
  double? shortfall;
  bool? isQualified;
  double? discountAmount;

  DiscountEligibilityModel({
    this.source, this.percentage, this.minPurchase, this.maxDiscount, this.qualifyingAmount,
    this.shortfall, this.isQualified, this.discountAmount,
  });

  bool get isHappyHour => source == 'happy_hour';
  bool get isStoreDiscount => source == 'store_discount';

  /// Whether the server actually priced a discount the app can name.
  ///
  /// [discountAmount] is only meaningful alongside a [source]: with neither kind
  /// running the server answers with a null source, and the figure beside it
  /// describes nothing. The app falls back to its own cart walk in that case
  /// rather than showing a number it cannot attribute — and the info icon has
  /// nothing to say, so it is not drawn.
  bool get hasKnownSource => isHappyHour || isStoreDiscount;

  /// Whether [discountAmount] is the figure to put on screen.
  ///
  /// Both halves matter. A [source] names what kind of discount it is, and
  /// [isQualified] says this basket has actually earned it — the server only
  /// honours a rate once the basket clears `min_purchase`. Quoting the amount
  /// while short of that threshold advertises a discount the order will not get,
  /// so the app falls back to its own item-level figure until the basket
  /// qualifies.
  bool get providesDiscountAmount => hasKnownSource && (isQualified ?? false);

  DiscountEligibilityModel.fromJson(Map<String, dynamic> json) {
    source = json['source']?.toString();
    percentage = double.tryParse('${json['percentage']}');
    minPurchase = double.tryParse('${json['min_purchase']}');
    maxDiscount = double.tryParse('${json['max_discount']}');
    qualifyingAmount = double.tryParse('${json['qualifying_amount']}');
    shortfall = double.tryParse('${json['shortfall']}');
    isQualified = json['is_qualified'] == true || json['is_qualified'] == 1;
    discountAmount = double.tryParse('${json['discount_amount']}');
  }

  Map<String, dynamic> toJson() => {
    'source': source, 'percentage': percentage, 'min_purchase': minPurchase,
    'max_discount': maxDiscount, 'qualifying_amount': qualifyingAmount,
    'shortfall': shortfall, 'is_qualified': isQualified, 'discount_amount': discountAmount,
  };
}
