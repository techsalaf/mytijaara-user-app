class TopCategoryModel {
  int? totalSize;
  int? limit;
  int? offset;
  List<TopCategory>? categories;

  TopCategoryModel({this.totalSize, this.limit, this.offset, this.categories});

  TopCategoryModel.fromJson(Map<String, dynamic> json) {
    totalSize = json['total_size'];
    limit = json['limit'] is String ? int.tryParse(json['limit']) : json['limit'];
    offset = json['offset'] is String ? int.tryParse(json['offset']) : json['offset'];
    if (json['categories'] != null) {
      categories = <TopCategory>[];
      json['categories'].forEach((v) => categories!.add(TopCategory.fromJson(v)));
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_size'] = totalSize;
    data['limit'] = limit;
    data['offset'] = offset;
    if (categories != null) {
      data['categories'] = categories!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class TopCategory {
  int? id;
  String? name;
  String? imageFullUrl;
  int? orderCount;
  String? slug;
  List<TopCategoryChild>? childes;
  int? moduleId;

  TopCategory({this.id, this.name, this.imageFullUrl, this.orderCount, this.slug, this.childes, this.moduleId});

  TopCategory.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    imageFullUrl = json['image_full_url'];
    orderCount = json['order_count'];
    slug = json['slug'];
    if (json['childes'] != null) {
      childes = <TopCategoryChild>[];
      json['childes'].forEach((v) => childes!.add(TopCategoryChild.fromJson(v)));
    }
    moduleId = json['module_id'] is String ? int.tryParse(json['module_id']) : json['module_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['image_full_url'] = imageFullUrl;
    data['order_count'] = orderCount;
    data['slug'] = slug;
    if (childes != null) {
      data['childes'] = childes!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class TopCategoryChild {
  int? id;
  String? name;
  String? slug;

  TopCategoryChild({this.id, this.name, this.slug});

  TopCategoryChild.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    slug = json['slug'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['slug'] = slug;
    return data;
  }
}
