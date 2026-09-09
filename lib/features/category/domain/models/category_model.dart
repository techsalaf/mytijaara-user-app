class CategoryModel {
  int? id;
  String? name;
  String? imageFullUrl;
  String? slug;
  int? moduleId;

  CategoryModel({this.id, this.name, this.imageFullUrl, this.slug, this.moduleId});

  CategoryModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    imageFullUrl = json['image_full_url'];
    slug = json['slug'];
    moduleId = json['module_id'] is String ? int.tryParse(json['module_id']) : json['module_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['image_full_url'] = imageFullUrl;
    data['slug'] = slug;
    data['module_id'] = moduleId;
    return data;
  }
}
