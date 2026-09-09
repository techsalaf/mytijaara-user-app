/// Service Module — category model (shared `categories` table; a category has
/// `childes` sub-categories). `order_count` is present on the top-categories
/// endpoint only.
class ServiceCategoryModel {
  final int? id;
  final String? name;
  final String? imageFullUrl;
  final String? slug;
  final int? orderCount;
  final List<ServiceCategoryModel>? childes;

  ServiceCategoryModel({this.id, this.name, this.imageFullUrl, this.slug, this.orderCount, this.childes});

  factory ServiceCategoryModel.fromJson(Map<String, dynamic> json) => ServiceCategoryModel(
    id: int.tryParse(json['id']?.toString() ?? ''),
    name: json['name']?.toString(),
    imageFullUrl: json['image_full_url']?.toString(),
    slug: json['slug']?.toString(),
    orderCount: int.tryParse(json['order_count']?.toString() ?? ''),
    childes: (json['childes'] as List<dynamic>?)
        ?.map((e) => ServiceCategoryModel.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'image_full_url': imageFullUrl,
    'slug': slug,
    'order_count': orderCount,
    'childes': childes?.map((e) => e.toJson()).toList(),
  };
}
