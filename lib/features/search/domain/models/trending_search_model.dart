class TrendingSearchModel {
  List<TrendingSearch>? trendingSearches;

  TrendingSearchModel({this.trendingSearches});

  TrendingSearchModel.fromJson(Map<String, dynamic> json) {
    if (json['trending_searches'] != null) {
      trendingSearches = <TrendingSearch>[];
      json['trending_searches'].forEach((v) {
        trendingSearches!.add(TrendingSearch.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (trendingSearches != null) {
      data['trending_searches'] = trendingSearches!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class TrendingSearch {
  String? keyword;
  int? moduleId;

  TrendingSearch({this.keyword, this.moduleId});

  TrendingSearch.fromJson(Map<String, dynamic> json) {
    keyword = json['keyword'];
    moduleId = json['module_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['keyword'] = keyword;
    data['module_id'] = moduleId;
    return data;
  }
}
