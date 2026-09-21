class RequestedServiceModel {
  final int? id;
  final String? serviceName;
  final String? description;
  final int? categoryId;
  final int? subCategoryId;
  final String? categoryName;
  final String? categoryImageFullUrl;
  final String? status;
  final String? statusLabel;
  final bool? canEdit;
  final bool? canDelete;
  final String? feedback;
  final String? createdAt;
  final String? updatedAt;

  const RequestedServiceModel({
    this.id, this.serviceName, this.description, this.categoryId, this.subCategoryId,
    this.categoryName, this.categoryImageFullUrl, this.status, this.statusLabel,
    this.canEdit, this.canDelete, this.feedback, this.createdAt, this.updatedAt,
  });

  factory RequestedServiceModel.fromJson(Map<String, dynamic> json) => RequestedServiceModel(
    id: int.tryParse(json['id']?.toString() ?? ''),
    serviceName: json['service_name']?.toString(),
    description: json['description']?.toString(),
    categoryId: int.tryParse(json['category_id']?.toString() ?? ''),
    subCategoryId: int.tryParse(json['sub_category_id']?.toString() ?? ''),
    categoryName: json['category_name']?.toString(),
    categoryImageFullUrl: json['category_image_full_url']?.toString(),
    status: json['status']?.toString(),
    statusLabel: json['status_label']?.toString(),
    canEdit: json['can_edit'] as bool?,
    canDelete: json['can_delete'] as bool?,
    feedback: json['feedback']?.toString(),
    createdAt: json['created_at']?.toString(),
    updatedAt: json['updated_at']?.toString(),
  );
}

class RequestedServiceListResult {
  final List<RequestedServiceModel> items;
  final int totalSize;
  final int? offset;

  const RequestedServiceListResult({required this.items, required this.totalSize, this.offset});

  factory RequestedServiceListResult.fromJson(Map<String, dynamic> json) => RequestedServiceListResult(
    items: (json['data'] as List<dynamic>? ?? [])
        .map((e) => RequestedServiceModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    totalSize: int.tryParse(json['total_size']?.toString() ?? '') ?? 0,
    offset: int.tryParse(json['offset']?.toString() ?? ''),
  );
}
