class BillingValues {
  final bool parcel;
  final bool prescriptionOrder;
  final double itemsPrice;
  final double addOns;
  final double subTotal;
  final double discount;
  final double couponDiscount;
  final double referrerBonusAmount;
  final double additionalCharge;
  final double tax;
  final bool taxIncluded;
  final double dmTips;
  final double extraPackagingCharge;
  final double deliveryCharge;
  final double deliveryTypeCharge;
  final double total;
  final bool isHappyHour;
  final double happyHourPercentage;
  final bool isStoreDiscount;

  const BillingValues({
    required this.parcel,
    required this.prescriptionOrder,
    required this.itemsPrice,
    required this.addOns,
    required this.subTotal,
    required this.discount,
    required this.couponDiscount,
    required this.referrerBonusAmount,
    required this.additionalCharge,
    required this.tax,
    required this.taxIncluded,
    required this.dmTips,
    required this.extraPackagingCharge,
    required this.deliveryCharge,
    required this.deliveryTypeCharge,
    required this.total,
    this.isHappyHour = false,
    this.happyHourPercentage = 0,
    this.isStoreDiscount = false,
  });
}

// SUMMARY
// The figures one order's bill is drawn from: item price, add-ons, subtotal, every
// discount and charge, the delivery fee and the total, plus whether a Happy Hour or a
// store discount is what produced the discount and at what rate.
