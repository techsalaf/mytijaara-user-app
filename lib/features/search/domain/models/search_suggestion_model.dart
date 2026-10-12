import 'package:sixam_mart/api/response_parser.dart';
class SearchSuggestionModel {
  List<Items>? items;
  List<Stores>? stores;

  SearchSuggestionModel({this.items, this.stores});

  /// The suggestion body carries **two** lists side by side, and only the item one
  /// was renamed:
  ///
  /// - `items/item-or-store-search`         → `{data: [...], stores: [...], pagination}`
  /// - `service/item-or-store-search`       → `{items: [...], stores: [...]}`
  ///
  /// Reading only `items` therefore returned null on every mart module, so the
  /// suggestion dropdown showed store matches and silently dropped the item matches.
  ///
  /// `items` is still checked first, which keeps the service module and any legacy
  /// backend byte-identical. `stores` must go through [ResponseParser.namedListOf] —
  /// `listOf` falls back to `data`, which here holds the *items* and would hand the
  /// store list the wrong rows.
  SearchSuggestionModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? itemEntries = ResponseParser.listOf(json, legacyKey: 'items');
    if (itemEntries != null) {
      items = <Items>[];
      for (final dynamic v in itemEntries) {
        items!.add(Items.fromJson(v));
      }
    }
    if (json['stores'] != null) {
      stores = <Stores>[];
      for (final dynamic v in ResponseParser.namedListOf(json, 'stores')) {
        stores!.add(Stores.fromJson(v));
      }
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
