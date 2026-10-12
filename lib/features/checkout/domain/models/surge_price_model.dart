import 'package:sixam_mart/api/json_reader.dart';

/// An active delivery surge.
///
/// Parsed from the `surge` block of `customer/order/checkout-summary`, which is
/// its only source — the `get-surge-price` endpoint it used to share with is no
/// longer served.
///
/// [customerNote] is the admin's own explanation, on its own key so a page can
/// style it as a *reason* rather than as part of the fee breakdown. The server
/// blanks it and forces [customerNoteStatus] to `0` whenever the delivery is
/// free — nothing is surged onto a free delivery, so there is nothing to explain.
class SurgePriceModel {
  String? title;
  String? customerNote;
  int? customerNoteStatus;
  double? price;
  String? priceType;

  /// The zone the surge was resolved for. Resolved for the **store's** zone
  /// rather than the `zoneId` header — that header can carry several ids where
  /// zones overlap, and the fee was computed for exactly one of them.
  int? zoneId;

  SurgePriceModel({this.title, this.customerNote, this.customerNoteStatus, this.price, this.priceType,
    this.zoneId,
  });

  SurgePriceModel.fromJson(Map<String, dynamic> json) {
    title = JsonReader.toStr(json['title']);
    customerNote = JsonReader.toStr(json['customer_note']);
    customerNoteStatus = JsonReader.toInt(json['customer_note_status']);
    price = JsonReader.toDouble(json['price']);
    priceType = JsonReader.toStr(json['price_type']);
    zoneId = JsonReader.toInt(json['zone_id']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['title'] = title;
    data['customer_note'] = customerNote;
    data['customer_note_status'] = customerNoteStatus;
    data['price'] = price;
    data['price_type'] = priceType;
    data['zone_id'] = zoneId;
    return data;
  }

  /// Whether there is a note worth rendering. Both conditions matter: the server
  /// blanks the text *and* clears the status on a free delivery.
  bool get hasCustomerNote => customerNoteStatus == 1 && (customerNote?.isNotEmpty ?? false);
}
