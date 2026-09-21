/// Response of `POST /api/v1/service/booking/rebook` — rebuilds a provider's
/// service cart from a past booking. Non-200 responses (403/404) carry the
/// same shape plus an `errors[0].message`, so `errorMessage` is parsed
/// regardless of status code and used as a fallback status line.
class ServiceRebookResponseModel {
  int? providerId;
  int? addedCount;
  int? unavailableCount;
  List<RebookUnavailableItem>? unavailableItems;
  String? message;
  String? errorMessage;

  ServiceRebookResponseModel({this.providerId, this.addedCount, this.unavailableCount,
    this.unavailableItems, this.message, this.errorMessage,
  });

  factory ServiceRebookResponseModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? errors = json['errors'] as List<dynamic>?;
    final Map<String, dynamic>? firstError = errors != null && errors.isNotEmpty ? errors.first as Map<String, dynamic> : null;

    return ServiceRebookResponseModel(
      providerId: int.tryParse(json['provider_id']?.toString() ?? ''),
      addedCount: int.tryParse(json['added_count']?.toString() ?? ''),
      unavailableCount: int.tryParse(json['unavailable_count']?.toString() ?? ''),
      unavailableItems: (json['unavailable_items'] as List<dynamic>?)?.map((e) => RebookUnavailableItem.fromJson(e as Map<String, dynamic>)).toList(),
      message: json['message']?.toString(),
      errorMessage: firstError?['message']?.toString(),
    );
  }
}

class RebookUnavailableItem {
  String? status;
  int? serviceId;
  String? serviceName;
  String? code;
  String? message;

  RebookUnavailableItem({this.status, this.serviceId, this.serviceName, this.code, this.message});

  factory RebookUnavailableItem.fromJson(Map<String, dynamic> json) => RebookUnavailableItem(
    status: json['status']?.toString(),
    serviceId: int.tryParse(json['service_id']?.toString() ?? ''),
    serviceName: json['service_name']?.toString(),
    code: json['code']?.toString(),
    message: json['message']?.toString(),
  );
}
