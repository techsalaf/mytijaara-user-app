class SearchSuggestionModel {
  List<Items>? items;
  List<Stores>? stores;

  SearchSuggestionModel({this.items, this.stores});

  SearchSuggestionModel.fromJson(Map<String, dynamic> json) {
    if (json['items'] != null) {
      items = <Items>[];
      json['items'].forEach((v) {
        items!.add(Items.fromJson(v));
      });
    }
    if (json['stores'] != null) {
      stores = <Stores>[];
      json['stores'].forEach((v) {
        stores!.add(Stores.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (items != null) {
      data['items'] = items!.map((v) => v.toJson()).toList();
    }
    if (stores != null) {
      data['stores'] = stores!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Items {
  int? id;
  String? name;
  String? image;
  String? unitType;
  String? imageFullUrl;
  int? moduleId;
  SuggestionModule? module;

  Items({this.id,
        this.name,
        this.image,
        this.unitType,
        this.imageFullUrl,
        this.moduleId,
        this.module,
      });

  String? get moduleType => module?.type;
  String? get moduleName => module?.name;

  Items.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    image = json['image'];
    unitType = json['unit_type'];
    imageFullUrl = json['image_full_url'];
    moduleId = json['module_id'];
    module = json['module'] != null ? SuggestionModule.fromJson(json['module']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['image'] = image;
    data['unit_type'] = unitType;
    data['image_full_url'] = imageFullUrl;
    data['module_id'] = moduleId;
    if (module != null) {
      data['module'] = module!.toJson();
    }
    return data;
  }
}

class Stores {
  int? id;
  String? name;
  String? logo;
  bool? gstStatus;
  String? gstCode;
  String? logoFullUrl;
  int? moduleId;
  SuggestionModule? module;

  Stores({this.id,
        this.name,
        this.logo,
        this.gstStatus,
        this.gstCode,
        this.logoFullUrl,
        this.moduleId,
        this.module,
  });

  String? get moduleType => module?.type;
  String? get moduleName => module?.name;

  Stores.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    logo = json['logo'];
    gstStatus = json['gst_status'];
    gstCode = json['gst_code'];
    logoFullUrl = json['logo_full_url'];
    moduleId = json['module_id'];
    module = json['module'] != null ? SuggestionModule.fromJson(json['module']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['logo'] = logo;
    data['gst_status'] = gstStatus;
    data['gst_code'] = gstCode;
    data['logo_full_url'] = logoFullUrl;
    data['module_id'] = moduleId;
    if (module != null) {
      data['module'] = module!.toJson();
    }
    return data;
  }
}

class SuggestionModule {
  int? id;
  String? name;
  String? image;
  String? type;

  SuggestionModule({this.id, this.name, this.image, this.type});

  SuggestionModule.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    image = json['image'];
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['image'] = image;
    data['type'] = type;
    return data;
  }
}
