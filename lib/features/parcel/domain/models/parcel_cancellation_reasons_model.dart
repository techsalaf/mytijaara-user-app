import 'package:sixam_mart/common/models/pagination_model.dart';
class ParcelCancellationReasonsModel {
  int? totalSize;
  int? limit;
  int? offset;
  List<Reason>? data;

  ParcelCancellationReasonsModel({this.totalSize, this.limit, this.offset, this.data});

  ParcelCancellationReasonsModel.fromJson(Map<String, dynamic> json) {
    // Paging arrives flat (`total_size`/`limit`/`offset`) on the legacy format
    // and nested under `pagination` now. Property names are unchanged, so no
    // caller needs an edit.
    final PaginationModel _pg = PaginationModel.fromJson(json);
    totalSize = _pg.totalSize;
    limit = _pg.limit;
    offset = _pg.offset;
    if (json['data'] != null) {
      data = <Reason>[];
      json['data'].forEach((v) {
        data!.add(Reason.fromJson(v));
      });
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

class Reason {
  int? id;
  String? reason;
  String? userType;
  String? cancellationType;

  Reason({this.id, this.reason, this.userType, this.cancellationType});

  Reason.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    reason = json['reason'];
    userType = json['user_type'];
    cancellationType = json['cancellation_type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['reason'] = reason;
    data['user_type'] = userType;
    data['cancellation_type'] = cancellationType;
    return data;
  }
}
