import 'dart:convert';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';

class ZoneModel {
  List<int>? zoneIds;
  List<ZoneData>? zoneData;

  ZoneModel({this.zoneIds, this.zoneData});

  ZoneModel.fromJson(Map<String, dynamic> json) {
    // GEMINI-MYTJ start: accept both legacy string IDs and native JSON arrays.
    zoneIds = [];
    final dynamic rawZoneIds = json['zone_id'];
    final dynamic decodedZoneIds = rawZoneIds is String
        ? jsonDecode(rawZoneIds)
        : rawZoneIds;
    if (decodedZoneIds is List) {
      for (final dynamic value in decodedZoneIds) {
        final int? zoneId = int.tryParse(value.toString());
        if (zoneId != null) zoneIds!.add(zoneId);
      }
    }
    // GEMINI-MYTJ end
    if (json['zone_data'] != null) {
      zoneData = <ZoneData>[];
      json['zone_data'].forEach((v) {
        zoneData!.add(ZoneData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['zone_id'] = zoneIds;
    if (zoneData != null) {
      data['zone_data'] = zoneData!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
