class BookingBillingValues {
  final double servicesPrice;
  final double addOns;
  final double subTotal;
  final double discount;
  final double couponDiscount;
  final double proDiscount;
  final double referrerBonusAmount;
  final double additionalCharge;
  final double tax;
  final bool taxIncluded;
  final double total;

  const BookingBillingValues({
    required this.servicesPrice,
    required this.addOns,
    required this.subTotal,
    required this.discount,
    required this.couponDiscount,
    required this.proDiscount,
    required this.referrerBonusAmount,
    required this.additionalCharge,
    required this.tax,
    required this.taxIncluded,
    required this.total,
  });
}
