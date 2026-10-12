import 'package:sixam_mart/api/json_reader.dart';
import 'package:sixam_mart/api/response_parser.dart';
import 'package:sixam_mart/common/models/pagination_model.dart';
import 'package:sixam_mart/helper/date_converter.dart';

/// Shared by the loyalty-point and wallet transaction histories
/// (`customer/loyalty-point/transactions`, `customer/wallet/transactions`).
class TransactionModel {
  int? totalSize;
  String? limit;
  String? offset;
  List<Transaction>? data;

  TransactionModel({this.totalSize, this.limit, this.offset, this.data});

  TransactionModel.fromJson(Map<String, dynamic> json) {
    // Paging moved under `pagination`; the flat `total_size`/`limit`/`offset` keys are
    // gone, so reading them directly left `totalSize` null and the list unable to page.
    // PaginationModel understands both shapes, and the property names here are
    // unchanged so no caller needs an edit.
    final PaginationModel pagination = PaginationModel.fromJson(json);
    totalSize = pagination.totalSize;
    limit = pagination.limit?.toString();
    offset = pagination.offset?.toString();
    final List<dynamic>? entries = ResponseParser.listOf(json);
    if (entries != null) {
      data = [];
      for (final dynamic v in entries) {
        data!.add(Transaction.fromJson(v));
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_size'] = totalSize;
    data['limit'] = limit;
    data['offset'] = offset;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Transaction {
  int? userId;
  String? transactionId;
  double? credit;
  double? debit;
  double? adminBonus;
  double? balance;
  String? transactionType;
  String? reference;
  DateTime? createdAt;
  DateTime? updatedAt;

  Transaction({
    this.userId,
    this.transactionId,
    this.credit,
    this.debit,
    this.adminBonus,
    this.balance,
    this.transactionType,
    this.reference,
    this.createdAt,
    this.updatedAt,
  });

  /// Every numeric and date field is read defensively.
  ///
  /// The payload has been trimmed to what the history actually renders — loyalty sends
  /// `{credit, debit, transaction_type, reference, created_at}` and wallet adds
  /// `admin_bonus`. `user_id`, `transaction_id`, `balance` and `updated_at` are no
  /// longer sent at all, so `json["balance"].toDouble()` and
  /// `DateTime.parse(json["updated_at"])` threw on the first row and took both entire
  /// histories down with them.
  Transaction.fromJson(Map<String, dynamic> json) {
    userId = JsonReader.toInt(json["user_id"]);
    transactionId = json["transaction_id"]?.toString();
    credit = JsonReader.toDouble(json["credit"]);
    debit = JsonReader.toDouble(json["debit"]);
    adminBonus = JsonReader.toDouble(json["admin_bonus"]);
    balance = JsonReader.toDouble(json["balance"]);
    transactionType = json["transaction_type"];
    reference = json["reference"]?.toString();
    createdAt = DateConverter.apiStringToDateOrNull(json["created_at"]?.toString());
    updatedAt = DateConverter.apiStringToDateOrNull(json["updated_at"]?.toString());
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["user_id"] = userId;
    data["transaction_id"] = transactionId;
    data["credit"] = credit;
    data["debit"] = debit;
    data["admin_bonus"] = adminBonus;
    data["balance"] = balance;
    data["transaction_type"] = transactionType;
    data["reference"] = reference;
    data["created_at"] = createdAt?.toIso8601String();
    data["updated_at"] = updatedAt?.toIso8601String();
    return data;
  }
}
