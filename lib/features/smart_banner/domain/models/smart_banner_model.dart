import 'package:sixam_mart/api/response_parser.dart';

class SmartBannerModel {
  List<SmartBanner>? smartBanners;

  SmartBannerModel({this.smartBanners});

  SmartBannerModel.fromJson(Map<String, dynamic> json) {
    // The list arrives under `data` on the current API format and under
    // `smart_banners` on the legacy one — accept either so this works against
    // both backends.
    final List<dynamic>? banners = ResponseParser.listOf(json, legacyKey: 'smart_banners');
    if (banners != null) {
      smartBanners = [];
      for (final dynamic v in banners) {
        smartBanners!.add(SmartBanner.fromJson(v));
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (smartBanners != null) {
      data['smart_banners'] = smartBanners!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class SmartBanner {
  int? id;
  String? title;
  String? subtitle;
  String? imageFullUrl;
  String? position;
  String? redirectType;
  int? redirectTargetId;
  int? moduleId;
  int? zoneId;
  String? activeDays;
  String? startDate;
  String? endDate;
  String? startTime;
  String? endTime;

  SmartBanner({
    this.id, this.title, this.subtitle, this.imageFullUrl, this.position,
    this.redirectType, this.redirectTargetId, this.moduleId, this.zoneId, this.activeDays,
    this.startDate, this.endDate, this.startTime, this.endTime,
  });

  SmartBanner.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    subtitle = json['subtitle'];
    imageFullUrl = json['image_full_url'];
    position = json['position'];
    redirectType = json['redirect_type'];
    redirectTargetId = json['redirect_target_id'];
    moduleId = json['module_id'];
    zoneId = json['zone_id'];
    activeDays = json['active_days'];
    startDate = json['start_date'];
    endDate = json['end_date'];
    startTime = json['start_time'];
    endTime = json['end_time'];
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'image_full_url': imageFullUrl,
      'position': position,
      'redirect_type': redirectType,
      'redirect_target_id': redirectTargetId,
      'module_id': moduleId,
      'zone_id': zoneId,
      'active_days': activeDays,
      'start_date': startDate,
      'end_date': endDate,
      'start_time': startTime,
      'end_time': endTime,
    };
  }
}
