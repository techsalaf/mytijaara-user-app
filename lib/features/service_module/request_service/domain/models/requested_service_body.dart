class RequestedServiceBody {
  final int categoryId;
  final int? subCategoryId;
  final String serviceName;
  final String? description;

  const RequestedServiceBody({required this.categoryId, this.subCategoryId,
    required this.serviceName, this.description});

  Map<String, dynamic> toJson() => {
    'category_id': categoryId,
    if (subCategoryId != null) 'sub_category_id': subCategoryId,
    'service_name': serviceName,
    if (description != null && description!.isNotEmpty) 'description': description,
  };
}
