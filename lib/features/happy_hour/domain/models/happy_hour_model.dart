class RunningHappyHourModel {
  bool? isRunning;
  HappyHourModel? happyHour;

  RunningHappyHourModel({this.isRunning, this.happyHour});

  RunningHappyHourModel.fromJson(Map<String, dynamic> json) {
    isRunning = json['is_running'] == true || json['is_running'] == 1;
    happyHour = json['happy_hour'] != null ? HappyHourModel.fromJson(json['happy_hour']) : null;
  }

  Map<String, dynamic> toJson() => {'is_running': isRunning, 'happy_hour': happyHour?.toJson()};
}

class HappyHourModel {
  int? id;
  String? slug;
  String? title;
  String? shortDescription;
  String? coverImageFullUrl;
  String? iconFullUrl;
  double? discount;
  double? minOrderAmount;
  String? durationType;
  bool? isPermanent;
  List<String>? weeklyDays;
  String? startTime;
  String? endTime;
  String? startDate;
  String? endDate;
  bool? isRunningNow;
  String? startedAt;
  String? endsAt;
  int? remainingSeconds;
  int? storeCount;
  int? moduleId;

  HappyHourModel({
    this.id, this.slug, this.title, this.shortDescription, this.coverImageFullUrl,
    this.iconFullUrl, this.discount, this.minOrderAmount, this.durationType, this.isPermanent,
    this.weeklyDays, this.startTime, this.endTime, this.startDate, this.endDate,
    this.isRunningNow, this.startedAt, this.endsAt, this.remainingSeconds, this.storeCount,
    this.moduleId,
  });

  HappyHourModel.fromJson(Map<String, dynamic> json) {
    id = int.tryParse('${json['id']}');
    slug = json['slug']?.toString();
    title = json['title']?.toString();
    shortDescription = json['short_description']?.toString();
    coverImageFullUrl = json['cover_image_full_url']?.toString();
    iconFullUrl = json['icon_full_url']?.toString();
    discount = double.tryParse('${json['discount']}');
    minOrderAmount = double.tryParse('${json['min_order_amount']}');
    durationType = json['duration_type']?.toString();
    isPermanent = json['is_permanent'] == true || json['is_permanent'] == 1;
    weeklyDays = json['weekly_days'] is List ? (json['weekly_days'] as List).map((d) => d.toString()).toList() : null;
    startTime = json['start_time']?.toString();
    endTime = json['end_time']?.toString();
    startDate = json['start_date']?.toString();
    endDate = json['end_date']?.toString();
    isRunningNow = json['is_running_now'] == true || json['is_running_now'] == 1;
    startedAt = json['started_at']?.toString();
    endsAt = json['ends_at']?.toString();
    remainingSeconds = int.tryParse('${json['remaining_seconds']}');
    // `store_count` is the mart wording; `restaurant_count` is kept for parity with
    // the shared backend, which still names it that way on food-only deployments.
    storeCount = int.tryParse('${json['store_count']}') ?? int.tryParse('${json['restaurant_count']}');
    moduleId = int.tryParse('${json['module_id']}');
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'slug': slug, 'title': title, 'short_description': shortDescription,
    'cover_image_full_url': coverImageFullUrl, 'icon_full_url': iconFullUrl,
    'discount': discount, 'min_order_amount': minOrderAmount, 'duration_type': durationType,
    'is_permanent': isPermanent, 'weekly_days': weeklyDays, 'start_time': startTime,
    'end_time': endTime, 'start_date': startDate, 'end_date': endDate,
    'is_running_now': isRunningNow, 'started_at': startedAt, 'ends_at': endsAt,
    'remaining_seconds': remainingSeconds, 'store_count': storeCount, 'module_id': moduleId,
  };
}
